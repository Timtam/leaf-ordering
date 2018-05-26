// additional c-level helper functions for matrix processing
#ifndef __LEAF_ORDERING_MATRIX_H__
  #define __LEAF_ORDERING_MATRIX_H__

  #include <math.h>

  // Fix for older C89 compiler for functions fmin, fmax, log2
  #ifndef fmin
    #define fmin(x,y) (x<y?x:y)
  #endif
  #ifndef fmax
    #define fmax(x,y) (x>y?x:y)
  #endif
  #ifndef log2
    #define log2(x) (log(x)/log((double)2))
  #endif
  
  #define GETI(x) (floor(sqrt((double)(8*x + 1))-1)/2)
  #define GETJ(i,x) (x-(i*(i+1)/2)) //without i: (x-(pow((floor(sqrt(8*x + 1)-1)/2), 2)+(floor(sqrt(8*x + 1)-1)/2))/2))
  #define IDX(i,j) ((int)fmax(i, j)*((int)fmax(i, j)+1)/2+(int)fmin(i, j))

  struct Distance
  {
    double distance;
    int index;
    bool operator<(const Distance& rhs) const
    {
      return !(distance < rhs.distance);
    }
  };

  double* min_element(double *start, double *end);
#endif
