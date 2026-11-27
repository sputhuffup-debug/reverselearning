// Day 5, Exercise 5.1: list every function with its entry address and size in bytes,
// then print how many functions and thunks the program has.
// Skeleton: it compiles and runs as it is, and prints nothing until you fill in the TODOs.
//@category Course.Day5

import ghidra.app.script.GhidraScript;
import ghidra.program.model.listing.Function;

public class Day5ListFunctions extends GhidraScript {

    @Override
    protected void run() throws Exception {
        // TODO 1: Start at the first function and loop until there are none left.
        //         Look up getFirstFunction() and getFunctionAfter(Function). Both return null at the end.
        //         Also stop if monitor.isCancelled() is true, so the Cancel button works.

        // TODO 2: Inside the loop, print the function's name and entry address on one line.
        //         Look up Function.getName(), Function.getEntryPoint() and println(String).

        // TODO 3: Add the function's size in bytes to that line, and mark thunks.
        //         Look up Function.getBody(), AddressSetView.getNumAddresses() and Function.isThunk().

        // TODO 4: After the loop, print the number of functions and the number of thunks.
        //         Count them in two int variables as you go.
    }
}
