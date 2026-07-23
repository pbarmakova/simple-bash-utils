CC = gcc
CFLAGS = -Wall -Wextra -Werror -std=c11 -pedantic -D_POSIX_C_SOURCE=201710L
NAME = s21_grep
SRC = s21_grep.c grep_input.c grep_output.c grep_flags.c

all: $(NAME)

$(NAME): $(SRC)
	$(CC) $(CFLAGS) $(SRC) -o $(NAME)

clean:
	rm -f $(NAME)

re: clean all

.PHONY: all clean re
