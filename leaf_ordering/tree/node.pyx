from ..exceptions import TreeError

cimport cython

cdef class Node:

  def __init__(Node self, Node root):
    self.left = None
    self.right = None
    self.previous = None
    self.level = 0
    self.data = None
    self.set_root(root)

  cpdef bint is_leaf(Node self):
    return self.left is None and self.right is None

  cpdef bint is_root(Node self):
    return self.previous is None

  cdef void set_left(Node self, Node l):
    self.left = l
    l.set_previous(self)

  cdef void set_right(Node self, Node r):
    self.right = r
    r.set_previous(self)

  cdef void set_previous(Node self, Node p):
    self.level = 0
    self.previous = p
    while p is not None:
      self.level += 1
      p = p.previous
    
  cdef void set_data(Node self, int[:] data, int data_offset):
    self.data = data
    self.data_offset = data_offset

  cpdef unsigned int get_child_count(Node self):
    cdef unsigned int size = 0
    if not self.left is None:
      size += 1 + self.left.get_child_count()
    if not self.right is None:
      size += 1 + self.right.get_child_count()
    return size

  cdef void rotate(Node self):
    cdef Node tmp = self.left
    self.set_left(self.right)
    self.set_right(tmp)

  cdef void detach_children(Node self):
    if self.left is not None:
      self.left.detach_children()
      self.left.set_previous(None)
      self.left.set_root(None)
    if self.right is not None:
      self.right.detach_children()
      self.right.set_previous(None)
      self.right.set_root(None)
    self.left = None
    self.right = None

  cdef void set_root(Node self, Node root):
    self.root = root

  cpdef list get_children_at_level(Node self, int level):
    cdef list nodes = []
    if self.level == level:
      return [self]
    if self.level > level or self.is_leaf():
      return []
    if not self.left is None:
      nodes += self.left.get_children_at_level(level)
    if not self.right is None:
      nodes += self.right.get_children_at_level(level)
    return nodes

  cdef Node get_bottom_left_node(Node self):
    if self.is_leaf():
      return self
    if not self.left is None:
      return self.left.get_bottom_left_node()
    return self.right.get_bottom_left_node()

  cdef Node get_bottom_right_node(Node self):
    if self.is_leaf():
      return self
    if not self.right is None:
      return self.right.get_bottom_left_node()
    return self.left.get_bottom_right_node()
