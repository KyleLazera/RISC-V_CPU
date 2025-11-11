module control_unit #(
    parameter DATA_WIDTH = 32
) (
    input logic                     i_clk,
    input logic                     i_reset_n,

    // Input Signals
    input logic [DATA_WIDTH-1:0]    i_instruction,          // Input Instruction to be Decoded
    input logic                     i_alu_zero_flag,        // Zero flag set by ALU

    // Output Signals
    output logic                    o_reg_write_back,       // Used as a write enable signal for the reg file
    output logic                    o_alu_src_sel,          // Selects the second operand of the ALU
    output logic                    o_mem_write,            // Write enable signal for the data memory
);

/* ---------------- Local Parameters  ---------------- */

localparam OP_CODE_WIDTH = 7;
localparam FUNCT3_WIDTH = 3;
localparam FUNCT7_WIDTH = 7;

/* Instruction Type Opcodes */
localparam [OP_CODE_WIDTH-1:0]  MEM_LOAD = 7'b0000011;
localparam [OP_CODE_WIDTH-1:0]  MEM_STORE = 7'b0100011;
localparam [OP_CODE_WIDTH-1:0]  R_TYPE = 7'b0110011;
localparam [OP_CODE_WIDTH-1:0]  INT_IMMEDIATE = 7'b0010011;
localparam [OP_CODE_WIDTH-1:0]  BRANCH = 7'b1100011;
localparam [OP_CODE_WIDTH-1:0]  JAL = 7'b1101111;

/* Instruction funct3 values */
//TODO: Need to complete list of instructions
localparam [FUNCT3_WIDTH-1:0] LW = 3'b010;
localparam [FUNCT3_WIDTH-1:0] SW = 3'b010;
localparam [FUNCT3_WIDTH-1:0] OR = 3'b110;
localparam [FUNCT3_WIDTH-1:0] BEQ = 3'b000;


/* ---------------- Instruction Decoding Logic  ---------------- */

logic [OP_CODE_WIDTH-1:0]   op_code;
logic [FUNCT3_WIDTH-1:0]    funct_3;
logic [FUNCT7_WIDTH-1:0]    funct_7;

assign op_code = i_instruction[6:0];
assign funct_3 = i_instruction[14:12];
assign funct7 = i_instruction[31:25];

/* ---------------- Output Control Logic  ---------------- */

assign o_reg_write_back = (op_code == MEM_LOAD) | (op_code == R_TYPE);
assign o_alu_src_sel = (op_code == MEM_LOAD) | (op_code == MEM_STORE);
assign o_mem_write = (op_code == MEM_STORE);

endmodule