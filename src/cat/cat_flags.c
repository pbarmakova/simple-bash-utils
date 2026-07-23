#include "cat_flags.h"

void numeric_b(int *count) {
  printf("%6d\t", *count);
  (*count)++;
}
void numeric_n(int *count) {
  printf("%6d\t", *count);
  (*count)++;
}
void end_line(int end) {
  if (end == 0) {
    printf("^M$");
  } else {
    printf("$");
  }
}
void tab(void) { printf("^I"); }

void print_v(int ch) {
  if (ch >= 0 && ch < 32 && ch != '\n' && ch != '\t') {
    printf("^%c", ch + 64);
  } else if (ch == 127) {
    printf("^?");
  } else {
    putchar(ch);
  }
}
