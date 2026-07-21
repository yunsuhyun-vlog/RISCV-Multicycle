`timescale 1ns / 1ps

module data_mem (
    input               clk,
    input               dwe,
    input        [ 2:0] i_funct3,
    input        [31:0] daddr,
    input        [31:0] dwdata,
    output logic [31:0] drdata
);

    logic [31:0] dmem [0:255];
    logic [31:0] rmem;
    assign rmem = dmem[daddr[31:2]];

//SIMULATION
//    initial begin
//        dmem[2] = 32'ha5010203; 
//    end

    always_ff @(posedge clk) begin
        if (dwe) begin
            case (i_funct3)
                3'b010: begin // SW 
                dmem[daddr[31:2]] <= dwdata;
                end
                3'b001: begin // SH                   
                if (daddr[1] == 1'b0) dmem[daddr[31:2]][15:0] <= dwdata[15:0];
                else dmem[daddr[31:2]][31:16] <= dwdata[15:0];
                end
                3'b000: begin // SB                     
                case (daddr[1:0])
                    2'b00: dmem[daddr[31:2]][7:0] <= dwdata[7:0];
                    2'b01: dmem[daddr[31:2]][15:8] <= dwdata[7:0];
                    2'b10: dmem[daddr[31:2]][23:16] <= dwdata[7:0];
                    2'b11: dmem[daddr[31:2]][31:24] <= dwdata[7:0];
                endcase
                end
            endcase
        end
    end

    always_comb begin
        drdata = 32'd0;
        case (i_funct3)
            3'b010: begin  //LW
            drdata = rmem;
            end
            3'b001: begin //LH
            if (daddr[1] == 1'b0) drdata = {{16{rmem[15]}}, rmem[15:0]};
            else drdata = {{16{rmem[31]}}, rmem[31:16]};
            end
            3'b101: begin //LHU     
            if (daddr[1] == 1'b0) drdata = {16'd0, rmem[15:0]};
            else drdata = {16'd0, rmem[31:16]};
            end
            3'b000: begin  //LB
            case (daddr[1:0])
                2'b00: drdata = {{24{rmem[7]}}, rmem[7:0]};
                2'b01: drdata = {{24{rmem[15]}}, rmem[15:8]};
                2'b10: drdata = {{24{rmem[23]}}, rmem[23:16]};
                2'b11: drdata = {{24{rmem[31]}}, rmem[31:24]};
            endcase
            end
            3'b100: begin //LBU 
            case (daddr[1:0])
                2'b00: drdata = {24'd0, rmem[7:0]};
                2'b01: drdata = {24'd0, rmem[15:8]};
                2'b10: drdata = {24'd0, rmem[23:16]};
                2'b11: drdata = {24'd0, rmem[31:24]};
            endcase
            end
            default: drdata = 0;
        endcase
    end
endmodule









