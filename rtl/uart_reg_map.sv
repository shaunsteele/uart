// uart_reg_map.sv

`default_nettype none

module uart_reg_map # (
    parameter int   IF_ADDR_WIDTH       = 32,
    parameter int   IF_DATA_WIDTH       = 32,
    parameter int   MM_OFFSET_WIDTH     = 2,
    parameter int   UART_DATA_WIDTH     = 8,
    parameter int   UART_DVSR_WIDTH     = 11
)(
    input   var logic                           clk,
    input   var logic                           rst_n,

    // memory map interface
    input   var logic                           i_we,
    input   var logic   [IF_ADDR_WIDTH-1:0]     i_waddr,
    input   var logic   [IF_DATA_WIDTH-1:0]     i_wdata,
    output  var logic                           o_waddr_invalid,

    input   var logic                           i_re,
    input   var logic   [IF_ADDR_WIDTH-1:0]     i_raddr,
    output  var logic   [IF_DATA_WIDTH-1:0]     o_rdata,
    output  var logic                           o_raddr_invalid,

    // uart interface
    output  var logic   [UART_DVSR_WIDTH-1:0]   o_divisor,
    output  var logic                           o_tx_we,
    output  var logic   [UART_DATA_WIDTH-1:0]   o_tx_wdata,
    input   var logic                           i_tx_wfull,
    output  var logic                           o_rx_re,
    input   var logic   [UART_DATA_WIDTH-1:0]   i_rx_rdata,
    input   var logic                           i_rx_rempty
);

// localparam bit [MM_OFFSET_WIDTH-1:0]    RdStat  = 'h0;
localparam bit [MM_OFFSET_WIDTH-1:0]    WrDvsr  = 'h1;
localparam bit [MM_OFFSET_WIDTH-1:0]    WrData  = 'h2;
localparam bit [MM_OFFSET_WIDTH-1:0]    WrRem   = 'h3;

// offset sizing
logic [MM_OFFSET_WIDTH-1:0] wr_offset;
assign wr_offset = i_waddr[MM_OFFSET_WIDTH-1:0];

// logic [1:0] rd_offset;
// assign rd_offset = i_raddr[MM_OFFSET_WIDTH-1:0];


// invalid address logic
always_comb begin
    o_waddr_invalid = 0;
    o_raddr_invalid = 0;

    if (i_we) begin
        o_waddr_invalid = i_waddr > ((2 ** MM_OFFSET_WIDTH) - 1);
    end

    if (i_re) begin
        o_raddr_invalid = i_raddr > ((2 ** MM_OFFSET_WIDTH) - 1);
    end
end


// Write Divisor Register
always_ff @(posedge clk) begin
    if (rst_n) begin
        o_divisor <= 'd651; // 9600 Baud at 16 Samples and 100 MHz
    end
    if (i_we && wr_offset == WrDvsr) begin
        o_divisor <= i_wdata[UART_DVSR_WIDTH-1:0];
    end
end

// Write Data Register
always_comb begin
    o_tx_we = i_we & (wr_offset == WrData);
end

// Write Remove Read Data
always_comb begin
    o_rx_re = i_we & (wr_offset == WrRem);
end

assign o_tx_wdata = i_wdata[7:0];


assign o_rdata = {
    {(IF_DATA_WIDTH-UART_DATA_WIDTH-2){1'b0}},
    i_rx_rempty,
    i_tx_wfull,
    i_rx_rdata
};

endmodule
