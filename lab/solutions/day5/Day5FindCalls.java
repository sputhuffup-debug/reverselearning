// SPOILER: complete solution for Day 5, Exercise 5.2.
// Finds every call to strcmp (or to the function named in the first script argument) and prints
// the calling function and any string the call is given as a direct reference.
//@category Course.Day5

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Data;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.Instruction;
import ghidra.program.model.symbol.Reference;

public class Day5FindCalls extends GhidraScript {

    // How far back from a call to look for the instructions that set up its arguments.
    private static final int LOOK_BACK = 6;

    @Override
    protected void run() throws Exception {
        // TODO 1: take the function name from the script arguments, or use strcmp.
        String target = "strcmp";                      // the default
        String[] args = getScriptArgs();               // empty when run from the Script Manager
        if (args.length > 0) {
            target = args[0];                          // headless: -postScript Day5FindCalls.java puts
        }

        // TODO 2: walk the functions and keep the ones with that name.
        List<Function> targets = new ArrayList<>();
        for (Function f = getFirstFunction(); f != null; f = getFunctionAfter(f)) {
            if (f.getName().equals(target)) {          // the import stub (thunk) carries the import's name
                targets.add(f);
            }
        }
        if (targets.isEmpty()) {
            println("No function named " + target);
            return;
        }

        int calls = 0;
        for (Function t : targets) {
            // TODO 3: get every reference to the function's entry point and keep the calls.
            for (Reference ref : getReferencesTo(t.getEntryPoint())) {
                Address from = ref.getFromAddress();               // where the reference comes from
                Instruction call = getInstructionAt(from);          // the instruction at that address
                if (call == null || !call.getFlowType().isCall()) {
                    continue;                                       // skip jumps and data references
                }
                calls++;

                // TODO 4: print the address of the call and the function that contains it.
                Function caller = getFunctionContaining(from);      // null if the code is not in a function
                String callerName = caller == null ? "(no function)" : caller.getName();
                println("Call to " + target + " at " + from + " in " + callerName);

                // TODO 5: look at the instructions just before the call for references to strings.
                Set<Address> seen = new HashSet<>();                 // print each string once
                Instruction prev = getInstructionBefore(call);
                for (int i = 0; i < LOOK_BACK && prev != null; i++) {
                    if (prev.getFlowType().isCall()) {
                        break;                                      // that belongs to the previous call
                    }
                    for (Reference r : getReferencesFrom(prev.getAddress())) {
                        Address to = r.getToAddress();
                        if (!seen.add(to)) {
                            continue;                               // already printed this one
                        }
                        String str = stringAt(to);
                        if (str != null) {
                            println("  string argument: \"" + str + "\"");
                        }
                    }
                    prev = getInstructionBefore(prev);              // one instruction further back
                }
            }
        }
        println("Calls to " + target + ": " + calls);
    }

    // The string at an address: Ghidra's defined string if there is one, otherwise the bytes up to
    // the terminating zero, if they are all printable (Ghidra doesn't define every string).
    private String stringAt(Address a) throws Exception {
        Data d = getDataAt(a);
        if (d != null && d.getValue() instanceof String) {
            return (String) d.getValue();
        }
        if (!currentProgram.getMemory().contains(a)) {
            return null;                                    // e.g. a register or stack reference
        }
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < 256; i++) {
            int b = getByte(a.add(i)) & 0xff;
            if (b == 0) {
                return sb.length() >= 4 ? sb.toString() : null;
            }
            if (b < 0x20 || b > 0x7e) {
                return null;                                // not text
            }
            sb.append((char) b);
        }
        return null;
    }
}
