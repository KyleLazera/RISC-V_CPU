module reg_file #(
    parameter REG_WIDTH = 32,
    parameter FILE_DEPTH = 32,
    parameter REG_OUTPUT = 0,

    /* Non-Adjustable Parameters */
    parameter ADDR_WIDTH = $clog2(FILE_DEPTH)
) (
    input logic                     i_clk,
    input logic                     i_reset_n,

    // Input Address Signals
    input logic [ADDR_WIDTH-1:0]    i_addr_a,
    input logic [ADDR_WIDTH-1:0]    i_addr_b, 

    // Output Read Signals
    output logic [REG_WIDTH-1:0]    o_data_a,
    output logic [REG_WIDTH-1:0]    o_data_b,

    // Input Write Signals
    input logic [ADDR_WIDTH-1:0]    i_wr_addr,
    input logic [REG_WIDTH-1:0]     i_wr_data,
    input logic                     i_wr_en
);

// Register File Declaration
logic [REG_WIDTH-1:0]   reg_file [FILE_DEPTH];

// -------------------------------------------------------------
// The register file is accessed during two pipeline phases:
// Instruction Decode (read) and Write Back (write).
// Writing on the falling edge ensures that the result produced
// by the Write Back stage can be written into the register file
// within the same cycle it becomes available. If we instead 
// wrote on the rising edge, the data generated in Write Back 
// would not be stored until the next cycle, delaying its 
// availability by one full clock period.
// -------------------------------------------------------------
always_ff @(negedge i_clk) begin
    if (!i_reset_n) begin
        for(int i = 0; i < FILE_DEPTH; i++)
            reg_file[i] <= {REG_WIDTH{1'b0}};
    end else begin
        // Register 0x0 should always contain the value 0
        if (i_wr_en & (i_wr_addr != {REG_WIDTH{1'b0}})) begin
            reg_file[i_wr_addr] <= i_wr_data;
        end
    end
end 

generate 
    // If REG_OUTPUT is set, register outputs first
    if (REG_OUTPUT) begin
        always_ff @(posedge i_clk) begin
            o_data_a <= reg_file[i_addr_a];
            o_data_b <= reg_file[i_addr_b];
        end
    end else begin
        assign o_data_a = reg_file[i_addr_a];
        assign o_data_b = reg_file[i_addr_b];
    end
endgenerate


endmodule