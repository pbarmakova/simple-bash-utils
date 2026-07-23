# Simple Bash Utils

[Русский](#русский) · [English](#english)

## Русский

Реализация классических Unix-утилит `cat` и `grep` на языке C. Программы
поддерживают основные флаги оригинальных команд, несколько файлов, стандартный
ввод и регулярные выражения.

Проект выполнен в рамках обучения в School 21.

### Возможности

#### s21_cat

| Флаг | Описание |
|---|---|
| `-b`, `--number-nonblank` | Нумерует непустые строки |
| `-e` | Показывает непечатаемые символы и `$` в конце строки |
| `-E` | Показывает `$` в конце строки |
| `-n`, `--number` | Нумерует все строки |
| `-s`, `--squeeze-blank` | Сжимает повторяющиеся пустые строки |
| `-t` | Показывает непечатаемые символы и табуляцию как `^I` |
| `-T` | Показывает табуляцию как `^I` |
| `-v` | Показывает непечатаемые символы |

#### s21_grep

| Флаг | Описание |
|---|---|
| `-e pattern` | Задаёт шаблон |
| `-i` | Игнорирует регистр |
| `-v` | Инвертирует результат |
| `-c` | Выводит количество найденных строк |
| `-l` | Выводит имена файлов с совпадениями |
| `-n` | Показывает номера строк |
| `-h` | Скрывает имена файлов |
| `-s` | Скрывает сообщения об ошибках |
| `-f file` | Загружает шаблоны из файла |
| `-o` | Выводит только совпавшие части строк |

Флаги можно комбинировать, например: `-iv`, `-in`, `-cl`.

### Технологии

C11, POSIX.1-2017, POSIX Regular Expressions, GCC, Make, Bash,
ClangFormat, Valgrind / Leaks.

Сборка выполняется со строгими флагами:
`-Wall -Wextra -Werror -pedantic`.

### Сборка и использование

```bash
cd src
make

./cat/s21_cat -n example.txt
./grep/s21_grep -in "hello" first.txt second.txt
```

Исполняемые файлы создаются в `src/cat/s21_cat` и `src/grep/s21_grep`.

Дополнительные команды:

```bash
make s21_cat  # собрать cat
make s21_grep # собрать grep
make clean    # удалить исполняемые файлы
make re       # пересобрать проект
```

Обе утилиты поддерживают стандартный ввод:

```bash
echo "Hello!" | ./src/cat/s21_cat -
echo "Hello!" | ./src/grep/s21_grep -i "hello"
```

### Тестирование

Тесты сравнивают результаты с системными `cat` и `grep`.

```bash
cd src
make test     # интеграционные тесты
make style    # проверка форматирования
make leaks    # проверка памяти
make check    # все проверки
```

### Структура

```text
src/
├── Makefile
├── cat/
│   ├── s21_cat.c
│   ├── cat_flags.c/.h
│   ├── cat_input.c/.h
│   ├── cat_output.c/.h
│   ├── test_cat.sh
│   └── Makefile
└── grep/
    ├── s21_grep.c
    ├── grep_flags.c/.h
    ├── grep_input.c/.h
    ├── grep_output.c/.h
    ├── test_grep.sh
    └── Makefile
```

---

## English

An implementation of the classic Unix `cat` and `grep` utilities in C. The
programs support the essential flags of the original commands, multiple input
files, standard input, and regular expressions.

This project was completed as part of the School 21 curriculum.

### Features

#### s21_cat

| Flag | Description |
|---|---|
| `-b`, `--number-nonblank` | Numbers non-empty lines |
| `-e` | Displays non-printing characters and `$` at line ends |
| `-E` | Displays `$` at line ends |
| `-n`, `--number` | Numbers all lines |
| `-s`, `--squeeze-blank` | Suppresses repeated empty lines |
| `-t` | Displays non-printing characters and tabs as `^I` |
| `-T` | Displays tabs as `^I` |
| `-v` | Displays non-printing characters |

#### s21_grep

| Flag | Description |
|---|---|
| `-e pattern` | Specifies a pattern |
| `-i` | Ignores letter case |
| `-v` | Inverts the result |
| `-c` | Prints the number of matching lines |
| `-l` | Prints names of files containing matches |
| `-n` | Prefixes output with line numbers |
| `-h` | Suppresses file names |
| `-s` | Suppresses file error messages |
| `-f file` | Reads patterns from a file |
| `-o` | Prints only matching parts of lines |

Flags can be combined, for example: `-iv`, `-in`, or `-cl`.

### Technologies

C11, POSIX.1-2017, POSIX Regular Expressions, GCC, Make, Bash,
ClangFormat, Valgrind / Leaks.

The project is compiled with strict options:
`-Wall -Wextra -Werror -pedantic`.

### Build and usage

```bash
cd src
make

./cat/s21_cat -n example.txt
./grep/s21_grep -in "hello" first.txt second.txt
```

The executables are created as `src/cat/s21_cat` and `src/grep/s21_grep`.

Additional commands:

```bash
make s21_cat  # build cat
make s21_grep # build grep
make clean    # remove executables
make re       # rebuild the project
```

Both utilities support standard input:

```bash
echo "Hello!" | ./src/cat/s21_cat -
echo "Hello!" | ./src/grep/s21_grep -i "hello"
```

### Testing

The tests compare the implementations with the system `cat` and `grep`.

```bash
cd src
make test     # integration tests
make style    # formatting check
make leaks    # memory check
make check    # run all checks
```

### Project structure

```text
src/
├── Makefile
├── cat/
│   ├── s21_cat.c
│   ├── cat_flags.c/.h
│   ├── cat_input.c/.h
│   ├── cat_output.c/.h
│   ├── test_cat.sh
│   └── Makefile
└── grep/
    ├── s21_grep.c
    ├── grep_flags.c/.h
    ├── grep_input.c/.h
    ├── grep_output.c/.h
    ├── test_grep.sh
    └── Makefile
```

### Implementation highlights

- custom command-line argument parsing;
- short, combined, and long options;
- multiple files and standard input;
- POSIX regular expressions;
- multiple patterns supplied through `-e` and `-f`;
- meaningful exit codes and error handling;
- modular input, output, and option-processing components;
- integration tests against the system utilities.

