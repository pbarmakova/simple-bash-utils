#include "grep_flags.h"

// Компилирует шаблон через regcomp
int compile_regex(regex_t *regex, const char *pattern, GrepFlags *flags) {
  int reg_flag = 0;
  int flag = 0;
  if (flags->i) {
    reg_flag |= REG_ICASE;
  }
  int result = regcomp(regex, pattern, reg_flag);

  if (result != 0) {
    char error_message[256];

    regerror(result, regex, error_message, sizeof(error_message));
    fprintf(stderr, "Regex compile error: %s\n", error_message);

    flag = 1;
  }
  return flag;
}
