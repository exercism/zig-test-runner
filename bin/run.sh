#!/usr/bin/env bash

# Synopsis:
# Run the Exercism Zig test runner on a solution.

# Arguments:
# $1: exercise slug
# $2: path to solution folder
# $3: path to output directory

# Output:
# Writes a v2 results.json to the output directory, per
# https://github.com/exercism/docs/blob/main/building/tooling/test-runners/interface.md

# Example:
# ./bin/run.sh two-fer path/to/solution/folder/ path/to/output/directory/

# Print usage and exit non-zero. Called when required args are missing.
usage() {
    echo "usage: ./bin/run.sh exercise-slug path/to/solution/folder/ path/to/output/directory/"
    exit 1
}

# Parse positional args, set globals consumed by later stages.
# Sets: slug, test_file, solution_dir, output_dir, results_file.
parse_args() {
    [[ -z "$1" || -z "$2" || -z "$3" ]] && usage
    slug="$1"
    test_file="$(echo "test_${slug}.zig" | tr '-' '_')"
    solution_dir=$(realpath "${2%/}")
    output_dir=$(realpath "${3%/}")
    results_file="${output_dir}/results.json"
}

# Compile and run the solution's test file, strip the solution-dir prefix
# and the "test command failed" trailer from the output so it is portable.
# Prints the sanitized output to stdout and returns zig's exit code.
run_zig_test() {
    local raw_output zig_exit
    raw_output=$(cd "${solution_dir}" && zig test -target x86_64-linux-musl "${test_file}" 2>&1)
    zig_exit=$?
    printf '%s' "${raw_output}" \
        | sed -e "s#${solution_dir}/\{0,1\}##g" \
              -e '/error: the following test command failed/,$d'
    return "${zig_exit}"
}

# Emit a top-level error report (compile failure) and exit successfully —
# the runner completed its job even though the solution did not build.
emit_compile_error() {
    jq -n --arg message "${test_output}" \
        '{version: 2, status: "error", message: $message}' > "${results_file}"
    echo "${slug}: done"
    exit 0
}

# Parse Zig's per-test output into a JSON array of test records.
# Zig test output has one line per test, optionally followed by user
# stdout and a status line:
#   1/5 test_file.test.TEST NAME...OK                     (no user output)
#   2/5 test_file.test.TEST NAME...Hello, World!          (user output)
#   OK                                                     (status on next line)
#   3/5 test_file.test.TEST NAME...FAIL (reason)          (immediate fail)
# Failed tests are followed by stack trace lines until the next test line
# or the summary ("N passed; N skipped; N failed."). Parsing is done in
# two passes: `segment` groups the raw lines into per-test blocks, then
# `classify` turns each block into a single JSON test record.
build_tests_json() {
    printf '%s' "${test_output}" | jq -Rs '
        def test_name: capture("test\\.(?<n>.+)\\.\\.\\.") | .n;
        def user_output: capture("\\.\\.\\.((?<o>.+)$)") | .o // "";
        def is_test_line: test("[0-9]+/[0-9]+ .*\\.test\\..*\\.\\.\\.");
        def is_summary: startswith("All ") or test("[0-9]+ passed;");
        def is_ok: . == "OK" or endswith("OK");
        def is_fail: startswith("FAIL") or test("\\.\\.\\.(FAIL|expected )");

        # Per-outcome record constructors. These set the leading fields;
        # classify extends records via `.field = ...` in the same order,
        # producing {name, status, message, output}.
        def pass_record(name): {name: name, status: "pass"};
        def fail_record(name): {name: name, status: "fail", message: ""};

        # Pass 1 — segment the flat output into per-test line groups.
        # A new group opens on a test-header line; the current group
        # closes on the next test-header line or on the summary line.
        def segment:
            split("\n")
            | reduce .[] as $line (
                {current: null, groups: []};
                if ($line | is_test_line) then
                    (if .current then .groups += [.current] else . end)
                    | .current = [$line]
                elif ($line | is_summary) then
                    (if .current then .groups += [.current] else . end)
                    | .current = null
                elif .current then
                    .current += [$line]
                else . end
            )
            | if .current then .groups += [.current] else .groups end;

        # Pass 2 — turn one line group into one test record.
        # Three shapes handled:
        #   (a) header ends with OK       → immediate pass, no output
        #   (b) header has FAIL/expected  → immediate fail, message is
        #                                    the stack trace in $rest
        #   (c) otherwise                 → pending: user output on the
        #                                    header, status line lives
        #                                    somewhere in $rest
        def classify:
            .[0] as $header
            | ($header | test_name) as $name
            | ($header | user_output) as $header_output
            | .[1:] as $rest
            | if ($header | endswith("OK")) then
                pass_record($name)
            elif ($header | is_fail) then
                fail_record($name)
                | .message = ($rest | join("\n") | sub("\n+$"; ""))
            else
                ($rest | map(is_ok or is_fail) | index(true)) as $i
                | $rest[:$i] as $extra_output
                | $rest[$i:] as $from_status
                | ($header_output
                   + (if ($extra_output | length) > 0
                      then "\n" + ($extra_output | join("\n"))
                      else "" end)) as $output
                | if $from_status[0] | is_ok then
                    pass_record($name) | .output = $output
                else
                    fail_record($name)
                    | .message = ($from_status | join("\n") | sub("\n+$"; ""))
                    | .output = $output
                end
            end;

        segment
        | map(classify)
        | map(
            if .message == "" or .message == null then del(.message) else . end
            | if .output == "" or .output == null then del(.output) else . end
        )
    '
}

# Write the final results.json. Truncates each test's "output" field to
# 500 chars to bound report size.
assemble_report() {
    local overall="$1"
    local tests_json="$2"
    jq -n --arg status "${overall}" --argjson tests "${tests_json}" '
        def trunc: if length > 500 then .[:481] + " [output truncated]" else . end;
        {version: 2, status: $status, tests: ($tests | map(
            if .output then .output |= trunc else . end
        ))}
    ' > "${results_file}"
}

main() {
    parse_args "$@"
    mkdir -p "${output_dir}"
    echo "${slug}: testing..."

    local any_failed=0
    test_output=$(run_zig_test) || any_failed=1
    if (( any_failed )) && [[ "${test_output}" = *error:* ]]; then
        emit_compile_error
    fi

    local tests_json overall
    tests_json=$(build_tests_json)
    if (( any_failed == 0 )); then
        overall="pass"
    else
        overall="fail"
    fi
    assemble_report "${overall}" "${tests_json}"

    echo "${slug}: done"
}

main "$@"
