class golden_model#(
    parameter DATA_WIDTH = 32,
    parameter MEMORY_DEPTH = 256,
    parameter INSTR_MEM_DEPTH = 256
);

    localparam PC_WIDTH = $clog2(INSTR_MEM_DEPTH);

    typedef enum logic [6:0] {
        R_TYPE = 7'b0110011,
        I_TYPE = 7'b0010011,
        LOAD = 7'b0000011,
        S_TYPE = 7'b0100011,
        B_TYPE = 7'b1100011,
        JALR = 7'b1100111
    }op_codes;

    /* Architectural State */
    logic [DATA_WIDTH-1:0]  register_file [DATA_WIDTH];
    logic [DATA_WIDTH-1:0]  data_memory [MEMORY_DEPTH];
    logic [DATA_WIDTH-1:0]  instr_memory [INSTR_MEM_DEPTH];
    logic [PC_WIDTH-1:0]    program_cntr = {PC_WIDTH{1'b0}};
    

    function new(logic [DATA_WIDTH-1:0]  instructions [INSTR_MEM_DEPTH]);
        program_cntr = {PC_WIDTH{1'b0}};

        // Load the instructions into the model memory
        for(int i = 0; i < INSTR_MEM_DEPTH; i++) begin
            instr_memory[i] = instructions[i];
        end

        // Load initial state of data memory
        for(int i = 0; i < MEMORY_DEPTH; i++) begin
            data_memory[i] = 32'b0;
        end

        // Load initial state of register file
        for(int i = 0; i < DATA_WIDTH; i++) begin
            register_file[i] = i;
        end
    endfunction : new

    // -----------------------------------------------
    // Execute a single instruction
    // -----------------------------------------------
    function void step();

        // Fetch the instruction from memory
        logic [31:0] instr = instr_memory[program_cntr];

        // Decode the instruction
        logic [6:0] opcode  = instr[6:0];
        logic [4:0] rd      = instr[11:7];
        logic [2:0] funct3  = instr[14:12];
        logic [4:0] rs1     = instr[19:15];
        logic [4:0] rs2     = instr[24:20];
        logic [6:0] funct7  = instr[31:25];

        logic [31:0] imm_i;
        logic [31:0] imm_s;
        logic [31:0] imm_b;
        logic [31:0] result;

        logic [31:0] next_pc;

        // Immediate formats
        imm_i = {{20{instr[31]}}, instr[31:20]};
        imm_s = {{20{instr[31]}}, instr[31:25], instr[11:7]};
        imm_b = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};

        $display("PC: %0h", program_cntr);

        // Default next PC
        next_pc = program_cntr + 4;

        case (opcode)

            // ---------------------------------------------------
            // R-TYPE
            // ---------------------------------------------------
            R_TYPE: begin
                $display("R-Type Instruction executed");
                case ({funct7, funct3})
                    {7'b0000000, 3'b000}: result = register_file[rs1] + register_file[rs2];     // ADD
                    {7'b0100000, 3'b000}: result = register_file[rs1] - register_file[rs2];     // SUB
                    {7'b0000000, 3'b001}: result = register_file[rs1] << register_file[rs2][4:0]; // SLL
                    {7'b0000000, 3'b010}: result = ($signed(register_file[rs1]) < $signed(register_file[rs2])); // SLT
                    {7'b0000000, 3'b011}: result = (register_file[rs1] < register_file[rs2]);     // SLTU
                    {7'b0000000, 3'b100}: result = register_file[rs1] ^ register_file[rs2];     // XOR
                    {7'b0000000, 3'b101}: result = register_file[rs1] >> register_file[rs2][4:0]; // SRL
                    {7'b0100000, 3'b101}: result = $signed(register_file[rs1]) >>> register_file[rs2][4:0]; // SRA
                    {7'b0000000, 3'b110}: result = register_file[rs1] | register_file[rs2];     // OR
                    {7'b0000000, 3'b111}: result = register_file[rs1] & register_file[rs2];     // AND
                    default: result = 32'd0;
                endcase

                if (rd != 0)
                    register_file[rd] = result;
            end


            // ---------------------------------------------------
            // I-TYPE ALU
            // ---------------------------------------------------
            I_TYPE: begin
                $display("I-Type Instruction:");
                case (funct3)
                    3'b000: result = register_file[rs1] + imm_i;                     // ADDI
                    3'b010: result = ($signed(register_file[rs1]) < $signed(imm_i)); // SLTI
                    3'b011: result = (register_file[rs1] < imm_i);                   // SLTIU
                    3'b100: result = register_file[rs1] ^ imm_i;                     // XORI
                    3'b110: result = register_file[rs1] | imm_i;                     // ORI
                    3'b111: result = register_file[rs1] & imm_i;                     // ANDI

                    3'b001: result = register_file[rs1] << instr[24:20];             // SLLI

                    3'b101: begin
                        if (instr[30]) result = $signed(register_file[rs1]) >>> instr[24:20]; // SRAI
                        else           result = register_file[rs1] >> instr[24:20];           // SRLI
                    end
                endcase

                if (rd != 0) begin
                    register_file[rd] = result;
                    $display("Writing %0d to reg: %0d", result, rd);
                    $display("Reg[%0d]: %0d", rd, register_file[rd]);
                end
            end


            // ---------------------------------------------------
            // STORE (SW)
            // ---------------------------------------------------
            S_TYPE: begin
                $display("Store Instruction Executed");
                data_memory[(register_file[rs1] + imm_s)] = register_file[rs2]; 
            end


            // ---------------------------------------------------
            // BRANCH (BEQ only)
            // ---------------------------------------------------
            B_TYPE: begin
                $display("B-Type Instruction executed.");
                if (funct3 == 3'b000) begin // BEQ
                    if (register_file[rs1] == register_file[rs2])
                        next_pc = program_cntr + imm_b;
                    else
                        next_pc = program_cntr + 12; // If branch is not taken, skip over no-ops in golden model - this will throw off alignment between model and DUT
                end  
                    
                $display("New PC: %0h", next_pc);
            end


            // ---------------------------------------------------
            // JALR
            // ---------------------------------------------------
            JALR: begin
                $display("JALR Instruction executed. Jumping to %0d + %0d", register_file[rs1], imm_i);
                if (rd != 0) 
                    register_file[rd] = next_pc;

                next_pc = (register_file[rs1] + imm_i);
                $display("New PC: %0d", next_pc);
            end

            // ---------------------------------------------------
            // LOAD (LW)
            // ---------------------------------------------------
            LOAD: begin
                $display("LW Instruction executed");

                if (funct3 == 3'b010) begin
                    int addr = register_file[rs1] + imm_i;

                    if (rd != 0)
                        register_file[rd] = data_memory[addr];  
                end
            end            

            default: begin
                $display("No-OP Instruction executed");
                // Unsupported instruction → no-op
            end

        endcase

        program_cntr = next_pc;

    endfunction : step


    // ----------------------------------------------------------------
    // Validate the reg file and its current state by comparing the DUT
    // reg file to the golden model reg file.
    // ----------------------------------------------------------------
    function void validate_reg_file(logic [DATA_WIDTH-1:0] dut_reg_file [DATA_WIDTH]);

        foreach(dut_reg_file[i]) begin
            assert(register_file[i] == dut_reg_file[i]) begin
                //$display("MATCH: Model reg[%0d]: %0h == Actual reg[%0d]: %0h", i, register_file[i], i, dut_reg_file[i]);
            end else begin
                $display("MISMATCH: Model reg[%0d]: %0h != Actual reg[%0d]: %0h", i, register_file[i], i, dut_reg_file[i]);
                $stop;
            end
        end
    endfunction : validate_reg_file

    // ----------------------------------------------------------------
    // Validate the datae memory and its current state by comparing the DUT
    // memory to the golden model reg file.
    // ----------------------------------------------------------------
    function void validate_memory(logic [DATA_WIDTH-1:0] dut_memory [MEMORY_DEPTH]);

        foreach(data_memory[i]) begin
            assert(data_memory[i] == dut_memory[i]) begin
                //$display("MATCH: Model reg[%0d]: %0h == Actual reg[%0d]: %0h", i, register_file[i], i, dut_reg_file[i]);
            end else begin
                $display("[%t] MISMATCH: Model Mem[%0d]: %0h != Actual Mem[%0d]: %0h", $time, i, data_memory[i], i, dut_memory[i]);
                $stop;
            end
        end
    endfunction : validate_memory

endclass : golden_model