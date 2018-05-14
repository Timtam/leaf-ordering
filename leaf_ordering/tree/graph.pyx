from ..exceptions import TreeError

cimport cython
from cython.parallel cimport prange
from libc.limits cimport INT_MAX
from libc.math cimport ceil, log2, pow, sqrt
from libc.stdlib cimport malloc, free

from .node cimport Node

cdef extern from * nogil:
  """
  #define IDX(i,j) ((int)fmax(i, j)*((int)fmax(i, j)+1)/2+(int)fmin(i, j))
  double* min_element(double *start, double *end)
  {
    if (start == end) return end;

    double *min = start++;
    for (; start != end; ++start)
      if (*start < *min) min = start;

    return min;
  }
  """
  int IDX(int i, int j)
  double *min_element(double *start, double*end)

cdef class Graph(Node):
  def __init__(Graph self):
    Node.__init__(self, self)
    self.height = 0
  
  cpdef build(Graph self, int[:, :] dataset):
    cdef int n = dataset.shape[0]
    cdef int i
    if self.height > 0:
      raise TreeError("tree already exists")
    if n > INT_MAX:
      raise TreeError("unable to process more data entries than {0}".format(INT_MAX))
    self.height = <int>ceil(log2(n))
    self.build_distances_matrix(dataset)
    for i in xrange(n):
      self.insert_at(i, dataset[i])

  cdef void insert_at(Graph self, int where, int[:] what):
    cdef int i
    cdef int pos
    cdef Node current = self
    cdef Node next
    for i in xrange(self.height - 1, -1, -1):
      pos = (where>>i)&0x1
      if pos == 0:
        if current.left is None:
          next = Node(self)
          current.set_left(next)
        current = current.left
      elif pos == 1:
        if current.right is None:
          next = Node(self)
          current.set_right(next)
        current = current.right
    current.set_data(what, where)

  cpdef clear(Graph self):
    Node.detach_children(self)
    self.height = 0
    if self.distances != NULL:
      free(<void*>self.distances)
      self.distances = NULL

  def __dealloc__(Graph self):
    if self.distances != NULL:
      free(<void*>self.distances)

  @cython.boundscheck(False)
  @cython.wraparound(False)
  @cython.nonecheck(False)
  cdef void build_distances_matrix(Graph self, int[:, :] dataset):
    cdef int n = dataset.shape[0]
    self.distances = <double*>malloc((n+1)*n/2*sizeof(double))
    cdef int i, j, k
    cdef double d
    if self.distances == NULL:
      raise TreeError("memory allocation error")
    for i in prange(n, nogil=True):
      for j in xrange(i+1):
        if i == j:
          self.distances[IDX(i,j)] = .0
        d = 0
        for k in xrange(dataset.shape[1]):
          d = d + pow(dataset[j,k]-dataset[i,k], 2)
        self.distances[IDX(i,j)] = sqrt(d)

  cpdef sort_a(Graph self):
    cdef double[4] dist;
    cdef double* min_dist
    cdef double dist_diff
    cdef int i
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
        dist[0] = self.distances[IDX(leaf_a.data_offset, leaf_b.data_offset)]
        # b
        leaf_a = node_a.get_bottom_left_node()
        dist[1] = self.distances[IDX(leaf_a.data_offset, leaf_b.data_offset)]
        if j > 0:
          dist[1] += dist_diff
        # c
        leaf_b = node_b.get_bottom_right_node()
        dist[2] = self.distances[IDX(leaf_a.data_offset, leaf_b.data_offset)]
        if j > 0:
          dist[2] += dist_diff
        # d
        leaf_a = node_a.get_bottom_right_node()
        dist[3] = self.distances[IDX(leaf_a.data_offset, leaf_b.data_offset)]
        # comparing and rotating
        min_dist = min_element(dist, dist + 4)
        if min_dist - dist == 1 or min_dist - dist == 2:
          node_a.rotate()
        if min_dist - dist == 2 or min_dist - dist == 4:
          node_b.rotate()
        # calculating distance difference
        leaf_b = node_b.get_bottom_right_node()
        dist_diff = self.distances[IDX(leaf_a.data_offset, leaf_b.data_offset)] - dist[0]
