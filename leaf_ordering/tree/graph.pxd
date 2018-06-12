# header-file for main graph
# graph.pyx is more important and contains the actual implementation
from .node cimport Node

cdef class Graph(Node):
  cdef readonly int height
  cdef double *distances
  cdef int data_height
  cdef int data_width  
  cdef unsigned int id_offset

  cpdef build(Graph self, int[:, :] dataset)
  cdef void insert_at(Graph self, int where, int *what)
  cpdef clear(Graph self)
  cdef void build_distances_matrix(Graph self)
  cpdef sort_a(Graph self)
  cpdef sort_b(Graph self)
  cdef double sort_b_rec(Graph self, Node v, dict S)
  cpdef get_data(Graph self)
  cpdef get_distance(Graph self)
  cdef void build_cluster(Graph self)
