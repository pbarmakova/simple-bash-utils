#include "cat_output.h"

typedef struct {
  int at_line_start;
  int pending_cr;
  int blank_count;
} CatOutputState;

// печать \r
static void print_pending_cr(CatFlags *flags, int *pending_cr) {
  if (flags->v) {
    printf("^M");
  } else {
    putchar('\r');
  }
  *pending_cr = 0;
}

// функция для обработки символа \r
static int process_carriage_return(int ch, CatFlags *flags,
                                   CatOutputState *state) {
  int print_char = 1;

  if (ch == '\r') {
    state->pending_cr = 1;
    print_char = 0;
  } else if (state->pending_cr == 1 && ch != '\n') {
    print_pending_cr(flags, &state->pending_cr);
  }

  return print_char;
}
// -s пустые строки подряд
static void process_blank_line(int ch, CatFlags *flags, CatOutputState *state,
                               int *print_char) {
  if (flags->s && ch == '\n' && state->at_line_start == 1) {
    state->blank_count++;
    if (state->blank_count > 1) {
      *print_char = 0;
    }
  }
  if (flags->s && ch != '\n') {
    state->blank_count = 0;
  }
}

// нумерация -b — непустые строки -n — все строки, если нет -b
static void print_line_number(int ch, CatFlags *flags, CatOutputState *state,
                              int *count, int print_char) {
  if (print_char && flags->b && state->at_line_start == 1 && ch != '\n') {
    numeric_b(count);
    state->at_line_start = 0;
  }
  if (print_char && flags->n && !flags->b && state->at_line_start == 1) {
    numeric_n(count);
    state->at_line_start = 0;
  }
}

// Обрабатывает \n, флаг -e/-E, печатает $, учитывает -s
static void process_newline(int ch, CatFlags *flags, CatOutputState *state,
                            int *print_char) {
  if (*print_char && ch == '\n') {
    state->at_line_start = 1;
    if (flags->e && state->pending_cr == 1) {
      end_line(0);
      state->pending_cr = 0;
    } else if (flags->e) {
      end_line(1);
    }
    if (!flags->s || state->blank_count <= 2) {
      putchar(ch);
    }
    *print_char = 0;
  }
}

// Обрабатывает таб \t для -t/-T, печатает ^I.
static void process_tab(int ch, CatFlags *flags, CatOutputState *state,
                        int *print_char) {
  if (*print_char && ch == '\t' && flags->t) {
    tab();
    state->at_line_start = 0;
    *print_char = 0;
  }
}

// Печатает обычный символ. Если включен -v, вызывает print_v.
static void process_regular_char(int ch, CatFlags *flags, CatOutputState *state,
                                 int print_char) {
  if (print_char && flags->v) {
    print_v(ch);
  } else if (print_char) {
    putchar(ch);
  }
  if (print_char) {
    state->at_line_start = 0;
  }
}

// обработчик одиночного символа
static void process_char(int ch, CatFlags *flags, int *count,
                         CatOutputState *state) {
  // 1 — этот символ еще надо печатать дальше. 0 — символ уже обработан или его
  // надо пропустить
  int print_char = process_carriage_return(ch, flags, state);
  // Обработка -s
  process_blank_line(ch, flags, state, &print_char);
  // Обработка -b и -n
  print_line_number(ch, flags, state, count, print_char);
  // Обработка \n
  process_newline(ch, flags, state, &print_char);
  // Обработка таба
  process_tab(ch, flags, state, &print_char);
  process_regular_char(ch, flags, state, print_char);
}

void print_file_content(FILE *file, CatFlags *flags, int *count) {
  int ch;
  CatOutputState state = {1, 0, 0};

  while ((ch = fgetc(file)) != EOF) {
    process_char(ch, flags, count, &state);
  }

  if (state.pending_cr == 1) {
    print_pending_cr(flags, &state.pending_cr);
  }
}
