pub const expected_minutes_in_oven: u32 = 40;

pub fn remainingMinutesInOven(actual_minutes_in_oven: u32) u32 {
    return expected_minutes_in_oven - actual_minutes_in_oven;
}

pub fn preparationTimeInMinutes(number_of_layers: u32) u32 {
    return number_of_layers * 2;
}
