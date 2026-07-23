#include "grep_output.h"

typedef struct {
  int count;
  int line_number;
  int file_has_match;
} GrepOutputState;

// проверяет строку по всем regex. Возвращает 1, если совпал хотя бы один
static int line_matches_any(regex_t *regexes, int regex_count,
                            const char *line) {
  int matched = 0;

  for (int i = 0; i < regex_count && !matched; i++) {
    // 0 — совпадение найдено, не 0 — совпадения нет
    matched = regexec(&regexes[i], line, 0, NULL, 0) == 0;
  }

  return matched;
}

// печать префикса file: line: учитывает -h, -n, количество файлов
static void print_prefix(const char *file_name, int multiple_files,
                         GrepFlags *flags, int line_number) {
  if (multiple_files && !flags->h && file_name != NULL) {
    printf("%s:", file_name);
  }
  if (flags->n) {
    printf("%d:", line_number);
  }
}

// Для -o: выбирает более раннее совпадение
static int is_better_match(regmatch_t match, regmatch_t best_match,
                           int has_match) {
  return !has_match || match.rm_so < best_match.rm_so;
}

// Для -o: ищет следующее совпадение в строке среди всех regex
static int find_next_match(const char *cursor, regex_t *regexes,
                           int regex_count, regmatch_t *best_match) {
  int has_match = 0;

  for (int i = 0; i < regex_count; i++) {
    regmatch_t match;

    if (regexec(&regexes[i], cursor, 1, &match, 0) == 0 &&
        match.rm_so != match.rm_eo &&
        is_better_match(match, *best_match, has_match)) {
      *best_match = match;
      has_match = 1;
    }
  }

  return has_match;
}

// Для флага -o. Печатает один найденный совпавший кусок строки
static void print_match(const char *cursor, regmatch_t match,
                        const char *file_name, int multiple_files,
                        GrepFlags *flags, int line_number) {
  print_prefix(file_name, multiple_files, flags, line_number);
  printf("%.*s\n", (int)(match.rm_eo - match.rm_so), cursor + match.rm_so);
}

// Для флага -o. Печатает все совпавшие части строки, каждую с новой строки
static void print_only_matches(const char *line, const char *file_name,
                               int multiple_files, GrepFlags *flags,
                               int line_number, regex_t *regexes,
                               int regex_count) {
  const char *cursor = line;
  int searching = 1;

  while (*cursor != '\0' && searching) {
    regmatch_t best_match = {0};
    int has_match = find_next_match(cursor, regexes, regex_count, &best_match);

    if (has_match) {
      print_match(cursor, best_match, file_name, multiple_files, flags,
                  line_number);
      cursor += best_match.rm_eo;
    } else {
      searching = 0;
    }
  }
}

// Удаляет \n в конце строки после getline
static int remove_newline(char *line) {
  size_t line_len = strlen(line);
  int has_newline = line_len > 0 && line[line_len - 1] == '\n';

  if (has_newline) {
    line[line_len - 1] = '\0';
  }

  return has_newline;
}

// Печатает выбранную строку
static void print_selected_line(const char *line, int has_newline,
                                const char *file_name, int multiple_files,
                                GrepFlags *flags, int line_number,
                                regex_t *regexes, int regex_count) {
  if (flags->o && !flags->v) {
    print_only_matches(line, file_name, multiple_files, flags, line_number,
                       regexes, regex_count);
  } else if (!flags->o) {
    print_prefix(file_name, multiple_files, flags, line_number);
    printf("%s", line);
    if (has_newline) {
      printf("\n");
    }
  }
}

// Обрабатывает одну строку файла
static void process_line(char *line, const char *file_name, int multiple_files,
                         GrepFlags *flags, regex_t *regexes, int regex_count,
                         int *count_match, GrepOutputState *state) {
  int has_newline = remove_newline(line);
  int matched = line_matches_any(regexes, regex_count, line);
  int selected = flags->v ? !matched : matched;

  if (selected) {
    (*count_match)++;
    state->count++;
    state->file_has_match = 1;
  }

  if (selected && !flags->c && !flags->l) {
    print_selected_line(line, has_newline, file_name, multiple_files, flags,
                        state->line_number, regexes, regex_count);
  }

  state->line_number++;
}

// Печатает итог после файла/ -l — печатает имя файла, если были совпадения -c —
// печатает количество выбранных строк -l выше -c
static void print_summary(const char *file_name, int multiple_files,
                          GrepFlags *flags, GrepOutputState *state) {
  if (flags->l) {
    if (state->file_has_match) {
      printf("%s\n", file_name != NULL ? file_name : "(standard input)");
    }
  } else if (flags->c) {
    if (multiple_files && !flags->h && file_name != NULL) {
      printf("%s:", file_name);
    }
    printf("%d\n", state->count);
  }
}

// создание состояния файла, чтение каждой строки, отправка в process_line, инф
// для -c или -l, фри line
void print_file_content(FILE *file, const char *file_name, GrepFlags *flags,
                        int multiple_files, regex_t *regexes, int regex_count,
                        int *count_match) {
  char *line = NULL;
  size_t len = 0;
  GrepOutputState state = {0, 1, 0};

  if (regex_count > 0 || flags->v) {
    while (getline(&line, &len, file) != -1) {
      process_line(line, file_name, multiple_files, flags, regexes, regex_count,
                   count_match, &state);
    }

    print_summary(file_name, multiple_files, flags, &state);
  }

  free(line);
}
