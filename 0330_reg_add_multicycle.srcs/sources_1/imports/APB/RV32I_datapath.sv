`timescale 1ns / 1ps
`include "define.vh"

module RV32I_datapath (
    input               clk,
    input               reset,
    input               pc_en,
    input        [31:0] instr_data,
    input               rf_we,
    input               branch,
    input               alu_src,
    input               jal,
    input               jalr,
    input        [ 3:0] alu_control,
    input        [31:0] bus_rdata,
    input        [ 2:0] rfwd_src,
    output       [31:0] instr_addr,
    output logic [31:0] bus_addr,
    output logic [31:0] bus_wdata
);
    logic [31:0] alu_result, imm_data, alusrc2_data, rf_wb_data;
    logic [31:0] pc_4_out, pc_imm_out;
    logic btaken;
    logic [31:0]
        i_dec_rs1,
        o_dec_rs1,
        i_dec_rs2,
        o_dec_rs2,
        i_dec_imm,
        o_dec_imm,
        o_exe_rs2,
        o_exe_alu_result,
        o_mem_drdata,
        o_exe_pc_imm,
        o_exe_pc_4,
        o_exe_lui_data;

    assign bus_addr  = o_exe_alu_result;
    assign bus_wdata = o_exe_rs2;

    program_counter U_PROGRAM_COUNTER (
        .clk(clk),
        .reset(reset),
        .pc_en(pc_en),
        .btaken(btaken),
        .branch(branch),
        .imm_data(o_dec_imm),
        .jal(jal),
        .jalr(jalr),
        .rd1(o_dec_rs1),
        .pc_4_out(pc_4_out),
        .pc_imm_out(pc_imm_out),
        .program_counter(instr_addr)
    );

    //decode
    register_file U_REG_FILE (
        .clk(clk),
        .reset(reset),
        .RA1(instr_data[19:15]),
        .RA2(instr_data[24:20]),
        .WA(instr_data[11:7]),
        .Wdata(rf_wb_data),
        .rf_we(rf_we),
        .RD1(i_dec_rs1),
        .RD2(i_dec_rs2)
    );
    imm_extender U_EXTENDER (
        .instr_data(instr_data),
        .imm_data  (imm_data)
    );

    register U_DEC_REG_RS1 (
        .clk(clk),
        .reset(reset),
        .data_in(i_dec_rs1),
        .data_out(o_dec_rs1)
    );
    register U_DEC_REG_RS2 (
        .clk(clk),
        .reset(reset),
        .data_in(i_dec_rs2),
        .data_out(o_dec_rs2)
    );
    register U_DEC_IMM_EXT (
        .clk(clk),
        .reset(reset),
        .data_in(imm_data),
        .data_out(o_dec_imm)
    );

    //execute
    mux2X1 U_MUX_ALUSRC_RS2 (
        .in0(o_dec_rs2),
        .in1(o_dec_imm),
        .mux_sel(alu_src),
        .out_mux(alusrc2_data)
    );
    alu U_ALU (
        .rd1(o_dec_rs1),
        .rd2(alusrc2_data),
        .alu_control(alu_control),
        .alu_result(alu_result),
        .btaken(btaken)
    );

    //execute
    register U_EXE_REG_RS2 (
        .clk(clk),
        .reset(reset),
        .data_in(o_dec_rs2),  //from alu result
        .data_out(o_exe_rs2)  //to Data MEM_Wdata
    );
    register U_EXE_ALU_RESULT (
        .clk(clk),
        .reset(reset),
        .data_in(alu_result),
        .data_out(o_exe_alu_result)  //to daddr & mux in 0
    );



    //MEM to Writeback
    register U_MEM_REG_DRDATA (
        .clk(clk),
        .reset(reset),
        .data_in(bus_rdata),
        .data_out(o_mem_drdata) // mux in1
    );
    register U_EXE_LUI_DATA (
        .clk(clk), 
        .reset(reset),
        .data_in(o_dec_imm),    
        .data_out(o_exe_lui_data) //MUX in2
    );
    register U_EXE_PC_IMM (
        .clk(clk), 
        .reset(reset),
        .data_in(pc_imm_out),
        .data_out(o_exe_pc_imm) //  MUX in3
    );
    register U_EXE_PC_4 (
        .clk(clk), 
        .reset(reset),
        .data_in(pc_4_out),
        .data_out(o_exe_pc_4) // MUX in4
    );


    //to register file
    mux5x1 U_WRITE_BACK (
        .in0(o_exe_alu_result),
        .in1(o_mem_drdata),
        .in2(o_exe_lui_data),
        .in3(o_exe_pc_imm),
        .in4(o_exe_pc_4),
        .mux_sel(rfwd_src),
        .out_mux(rf_wb_data)
    );




endmodule

module mux2X1 (
    input        [31:0] in0,
    input        [31:0] in1,
    input               mux_sel,
    output logic [31:0] out_mux
);

    assign out_mux = (mux_sel) ? in1 : in0;
endmodule

module mux5x1 (
    input        [31:0] in0,
    input        [31:0] in1,
    input        [31:0] in2,
    input        [31:0] in3,
    input        [31:0] in4,
    input        [ 2:0] mux_sel,
    output logic [31:0] out_mux
);
    always_comb begin
        case (mux_sel)
            3'b000:  out_mux = in0;
            3'b001:  out_mux = in1;
            3'b010:  out_mux = in2;
            3'b011:  out_mux = in3;
            3'b100:  out_mux = in4;
            default: out_mux = 32'hxxx;
        endcase
    end
endmodule


module imm_extender (
    input        [31:0] instr_data,
    output logic [31:0] imm_data
);
    always_comb begin
        imm_data = 32'd0;
        case (instr_data[6:0])
            `S_TYPE: begin
                imm_data = {
                    {20{instr_data[31]}}, instr_data[31:25], instr_data[11:7]
                };
            end


            `IL_TYPE, `I_TYPE, `JL_TYPE: begin
                imm_data = {{20{instr_data[31]}}, instr_data[31:20]};
            end

            `B_TYPE: begin
                imm_data = {
                    {20{instr_data[31]}},
                    instr_data[7],
                    instr_data[30:25],
                    instr_data[11:8],
                    1'b0
                };
            end

            `UL_TYPE, `UA_TYPE: begin
                imm_data = {instr_data[31:12], 12'b0000_0000_0000};
            end

            `J_TYPE: begin
                imm_data = {
                    {12{instr_data[31]}},
                    instr_data[19:12],
                    instr_data[20],
                    instr_data[30:21],
                    1'b0
                };
            end
        endcase
    end
endmodule

module register_file (
    input         clk,
    input         reset,
    input  [ 4:0] RA1,
    input  [ 4:0] RA2,
    input  [ 4:0] WA,
    input  [31:0] Wdata,
    input         rf_we,
    output [31:0] RD1,
    output [31:0] RD2
);
    logic [31:0] register_file[1:31];


    initial begin
        for (int i = 1; i < 32; i++) begin
            register_file[i] = i;
        end
    end

    always_ff @(posedge clk) begin

        if ((!reset) & rf_we) begin
            register_file[WA] <= Wdata;
        end
    end

    assign RD1 = (RA1 != 0) ? register_file[RA1] : 0;
    assign RD2 = (RA2 != 0) ? register_file[RA2] : 0;
endmodule

module alu (
    input        [31:0] rd1,
    input        [31:0] rd2,
    input        [ 3:0] alu_control,
    output logic [31:0] alu_result,
    output logic        btaken
);
    always_comb begin  //R-TYPE compare
        alu_result = 0;
        case (alu_control)
            `ADD:  alu_result = rd1 + rd2;
            `SUB:  alu_result = rd1 - rd2;
            `SLL:  alu_result = rd1 << rd2[4:0];
            `SLT:  alu_result = ($signed(rd1) < $signed(rd2)) ? 1 : 0;
            `SLTU: alu_result = (rd1 < rd2) ? 1 : 0;
            `XOR:  alu_result = rd1 ^ rd2;
            `SRL:  alu_result = rd1 >> rd2[4:0];
            `SRA:  alu_result = $signed(rd1) >>> rd2;
            `OR:   alu_result = rd1 | rd2;
            `AND:  alu_result = rd1 & rd2;
        endcase
    end



    always_comb begin  //B-TYPE compare
        btaken = 0;
        case (alu_control)
            `BEQ: begin
                if (rd1 == rd2) btaken = 1;
                else btaken = 0;
            end
            `BNE: begin
                if (rd1 != rd2) btaken = 1;
                else btaken = 0;
            end
            `BLT: begin
                if ($signed(rd1) < $signed(rd2)) btaken = 1;
                else btaken = 0;
            end
            `BGE: begin
                if ($signed(rd1) >= $signed(rd2)) btaken = 1;
                else btaken = 0;
            end
            `BLTU: begin
                if (rd1 < rd2) btaken = 1;
                else btaken = 0;
            end
            `BGEU: begin
                if (rd1 >= rd2) btaken = 1;
                else btaken = 0;
            end
        endcase
    end
endmodule


module program_counter (
    input               clk,
    input               reset,
    input               pc_en,
    input               btaken,
    input               branch,
    input               jal,
    input               jalr,
    input        [31:0] imm_data,
    input        [31:0] rd1,
    output logic [31:0] pc_4_out,
    output logic [31:0] pc_imm_out,
    output logic [31:0] program_counter
);
    logic [31:0] pc_next;
    logic [31:0] jalr_mux_out;
    logic [31:0] o_exe_PCNEXT;

    pc_alu U_PC_ALU_4 (
        .a(32'd4),
        .b(program_counter),
        .pc_alu_out(pc_4_out)
    );
    pc_alu U_PC_ALU_imm (
        .a(imm_data),
        .b(jalr_mux_out),
        .pc_alu_out(pc_imm_out)
    );

    mux2X1 jalr_mux (
        .in0(program_counter),
        .in1(rd1),
        .mux_sel(jalr),
        .out_mux(jalr_mux_out)
    );
    mux2X1 imm_4_mux (
        .in0(pc_4_out),
        .in1(pc_imm_out),
        .mux_sel((btaken & branch) | jal),
        .out_mux(pc_next)
    );


    //fetch

    register_en U_PC_REG (
        .clk(clk),
        .reset(reset),
        .en(pc_en),
        .data_in(pc_next),
        .data_out(program_counter)
    );

endmodule



module pc_alu (
    input  [31:0] a,
    input  [31:0] b,
    output [31:0] pc_alu_out
);
    assign pc_alu_out = a + b;

endmodule

module register (
    input               clk,
    input               reset,
    input  logic [31:0] data_in,
    output       [31:0] data_out
);
    logic [31:0] register;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            register <= 0;
        end else begin
            register <= data_in;
        end
    end

    assign data_out = register;
endmodule


module register_en (
    input               clk,
    input               reset,
    input               en,
    input  logic [31:0] data_in,
    output       [31:0] data_out
);
    logic [31:0] register;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            register <= 0;
        end else begin
            if (en) register <= data_in;
        end
    end

    assign data_out = register;
endmodule



