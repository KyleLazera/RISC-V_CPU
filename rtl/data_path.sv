//TODO: Replace Data memory with interface to on-board DDR3 memory controller

module data_path #(
    parameter DATA_WIDTH = 32,

    /* Decoding Parameters */
    parameter OP_CODE_WIDTH = 7,
    parameter FUNCT3_WIDTH = 3,
    parameter FUNCT7_WIDTH = 7,

    /* Memory Parameters */
    parameter MEM_DEPTH = 256,
    parameter INSTR_MEM_DEPTH = 256,

    /* Simulation Parameters */
    parameter SIMULATION = 1    
) (
    input logic         i_clk,
    input logic         i_reset_n,

    /* Control Unit Interface */
    output logic [OP_CODE_WIDTH-1:0] o_op_code,
    output logic [FUNCT3_WIDTH-1:0]  o_funct3,
    output logic [FUNCT7_WIDTH-1:0]  o_funct7,
    output logic                     o_alu_zero_flag,   

    input logic [1:0]                i_ctrl_imm_sel,            // Immediate select from control unit
    input logic                      i_ctrl_alu_src_sel,        // Selects teh second operand for the ALU (immediate vs register output)
    input logic [3:0]                i_ctrl_alu_op,             // ALU operation select from control unit
    input logic                      i_ctrl_reg_file_wr_en,
    input logic [1:0]                i_ctrl_wb_result_sel,      // Determine the Source for the Write Back 
    input logic                      i_ctrl_jump,
    input logic                      i_ctrl_branch,
    input logic                      i_mem_wr_en,  

    /* Hazard Unit Interface */
    output logic [4:0]               o_IE_src_reg_1,
    output logic [4:0]               o_IE_src_reg_2,
    output logic [4:0]               o_IM_dst_reg,
    output logic [4:0]               o_WB_dst_reg,
    output logic                     o_ctrl_WB_reg_wr_en,
    output logic                     o_ctrl_IM_reg_wr_en,

    input logic                      i_IM_forward,
    input logic                      i_WB_forward,

    /* Simulation Signals (ONLY IS SIMULATION = 1) */
    output logic                    o_instr_commit
);

/* Local Parameters */

localparam  INSTR_MEM_WIDTH = DATA_WIDTH;
localparam  INSTR_MEM_ADDR_WIDTH = $clog2(INSTR_MEM_DEPTH);

localparam REG_FILE_ADDR = $clog2(DATA_WIDTH);

/* ---------------- Instruction Fetch  ---------------- */

logic [INSTR_MEM_ADDR_WIDTH-1:0]    IF_ID_program_ctr;
logic [INSTR_MEM_ADDR_WIDTH-1:0]    IF_ID_program_ctr_next;
logic [DATA_WIDTH-1:0]              IF_ID_instruction;

I_Fetch #(
    .INSTR_WIDTH(DATA_WIDTH),
    .INSTR_MEM_DEPTH(INSTR_MEM_DEPTH)
) instruction_fetch (
    .i_clk(i_clk),
    .i_reset_n(i_reset_n),
    .i_ctrl_PC_sel(ctrl_IE_PC_sel),                    
    .i_PC_target(IE_IF_PC_target),
    .o_IF_instr(IF_ID_instruction),
    .o_IF_program_cntr(IF_ID_program_ctr),
    .o_IF_program_cntr_next(IF_ID_program_ctr_next)
);

logic       IF_instr_commit = 1'b0;

generate 
    if(SIMULATION) begin 
        always_ff @(posedge i_clk) begin
            if(!i_reset_n) begin
                IF_instr_commit <= 1'b0;
            end else begin
                IF_instr_commit <= 1'b1;
            end
        end
    end
endgenerate

/* ---------------- Instruction Decode  ---------------- */

logic [DATA_WIDTH-1:0]      ID_IE_rd_data_1;
logic [DATA_WIDTH-1:0]      ID_IE_rd_data_2;
logic [DATA_WIDTH-1:0]      ID_IE_immediate;

logic [OP_CODE_WIDTH-1:0]   instr_op_code;
logic [FUNCT3_WIDTH-1:0]    instr_funct3;
logic [FUNCT7_WIDTH-1:0]    instr_funct7;

I_Decode #(
    .INSTR_WIDTH(DATA_WIDTH),
    .REG_FILE_DEPTH(DATA_WIDTH)
) instruction_decode (
    .i_clk(i_clk),
    .i_reset_n(i_reset_n),
    .i_ctrl_imm_sel(i_ctrl_imm_sel),
    .i_ctrl_WB_en(ctrl_IM_reg_wr_en), 
    .o_ctrl_opcode(instr_op_code),
    .o_ctrl_funct3(instr_funct3),
    .o_ctrl_funct7(instr_funct7),
    .i_IF_instruction(IF_ID_instruction),
    .i_WB_result(WB_result),
    .i_WB_addr(WB_dst_reg),
    .o_ID_data_1(ID_IE_rd_data_1),
    .o_ID_data_2(ID_IE_rd_data_2),
    .o_ID_immediate(ID_IE_immediate)
);

assign o_op_code = instr_op_code;
assign o_funct3 = instr_funct3;
assign o_funct7 = instr_funct7;

// --------------------------------------------------------
// In addition to decoding the instruction & sign extending
// the immediate value, we also need to pipeline the program
// counter value & next (program counter) value from the IF stage. 
// This allows the program counter value to stay in sync with the 
// instruction it corresponds to.
// --------------------------------------------------------

logic [INSTR_MEM_ADDR_WIDTH-1:0]    ID_program_cntr = {INSTR_MEM_ADDR_WIDTH{1'b0}};
logic [INSTR_MEM_ADDR_WIDTH-1:0]    ID_program_cntr_next = {INSTR_MEM_ADDR_WIDTH{1'b0}};
logic [REG_FILE_ADDR-1:0]           ID_dst_reg = {REG_FILE_ADDR{1'b0}};
logic [REG_FILE_ADDR-1:0]           ID_src_reg_1 = {REG_FILE_ADDR{1'b0}};
logic [REG_FILE_ADDR-1:0]           ID_src_reg_2 = {REG_FILE_ADDR{1'b0}};

always_ff @(posedge i_clk) begin
    if (!i_reset_n) begin
        ID_program_cntr <= {INSTR_MEM_ADDR_WIDTH{1'b0}};
        ID_program_cntr_next <= {INSTR_MEM_ADDR_WIDTH{1'b0}};
        ID_dst_reg <= {REG_FILE_ADDR{1'b0}};
        ID_src_reg_1 <= {REG_FILE_ADDR{1'b0}};
        ID_src_reg_2 <= {REG_FILE_ADDR{1'b0}};
    end else begin
        ID_program_cntr <= IF_ID_program_ctr;
        ID_program_cntr_next <= IF_ID_program_ctr_next;
        ID_dst_reg <= IF_ID_instruction[11:7];
        ID_src_reg_1 <= IF_ID_instruction[19:15];
        ID_src_reg_2 <= IF_ID_instruction[24:20];
    end  
end

// Hazard Signals 
assign o_IE_src_reg_1 = ID_src_reg_1;
assign o_IE_src_reg_2 = ID_src_reg_2;

// -------------------------------------------------------
// The Control signals are generated combinationally by the
// control unit during the decoding stage. The signals must 
// then be pipelined to remain in sync with the instruction
// as it moves through the pipeline stages.
// -------------------------------------------------------

logic [1:0]     ctrl_ID_wb_result_sel = 2'b00;
logic           ctrl_ID_reg_wr_en = 1'b0;
logic           ctrl_ID_alu_src_sel = 1'b0;
logic [3:0]     ctrl_ID_alu_op = 4'b0;
logic           ctrl_ID_jump = 1'b0;
logic           ctrl_ID_branch = 1'b0;
logic           ctrl_ID_mem_wr_en = 1'b0;

always_ff@(posedge i_clk) begin
    if (!i_reset_n) begin
        ctrl_ID_wb_result_sel <= 2'b00;
        ctrl_ID_reg_wr_en <= 1'b0;
        ctrl_ID_alu_src_sel <= 1'b0;
        ctrl_ID_alu_op <= 4'b0;
        ctrl_ID_jump <= 1'b0;
        ctrl_ID_branch <= 1'b0;
        ctrl_ID_mem_wr_en <= 1'b0;
    end else begin
        ctrl_ID_wb_result_sel <= i_ctrl_wb_result_sel;
        ctrl_ID_reg_wr_en <= i_ctrl_reg_file_wr_en;
        ctrl_ID_alu_src_sel <= i_ctrl_alu_src_sel;
        ctrl_ID_alu_op <= i_ctrl_alu_op;
        ctrl_ID_mem_wr_en <= i_mem_wr_en;
        ctrl_ID_jump <= i_ctrl_jump;
        ctrl_ID_branch <= i_ctrl_branch;
    end
end

logic       ID_instr_commit = 1'b0;

generate 
    if(SIMULATION) begin 
        always_ff @(posedge i_clk) begin
            if(!i_reset_n) begin
                ID_instr_commit <= 1'b0;
            end else begin
                ID_instr_commit <= IF_instr_commit;
            end
        end
    end
endgenerate

/* ---------------- Instruction Execute  ---------------- */

logic [DATA_WIDTH-1:0]              IE_IM_alu_result;
logic [DATA_WIDTH-1:0]              IE_IM_data_write;
logic [DATA_WIDTH-1:0]              IE_src_1;
logic [DATA_WIDTH-1:0]              IE_src_2;
logic [INSTR_MEM_ADDR_WIDTH-1:0]    IE_IF_PC_target;
logic                               IE_alu_zero_flag;

// If the forward signal is set from hazard unit, we need to forward the 
// data from the Memory stage (next pipeline stage) instead of using the 
// data from the register file.
assign IE_src_1 = (i_IM_forward) ? IE_IM_alu_result : ID_IE_rd_data_1;
assign IE_src_2 = (i_WB_forward) ? WB_result : ID_IE_rd_data_2;

I_Execute #(
    .DATA_WIDTH(DATA_WIDTH),
    .REG_FILE_ADDR(REG_FILE_ADDR),
    .INSTR_MEM_ADDR(INSTR_MEM_ADDR_WIDTH)
) instruction_execute (
    .i_clk(i_clk),
    .i_reset_n(i_reset_n),
    .i_ctrl_alu_src_sel(ctrl_ID_alu_src_sel),
    .i_ctrl_jalr(ctrl_ID_jump),
    .i_ctrl_alu_op_sel(ctrl_ID_alu_op),
    .i_ID_read_data_1(IE_src_1), 
    .i_ID_read_data_2(IE_src_2), //ID_IE_rd_data_2
    .i_ID_program_ctr(ID_program_cntr),
    .i_ID_immediate(ID_IE_immediate),
    .o_IE_result(IE_IM_alu_result),
    .o_IE_data_write(IE_IM_data_write),
    .o_IE_PC_target(IE_IF_PC_target),
    .o_IE_zero_flag(IE_alu_zero_flag)
);

// --------------------------------------------------------
// Similarly to the Instruction Decode stage, we also need 
// to pipeline the program counter next value & the 
// destination register from the decode stage. This allows
// the program counter and destination register to remain
// in sync with the instruction being executed, since both
// of these values will be used in the final write-back stage.
// --------------------------------------------------------

logic [REG_FILE_ADDR-1:0]           IE_dst_reg = {REG_FILE_ADDR{1'b0}};
logic [REG_FILE_ADDR-1:0]           IE_src_reg_1 = {REG_FILE_ADDR{1'b0}};
logic [REG_FILE_ADDR-1:0]           IE_src_reg_2 = {REG_FILE_ADDR{1'b0}};
logic [INSTR_MEM_ADDR_WIDTH-1:0]    IE_program_cntr_next = {INSTR_MEM_ADDR_WIDTH{1'b0}};

always_ff @(posedge i_clk) begin
    if (!i_reset_n) begin
        IE_dst_reg <= {REG_FILE_ADDR{1'b0}};
        IE_src_reg_1 <= {REG_FILE_ADDR{1'b0}};
        IE_src_reg_2 <= {REG_FILE_ADDR{1'b0}};
        IE_program_cntr_next <= {INSTR_MEM_ADDR_WIDTH{1'b0}};
    end else begin
        IE_dst_reg <= ID_dst_reg;
        IE_src_reg_1 <= ID_src_reg_1;
        IE_src_reg_2 <= ID_src_reg_2;
        IE_program_cntr_next <= ID_program_cntr_next;
    end
end

// Branch & Jump Logic 
logic           ctrl_IE_PC_sel;

assign ctrl_IE_PC_sel = (ctrl_ID_jump | (ctrl_ID_branch & IE_alu_zero_flag));

// Control Unit Signal Pipelining Logic

logic [1:0]     ctrl_IE_wb_result_sel = 2'b00;
logic           ctrl_IE_reg_wr_en = 1'b0;
logic           ctrl_IE_mem_wr_en = 1'b0;

always_ff@(posedge i_clk) begin
    ctrl_IE_wb_result_sel <= ctrl_ID_wb_result_sel;
    ctrl_IE_reg_wr_en <= ctrl_ID_reg_wr_en;
    ctrl_IE_mem_wr_en <= ctrl_ID_mem_wr_en;
end

// Hazard Signals (Memory Stage)

assign o_IM_dst_reg = IE_dst_reg;
assign o_ctrl_IM_reg_wr_en = ctrl_IE_reg_wr_en;

logic       IE_instr_commit = 1'b0;

generate 
    if(SIMULATION) begin 
        always_ff @(posedge i_clk) begin
            if(!i_reset_n) begin
                IE_instr_commit <= 1'b0;
            end else begin
                IE_instr_commit <= ID_instr_commit;
            end
        end
    end
endgenerate

/* ---------------- Memory Read/Write  ---------------- */

logic [DATA_WIDTH-1:0]      IM_mem_addr;
logic [DATA_WIDTH-1:0]      IM_mem_wr_data;
logic [DATA_WIDTH-1:0]      IM_mem_rd_data;

assign IM_mem_addr = IE_IM_alu_result;
assign IM_mem_wr_data = IE_IM_data_write;

// Memory Instantiation
data_mem #(
    .DATA_WIDTH(DATA_WIDTH),
    .MEM_DEPTH(MEM_DEPTH)
) mem (
    .i_clk(i_clk),
    .i_reset_n(i_reset_n),
    .i_mem_addr(IM_mem_addr),          
    .i_wr_data(IM_mem_wr_data),
    .i_wr_en(ctrl_IE_mem_wr_en),                        
    .o_rd_data(IM_mem_rd_data)     
);

// Pipeline Logic

logic [DATA_WIDTH-1:0]              IM_read_data = {DATA_WIDTH{1'b0}};
logic [REG_FILE_ADDR-1:0]           IM_dst_reg = {REG_FILE_ADDR{1'b0}};
logic [INSTR_MEM_ADDR_WIDTH-1:0]    IM_program_cntr_next = {INSTR_MEM_ADDR_WIDTH{1'b0}};
logic [DATA_WIDTH-1:0]              IM_WB_alu_result = {DATA_WIDTH{1'b0}};

always_ff @(posedge i_clk) begin
    if (!i_reset_n) begin
        IM_read_data <= {DATA_WIDTH{1'b0}};
        IM_dst_reg <= {REG_FILE_ADDR{1'b0}};
        IM_program_cntr_next <= {INSTR_MEM_ADDR_WIDTH{1'b0}};
        IM_WB_alu_result <= {DATA_WIDTH{1'b0}};
    end else begin
        IM_read_data <= IM_mem_rd_data;
        IM_dst_reg <= IE_dst_reg;
        IM_program_cntr_next <= IE_program_cntr_next;
        IM_WB_alu_result <= IE_IM_alu_result;
    end
end

// Control Unit Pipelining Logic

logic [1:0]     ctrl_IM_wb_result_sel = 2'b00;
logic           ctrl_IM_reg_wr_en = 1'b0;

always_ff@(posedge i_clk) begin
    ctrl_IM_wb_result_sel <= ctrl_IE_wb_result_sel;
    ctrl_IM_reg_wr_en <= ctrl_IE_reg_wr_en;
end

logic       IM_instr_commit = 1'b0;

generate 
    if(SIMULATION) begin 
        always_ff @(posedge i_clk) begin
            if(!i_reset_n) begin
                IM_instr_commit <= 1'b0;
            end else begin
                IM_instr_commit <= IE_instr_commit;
            end
        end
    end
endgenerate

/* ---------------- Memory Write-Back  ---------------- */

logic [DATA_WIDTH-1:0]    WB_result;
logic [REG_FILE_ADDR-1:0] WB_dst_reg;

assign WB_dst_reg = IM_dst_reg;

// Hazard Signals (WB Stage)

assign o_WB_dst_reg = WB_dst_reg;
assign o_ctrl_WB_reg_wr_en = ctrl_IM_reg_wr_en;

always_comb begin
    case(ctrl_IM_wb_result_sel)
        2'b00: WB_result = IM_read_data;            // Load from the data memory
        2'b01: WB_result = IM_WB_alu_result;        // Output from the ALU 
        2'b10: WB_result = IM_program_cntr_next;    // Next PC for JAL instructions
        default: WB_result = {DATA_WIDTH{1'b0}};
    endcase
end

/* ---------------- Simulation Related Signals  ---------------- */

logic       instr_commit_pipe[4:0];

generate 
    if(SIMULATION) begin 
        always_ff @(posedge i_clk) begin
            if(!i_reset_n) begin
                for(int i = 0; i < 5; i++)
                    instr_commit_pipe[i] <= 1'b0;
            end else begin
                instr_commit_pipe[0] <= !(o_op_code == 7'b1100111 | o_op_code == 7'b1100011);
                // For branch & jump operations we need to lower the commit for 1 cycle 
                instr_commit_pipe[1] <= (o_op_code == 7'b1100111 | o_op_code == 7'b1100011) ? 1'b0 : instr_commit_pipe[0];
                instr_commit_pipe[2] <= instr_commit_pipe[1];
                instr_commit_pipe[3] <= instr_commit_pipe[2];
                instr_commit_pipe[4] <= instr_commit_pipe[3];
            end
        end
    end
endgenerate

assign o_instr_commit = instr_commit_pipe[3];

endmodule 