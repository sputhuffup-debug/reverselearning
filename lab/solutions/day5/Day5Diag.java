// TEMPORARY CI diagnostic (to be removed): dump the function that uses "Bad license key".
//@category Course.Day5
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Data;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.Instruction;
import ghidra.program.model.listing.InstructionIterator;
import ghidra.program.model.symbol.Reference;

public class Day5Diag extends GhidraScript {
    @Override
    protected void run() throws Exception {
        Address text = findBytes(currentProgram.getMinAddress(), "Bad license key");
        Function main = getFunctionContaining(getReferencesTo(text)[0].getFromAddress());
        InstructionIterator it = currentProgram.getListing().getInstructions(main.getBody(), true);
        boolean on = false;
        while (it.hasNext()) {
            Instruction ins = it.next();
            if (!on) {
                for (Address f : ins.getFlows()) {
                    Function c = getFunctionAt(f);
                    if (c != null && c.getName().equals("strcspn")) { on = true; }
                }
                continue;
            }
            StringBuilder sb = new StringBuilder("D " + ins.getAddress().toString().substring(7) + " " + ins);
            for (Address f : ins.getFlows()) {
                Function c = getFunctionAt(f);
                sb.append(" ->" + (c == null ? f.toString() : c.getName()));
            }
            for (Reference r : ins.getReferencesFrom()) {
                Data d = getDataAt(r.getToAddress());
                sb.append(" r:" + r.getReferenceType().toString().substring(0, 3));
            }
            println(sb.toString());
        }
    }
}
