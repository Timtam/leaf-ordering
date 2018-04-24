import array

from .exceptions import PGMEOF, PGMError

class PGMReader(object):
  FILLS = " \t\r\n"

  def __init__(self, filename):
    self.__file = open(filename, "r")
    self.width = 0
    self.height = 0
    self.maximum_gray = 0
    
  # read the next line
  def get_next_line(self):
    line = ''
    c = self.__file.read(1)
    if c == '#':
      while self.__file.read(1) != '\n':
        pass
      c = self.__file.read(1)
    while True:
      if c == '':
        raise PGMEOF()
      if c in self.FILLS:
        if len(line) == 0:
          raise PGMError("Filler on wrong position")
        return line
      line = line + c
      c = self.__file.read(1)

  def parse_header(self):
    magic = self.get_next_line()
    if magic.lower() != "p2":
      raise PGMError("Only portable graymaps in ascii-format are supported")
    width = self.get_next_line()
    try:
      self.width = int(width, 10)
    except ValueError:
      raise PGMError("invalid width: "+width)
    height = self.get_next_line()
    try:
      self.height = int(height, 10)
    except ValueError:
      raise PGMError("invalid height: "+height)
    maxval = self.get_next_line()
    try:
      maxval = int(maxval, 10)
    except ValueError:
      raise PGMError("invalid maximum gray value: "+maxval)
    if maxval <= 0 or maxval > 65536:
      raise PGMError("invalid maximum gray value, must be from 1 to 65536, but is "+maxval)
    self.maximum_gray = maxval

  def parse_body(self):
    columns = [array.array('H') for i in range(self.height)]
    col = 0
    row = 0
    while True:
      try:
        n = self.get_next_line()
      except PGMEOF:
        raise PGMError("eof encountered before end of data")
      try:
        n = int(n, 10)
      except ValueError:
        raise PGMError("invalid pixel at row {row}, column {col}: {pixel}".format(row=row, col=col, pixel=n))
      columns[col].append(n)
      col += 1
      if col == self.width:
        row += 1
        col = 0
        if row == self.height:
          return columns

  def read(self):
    self.parse_header()
    return self.parse_body()
