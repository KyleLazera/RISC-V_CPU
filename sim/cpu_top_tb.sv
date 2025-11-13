module cpu_top_tb;

logic clk;
logic reset_n;

cpu_top #(
    .DATA_WIDTH(32)
) cpu_top_inst (
    .i_clk(clk),
    .i_reset_n(reset_n)
);

/* Clock Generation */
initial begin
    clk = 1'b0;
    forever #5 clk = ~clk; // 10MHz Clock
end

/* Reset Generation */
initial begin
    reset_n = 1'b0;
    repeat(3)
        @(posedge clk);
    reset_n <= 1'b1; 
    @(posedge clk);

    // Simulation run time only used for initial testing to prevent infinite running
    #1000;
    $finish;
end

endmodule : cpu_top_tb