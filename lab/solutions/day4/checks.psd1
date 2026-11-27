# SPOILERS: Day 4 answers, used by tests/Test-Kit.ps1 to check each built program.
#
# Each check runs <Program>.exe from the day's build folder with Input on stdin, and passes when the
# exit code is Exit and the output contains Expect. "{keygen}" in Input is replaced by the output of
# the Keygen script (in this folder) run with KeygenArgs; the check is skipped if Python is missing.
@{
    Checks = @(
        @{ Name = 'ex1 reserved part 4417 x12';  Program = 'ex1'; Input = @('4417', '12');   Exit = 0; Expect = 'Order accepted: keystone' }
        @{ Name = 'ex1 wrong quantity';          Program = 'ex1'; Input = @('4417', '13');   Exit = 1; Expect = 'Order refused.' }
        @{ Name = 'ex1 part not reserved';       Program = 'ex1'; Input = @('3075', '12');   Exit = 1; Expect = 'Order refused.' }
        @{ Name = 'ex1 unknown part';            Program = 'ex1'; Input = @('9999', '1');    Exit = 1; Expect = 'Unknown part.' }
        @{ Name = 'ex1 substitute hint';         Program = 'ex1'; Input = @('1001', '50');   Exit = 1; Expect = 'try part 1002' }
        @{ Name = 'ex2 right pick code';         Program = 'ex2'; Input = @('W4LK-TH3-L1ST'); Exit = 0; Expect = 'Pick list confirmed.' }
        @{ Name = 'ex2 code one short';          Program = 'ex2'; Input = @('W4LK-TH3-L1S');  Exit = 1; Expect = 'Wrong pick code.' }
        @{ Name = 'ex2 code one too long';       Program = 'ex2'; Input = @('W4LK-TH3-L1STX'); Exit = 1; Expect = 'Wrong pick code.' }
        @{ Name = 'ex3 restock 7002 x13';        Program = 'ex3'; Input = @('7002', '13');   Exit = 0; Expect = 'Restock approved: 13 x valve' }
        @{ Name = 'ex3 part not on the shelf';   Program = 'ex3'; Input = @('7007', '40');   Exit = 1; Expect = 'Restock rejected.' }
        @{ Name = 'ex3 untracked part';          Program = 'ex3'; Input = @('7003', '19');   Exit = 1; Expect = 'Restock rejected.' }
        @{ Name = 'ex3 wrong quantity';          Program = 'ex3'; Input = @('7002', '12');   Exit = 1; Expect = 'Restock rejected.' }
    )
}
