module I_Execute #(
    parameter DATA_WIDTH = 32,
    parameter REG_FILE_DEPTH = 5,
    parameter INTSR_MEM_DEPTH = 5,

    /* Non-Modifiable params */
    parameter REG_FILE_ADDR = $clog2(REG_FILE_DEPTH),
    parameter INSTR_MEM_ADDR = $clog2(INTSR_MEM_DEPTH)
) (
    input logic                         i_clk,
    input logic                         i_reset_n,

    // Control Signals 
    input logic                         i_ctrl_alu_src_sel,     // Operand B of the ALU can either be:
                                                                //  1. Register value from reg file
                                                                //  2. Immediate value for jumps/stores/loads etc.
                                                                // i_ctrl_alu_src_sel acts as a select signal
    input logic [3:0]                   i_ctrl_alu_op_sel,      // Select which operation the ALU should perform
    output logic                        o_ctrl_zero_flag,

    // Input Signals 
    input logic [DATA_WIDTH-1:0]        i_ID_read_data_1,
    input logic [DATA_WIDTH-1:0]        i_ID_read_data_2,

    input logic [REG_FILE_ADDR-1:0]     i_ID_program_ctr,
    input logic [INSTR_MEM_ADDR-1:0]    i_ID_immediate,

    // Output Signals
    output logic [DATA_WIDTH-1:0]       o_IE_result,            // Output of ALU (Can be either an address or data)
    output logic [DATA_WIDTH-1:0]       o_IE_data_write,        // Data that would be used in the memory write stage
    output logic [REG_FILE_ADDR-1:0]    o_IE_PC_target          // PC target (for jump style instruction)
);

logic [DATA_WIDTH-1:0]      alu_output;
logic [DATA_WIDTH-1:0]      alu_operand_1;
logic [DATA_WIDTH-1:0]      alu_operand_2;

// ----------------------------------------------------
// The ALU will always take in 2, 32-bit operands.
// The first operand will always be the contents of source 
// register 1 (read data 1). The second operand can be 1 
// of the following:
//      1) Contents of Source register 2 (read output data 2)
//      2) Immediate value calculated in the Decode block
//
// The second operand is selected based on the input signal
// alu_imm_sel which comes from the control unit.
// ----------------------------------------------------

assign alu_operand_1 = i_ID_read_data_1;
assign alu_operand_2 = (i_ctrl_alu_src_sel) ? i_ID_immediate : i_ID_read_data_2;

/* --------------- ALU Instantiation --------------- */
alu #(
    .DATA_WIDTH(DATA_WIDTH),
    .SEL_WIDTH(4),
    .REG_OUTPUT(0)
) alu_execute (
    .i_clk(i_clk),
    .i_src_a(alu_operand_1),
    .i_src_b(alu_operand_2),
    .i_sel(i_ctrl_alu_op_sel),
    .o_data(alu_output)
);

/* --------------- Pipelined Logic --------------- */

logic [DATA_WIDTH-1:0]      IE_alu_result = {DATA_WIDTH{1'b0}};
logic [DATA_WIDTH-1:0]      IE_rd_data_2 = {DATA_WIDTH{1'b0}};

always_ff @(posedge i_clk) begin
    if (!i_reset_n) begin
        IE_alu_result <= {DATA_WIDTH{1'b0}};
        IE_rd_data_2 <= {DATA_WIDTH{1'b0}};
    end else begin
        IE_alu_result <= alu_output;
        IE_rd_data_2 <= i_ID_read_data_2;
    end
end

/* --------------- Output Logic --------------- */

assign o_IE_result = IE_alu_result;
assign o_IE_data_write = IE_rd_data_2;
assign o_IE_PC_target = i_ID_program_ctr + i_ID_immediate;

// TODO: Add Zero Flag logic

endmodule