from ..exceptions import TreeError

cimport cython
from cython.parallel cimport prange
from libc.limits cimport INT_MAX
from libc.math cimport ceil, log2, pow, sqrt
from libc.stdlib cimport malloc, free

from .node cimport Node

cdef class Graph(Node):
  def __init__(Graph self):
    Node.__init__(self, self)
    self.height = 0
    self.distances = None
  
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

  @cython.boundscheck(False)
  @cython.wraparound(False)
  @cython.nonecheck(False)
  cdef void build_distances_matrix(Graph self, int[:, :] dataset):
    cdef int n = dataset.shape[0]
    cdef double * m = <double*>malloc(n * n * sizeof(double))
    cdef int i, j, k
    cdef double d
    if m == NULL:
      raise TreeError("memory allocation error")
    self.distances = <double[:n, :n]>m
    for i in prange(n, nogil=True):
      for j in xrange(n):
        if i == j:
          self.distances[i,j] = .0
        d = 0
        for k in xrange(dataset.shape[1]):
          d = d + pow(dataset[j,k]-dataset[i,k], 2)
        self.distances[i,j] = sqrt(d)
