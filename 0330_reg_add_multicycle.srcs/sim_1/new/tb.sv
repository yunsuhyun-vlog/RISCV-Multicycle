`timescale 1ns / 1ps

module tb_rv32i ();

    logic clk, rst;
    logic [7:0] gpi, gpo;
    wire  [15:0] gpio;
    logic [ 3:0] fnd_digit;
    logic [ 7:0] fnd_data;
    logic uart_rx, uart_tx;

    RV32I_MCU dut (.*);

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
    //     gpi = 8'h00;
    //     //gpo: 8'h00;
    //     // gpio = 16'h0000;

    //     @(negedge clk);
    //     @(negedge clk);
        rst = 0;
    //     gpi = 8'haa;
    //     //gpio 
    //     repeat (2000) @(negedge clk);
    //     $stop;
    end
endmodule
