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
    cpu_top_inst.data_path_inst.instruction_fetch.instr_mem[0] = sub(5, 3, 10);         // reg[3] - reg[10] -> reg[5] (3 - 10 = -7)
    cpu_top_inst.data_path_inst.instruction_fetch.instr_mem[4] = addi(1, 0, 15);        // reg[0] + 15 -> reg[1] (0 + 15 = 15)
    cpu_top_inst.data_path_inst.instruction_fetch.instr_mem[8] = addi(2, 30, -5);       // reg[30] - 5 -> reg[2]  (30 - 5 = 25)
    cpu_top_inst.data_path_inst.instruction_fetch.instr_mem[12] = slti(3, 5, -10);      // reg[5] < -10 -> reg[3]   (Should be False)
    cpu_top_inst.data_path_inst.instruction_fetch.instr_mem[16] = slti(4, 5, -4);       // reg[5] < -4 -> reg[4]   (Should be True)
    cpu_top_inst.data_path_inst.instruction_fetch.instr_mem[20] = sltiu(6, 8, 10);      // reg[8] < 10 -> reg[6] (Should be True)
    cpu_top_inst.data_path_inst.instruction_fetch.instr_mem[24] = xori(7, 15, 15);      // reg[15] ^ 15 -> reg[7] (15 ^ 15 = 0)
    cpu_top_inst.data_path_inst.instruction_fetch.instr_mem[28] = andi(8, 8, 9);        // reg[8] & 9 -> reg[8] (8 & 9 = 8)
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