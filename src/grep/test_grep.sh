#!/bin/bash

MY_GREP="./s21_grep"
REAL_GREP="grep"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
GRAY='\033[0;90m'
NC='\033[0m'

mkdir -p tests/input
mkdir -p tests/output

FAIL_LOG="tests/output/failures_grep.log"
: > "$FAIL_LOG"

export LC_ALL=C

TEST_ALL_COMBINATIONS=1

cat > tests/input/simple.txt <<'EOF'
hello
world
Hello
HELLO
line with hello
another line
EOF

cat > tests/input/blank_lines.txt <<'EOF'
first

second


third

EOF

cat > tests/input/numbers.txt <<'EOF'
abc123
123abc
no digits
456
line 789 line
EOF

cat > tests/input/mixed.txt <<'EOF'
hello world
HELLO WORLD
HeLLo WoRLd
cat
concatenate
dog
grep test
test grep
EOF

cat > tests/input/repeated.txt <<'EOF'
hello hello hello
hello
world hello
nothing
EOF

cat > tests/input/special.txt <<'EOF'
a.b
acb
a*b
aaaab
[hello]
hello?
hello+
^hello
hello$
EOF

cat > tests/input/no_matches.txt <<'EOF'
apple
banana
orange
EOF

touch tests/input/empty.txt

cat > tests/input/patterns_1.txt <<'EOF'
hello
world
EOF

cat > tests/input/patterns_2.txt <<'EOF'
HELLO
cat
123
EOF

cat > tests/input/patterns_regex.txt <<'EOF'
^hello
[0-9]
a.b
EOF

cat > tests/input/patterns_empty.txt <<'EOF'
EOF

cat > tests/input/patterns_blank_line.txt <<'EOF'

hello
EOF

FILES=(
    "tests/input/simple.txt"
    "tests/input/blank_lines.txt"
    "tests/input/numbers.txt"
    "tests/input/mixed.txt"
    "tests/input/repeated.txt"
    "tests/input/special.txt"
    "tests/input/no_matches.txt"
    "tests/input/empty.txt"
)

PATTERNS=(
    "hello"
    "HELLO"
    "world"
    "line"
    "cat"
    "123"
    "[0-9]"
    "^hello"
    "hello$"
    "a.b"
    "not_found_pattern"
)

SHORT_FLAGS=(
    "i"
    "v"
    "c"
    "l"
    "n"
    "h"
    "s"
    "o"
)

TEST_FLAGS=(
    "-i"
    "-v"
    "-c"
    "-l"
    "-n"
    "-h"
    "-s"
    "-o"

    "-iv"
    "-vi"
    "-in"
    "-ni"
    "-ic"
    "-ci"
    "-il"
    "-li"

    "-vn"
    "-nv"
    "-vc"
    "-cv"
    "-vl"
    "-lv"

    "-cn"
    "-nc"
    "-cl"
    "-lc"
    "-ln"
    "-nl"

    "-ho"
    "-oh"
    "-no"
    "-on"
    "-io"
    "-oi"

    "-ivn"
    "-nvi"
    "-inc"
    "-vcl"
    "-inh"
    "-iov"
    "-oin"
    "-hno"
)

PATTERN_FILES=(
    "tests/input/patterns_1.txt"
    "tests/input/patterns_2.txt"
    "tests/input/patterns_regex.txt"
    "tests/input/patterns_empty.txt"
    "tests/input/patterns_blank_line.txt"
)

TOTAL=0
PASSED=0
FAILED=0

print_command() {
    local cmd="$1"
    shift

    printf "%q" "$cmd"

    for arg in "$@"
    do
        printf " %q" "$arg"
    done
}

normalize_stderr() {
    local input_file="$1"
    local output_file="$2"

    sed -E \
        -e 's#^grep:#GREP:#' \
        -e 's#^\./s21_grep:#GREP:#' \
        -e 's#^s21_grep:#GREP:#' \
        "$input_file" > "$output_file"
}

run_test() {
    local test_name="$1"
    local stdin_file="$2"
    shift 2

    local args=("$@")

    TOTAL=$((TOTAL + 1))

    local expected="tests/output/grep_expected.txt"
    local actual="tests/output/grep_actual.txt"
    local diff_file="tests/output/grep_diff.txt"

    local expected_err_raw="tests/output/grep_expected.err.raw"
    local actual_err_raw="tests/output/grep_actual.err.raw"

    local expected_err="tests/output/grep_expected.err"
    local actual_err="tests/output/grep_actual.err"
    local diff_err="tests/output/grep_diff_err.txt"

    local real_code
    local my_code

    if [ "$stdin_file" = "__NO_STDIN__" ]; then
        "$REAL_GREP" "${args[@]}" > "$expected" 2> "$expected_err_raw"
        real_code=$?

        "$MY_GREP" "${args[@]}" > "$actual" 2> "$actual_err_raw"
        my_code=$?
    else
        "$REAL_GREP" "${args[@]}" < "$stdin_file" > "$expected" 2> "$expected_err_raw"
        real_code=$?

        "$MY_GREP" "${args[@]}" < "$stdin_file" > "$actual" 2> "$actual_err_raw"
        my_code=$?
    fi

    normalize_stderr "$expected_err_raw" "$expected_err"
    normalize_stderr "$actual_err_raw" "$actual_err"

    diff -u "$expected" "$actual" > "$diff_file"
    local out_diff_code=$?

    diff -u "$expected_err" "$actual_err" > "$diff_err"
    local err_diff_code=$?

    if [ $out_diff_code -eq 0 ] && [ $err_diff_code -eq 0 ] && [ $real_code -eq $my_code ]; then
        PASSED=$((PASSED + 1))
        printf "${GREEN}[%04d] OK${NC}    ${GRAY}%s${NC}\n" "$TOTAL" "$test_name"
    else
        FAILED=$((FAILED + 1))

        {
            printf "[%04d] FAIL  %s\n" "$TOTAL" "$test_name"

            echo -n "real: "
            print_command "$REAL_GREP" "${args[@]}"
            if [ "$stdin_file" != "__NO_STDIN__" ]; then
                printf " < %q" "$stdin_file"
            fi
            echo

            echo -n "mine:   "
            print_command "$MY_GREP" "${args[@]}"
            if [ "$stdin_file" != "__NO_STDIN__" ]; then
                printf " < %q" "$stdin_file"
            fi
            echo
            echo "real exit code: $real_code"
            echo "my exit code:   $my_code"

            if [ $out_diff_code -ne 0 ]; then
                echo "stdout diff:"
                echo "--- expected = system grep"
                echo "+++ actual   = your s21_grep"
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
                echo "--- expected stderr = system grep"
                echo "+++ actual stderr   = your s21_grep"
                cat "$diff_err"

                echo
                echo "expected stderr raw:"
                cat -A "$expected_err_raw"

                echo
                echo "actual stderr raw:"
                cat -A "$actual_err_raw"
            fi

            echo
        } >> "$FAIL_LOG"

        echo
        printf "${RED}[%04d] FAIL${NC}  %s\n" "$TOTAL" "$test_name"

        echo -ne "${BLUE}real:${NC} "
        print_command "$REAL_GREP" "${args[@]}"
        if [ "$stdin_file" != "__NO_STDIN__" ]; then
            printf " < %q" "$stdin_file"
        fi
        echo

        echo -ne "${BLUE}mine:  ${NC} "
        print_command "$MY_GREP" "${args[@]}"
        if [ "$stdin_file" != "__NO_STDIN__" ]; then
            printf " < %q" "$stdin_file"
        fi
        echo
        echo -e "real exit code: ${YELLOW}$real_code${NC}"
        echo -e "my exit code:   ${YELLOW}$my_code${NC}"

        if [ $out_diff_code -ne 0 ]; then
            echo -e "${YELLOW}stdout diff:${NC}"
            echo -e "${GRAY}--- expected = system grep${NC}"
            echo -e "${GRAY}+++ actual   = your s21_grep${NC}"
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
            echo -e "${GRAY}--- expected stderr = system grep${NC}"
            echo -e "${GRAY}+++ actual stderr   = your s21_grep${NC}"
            cat "$diff_err"

            echo
            echo -e "${YELLOW}expected stderr raw:${NC}"
            cat -A "$expected_err_raw"

            echo
            echo -e "${YELLOW}actual stderr raw:${NC}"
            cat -A "$actual_err_raw"
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

echo -e "${BLUE}Testing s21_grep${NC}"
echo -e "${GRAY}MY_GREP:   $MY_GREP${NC}"
echo -e "${GRAY}REAL_GREP: $REAL_GREP${NC}"
echo -e "${GRAY}FAIL_LOG:  $FAIL_LOG${NC}"
echo

if [ ! -x "$MY_GREP" ]; then
    echo -e "${RED}ERROR:${NC} $MY_GREP not found or not executable"
    echo "Build the program first, for example:"
    echo "  make"
    echo
    echo "Or change MY_GREP at the top of the script."
    exit 1
fi

echo -e "${YELLOW}No flags${NC}"

for pattern in "${PATTERNS[@]}"
do
    for file in "${FILES[@]}"
    do
        run_test "no flags | pattern=$pattern | file=$file" "__NO_STDIN__" "$pattern" "$file"
    done
done

echo

echo -e "${YELLOW}Selected flags${NC}"

for flag in "${TEST_FLAGS[@]}"
do
    for pattern in "${PATTERNS[@]}"
    do
        for file in "${FILES[@]}"
        do
            run_test "flag=$flag | pattern=$pattern | file=$file" "__NO_STDIN__" "$flag" "$pattern" "$file"
        done
    done
done

echo

if [ "$TEST_ALL_COMBINATIONS" -eq 1 ]; then
    echo -e "${YELLOW}Flag combinations${NC}"

    while read -r flag
    do
        for pattern in "${PATTERNS[@]}"
        do
            for file in "${FILES[@]}"
            do
                run_test "combo=$flag | pattern=$pattern | file=$file" "__NO_STDIN__" "$flag" "$pattern" "$file"
            done
        done
    done < <(generate_all_flag_combinations)

    echo
else
    echo -e "${YELLOW}Flag combinations skipped${NC}"
    echo
fi

echo -e "${YELLOW}Multiple files${NC}"

for pattern in "hello" "HELLO" "123" "[0-9]" "not_found_pattern"
do
    run_test "multiple files | no flags | pattern=$pattern" "__NO_STDIN__" \
        "$pattern" \
        "tests/input/simple.txt" \
        "tests/input/mixed.txt" \
        "tests/input/numbers.txt"
done

for flag in "${TEST_FLAGS[@]}"
do
    for pattern in "hello" "HELLO" "123" "[0-9]" "not_found_pattern"
    do
        run_test "multiple files | flag=$flag | pattern=$pattern" "__NO_STDIN__" \
            "$flag" \
            "$pattern" \
            "tests/input/simple.txt" \
            "tests/input/mixed.txt" \
            "tests/input/numbers.txt"
    done
done

echo

echo -e "${YELLOW}-e pattern${NC}"

for file in "${FILES[@]}"
do
    run_test "-e single | file=$file" "__NO_STDIN__" "-e" "hello" "$file"
    run_test "-e single with -i | file=$file" "__NO_STDIN__" "-i" "-e" "hello" "$file"
    run_test "-e single with -n | file=$file" "__NO_STDIN__" "-n" "-e" "hello" "$file"
    run_test "-e single with -v | file=$file" "__NO_STDIN__" "-v" "-e" "hello" "$file"
    run_test "-e single with -c | file=$file" "__NO_STDIN__" "-c" "-e" "hello" "$file"
    run_test "-e single with -l | file=$file" "__NO_STDIN__" "-l" "-e" "hello" "$file"
    run_test "-e single with -o | file=$file" "__NO_STDIN__" "-o" "-e" "hello" "$file"

    run_test "-e multiple | file=$file" "__NO_STDIN__" "-e" "hello" "-e" "world" "$file"
    run_test "-e multiple with -i | file=$file" "__NO_STDIN__" "-i" "-e" "hello" "-e" "world" "$file"
    run_test "-e multiple with -n | file=$file" "__NO_STDIN__" "-n" "-e" "hello" "-e" "world" "$file"
    run_test "-e multiple with -v | file=$file" "__NO_STDIN__" "-v" "-e" "hello" "-e" "world" "$file"
    run_test "-e multiple with -c | file=$file" "__NO_STDIN__" "-c" "-e" "hello" "-e" "world" "$file"
    run_test "-e multiple with -l | file=$file" "__NO_STDIN__" "-l" "-e" "hello" "-e" "world" "$file"
    run_test "-e multiple with -o | file=$file" "__NO_STDIN__" "-o" "-e" "hello" "-e" "world" "$file"

    run_test "-e empty pattern | file=$file" "__NO_STDIN__" "-e" "" "$file"
    run_test "-i -e empty pattern | file=$file" "__NO_STDIN__" "-i" "-e" "" "$file"
done

echo

echo -e "${YELLOW}-f files${NC}"

for pattern_file in "${PATTERN_FILES[@]}"
do
    for file in "${FILES[@]}"
    do
        run_test "-f $pattern_file | file=$file" "__NO_STDIN__" "-f" "$pattern_file" "$file"
        run_test "-f $pattern_file with -i | file=$file" "__NO_STDIN__" "-i" "-f" "$pattern_file" "$file"
        run_test "-f $pattern_file with -n | file=$file" "__NO_STDIN__" "-n" "-f" "$pattern_file" "$file"
        run_test "-f $pattern_file with -v | file=$file" "__NO_STDIN__" "-v" "-f" "$pattern_file" "$file"
        run_test "-f $pattern_file with -c | file=$file" "__NO_STDIN__" "-c" "-f" "$pattern_file" "$file"
        run_test "-f $pattern_file with -l | file=$file" "__NO_STDIN__" "-l" "-f" "$pattern_file" "$file"
        run_test "-f $pattern_file with -o | file=$file" "__NO_STDIN__" "-o" "-f" "$pattern_file" "$file"
    done
done

echo

echo -e "${YELLOW}-e and -f together${NC}"

for file in "${FILES[@]}"
do
    run_test "-e hello -f patterns_1 | file=$file" "__NO_STDIN__" \
        "-e" "hello" "-f" "tests/input/patterns_1.txt" "$file"

    run_test "-i -e hello -f patterns_2 | file=$file" "__NO_STDIN__" \
        "-i" "-e" "hello" "-f" "tests/input/patterns_2.txt" "$file"

    run_test "-n -e hello -f patterns_regex | file=$file" "__NO_STDIN__" \
        "-n" "-e" "hello" "-f" "tests/input/patterns_regex.txt" "$file"

    run_test "-c -e hello -f patterns_regex | file=$file" "__NO_STDIN__" \
        "-c" "-e" "hello" "-f" "tests/input/patterns_regex.txt" "$file"

    run_test "-l -e hello -f patterns_regex | file=$file" "__NO_STDIN__" \
        "-l" "-e" "hello" "-f" "tests/input/patterns_regex.txt" "$file"

    run_test "-o -e hello -f patterns_regex | file=$file" "__NO_STDIN__" \
        "-o" "-e" "hello" "-f" "tests/input/patterns_regex.txt" "$file"

    run_test "-ivn -e hello -f patterns_regex | file=$file" "__NO_STDIN__" \
        "-ivn" "-e" "hello" "-f" "tests/input/patterns_regex.txt" "$file"

    run_test "-cl -e hello -f patterns_regex | file=$file" "__NO_STDIN__" \
        "-cl" "-e" "hello" "-f" "tests/input/patterns_regex.txt" "$file"
done

echo

echo -e "${YELLOW}Stdin${NC}"

run_test "stdin | no flags | pattern=hello" "tests/input/mixed.txt" "hello"
run_test "stdin | -i | pattern=hello" "tests/input/mixed.txt" "-i" "hello"
run_test "stdin | -n | pattern=hello" "tests/input/mixed.txt" "-n" "hello"
run_test "stdin | -v | pattern=hello" "tests/input/mixed.txt" "-v" "hello"
run_test "stdin | -c | pattern=hello" "tests/input/mixed.txt" "-c" "hello"
run_test "stdin | -l | pattern=hello" "tests/input/mixed.txt" "-l" "hello"
run_test "stdin | -h | pattern=hello" "tests/input/mixed.txt" "-h" "hello"
run_test "stdin | -s | pattern=hello" "tests/input/mixed.txt" "-s" "hello"
run_test "stdin | -o | pattern=hello" "tests/input/mixed.txt" "-o" "hello"
run_test "stdin | -ivn | pattern=hello" "tests/input/mixed.txt" "-ivn" "hello"
run_test "stdin | -e hello" "tests/input/mixed.txt" "-e" "hello"
run_test "stdin | -e hello -e world" "tests/input/mixed.txt" "-e" "hello" "-e" "world"
run_test "stdin | -f patterns_1" "tests/input/mixed.txt" "-f" "tests/input/patterns_1.txt"
run_test "stdin | -i -f patterns_2" "tests/input/mixed.txt" "-i" "-f" "tests/input/patterns_2.txt"

echo

echo -e "${YELLOW}Missing files${NC}"

run_test "missing file | no flags" "__NO_STDIN__" \
    "hello" \
    "tests/input/does_not_exist.txt"

run_test "normal file + missing file | no flags" "__NO_STDIN__" \
    "hello" \
    "tests/input/simple.txt" \
    "tests/input/does_not_exist.txt"

run_test "missing file + normal file | no flags" "__NO_STDIN__" \
    "hello" \
    "tests/input/does_not_exist.txt" \
    "tests/input/simple.txt"

run_test "missing file with -s" "__NO_STDIN__" \
    "-s" \
    "hello" \
    "tests/input/does_not_exist.txt"

run_test "normal + missing with -s" "__NO_STDIN__" \
    "-s" \
    "hello" \
    "tests/input/simple.txt" \
    "tests/input/does_not_exist.txt"

run_test "missing file with -c" "__NO_STDIN__" \
    "-c" \
    "hello" \
    "tests/input/does_not_exist.txt"

run_test "missing file with -l" "__NO_STDIN__" \
    "-l" \
    "hello" \
    "tests/input/does_not_exist.txt"

run_test "missing -f file with -f" "__NO_STDIN__" \
    "-f" \
    "tests/input/no_such_patterns.txt" \
    "tests/input/simple.txt"

run_test "missing -f file with -s -f" "__NO_STDIN__" \
    "-s" \
    "-f" \
    "tests/input/no_such_patterns.txt" \
    "tests/input/simple.txt"

echo

echo -e "${YELLOW}Flag order${NC}"

run_test "order -in | pattern=hello" "__NO_STDIN__" "-in" "hello" "tests/input/simple.txt"
run_test "order -ni | pattern=hello" "__NO_STDIN__" "-ni" "hello" "tests/input/simple.txt"

run_test "order -cv | pattern=hello" "__NO_STDIN__" "-cv" "hello" "tests/input/simple.txt"
run_test "order -vc | pattern=hello" "__NO_STDIN__" "-vc" "hello" "tests/input/simple.txt"

run_test "order -lo | pattern=hello" "__NO_STDIN__" "-lo" "hello" "tests/input/simple.txt"
run_test "order -ol | pattern=hello" "__NO_STDIN__" "-ol" "hello" "tests/input/simple.txt"

run_test "order -hn | pattern=hello" "__NO_STDIN__" "-hn" "hello" "tests/input/simple.txt"
run_test "order -nh | pattern=hello" "__NO_STDIN__" "-nh" "hello" "tests/input/simple.txt"

run_test "order -oi | pattern=hello" "__NO_STDIN__" "-oi" "hello" "tests/input/simple.txt"
run_test "order -io | pattern=hello" "__NO_STDIN__" "-io" "hello" "tests/input/simple.txt"

echo

echo -e "${YELLOW}-h with multiple files${NC}"

run_test "-h multiple files | pattern=hello" "__NO_STDIN__" \
    "-h" \
    "hello" \
    "tests/input/simple.txt" \
    "tests/input/mixed.txt"

run_test "-hn multiple files | pattern=hello" "__NO_STDIN__" \
    "-hn" \
    "hello" \
    "tests/input/simple.txt" \
    "tests/input/mixed.txt"

run_test "-ho multiple files | pattern=hello" "__NO_STDIN__" \
    "-ho" \
    "hello" \
    "tests/input/simple.txt" \
    "tests/input/mixed.txt"

run_test "-hc multiple files | pattern=hello" "__NO_STDIN__" \
    "-hc" \
    "hello" \
    "tests/input/simple.txt" \
    "tests/input/mixed.txt"

echo

echo -e "${YELLOW}-o checks${NC}"

run_test "-o repeated matches" "__NO_STDIN__" \
    "-o" \
    "hello" \
    "tests/input/repeated.txt"

run_test "-on repeated matches" "__NO_STDIN__" \
    "-on" \
    "hello" \
    "tests/input/repeated.txt"

run_test "-io repeated matches" "__NO_STDIN__" \
    "-io" \
    "hello" \
    "tests/input/simple.txt"

run_test "-vo combination" "__NO_STDIN__" \
    "-vo" \
    "hello" \
    "tests/input/simple.txt"

run_test "-co combination" "__NO_STDIN__" \
    "-co" \
    "hello" \
    "tests/input/simple.txt"

run_test "-lo combination" "__NO_STDIN__" \
    "-lo" \
    "hello" \
    "tests/input/simple.txt"

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
