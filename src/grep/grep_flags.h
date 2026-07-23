#ifndef GREP_FLAGS_H
#define GREP_FLAGS_H

#include <regex.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct {
  int e;
  int i;
  int v;
  int c;
  int l;
  int n;
  int h;
  int s;
  int f;
  int o;
} GrepFlags;

int compile_regex(regex_t *regex, const char *pattern, GrepFlags *flags);

#endif  // GREP_FLAGS_H
