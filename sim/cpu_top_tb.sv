`include "compiler_pkg.sv"
`include "golden_model.sv"

module cpu_top_tb;

import compiler_pkg::*;

localparam DATA_WIDTH = 32;
localparam MEM_DEPTH = 32;
localparam INSTR_MEM_DEPTH = 256;

logic clk;
logic reset_n;
logic instr_complete;

golden_model#(
    .DATA_WIDTH(DATA_WIDTH),
    .MEMORY_DEPTH(MEM_DEPTH),
    .INSTR_MEM_DEPTH(INSTR_MEM_DEPTH)
) cpu_model;

cpu_top #(
    .DATA_WIDTH(DATA_WIDTH),
    .MEM_DEPTH(MEM_DEPTH),
    .INSTR_MEM_DEPTH(INSTR_MEM_DEPTH),
    .SIMULATION(1)
) cpu_top_inst (
    .i_clk(clk),
    .i_reset_n(reset_n),
    .o_instr_commit(instr_complete)
);

/* Clock Generation */
initial begin
    clk = 1'b0;
    forever #5 clk = ~clk; // 10MHz Clock
end

// Load Instructions into the DUT instruction memory
initial begin
    /* Instruction Tests */
    cpu_top_inst.data_path_inst.instruction_fetch.instr_mem[0] = addi(1, 1, 1);         //addi x1, x1, 1 -> *Reg[1] = *reg[1] + 1 -> Should be 1
    cpu_top_inst.data_path_inst.instruction_fetch.instr_mem[4] = 32'b0; 
    cpu_top_inst.data_path_inst.instruction_fetch.instr_mem[8] = 32'b0; 
    cpu_top_inst.data_path_inst.instruction_fetch.instr_mem[12] = beq(1, 2, 60);         //beq x1, x2, 0x15 -> If (*reg[1] == *reg[2]) branch to PC + 0x15 (branch to 0x64)

    // Add 2 No-op instructions to allow for branch to be taken
    cpu_top_inst.data_path_inst.instruction_fetch.instr_mem[16] = 32'b0;                 
    cpu_top_inst.data_path_inst.instruction_fetch.instr_mem[20] = 32'b0;          

    // Branched instructions
    cpu_top_inst.data_path_inst.instruction_fetch.instr_mem[72] = sw(20, 30, -10);       // SW x20, -10(reg[30]) -> Store 20 in address (30-10 = 20)
    cpu_top_inst.data_path_inst.instruction_fetch.instr_mem[76] = sw(10, 20, -4);        // SW x10, -4(reg[20])  -> Store 10 in address (20-4 = 16)
    cpu_top_inst.data_path_inst.instruction_fetch.instr_mem[80] = sw(8, 12, 0);          // SW x8, 0(reg[12])    -> Store 8 in address (12 + 0 = 12)

    // Load instructions into the Golden model
    cpu_model = new(cpu_top_inst.data_path_inst.instruction_fetch.instr_mem);
end

always_ff @(posedge clk) begin
    if(instr_complete) begin
        cpu_model.step();
        cpu_model.validate_reg_file(cpu_top_inst.data_path_inst.instruction_decode.regfile.reg_file);
    end
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