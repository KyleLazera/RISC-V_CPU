`include "compiler_pkg.sv"

module cpu_top_tb;

import compiler_pkg::*;

logic clk;
logic reset_n;

cpu_top #(
    .DATA_WIDTH(32)
) cpu_top_inst (
    .i_clk(clk),
    .i_reset_n(reset_n)
);

/* Clock Generation */
initial begin
    clk = 1'b0;
    forever #5 clk = ~clk; // 10MHz Clock
end

initial begin
    /* Instruction Tests */

    cpu_top_inst.data_path_inst.instruction_fetch.instr_mem[0] = sw(20, 30, -10);       // SW x20, -10(reg[30]) -> Store 20 in address (30-10 = 20)
    cpu_top_inst.data_path_inst.instruction_fetch.instr_mem[4] = sw(10, 20, -4);        // SW x10, -4(reg[20])  -> Store 10 in address (20-4 = 16)
    cpu_top_inst.data_path_inst.instruction_fetch.instr_mem[8] = sw(8, 12, 0);          // SW x8, 0(reg[12])    -> Store 8 in address (12 + 0 = 12)

end

/* Reset Generation */
initial begin
    reset_n = 1'b0;
    repeat(3)
        @(posedge clk);
    reset_n <= 1'b1; 
    @(posedge clk);

    // Simulation run time only used for initial testing to prevent infinite running
    #1000;
    $finish;
end

endmodule : cpu_top_tb