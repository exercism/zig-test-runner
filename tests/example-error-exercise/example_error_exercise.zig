pub const ComputationError = error{
    IllegalArgument,
};

pub fn steps(start: usize) ComputationError!usize {
    // Bug: doesn't return error for zero input
    var n = start;
    var result: usize = 0;
    while (n > 1) {
        n = if (n % 2 == 0) n / 2 else 3 * n + 1;
        result += 1;
    }
    return result;
}
