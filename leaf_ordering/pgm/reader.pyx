from leaf_ordering.exceptions import PGMEOF, PGMError

cimport cython
from libc.stdio cimport FILE, fopen, fclose, fread, fseek, ftell, rewind, SEEK_END
from libc.stdlib cimport malloc, free, strtol
from libc.string cimport strchr

cdef class PGMReader:
  cdef char *data
  cdef long data_size
  cdef char *p_ptr
  cdef readonly int width
  cdef readonly height
  cdef readonly int maximum_gray

  def __cinit__(PGMReader self, char *filename):
    cdef FILE *file = fopen(filename, "r")
    if file == NULL:
      raise PGMError("File not found")
    fseek(file, 0, SEEK_END)
    self.data_size = ftell(file)
    rewind(file)
    self.data = <char*>malloc(sizeof(char)*self.data_size)
    if self.data == NULL:
      raise PGMError("Unable to read file: memory allocation error")
    fread(self.data, self.data_size, 1, file)
    fclose(file)
    self.width = 0
    self.height = 0
    self.maximum_gray = 0
    
  # returns the next number, skipping comments if available
  cdef inline long get_next_number(PGMReader self) nogil:
    cdef char *endptr
    if self.p_ptr[0] == '#':
      self.p_ptr = strchr(self.p_ptr, '\n') + 1
    cdef long res = strtol(self.p_ptr, &endptr, 10)
    self.p_ptr = endptr + 1
    return res

  cdef object parse_header(PGMReader self):
    if self.p_ptr[1] != '2':
      raise PGMError("Only portable graymaps in ascii-format are supported")
    self.p_ptr += 3
    cdef long width = self.get_next_number()
    if width == 0:
      raise PGMError("invalid width: 0")
    self.width = width
    cdef long height = self.get_next_number()
    if height == 0:
      raise PGMError("invalid height: 0")
    self.height = height
    maxval = self.get_next_number()
    if maxval <= 0 or maxval > 65536:
      raise PGMError("invalid maximum gray value, must be from 1 to 65536, but is "+maxval)
    self.maximum_gray = maxval

  @cython.boundscheck(False)
  @cython.wraparound(False)
  cdef int[:,:] parse_body(PGMReader self):
    cdef int *buf = <int*>malloc(sizeof(int) * self.width * self.height)
    cdef int col = 0
    cdef int row = 0
    cdef long tmp
    while True:
      if self.p_ptr - self.data == self.data_size + 1:
        raise PGMError("EOF occurred too early")
      tmp = self.get_next_number()
      if tmp < 0 or tmp > self.maximum_gray:
        raise PGMError("pixel at row {row}, column {col} exceeded range from 0 to {gray}: {pixel}".format(col=col, row=row, pixel=tmp, gray=self.maximum_gray))
      buf[col * self.height + row] = tmp
      col += 1
      if col == self.width:
        row += 1
        col = 0
        if row == self.height:
          break
    cdef int[:, ::1] columns = (<int[:self.width, :self.height]>buf).copy()
    free(<void*>buf)
    return columns

  cpdef int[:, :] read(PGMReader self):
    self.p_ptr = self.data
    self.parse_header()
    return self.parse_body()


  def __dealloc__(PGMReader self):
    if self.data != NULL:
      free(<void*>self.data)
