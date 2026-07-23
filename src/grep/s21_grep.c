#include <stdio.h>

#include "grep_input.h"

int main(int argc, char *argv[]) {
  // счетчик выбранных строк
  int count_match = 0;
  // код ошибки от parse_input 0 — ошибок нет 2 — ошибка
  int status = parse_input(argc, argv, &count_match);
  // то, что программа вернет операционной системе
  // 0 — найдены совпадения
  // 1 — совпадений не найдено 2 — ошибка
  int exit_code = 0;

  if (status != 0) {
    exit_code = status;
  } else if (count_match == 0) {
    exit_code = 1;
  } else {
    exit_code = 0;
  }

  return exit_code;
}
