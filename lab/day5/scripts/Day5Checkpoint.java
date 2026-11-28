// Day 5 checkpoint: recover the passphrase that checkpoint.exe in bin/day5 asks for.
// Skeleton: it compiles and runs as it is, and prints nothing until you fill in the TODOs.
//
// Use the five steps from the guide, in this order:
//   1. By hand first. Find the code that checks the passphrase and the data it reads. Work out how
//      one record is laid out and how the check uses it. Decode 2 or 3 records by hand, in your notes.
//   2. Plan in words. Write one line per step in your notes, and compare it with the TODOs below.
//   3. Fill one TODO at a time.
//   4. Run the script after each TODO and compare what it prints with your notes.
//   5. Comment every line you wrote, saying what it does and why.
//@category Course.Day5

import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.Instruction;
import ghidra.program.model.listing.InstructionIterator;
import ghidra.program.model.mem.MemoryBlock;
import ghidra.program.model.symbol.Reference;

public class Day5Checkpoint extends GhidraScript {

    // TODO 1: Replace the zeros with what you worked out by hand: the size of one record, the number
    //         of records, and the offset of each field the check reads. Add a constant for anything
    //         else the check tests, such as a flag bit. Rename the fields to match your notes.
    private static final int RECORD_SIZE = 0;
    private static final int COUNT = 0;
    private static final int FIELD_A = 0;
    private static final int FIELD_B = 0;

    @Override
    protected void run() throws Exception {
        // TODO 2: Find a string that main prints, follow a reference to main, and print main's address.
        //         Look up findBytes(Address, String), getReferencesTo(Address) and
        //         getFunctionContaining(Address). Print a message and return if anything is null.

        // TODO 3: Find the function that does the check, starting from main. Decide from your notes how
        //         to recognize its call, and print its address. Look up getInstructions(AddressSetView,
        //         boolean) on currentProgram.getListing(), Instruction.getFlowType().isCall(),
        //         Instruction.getFlows(), getFunctionAt(Address) and Function.isThunk().

        // TODO 4: Find the table from the code that reads it, without a hardcoded address, and print it.
        //         Look up Instruction.getReferencesFrom(), Address.isMemoryAddress(),
        //         getMemoryBlock(Address), MemoryBlock.getName() and Address.compareTo(Address).
        //         Check: the address matches your notes. More than one instruction may point into it.

        // TODO 5: Loop over the records. Read each field, undo the encoding you worked out by hand, and
        //         print one line per record. Check the records you decoded by hand first.
        //         Look up Address.add(long) and getByte(Address); mask each byte with & 0xff.

        // TODO 6: Skip the records the check skips, put the rest in the order the check uses, and print
        //         the passphrase. Print a message if a position is missing or used twice.
        //         Arrays or a java.util.List both work; see the primer if you need a reminder.
    }
}
