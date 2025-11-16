/* This module is a simple ALU (arithmetic logic unit) that
 * is used for the RISC-V Execute phase (Within the 5-stage
 * pipeline). It works similarly to a mulitplexer which determines
 * what operation is performed on the 2 source inputs. 
 * The ALU currently supports:
 *  1) Addition                     (i_sel = 0000)
 *  2) Subtraction                  (i_sel = 0001)
 *  3) Logical Shift Left (SLL)     (i_sel = 0010)
 *  4) Set Less Than (unsigned)     (i_sel = 0011)
 *  5) Set Less Than (signed)       (i_sel = 0100)
 *  6) Bit-wise XOR                 (i_sel = 0101)
 *  7) Logical Shift Right (SRL)    (i_sel = 0110)
 *  8) Arithmetic Shift Right (SRA) (i_sel = 0111)
 *  9) Bit-wise OR                  (i_sel = 1000)
 * 10) Bit-wise AND                 (i_sel = 1001)
 *
 * The ALU also has a parameter, REG_OUTPUT, that enables the user to
 * register the output. If this is not set, the output is combinational.
 */

module alu #(
    parameter DATA_WIDTH = 32,
    parameter SEL_WIDTH = 4,
    parameter REG_OUTPUT = 0
) (
    
    input logic     i_clk,

    input logic [DATA_WIDTH-1:0]    i_src_a,
    input logic [DATA_WIDTH-1:0]    i_src_b,
    input logic [SEL_WIDTH-1:0]     i_sel,

    output logic [DATA_WIDTH-1:0]   o_data,
    output logic                    o_zero
);

// ALU Logic 

logic [DATA_WIDTH-1:0]  temp_out;

always_comb begin
    case(i_sel)
        4'b0000: temp_out = i_src_a + i_src_b;
        4'b0001: temp_out = i_src_a - i_src_b;
        4'b0010: temp_out = i_src_a << i_src_b;
        4'b0011: temp_out = $signed(i_src_a) < $signed(i_src_b);
        4'b0100: temp_out = i_src_a < i_src_b; 
        4'b0101: temp_out = i_src_a ^ i_src_b;
        4'b0110: temp_out = i_src_a >> i_src_b;
        4'b0111: temp_out = $signed(i_src_a) >>> i_src_b;
        4'b1000: temp_out = i_src_a | i_src_b;
        4'b1001: temp_out = i_src_a & i_src_b;
        default: temp_out = i_src_a + i_src_b;
    endcase
end

generate
    // Register the output if parameter was set
    if (REG_OUTPUT) begin
        always_ff @(posedge i_clk) begin
            o_zero <= (temp_out == {DATA_WIDTH{1'b0}});
            o_data <= temp_out; 
        end  
    end else begin
        assign o_data = temp_out;
        assign o_zero = (temp_out == {DATA_WIDTH{1'b0}});
    end
endgenerate

endmodule