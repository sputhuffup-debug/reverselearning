# SPOILERS: Day 1 answers, used by tests/Test-Kit.ps1 to check each built program.
#
# Each check runs <Program>.exe from the day's build folder with Input on stdin, and passes when the
# exit code is Exit and the output contains Expect. "{keygen}" in Input is replaced by the output of
# the Keygen script (in this folder) run with KeygenArgs; the check is skipped if Python is missing.
# Optional: Args = @('a', 'b') passes command-line arguments to the program (quoted if they contain spaces).
@{
    Checks = @(
        @{ Name = 'ex1 right password'; Program = 'ex1'; Input = @('hunter2-ghidra');      Exit = 0; Expect = 'Access granted!' }
        @{ Name = 'ex1 wrong password'; Program = 'ex1'; Input = @('hunter2');             Exit = 1; Expect = 'Access denied.' }
        @{ Name = 'ex2 alice/cfb71247'; Program = 'ex2'; Input = @('alice', 'cfb71247');   Exit = 0; Expect = 'Valid serial.' }
        @{ Name = 'ex2 wrong serial';   Program = 'ex2'; Input = @('alice', 'deadbeef');   Exit = 1; Expect = 'Invalid serial.' }
        @{ Name = 'ex2 short name';     Program = 'ex2'; Input = @('bob');                 Exit = 1; Expect = 'at least 4 characters' }
        @{ Name = 'ex2 keygen serial for reverser'; Program = 'ex2'; Input = @('reverser', '{keygen}'); Exit = 0; Expect = 'Valid serial.'
           Keygen = 'keygen_ex2.py'; KeygenArgs = @('reverser') }
        @{ Name = 'ex3 right key';      Program = 'ex3'; Input = @('R3v3rs1ng_D4y1');      Exit = 0; Expect = 'License OK.' }
        @{ Name = 'ex3 wrong key';      Program = 'ex3'; Input = @('R3v3rs1ng');           Exit = 0; Expect = 'Bad license key.' }
        @{ Name = 'checkpoint right code';    Program = 'checkpoint'; Input = @('Br34kp01nt'); Exit = 0; Expect = 'Unlocked. Checkpoint passed.' }
        @{ Name = 'checkpoint wrong code';    Program = 'checkpoint'; Input = @('Br34kp01nx'); Exit = 1; Expect = 'Wrong code.' }
        @{ Name = 'checkpoint table as text'; Program = 'checkpoint'; Input = @('Bs57ou68v}'); Exit = 1; Expect = 'Wrong code.' }
        @{ Name = 'checkpoint wrong length';  Program = 'checkpoint'; Input = @('Br34k');      Exit = 1; Expect = 'Wrong length.' }
    )
}
