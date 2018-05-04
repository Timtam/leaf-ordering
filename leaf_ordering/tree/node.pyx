from leaf_ordering.exceptions import TreeError

cimport cython

from libc.math cimport pow, sqrt

cdef class Node:
  cdef readonly Node left
  cdef readonly Node right
  cdef readonly Node previous
  cdef public int[:] data

  def __init__(Node self, int[:] data = None):
    self.left = None
    self.right = None
    self.previous = None
    self.data = data

  cpdef bint is_leaf(Node self):
    return self.left is None and self.right is None

  cpdef bint is_root(Node self):
    return self.previous is None

  cpdef double get_distance(Node self):
    if self.is_leaf():
      raise TreeError("cannot get distance from leaf")
    if self.left.is_leaf() and self.right.is_leaf():
      if self.left.data.size != self.right.data.size:
        raise TreeError("data vectors don't have the same length")
      return self.get_euklid_distance(self.left.data, self.right.data)
    else:
      return self.left.get_distance() + self.right.get_distance()

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
    self.previous = p
