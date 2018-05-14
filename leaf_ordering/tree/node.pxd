cdef class Node:
  cdef readonly Node left
  cdef readonly Node right
  cdef readonly Node previous
  cdef readonly int[:] data
  cdef readonly Node root
  cdef readonly int level

  cpdef bint is_leaf(Node self)
  cpdef bint is_root(Node self)
  cdef void set_left(Node self, Node l)
  cdef void set_right(Node self, Node r)
  cdef void set_previous(Node self, Node p)
  cdef void set_data(Node self, int[:] data)
  cpdef unsigned int get_child_count(Node self)
  cdef void rotate(Node self)
  cdef void detach_children(Node self)
  cdef void set_root(Node self, Node root)
  cpdef list get_children_at_level(Node self, int level)
