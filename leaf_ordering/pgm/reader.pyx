from leaf_ordering.exceptions import PGMEOF, PGMError

cimport cython
from libc.stdio cimport FILE, fopen, fclose, fread, fseek, ftell, rewind, SEEK_END
from libc.stdlib cimport malloc, free, strtol
from libc.string cimport strchr

# the PGMReader class
# reads pgm files and processes the contained data

cdef class PGMReader:
  cdef char *data
  cdef long data_size
  cdef char *p_ptr
  cdef int body_offset
  cdef readonly int width
  cdef readonly height
  cdef readonly int maximum_gray

  # constructor
  # accepts pgm filename to open the corresponding file
  def __cinit__(PGMReader self, char *filename):
    cdef FILE *file = fopen(filename, "r")
    if file == NULL:
      raise PGMError("File not found")
    # calculating file size
    fseek(file, 0, SEEK_END)
    self.data_size = ftell(file)
    rewind(file)
    # reading file to memory
    self.data = <char*>malloc(sizeof(char)*self.data_size)
    if self.data == NULL:
      raise MemoryError()
    fread(self.data, self.data_size, 1, file)
    fclose(file)
    # defining attributes and parsing header
    self.width = 0
    self.height = 0
    self.maximum_gray = 0
    self.p_ptr = self.data
    self.parse_header()
    self.body_offset = self.p_ptr - self.data
    
  # returns the next number, skipping comments if available
  cdef inline long get_next_number(PGMReader self) nogil:
    cdef char *endptr
    if self.p_ptr[0] == '#':
      # skipping comments
      self.p_ptr = strchr(self.p_ptr, '\n') + 1
    cdef long res = strtol(self.p_ptr, &endptr, 10)
    self.p_ptr = endptr + 1
    return res

  # parses the header and reads width, height etc
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

  # parses the body and processes the pixel values into a reversed array
  #   (column,row instead of row,column)
  @cython.boundscheck(False)
  @cython.wraparound(False)
  cdef int[:,:] parse_body(PGMReader self):
    cdef int *buf = <int*>malloc(sizeof(int) * self.width * self.height)
    cdef int col = 0
    cdef int row = 0
    cdef long tmp
    if buf == NULL:
      raise MemoryError()
    while True:
      if self.p_ptr - self.data == self.data_size + 1:
        free(<void*>buf)
        raise PGMError("EOF occurred too early")
      tmp = self.get_next_number()
      if tmp < 0 or tmp > self.maximum_gray:
        free(<void*>buf)
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

  # performs the reading and returns the data as memory view
  cpdef int[:, :] read(PGMReader self):
    self.p_ptr = self.data + self.body_offset
    return self.parse_body()

  # destructor
  # free internal buffers on destruction
  def __dealloc__(PGMReader self):
    if self.data != NULL:
      free(<void*>self.data)
