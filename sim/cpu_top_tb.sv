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
    /* R-Type Tests */
    cpu_top_inst.data_path_inst.instruction_fetch.instr_mem[0] = add(2, 0, 1);          // add reg[0] + reg[1] -> reg[2] = 0 + 1 = 1
    cpu_top_inst.data_path_inst.instruction_fetch.instr_mem[4] = add(4, 1, 3);          // add reg[3] + reg[1] -> reg[4] = 1 + 3 = 4 
    cpu_top_inst.data_path_inst.instruction_fetch.instr_mem[8] = sub(5, 5, 1);          // sub reg[5] - reg[1] -> reg[5] = 5 - 1 = 4 
    cpu_top_inst.data_path_inst.instruction_fetch.instr_mem[12] = or_op(6, 7, 8);       // or reg[7] | reg[8] -> reg[6] = 7 | 8 = 15 (32'b1111)
    cpu_top_inst.data_path_inst.instruction_fetch.instr_mem[16] = and_op(4, 4, 2);      // and reg[4] & reg[2] -> reg[4] = 2 & 4 = 0 
    cpu_top_inst.data_path_inst.instruction_fetch.instr_mem[20] = xor_op(5, 3, 2);      // xor reg[3] ^ reg[2] -> reg[5] = 3 ^ 1 = 2
    cpu_top_inst.data_path_inst.instruction_fetch.instr_mem[24] = sll(2, 6, 2);         // sll reg[6] << reg[2] -> reg[2] = 15 << 1 = 30 (multiply by 2)
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