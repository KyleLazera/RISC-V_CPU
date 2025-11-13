
//TODO: Replace Instruction Memory with Instruction Cache

module I_Fetch #(
    parameter INSTR_WIDTH = 32,    
    parameter INSTR_MEM_DEPTH = 32,

    /* Non-Modifiable Parameters */
    parameter INSTR_MEM_ADDR_WIDTH = $clog2(INSTR_MEM_DEPTH),
    parameter INSTR_MEM_WIDTH = INSTR_WIDTH
)(
    input logic                             i_clk,
    input logic                             i_reset_n,

    // Control Signals
    input logic                             i_ctrl_PC_sel,

    // Input Signals
    input logic [INSTR_MEM_ADDR_WIDTH-1:0]  i_PC_target,

    // Pipelined Output Signals
    output logic [INSTR_MEM_WIDTH-1:0]      o_IF_instr,
    output logic [INSTR_MEM_ADDR_WIDTH-1:0] o_IF_program_cntr,
    output logic [INSTR_MEM_ADDR_WIDTH-1:0] o_IF_program_cntr_next    
);

/* ---------------- Instruction Memory ---------------- */

logic [INSTR_WIDTH-1:0]  instr_mem [INSTR_MEM_DEPTH];

// Sample Program - Used to test instruction support
initial begin
    /* R-Type Tests */
    instr_mem[0] = 32'b0000000_00000_00001_000_00010_0110011; // add reg[0] + reg[1] -> reg[2]

end

/* ---------------- Instruction Fetch  ---------------- */

logic [INSTR_MEM_ADDR_WIDTH-1:0]    program_cntr = {INSTR_MEM_ADDR_WIDTH{1'b0}};
logic [INSTR_MEM_ADDR_WIDTH-1:0]    IF_program_cntr = {INSTR_MEM_ADDR_WIDTH{1'b0}};
logic [INSTR_MEM_ADDR_WIDTH-1:0]    IF_program_cntr_next = {INSTR_MEM_ADDR_WIDTH{1'b0}};
logic [INSTR_WIDTH-1:0]             IF_instr = {INSTR_WIDTH{1'b0}};
logic [INSTR_MEM_ADDR_WIDTH-1:0]    program_cntr_next;

assign program_cntr_next = program_cntr + 4;

always @(posedge i_clk) begin
    if (!i_reset_n) begin
        program_cntr <= {INSTR_MEM_ADDR_WIDTH{1'b0}};
        IF_program_cntr <= {INSTR_MEM_ADDR_WIDTH{1'b0}};
        IF_program_cntr_next <= {INSTR_MEM_ADDR_WIDTH{1'b0}};
        IF_instr <= {INSTR_MEM_ADDR_WIDTH{1'b0}};
    end else begin
        program_cntr <= (i_ctrl_PC_sel) ? i_PC_target : program_cntr_next;
        IF_program_cntr <= program_cntr;
        IF_instr <= instr_mem[program_cntr];
        IF_program_cntr_next <= program_cntr_next;
    end
end

/* ---------------- Output Logic  ---------------- */

assign o_IF_instr = IF_instr;
assign o_IF_program_cntr = IF_program_cntr;
assign o_IF_program_cntr_next = IF_program_cntr_next;


endmodule