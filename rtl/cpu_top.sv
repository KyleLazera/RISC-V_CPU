module cpu_top #(
    parameter DATA_WIDTH = 32
) (
    input logic         i_clk,
    input logic         i_reset_n
);

/* ---------------- Local Parameters  ---------------- */

localparam OP_CODE_WIDTH = 7;
localparam FUNCT3_WIDTH = 3;
localparam FUNCT7_WIDTH = 7;   

/* ---------------- Control Unit Instantiation  ---------------- */

logic [OP_CODE_WIDTH-1:0] op_code;
logic [FUNCT3_WIDTH-1:0]  funct3;
logic [FUNCT7_WIDTH-1:0]  funct7;

logic [1:0]               imm_sel;
logic                     alu_src_sel;
logic [3:0]               alu_op;
logic                     reg_file_wr_en;
logic [1:0]               wb_result_sel;
logic                     pc_src_sel;
logic                     mem_wr_en;

control_unit #(
    .DATA_WIDTH(DATA_WIDTH),
    .OP_CODE_WIDTH(OP_CODE_WIDTH),
    .FUNCT3_WIDTH(FUNCT3_WIDTH),
    .FUNCT7_WIDTH(FUNCT7_WIDTH)
) control_unit_inst (
    .i_clk(i_clk),
    .i_reset_n(i_reset_n),

    /* Decoded Instruction Inputs */
    .i_op_code(op_code),
    .i_funct3(funct3),
    .i_funct7(funct7),    
    .i_alu_zero_flag(),

    /* Output Control Signals */
    .o_imm_sel(imm_sel),           // Indicates where within the instruction the immediate bits are located
    .o_alu_src_sel(alu_src_sel),          // Selects between register file output or immediate value for ALU operand 2
    .o_alu_op(alu_op),               // ALU operation select signal
    .o_reg_file_wr_en(reg_file_wr_en),       // Enables writing back to the register file
    .o_wb_result_sel(wb_result_sel),
    .o_pc_src_sel(pc_src_sel),
    .o_mem_wr_en(mem_wr_en)
);

/* ---------------- Data Path Instantiation  ---------------- */

data_path #(
    .DATA_WIDTH(DATA_WIDTH),
    .OP_CODE_WIDTH(OP_CODE_WIDTH),
    .FUNCT3_WIDTH(FUNCT3_WIDTH),
    .FUNCT7_WIDTH(FUNCT7_WIDTH)
) data_path_inst (
    .i_clk(i_clk),
    .i_reset_n(i_reset_n),

    /* Control Unit Outputs */
    .o_op_code(op_code),
    .o_funct3(funct3),
    .o_funct7(funct7),
    .o_alu_zero_flag(),

    /* Control Unit Inputs */
    .i_ctrl_imm_sel(imm_sel),
    .i_ctrl_alu_src_sel(alu_src_sel),        // Selects teh second operand for the ALU (immediate vs register output)
    .i_ctrl_alu_op(alu_op),             // ALU operation select from control unit
    .i_ctrl_reg_file_wr_en(reg_file_wr_en),
    .i_ctrl_wb_result_sel(wb_result_sel),
    .i_ctrl_PC_sel(pc_src_sel),
    .i_mem_wr_en(mem_wr_en)   
);


endmodule