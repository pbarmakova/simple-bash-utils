#include "cat_input.h"

// печатаем ошибку, если файл не открылся
static void print_file_error(const char *filename) {
  if (filename[0] == '\0') {
    fprintf(stderr, "cat: '': %s\n", strerror(errno));
  } else {
    fprintf(stderr, "cat: %s: %s\n", filename, strerror(errno));
  }
}

// открытие файла, вызов print_file_content
static int handle_file(const char *filename, CatFlags *flags, int *count) {
  int error = 0;

  FILE *file = fopen(filename, "r");
  if (file == NULL) {
    print_file_error(filename);
    error = 1;
  } else {
    print_file_content(file, flags, count);
    fclose(file);
  }

  return error;
}

// длинные флаги
static int parse_long_flag(const char *arg, CatFlags *flags) {
  int error = 0;

  if (strcmp(arg, "--number-nonblank") == 0) {
    flags->b = 1;
  } else if (strcmp(arg, "--number") == 0) {
    flags->n = 1;
  } else if (strcmp(arg, "--squeeze-blank") == 0) {
    flags->s = 1;
  } else {
    fprintf(stderr, "invalid option: %s\n", arg);
    error = 1;
  }

  return error;
}

// короткие флаги
static int set_short_flag(char option, CatFlags *flags) {
  int error = 0;

  if (option == 'b') {
    flags->b = 1;
  } else if (option == 'e') {
    flags->e = 1;
    flags->v = 1;
  } else if (option == 'E') {
    flags->e = 1;
  } else if (option == 'n') {
    flags->n = 1;
  } else if (option == 's') {
    flags->s = 1;
  } else if (option == 't') {
    flags->t = 1;
    flags->v = 1;
  } else if (option == 'T') {
    flags->t = 1;
  } else if (option == 'v') {
    flags->v = 1;
  } else {
    fprintf(stderr, "invalid option: -%c\n", option);
    error = 1;
  }

  return error;
}

// разбитие группы флагов на одиночные
static int parse_short_flags(const char *arg, CatFlags *flags) {
  int error = 0;

  for (int j = 1; arg[j] != '\0' && error == 0; j++) {
    error = set_short_flag(arg[j], flags);
  }

  return error;
}

// функция видна только внутри этого файла
static int process_argument(char *arg, CatFlags *flags, int *count) {
  int error = 0;

  // ввод с клавиатуры, файл, длинный флаг, короткие флаги
  if (strcmp(arg, "-") == 0) {
    print_file_content(stdin, flags, count);
  } else if (arg[0] != '-') {
    error = handle_file(arg, flags, count);
  } else if (arg[1] == '-') {
    error = parse_long_flag(arg, flags);
  } else {
    error = parse_short_flags(arg, flags);
  }

  return error;
}

int parse_input(int argc, char *argv[]) {
  if (argc < 2) {
    printf("Usage: %s filename\n", argv[0]);
    return 1;
  }
  CatFlags flags = {0};
  // счетчик строк для n и b
  int count = 1;
  // общий признак ошибки 0 — ошибок нет 1 — ошибка была
  int error = 0;
  // фатальная ошибка для остановки программы
  int fatal_error = 0;
  int i = 1;

  while (i != argc && fatal_error == 0) {
    if (process_argument(argv[i], &flags, &count) != 0) {
      error = 1;
      fatal_error = argv[i][0] == '-';
    }
    i++;
  }

  return error;
}
