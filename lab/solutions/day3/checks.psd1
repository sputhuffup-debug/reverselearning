# SPOILERS: Day 3 answers, used by tests/Test-Kit.ps1 to check each built program.
#
# Each check runs <Program>.exe from the day's build folder with Input on stdin, and passes when the
# exit code is Exit and the output contains Expect. "{keygen}" in Input is replaced by the output of
# the Keygen script (in this folder) run with KeygenArgs; the check is skipped if Python is missing.
@{
    Checks = @(
        @{ Name = 'ex1 right sequence 4 1 6 3 7'; Program = 'ex1'; Input = @('4', '1', '6', '3', '7');      Exit = 0; Expect = 'The vault opens.' }
        @{ Name = 'ex1 wrong order';              Program = 'ex1'; Input = @('1', '4', '6', '3', '7', '0'); Exit = 1; Expect = 'The vault stays shut.' }
        @{ Name = 'ex1 handle too early';         Program = 'ex1'; Input = @('4', '1', '7', '0');           Exit = 1; Expect = "The handle won't move." }
        @{ Name = 'ex2 right code';               Program = 'ex2'; Input = @('11389730');                   Exit = 0; Expect = 'Door unlocked.' }
        @{ Name = 'ex2 code not reversed';        Program = 'ex2'; Input = @('03798311');                   Exit = 1; Expect = 'Wrong code.' }
        @{ Name = 'ex2 short code';               Program = 'ex2'; Input = @('1138');                       Exit = 1; Expect = 'The code has 8 digits.' }
        @{ Name = 'ex2 solver code';              Program = 'ex2'; Input = @('{keygen}');                   Exit = 0; Expect = 'Door unlocked.'
           Keygen = 'solve_day3.py'; KeygenArgs = @('ex2') }
        @{ Name = 'ex3 right level';              Program = 'ex3'; Input = @('19');                         Exit = 0; Expect = 'You reached the top of the tower.' }
        @{ Name = 'ex3 wrong level';              Program = 'ex3'; Input = @('18');                         Exit = 1; Expect = 'Not this level.' }
        @{ Name = 'ex3 out of range';             Program = 'ex3'; Input = @('31');                         Exit = 1; Expect = 'Level out of range.' }
        @{ Name = 'ex3 solver level';             Program = 'ex3'; Input = @('{keygen}');                   Exit = 0; Expect = 'You reached the top of the tower.'
           Keygen = 'solve_day3.py'; KeygenArgs = @('ex3') }
        @{ Name = 'ex4 right passphrase';         Program = 'ex4'; Input = @('meadow-falcon-tundra-amber'); Exit = 0; Expect = 'Passphrase accepted.' }
        @{ Name = 'ex4 upper case accepted';      Program = 'ex4'; Input = @('MEADOW-Falcon-TUNDRA-amber'); Exit = 0; Expect = 'Passphrase accepted.' }
        @{ Name = 'ex4 table order';              Program = 'ex4'; Input = @('amber-falcon-meadow-tundra'); Exit = 1; Expect = 'Locked out.' }
        @{ Name = 'ex4 extra word';               Program = 'ex4'; Input = @('meadow-falcon-tundra-amber-orbit', 'meadow', 'x'); Exit = 1; Expect = 'Wrong passphrase.' }
    )
}
