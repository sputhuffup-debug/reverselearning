# SPOILERS: Day 3 answers, used by tests/Test-Kit.ps1 to check each built program.
#
# Each check runs <Program>.exe from the day's build folder with Input on stdin, and passes when the
# exit code is Exit and the output contains Expect. "{keygen}" in Input is replaced by the output of
# the Keygen script (in this folder) run with KeygenArgs; the check is skipped if Python is missing.
# Optional: Args = @('a', 'b') passes command-line arguments to the program (quoted if they contain spaces).
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
        @{ Name = 'ex5 grace with her code';      Program = 'ex5'; Args = @('grace', 'JUDFH');      Input = @(); Exit = 0; Expect = 'Badge accepted.' }
        @{ Name = 'ex5 barbara with her code';    Program = 'ex5'; Args = @('barbara', 'EDUEDUD');  Input = @(); Exit = 0; Expect = 'Badge accepted.' }
        @{ Name = 'ex5 code in lower case';       Program = 'ex5'; Args = @('grace', 'judfh');      Input = @(); Exit = 1; Expect = 'Wrong code.' }
        @{ Name = 'ex5 low clearance';            Program = 'ex5'; Args = @('linus', 'OLQXV');      Input = @(); Exit = 1; Expect = 'Clearance too low.' }
        @{ Name = 'ex5 unknown name';             Program = 'ex5'; Args = @('alice', '1234');       Input = @(); Exit = 1; Expect = 'Unknown name.' }
        @{ Name = 'ex5 name only';                Program = 'ex5'; Args = @('grace');               Input = @(); Exit = 2; Expect = 'Usage: ex5 <name> <code>' }
        @{ Name = 'ex5 no arguments';             Program = 'ex5';                                  Input = @(); Exit = 2; Expect = 'Usage: ex5 <name> <code>' }
        @{ Name = 'checkpoint right path';        Program = 'checkpoint'; Args = @('631236932');    Input = @(); Exit = 0; Expect = 'You found the way out.' }
        @{ Name = 'checkpoint path stops short';  Program = 'checkpoint'; Args = @('63123693');     Input = @(); Exit = 1; Expect = 'Still lost in the maze.' }
        @{ Name = 'checkpoint walks into a wall'; Program = 'checkpoint'; Args = @('2');            Input = @(); Exit = 1; Expect = 'You walk into a wall.' }
        @{ Name = 'checkpoint 5 is not a move';   Program = 'checkpoint'; Args = @('65');           Input = @(); Exit = 1; Expect = 'Unknown move.' }
        @{ Name = 'checkpoint too many moves';    Program = 'checkpoint'; Args = @('6464646464646'); Input = @(); Exit = 1; Expect = 'Too many moves.' }
        @{ Name = 'checkpoint no argument';       Program = 'checkpoint';                           Input = @(); Exit = 2; Expect = 'Usage: checkpoint <moves>' }
    )
}
