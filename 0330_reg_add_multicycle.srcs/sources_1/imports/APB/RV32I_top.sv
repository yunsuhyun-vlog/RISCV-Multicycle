`timescale 1ns / 1ps

module RV32I_MCU (
    input               clk,
    input               reset,
    input        [ 7:0] GPI_IN,
    output logic [ 7:0] GPO_OUT,
    output logic [ 3:0] fnd_digit,
    output logic [ 7:0] fnd_data,
    inout  logic [15:0] GPIO,
    output logic        uart_tx,
    input  logic        uart_rx
);
    logic branch;
    logic bus_wreq, bus_rreq;
    logic Ready;
    logic [2:0] o_funct3;
    logic [31:0] instr_addr, instr_data;
    logic [31:0] bus_wdata, bus_addr, bus_rdata;
    logic [31:0] PADDR, PWDATA;
    logic PENABLE, PWRITE;
    logic PSEL0, PSEL1, PSEL2, PSEL3, PSEL4, PSEL5;
    logic PREADY0, PREADY1, PREADY2, PREADY3, PREADY4, PREADY5;
    logic [31:0] PRDATA0, PRDATA1, PRDATA2, PRDATA3, PRDATA4, PRDATA5;
    instruction_mem U_INSTRUCTION_MEM (.*);
    RV32I_CPU U_RV32 (
        .*,
        .o_funct3(o_funct3)
    );
    APB_Master U_APB_MASTER (
        .PCLK  (clk),
        .PRESET(reset),
        .Addr  (bus_addr),
        .Wdata (bus_wdata),
        .WREQ  (bus_wreq),
        .RREQ  (bus_rreq),
        .Rdata (bus_rdata),
        .Ready (Ready),
        .*
    );
    APB_RAM U_S_RAM (
        .PCLK(clk),
        .*
    );
    APB_GPI U_S_GPI (
        .PCLK  (clk),
        .PRESET(reset),
        .*
    );
    APB_GPO U_S_GPO (
        .PCLK  (clk),
        .PRESET(reset),
        .*
    );
    APB_GPIO U_S_GPIO (
        .PCLK  (clk),
        .PRESET(reset),
        .*
    );
    APB_FND U_S_FND (
        .PCLK  (clk),
        .PRESET(reset),
        .*
    );
    APB_UART U_S_UART (
        .PCLK  (clk),
        .PRESET(reset),
        .*
    );



    //    data_mem U_DATA_MEM (     
    //        .*,
    //        .i_funct3(o_funct3)
    //    );
endmodule

