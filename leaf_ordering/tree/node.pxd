# the node header file
# node.pyx is much more interesting

cdef class Node:
  cdef readonly Node left
  cdef readonly Node right
  cdef readonly Node previous
  cdef int *data
  cdef readonly Node root
  cdef readonly int level
  cdef unsigned int id

  cdef inline bint _is_leaf(Node self)
  cdef inline bint _is_root(Node self)
  cdef void set_left(Node self, Node l)
  cdef void set_right(Node self, Node r)
  cdef void set_previous(Node self, Node p)
  cdef void set_data(Node self, int *data)
  cpdef unsigned int get_child_count(Node self)
  cdef void rotate(Node self)
  cdef void detach_children(Node self)
  cdef void set_root(Node self, Node root)
  cdef Node get_bottom_left_node(Node self)
  cdef Node get_bottom_right_node(Node self)
  cpdef list get_children(Node self)
  cpdef list get_leaves(Node self)
  cpdef Node get_parent_at_level(Node self, int level)
  cdef void rotate_until_bottom_left_node(Node self, Node new_left)
  cdef void rotate_until_bottom_right_node(Node self, Node new_right)
  cpdef list get_nodes(Node self)
  cpdef Node get_child(Node self, int id)
