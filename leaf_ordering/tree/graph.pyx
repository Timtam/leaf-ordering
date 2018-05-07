from .node cimport Node

cdef class Graph(Node):
  cdef int[:, :] dataset
  def __init__(Graph self):
    super().__init__()
  
  def build(Graph self, int[:, :] dataset):
    self.dataset = dataset.copy()
