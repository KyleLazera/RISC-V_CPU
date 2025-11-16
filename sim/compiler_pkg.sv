package compiler_pkg;

//-------------------------------------------------------
// This package contains functions that are used to mimic
// a compiler and convert RISC-V assembly instructions into
// their binary representation.
//-------------------------------------------------------

// Sample Instruction Memory
logic [31:0] instruction_memory [31:0];

/* Enum that contains op-codes for RISC-V instruction types */
typedef enum logic [6:0] {
    OP_R_TYPE   = 7'b0110011,
    OP_I_TYPE   = 7'b0010011,
    OP_LOAD     = 7'b0000011,
    OP_STORE    = 7'b0100011,
    OP_BRANCH   = 7'b1100011,
    OP_JAL      = 7'b1101111,
    OP_JALR     = 7'b1100111,
    OP_LUI      = 7'b0110111
} op_code_e;

// Add the contents of src_1 and src_2 registers and store the result in dst_reg
function logic [31:0] add(int dst_reg, int src1, int src2);
    logic [6:0] op_code, funct7;
    logic [2:0] funct3;
    logic [4:0] rs1, rs2, rd;

    op_code = OP_R_TYPE;
    funct3 = 3'b000;
    funct7 = 7'b0000000;
    rs1 = src1;
    rs2 = src2;
    rd = dst_reg;

    return {funct7, rs2, rs1, funct3, rd, op_code};
endfunction : add

// Subtract the contents of register 2 from the contents of reg 1 and store result
// in the dst_reg
function logic [31:0] sub(int dst_reg, int src1, int src2);
    logic [6:0] op_code, funct7;
    logic [2:0] funct3;
    logic [4:0] rs1, rs2, rd;

    op_code = OP_R_TYPE;
    funct3 = 3'b000;
    funct7 = 7'b0100000;
    rs1 = src1;
    rs2 = src2;
    rd = dst_reg;

    return {funct7, rs2, rs1, funct3, rd, op_code};
endfunction : sub

// Bitwise AND of contents of src1 and src2 registers, store in dst_reg
function logic [31:0] and_op(int dst_reg, int src1, int src2);
    logic [6:0] op_code, funct7;
    logic [2:0] funct3;
    logic [4:0] rs1, rs2, rd;

    op_code = OP_R_TYPE;
    funct3 = 3'b111;
    funct7 = 7'b0000000;
    rs1 = src1;
    rs2 = src2;
    rd = dst_reg;

    return {funct7, rs2, rs1, funct3, rd, op_code};
endfunction : and_op

// Bitwise OR of contents of src1 and src2 registers, store in dst_reg
function logic [31:0] or_op(int dst_reg, int src1, int src2);
    logic [6:0] op_code, funct7;
    logic [2:0] funct3;
    logic [4:0] rs1, rs2, rd;

    op_code = OP_R_TYPE;
    funct3 = 3'b110;
    funct7 = 7'b0000000;
    rs1 = src1;
    rs2 = src2;
    rd = dst_reg;

    return {funct7, rs2, rs1, funct3, rd, op_code};
endfunction : or_op

// Bitwise XOR of contents of src1 and src2 registers, store in dst_reg
function logic [31:0] xor_op(int dst_reg, int src1, int src2);
    logic [6:0] op_code, funct7;
    logic [2:0] funct3;
    logic [4:0] rs1, rs2, rd;

    op_code = OP_R_TYPE;
    funct3 = 3'b100;
    funct7 = 7'b0000000;
    rs1 = src1;
    rs2 = src2;
    rd = dst_reg;

    return {funct7, rs2, rs1, funct3, rd, op_code};
endfunction : xor_op

endpackage : compiler_pkg