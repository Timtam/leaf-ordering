from ..exceptions import TreeError

cimport cython

from libc.math cimport pow, sqrt

cdef class Node:

  def __init__(Node self, Node root):
    self.left = None
    self.right = None
    self.previous = None
    self.level = 0
    self.set_root(root)

  cpdef bint is_leaf(Node self):
    return self.left is None and self.right is None

  cpdef bint is_root(Node self):
    return self.previous is None

  cpdef double get_distance(Node self, Node t):
    if not self.is_leaf() or not t.is_leaf():
      raise TreeError("cannot get distance from leaf")
    if self.data.size != t.data.size:
      raise TreeError("data vectors don't have the same length")
    return self.get_euklid_distance(self.data, t.data)

  @cython.boundscheck(False)
  @cython.wraparound(False)
  @cython.nonecheck(False)
  cdef inline double get_euklid_distance(Node self, int[:] l, int[:] r):
    cdef double d = 0
    cdef int i
    for i in xrange(l.size):
      d += pow(r[i]-l[i], 2)
    return sqrt(d)

  cpdef void set_left(Node self, Node l):
    self.left = l
    l.set_previous(self)

  cpdef void set_right(Node self, Node r):
    self.right = r
    r.set_previous(self)

  cpdef void set_previous(Node self, Node p):
    self.level = 0
    self.previous = p
    while p is not None:
      self.level += 1
      p = p.previous
    
  cpdef set_data(Node self, int[:] data):
    self.data = data

  cpdef unsigned int get_child_count(Node self):
    cdef unsigned int size = 0
    if not self.left is None:
      size += 1 + self.left.get_child_count()
    if not self.right is None:
      size += 1 + self.right.get_child_count()
    return size

  cpdef void rotate(Node self):
    cdef Node tmp = self.left
    self.set_left(self.right)
    self.set_right(tmp)

  cdef void detach_children(Node self):
    if self.left is not None:
      self.left.clear()
      self.left.set_previous(None)
      self.left.set_root(None)
    if self.right is not None:
      self.right.clear()
      self.right.set_previous(None)
      self.right.set_root(None)
    self.left = None
    self.right = None

  cdef void set_root(Node self, Node root):
    self.root = root
