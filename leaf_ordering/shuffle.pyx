from libc.stdlib cimport malloc, free, srand, rand
from libc.time cimport time

# a method to randomly shuffle any pgm dataset
cpdef random_shuffle_dataset(int[:, :] data):
  cdef int * buf = <int*>malloc(data.nbytes)
  cdef list r
  cdef int rnd
  cdef int offset = 0
  cdef int[:] blk
  cdef int m = data.shape[0]
  cdef int n = data.shape[1]
  cdef int I
  if buf == NULL:
    raise MemoryError()
  r = list(range(data.shape[0]))
  srand(time(NULL))
  while r:
    rnd = rand()%len(r)
    I = r[rnd]
    blk = <int[:n]>(buf+offset)
    blk[...] = data[I]
    del r[rnd]
    offset += n
  cdef int[:, :] mem = (<int[:m, :n]>buf).copy()
  free(<void*>buf)
  return mem
