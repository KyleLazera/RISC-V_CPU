//TODO: Replaced Instruction Memory with Instruction Cache
// TODO: Need to deal with passing pipelined PC value for JAL instructions

module data_path #(
    parameter DATA_WIDTH = 32,

) (
    input logic         i_clk,
    input logic         i_reset_n,

    // Control Signals 
    logic               PC_src,                 // Determines the source of the next Program Counter
    logic               reg_file_wr_en,         // Write data to the register files
    logic [1:0]         imm_sel,                // Used to indicate where the immediate bits are within an instruction
    logic [2:0]         alu_sel,                // Select the operation for the ALU to perform
    logic               alu_imm_sel,            // Select Input source for the second operand of the ALU


    // Hazard Signals 
);

/* Local Parameters */

localparam INSTR_MEM_WIDTH = DATA_WIDTH;
localparam INSTR_MEM_DEPTH = 5;
localparam INSTR_MEM_ADDR_WIDTH = $clog2(INSTR_MEM_DEPTH);

localparam REG_FILE_ADDR = $clog2(DATA_WIDTH);
localparam OP_CODE_WIDTH = 7;
localparam FUNCT3_WIDTH = 3;
localparam FUNCT7_WIDTH = 7;

/* ---------------- Instruction Memory ---------------- */

logic [DATA_WIDTH-1:0]  instr_mem [INSTR_MEM_DEPTH];

initial begin
    //TODO: Add initial program to test & run
end

/* ---------------- Instruction Fetch  ---------------- */

logic [INSTR_MEM_ADDR_WIDTH-1:0]    program_cntr = {INSTR_MEM_ADDR_WIDTH{1'b0}};
logic [INSTR_MEM_ADDR_WIDTH-1:0]    program_cntr_next = {INSTR_MEM_ADDR_WIDTH{1'b0}};
logic [INSTR_MEM_ADDR_WIDTH-1:0]    IF_program_cntr = {INSTR_MEM_ADDR_WIDTH{1'b0}};
logic [INSTR_MEM_ADDR_WIDTH-1:0]    IF_program_cntr_next = {INSTR_MEM_ADDR_WIDTH{1'b0}};
logic [DATA_WIDTH-1:0]              IF_instr = {DATA_WIDTH{1'b0}};

assign program_cntr_next = program_cntr + 4;

always @(posedge i_clk) begin
    if (!i_reset_n) begin
        program_cntr <= {INSTR_MEM_ADDR_WIDTH{1'b0}};
        IF_program_cntr <= {INSTR_MEM_ADDR_WIDTH{1'b0}};
        IF_program_cntr_next <= {INSTR_MEM_ADDR_WIDTH{1'b0}};
        IF_instr <= {INSTR_MEM_ADDR_WIDTH{1'b0}};
    end else begin
        //TODO : program_cntr <= (PC_src) ? 
        IF_program_cntr <= program_cntr;
        IF_instr <= instr_mem[program_cntr];
        IF_program_cntr_next <= program_cntr_next;
    end
end

/* ---------------- Instruction Decode  ---------------- */

// Logic to decode the Instruction

logic [REG_FILE_ADDR-1:0]           src_reg_1;
logic [REG_FILE_ADDR-1:0]           src_reg_2;
logic [REG_FILE_ADDR-1:0]           dst_reg;
logic [OP_CODE_WIDTH-1:0]           op_code;
logic [FUNCT3_WIDTH-1:0]            funct_3;
logic [FUNCT7_WIDTH-1:0]            funct_7;
logic [24:0]                        immediate;

assign src_reg_1 = IF_instr[19:15];
assign src_reg_2 = IF_instr[24:20];
assign dst_reg = IF_inst[11:7];         // Note: Only used in R and I type instructions
assign op_code = IF_instr[6:0];
assign funct_3 = IF_instr[14:12];
assign funct_7 = IF_inst[31:25];        // NOTE: Only used with R-Type Instructions
assign immediate = IF_inst[31:7];       // NOTE: The location of immediate bits depend on the specific instruction

/* Reg file read/write logic */

logic [DATA_WIDTH-1:0]              rd_data_1 = {DATA_WIDTH{1'b0}};
logic [DATA_WIDTH-1:0]              rd_data_2 = {DATA_WIDTH{1'b0}};

reg_file #(
    .REG_WIDTH(DATA_WIDTH),
    .FILE_DEPTH(32),
    .REG_OUTPUT(0)              
) regfile (
    .i_clk(i_clk),
    .i_reset_n(i_reset_n),
    .i_addr_a(src_reg_1),       // Source Register 1 as address A
    .i_addr_b(src_reg_2),       // Source Register 2 as address B
    .o_data_a(rd_data_1),
    .o_data_b(rd_data_2),
    .i_wr_addr(),   //TODO: Add from write back stage
    .i_wr_data(),   //TODO: Add from write back stage
    .i_wr_en(reg_file_wr_en)    // Set by the Control Unit 
);

/* Sign Extension Logic */

logic [DATA_WIDTH-1:0]  se_immediate;  

// --------------------------------------------------
// The instruction decode stage is also responsible
// for sign extending the immediate value within the 
// instruction. To do this, we first have to determine
// which bits of the instruction contain the relevant
// immediate bits.
// --------------------------------------------------
always_comb begin
    case(imm_sel)
        2'b00: se_immediate = {{20{immediate[24]}}, immediate[24:13]};                      // I-Type Instruction {instr[31:20]}
        2'b01: se_immediate = {{20{immediate[24]}}, immediate[24:18], immediate[4:0]};      // S/B Type Instruction {instr[31:25], instr[11:7]}
        // TODO: Complete Extend Unit 2'b10: se_immediate = {{20{immediate[24]}}, }; 
    endcase
end

/* Decode Pipeline Logic */

logic [DATA_WIDTH-1:0]              ID_rd_data_1 = {DATA_WIDTH{1'b0}};
logic [DATA_WIDTH-1:0]              ID_rd_data_2 = {DATA_WIDTH{1'b0}};
logic [DATA_WIDTH-1:0]              ID_se_immediate = {DATA_WIDTH{1'b0}};
logic [INSTR_MEM_ADDR_WIDTH-1:0]    ID_program_cntr = {INSTR_MEM_ADDR_WIDTH{1'b0}};
logic [REG_FILE_ADDR-1:0]           ID_src_reg_1 = {REG_FILE_ADDR{1'b0}};
logic [REG_FILE_ADDR-1:0]           ID_src_reg_2 = {REG_FILE_ADDR{1'b0}};
logic [REG_FILE_ADDR-1:0]           ID_dst_reg = {REG_FILE_ADDR{1'b0}};

always_ff @(posedge i_clk) begin
    if (!i_reset_n) begin
        ID_rd_data_1 <= {DATA_WIDTH{1'b0}};
        ID_rd_data_2 <= {DATA_WIDTH{1'b0}};
        ID_se_immediate <= {DATA_WIDTH{1'b0}};
        ID_program_cntr <= {INSTR_MEM_ADDR_WIDTH{1'b0}};
        ID_src_reg_1 <= {REG_FILE_ADDR{1'b0}};
        ID_src_reg_2 <= {REG_FILE_ADDR{1'b0}};
        ID_dst_reg <= {REG_FILE_ADDR{1'b0}};   
    end else begin
        ID_rd_data_1 <= rd_data_1;
        ID_rd_data_2 <= rd_data_2;
        ID_se_immediate <= se_immediate;
        ID_program_cntr <= IF_program_cntr;
        ID_src_reg_1 <= src_reg_1;
        ID_src_reg_2 <= src_reg_2;
        ID_dst_reg <= dst_reg;   
    end
end

/* ---------------- Instruction Execute  ---------------- */

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

assign alu_operand_1 = ID_rd_data_1;
assign alu_operand_2 = (alu_imm_sel) ? ID_se_immediate : ID_rd_data_2;

// ALU Instantiation
alu #(
    .DATA_WIDTH(DATA_WIDTH),
    .SEL_WIDTH(3),
    .REG_OUTPUT(0)
) alu_execute (
    .i_clk(i_clk),
    .i_src_a(alu_operand_1),
    .i_src_b(alu_operand_2),
    .i_sel(alu_sel),
    .o_data(alu_output)
);

/* Execute Pipeline Logic */

logic [DATA_WIDTH-1:0]      IE_alu_result = {DATA_WIDTH{1'b0}};
logic [DATA_WIDTH-1:0]      IE_rd_data_2 = {DATA_WIDTH{1'b0}};
logic [REG_FILE_ADDR-1:0]   IE_dst_reg = {REG_FILE_ADDR{1'b0}};

always_ff @(posedge i_clk) begin
    if (!i_reset_n) begin
        IE_alu_result <= {DATA_WIDTH{1'b0}};
        IE_rd_data_2 <= {DATA_WIDTH{1'b0}};
        IE_dst_reg <= {REG_FILE_ADDR{1'b0}};
    end else begin
        IE_alu_result <= alu_output;
        IE_rd_data_2 <= ID_rd_data_2;
        IE_dst_reg <= ID_dst_reg;
    end
end

/* ---------------- Memory Read/Write  ---------------- */

endmodule 