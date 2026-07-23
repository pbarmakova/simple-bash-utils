#include <stdio.h>

#include "cat_input.h"

int main(int argc, char *argv[]) {
  int result = 0;

  if (parse_input(argc, argv) != 0) {
    result = 1;
  }

  return result;
}
