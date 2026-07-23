#ifndef CAT_FLAGS_H
#define CAT_FLAGS_H

#include <stdio.h>

typedef struct {
  int b;
  int e;
  int n;
  int s;
  int t;
  int v;
} CatFlags;

void numeric_b(int *count);
void numeric_n(int *count);
void end_line(int end);
void tab(void);
void print_v(int ch);

#endif  // CAT_FLAGS_H
