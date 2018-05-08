import os
import os.path

from ..exceptions import PGMError

cimport cython
from libc.stdio cimport FILE, fclose, fopen, fwrite, snprintf, sprintf
from libc.stdlib cimport free, malloc

cdef extern from "<errno.h>":
  int errno
  int ENOENT

cdef extern from "<unistd.h>":
  int F_OK
  int R_OK
  int W_OK
  int X_OK
  int access(const char *pathname, int mode)

cdef class PGMWriter(object):
  cdef readonly int maximum_gray
  def __cinit__(PGMWriter self, int maximum_gray = 65536):
    self.maximum_gray = maximum_gray
  
  @cython.wraparound(False)
  @cython.boundscheck(False)
  cpdef write(PGMWriter self, char *filename, int[:, :] data):
    cdef int a
    cdef int data_size
    cdef int i, j
    cdef char *buf
    cdef FILE *file
    if os.path.exists(filename):
      a = access(filename, W_OK)
      if a == -1:
        raise PGMError("unable to write to file. errno: {0}".format(errno))
    self.validate(data)
    if not os.path.exists(os.path.dirname(os.path.abspath(filename))):
      os.makedirs(os.path.dirname(os.path.abspath(filename)))
    data_size = self.get_total_string_length(data)
    buf = <char*>malloc(data_size)
    if buf == NULL:
      raise PGMError("memory allocation error")
    buf += sprintf(buf, "P2\n%d %d\n%d\n", data.shape[0], data.shape[1], self.maximum_gray)
    for j in xrange(data.shape[1]):
      for i in xrange(data.shape[0]):
        buf += sprintf(buf, "%d ", data[i][j])
      buf -= 1
      buf += sprintf(buf, "\n")
    buf -= data_size
    file = fopen(filename, "w")
    if file == NULL:
      free(<void*>buf)
      raise PGMError("unable to open writable file")
    fwrite(buf, data_size, 1, file)
    fclose(file)
    free(<void*>buf)

  @cython.wraparound(False)
  @cython.boundscheck(False)
  cdef int get_data_string_length(PGMWriter self, int[:, :] data):
    cdef int size = 0
    cdef int i, j
    for i in xrange(data.shape[0]):
      for j in xrange(data.shape[1]):
        size += snprintf(NULL, 0, "%d", data[i][j]) + 1
    return size

  cdef int get_total_string_length(PGMWriter self, int[:, :] data):
    cdef int size = 3 # magic bytes + line break
    size += snprintf(NULL, 0, "%d", data.shape[0])+1 # columns + line break
    size += snprintf(NULL, 0, "%d", data.shape[1])+1 # lines + line break
    size += snprintf(NULL, 0, "%d", self.maximum_gray)+1 # maximum gray value + line break
    size += self.get_data_string_length(data)
    return size * sizeof(char)

  cpdef validate(PGMWriter self, int[:, :] data):
    cdef int i, j
    for i in xrange(data.shape[0]):
      for j in xrange(data.shape[1]):
        if data[i][j] < 0 or data[i][j] > self.maximum_gray:
          raise PGMError("pixel value at {0}, {1} out of range: {2}".format(i, j, data[i][j]))
