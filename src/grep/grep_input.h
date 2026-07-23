#ifndef GREP_INPUT_H
#define GREP_INPUT_H

#include <regex.h>
#include <stdio.h>
#include <string.h>

#include "grep_flags.h"
#include "grep_output.h"

int parse_input(int argc, char *argv[], int *count_match);

#endif  // GREP_INPUT_H
