#!/usr/bin/gawk -f

# Synopsis:
# Extract per-test metadata from a Zig test file, for version 3 of
# https://github.com/exercism/docs/blob/main/building/tooling/test-runners/interface.md

# Two things are picked up for each test: the body of its test block, which
# is reported as "test_code", and the task it belongs to, which concept
# exercise test files mark with a comment:
#
#     // task 1
#     test "expected minutes in oven" { ... }
#
# A marker applies to every test that follows it, until the next marker.
# Tests declared before the first marker — which, in a practice exercise,
# means all of them — are left unlinked.

# Output:
# One record per test, in declaration order:
#
#     <RS> task id <US> name <US> test code
#
# where RS is 0x1e and US is 0x1f, and the task id is empty when the test is
# not linked to one. Emitting delimited text rather than JSON keeps every
# string escaping question in jq, where it is correct by construction.

# Requires GNU awk, for the third argument to match().

BEGIN {
    # The escape sequences Zig and JSON share; any other escape stands for
    # the character it precedes. Numeric escapes (\x41, \u{1F600}) are not
    # understood, so a test named with one is left unlinked rather than
    # linked to the wrong task.
    unescaped["n"] = "\n"
    unescaped["t"] = "\t"
    unescaped["r"] = "\r"
}

# Turn the body of a Zig string literal into the text it denotes, which is
# what zig prints when it runs the test, and so what we match against.
function unescape(s,    out, c) {
    while (s != "") {
        c = substr(s, 1, 1)
        s = substr(s, 2)
        if (c != "\\") {
            out = out c
            continue
        }
        c = substr(s, 1, 1)
        s = substr(s, 2)
        out = out (c in unescaped ? unescaped[c] : c)
    }
    return out
}

# Return the index of the closing quote of the literal opening at `i`.
function skip_literal(line, i, quote,    c) {
    while (i <= length(line)) {
        c = substr(line, i, 1)
        if (c == "\\") i++
        else if (c == quote) return i
        i++
    }
    return i
}

# Advance the brace depth across one line of Zig source, ignoring braces
# inside comments, character literals and string literals. Tracking depth
# rather than trusting `zig fmt` matters because students may edit and
# submit the test file of a practice exercise.
function scan_braces(line, depth,    i, c) {
    for (i = 1; i <= length(line); i++) {
        c = substr(line, i, 1)
        # Line comments and multiline string literals run to end of line.
        if (c == "/" && substr(line, i + 1, 1) == "/") break
        if (c == "\\" && substr(line, i + 1, 1) == "\\") break
        if (c == "\"" || c == "'") i = skip_literal(line, i + 1, c)
        else if (c == "{") depth++
        else if (c == "}") depth--
    }
    return depth
}

# Join the captured body lines, stripping the indentation they share and
# any blank lines top and bottom.
function dedent(count,    i, margin, out) {
    margin = -1
    for (i = 1; i <= count; i++) {
        if (body[i] ~ /^[[:space:]]*$/) continue
        match(body[i], /^[[:space:]]*/)
        if (margin < 0 || RLENGTH < margin) margin = RLENGTH
    }
    if (margin < 0) return ""
    for (i = 1; i <= count; i++) out = out (i == 1 ? "" : "\n") substr(body[i], margin + 1)
    sub(/^\n+/, "", out)
    sub(/\n+$/, "", out)
    return out
}

match($0, /^[[:space:]]*\/\/[[:space:]]*[Tt]ask[[:space:]]+([0-9]+)/, marker) {
    task = marker[1]
    next
}

# A test block: capture the lines up to the "}" that closes it. The closing
# line is left out, as is the header, so what remains is the body.
match($0, /^[[:space:]]*test[[:space:]]+"((\\.|[^"\\])*)"/, decl) {
    depth = scan_braces($0, 0)
    count = 0
    while (depth > 0 && (getline line) > 0) {
        depth = scan_braces(line, depth)
        if (depth > 0) body[++count] = line
    }
    printf "%c%s%c%s%c%s", 30, task, 31, unescape(decl[1]), 31, dedent(count)
    delete body
    next
}
