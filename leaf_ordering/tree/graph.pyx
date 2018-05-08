from ..exceptions import TreeError

from libc.limits cimport UINT_MAX
from libc.math cimport ceil, log2

from .node cimport Node

cdef class Graph(Node):
  def __init__(Graph self):
    super().__init__(self)
    self.height = 0
  
  cpdef build(Graph self, int[:, :] dataset):
    cdef unsigned int i
    if self.height > 0:
      raise TreeError("tree already exists")
    if dataset.shape[0] > UINT_MAX:
      raise TreeError("unable to process more data entries than {0}".format(UINT_MAX))
    self.dataset = dataset.copy()
    self.height = <int>ceil(log2(dataset.shape[0]))
    for i in xrange(dataset.shape[0]):
      self.insert_at(i)

  cdef void insert_at(Graph self, unsigned int ind):
    cdef int i
    cdef int pos
    cdef Node current = self
    cdef Node next
    for i in xrange(self.height - 1, -1, -1):
      pos = (ind>>i)&0x1
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
    current.set_data(self.dataset[ind])
