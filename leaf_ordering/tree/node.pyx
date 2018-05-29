# cython: profile=True
# distutils: define_macros=CYTHON_TRACE_NOGIL=1
cimport cython

from .matrix cimport IDX
from libc.float cimport DBL_MAX

# a node class, which implements basic functionalities

cdef class Node:

  # constructor
  # taking its root as parameter
  def __init__(Node self, Node root, int branch_index):
    self.left = None
    self.right = None
    self.previous = None
    self.level = 0
    self.data = NULL
    self.branch_index = branch_index
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
  cdef void set_data(Node self, int *data, int leaf_index):
    self.data = data
    self.leaf_index = leaf_index

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

  # return all children at a specified depth level
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

  # get the bottom-left-most child (leaf) from this node
  cdef Node get_bottom_left_node(Node self):
    if self.is_leaf():
      return self
    if not self.left is None:
      return self.left.get_bottom_left_node()
    return self.right.get_bottom_left_node()

  # get the bottom-right-most child (leaf) from this node
  cdef Node get_bottom_right_node(Node self):
    if self.is_leaf():
      return self
    if not self.right is None:
      return self.right.get_bottom_left_node()
    return self.left.get_bottom_right_node()

  cpdef list get_children(Node self):
    cdef list l = []
    if self.is_leaf():
      return []
    if not self.left is None:
      l.append(self.left)
      l += self.left.get_children()
    if not self.right is None:
      l.append(self.right)
      l += self.right.get_children()
    return l

  # a recursive helper method for second heuristics
  @cython.boundscheck(False)
  @cython.wraparound(False)
  @cython.nonecheck(False)
  cdef void sort_b_rec(Node self, Node x, Node y, double[:, :] m_dist, double *dists):
    cdef Node v, w
    cdef list v_nodes, w_nodes
    cdef unsigned int vc, wc
    cdef unsigned int i, j
    cdef double tmp
    m_dist[self.branch_index, IDX(x.leaf_index, y.leaf_index)] = DBL_MAX
    self.rotate_until_bottom_left_node(x)
    self.rotate_until_bottom_right_node(y)
    if not self.right:
      return
    if not self.left:
      return
    v = self.left
    w = self.right
    v_nodes = v.get_children_at_level(self.root.height)
    w_nodes = w.get_children_at_level(self.root.height)
    vc = len(v_nodes)
    wc = len(w_nodes)
    for i in xrange(vc):
      if v_nodes[i] is x:
        continue
      for j in xrange(wc):
        if w_nodes[j] is y:
          continue
        v.rotate_until_bottom_left_node(x)
        v.rotate_until_bottom_right_node(v_nodes[i])
        w.rotate_until_bottom_left_node(w_nodes[j])
        w.rotate_until_bottom_right_node(y)
        if m_dist[v.branch_index, IDX(x.leaf_index, (<Node>v_nodes[i]).leaf_index)] == -1 and not v.is_leaf():
          v.sort_b_rec(x, <Node>v_nodes[i], m_dist, dists)
        if m_dist[w.branch_index, IDX((<Node>w_nodes[j]).leaf_index, y.leaf_index)] == -1 and not w.is_leaf():
          w.sort_b_rec(<Node>w_nodes[j], y, m_dist, dists)
        tmp = m_dist[v.branch_index, IDX(x.leaf_index, (<Node>v_nodes[i]).leaf_index)] + m_dist[w.branch_index, IDX((<Node>w_nodes[j]).leaf_index, y.leaf_index)] + dists[IDX((<Node>v_nodes[i]).leaf_index, (<Node>w_nodes[j]).leaf_index)]
        if tmp < m_dist[self.branch_index, IDX(x.leaf_index, y.leaf_index)]:
          m_dist[self.branch_index, IDX(x.leaf_index, y.leaf_index)] = tmp

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
