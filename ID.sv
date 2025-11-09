module ID #(
    parameter INSTR_WIDTH = 32,
    parameter REG_FILE_DEPTH = 32,

    /* Non-Modifiable Parameters */
    parameter REG_FILE_ADDR = $clog2(REG_FILE_DEPTH),
    parameter DATA_WIDTH = INSTR_WIDTH
) (
    input logic                     i_clk,
    input logic                     i_reset_n,

    // Control Logic 
    logic input [1:0]               i_ctrl_imm_sel,         // The location of teh immediate value varies depending on the instruction,
                                                            // this signal acts as a select to determine which bits to use.
    
    logic input                     i_ctrl_WB_en,           // Enables writing data into teh register file - only used for various
                                                            // instructions.
    logic output [6:0]              o_ctrl_opcode,
    logic output [2:0]              o_ctrl_funct3,
    logic output [6:0]              o_ctrl_funct7,

    // Input Signals 
    logic input [INSTR_WIDTH-1:0]   i_IF_instruction,       // Input Instruction gtom Instruction Fetch
    logic input [DATA_WIDTH-1:0]    i_WB_result,            // Result/Data to wrtie back to the register file
    logic input [REG_FILE_ADDR-1:0] i_WB_addr,              // Address for the destination register to write back to

    // Output Signals 
    logic output [INSTR_WIDTH-1:0]  o_ID_data_1,            // Data output from register file port 1
    logic output [INSTR_WIDTH-1:0]  o_ID_data_2,            // Data output from register file port 2
    logic output [INSTR_WIDTH-1:0]  o_ID_immediate          // Sign extended immediate 
);

/* --------------- Local Parameters --------------- */

localparam OP_CODE_WIDTH = 7;
localparam FUNCT3_WIDTH = 3;
localparam FUNCT7_WIDTH = 7;

/* --------------- Instruction Decoding Logic --------------- */

logic [REG_FILE_ADDR-1:0]           src_reg_1;
logic [REG_FILE_ADDR-1:0]           src_reg_2;
logic [REG_FILE_ADDR-1:0]           dst_reg;
logic [OP_CODE_WIDTH-1:0]           op_code;
logic [FUNCT3_WIDTH-1:0]            funct_3;
logic [FUNCT7_WIDTH-1:0]            funct_7;
logic [24:0]                        immediate;

assign src_reg_1 = i_IF_instruction[19:15];
assign src_reg_2 = i_IF_instruction[24:20];
assign dst_reg = i_IF_instruction[11:7];         // Note: Only used in R and I type instructions
assign op_code = i_IF_instruction[6:0];
assign funct_3 = i_IF_instruction[14:12];
assign funct_7 = i_IF_instruction[31:25];        // NOTE: Only used with R-Type Instructions
assign immediate = i_IF_instruction[31:7];       // NOTE: The location of immediate bits depend on the specific instruction

/* --------------- Register File Instantiation --------------- */

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
    .i_wr_addr(i_WB_addr),   
    .i_wr_data(i_WB_result),   
    .i_wr_en(i_ctrl_WB_en)      // Set by the Control Unit 
);

/* --------------- Immediate Sign Extension Logic --------------- */

logic [DATA_WIDTH-1:0]  se_immediate;  

// --------------------------------------------------
// The instruction decode stage is also responsible
// for sign extending the immediate value within the 
// instruction. To do this, we first have to determine
// which bits of the instruction contain the relevant
// immediate bits, and then concatenate and extend them
// into a 32-bit signed value.
// --------------------------------------------------
always_comb begin
    case(i_ctrl_imm_sel)
        2'b00: se_immediate = {{20{immediate[24]}}, immediate[24:13]};                      // I-Type Instruction {instr[31:20]}
        2'b01: se_immediate = {{20{immediate[24]}}, immediate[24:18], immediate[4:0]};      // S/B Type Instruction {instr[31:25], instr[11:7]}
        // TODO: Complete Extend Unit 2'b10: se_immediate = {{20{immediate[24]}}, }; 
    endcase
end

/* --------------- Pipeline Logic --------------- */

logic [DATA_WIDTH-1:0]              ID_rd_data_1 = {DATA_WIDTH{1'b0}};
logic [DATA_WIDTH-1:0]              ID_rd_data_2 = {DATA_WIDTH{1'b0}};
logic [DATA_WIDTH-1:0]              ID_se_immediate = {DATA_WIDTH{1'b0}};
logic [REG_FILE_ADDR-1:0]           ID_dst_reg = {REG_FILE_ADDR{1'b0}};

always_ff @(posedge i_clk) begin
    if (!i_reset_n) begin
        ID_rd_data_1 <= {DATA_WIDTH{1'b0}};
        ID_rd_data_2 <= {DATA_WIDTH{1'b0}};
        ID_se_immediate <= {DATA_WIDTH{1'b0}};
        ID_dst_reg <= {REG_FILE_ADDR{1'b0}};   
    end else begin
        ID_rd_data_1 <= rd_data_1;
        ID_rd_data_2 <= rd_data_2;
        ID_se_immediate <= se_immediate;
        ID_dst_reg <= dst_reg;   
    end
end

/* --------------- Output Logic --------------- */

assign o_ID_data_1 = ID_rd_data_1;
assign o_ID_data_2 = ID_rd_data_2;
assign o_ID_immediate = ID_se_immediate;

assign o_ctrl_opcode = op_code;
assign o_ctrl_funct3 = funct_3;
assign o_ctrl_funct7 = funct_7;

endmodule