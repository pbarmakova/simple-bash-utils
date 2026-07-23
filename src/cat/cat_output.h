#ifndef CAT_OUTPUT_H
#define CAT_OUTPUT_H

#include <stdio.h>
#include <string.h>

#include "cat_flags.h"

void print_file_content(FILE *file, CatFlags *flags, int *count);

#endif  // CAT_OUTPUT_H
