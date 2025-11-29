module hazard_unit (
    /* Input Logic */
    input logic [4:0]       i_IE_src_reg_1,         // Source register 1 currently in memory stage
    input logic [4:0]       i_IE_src_reg_2,         // Source register 2 currently in memory stage
    input logic [4:0]       i_IM_dst_reg,           // Destination for following instruction (in execute stage)
    input logic [4:0]       i_WB_dst_reg,           // Destination for writeback statge
    input logic             i_ctrl_WB_reg_wr_en,    // Enable signal to write into data memory
    input logic             i_ctrl_IM_reg_wr_en,    // Enable signal to write into register file

    /* Output Logic */
    output logic            o_IM_forward,           // When set, indicates we should forward data from Memory stage 
    output logic            o_WB_forward            // When set, we should forward data from Write back stage
);

/* --------------------- Forwarding/Bypass logic --------------------- */

// ------------------------------------------------------------
// Memory stage forward is responsible for forwarding data from
// the memory stage to the execute stage (back by 1 pipeline stage).
// This allows an instruction to use the output of the previous
// instruction.
// ------------------------------------------------------------
assign o_IM_forward = (i_IM_dst_reg == i_IE_src_reg_1) & (i_IM_dst_reg != 0) & i_ctrl_IM_reg_wr_en;

assign o_WB_forward = (i_WB_dst_reg == i_IE_src_reg_2) & (i_WB_dst_reg != 0) & i_ctrl_WB_reg_wr_en;

endmodule