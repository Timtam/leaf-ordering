import os
import os.path

from ..exceptions import PGMError

cimport cython
from cython.parallel cimport prange
from libc.stdio cimport FILE, fclose, fopen, fwrite, snprintf, sprintf
from libc.stdlib cimport free, malloc

# the PGMWriter class
# writes data to a valid pgm file

cdef class PGMWriter(object):
  cdef readonly int maximum_gray

  # constructor
  # accepts a value as maximum gray value (default 65536)
  def __cinit__(PGMWriter self, int maximum_gray = 65536):
    self.maximum_gray = maximum_gray
  
  # writes the data parameter into a file called filename
  @cython.wraparound(False)
  @cython.boundscheck(False)
  cpdef write(PGMWriter self, char *filename, int[:, :] data):
    cdef int data_size
    cdef int i, j
    cdef char *buf
    cdef FILE *file
    self.validate(data)
    if not os.path.exists(os.path.dirname(os.path.abspath(filename))):
      os.makedirs(os.path.dirname(os.path.abspath(filename)))
    data_size = self.get_total_string_length(data)
    buf = <char*>malloc(data_size)
    if buf == NULL:
      raise MemoryError()
    file = fopen(filename, "w")
    if file == NULL:
      free(<void*>buf)
      raise PGMError("unable to open writable file")
    buf += sprintf(buf, "P2\n%d %d\n%d\n", data.shape[0], data.shape[1], self.maximum_gray)
    for j in xrange(data.shape[1]):
      for i in xrange(data.shape[0]):
        buf += sprintf(buf, "%d ", data[i,j])
      buf -= 1
      buf += sprintf(buf, "\n")
    buf -= data_size - 1
    fwrite(buf, data_size, 1, file)
    fclose(file)
    free(<void*>buf)

  # calculates the required size needed to store the data buffer
  @cython.wraparound(False)
  @cython.boundscheck(False)
  cdef int get_data_string_length(PGMWriter self, int[:, :] data):
    cdef int size = 0
    cdef int m = data.shape[0]
    cdef int n = data.shape[1]
    cdef int i, j
    for i in prange(m, nogil=True):
      for j in xrange(n):
        size += snprintf(NULL, 0, "%d", data[i,j]) + 1
    return size + 1

  # gets the total string length required to store the pgm file as a whole
  cdef int get_total_string_length(PGMWriter self, int[:, :] data):
    cdef int size = 3 # magic bytes + line break
    size += snprintf(NULL, 0, "%d", data.shape[0])+1 # columns + line break
    size += snprintf(NULL, 0, "%d", data.shape[1])+1 # rows + line break
    size += snprintf(NULL, 0, "%d", self.maximum_gray)+1 # maximum gray value + line break
    size += self.get_data_string_length(data)
    return size * sizeof(char)

  # validates the pgm data
  cpdef validate(PGMWriter self, int[:, :] data):
    cdef int i, j
    for i in xrange(data.shape[0]):
      for j in xrange(data.shape[1]):
        if data[i,j] < 0 or data[i,j] > self.maximum_gray:
          raise PGMError("pixel value at {0}, {1} out of range: {2}".format(i, j, data[i,j]))
