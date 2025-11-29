`include "compiler_pkg.sv"
`include "golden_model.sv"

module cpu_top_tb;

import compiler_pkg::*;

localparam DATA_WIDTH = 32;
localparam MEM_DEPTH = 256;
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

/* This contains a simple test sequence that mimics the following simple C program:

int compute_sum(int n) {
    int i = 0;
    int sum = 0;
    while (i < n) {
        sum += i;
        i++;
    }
    return sum;
}

int main() {
    int n = 5;
    int result = compute_sum(n);
    memory[200] = result;
}

This utilizes majority of teh base instruction set including R-type, I-type, S-type instructions*/

initial begin

    // Init variable n = 5
    cpu_top_inst.data_path_inst.instruction_fetch.instr_mem[0] = addi(10, 0, 5);        // addi x10, x0, 5      

    // Save/store architectural state for function call
    cpu_top_inst.data_path_inst.instruction_fetch.instr_mem[4] = addi(4, 30, 30);       // addi x4, x30, 30     (Store value 60 in x4)
    cpu_top_inst.data_path_inst.instruction_fetch.instr_mem[8] = add(5, 4, 3);           // add x5, x4, x3      (Store output of 60 + 3 in x5)
    cpu_top_inst.data_path_inst.instruction_fetch.instr_mem[12] = sll(20, 5, 1);         // sll x20, x4, x1     (Store x5 << 1 (x5*2) in x20)
    cpu_top_inst.data_path_inst.instruction_fetch.instr_mem[16] = sw(10, 4, 0);          // sw x10, 0(x4)       (Store contents of x10 to memory[60])
    cpu_top_inst.data_path_inst.instruction_fetch.instr_mem[20] = sw(1, 4, 4);           // sw x1, 4(x4)        (Store contents of x1 to memory[64])
    cpu_top_inst.data_path_inst.instruction_fetch.instr_mem[24] = sw(2, 4, 8);           // sw x2, 8(x4)        (Store contents of x2 to mem[68])
    cpu_top_inst.data_path_inst.instruction_fetch.instr_mem[28] = jalr(6, 30, 50);       // Jump to function call & store current address in x6
    cpu_top_inst.data_path_inst.instruction_fetch.instr_mem[32] = 32'b0;                 // NOP 
    cpu_top_inst.data_path_inst.instruction_fetch.instr_mem[36] = 32'b0;                 // NOP     

    // Restore architectural state after function call
    cpu_top_inst.data_path_inst.instruction_fetch.instr_mem[40] = lw(1, 4, 0);           // lw x1, 0(x4)
    cpu_top_inst.data_path_inst.instruction_fetch.instr_mem[44] = lw(2, 4, 4);           // lw x2, 4(x4)
    
    // Save return value to Memory
    cpu_top_inst.data_path_inst.instruction_fetch.instr_mem[48] = sw(11, 4, 0);         // Store return value to mem[200] 

    // Function compute_sum
    cpu_top_inst.data_path_inst.instruction_fetch.instr_mem[80] = addi(1, 0, 0);        // addi x1, x0, 0  (Init i = 0)
    cpu_top_inst.data_path_inst.instruction_fetch.instr_mem[84] = addi(2, 0, 0);        // addi x2, x0, 0  (init sum = 0)
    cpu_top_inst.data_path_inst.instruction_fetch.instr_mem[88] = slt(3, 1, 10);        // slt x3, x1, x10  (x3 = (i < n))
    cpu_top_inst.data_path_inst.instruction_fetch.instr_mem[92] = 32'b0;                // NOP 
    cpu_top_inst.data_path_inst.instruction_fetch.instr_mem[96] = 32'b0;               // NOP     
    cpu_top_inst.data_path_inst.instruction_fetch.instr_mem[100] = beq(3, 0, 44);        // Jump out of while loop
    cpu_top_inst.data_path_inst.instruction_fetch.instr_mem[104] = 32'b0;                // NOP 
    cpu_top_inst.data_path_inst.instruction_fetch.instr_mem[108] = 32'b0;               // NOP 
    cpu_top_inst.data_path_inst.instruction_fetch.instr_mem[112] = add(2, 2, 1);        // add x2, x2, x1  (sum += i)
    cpu_top_inst.data_path_inst.instruction_fetch.instr_mem[116] = addi(1, 1, 1);       // addi x1, x1, 1  (i++)
    cpu_top_inst.data_path_inst.instruction_fetch.instr_mem[120] = addi(5, 30, 58);     // Store address of the while loop beginning
    cpu_top_inst.data_path_inst.instruction_fetch.instr_mem[124] = 32'b0;
    cpu_top_inst.data_path_inst.instruction_fetch.instr_mem[128] = 32'b0;
    cpu_top_inst.data_path_inst.instruction_fetch.instr_mem[132] = jalr(0, 5, 0);       // Jump back to loop
    cpu_top_inst.data_path_inst.instruction_fetch.instr_mem[136] = 32'b0;
    cpu_top_inst.data_path_inst.instruction_fetch.instr_mem[140] = 32'b0;

    // Return value and jump back to main
    cpu_top_inst.data_path_inst.instruction_fetch.instr_mem[144] = addi(11, 2, 0);      // Store return value in x11
    cpu_top_inst.data_path_inst.instruction_fetch.instr_mem[148] = jalr(0, 6, 8);       // Return back to main 
    cpu_top_inst.data_path_inst.instruction_fetch.instr_mem[152] = 32'b0;
    cpu_top_inst.data_path_inst.instruction_fetch.instr_mem[156] = 32'b0;


    // Load instructions into the Golden model
    cpu_model = new(cpu_top_inst.data_path_inst.instruction_fetch.instr_mem);
end

// Use negedge to ensure the RTL blocking signals have been driven
always @(posedge clk) begin 
    if(instr_complete) begin
        cpu_model.step();
        cpu_model.validate_reg_file(cpu_top_inst.data_path_inst.instruction_decode.regfile.reg_file);
        cpu_model.validate_memory(cpu_top_inst.data_path_inst.mem.mem);
    end
end

/* Reset Generation */
initial begin
    reset_n = 1'b0;
    repeat(3)
        @(posedge clk);
    reset_n <= 1'b1; 
    @(posedge clk);

    // Run the simulation for a fixed amount of time
    repeat(500)
        @(posedge clk);


    $display("Execution Complete!");
    $finish;
end


endmodule : cpu_top_tb