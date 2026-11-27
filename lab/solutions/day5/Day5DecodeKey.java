// SPOILER: complete solution for Day 5, Exercise 5.3.
// Decodes Day 1 ex3's license key from the program's bytes: finds main from the
// "Bad license key." string, finds decode as the call just before strcmp, reads the
// array, the XOR key and the length from the code, and prints the decoded key.
//@category Course.Day5

import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.Instruction;
import ghidra.program.model.listing.InstructionIterator;
import ghidra.program.model.scalar.Scalar;
import ghidra.program.model.symbol.Reference;

public class Day5DecodeKey extends GhidraScript {

    @Override
    protected void run() throws Exception {
        // TODO 1: find the "Bad license key" string in memory.
        Address text = findBytes(currentProgram.getMinAddress(), "Bad license key");
        if (text == null) {
            println("String not found. Is this Day 1's ex3?");
            return;
        }
        println("String at " + text);

        // TODO 2: follow its reference to the function that uses it: main.
        Reference[] refs = getReferencesTo(text);           // the code that loads the string's address
        if (refs.length == 0) {
            println("Nothing references the string.");
            return;
        }
        Function main = getFunctionContaining(refs[0].getFromAddress());
        println("main is " + main.getName() + " at " + main.getEntryPoint());

        // TODO 3: walk main's instructions. Remember the last call and the last "MOV EDX, <number>"
        // before it; when the call to strcmp comes, the call before it is decode.
        Instruction lastCall = null;          // the most recent call that wasn't strcmp
        long lastEdx = -1;                    // the last number moved into EDX: decode's second argument
        long length = -1;                     // the length that was in EDX when decode was called
        Address decodeAddr = null;
        InstructionIterator it = currentProgram.getListing().getInstructions(main.getBody(), true);
        while (it.hasNext() && decodeAddr == null) {
            Instruction ins = it.next();
            if (ins.getMnemonicString().equals("MOV") && ins.getNumOperands() == 2 && ins.getRegister(0) != null
                    && ins.getRegister(0).getName().equals("EDX") && ins.getScalar(1) != null) {
                lastEdx = ins.getScalar(1).getValue();       // e.g. MOV EDX,0xe
            }
            if (!ins.getFlowType().isCall()) {
                continue;
            }
            Address[] flows = ins.getFlows();                // where the call goes
            Function callee = flows.length > 0 ? getFunctionAt(flows[0]) : null;
            if (callee != null && callee.getName().equals("strcmp") && lastCall != null) {
                decodeAddr = lastCall.getFlows()[0];         // the call just before strcmp
            } else {
                lastCall = ins;
                length = lastEdx;                            // EDX as it was at this call
                lastEdx = -1;
            }
        }
        if (decodeAddr == null || length <= 0) {
            println("Could not find the call to decode before strcmp (decode "
                    + decodeAddr + ", length " + length + ").");
            return;
        }
        Function decode = getFunctionAt(decodeAddr);
        println("decode is " + decode.getName() + " at " + decodeAddr + ", length " + length);

        // TODO 4: in decode, find the array (a data reference) and the key (the number in the XOR).
        Address array = null;
        long key = -1;
        InstructionIterator dit = currentProgram.getListing().getInstructions(decode.getBody(), true);
        while (dit.hasNext()) {
            Instruction ins = dit.next();
            for (Reference r : ins.getReferencesFrom()) {
                if (r.getReferenceType().isData()) {
                    array = r.getToAddress();                // LEA RDX,[secret]
                }
            }
            if (ins.getMnemonicString().equals("XOR") && ins.getNumOperands() == 2) {
                Scalar s = ins.getScalar(1);                 // XOR EAX,0x42
                if (s != null) {
                    key = s.getValue();
                }
            }
        }
        if (array == null || key < 0) {
            println("Could not find the array or the key in decode.");
            return;
        }
        println("Array at " + array + ", XOR key 0x" + Long.toHexString(key));

        // TODO 5: read the bytes, XOR each one with the key, and print the result.
        byte[] bytes = getBytes(array, (int) length);
        StringBuilder sb = new StringBuilder();
        for (byte b : bytes) {
            sb.append((char) ((b ^ key) & 0xff));            // & 0xff: Java bytes are signed
        }
        println("Key: " + sb);
    }
}
