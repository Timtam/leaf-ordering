cdef class Node:
  cdef readonly Node left
  cdef readonly Node right
  cdef readonly Node previous
  cdef readonly int[:] data
  cdef readonly Node root
  cdef readonly int level

  cpdef bint is_leaf(Node self)
  cpdef bint is_root(Node self)
  cpdef void set_left(Node self, Node l)
  cpdef void set_right(Node self, Node r)
  cpdef void set_previous(Node self, Node p)
  cpdef set_data(Node self, int[:] data)
  cpdef unsigned int get_child_count(Node self)
  cpdef void rotate(Node self)
  cdef void detach_children(Node self)
  cdef void set_root(Node self, Node root)
