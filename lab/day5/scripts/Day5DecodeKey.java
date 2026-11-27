// Day 5, Exercise 5.3: decode Day 1 ex3's license key from the program's bytes, the way you did
// by hand: find main from a string, find decode, read its array and key, and XOR the bytes.
// Skeleton: it compiles and runs as it is, and prints nothing until you fill in the TODOs.
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
        // TODO 1: Find the "Bad license key" string in memory and print its address.
        //         Look up findBytes(Address, String) and currentProgram.getMinAddress().
        //         Print a message and return if it is null.

        // TODO 2: Follow the string's first reference to the function that uses it (main), and print
        //         main's name and address. Look up getReferencesTo(Address) and getFunctionContaining(Address).

        // TODO 3: Walk main's instructions in order. Find the call to strcmp; the call just before it is
        //         decode. Also keep the number moved into EDX just before the decode call: the length.
        //         Look up currentProgram.getListing().getInstructions(AddressSetView, boolean),
        //         Instruction.getFlows(), getFunctionAt(Address), Instruction.getMnemonicString(),
        //         Instruction.getRegister(int) and Instruction.getScalar(int).

        // TODO 4: Walk decode's instructions. The array is the target of a data reference; the key is the
        //         number in the XOR instruction. Look up Instruction.getReferencesFrom(),
        //         Reference.getReferenceType().isData(), Reference.getToAddress() and Scalar.getValue().

        // TODO 5: Read the bytes, XOR each one with the key, and print the key you get.
        //         Look up getBytes(Address, int). Java bytes are signed, so mask with & 0xff.
    }
}
