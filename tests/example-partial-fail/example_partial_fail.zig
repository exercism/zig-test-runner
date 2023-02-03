pub fn leap(year: u32) bool {
    return year % 4 == 0 and (year % 101 != 0 or year % 400 == 0);
}
