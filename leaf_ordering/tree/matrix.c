// additional c-level helpers for matrix processing
#include "matrix.h"

double* min_element(double *start, double *end)
{
  double *min = start++;
  if (start == end) return end;

  for (; start != end; ++start)
    if (*start < *min) min = start;

  return min;
}
