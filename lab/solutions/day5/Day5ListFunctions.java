// SPOILER: complete solution for Day 5, Exercise 5.1.
// Lists every function in the program with its entry address and its size in bytes,
// then the number of functions and how many of them are thunks (import stubs).
//@category Course.Day5

import ghidra.app.script.GhidraScript;
import ghidra.program.model.listing.Function;

public class Day5ListFunctions extends GhidraScript {

    @Override
    protected void run() throws Exception {
        int count = 0;                        // every function seen so far
        int thunks = 0;                       // the ones that only jump to an import

        // TODO 1: start at the first function and move to the next one until there are none left.
        Function f = getFirstFunction();      // lowest address first; null if there are no functions
        while (f != null && !monitor.isCancelled()) {   // stop when the list ends or Cancel is pressed

            // TODO 2: print the function's name and entry address.
            String name = f.getName();        // FUN_... for a stripped function, or the import's name for a thunk
            String entry = f.getEntryPoint().toString();   // the address the function starts at

            // TODO 3: add its size in bytes, and mark thunks.
            long size = f.getBody().getNumAddresses();     // the body is the set of addresses the function covers
            String mark = f.isThunk() ? "  thunk" : "";    // a thunk is a stub that jumps to another function
            println(String.format("%-28s %s %6d bytes%s", name, entry, size, mark));   // one line per function

            count++;                          // count every function
            if (f.isThunk()) {
                thunks++;                     // and the thunks separately
            }
            f = getFunctionAfter(f);          // the next function by address, or null after the last one
        }

        // TODO 4: print the totals.
        println("Functions: " + count + ", thunks: " + thunks);   // compare with the Symbol Tree's Functions folder
    }
}
