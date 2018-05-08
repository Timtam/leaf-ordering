from .node cimport Node

cdef class Graph(Node):
  cdef int[:, :] dataset
  cdef readonly int height
  
  cpdef build(Graph self, int[:, :] dataset)
  cdef void insert_at(Graph self, unsigned int ind)
