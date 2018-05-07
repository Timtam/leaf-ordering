cdef class Node:
  cdef readonly Node left
  cdef readonly Node right
  cdef readonly Node previous
  cdef public int[:] data

  cpdef bint is_leaf(Node self)
  cpdef bint is_root(Node self)
  cpdef double get_distance(Node self)
  cdef inline double get_euklid_distance(Node self, int[:] l, int[:] r)
  cpdef void set_left(Node self, Node l)
  cpdef void set_right(Node self, Node r)
  cpdef void set_previous(Node self, Node p)
