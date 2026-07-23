NAME = cat/s21_cat
NAME2 = grep/s21_grep
# -pedantic - строгая проверка на стандарт C11
FLAGS = -Wall -Wextra -Werror -std=c11 -pedantic -D_POSIX_C_SOURCE=201710L
CLANG_FORMAT = $(shell command -v clang-format 2>/dev/null || xcrun --find clang-format 2>/dev/null || echo clang-format)
MEMCHECK = $(shell command -v leaks >/dev/null 2>&1 && echo leaks || command -v valgrind >/dev/null 2>&1 && echo valgrind || echo none)

SRC = cat/s21_cat.c cat/cat_input.c cat/cat_output.c cat/cat_flags.c
SRC2 = grep/s21_grep.c grep/grep_input.c grep/grep_output.c grep/grep_flags.c

all: $(NAME) $(NAME2)

$(NAME): $(SRC)
	gcc $(FLAGS) $(SRC) -o $(NAME)

$(NAME2): $(SRC2)
	gcc $(FLAGS) $(SRC2) -o $(NAME2)

s21_cat: $(NAME)

s21_grep: $(NAME2)

style:
	$(CLANG_FORMAT) -n -style=file:../materials/linters/.clang-format cat/*.c cat/*.h grep/*.c grep/*.h

test_cat: $(NAME)
	cd cat && bash test_cat.sh

test_grep: $(NAME2)
	cd grep && bash test_grep.sh

test: test_cat test_grep

leaks_cat: $(NAME)
	@if command -v leaks >/dev/null 2>&1; then \
		(cd cat && leaks -atExit -- ./s21_cat -benst cat_input.c cat_output.c | grep "leaks for"); \
	elif command -v valgrind >/dev/null 2>&1; then \
		(cd cat && valgrind --vgdb=no --tool=memcheck --leak-check=yes --error-exitcode=1 ./s21_cat -benst cat_input.c cat_output.c > /dev/null); \
	else \
		echo "Install leaks (macOS) or valgrind (Linux) to run memory checks"; \
		exit 1; \
	fi

leaks_grep: $(NAME2)
	@if command -v leaks >/dev/null 2>&1; then \
		(cd grep && leaks -atExit -- ./s21_grep -in "regex" grep_input.c grep_output.c | grep "leaks for"); \
		(cd grep && leaks -atExit -- ./s21_grep -e "regex" -e "flag" -o grep_input.c grep_flags.c | grep "leaks for"); \
	elif command -v valgrind >/dev/null 2>&1; then \
		(cd grep && valgrind --vgdb=no --tool=memcheck --leak-check=yes --error-exitcode=1 ./s21_grep -in "regex" grep_input.c grep_output.c > /dev/null); \
		(cd grep && valgrind --vgdb=no --tool=memcheck --leak-check=yes --error-exitcode=1 ./s21_grep -e "regex" -e "flag" -o grep_input.c grep_flags.c > /dev/null); \
	else \
		echo "Install leaks (macOS) or valgrind (Linux) to run memory checks"; \
		exit 1; \
	fi

leaks:
	$(MAKE) clean
	$(MAKE) all
	$(MAKE) leaks_cat
	$(MAKE) leaks_grep

check:
	$(MAKE) clean
	$(MAKE) all
	$(MAKE) style
	$(MAKE) leaks_cat
	$(MAKE) leaks_grep
	$(MAKE) test

format:
	$(CLANG_FORMAT) -i -style=file:../materials/linters/.clang-format cat/*.c cat/*.h grep/*.c grep/*.h

clean:
	rm -f $(NAME) $(NAME2)

re: clean all

# PHONY защищает служебные цели Makefile от конфликта с файлами с такими же именами
.PHONY: all s21_cat s21_grep style test_cat test_grep test leaks_cat leaks_grep leaks check format clean re
