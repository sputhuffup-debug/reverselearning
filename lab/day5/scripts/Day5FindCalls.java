// Day 5, Exercise 5.2: find every call to strcmp (or to the function named in the first
// script argument), and print the calling function and any string passed as a direct reference.
// Skeleton: it compiles and runs as it is, and prints nothing until you fill in the TODOs.
//@category Course.Day5

import java.util.ArrayList;
import java.util.List;

import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Data;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.Instruction;
import ghidra.program.model.symbol.Reference;

public class Day5FindCalls extends GhidraScript {

    @Override
    protected void run() throws Exception {
        // TODO 1: Put "strcmp" in a String variable. If the script was given arguments, use the first
        //         one instead. Look up getScriptArgs(); it returns an empty array in the Script Manager.

        // TODO 2: Walk the functions as in Exercise 5.1 and keep the ones with that name in a List.
        //         The import stub (a thunk) carries the import's name. Print a message and return
        //         if the list is empty.

        // TODO 3: For each function you kept, loop over the references to its entry point.
        //         Look up getReferencesTo(Address), Reference.getFromAddress(), getInstructionAt(Address)
        //         and Instruction.getFlowType().isCall(). Skip references that don't come from a call.

        // TODO 4: For each call, print its address and the name of the function that contains it.
        //         Look up getFunctionContaining(Address). Count the calls and print the total at the end.

        // TODO 5: Walk back up to 6 instructions from the call, stopping at an earlier call.
        //         Look up getInstructionBefore(Instruction) and getReferencesFrom(Address).
        //         For each reference, look up getDataAt(Address); if Data.getValue() is a String, print it.
    }
}
