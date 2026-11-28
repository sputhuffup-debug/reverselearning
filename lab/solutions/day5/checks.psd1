# SPOILERS: Day 5 answers, used by tests/Test-Kit.ps1 to check each built program.
#
# Each check runs <Program>.exe from the day's build folder with Input on stdin, and passes when the
# exit code is Exit and the output contains Expect. "{keygen}" in Input is replaced by the output of
# the Keygen script (in this folder) run with KeygenArgs; the check is skipped if Python is missing.
# The Ghidra solution scripts for today are listed in scripts.psd1.
@{
    Checks = @(
        @{ Name = 'ex1 right unlock word';  Program = 'ex1'; Input = @('brass-lantern-7'); Exit = 0; Expect = 'Archive unlocked.' }
        @{ Name = 'ex1 retired unlock word'; Program = 'ex1'; Input = @('tin-beacon-3');   Exit = 1; Expect = 'Wrong unlock word.' }
        @{ Name = 'ex1 open message 1';     Program = 'ex1'; Input = @('1');               Exit = 0; Expect = "Message 1: Keeper's log, week one." }
        @{ Name = 'ex1 sealed message 15';  Program = 'ex1'; Input = @('15');              Exit = 1; Expect = 'Message 15 is sealed.' }
        @{ Name = 'ex1 no message 21';      Program = 'ex1'; Input = @('21');              Exit = 1; Expect = 'No such message.' }
        @{ Name = 'checkpoint right passphrase';  Program = 'checkpoint'; Input = @('north-relay-holds-at-dawn-42'); Exit = 0; Expect = 'Relay open.' }
        @{ Name = 'checkpoint decoy passphrase';  Program = 'checkpoint'; Input = @('south-relay-folds-at-dusk-17'); Exit = 1; Expect = 'Wrong passphrase.' }
        @{ Name = 'checkpoint one char short';    Program = 'checkpoint'; Input = @('north-relay-holds-at-dawn-4');  Exit = 1; Expect = 'Wrong passphrase.' }
        @{ Name = 'checkpoint table order';       Program = 'checkpoint'; Input = @('e-4n-ty2-wlhaloadra-r-tsohdn'); Exit = 1; Expect = 'Wrong passphrase.' }
    )
}
