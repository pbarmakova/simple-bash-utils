CC = gcc
CFLAGS = -Wall -Wextra -Werror -std=c11 -pedantic -D_POSIX_C_SOURCE=201710L
NAME = s21_cat
SRC = s21_cat.c cat_input.c cat_output.c cat_flags.c

all: $(NAME)

$(NAME): $(SRC)
	$(CC) $(CFLAGS) $(SRC) -o $(NAME)

clean:
	rm -f $(NAME)

re: clean all

.PHONY: all clean re
