module alu_tb;

    /* Parameters */
    parameter DATA_WIDTH = 32;
    
    /* Variables */
    int result_success = 0, result_failure = 0;
    int zero_success = 0, zero_failure = 0;

    /* Signals */
    logic clk;
    logic reset_n;

    logic [DATA_WIDTH-1:0]  operand_a;
    logic [DATA_WIDTH-1:0]  operand_b;
    logic [3:0]             sel;
    logic [DATA_WIDTH-1:0]  alu_result;
    logic                   zero_flag;

    /* ALU Instnatiation */
    alu #(
        .DATA_WIDTH(DATA_WIDTH),
        .SEL_WIDTH(4),
        .REG_OUTPUT(0)
    ) DUT (
        .i_clk(clk),
        .i_src_a(operand_a),
        .i_src_b(operand_b),
        .i_sel(sel),
        .o_data(alu_result),
        .o_zero(zero_flag)
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
    end      

    /* ---------- Drive data to ALU (DUT) & Compare with Expected ---------- */
    task run_test(
        input logic [31:0] a,
        input logic [31:0] b,
        input logic [3:0]  alu_sel,
        input logic [31:0] expected
    );
        begin
            operand_a = a;
            operand_b = b;
            sel   = alu_sel;

            @(posedge clk);

            // Validate ALU Output with expected output
            if (alu_result !== expected) begin
                $display("\n[FAIL] sel=%b  A=%0d  B=%0d  Expected=%0d  Got=%0d",
                          alu_sel, a, b, expected, alu_result);
                result_failure++;
            end else begin
                $display("[PASS] sel=%b  A=%0d  B=%0d  Result=%0d",
                          alu_sel, a, b, alu_result);
                result_success++;
            end

            // Validate Zero Flag
            if (alu_result == 0) begin
                if (zero_flag != 1'b1) begin
                    $display("[FAIL] Zero flag incorrect for A=%0d B=%0d", a, b);
                    zero_failure++;
                end else
                    zero_success++;
            end else begin
                if (zero_flag != 1'b0) begin
                    $display("[FAIL] Zero flag incorrect for A=%0d B=%0d", a, b);
                    zero_failure++;
                end else
                    zero_success++;
            end

        end
    endtask    

    /* ---------- Computer Expected Value from ALU ---------- */
    function automatic [31:0] exp_alu(
        input [31:0] a,
        input [31:0] b,
        input [3:0] sel
    );
        case(sel)
            4'b0000: exp_alu = a + b;
            4'b0001: exp_alu = a - b;
            4'b0010: exp_alu = a << b;
            4'b0011: exp_alu = (a < b);
            4'b0100: exp_alu = ($signed(a) < $signed(b));
            4'b0101: exp_alu = a ^ b;
            4'b0110: exp_alu = a >> b;
            4'b0111: exp_alu = $signed(a) >>> b;
            4'b1000: exp_alu = a | b;
            4'b1001: exp_alu = a & b;
            default: exp_alu = a + b;
        endcase
    endfunction

    /* ---------- Main Testcase ---------- */
    initial begin
        @(posedge reset_n);
        @(posedge clk);

        $display("\n===== BEGIN ALU TESTS =====\n");

        // Loop through all operations
        for (int op = 0; op < 10; op++) begin
            for (int t = 0; t < 20; t++) begin
                logic [31:0] a = $random;
                // For logical/arithmetic shift values, we want the value to shift by to be smaller so we can validate the shifting
                // functionality
                logic [31:0] b = (op == 4'b0010 || op == 4'b0110 || op == 4'b0111) ? $urandom_range(35,0) : $random;

                run_test(a, b, op[3:0], exp_alu(a, b, op[3:0]));
            end
        end

        // Corner cases (signed/unsigned) & Zero Flags
        run_test(32'hFFFF_FFFF, 32'd1, 4'b0000, exp_alu(32'hFFFF_FFFF, 32'd1, 4'b0000)); // ADD wrap
        run_test(-5, 3,          4'b0100, exp_alu(-5, 3, 4'b0100));                      // SLT signed
        run_test(32'hFFFF_FFFE, 1, 4'b0011, exp_alu(32'hFFFF_FFFE, 1, 4'b0011));         // SLTU
        run_test(32'h8000_0000, 1, 4'b0111, exp_alu(32'h8000_0000, 1, 4'b0111));         // SRA sign-extend
        run_test(5, 5,          4'b0001, exp_alu(5, 5, 4'b0001));                        // SUB to zero

        $display("\n===== ALL ALU TESTS COMPLETE =====\n");

        $display("RESULT SUMMARY:");
        $display("  Result:  %0d Passed, %0d Failed", result_success, result_failure);
        $display("  Zero Flag: %0d Passed, %0d Failed", zero_success, zero_failure);    

        #10;
        $finish;
    end    

endmodule : alu_tb