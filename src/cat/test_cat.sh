#!/bin/bash

MY_CAT="./s21_cat"
REAL_CAT="cat"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
GRAY='\033[0;90m'
NC='\033[0m'

mkdir -p tests/input
mkdir -p tests/output

FAIL_LOG="tests/output/failures.log"
: > "$FAIL_LOG"

printf "hello\nworld\n" > tests/input/simple.txt
printf "one\n\n\ntwo\n" > tests/input/blank_lines.txt
printf "one\ttwo\n\tthree\n" > tests/input/tabs.txt
printf "line without newline" > tests/input/no_newline.txt
printf "A\001B\002C\177D\n" > tests/input/nonprinting.txt
printf "\n\n\n\n" > tests/input/only_blank_lines.txt
printf "first line\n\n\tline with tab\nline after tab\n\n\nlast line\n" > tests/input/mixed.txt
touch tests/input/empty.txt

FILES=(
    "tests/input/simple.txt"
    "tests/input/blank_lines.txt"
    "tests/input/tabs.txt"
    "tests/input/no_newline.txt"
    "tests/input/nonprinting.txt"
    "tests/input/only_blank_lines.txt"
    "tests/input/mixed.txt"
    "tests/input/empty.txt"
)

SHORT_FLAGS=(
    "b"
    "e"
    "n"
    "s"
    "t"
    "v"
    "E"
    "T"
)

TEST_FLAGS=(
    "-b"
    "-e"
    "-n"
    "-s"
    "-t"
    "-v"
    "-E"
    "-T"

    "-bn"
    "-nb"
    "-bs"
    "-sb"
    "-ns"
    "-sn"

    "-ev"
    "-ve"
    "-tv"
    "-vt"

    "-eT"
    "-tE"
    "-ET"
    "-TE"

    "-benst"
    "-bens"
    "-nst"
    "-vet"
)

TOTAL=0
PASSED=0
FAILED=0

print_command() {
    local cmd="$1"
    shift

    printf "%s" "$cmd"

    for arg in "$@"
    do
        printf " %q" "$arg"
    done
}

run_test() {
    local test_name="$1"
    local stdin_file="$2"
    shift 2

    local args=("$@")

    TOTAL=$((TOTAL + 1))

    local expected="tests/output/expected.txt"
    local actual="tests/output/actual.txt"
    local diff_file="tests/output/diff.txt"

    local expected_err="tests/output/expected.err"
    local actual_err="tests/output/actual.err"
    local diff_err="tests/output/diff_err.txt"

    if [ "$stdin_file" = "__NO_STDIN__" ]; then
        "$REAL_CAT" "${args[@]}" > "$expected" 2> "$expected_err"
        local real_code=$?

        "$MY_CAT" "${args[@]}" > "$actual" 2> "$actual_err"
        local my_code=$?
    else
        "$REAL_CAT" "${args[@]}" < "$stdin_file" > "$expected" 2> "$expected_err"
        local real_code=$?

        "$MY_CAT" "${args[@]}" < "$stdin_file" > "$actual" 2> "$actual_err"
        local my_code=$?
    fi

    diff -u "$expected" "$actual" > "$diff_file"
    local out_diff_code=$?

    diff -u "$expected_err" "$actual_err" > "$diff_err"
    local err_diff_code=$?

    if [ $out_diff_code -eq 0 ] && [ $err_diff_code -eq 0 ] && [ $real_code -eq $my_code ]; then
        PASSED=$((PASSED + 1))
        printf "${GREEN}[%03d] OK${NC}    ${GRAY}%s${NC}\n" "$TOTAL" "$test_name"
    else
        FAILED=$((FAILED + 1))
        {
            printf "[%03d] FAIL  %s\n" "$TOTAL" "$test_name"

            echo -n "real: "
            print_command "$REAL_CAT" "${args[@]}"
            if [ "$stdin_file" != "__NO_STDIN__" ]; then
                printf " < %q" "$stdin_file"
            fi
            echo

            echo -n "mine:   "
            print_command "$MY_CAT" "${args[@]}"
            if [ "$stdin_file" != "__NO_STDIN__" ]; then
                printf " < %q" "$stdin_file"
            fi
            echo
            echo "real exit code: $real_code"
            echo "my exit code:   $my_code"

            if [ $out_diff_code -ne 0 ]; then
                echo "stdout diff:"
                echo "--- expected = system cat"
                echo "+++ actual   = your s21_cat"
                cat "$diff_file"

                echo
                echo "expected output:"
                cat -A "$expected"

                echo
                echo "actual output:"
                cat -A "$actual"
            fi

            if [ $err_diff_code -ne 0 ]; then
                echo "stderr diff:"
                echo "--- expected stderr = system cat"
                echo "+++ actual stderr   = your s21_cat"
                cat "$diff_err"
            fi

            echo
        } >> "$FAIL_LOG"
        echo
        printf "${RED}[%03d] FAIL${NC}  %s\n" "$TOTAL" "$test_name"

        echo -ne "${BLUE}real:${NC} "
        print_command "$REAL_CAT" "${args[@]}"
        if [ "$stdin_file" != "__NO_STDIN__" ]; then
            printf " < %q" "$stdin_file"
        fi
        echo

        echo -ne "${BLUE}mine:  ${NC} "
        print_command "$MY_CAT" "${args[@]}"
        if [ "$stdin_file" != "__NO_STDIN__" ]; then
            printf " < %q" "$stdin_file"
        fi
        echo
        echo -e "real exit code: ${YELLOW}$real_code${NC}"
        echo -e "my exit code:   ${YELLOW}$my_code${NC}"

        if [ $out_diff_code -ne 0 ]; then
            echo -e "${YELLOW}stdout diff:${NC}"
            echo -e "${GRAY}--- expected = system cat${NC}"
            echo -e "${GRAY}+++ actual   = your s21_cat${NC}"
            cat "$diff_file"

            echo
            echo -e "${YELLOW}expected output:${NC}"
            cat -A "$expected"

            echo
            echo -e "${YELLOW}actual output:${NC}"
            cat -A "$actual"
        fi

        if [ $err_diff_code -ne 0 ]; then
            echo -e "${YELLOW}stderr diff:${NC}"
            echo -e "${GRAY}--- expected stderr = system cat${NC}"
            echo -e "${GRAY}+++ actual stderr   = your s21_cat${NC}"
            cat "$diff_err"
        fi
        echo
    fi
}

generate_all_flag_combinations() {
    local count=${#SHORT_FLAGS[@]}
    local max=$((1 << count))

    for ((mask = 1; mask < max; mask++))
    do
        local opt="-"

        for ((i = 0; i < count; i++))
        do
            if ((mask & (1 << i))); then
                opt+="${SHORT_FLAGS[$i]}"
            fi
        done

        echo "$opt"
    done
}

echo -e "${BLUE}Testing s21_cat${NC}"
echo -e "${GRAY}MY_CAT:   $MY_CAT${NC}"
echo -e "${GRAY}REAL_CAT: $REAL_CAT${NC}"
echo -e "${GRAY}FAIL_LOG: $FAIL_LOG${NC}"
echo

if [ ! -x "$MY_CAT" ]; then
    echo -e "${RED}ERROR:${NC} $MY_CAT not found or not executable"
    echo "Build the program first, for example:"
    echo "  make"
    echo
    echo "Or change MY_CAT at the top of the script."
    exit 1
fi

echo -e "${YELLOW}No flags${NC}"

for file in "${FILES[@]}"
do
    run_test "no flags | file=$file" "__NO_STDIN__" "$file"
done

echo

echo -e "${YELLOW}Selected flags${NC}"

for flag in "${TEST_FLAGS[@]}"
do
    for file in "${FILES[@]}"
    do
        run_test "flag=$flag | file=$file" "__NO_STDIN__" "$flag" "$file"
    done
done

echo

echo -e "${YELLOW}Flag combinations${NC}"

while read -r flag
do
    for file in "${FILES[@]}"
    do
        run_test "combo=$flag | file=$file" "__NO_STDIN__" "$flag" "$file"
    done
done < <(generate_all_flag_combinations)

echo

echo -e "${YELLOW}Multiple files${NC}"

run_test "multiple files | no flags" "__NO_STDIN__" \
    "tests/input/simple.txt" \
    "tests/input/blank_lines.txt" \
    "tests/input/tabs.txt"

for flag in "${TEST_FLAGS[@]}"
do
    run_test "multiple files | flag=$flag" "__NO_STDIN__" \
        "$flag" \
        "tests/input/simple.txt" \
        "tests/input/blank_lines.txt" \
        "tests/input/tabs.txt"
done

echo

echo -e "${YELLOW}Missing files${NC}"

run_test "missing file | no flags" "__NO_STDIN__" \
    "tests/input/does_not_exist.txt"

for flag in "${TEST_FLAGS[@]}"
do
    run_test "missing file | flag=$flag" "__NO_STDIN__" \
        "$flag" \
        "tests/input/does_not_exist.txt"
done

run_test "normal file + missing file | no flags" "__NO_STDIN__" \
    "tests/input/simple.txt" \
    "tests/input/does_not_exist.txt"

run_test "missing file + normal file | no flags" "__NO_STDIN__" \
    "tests/input/does_not_exist.txt" \
    "tests/input/simple.txt"

echo

echo -e "${YELLOW}Stdin through '-'${NC}"

run_test "stdin '-' | no flags" "tests/input/mixed.txt" "-"

for flag in "${TEST_FLAGS[@]}"
do
    run_test "stdin '-' | flag=$flag" "tests/input/mixed.txt" "$flag" "-"
done

echo

echo -e "${YELLOW}File + stdin + file${NC}"

run_test "file + stdin + file | no flags" "tests/input/blank_lines.txt" \
    "tests/input/simple.txt" \
    "-" \
    "tests/input/tabs.txt"

for flag in "${TEST_FLAGS[@]}"
do
    run_test "file + stdin + file | flag=$flag" "tests/input/blank_lines.txt" \
        "$flag" \
        "tests/input/simple.txt" \
        "-" \
        "tests/input/tabs.txt"
done

echo

LONG_FLAGS=(
    "--number-nonblank"
    "--number"
    "--squeeze-blank"
)

echo -e "${YELLOW}Long GNU options${NC}"

for flag in "${LONG_FLAGS[@]}"
do
    for file in "${FILES[@]}"
    do
        run_test "long flag=$flag | file=$file" "__NO_STDIN__" "$flag" "$file"
    done
done

echo

echo
echo -e "Summary"
echo -e "TOTAL:  ${YELLOW}$TOTAL${NC}"
echo -e "PASSED: ${GREEN}$PASSED${NC}"
echo -e "FAILED: ${RED}$FAILED${NC}"

if [ $FAILED -ne 0 ]; then
    echo
    echo -e "${YELLOW}Log:${NC}"
    echo -e "${BLUE}$FAIL_LOG${NC}"
    exit 1
fi

exit 0