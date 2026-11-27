# SPOILERS: Day 5 solution scripts, run by tests/Test-Kit.ps1 (with -Headless) through
# analyzeHeadless -postScript <Script> <ScriptArgs> against the built Program. Each passes when the
# output contains every Expect string. The scripts print with println(), so their lines appear in
# the output as "<Script>> ...".
# The skeletons in lab/day5/scripts use the same class names, so never put both folders on
# Ghidra's script path at once.
@{
    Scripts = @(
        @{ Name = 'list functions';          Script = 'Day5ListFunctions.java';  Program = 'day1/ex1'; Expect = @('strcmp', ' thunk', 'Functions: ') }
        @{ Name = 'find strcmp calls';       Script = 'Day5FindCalls.java';      Program = 'day1/ex1'; Expect = @('string argument: "hunter2-ghidra"', 'Calls to strcmp: 1') }
        @{ Name = 'find puts calls';         Script = 'Day5FindCalls.java';      Program = 'day1/ex3'; Expect = @('string argument: "Debugger detected. Bye."', 'Calls to puts: 3')
           ScriptArgs = @('puts') }
        @{ Name = 'TEMP diag ex3 main';      Script = 'Day5Diag.java';           Program = 'day1/ex3'; Expect = @('__show_output__') }
        @{ Name = 'decode ex3 key';          Script = 'Day5DecodeKey.java';      Program = 'day1/ex3'; Expect = @('Key: R3v3rs1ng_D4y1') }
        @{ Name = 'decode day5 ex1 messages'; Script = 'Day5DecodeMessages.java'; Program = 'day5/ex1'; Expect = @('Unlock word: brass-lantern-7', "Keeper's log, week one.", '15 key 0xc1 sealed') }
    )
}
