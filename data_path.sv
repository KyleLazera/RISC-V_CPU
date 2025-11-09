//TODO: Need to deal with passing pipelined PC value for JAL instructions
//TODO: Replace Data memory with interface to on-board DDR3 memory controller
// TODO: PC Targte from Instruction execute phase is used before declaration

module data_path #(
    parameter DATA_WIDTH = 32,

) (
    input logic         i_clk,
    input logic         i_reset_n,

    // Control Signals 


    // Hazard Signals 
);

/* Local Parameters */

localparam  INSTR_MEM_WIDTH = DATA_WIDTH;
localparam  INSTR_MEM_DEPTH = 5;
localparam  INSTR_MEM_ADDR_WIDTH = $clog2(INSTR_MEM_DEPTH);

localparam REG_FILE_ADDR = $clog2(DATA_WIDTH);
localparam OP_CODE_WIDTH = 7;
localparam FUNCT3_WIDTH = 3;
localparam FUNCT7_WIDTH = 7;

/* ---------------- Instruction Fetch  ---------------- */

logic [INSTR_MEM_ADDR_WIDTH-1:0]    IF_ID_program_ctr;
logic [INSTR_MEM_ADDR_WIDTH-1:0]    IF_ID_program_ctr_next;
logic [DATA_WIDTH-1:0]              IF_ID_instruction;

IF #(
    .INSTR_WIDTH(DATA_WIDTH),
    .INSTR_MEM_DEPTH(INSTR_MEM_DEPTH)
) instruction_fetch (
    .i_clk(i_clk),
    .i_reset_n(i_reset_n),
    .i_ctrl_PC_sel(),
    .i_PC_target(IE_IM_PC_target),
    .o_IF_instr(IF_ID_instruction),
    .o_IF_program_cntr(IF_ID_program_ctr),
    .o_IF_program_cntr_next(IF_ID_program_ctr_next)
);

/* ---------------- Instruction Decode  ---------------- */

logic [DATA_WIDTH-1:0]      ID_IE_rd_data_1;
logic [DATA_WIDTH-1:0]      ID_IE_rd_data_2;
logic [DATA_WIDTH-1:0]      ID_IE_immediate;

ID #(
    .INSTR_WIDTH(DATA_WIDTH),
    .REG_FILE_DEPTH(DATA_WIDTH)
) instruction_decode (
    .i_clk(i_clk),
    .i_reset_n(i_reset_n),
    .i_ctrl_imm_sel(),
    .i_ctrl_WB_en(),
    .o_ctrl_opcode(),
    .o_ctrl_funct3(),
    .o_ctrl_funct7(),
    .i_IF_instruction(IF_ID_instruction),
    .i_WB_result(WB_result),
    .i_WB_addr(WB_dst_reg),
    .o_ID_data_1(ID_IE_rd_data_1),
    .o_ID_data_2(ID_IE_rd_data_2),
    .o_ID_immediate(ID_IE_immediate)
);

// --------------------------------------------------------
// In addition to decoding the instruction & sign extending
// the immediate value, we also need to pipeline the program
// counter value & next value from the IF stage. This allows 
// the program counter value to stay in sync with the 
// instruction it corresponds to.
// --------------------------------------------------------

logic [INSTR_MEM_ADDR_WIDTH-1:0]    ID_program_cntr = {INSTR_MEM_ADDR_WIDTH{1'b0}};
logic [INSTR_MEM_ADDR_WIDTH-1:0]    ID_program_cntr_next = {INSTR_MEM_ADDR_WIDTH{1'b0}};

always_ff @(posedge i_clk) begin
    if (!i_reset_n) begin
        ID_program_cntr <= {INSTR_MEM_ADDR_WIDTH{1'b0}};
        ID_program_cntr_next <= {INSTR_MEM_ADDR_WIDTH{1'b0}};
    end else begin
        ID_program_cntr <= IF_ID_program_ctr;
        ID_program_cntr_next <= IF_ID_program_ctr_next;
    end  
end

/* ---------------- Instruction Execute  ---------------- */

logic [DATA_WIDTH-1:0]              IE_IM_alu_result;
logic [DATA_WIDTH-1:0]              IE_IM_data_write;
logic [INSTR_MEM_ADDR_WIDTH-1:0]    IE_IM_PC_target;

I_Execute #(
    .DATA_WIDTH(DATA_WIDTH),
    .REG_FILE_ADDR(REG_FILE_ADDR),
    .INSTR_MEM_ADDR(INSTR_MEM_ADDR_WIDTH)
) instruction_execute (
    .i_clk(i_clk),
    .i_reset_n(i_reset_n),
    .i_ctrl_alu_src_sel(),
    .i_ctrl_alu_op_sel(),
    .i_ID_read_data_1(ID_IE_rd_data_1),
    .i_ID_read_data_2(ID_IE_rd_data_2),
    .i_ID_program_ctr(ID_program_cntr),
    .i_ID_immediate(ID_IE_immediate),
    .o_IE_result(IE_IM_alu_result),
    .o_IE_data_write(IE_IM_data_write),
    .o_IE_PC_target(IE_IM_PC_target)
);

// --------------------------------------------------------
// Similarly to the INstruction Decode stage, we also need 
// to pipeline the program counter next value & the 
// destination register from the decode stage. This allows
// the program counter and destination register to remain
// in sync with the instruction being executed, since both
// of these values will be used in the final write-back stage.
// --------------------------------------------------------

logic [REG_FILE_ADDR-1:0]           IE_dst_reg = {REG_FILE_ADDR{1'b0}};
logic [INSTR_MEM_ADDR_WIDTH-1:0]    IE_program_cntr_next = {INSTR_MEM_ADDR_WIDTH{1'b0}};


always_ff @(posedge i_clk) begin
    if (!i_reset_n) begin
        IE_dst_reg <= {REG_FILE_ADDR{1'b0}};
        IE_program_cntr_next <= {INSTR_MEM_ADDR_WIDTH{1'b0}};
    end else begin
        IE_dst_reg <= ID_dst_reg;
        IE_program_cntr_next <= ID_program_cntr_next;
    end
end

/* ---------------- Memory Read/Write  ---------------- */

logic [DATA_WIDTH-1:0]      IM_mem_addr;
logic [DATA_WIDTH-1:0]      IM_mem_wr_data;
logic [DATA_WIDTH-1:0]      IM_mem_rd_data;

assign IM_mem_addr = IE_IM_alu_result;
assign IM_mem_wr_data = IE_IM_data_write;

// Memory Instantiation
data_mem #(
    .DATA_WIDTH(DATA_WIDTH),
    .MEM_DEPTH(32)
) mem (
    .i_clk(i_clk),
    .i_reset_n(i_reset_n),
    .i_mem_addr(IM_mem_addr[4:0]),          //NOTE: To mimize total memory depth - only use first 5 bits of actual address
    .i_wr_data(IM_mem_wr_data),
    .i_wr_en(),                         // TODO: This comes from control Unit
    .o_rd_data(IM_mem_rd_data)     
);

// Pipeline Logic

logic [DATA_WIDTH-1:0]              IM_read_data = {DATA_WIDTH{1'b0}};
logic [REG_FILE_ADDR-1:0]           IM_dst_reg = {REG_FILE_ADDR{1'b0}};
logic [INSTR_MEM_ADDR_WIDTH-1:0]    IM_program_cntr_next = {INSTR_MEM_ADDR_WIDTH{1'b0}};

always_ff @(posedge i_clk) begin
    if (!i_reset_n) begin
        IM_read_data <= {DATA_WIDTH{1'b0}};
        IM_dst_reg <= {REG_FILE_ADDR{1'b0}};
        IM_program_cntr_next <= {INSTR_MEM_ADDR_WIDTH{1'b0}};
    end else begin
        IM_read_data <= IM_mem_rd_data;
        IM_dst_reg <= IE_dst_reg;
        IM_program_cntr_next <= IE_program_cntr_next;
    end
end

/* ---------------- Memory Write-Back  ---------------- */

logic [DATA_WIDTH-1:0]    WB_result;
logic [REG_FILE_ADDR-1:0] WB_dst_reg;

// TODO: Depends on control signal
// case(WB_result_sel)
//     2'b00: WB_result = IE_alu_result;            // Load from ALU output
//     2'b01: WB_result = IM_read_data;             // Data output from memory block
//     2'b10: WB_result = IE_program_cntr_next;     // Next PC for JAL instructions
//     default: WB_result = {DATA_WIDTH{1'b0}};
// endcase



endmodule 