/* This module is intended to represent a memory block
 * that is used to hold data in the CPU. This is a 
 * temporary implementaiton that will be changed 
 * to an actual memory controller rather than 
 * implementing the memory on the FPGA.
 * This memory takes in an address. If i_wr_en is 
 * set, then it will write the data on i_wr_data to
 * the address presented. The module will also always 
 * combinationally output the data at teh input mem 
 * address.
 */

module data_mem #(
    parameter DATA_WIDTH = 32,
    parameter MEM_DEPTH = 2**32,

    /* Do Not Modify */
    parameter ADDR_WIDTH = $clog2(MEM_DEPTH)
) (
    input logic                     i_clk,
    input logic                     i_reset_n,

    // Write Memory Interface
    input logic [ADDR_WIDTH-1:0]    i_mem_addr,
    input logic [DATA_WIDTH-1:0]    i_wr_data,
    input logic                     i_wr_en,

    // Output Read Interface
    output logic [DATA_WIDTH-1:0]   o_rd_data          
);

// Memory block instantiation
logic [DATA_WIDTH-1:0] mem [MEM_DEPTH-1:0];

always_ff @(posedge i_clk) begin
    if (!i_reset_n) begin
        for(int i = 0; i < MEM_DEPTH; i++)
            mem[i] <= {DATA_WIDTH{1'b0}};
    end else begin
        // If write enable is set, write data to memory
        if (i_wr_en) 
            mem[i_mem_addr] <= i_wr_data;
    end
end

// Combinational memory read
assign o_rd_data = mem[i_mem_addr];

endmodule