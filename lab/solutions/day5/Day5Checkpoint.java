// SPOILER: complete solution for the Day 5 checkpoint.
// Recovers checkpoint.exe's passphrase: finds main from the "Relay open." string, finds the check
// function as the last call before main uses that string, finds the station table as the lowest
// .data address the check function refers to, then decodes every live station and sorts them.
// Headless-safe: it asks nothing, so analyzeHeadless can run it.
//@category Course.Day5

import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.Instruction;
import ghidra.program.model.listing.InstructionIterator;
import ghidra.program.model.mem.MemoryBlock;
import ghidra.program.model.symbol.Reference;

public class Day5Checkpoint extends GhidraScript {

    // TODO 1: the record layout worked out by hand.
    private static final int RECORD_SIZE = 4;      // the index is multiplied by 4 (LEA RDX,[RAX*4])
    private static final int COUNT = 40;           // the loops run while j <= 0x27; the prompt says 40
    private static final int FLAGS = 0;            // offset of the flags byte
    private static final int SEQ = 1;              // offset of the position in the passphrase
    private static final int SIG = 2;              // offset of the encoded character
    private static final int KEY = 3;              // offset of the station's key
    private static final int DECOY = 0x10;         // AND EAX,0x10 then JNE: the check skips these

    @Override
    protected void run() throws Exception {
        // TODO 2: find the "Relay open." string and follow a reference to main.
        Address text = findBytes(currentProgram.getMinAddress(), "Relay open.");
        if (text == null) {
            println("String not found. Is this Day 5's checkpoint?");
            return;
        }
        Function main = null;
        for (Reference r : getReferencesTo(text)) {
            main = getFunctionContaining(r.getFromAddress());    // the code that loads the string
            if (main != null) {
                break;
            }
        }
        if (main == null) {
            println("No function uses the string at " + text);
            return;
        }
        println("main is " + main.getName() + " at " + main.getEntryPoint());

        // TODO 3: walk main in order, remembering the last call to a function that is not a thunk.
        // When an instruction refers to the string, that call was the check. (printf is MinGW's own
        // code, not a thunk, but it is called before the check, so a later call replaces it.)
        Function check = null;
        Function lastCalled = null;
        InstructionIterator it = currentProgram.getListing().getInstructions(main.getBody(), true);
        while (it.hasNext() && check == null) {
            Instruction ins = it.next();
            if (ins.getFlowType().isCall()) {
                Address[] flows = ins.getFlows();                // empty for CALL RAX
                Function callee = flows.length > 0 ? getFunctionAt(flows[0]) : null;
                if (callee != null && !callee.isThunk()) {
                    lastCalled = callee;                         // strlen, puts and fgets are thunks
                }
                continue;
            }
            for (Reference r : ins.getReferencesFrom()) {
                if (r.getToAddress().equals(text)) {             // the LEA that loads "Relay open."
                    check = lastCalled;
                }
            }
        }
        if (check == null) {
            println("Could not find the call before main uses the string.");
            return;
        }
        println("check is " + check.getName() + " at " + check.getEntryPoint());

        // TODO 4: the table is the lowest .data address the check refers to. At -O0 each field gets
        // its own LEA (table+0, +1, +2, +3), so take the minimum, not the first one seen.
        Address table = null;
        InstructionIterator cit = currentProgram.getListing().getInstructions(check.getBody(), true);
        while (cit.hasNext()) {
            Instruction ins = cit.next();
            for (Reference r : ins.getReferencesFrom()) {
                Address to = r.getToAddress();
                if (!to.isMemoryAddress()) {
                    continue;                                    // stack slots are references too
                }
                MemoryBlock block = getMemoryBlock(to);
                if (block == null || !block.getName().equals(".data")) {
                    continue;
                }
                if (table == null || to.compareTo(table) < 0) {
                    table = to;
                }
            }
        }
        if (table == null) {
            println("The check refers to nothing in .data.");
            return;
        }
        println("Table at " + table);

        // TODO 5: decode and print every record.
        // The check computes sig = (c ^ key) + 3 * seq in 8 bits, so c = (sig - 3 * seq) ^ key.
        char[] phrase = new char[COUNT];
        boolean[] filled = new boolean[COUNT];
        int live = 0;
        for (int i = 0; i < COUNT && !monitor.isCancelled(); i++) {
            Address rec = table.add((long) i * RECORD_SIZE);     // start of record i
            int flags = getByte(rec.add(FLAGS)) & 0xff;          // & 0xff: Java bytes are signed
            int seq = getByte(rec.add(SEQ)) & 0xff;
            int sig = getByte(rec.add(SIG)) & 0xff;
            int key = getByte(rec.add(KEY)) & 0xff;
            char c = (char) (((sig - 3 * seq) & 0xff) ^ key);
            boolean decoy = (flags & DECOY) != 0;
            println(String.format("%2d seq %2d key 0x%02x %s '%c'", i + 1, seq, key, decoy ? "decoy" : "live ", c));

            // TODO 6: skip the decoys, and put each live character at its position.
            if (decoy) {
                continue;
            }
            if (seq >= COUNT || filled[seq]) {
                println("Station " + (i + 1) + " has a bad or repeated position " + seq);
                return;
            }
            phrase[seq] = c;
            filled[seq] = true;
            live++;
        }
        for (int s = 0; s < live; s++) {
            if (!filled[s]) {
                println("No live station holds position " + s);
                return;
            }
        }
        println("Live stations: " + live);
        println("Passphrase: " + new String(phrase, 0, live));
    }
}
