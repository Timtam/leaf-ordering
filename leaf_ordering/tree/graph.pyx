# cython: profile=True
# distutils: define_macros=CYTHON_TRACE_NOGIL=1

from ..exceptions import TreeError

cimport cython
from cython.parallel cimport prange
from libc.float cimport DBL_MAX
from libc.limits cimport INT_MAX
from libc.math cimport ceil, log2, pow, sqrt
from libc.stdlib cimport malloc, free
from libc.string cimport memcpy, memset
from libcpp.queue cimport priority_queue

from .node cimport Node
from .matrix cimport GETI, GETJ, IDX, min_element, Distance

# graph class
# is basically just a derived node, but with additional methods

cdef class Graph(Node):
  # constructor
  def __init__(Graph self):
    Node.__init__(self, self, 0)
    self.height = 0
    self.data_width = 0
    self.data_height = 0
    self.id_offset = 1
  
  # builds the binary tree
  # receives the leaf data as parameter
  @cython.boundscheck(False)
  @cython.nonecheck(False)
  @cython.wraparound(False)
  cpdef build(Graph self, int[:, :] dataset):
    cdef int m, n
    cdef int i
    if self.height > 0:
      raise TreeError("tree already exists")
    m = dataset.shape[0]
    n = dataset.shape[1]
    if m > INT_MAX:
      raise TreeError("unable to process more data entries than {0}".format(INT_MAX))
    self.height = <int>ceil(log2(<double>m))
    if pow(2, self.height) > INT_MAX:
      self.height = 0
      raise TreeError("unable to process more data entries than {0}".format(INT_MAX))
    # copying the dataset
    # and filling in additional data
    # until we get a complete tree
    self.data = <int*>malloc(<int>pow(2, self.height)*n*sizeof(int))
    if self.data == NULL:
      self.height = 0
      raise MemoryError()
    for i in prange(m, nogil=True):
      memcpy(self.data + i * n, &(dataset[i, 0]), n*sizeof(int))
    if pow(2, self.height) > m:
      for i in prange(m, <int>pow(2, self.height), nogil=True):
        memset(self.data + i * n, 0, n * sizeof(int))
    m = <int>pow(2, self.height)
    self.data_height = m
    self.data_width = n
    # building the distances matrix (see below)
    self.build_distances_matrix()
    # clustering all leaves
    self.build_cluster()
    # rebuilding distances matrix
    free(<void*>self.distances)
    self.build_distances_matrix()
    # inserting all leaves
    for i in xrange(m):
      self.insert_at(i, self.data + i * n)

  # inserts the given leaf at the given index
  # index points towards the leaf at the given position
  #   (binary representation)
  # all nodes which don't yet exist, but need to be filled in
  # will be created automatically
  cdef void insert_at(Graph self, int where, int *what):
    cdef int i
    cdef int pos
    cdef Node current = self
    cdef Node next
    for i in xrange(self.height - 1, -1, -1):
      pos = (where>>i)&0x1
      if pos == 0:
        if current.left is None:
          next = Node(self, self.id_offset)
          current.set_left(next)
          self.id_offset += 1
        current = current.left
      elif pos == 1:
        if current.right is None:
          next = Node(self, self.id_offset)
          current.set_right(next)
          self.id_offset += 1
        current = current.right
    current.set_data(what, where)

  # cleans the graph from all children
  cpdef clear(Graph self):
    Node.detach_children(self)
    self.height = 0
    self.data_height = 0
    self.data_width = 0
    self.id_offset = 1
    if self.distances != NULL:
      free(<void*>self.distances)
      self.distances = NULL
    if self.data != NULL:
      free(<void*>self.data)
      self.data = NULL

  # destructor
  # frees unneeded memory
  def __dealloc__(Graph self):
    if self.distances != NULL:
      free(<void*>self.distances)
    if self.data != NULL:
      free(<void*>self.data)

  # builds the distance matrix
  # the distance matrix is a triangular matrix, which contains
  # all possible distances between the leaves
  @cython.boundscheck(False)
  @cython.wraparound(False)
  @cython.nonecheck(False)
  cdef void build_distances_matrix(Graph self):
    cdef int m = self.data_height
    cdef int n = self.data_width
    self.distances = <double*>malloc((m+1)*m/2*sizeof(double))
    cdef int i, j, k
    cdef double d
    if self.distances == NULL:
      raise MemoryError()
    # prange enables multithreading to improve performance drastically
    for i in prange(m, nogil=True):
      for j in xrange(i+1):
        if i == j:
          self.distances[IDX(i,j)] = -1.0
        else:
          d = 0
          for k in xrange(n):
            d = d + pow(self.data[j * n + k]-self.data[i * n +k], 2)
          self.distances[IDX(i,j)] = sqrt(d)

  # first heuristics implementation
  # we start ordering at level (graph.height - 1)
  # we take all nodes and compare them
  # we then check all 4 possible distances (see below)
  # and rotate the nodes to get the best possible distance
  # we therefore remember the previous distance and check, if turning the first
  # node around will probably increase the previous distance even more than we reduce it
  # when one level finished, we decrease the level and start again
  # ends at level 0 (root)
  cpdef sort_a(Graph self):
    cdef double[4] dist;
    cdef double* min_dist
    cdef double dist_diff = .0
    cdef int i, j
    cdef list nodes
    cdef Node leaf_a, leaf_b
    cdef Node node_a, node_b
    # we got four different distances:
    # a: both leaves are initial
    # b: leave 1 and 2 are rotated
    # c: leaves 1 and 2 and 3 and 4 are rotated
    # d: leaves 1 and 2 are initial, 3 and 4 are rotated
    for i in xrange(self.height - 1, -1, -1):
      nodes = self.get_children_at_level(i)
      for j in xrange(len(nodes) - 1):
        node_a = nodes[j]
        node_b = nodes[j+1]
        #   calculating all distances
        # a
        leaf_a = node_a.get_bottom_right_node()
        leaf_b = node_b.get_bottom_left_node()
        dist[0] = self.distances[IDX(leaf_a.leaf_id, leaf_b.leaf_id)]
        # b
        leaf_a = node_a.get_bottom_left_node()
        dist[1] = self.distances[IDX(leaf_a.leaf_id, leaf_b.leaf_id)]
        if j > 0:
          dist[1] += dist_diff
        # c
        leaf_b = node_b.get_bottom_right_node()
        dist[2] = self.distances[IDX(leaf_a.leaf_id, leaf_b.leaf_id)]
        if j > 0:
          dist[2] += dist_diff
        # d
        leaf_a = node_a.get_bottom_right_node()
        dist[3] = self.distances[IDX(leaf_a.leaf_id, leaf_b.leaf_id)]
        # comparing and rotating
        min_dist = min_element(dist, dist + 4)
        if min_dist - dist == 1 or min_dist - dist == 2:
          node_a.rotate()
        if min_dist - dist == 2 or min_dist - dist == 3:
          node_b.rotate()
        # calculating distance difference
        leaf_a = node_a.get_bottom_right_node()
        leaf_b = node_b.get_bottom_right_node()
        dist_diff = self.distances[IDX(leaf_a.leaf_id, leaf_b.leaf_id)] - min_dist[0]

  # copies all datasets within the leaves together and returns them
  @cython.boundscheck(False)
  @cython.nonecheck(False)
  @cython.wraparound(False)
  cpdef get_data(Graph self):
    cdef int i
    cdef int offset
    cdef list nodes = self.get_children_at_level(self.height)
    cdef int m = self.data_height
    cdef int n = self.data_width
    cdef Node node
    cdef int *data = <int*>malloc(m*n*sizeof(int))
    cdef int[:] blk
    cdef int[:] datablk
    if data == NULL:
      raise MemoryError()
    for i in xrange(m):
      node = nodes[i]
      offset = i*n
      blk = <int[:n]>(data+offset)
      datablk = <int[:n]>(node.data)
      blk[...] = datablk
    cdef int[:, ::1] mem = (<int[:m, :n]>data).copy()
    free(<void*>data)
    return mem

  # calculates the distances of all pairs of leaves
  cpdef get_distance(Graph self):
    cdef list nodes = self.get_children_at_level(self.height)
    cdef double dist = 0
    cdef int i
    cdef int n = self.data_height
    cdef Node node_a, node_b
    for i in xrange(1, n - 2, 2):
      node_a = nodes[i]
      node_b = nodes[i+1]
      dist += self.distances[IDX(node_a.leaf_id, node_b.leaf_id)]
    return dist

  # clustering the tree
  cdef void build_cluster(Graph self):
    cdef priority_queue[Distance] q
    cdef Distance d
    cdef int m = self.data_height
    cdef int n = self.data_width
    cdef int i
    cdef int row, col
    cdef bint * clustered = <bint*>malloc(m*sizeof(bint))
    cdef int *buf = <int*>malloc(n*m*sizeof(int))
    cdef int offset = 0
    cdef int[:, :] res
    if clustered == NULL:
      return
    if buf == NULL:
      free(<void*>clustered)
      return
    memset(<void*>clustered, False, m*sizeof(bint))
    for i in xrange((m+1)*m/2):
      if self.distances[i] >= 0:
        d.distance = self.distances[i]
        d.index = i
        q.push(d)
    while not q.empty():
      d = q.top()
      q.pop()
      row = GETI(d.index)
      col = GETJ(row,d.index)
      if clustered[row] == True or clustered[col] == True:
        continue
      memcpy(buf+offset, self.data+n*row, n*sizeof(int))
      offset += n
      clustered[row] = True
      memcpy(buf+offset, self.data+n*col, n*sizeof(int))
      offset += n
      clustered[col] = True

  # the second heuristics (by Ziv Bar-Joseph et al.)
  cpdef sort_b(Graph self):
    cdef dict S = {}
    if not self.right:
      raise TreeError("no right tree")
    if not self.left:
      raise TreeError("no left tree")
    self.sort_b_rec(self, S)

  cdef double sort_b_rec(Graph self, Node v, dict S):
    cdef double min, score
    cdef list L, R, LL, LR, RL, RR, TL, TR
    cdef Node l, r, u, w, m, k
    cdef unsigned int i, j, I, J, ii, jj
    if v.is_leaf():
      S[v.id, v.leaf_id, v.leaf_id] = 0
      return 0
    L = v.left.get_children_at_level(self.height)
    R = v.right.get_children_at_level(self.height)
    if not v.left.left is None:
      LL = v.left.left.get_children_at_level(self.height)
    else:
      LL = v.left.get_children_at_level(self.height)
    if not v.left.right is None:
      LR = v.left.right.get_children_at_level(self.height)
    else:
      LR = v.left.get_children_at_level(self.height)
    if not v.right.left is None:
      RL = v.right.left.get_children_at_level(self.height)
    else:
      RL = v.right.get_children_at_level(self.height)
    if not v.left.left is None:
      RR = v.right.right.get_children_at_level(self.height)
    else:
      RR = v.right.get_children_at_level(self.height)
    for i in xrange(len(L)):
      l = L[i]
      for j in xrange(len(R)):
        r = R[j]
        S[v.left.id, l.leaf_id, r.leaf_id] = self.sort_b_rec(v.left, S)
        S[v.right.id, l.leaf_id, r.leaf_id] = self.sort_b_rec(v.right, S)
        for I in xrange(len(L)):
          u = L[I]
          for J in xrange(len(R)):
            w = R[J]
            min = DBL_MAX
            if u in LR:
              TL = LL
            else:
              TL = LR
            if w in RR:
              TR = RL
            else:
              TR = RR
            for ii in xrange(len(TL)):
              m = TL[ii]
              for jj in xrange(len(TR)):
                k = TR[jj]
                if u == m:
                  S[v.left.id, u.leaf_id, m.leaf_id] = 0
                if w == k:
                  S[v.right.id, w.leaf_id, k.leaf_id] = 0
                score = S[v.left.id, u.leaf_id, m.leaf_id] + S[v.right.id, w.leaf_id, k.leaf_id] + self.distances[IDX(m.leaf_id, k.leaf_id)]
                if score < min:
                  min = score
            S[v.id, u.leaf_id, w.leaf_id] = S[v.id, w.leaf_id, u.leaf_id] = min
        return <double>S[v.id, l.leaf_id, r.leaf_id]
