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
        while (it.hasNext()) {
            Instruction ins = it.next();
            StringBuilder sb = new StringBuilder("D " + ins.getAddress() + " " + ins + " flow=" + ins.getFlowType());
            for (Address f : ins.getFlows()) {
                Function c = getFunctionAt(f);
                sb.append(" ->" + f + (c == null ? "" : "(" + c.getName() + ")"));
            }
            for (Reference r : ins.getReferencesFrom()) {
                Data d = getDataAt(r.getToAddress());
                sb.append(" ref:" + r.getReferenceType() + "@" + r.getToAddress()
                        + (d == null ? " nodata" : " data=" + d.getDataType().getName()));
            }
            println(sb.toString());
        }
    }
}
