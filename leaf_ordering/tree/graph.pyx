from ..exceptions import TreeError

cimport cython
from libc.limits cimport UINT_MAX
from libc.math cimport ceil, log2, pow, sqrt
from libc.stdlib cimport malloc, free

from .node cimport Node

cdef class Graph(Node):
  def __init__(Graph self):
    Node.__init__(self, self)
    self.height = 0
    self.distances = None
  
  cpdef build(Graph self, int[:, :] dataset):
    cdef unsigned int i
    if self.height > 0:
      raise TreeError("tree already exists")
    if dataset.shape[0] > UINT_MAX:
      raise TreeError("unable to process more data entries than {0}".format(UINT_MAX))
    self.height = <int>ceil(log2(dataset.shape[0]))
    self.build_distances_matrix(dataset)
    for i in xrange(dataset.shape[0]):
      self.insert_at(i, dataset[i])

  cdef void insert_at(Graph self, unsigned int where, int[:] what):
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
    current.set_data(what)

  cpdef clear(Graph self):
    Node.detach_children(self)
    self.height = 0
    if not self.distances is None:
      free(<void*>&self.distances[0,0])
      self.distances = None

  def __dealloc__(Graph self):
    if not self.distances is None:
      free(<void*>&self.distances[0,0])

  cdef void build_distances_matrix(Graph self, int[:, :] dataset):
    cdef double * m = <double*>malloc(dataset.shape[0] * dataset.shape[0] * sizeof(double))
    cdef unsigned int i, j
    if m == NULL:
      raise TreeError("memory allocation error")
    self.distances = <double[:dataset.shape[0], :dataset.shape[0]]>m
    for i in xrange(dataset.shape[0]):
      for j in xrange(dataset.shape[0]):
        if i == j:
          self.distances[i,j] = .0
        self.distances[i,j] = Graph.get_euklid_distance(dataset[i], dataset[j])

  @cython.boundscheck(False)
  @cython.wraparound(False)
  @cython.nonecheck(False)
  @staticmethod
  cdef inline double get_euklid_distance(int[:] l, int[:] r):
    cdef double d = 0
    cdef int i
    for i in xrange(l.size):
      d += pow(r[i]-l[i], 2)
    return sqrt(d)
