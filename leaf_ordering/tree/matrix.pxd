cdef extern from "matrix.h" nogil:
  int GETI(int x)
  int GETJ(int i, int x)
  int IDX(int i, int j, int n)
