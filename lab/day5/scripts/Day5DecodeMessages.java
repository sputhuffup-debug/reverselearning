// Day 5, Exercise 5.4: decode every message in Day 5's ex1, sealed ones included.
// Find the message table from the code that uses it, then XOR each record's text with its own key.
// Skeleton: it compiles and runs as it is, and prints nothing until you fill in the TODOs.
//@category Course.Day5

import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.Instruction;
import ghidra.program.model.listing.InstructionIterator;
import ghidra.program.model.mem.MemoryBlock;
import ghidra.program.model.symbol.Reference;

public class Day5DecodeMessages extends GhidraScript {

    // TODO 1: Replace the zeros with the record layout you worked out by hand:
    //         the size of one record, the number of records, and the offset of each field.
    private static final int RECORD_SIZE = 0;
    private static final int COUNT = 0;
    private static final int KEY = 0;
    private static final int LEN = 0;
    private static final int SEALED = 0;
    private static final int TEXT = 0;

    @Override
    protected void run() throws Exception {
        // TODO 2: Find the "Message %d is sealed" string and follow its reference to main, as in
        //         Exercise 5.3. Look up findBytes(Address, String), getReferencesTo(Address) and
        //         getFunctionContaining(Address). Print main's address.

        // TODO 3: Walk main's instructions and find the LEA whose reference points into the .data block.
        //         That address is the table. Look up Instruction.getMnemonicString(),
        //         Instruction.getReferencesFrom(), getMemoryBlock(Address) and MemoryBlock.getName().

        // TODO 4: Loop over the records. For record i, the start is table + i * RECORD_SIZE.
        //         Read the key, the length and the sealed flag, then read the text and XOR each byte.
        //         Look up Address.add(long), getByte(Address) and getBytes(Address, int).

        // TODO 5: Print one line per record: its number (from 1), its key, open or sealed, and the text.
        //         Look up String.format if you want the columns to line up.
    }
}
