`timescale 1ns / 1ps

module instruction_mem (
    input  logic        clk,
    input  logic [31:0] instr_addr,
    output logic [31:0] instr_data
);
    logic [31:0] rom[0:255];

    initial begin
        $readmemh("apb.mem", rom);
    end
    always_ff @(posedge clk) begin
        instr_data <= rom[instr_addr[11:2]];
    end
endmodule

