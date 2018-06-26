# header-file for main graph
# graph.pyx is more important and contains the actual implementation
from .node cimport Node

cdef class Graph(Node):
  cdef readonly int height
  cdef double[:] distances
  cdef int data_height
  cdef int data_width  

  cpdef build(Graph self, int[:, :] dataset)
  cdef void build_from_cluster(Graph self, Node node, object cluster)
  cdef inline Node create_node(Graph self, object cluster)
  cpdef clear(Graph self)
  cdef void build_distances_matrix(Graph self)
  cpdef sort_scipy(Graph self)
  cpdef sort_a(Graph self)
  cpdef sort_b(Graph self)
  cdef void sort_b_rec1(Graph self, Node v, dict S)
  cdef double sort_b_rec2(Graph self, Node v, dict S)
  cpdef get_data(Graph self)
  cpdef get_distance(Graph self)
  cdef double[:, ::1] build_cluster(Graph self)
