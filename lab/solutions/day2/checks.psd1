# SPOILERS: Day 2 answers, used by tests/Test-Kit.ps1 to check each built program.
#
# Each check runs <Program>.exe from the day's build folder with Input on stdin, and passes when the
# exit code is Exit and the output contains Expect. "{keygen}" in Input is replaced by the output of
# the Keygen script (in this folder) run with KeygenArgs; the check is skipped if Python is missing.
# ex1o2, ex2o2 and ex3o2 are the Day 1 programs at -O2, so they take the Day 1 answers.
@{
    Checks = @(
        @{ Name = 'ex1o2 right password'; Program = 'ex1o2'; Input = @('hunter2-ghidra');    Exit = 0; Expect = 'Access granted!' }
        @{ Name = 'ex1o2 wrong password'; Program = 'ex1o2'; Input = @('hunter2');           Exit = 1; Expect = 'Access denied.' }
        @{ Name = 'ex2o2 alice/cfb71247'; Program = 'ex2o2'; Input = @('alice', 'cfb71247'); Exit = 0; Expect = 'Valid serial.' }
        @{ Name = 'ex2o2 wrong serial';   Program = 'ex2o2'; Input = @('alice', 'deadbeef'); Exit = 1; Expect = 'Invalid serial.' }
        @{ Name = 'ex2o2 short name';     Program = 'ex2o2'; Input = @('bob');               Exit = 1; Expect = 'at least 4 characters' }
        @{ Name = 'ex2o2 keygen serial for reverser'; Program = 'ex2o2'; Input = @('reverser', '{keygen}'); Exit = 0; Expect = 'Valid serial.'
           Keygen = '..\day1\keygen_ex2.py'; KeygenArgs = @('reverser') }
        @{ Name = 'ex3o2 right key';      Program = 'ex3o2'; Input = @('R3v3rs1ng_D4y1');    Exit = 0; Expect = 'License OK.' }
        @{ Name = 'ex3o2 wrong key';      Program = 'ex3o2'; Input = @('R3v3rs1ng');         Exit = 0; Expect = 'Bad license key.' }
        @{ Name = 'ex4 right code';       Program = 'ex4';   Input = @('25039268');          Exit = 0; Expect = 'Door open.' }
        @{ Name = 'ex4 wrong code';       Program = 'ex4';   Input = @('25039269');          Exit = 1; Expect = 'Access refused.' }
        @{ Name = 'ex4 not a number';     Program = 'ex4';   Input = @('25039268x');         Exit = 1; Expect = 'Access refused.' }
        @{ Name = 'ex4 code from solution script'; Program = 'ex4'; Input = @('{keygen}'); Exit = 0; Expect = 'Door open.'
           Keygen = 'ex4_code.py'; KeygenArgs = @() }
        @{ Name = 'ex4o2 right code';     Program = 'ex4o2'; Input = @('25039268');          Exit = 0; Expect = 'Door open.' }
        @{ Name = 'ex4o2 wrong code';     Program = 'ex4o2'; Input = @('25039269');          Exit = 1; Expect = 'Access refused.' }
        @{ Name = 'ex5 right pass';       Program = 'ex5';   Input = @('FR4ME-W4LK3R');      Exit = 0; Expect = 'Boarding pass accepted.' }
        @{ Name = 'ex5 wrong pass';       Program = 'ex5';   Input = @('FR4ME-WALKER');      Exit = 1; Expect = 'Boarding pass rejected.' }
        @{ Name = 'ex5 pass too long';    Program = 'ex5';   Input = @('FR4ME-W4LK3R2');     Exit = 1; Expect = 'Boarding pass rejected.' }
    )
}
