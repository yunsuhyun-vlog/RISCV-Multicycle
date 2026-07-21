`timescale 1ns / 1ps

module APB_RAM (
    input               PCLK,
    input        [31:0] PADDR,
    input        [31:0] PWDATA,
    input               PENABLE,
    input               PWRITE,
    input               PSEL0,
    output logic [31:0] PRDATA0,
    output logic        PREADY0
);
    logic [31:0] bmem[0:1023];
    assign PREADY0 = (PENABLE & PSEL0) ? 1'b1 : 1'b0;

    always_ff @(posedge PCLK) begin
        if (PSEL0 & PENABLE & PWRITE) begin
            bmem[PADDR[11:2]] <= PWDATA;
        end
    end

    assign PRDATA0 = bmem[PADDR[11:2]];
endmodule

module APB_GPO (
    input  logic        PCLK,
    input  logic        PRESET,
    input  logic [31:0] PADDR,
    input  logic [31:0] PWDATA,
    input  logic        PWRITE,
    input  logic        PENABLE,
    input  logic        PSEL1,
    output logic [31:0] PRDATA1,
    output logic        PREADY1,
    output logic [15:0] GPO_OUT
);
    localparam [11:0] GPO_CTL_ADDR = 12'h0000;
    localparam [11:0] GPO_ODATA_ADDR = 12'h0004;
    logic [15:0] GPO_ctl_reg;
    logic [15:0] GPO_odata_reg;

    assign PREADY1 = (PSEL1 & PENABLE) ? 1'b1 : 1'b0;
    assign PRDATA1 = (PADDR[11:0]== GPO_CTL_ADDR) ? {16'h0000,GPO_ctl_reg }: 
           (PADDR[11:0]== GPO_ODATA_ADDR) ? {16'h0000,GPO_odata_reg} : 32'hxxxx_xxxx;

    always_ff @(posedge PCLK or posedge PRESET) begin
        if (PRESET) begin
            GPO_ctl_reg   <= 16'd0;
            GPO_odata_reg <= 16'd0;
        end else begin
            if (PSEL1 & PENABLE & PWRITE) begin
                case (PADDR[11:0])
                    GPO_CTL_ADDR:   GPO_ctl_reg <= PWDATA[15:0];
                    GPO_ODATA_ADDR: GPO_odata_reg <= PWDATA[15:0];
                endcase
            end
        end
    end

    genvar i;
    generate
        for (i = 0; i < 16; i++) begin
            assign GPO_OUT[i] = (GPO_ctl_reg[i]) ? GPO_odata_reg[i] : 1'bz;
        end
    endgenerate
endmodule

module APB_GPI (
    input  logic        PCLK,
    input  logic        PRESET,
    input  logic [31:0] PADDR,
    input  logic [31:0] PWDATA,
    input  logic        PWRITE,
    input  logic        PENABLE,
    input  logic        PSEL2,
    output logic [31:0] PRDATA2,
    output logic        PREADY2,
    input  logic [15:0] GPI_IN
);
    localparam [11:0] GPI_CTL_ADDR = 12'h0000;
    localparam [11:0] GPI_IDATA_ADDR = 12'h0004;
    logic [15:0] GPI_ctl_reg;
    logic [15:0] GPI_idata_reg;

    assign PREADY2 = (PSEL2 & PENABLE) ? 1'b1 : 1'b0;
    assign PRDATA2 = (PADDR[11:0] == GPI_CTL_ADDR)   ? {16'h0000, GPI_ctl_reg} : 
                     (PADDR[11:0] == GPI_IDATA_ADDR) ? {16'h0000, GPI_idata_reg} : 32'hxxxx_xxxx;

    always_ff @(posedge PCLK or posedge PRESET) begin
        if (PRESET) begin
            GPI_ctl_reg <= 16'd0;
        end else begin
            if (PSEL2 & PENABLE & PWRITE) begin
                if (PADDR[11:0] == GPI_CTL_ADDR) begin
                    GPI_ctl_reg <= PWDATA[15:0];
                end
            end
        end
    end

    genvar i;
    generate
        for (i = 0; i < 16; i++) begin
            assign GPI_idata_reg[i] = (GPI_ctl_reg[i]) ? GPI_IN[i] : 1'bz;
        end
    endgenerate
endmodule

module APB_GPIO (
    input  logic        PCLK,
    input  logic        PRESET,
    input  logic [31:0] PADDR,
    input  logic [31:0] PWDATA,
    input  logic        PWRITE,
    input  logic        PENABLE,
    input  logic        PSEL3,
    output logic [31:0] PRDATA3,
    output logic        PREADY3,
    inout  logic [15:0] GPIO
);
    localparam [11:0] GPIO_CTL_ADDR = 12'h0000;
    localparam [11:0] GPIO_ODATA_ADDR = 12'h0004;
    localparam [11:0] GPIO_IDATA_ADDR = 12'h0008;
    logic [15:0] GPIO_ctl_reg;
    logic [15:0] GPIO_odata_reg;
    logic [15:0] GPIO_idata_reg;

    assign PREADY3 = (PSEL3 & PENABLE) ? 1'b1 : 1'b0;
    assign PRDATA3 = (PADDR[11:0]== GPIO_CTL_ADDR) ? {16'h0000,GPIO_ctl_reg }: 
           (PADDR[11:0]== GPIO_ODATA_ADDR) ? {16'h0000,GPIO_odata_reg} : 
           (PADDR[11:0]== GPIO_IDATA_ADDR) ? {16'h0000,GPIO_idata_reg} :32'hxxxx_xxxx;

    always_ff @(posedge PCLK or posedge PRESET) begin
        if (PRESET) begin
            GPIO_ctl_reg   <= 16'd0;
            GPIO_odata_reg <= 16'd0;
        end else begin
            if (PSEL3 & PENABLE & PWRITE) begin
                case (PADDR[11:0])
                    GPIO_CTL_ADDR:   GPIO_ctl_reg <= PWDATA[15:0];
                    GPIO_ODATA_ADDR: GPIO_odata_reg <= PWDATA[15:0];
                endcase
            end
        end
    end

    gpio U_GPIO (
        .ctl(GPIO_ctl_reg),
        .o_data(GPIO_odata_reg),
        .i_data(GPIO_idata_reg),
        .GPIO(GPIO)
    );
endmodule

module gpio (
    input        [15:0] ctl,
    input        [15:0] o_data,
    output logic [15:0] i_data,
    inout  logic [15:0] GPIO
);
    genvar i;
    generate
        for (i = 0; i < 16; i++) begin
            assign GPIO[i]   = ctl[i] ? o_data[i] : 1'bz;
            assign i_data[i] = ~ctl[i] ? GPIO[i] : 1'bz;
        end
    endgenerate
endmodule

module APB_FND (
    input  logic        PCLK,
    input  logic        PRESET,
    input  logic [31:0] PADDR,
    input  logic [31:0] PWDATA,
    input  logic        PWRITE,
    input  logic        PENABLE,
    input  logic        PSEL4,       
    output logic [31:0] PRDATA4,
    output logic        PREADY4,
    output logic [3:0] fnd_digit,
    output logic [7:0] fnd_data
);
    localparam [11:0] FND_CTL_ADDR = 12'h0000;
    logic [15:0] fnd_reg;

    assign PREADY4 = (PSEL4 & PENABLE) ? 1'b1 : 1'b0;
    assign PRDATA4 = (PADDR[11:0] == FND_CTL_ADDR) ? {16'h0000, fnd_reg} :32'h0000_0000;
        
    always_ff @(posedge PCLK or posedge PRESET) begin
        if (PRESET) begin
            fnd_reg <= 16'd0; 
        end else begin
            if (PSEL4 & PENABLE & PWRITE) begin
                case (PADDR[11:0])
                FND_CTL_ADDR : fnd_reg <= PWDATA[15:0];
                endcase
            end
        end
    end

fnd_controller U_APB_FND(
    .sum(fnd_reg),
    .clk(PCLK),
    .reset(PRESET),
    .fnd_digit(fnd_digit),
    .fnd_data(fnd_data)
);
endmodule

module APB_UART (
    input  logic        PCLK,
    input  logic        PRESET,
    input  logic [31:0] PADDR,
    input  logic [31:0] PWDATA,
    input  logic        PENABLE,
    input  logic        PWRITE,
    input  logic        PSEL5,
    output logic [31:0] PRDATA5,
    output logic        PREADY5,

    output logic        uart_tx,
    input  logic        uart_rx
);


    localparam [11:0] UART_CTL_ADDR     = 12'h000;
    localparam [11:0] UART_BAUD_ADDR    = 12'h004;
    localparam [11:0] UART_STATUS_ADDR  = 12'h008; 
    localparam [11:0] UART_TX_DATA_ADDR = 12'h00c; 
    localparam [11:0] UART_RX_DATA_ADDR = 12'h010; 

    logic       uart_ctl_reg;      
    logic [1:0] uart_baud_reg;    
    logic [7:0] uart_tx_data_reg;  
    logic [7:0] w_rx_data;       
    logic       w_tx_busy;         
    logic       w_rx_done;         
    logic       w_b_tick;
    logic       rx_done_hold;

    assign PREADY5 = (PSEL5 & PENABLE) ? 1'b1 : 1'b0;
    assign PRDATA5 = (PADDR[11:0] == UART_CTL_ADDR)     ? {31'd0, uart_ctl_reg} :
                     (PADDR[11:0] == UART_BAUD_ADDR)    ? {30'd0, uart_baud_reg} :
                     (PADDR[11:0] == UART_STATUS_ADDR)  ? {30'd0, rx_done_hold, w_tx_busy} :
                     (PADDR[11:0] == UART_TX_DATA_ADDR) ? {24'd0, uart_tx_data_reg} :
                     (PADDR[11:0] == UART_RX_DATA_ADDR) ? {24'd0, w_rx_data} : 32'd0;

    always_ff @(posedge PCLK or posedge PRESET) begin
        if (PRESET) begin
            uart_ctl_reg     <= 1'b0;
            uart_baud_reg    <= 2'b00;
            uart_tx_data_reg <= 8'h0;
            rx_done_hold    <= 1'b0; 
        end else begin   
            if (PSEL5 & PENABLE & PWRITE) begin
                case (PADDR[11:0])
                    UART_CTL_ADDR:     uart_ctl_reg     <= PWDATA[0];
                    UART_BAUD_ADDR:    uart_baud_reg    <= PWDATA[1:0];
                    UART_TX_DATA_ADDR: uart_tx_data_reg <= PWDATA[7:0];
                endcase
            end 
            else if (w_tx_busy) begin
                uart_ctl_reg <= 1'b0;
            end           
            if (w_rx_done) begin
                rx_done_hold <= 1'b1; 
            end 
            else if  (PADDR[11:0] == UART_RX_DATA_ADDR) begin
                rx_done_hold <= 1'b0; 
            end
        end
    end

    b_tick BAUD_Gen (
        .clk(PCLK), 
        .rst(PRESET),
        .baud_sel(uart_baud_reg),
        .b_tick(w_b_tick)
    );
    uart_tx U_TX (
        .clk(PCLK), 
        .rst(PRESET),
        .tx_start(uart_ctl_reg),
        .b_tick(w_b_tick),
        .tx_data(uart_tx_data_reg),
        .tx_busy(w_tx_busy),
        .tx_done(),
        .uart_tx(uart_tx)
    );
    uart_rx U_RX (
        .clk(PCLK), 
        .rst(PRESET),
        .rx(uart_rx),
        .b_tick(w_b_tick),
        .rx_data(w_rx_data),
        .rx_done(w_rx_done)
    );
endmodule
