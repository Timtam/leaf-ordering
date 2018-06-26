# cython: profile=True
# distutils: define_macros=CYTHON_TRACE_NOGIL=1
cimport cython

# a node class, which implements basic functionalities

cdef class Node:

  # constructor
  # taking its root as parameter
  def __init__(Node self, Node root, unsigned int id):
    self.left = None
    self.right = None
    self.previous = None
    self.level = 0
    self.data = NULL
    self.id = id
    self.set_root(root)

  # checks if this node is a leaf
  cpdef bint is_leaf(Node self):
    return self.left is None and self.right is None

  # checks if this node is the root node
  cpdef bint is_root(Node self):
    return self.previous is None

  # those three methods set the left child, the right child and the parent
  cdef void set_left(Node self, Node l):
    self.left = l
    if not l is None:
      l.set_previous(self)

  cdef void set_right(Node self, Node r):
    self.right = r
    if not r is None:
      r.set_previous(self)

  # set_previous() also calculates the depth level of this child
  cdef void set_previous(Node self, Node p):
    self.level = 0
    self.previous = p
    while p is not None:
      self.level += 1
      p = p.previous
    
  # sets the dataset for this node
  cdef void set_data(Node self, int *data):
    self.data = data

  # returns the overall amount of this node's children
  cpdef unsigned int get_child_count(Node self):
    return len(self.get_children())

  # exchanges both child nodes
  cdef void rotate(Node self):
    cdef Node tmp = self.left
    self.set_left(self.right)
    self.set_right(tmp)

  # detaches all child nodes recursively and cleans them properly
  # used by graph.clear()
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

  # sets the root node (used by constructor)
  cdef void set_root(Node self, Node root):
    self.root = root

  # get the bottom-left-most child (leaf) from this node
  cdef Node get_bottom_left_node(Node self):
    if self.is_leaf():
      return self
    return self.left.get_bottom_left_node()

  # get the bottom-right-most child (leaf) from this node
  cdef Node get_bottom_right_node(Node self):
    if self.is_leaf():
      return self
    return self.right.get_bottom_left_node()

  cpdef list get_children(Node self):
    cdef list l = []
    if self.is_leaf():
      return []
    l.append(self.left)
    l += self.left.get_children()
    l.append(self.right)
    l += self.right.get_children()
    return l

  # backtracks until it finds the parent with the given level
  cpdef Node get_parent_at_level(Node self, int level):
    if self.previous.level != level:
      return self.previous.get_parent_at_level(level)
    return self.previous

  # those methods rotate the (sub)tree until the given node is the bottom left (or right) one
  cdef void rotate_until_bottom_left_node(Node self, Node new_left):
    cdef Node next_parent
    if new_left.level == self.level + 1:
      if not self.left is new_left:
        self.rotate()
    else:
      next_parent = new_left.get_parent_at_level(self.level + 1)
      if not self.left is next_parent:
        self.rotate()
      next_parent.rotate_until_bottom_left_node(new_left)

  cdef void rotate_until_bottom_right_node(Node self, Node new_right):
    cdef Node next_parent
    if new_right.level == self.level + 1:
      if not self.right is new_right:
        self.rotate()
    else:
      next_parent = new_right.get_parent_at_level(self.level + 1)
      if not self.right is next_parent:
        self.rotate()
      next_parent.rotate_until_bottom_right_node(new_right)

  def __repr__(Node self):
    if self.is_leaf():
      return "Leaf {0}".format(self.id)
    return "Node {0}".format(self.id)

  cpdef list get_leaves(Node self):
    cdef list children = self.get_children()
    if self.is_leaf():
      return [self]
    return [c for c in children if c.is_leaf()]

  cpdef list get_nodes(Node self):
    if self.is_leaf():
      return []
    return self.left.get_nodes() + self.right.get_nodes() + [self]

  cpdef Node get_child(Node self, int id):
    if self.id == id:
      return self
    if self.is_leaf():
      return None
    return self.left.get_child(id) or self.right.get_child(id)
