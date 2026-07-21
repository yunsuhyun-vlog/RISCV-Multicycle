`timescale 1ns / 1ps
`include "define.vh"

module RV32I_CPU (
    input         clk,
    input         reset,
    input         Ready,
    input  [31:0] instr_data,
    input  [31:0] bus_rdata,
    output [31:0] instr_addr,
    output        bus_wreq,
    output        bus_rreq,
    output [31:0] bus_addr,
    output [31:0] bus_wdata,
    output [ 2:0] o_funct3
);
    logic rf_we, alu_src, branch, pc_en;
    logic jal, jalr;
    logic [2:0] rfwd_src;
    logic [3:0] alu_control;

    control_unit U_CONTROL_UNIT (
        .clk(clk),
        .reset(reset),
        .funct7(instr_data[31:25]),
        .funct3(instr_data[14:12]),
        .opcode(instr_data[6:0]),
        .Ready(Ready),
        .pc_en(pc_en),
        .rf_we(rf_we),
        .alu_src(alu_src),
        .alu_control(alu_control),
        .rfwd_src(rfwd_src),
        .o_funct3(o_funct3),
        .dwe(bus_wreq),
        .dre(bus_rreq),
        .branch(branch),
        .jal(jal),
        .jalr(jalr)
    );
    RV32I_datapath U_DATAPATH (.*);

endmodule

module control_unit (
    input              clk,
    input              reset,
    input        [6:0] funct7,
    input        [2:0] funct3,
    input        [6:0] opcode,
    input              Ready,
    output logic       pc_en,
    output logic       rf_we,
    output logic       alu_src,
    output logic [3:0] alu_control,
    output logic [2:0] rfwd_src,
    output logic [2:0] o_funct3,
    output logic       dwe,
    output logic       dre,
    output logic       branch,
    output logic       jal,
    output logic       jalr
);
    logic fsm_rfwe, fsm_dwe, fsm_dre;
    logic op_rfwe, op_dwe, op_dre;

    typedef enum logic [3:0] {
        FETCH,
        DECODE,
        EXE_RIUJ,
        EXE_L,
        EXE_S,
        EXE_B,
        MEM_S,
        MEM_L,
        WB
    } state_e;
    state_e c_state, n_state;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            c_state <= FETCH;
        end else begin
            c_state <= n_state;
        end
    end

    always_comb begin
        n_state = c_state;
        fsm_rfwe   = 1'b0;
        fsm_dwe    = 1'b0;
        pc_en   = 1'b0;
        fsm_dre = 1'b0;
        case (c_state)
            FETCH: begin
                n_state = DECODE;
            end
            DECODE: begin
                case (opcode)
                    `B_TYPE: n_state = EXE_B;
                    `S_TYPE: n_state = EXE_S;
                    `IL_TYPE: n_state = EXE_L;
                    `R_TYPE, `I_TYPE, `UL_TYPE, `UA_TYPE, `J_TYPE, `JL_TYPE:n_state = EXE_RIUJ;
                endcase
            end
            EXE_RIUJ: begin
                n_state = WB;
            end
            EXE_L: begin
                n_state = MEM_L;
            end
            EXE_S: begin
                n_state = MEM_S;
            end
            EXE_B: begin
                n_state = FETCH;
                pc_en   = 1'b1;
            end
            MEM_S: begin
                fsm_dwe = 1'b1;
                if (Ready) begin
                n_state = FETCH;
                pc_en   = 1'b1;
                end else begin
                    n_state = MEM_S;
                end
            end
            MEM_L: begin
                fsm_dre = 1'b1;
                if (Ready) begin
                n_state = WB;
                end else begin
                    n_state = MEM_L;
                end
            end
            WB: begin
                n_state = FETCH;
                fsm_rfwe = 1'b1;
                pc_en = 1'b1; 
            end
            default: begin
                n_state = FETCH;
            end
        endcase
    end

    always_comb begin
        op_rfwe = 1'b0;
        alu_src = 1'b0;
        alu_control = 4'b0000;
        rfwd_src = 3'b000;
        o_funct3 = 3'b000;
        op_dwe = 1'b0;
        op_dre = 1'b0;
        branch = 1'b0;
        jal = 1'b0;
        jalr = 1'b0;
        case (opcode)
            `R_TYPE: begin
                op_rfwe = 1'b1;
                alu_src = 1'b0;
                alu_control = {funct7[5], funct3};
                rfwd_src = 3'b000;
                o_funct3 = 3'b000;
                op_dwe = 1'b0;
                branch = 1'b0;
                jal = 1'b0;
                jalr = 1'b0;
            end
            `S_TYPE: begin
                op_rfwe = 1'b0;
                alu_src = 1'b1;
                alu_control = 4'b000;
                rfwd_src = 3'b000;
                o_funct3 = funct3;
                op_dwe = 1'b1;
                branch = 1'b0;
                jal = 1'b0;
                jalr = 1'b0;
            end
            `IL_TYPE: begin
                op_rfwe = 1'b1;
                alu_src = 1'b1;
                alu_control = 4'b000;
                rfwd_src = 3'b001;
                o_funct3 = funct3;
                op_dwe = 1'b0;
                op_dre = 1'b1;
                branch = 1'b0;
                jal = 1'b0;
                jalr = 1'b0;
            end
            `I_TYPE: begin
                op_rfwe = 1'b1;
                alu_src = 1'b1;
                if (funct3 == 3'b001 || funct3 == 3'b101)
                    alu_control = {funct7[5], funct3};
                else alu_control = {1'b0, funct3};
                rfwd_src = 3'b000;
                o_funct3 = funct3;
                op_dwe = 1'b0;
                branch = 1'b0;
                jal = 1'b0;
                jalr = 1'b0;
            end
            `B_TYPE: begin
                op_rfwe = 1'b0;
                alu_src = 1'b0;
                alu_control = {1'b0, funct3};
                rfwd_src = 1'b0;
                o_funct3 = 3'b000;
                op_dwe = 1'b0;
                branch = 1'b1;
                jal = 1'b0;
                jalr = 1'b0;
            end

            `UL_TYPE: begin
                op_rfwe     = 1'b1;
                alu_src     = 1'b0;
                alu_control = 4'b000;
                rfwd_src    = 3'b010;
                o_funct3    = 3'b000;
                op_dwe      = 1'b0;
                branch      = 1'b0;
                jal         = 1'b0;
                jalr        = 1'b0;
            end
            `UA_TYPE: begin
                op_rfwe     = 1'b1;
                alu_src     = 1'b0;
                alu_control = 4'b000;
                rfwd_src    = 3'b011;
                o_funct3    = 3'b000;
                op_dwe      = 1'b0;
                branch      = 1'b0;
                jal         = 1'b0;
                jalr        = 1'b0;
            end
            `J_TYPE, `JL_TYPE: begin
                op_rfwe     = 1'b1;
                alu_src     = 1'b0;
                alu_control = 4'b000;
                rfwd_src    = 3'b100;
                o_funct3    = 3'b000;
                op_dwe      = 1'b0;
                branch      = 1'b0;
                jal         = 1'b1;
                if (opcode == `JL_TYPE) jalr = 1'b1;
                else jalr = 1'b0;
            end
        endcase
    end

    assign rf_we = fsm_rfwe & op_rfwe;
    assign dwe   = fsm_dwe & op_dwe;
    assign dre   = fsm_dre  & op_dre;
endmodule


