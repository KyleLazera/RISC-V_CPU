/* This module is a simple ALU (arithmetic logic unit) that
 * is used for the RISC-V Execute phase (Within the 5-stage
 * pipeline). It works similarly to a mulitplexer which determines
 * what operation is performed on the 2 source inputs. The ALU 
 * currently supports:
 *  1) Addition (i_sel = 000)
 *  2) Subtraction (i_sel = 001)
 *  3) Bit-wise AND (i_sel = 010)
 *  4) Bit-wise OR (i_sel = 011)
 *  5) Src A < Arc B (i_sel = 100)
 *
 * The ALU also has a parameter, REG_OUTPUT, that enables the user to
 * register the output. If this is not set, the output is combinational.
 */

module alu #(
    parameter DATA_WIDTH = 32,
    parameter SEL_WIDTH = 3,
    parameter REG_OUTPUT = 0
) (
    
    input logic     i_clk,

    input logic [DATA_WIDTH-1:0]    i_src_a,
    input logic [DATA_WIDTH-1:0]    i_src_b,
    input logic [SEL_WIDTH-1:0]     i_sel,

    output logic [DATA_WIDTH-1:0]   o_data
);

// ALU Logic 

logic [DATA_WIDTH-1:0]  temp_out;

always_comb begin
    case(i_sel)
        3'b000: temp_out = i_src_a + i_src_b;
        3'b001: temp_out = i_src_a - i_src_b;
        3'b010: temp_out = i_src_a & i_src_b;
        3'b011: temp_out = i_src_a | i_src_b;
        3'b100: temp_out = i_src_a < i_src_b;
        default: temp_out = i_src_a + i_src_b;
    endcase
end

generate
    // Register the output if parameter was set
    if (REG_OUTPUT) begin
        always_ff @(posedge i_clk)
            o_data <= temp_out;   
    end else begin
        assign o_data = temp_out;
    end
endgenerate

endmodule