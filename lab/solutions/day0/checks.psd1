# SPOILERS: Day 0 answers, used by tests/Test-Kit.ps1 to check each built program.
#
# Each check runs <Program>.exe from the day's build folder with Input on stdin, and passes when the
# exit code is Exit and the output contains Expect. "{keygen}" in Input is replaced by the output of
# the Keygen script (in this folder) run with KeygenArgs; the check is skipped if Python is missing.
# Optional: Args = @('a', 'b') passes command-line arguments to the program (quoted if they contain spaces).
@{
    Checks = @(
        @{ Name = 'sample right line';       Program = 'sample';     Input = @('channel=stable');  Exit = 0; Expect = 'Config OK: channel is stable.' }
        @{ Name = 'sample wrong value';      Program = 'sample';     Input = @('channel=beta');    Exit = 1; Expect = 'Config rejected.' }
        @{ Name = 'sample wrong key';        Program = 'sample';     Input = @('mode=stable');     Exit = 1; Expect = 'Unknown key.' }
        @{ Name = 'sample no equals sign';   Program = 'sample';     Input = @('stable');          Exit = 2; Expect = 'Bad format' }
        @{ Name = 'checkpoint right code';   Program = 'checkpoint'; Input = @('10847');           Exit = 0; Expect = 'Unlocked. Checkpoint passed.' }
        @{ Name = 'checkpoint wrong code';   Program = 'checkpoint'; Input = @('1234');            Exit = 1; Expect = 'Wrong code.' }
        @{ Name = 'checkpoint hex form';     Program = 'checkpoint'; Input = @('0x2a5f');          Exit = 2; Expect = 'Not a number.' }
        @{ Name = 'checkpoint decoy string'; Program = 'checkpoint'; Input = @('debug-override');  Exit = 3; Expect = 'Maintenance mode is disabled' }
    )
}
