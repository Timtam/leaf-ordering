# cython: profile=True
from .exceptions import PGMEOF, PGMError

cimport cython
from libc.stdio cimport FILE, fopen, fgetc, fclose, feof, rewind
from libc.stdlib cimport malloc, free
from libc.string cimport memcpy, strchr

cdef class PGMReader:
  cdef FILE* __file
  cdef char[5] fills
  cdef readonly int width
  cdef readonly height
  cdef readonly int maximum_gray

  def __cinit__(PGMReader self, char *filename):
    self.__file = fopen(filename, "r")
    if self.__file == NULL:
      raise PGMError("File not found")
    memcpy(self.fills, " \t\r\n\0", 5)
    self.width = 0
    self.height = 0
    self.maximum_gray = 0
    
  # read the next line
  @cython.profile(False)
  cdef object get_next_line(PGMReader self):
    cdef str line = ''
    cdef char c = fgetc(self.__file)
    if c == '#':
      while fgetc(self.__file) != '\n':
        pass
      c = fgetc(self.__file)
    while True:
      if feof(self.__file):
        raise PGMEOF()
      if strchr(self.fills, c) != NULL:
        if len(line) == 0:
          raise PGMError("Filler on wrong position")
        return line
      line = line + <bytes>c
      c = fgetc(self.__file)

  cdef object parse_header(PGMReader self):
    cdef str magic = self.get_next_line()
    if magic.lower() != "p2":
      raise PGMError("Only portable graymaps in ascii-format are supported")
    cdef object width = self.get_next_line()
    try:
      self.width = int(width, 10)
    except ValueError:
      raise PGMError("invalid width: "+width)
    cdef object height = self.get_next_line()
    try:
      self.height = int(height, 10)
    except ValueError:
      raise PGMError("invalid height: "+height)
    cdef object maxval = self.get_next_line()
    try:
      maxval = int(maxval, 10)
    except ValueError:
      raise PGMError("invalid maximum gray value: "+maxval)
    if maxval <= 0 or maxval > 65536:
      raise PGMError("invalid maximum gray value, must be from 1 to 65536, but is "+maxval)
    self.maximum_gray = maxval

  @cython.boundscheck(False)
  @cython.wraparound(False)
  cdef int[:,:] parse_body(PGMReader self):
    cdef int *buf = <int*>malloc(sizeof(int) * self.width * self.height)
    cdef int col = 0
    cdef int row = 0
    cdef bytes n
    cdef int tmp
    while True:
      try:
        n = self.get_next_line()
      except PGMEOF:
        raise PGMError("eof encountered before end of data")
      try:
        tmp = int(n, 10)
      except ValueError:
        raise PGMError("invalid pixel at row {row}, column {col}: {pixel}".format(row=row, col=col, pixel=n))
      if tmp < 0 or tmp > self.maximum_gray:
        raise PGMError("pixel at row {row}, column {col} exceeded range from 0 to {gray}: {pixel}".format(col=col, row=row, pixel=n, gray=self.maximum_gray))
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
    rewind(self.__file)
    self.parse_header()
    return self.parse_body()


  def __dealloc__(PGMReader self):
    if self.__file != NULL:
      fclose(self.__file)
      self.__file = NULL
