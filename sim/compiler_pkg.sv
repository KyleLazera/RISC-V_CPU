package compiler_pkg;

//-------------------------------------------------------
// This package contains functions that are used to mimic
// a compiler and convert RISC-V assembly instructions into
// their binary representation.
//-------------------------------------------------------

/* Op codes for RISC-V Instructions */
localparam logic [6:0] OP_R_TYPE = 7'b0110011;
localparam logic [6:0] OP_I_TYPE = 7'b0010011;
localparam logic [6:0] OP_LOAD   = 7'b0000011;
localparam logic [6:0] OP_STORE  = 7'b0100011;
localparam logic [6:0] OP_BRANCH = 7'b1100011;
localparam logic [6:0] OP_JAL    = 7'b1101111;
localparam logic [6:0] OP_JALR   = 7'b1100111;
localparam logic [6:0] OP_LUI    = 7'b0110111;

/* Funct3 values */
localparam F3_ADD_SUB = 3'b000;
localparam F3_SLL     = 3'b001;
localparam F3_SLT     = 3'b010;
localparam F3_SLTU    = 3'b011;
localparam F3_XOR     = 3'b100;
localparam F3_SRL_SRA = 3'b101;
localparam F3_OR      = 3'b110;
localparam F3_AND     = 3'b111;

/* Funct7 values */
localparam F7_ADD = 7'b0000000;
localparam F7_SUB = 7'b0100000;
localparam F7_SRL = 7'b0000000;
localparam F7_SRA = 7'b0100000;


/* ------------------------- R-Type Instructions Functions --------------------------- */

function logic [31:0] encode_rtype(
    input logic [4:0] rd,
    input logic [4:0] rs1,
    input logic [4:0] rs2,
    input logic [2:0] funct3,
    input logic [6:0] funct7
);
    return {funct7, rs2, rs1, funct3, rd, OP_R_TYPE};
endfunction

// Add the contents of src_1 and src_2 registers and store the result in dst_reg
function logic [31:0] add(int rd, int rs1, int rs2);
    return encode_rtype(rd, rs1, rs2, F3_ADD_SUB, F7_ADD);
endfunction

// Subtract the contents of register 2 from the contents of reg 1 and store result
// in the dst_reg
function logic [31:0] sub(int rd, int rs1, int rs2);
    return encode_rtype(rd, rs1, rs2, F3_ADD_SUB, F7_SUB);
endfunction

// Bitwise AND of contents of src1 and src2 registers, store in dst_reg
function logic [31:0] and_op(int rd, int rs1, int rs2);
    return encode_rtype(rd, rs1, rs2, F3_AND, F7_ADD);
endfunction

// Bitwise OR of contents of src1 and src2 registers, store in dst_reg
function logic [31:0] or_op(int rd, int rs1, int rs2);
    return encode_rtype(rd, rs1, rs2, F3_OR, F7_ADD);
endfunction

// Bitwise XOR of contents of src1 and src2 registers, store in dst_reg
function logic [31:0] xor_op(int rd, int rs1, int rs2);
    return encode_rtype(rd, rs1, rs2, F3_XOR, F7_ADD);
endfunction

// Shift Left Logical - Shift contents of src1 left by amount in src2, store shifted value in dst_reg
function logic [31:32] sll(int rd, int rs1, int rs2);
    return encode_rtype(rd, rs1, rs2, F3_SLL, F7_ADD);
endfunction

// Set Less Than (signed)
function logic [31:0] slt(int rd, int rs1, int rs2);
    return encode_rtype(rd, rs1, rs2, F3_SLT, F7_ADD);
endfunction : slt

// Set Less Than Unsigned
function logic [31:0] sltu(int rd, int rs1, int rs2);
    return encode_rtype(rd, rs1, rs2, F3_SLTU, F7_ADD);
endfunction : sltu

// Shift Right Logical
function logic [31:0] srl(int rd, int rs1, int rs2);
    return encode_rtype(rd, rs1, rs2, F3_SRL_SRA, F7_SRL);
endfunction : srl

// Shift Right Arithmetic
function logic [31:0] sra(int rd, int rs1, int rs2);
    return encode_rtype(rd, rs1, rs2, F3_SRL_SRA, F7_SRA);
endfunction : sra

/* ------------------------- I-Type Instructions Functions --------------------------- */

/* Shift Immediate Encoding Helper Function */
function logic [31:0] encode_shift_imm (
    input logic [6:0] funct7,
    input logic [4:0] rd,
    input logic [4:0] rs1,
    input logic [4:0] imm,
    input logic [2:0] funct3
);
    return {funct7, imm, rs1, funct3, rd, OP_I_TYPE};
endfunction : encode_shift_imm

// Shift Left Logical Immediate (SRLI)
function logic [31:0] slli (int rd, int rs1, int imm);
    return encode_shift_imm(7'b0000000, rd, rs1, imm, 3'b000);
endfunction : slli

// Shift Right Logical Immediate (SRLI)
function logic [31:0] srli (int rd, int rs1, int imm);
    return encode_shift_imm(7'b0000000, rd, rs1, imm, 3'b101);
endfunction : srli

// Shift Right Arithmetic Immediate (SRAI)
function logic [31:0] srai (int rd, int rs1, int imm);
    return encode_shift_imm(7'b0100000, rd, rs1, imm, 3'b101);
endfunction : srai

/* Integer Immediate Encoding Helper Function */
function logic [31:0] encode_int_imm (
    input logic [4:0] rd,
    input logic [4:0] rs1,
    input logic [11:0] imm,
    input logic [2:0] funct3
);
    return {imm, rs1, funct3, rd, OP_I_TYPE};
endfunction : encode_int_imm

// ADDI: Add Immediate
function logic [31:0] addi (int rd, int rs1, int imm);
    return encode_int_imm(rd, rs1, imm, 3'b000);
endfunction : addi

// SLTI: Set Less Than Immediate (signed)
function logic [31:0] slti (int rd, int rs1, int imm);
    return encode_int_imm(rd, rs1, imm, 3'b010);
endfunction : slti

// SLTIU: Set Less Than Immediate (unsigned)
function logic [31:0] sltiu (int rd, int rs1, int imm);
    return encode_int_imm(rd, rs1, imm, 3'b011);
endfunction : sltiu

// XORI: XOR Immediate
function logic [31:0] xori (int rd, int rs1, int imm);
    return encode_int_imm(rd, rs1, imm, 3'b100);
endfunction : xori

// ORI: OR Immediate
function logic [31:0] ori (int rd, int rs1, int imm);
    return encode_int_imm(rd, rs1, imm, 3'b110);
endfunction : ori

// ANDI: AND Immediate
function logic [31:0] andi (int rd, int rs1, int imm);
    return encode_int_imm(rd, rs1, imm, 3'b111);
endfunction : andi

/* Integer Immediate Encoding Helper Function */
function logic [31:0] encode_load (
    input logic [4:0] rd,
    input logic [4:0] rs1,
    input logic [11:0] imm,
    input logic [2:0] funct3
);
    return {imm, rs1, funct3, rd, OP_LOAD};
endfunction : encode_load

function logic [31:0] lw (int rd, int rs1, int imm);
    return encode_load(rd, rs1, imm, 3'b010);
endfunction : lw

function logic [31:0] jalr (int rd, int rs1, int imm);
    logic [4:0] rd_reg;
    logic [4:0] rs1_reg;
    logic [11:0] imm_reg;

    rd_reg = rd;
    rs1_reg = rs1;
    imm_reg = imm;

    return {imm_reg, rs1_reg, 3'b000, rd_reg, OP_JALR};
endfunction : jalr

/* ------------------------- S-Type Instructions Functions --------------------------- */

function logic [31:0] encode_stype(
    int rs1, 
    int rs2, 
    int imm
);

    logic [6:0] imm_high;
    logic [4:0] imm_low;
    logic [4:0] rs1_reg;
    logic [4:0] rs2_reg;

    imm_high = imm[11:5];
    imm_low = imm[4:0];
    rs1_reg = rs1;
    rs2_reg = rs2;

    return {imm_high, rs2_reg, rs1_reg, 3'b010, imm_low, OP_STORE};

endfunction : encode_stype

/* SW (Store Word) Instruction */
function logic [31:0] sw(int rs1, int rs2, int imm);
    return encode_stype(rs1, rs2, imm);
endfunction : sw

endpackage : compiler_pkg