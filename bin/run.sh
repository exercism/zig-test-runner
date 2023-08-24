#!/usr/bin/env bash

# Synopsis:
# Run the test runner on a solution.

# Arguments:
# $1: exercise slug
# $2: path to solution folder
# $3: path to output directory

# Output:
# Writes the test results to a results.json file in the passed-in output directory.
# The test results are formatted according to the specifications at https://github.com/exercism/docs/blob/main/building/tooling/test-runners/interface.md

# Example:
# ./bin/run.sh two-fer path/to/solution/folder/ path/to/output/directory/

# If any required arguments is missing, print the usage and exit
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo "usage: ./bin/run.sh exercise-slug path/to/solution/folder/ path/to/output/directory/"
    exit 1
fi

slug="$1"
test_file="test_${slug//-/_}.zig"
solution_dir=$(realpath "${2%/}")
output_dir=$(realpath "${3%/}")
results_file="${output_dir}/results.json"

# Create the output directory if it doesn't exist
mkdir -p "${output_dir}"

echo "${slug}: testing..."

pushd "${solution_dir}" > /dev/null

# Run the tests for the provided implementation file and redirect stdout and
# stderr to capture it
test_output=$(zig test "${test_file}" 2>&1)
exit_code=$?

popd > /dev/null

# Write the results.json file based on the exit code of the command that was 
# just executed that tested the implementation file
if [ ${exit_code} -eq 0 ]; then
    jq -n '{version: 1, status: "pass"}' > "${results_file}"
else
    # Sanitize the output
    sanitized_test_output=$(printf "${test_output}" | sed -n -e '/error: the following test command failed/q;p')

    # Try to distinguish between failing tests and errors
    if [[ ${sanitized_test_output} =~ "error:" ]]; then
        status="error"
    else
        status="fail"
    fi    

    jq -n --arg output "${sanitized_test_output}" --arg status "${status}" '{version: 1, status: $status, message: $output}' > "${results_file}"
fi

echo "${slug}: done"
