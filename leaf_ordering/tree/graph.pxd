from .node cimport Node

cdef class Graph(Node):
  cdef readonly int height
  cdef double *distances
  
  cpdef build(Graph self, int[:, :] dataset)
  cdef void insert_at(Graph self, int where, int[:] what)
  cpdef clear(Graph self)
  cdef void build_distances_matrix(Graph self, int[:, :] dataset)
