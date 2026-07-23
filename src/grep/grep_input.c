#include "grep_input.h"

// Добавляет один pattern: расширяет массив regexes, компилирует regex,
// увеличивает regex_count
static int add_pattern(regex_t **regexes, int *regex_count, const char *pattern,
                       GrepFlags *flags) {
  // увеличиваем массив regexes через realloc
  regex_t *tmp = realloc(*regexes, (*regex_count + 1) * sizeof(regex_t));

  int flag = 0;

  if (tmp == NULL) {
    perror("realloc");
    flag = 2;
  }

  if (flag == 0) {
    *regexes = tmp;
  }
  // &(*regexes)[*regex_count] - адрес ячейки массива
  if (flag == 0 &&
      compile_regex(&(*regexes)[*regex_count], pattern, flags) != 0) {
    flag = 2;
  }

  if (flag == 0) {
    (*regex_count)++;
  }
  return flag;
}

// Обрабатывает -f: открывает файл, читает patterns построчно, добавляет каждый
// через add_pattern
static int add_patterns_from_file(const char *filename, regex_t **regexes,
                                  int *regex_count, GrepFlags *flags) {
  FILE *file = fopen(filename, "r");
  char *line = NULL;
  size_t len = 0;
  int status = 0;

  if (file == NULL) {
    fprintf(stderr, "./s21_grep: %s: No such file or directory\n", filename);
    status = 2;
  } else {
    while (status == 0 && getline(&line, &len, file) != -1) {
      size_t line_len = strlen(line);

      if (line_len > 0 && line[line_len - 1] == '\n') {
        line[line_len - 1] = '\0';
      }
      status = add_pattern(regexes, regex_count, line, flags);
    }

    fclose(file);
  }

  free(line);

  return status;
}

// Освобождает все скомпилированные regex через regfree и free
static void free_regexes(regex_t *regexes, int regex_count) {
  for (int i = 0; i < regex_count; i++) {
    regfree(&regexes[i]);
  }
  free(regexes);
}

// простые флаги
static int set_simple_flag(char option, GrepFlags *flags) {
  int handled = 1;

  if (option == 'i') {
    flags->i = 1;
  } else if (option == 'v') {
    flags->v = 1;
  } else if (option == 'c') {
    flags->c = 1;
  } else if (option == 'l') {
    flags->l = 1;
  } else if (option == 'n') {
    flags->n = 1;
  } else if (option == 'h') {
    flags->h = 1;
  } else if (option == 's') {
    flags->s = 1;
  } else if (option == 'o') {
    flags->o = 1;
  } else {
    handled = 0;
  }

  return handled;
}

// Обрабатывает значение для -e или -f
static int add_option_pattern(int argc, char *argv[], int *arg_index,
                              int option_index, regex_t **regexes,
                              int *regex_count, GrepFlags *flags) {
  int status = 0;
  char option = argv[*arg_index][option_index];
  const char *pattern = &argv[*arg_index][option_index + 1];

  if (pattern[0] == '\0' && *arg_index + 1 < argc) {
    (*arg_index)++;
    pattern = argv[*arg_index];
  } else if (pattern[0] == '\0') {
    status = 2;
  }

  if (status == 0 && option == 'e') {
    status = add_pattern(regexes, regex_count, pattern, flags);
  } else if (status == 0) {
    status = add_patterns_from_file(pattern, regexes, regex_count, flags);
  }

  return status;
}

// парсит большой флаг на одиночные
static int parse_option_arg(int argc, char *argv[], int *arg_index,
                            GrepFlags *flags, regex_t **regexes,
                            int *regex_count, int *pattern_set) {
  // 0 — все ок 2 — ошибка
  int status = 0;
  // остановка текущего разбора арг(для е и ф)
  int option_done = 0;

  for (int j = 1; argv[*arg_index][j] != '\0' && status == 0 && !option_done;
       j++) {
    // Берем текущий символ флага
    char option = argv[*arg_index][j];

    if (option == 'e' || option == 'f') {
      flags->e = flags->e || option == 'e';
      flags->f = flags->f || option == 'f';
      *pattern_set = 1;
      status = add_option_pattern(argc, argv, arg_index, j, regexes,
                                  regex_count, flags);
      // останавливаем разбор, потому что после е или ф уже не влаги а значение
      option_done = 1;
    } else if (!set_simple_flag(option, flags)) {
      fprintf(stderr, "invalid option: -%c\n", option);
      status = 2;
    }
  }

  return status;
}

// Идет по начальным аргументам и разбирает флаги, пока они есть
static int parse_options(int argc, char *argv[], int *arg_index,
                         GrepFlags *flags, regex_t **regexes, int *regex_count,
                         int *pattern_set) {
  int status = 0;
  int parsing_options = 1;

  // пока видит аргументы, похожие на флаги, обрабатывает их
  while (*arg_index < argc && status == 0 && parsing_options) {
    if (argv[*arg_index][0] == '-' && argv[*arg_index][1] != '\0') {
      // передает каждый аргумент вида флага
      status = parse_option_arg(argc, argv, arg_index, flags, regexes,
                                regex_count, pattern_set);
      (*arg_index)++;
    } else {
      parsing_options = 0;
    }
  }

  return status;
}

// Если -e/-f не было, берет следующий аргумент как обычный pattern
static int set_default_pattern(int argc, char *argv[], int *arg_index,
                               GrepFlags *flags, regex_t **regexes,
                               int *regex_count, int *pattern_set) {
  int status = 0;

  if (status == 0 && !*pattern_set) {
    if (*arg_index < argc) {
      status = add_pattern(regexes, regex_count, argv[*arg_index], flags);
      *pattern_set = 1;
      (*arg_index)++;
    } else {
      status = 2;
    }
  }

  return status;
}

// печать ошибки, если нет -s
static void print_file_error(const char *filename, GrepFlags *flags) {
  if (!flags->s) {
    fprintf(stderr, "./s21_grep: %s: No such file or directory\n", filename);
  }
}

// Обрабатывает ввод из stdin, если файлы не переданы
static int process_stdin(GrepFlags *flags, regex_t *regexes, int regex_count,
                         int *count_match) {
  print_file_content(stdin, NULL, flags, 0, regexes, regex_count, count_match);

  return 0;
}

// Открывает один файл, вызывает print_file_content, закрывает файл
static int process_file(const char *filename, GrepFlags *flags,
                        int multiple_files, regex_t *regexes, int regex_count,
                        int *count_match) {
  int status = 0;
  FILE *file = fopen(filename, "r");

  if (file == NULL) {
    print_file_error(filename, flags);
    status = 2;
  } else {
    print_file_content(file, filename, flags, multiple_files, regexes,
                       regex_count, count_match);
    fclose(file);
  }

  return status;
}

// Обрабатывает список файлов
static int process_file_list(int argc, char *argv[], int file_start,
                             GrepFlags *flags, regex_t *regexes,
                             int regex_count, int *count_match) {
  int status = 0;
  int multiple_files = argc - file_start > 1;

  for (int f = file_start; f < argc; f++) {
    int file_status = process_file(argv[f], flags, multiple_files, regexes,
                                   regex_count, count_match);
    if (file_status != 0) {
      status = file_status;
    }
  }

  return status;
}

// выбор обработки стдин или список файлов
static int process_files(int argc, char *argv[], int file_start,
                         GrepFlags *flags, regex_t *regexes, int regex_count,
                         int *count_match) {
  int status = 0;

  if (file_start >= argc) {
    status = process_stdin(flags, regexes, regex_count, count_match);
  } else {
    status = process_file_list(argc, argv, file_start, flags, regexes,
                               regex_count, count_match);
  }

  return status;
}

// Главная функция парсинга grep
int parse_input(int argc, char *argv[], int *count_match) {
  GrepFlags flags = {0};
  // массив скомпилированных регулярных выражений
  regex_t *regexes = NULL;
  // количество regex-ов в массиве regexes
  int regex_count = 0;
  // индекс текущего аргумента в argv
  int arg_index = 1;
  // был ли уже задан шаблон 0 — шаблона еще нет 1 — шаблон уже есть
  int pattern_set = 0;
  // 0 — все нормально 2 — ошибка
  int status = 0;

  status = parse_options(argc, argv, &arg_index, &flags, &regexes, &regex_count,
                         &pattern_set);
  if (status == 0) {
    status = set_default_pattern(argc, argv, &arg_index, &flags, &regexes,
                                 &regex_count, &pattern_set);
  }
  if (status == 0) {
    status = process_files(argc, argv, arg_index, &flags, regexes, regex_count,
                           count_match);
  }

  free_regexes(regexes, regex_count);

  return status;
}
