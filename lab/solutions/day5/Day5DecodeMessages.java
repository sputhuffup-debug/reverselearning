// SPOILER: complete solution for Day 5, Exercise 5.4.
// Decodes every message in Day 5's ex1: finds main from the "Message %d is sealed." string, finds the
// message table as the address main takes in .data with LEA, then XORs each record's text with its own key.
//@category Course.Day5

import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.Instruction;
import ghidra.program.model.listing.InstructionIterator;
import ghidra.program.model.mem.MemoryBlock;
import ghidra.program.model.symbol.Reference;

public class Day5DecodeMessages extends GhidraScript {

    // TODO 1: the record layout you worked out by hand.
    private static final int RECORD_SIZE = 0x30;   // 48 bytes per message
    private static final int COUNT = 20;           // the prompt says there are 20 messages
    private static final int KEY = 0;              // offset of the one-byte XOR key
    private static final int LEN = 1;              // offset of the text length
    private static final int SEALED = 2;           // offset of the sealed flag
    private static final int TEXT = 3;             // offset of the encoded text

    @Override
    protected void run() throws Exception {
        // TODO 2: find the "Message %d is sealed." string and follow its reference to main.
        Address text = findBytes(currentProgram.getMinAddress(), "Message %d is sealed");
        if (text == null) {
            println("String not found. Is this Day 5's ex1?");
            return;
        }
        Reference[] refs = getReferencesTo(text);
        if (refs.length == 0) {
            println("Nothing references the string at " + text);
            return;
        }
        Function main = getFunctionContaining(refs[0].getFromAddress());
        println("main is " + main.getName() + " at " + main.getEntryPoint());

        // TODO 3: find the LEA in main that takes an address in the .data block: that is the table.
        // (A MOV that loads a pointer from .data is something else, such as a pointer to an import.)
        Address table = null;
        InstructionIterator it = currentProgram.getListing().getInstructions(main.getBody(), true);
        while (it.hasNext() && table == null) {
            Instruction ins = it.next();                          // main's instructions, in address order
            if (!ins.getMnemonicString().equals("LEA")) {
                continue;                                         // only LEA takes an address
            }
            for (Reference r : ins.getReferencesFrom()) {
                MemoryBlock block = getMemoryBlock(r.getToAddress());   // the block the address is in
                if (block != null && block.getName().equals(".data")) {
                    table = r.getToAddress();                     // strings are in .rdata, the table in .data
                }
            }
        }
        if (table == null) {
            println("No LEA in main takes an address in .data.");
            return;
        }
        println("Table at " + table);

        // TODO 4: for each record, read the key, the length and the flag, then decode the text.
        for (int i = 0; i < COUNT; i++) {
            Address rec = table.add((long) i * RECORD_SIZE);      // start of record i
            int key = getByte(rec.add(KEY)) & 0xff;              // & 0xff: Java bytes are signed
            int len = getByte(rec.add(LEN)) & 0xff;
            boolean sealed = getByte(rec.add(SEALED)) != 0;
            byte[] enc = getBytes(rec.add(TEXT), len);
            StringBuilder sb = new StringBuilder();
            for (byte b : enc) {
                sb.append((char) ((b ^ key) & 0xff));
            }

            // TODO 5: print the message number, the key, whether it is sealed, and the text.
            println(String.format("%2d key 0x%02x %s %s", i + 1, key, sealed ? "sealed" : "open  ", sb));
        }
    }
}
