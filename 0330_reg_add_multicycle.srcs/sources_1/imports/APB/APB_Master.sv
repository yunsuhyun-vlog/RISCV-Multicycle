`timescale 1ns / 1ps `timescale 1ns / 1ps

module APB_Master (
    //BUS Global signal
    input  logic        PCLK,
    input  logic        PRESET,
    //APB Master - CPU
    input  logic [31:0] Addr,
    input  logic [31:0] Wdata,
    input  logic        WREQ,   //from CPU(dwe)
    input  logic        RREQ,   //from CPU(dre)
    output logic [31:0] Rdata,
    output logic        Ready,
    //APB Master - Slave(common)
    output logic [31:0] PADDR,     
    output logic [31:0] PWDATA,   
    output logic        PENABLE,
    output logic        PWRITE,
    //RAM
    output logic        PSEL0,
    input  logic [31:0] PRDATA0,
    input  logic        PREADY0,
    //GPO
    output logic        PSEL1,
    input  logic [31:0] PRDATA1,
    input  logic        PREADY1,
    //GPI
    output logic        PSEL2,
    input  logic [31:0] PRDATA2,
    input  logic        PREADY2,
    //GPIO
    output logic        PSEL3,
    input  logic [31:0] PRDATA3, 
    input  logic        PREADY3,
    //FND
    output logic        PSEL4,
    input  logic [31:0] PRDATA4,
    input  logic        PREADY4,
    //UART
    output logic        PSEL5,
    input  logic [31:0] PRDATA5,
    input  logic        PREADY5
);

    typedef enum logic [1:0] {
        IDLE,
        SETUP,
        ACCESS
    } apb_state;
    apb_state c_state, n_state;

    logic [31:0] PADDR_next, PWDATA_next;
    logic decode_en, PWRITE_next;

    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            c_state <= IDLE;
            PADDR   <= 32'd0;
            PWDATA  <= 32'd0;
            PWRITE  <= 32'd0;
        end else begin
            c_state <= n_state;
            PADDR   <= PADDR_next;
            PWDATA  <= PWDATA_next;
            PWRITE  <= PWRITE_next;
        end
    end

    logic transfer;
    assign transfer = WREQ | RREQ;

    always_comb begin
        n_state = c_state;
        decode_en = 1'b0;
        PENABLE = 1'b0;
        PADDR_next = PADDR;
        PWDATA_next = PWDATA;
        PWRITE_next = PWRITE;


        case (c_state)
            IDLE: begin
                decode_en = 0;
                PENABLE = 0;
                PADDR_next = 32'd0;
                PWDATA_next = 32'd0;
                PWRITE_next = 1'b0;
                if (transfer) begin
                    PADDR_next  = Addr;
                    PWDATA_next = Wdata;
                    if (WREQ) begin
                        PWRITE_next = 1'b1;
                    end else begin
                        PWRITE_next = 1'b0;
                    end
                    n_state = SETUP;
                end
            end
            SETUP: begin
                decode_en = 1'b1;
                PENABLE   = 1'b0;
                n_state   = ACCESS;
            end
            ACCESS: begin
                decode_en = 1;
                PENABLE   = 1'b1;
                if (Ready) begin
                    n_state = IDLE;
                end
            end
        endcase
    end


    Address_decoder U_ADDR_DEC (
        .*,
        .Addr(PADDR),
        .en(decode_en)
    );

    apb_mux U_MASTER_MUX (
        .*,
        .sel(PADDR)
    );
endmodule



module Address_decoder (
    input               en,
    input        [31:0] Addr,
    output logic        PSEL0,
    output logic        PSEL1,
    output logic        PSEL2,
    output logic        PSEL3,
    output logic        PSEL4,
    output logic        PSEL5
);
    always_comb begin
        PSEL0 = 1'b0;
        PSEL1 = 1'b0;
        PSEL2 = 1'b0;
        PSEL3 = 1'b0;
        PSEL4 = 1'b0;
        PSEL5 = 1'b0;
        if (en) begin
            case (Addr[31:28])
                4'h1: begin
                    if (Addr[27:12] == 16'h000_0) begin
                        PSEL0 = 1'b1;  //RAM
                    end
                end
                4'h2: begin
                    case (Addr[15:12])
                        4'h0: PSEL1 = 1'b1; //GPO
                        4'h1: PSEL2 = 1'b1; //GPI
                        4'h2: PSEL3 = 1'b1; //GPIO
                        4'h3: PSEL4 = 1'b1; //FND
                        4'h4: PSEL5 = 1'b1; //UART
                    endcase
                end
            endcase
        end
    end
endmodule

module apb_mux (
    input        [31:0] PRDATA0,
    input        [31:0] PRDATA1,
    input        [31:0] PRDATA2,
    input        [31:0] PRDATA3,
    input        [31:0] PRDATA4,
    input        [31:0] PRDATA5,
    input               PREADY0,
    input               PREADY1,
    input               PREADY2,
    input               PREADY3,
    input               PREADY4,
    input               PREADY5,
    input        [31:0] sel,
    output logic [31:0] Rdata,
    output logic        Ready
);
    always_comb begin
        Rdata = 32'h0000_0000;
        Ready = 1'b0;  
        case (sel[31:28])
            4'h1: begin
                if (sel[27:12] == 16'h000_0) begin
                    Rdata = PRDATA0;
                    Ready = PREADY0;        //RAM   
                end
            end
            4'h2: begin
                case (sel[15:12])
                    4'h0: begin
                        Rdata = PRDATA1;
                        Ready = PREADY1;    //GPO
                    end
                    4'h1: begin
                        Rdata = PRDATA2;
                        Ready = PREADY2;    //GPI
                    end
                    4'h2: begin
                        Rdata = PRDATA3;
                        Ready = PREADY3;    //GPIO
                    end
                    4'h3: begin
                        Rdata = PRDATA4;
                        Ready = PREADY4;    //FND
                    end
                    4'h4: begin
                        Rdata = PRDATA5;
                        Ready = PREADY5;   //UART
                    end
                endcase
            end
        endcase
    end
endmodule
