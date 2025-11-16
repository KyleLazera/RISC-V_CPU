

module control_unit #(
    parameter DATA_WIDTH = 32,

    /* Decoding Parameters */
    parameter OP_CODE_WIDTH = 7,
    parameter FUNCT3_WIDTH = 3,
    parameter FUNCT7_WIDTH = 7
) (
    input logic                     i_clk,
    input logic                     i_reset_n,

    // Input Signals
    input logic [OP_CODE_WIDTH-1:0] i_op_code,
    input logic [FUNCT3_WIDTH-1:0]  i_funct3,
    input logic [FUNCT7_WIDTH-1:0]  i_funct7,
    input logic                     i_alu_zero_flag,        // Zero flag set by ALU

    // Output Signals
    output logic [1:0]              o_imm_sel,              // Indicates where within the instruction the immediate bits are located
    output logic                    o_alu_src_sel,          // Selects between register file output or immediate value for ALU operand 2
    output logic [3:0]              o_alu_op,               // ALU operation select signal
    output logic                    o_reg_file_wr_en,       // Enables writing back to the register file
    output logic [1:0]              o_wb_result_sel         // Selects the source of the data to write back to the register file
);

/* ---------------- Local Parameters  ---------------- */

/* Instruction Type Opcodes */
localparam [OP_CODE_WIDTH-1:0]  MEM_LOAD = 7'b0000011;
localparam [OP_CODE_WIDTH-1:0]  MEM_STORE = 7'b0100011;
localparam [OP_CODE_WIDTH-1:0]  R_TYPE = 7'b0110011;
localparam [OP_CODE_WIDTH-1:0]  INT_IMMEDIATE = 7'b0010011;
localparam [OP_CODE_WIDTH-1:0]  BRANCH = 7'b1100011;
localparam [OP_CODE_WIDTH-1:0]  JAL = 7'b1101111;
localparam [OP_CODE_WIDTH-1:0]  JALR = 7'b1100111;

/* Instruction funct3 values */
//TODO: Need to complete list of instructions
localparam [FUNCT3_WIDTH-1:0] LW = 3'b010;
localparam [FUNCT3_WIDTH-1:0] SW = 3'b010;
localparam [FUNCT3_WIDTH-1:0] OR = 3'b110;
localparam [FUNCT3_WIDTH-1:0] BEQ = 3'b000;

/* ---------------- Immediate Field Decoding Logic  ---------------- */

logic [1:0] imm_sel;

// -------------------------------------------------
// Each instruction has slightly different locations 
// for the immediate value bits. This logic block
// decodes the instruction type and sets the select 
// signal accordingly.
// -------------------------------------------------
always_comb begin
    /* J-Type Instructions - [{imm[20], imm[10:1], imm[11], imm[19:12], reg_dst, op_code}] */
    if (i_op_code == JAL)
        imm_sel = 2'b11;
    /* S-Type Instruction - [{imm[11:5], rs2, rs1, funct3, imm[4:0], op_code}] */
    else if (i_op_code == MEM_STORE)
        imm_sel = 2'b01;
    /* B-Type Instructions - [{imm[12], imm[10:5], rs2, rs1, funct3, imm[4:1], imm[11], op_code}] */
    else if (i_op_code == BRANCH)
        imm_sel = 2'b10;
    /* I-Type Instructions - [{imm[11:0], rs1, funct3, rd, op_code}] */
    else
        imm_sel = 2'b00;
end

/* ---------------- ALU Decoding Logic  ---------------- */

logic                       src_sel;
logic [3:0]                 alu_op;

//-------------------------------------------------------
// The ALU has 2 main decoding signals:
// 1. ALU Operation Select - Determines the specific
//    operation to be performed (ADD, SUB, AND, OR, etc)
// 2. ALU Source Select - Determines the source of the
//    second operand (register output vs immediate value)
//--------------------------------------------------------

// I-Type & S-Type instructions use immediate values
assign src_sel = (i_op_code == MEM_STORE | i_op_code == MEM_LOAD | i_op_code == INT_IMMEDIATE | i_op_code == JALR);

always_comb begin
    case(i_funct3)
        4'b0000: begin
            if (i_funct7[5] & i_op_code[5])
                alu_op = 4'b0001;   // Subtract
            else
                alu_op = 4'b0000;   // Add
        end
        4'b0001: alu_op = 4'b0010;   // Register shift-left
        4'b0010: alu_op = 4'b0011;   // Set less than
        4'b0011: alu_op = 4'b0100;   // Set less than (unsigned)
        4'b0100: alu_op = 4'b0101;   // XOR
        4'b0101: begin
            if (i_funct7[5])
                alu_op = 4'b0111;   // Shift Right Arithmetic
            else
                alu_op = 4'b0110;   // Shift Right Logical
        end
        4'b0110: alu_op = 4'b1000;   // OR
        4'b0111: alu_op = 4'b1001;   // AND  
        default : alu_op = 4'b0000;  // Default = add    
    endcase
end

/* ---------------- Write Back Control Logic  ---------------- */

logic       reg_file_wr_en;
logic [1:0] wb_result_sel;

//-------------------------------------------------------
// There are 2 things that need to be decoded for the write
// back stage. The first is determining the result source.
// This allows us to write back the ALU output, memory 
// data, or the incremented PC value (for JAL/JALR). The 
// second is enabling the write back to the register file
// to write to a desintation register.
//--------------------------------------------------------

assign reg_file_wr_en = (i_op_code == R_TYPE | i_op_code == INT_IMMEDIATE); //TODO: Complete this logic to include all instructions that write back to the register file
assign wb_result_sel = (i_op_code == MEM_LOAD) ? 2'b00 :                // Load from memory
                       (i_op_code == JAL | i_op_code == JALR) ? 2'b10 : // Next PC for JAL/JALR
                       2'b01;                                           // Default to ALU result


/* ---------------- Output Control Logic  ---------------- */

assign o_imm_sel = imm_sel;
assign o_alu_src_sel = src_sel;
assign o_alu_op = alu_op;   
assign o_reg_file_wr_en = reg_file_wr_en;
assign o_wb_result_sel = wb_result_sel; 

endmodule