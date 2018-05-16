try:
  from Queue import Queue
except ImportError:
  from queue import Queue

from libc.math cimport pow

from .graph cimport Graph
from .node cimport Node
from ..exceptions import ValidatorError

cdef class Validator(object):
  cdef object open, close
  
  def __init__(Validator self):
    pass
  
  # validation for cycles in graph
  cpdef void check_cycle(Validator self, Graph graph):
    cdef Node left, right
    self.open = Queue(pow(2, graph.height))  # max elements: 2^height
    self.close = Queue(graph.get_child_count() + 1)  # max elements: number of
    #                                                  children + 1 (root)
    self.open.put_nowait(graph)
    
    # iteration over open queue (nodes that need to be checked)
    while not self.open.empty():
      
      node = self.open.get_nowait()
      if node in self.close.queue:
        raise ValidatorError("validator detected cycle in graph")
      
      # insert children if available and insert current node to close queue
      if node.left is not None:
        self.open.put_nowait(node.left)
      if node.right is not None:
        self.open.put_nowait(node.right)
      self.close.put_nowait(node)
