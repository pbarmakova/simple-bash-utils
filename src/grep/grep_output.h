#ifndef GREP_OUTPUT_H
#define GREP_OUTPUT_H

#include <regex.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "grep_flags.h"

void print_file_content(FILE *file, const char *file_name, GrepFlags *flags,
                        int multiple_files, regex_t *regexes, int regex_count,
                        int *count_match);

#endif  // GREP_OUTPUT_H
