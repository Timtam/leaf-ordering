# cython: profile=True
# cython: profile=True
# distutils: define_macros=CYTHON_TRACE_NOGIL=1

from ..exceptions import NotAvailableError, TreeError
from itertools import product
from scipy.cluster.hierarchy import linkage, to_tree
from scipy.spatial.distance import pdist

try:
  from scipy.cluster.hierarchy import optimal_leaf_ordering
except ImportError:
  SCIPY_ORDERING = False
else:
  SCIPY_ORDERING = True

cimport cython
from cython.parallel cimport prange
from libc.float cimport DBL_MAX
from libc.limits cimport INT_MAX
from libc.math cimport ceil, log2, pow, sqrt
from libc.stdlib cimport malloc, free, srand, rand
from libc.string cimport memcpy, memset
from libc.time cimport time

from .node cimport Node
from .matrix cimport GETI, GETJ, IDX

# compile-time constants
# the amount of attempts in finding the best result for sort_a (as factor to the node count)
DEF SORT_A_ATTEMPTS = 5


# graph class
# is basically just a derived node, but with additional methods

cdef class Graph(Node):
  # constructor
  def __init__(Graph self):
    Node.__init__(self, self, 0)
    self.height = 0
    self.data_width = 0
    self.data_height = 0
  
  # builds the binary tree
  # receives the leaf data as parameter
  @cython.boundscheck(False)
  @cython.nonecheck(False)
  @cython.wraparound(False)
  cpdef build(Graph self, int[:, :] dataset):
    cdef double[:, ::1] cluster
    cdef int m, n
    cdef int i
    cdef object root
    if self.height > 0:
      raise TreeError("tree already exists")
    m = dataset.shape[0]
    n = dataset.shape[1]
    if m > INT_MAX:
      raise TreeError("unable to process more data entries than {0}".format(INT_MAX))
    self.height = <int>ceil(log2(<double>m))
    # copying the dataset
    self.data = <int*>malloc(<int>m*n*sizeof(int))
    if self.data == NULL:
      self.height = 0
      raise MemoryError()
    for i in prange(m, nogil=True):
      memcpy(self.data + i * n, &(dataset[i, 0]), n*sizeof(int))
    self.data_height = m
    self.data_width = n
    # building the distances matrix (see below)
    self.build_distances_matrix()
    # clustering all leaves
    cluster = self.build_cluster()
    # inserting all leaves
    root = to_tree(cluster)
    self.id = root.id
    self.build_from_cluster(self, root)

  cdef void build_from_cluster(Graph self, Node node, object cluster):
    cdef Node n
    if cluster.left is not None:
      n = self.create_node(cluster.left)
      node.set_left(n)
      self.build_from_cluster(node.left, cluster.left)
    if cluster.right is not None:
      n = self.create_node(cluster.right)
      node.set_right(n)
      self.build_from_cluster(node.right, cluster.right)
      
  cdef inline Node create_node(Graph self, object cluster):
    cdef int i
    cdef Node n = Node(self, cluster.id)
    if cluster.is_leaf():
      i = cluster.id
      n.set_data(self.data + i * self.data_width)
    return n

  # cleans the graph from all children
  cpdef clear(Graph self):
    Node.detach_children(self)
    self.height = 0
    self.data_height = 0
    self.data_width = 0
    if self.data != NULL:
      free(<void*>self.data)
      self.data = NULL

  # destructor
  # frees unneeded memory
  def __dealloc__(Graph self):
    if self.data != NULL:
      free(<void*>self.data)

  # builds the distance matrix
  # the distance matrix is a triangular matrix, which contains
  # all possible distances between the leaves
  cdef void build_distances_matrix(Graph self):
    cdef int m = self.data_height
    cdef int n = self.data_width
    self.distances = pdist(<int[:m, :n]>self.data, 'euclidean')

  # copies all datasets within the leaves together and returns them
  @cython.boundscheck(False)
  @cython.nonecheck(False)
  @cython.wraparound(False)
  cpdef get_data(Graph self):
    cdef int i
    cdef int offset
    cdef list leaves = self.get_leaves()
    cdef int m = self.data_height
    cdef int n = self.data_width
    cdef Node leaf
    cdef int *data = <int*>malloc(m*n*sizeof(int))
    if data == NULL:
      raise MemoryError()
    for i in xrange(m):
      leaf = leaves[i]
      offset = i*n
      memcpy(data + offset, leaf.data, n*sizeof(int))
    cdef int[:, ::1] mem = (<int[:m, :n]>data).copy()
    free(<void*>data)
    return mem

  # calculates the distances of all pairs of leaves
  cpdef get_distance(Graph self):
    cdef list nodes = self.get_leaves()
    cdef double dist = 0
    cdef int i
    cdef int n = self.data_height
    cdef Node node_a, node_b
    for i in xrange(1, n - 2, 2):
      node_a = nodes[i]
      node_b = nodes[i+1]
      dist += self.distances[IDX(node_a.id, node_b.id, n)]
    return dist

  # clustering the tree
  cdef double[:, ::1] build_cluster(Graph self):
    return linkage(self.distances, method='single', metric='euclidean')
    
  # the second heuristics (by Ziv Bar-Joseph et al.)
  cpdef sort_b(Graph self):
    cdef dict S = {}
    # first matrix calculation
    self.sort_b_rec2(self, S)
    # complete ordering
    self.sort_b_rec1(self, S)

  cdef double sort_b_rec2(Graph self, Node v, dict S):
    cdef double min, score, o_min, left_score, right_score
    cdef list L, R, LL, LR, RL, RR, TL, TR
    cdef Node l, r, u, w, m, k, l_min, r_min
    cdef unsigned int i, j, I, J, ii, jj
    if v.is_leaf():
      S[v.id, v.id, v.id] = 0
      return 0
    L = v.left.get_leaves()
    R = v.right.get_leaves()
    if not v.left.left is None:
      LL = v.left.left.get_leaves()
    else:
      LL = v.left.get_leaves()
    if not v.left.right is None:
      LR = v.left.right.get_leaves()
    else:
      LR = v.left.get_leaves()
    if not v.right.left is None:
      RL = v.right.left.get_leaves()
    else:
      RL = v.right.get_leaves()
    if not v.right.right is None:
      RR = v.right.right.get_leaves()
    else:
      RR = v.right.get_leaves()
    o_min = DBL_MAX
    left_score = self.sort_b_rec2(v.left, S)
    right_score = self.sort_b_rec2(v.right, S)
    for i in xrange(len(L)):
      l = L[i]
      for j in xrange(len(R)):
        r = R[j]
        S[v.left.id, l.id, r.id] = left_score
        S[v.right.id, l.id, r.id] = right_score
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
                  S[v.left.id, u.id, m.id] = 0
                if w == k:
                  S[v.right.id, w.id, k.id] = 0
                score = S[v.left.id, u.id, m.id] + S[v.right.id, w.id, k.id] + self.distances[IDX(m.id, k.id, self.data_width)]
                if score < min:
                  min = score
                  if min < o_min:
                    o_min = min
                    l_min = l
                    r_min = r
            S[v.id, u.id, w.id] = S[v.id, w.id, u.id] = min
    return <double>S[v.id, l_min.id, r_min.id]

  cdef void sort_b_rec1(Graph self, Node v, dict S):
    cdef double min, tmp
    cdef list L, R, RL, LR
    cdef Node u, w
    cdef object products, p
    if v.is_leaf():
      return
    L = v.left.get_leaves()
    R = v.right.get_leaves()
    products = product(L, R)
    min = DBL_MAX
    for p in products:
      tmp = S[v.id, (<Node>p[0]).id, (<Node>p[1]).id]
      if tmp < min:
        min = tmp
        u = p[0]
        w = p[1]
    v.rotate_until_bottom_left_node(u)
    v.rotate_until_bottom_right_node(w)
    self.sort_b_rec1(v.left, S)
    self.sort_b_rec1(v.right, S)

  # no heuristics, just for reference
  cpdef sort_scipy(Graph self):
    cdef double[:, ::1] cluster
    cdef double[:, ::1] ordered
    if SCIPY_ORDERING == False:
      raise NotAvailableError("scipy doesn't yet support optimal leaf ordering. update to the latest scipy version to enable this functionality.")
    cluster = linkage(self.distances, method='single', metric='euclidean')
    ordered = optimal_leaf_ordering(cluster, self.distances)
    self.detach_children()
    self.build_from_cluster(self, to_tree(ordered))

  cpdef sort_a(Graph self):
    cdef int *current_rotations
    cdef int *min_rotations
    cdef list nodes = self.get_nodes()
    cdef Node n
    cdef int node_count = len(nodes)
    cdef int leaf_count = len(self.get_leaves())
    cdef double distance
    cdef double min_distance = DBL_MAX
    cdef unsigned int i, j, r
    min_rotations = <int*>malloc(node_count * sizeof(int))
    if min_rotations == NULL:
      raise MemoryError()
    current_rotations = <int*>malloc(node_count * sizeof(int))
    if current_rotations == NULL:
      free(<void*>min_rotations)
      raise MemoryError()
    memset(min_rotations, 0, node_count * sizeof(int))
    memset(current_rotations, 0, node_count * sizeof(int))
    srand(time(NULL))
    for i in xrange(node_count * SORT_A_ATTEMPTS):
      for j in xrange(node_count):
        r = rand()%2
        if r == 1:
          n = nodes[j]
          n.rotate()
          current_rotations[n.id - leaf_count] = 1
      distance = self.get_distance()
      if distance < min_distance:
        memcpy(min_rotations, current_rotations, node_count * sizeof(int))
        min_distance = distance
      # reverting the changes
      for j in xrange(node_count):
        n = nodes[j]
        if current_rotations[n.id - leaf_count] == 1:
          n.rotate()
      memset(current_rotations, 0, node_count * sizeof(int))
    # we now know the best attempt, we rotate until we reach it
    for i in xrange(node_count):
      n = nodes[i]
      if min_rotations[n.id - leaf_count] == 1:
        n.rotate()
    free(<void*>min_rotations)
    free(<void*>current_rotations)
