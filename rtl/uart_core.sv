// uart_core.sv

`default_nettype none

module uart_core # (
    parameter int   DATA_WIDTH = 8,
    parameter int   DVSR_WIDTH = 11,
    parameter int   SAMPLE_RATE = 16,
    parameter int   FIFO_ADDR_WIDTH = 2
)(
    input   var logic                       clk,
    input   var logic                       rst_n,

    // uart phy
    input   var logic                       i_rx,
    output  var logic                       o_tx,

    // baud rate divisor
    input   var logic   [DVSR_WIDTH-1:0]    i_divisor,

    // transmitter control
    input   var logic                       i_tx_we,
    input   var logic   [DATA_WIDTH-1:0]    i_tx_wdata,
    output  var logic                       o_tx_wfull,

    // receiver control
    input   var logic                       i_rx_re,
    output  var logic   [DATA_WIDTH-1:0]    o_rx_rdata,
    output  var logic                       o_rx_rempty
);


// baud rate generator
logic bg_baud_tick;
baud_gen # (
    .DVSR_WIDTH (DVSR_WIDTH)
) u_BG (
    .clk        (clk),
    .rst_n      (rst_n),
    .i_divisor  (i_divisor),
    .o_tick     (bg_baud_tick)
);


// receiver modules
logic                   rx_done;
logic [DATA_WIDTH-1:0]  rx_rdata;

fifo #(
    .DATA_WIDTH (8),
    .ADDR_WIDTH (FIFO_ADDR_WIDTH)
) u_RXBUF (
    .clk        (clk),
    .rst_n      (rst_n),
    .i_re       (i_rx_re),
    .o_rdata    (o_rx_rdata),
    .o_rempty   (o_rx_rempty),
    .i_we       (rx_done),
    .i_wdata    (rx_rdata),
    .o_wfull    ()
);

uart_rx # (
    .DATA_WIDTH     (DATA_WIDTH),
    .SAMPLE_RATE    (SAMPLE_RATE)
) u_RX (
    .clk            (clk),
    .rst_n          (rst_n),
    .i_rx           (i_rx),
    .i_baud_tick    (bg_baud_tick),
    .o_done         (rx_done),
    .o_data         (rx_rdata)
);


// transmitter modules
logic                   tx_done;
logic [DATA_WIDTH-1:0]  tx_wdata;
logic                   txbuf_empty;

fifo #(
    .DATA_WIDTH (8),
    .ADDR_WIDTH (FIFO_ADDR_WIDTH)
) u_TXBUF (
    .clk        (clk),
    .rst_n      (rst_n),
    .i_re       (tx_done),
    .o_rdata    (tx_wdata),
    .o_rempty   (txbuf_empty),
    .i_we       (i_tx_we),
    .i_wdata    (i_tx_wdata),
    .o_wfull    (o_tx_wfull)
);

uart_tx # (
    .DATA_WIDTH     (DATA_WIDTH),
    .SAMPLE_RATE    (SAMPLE_RATE)
) u_TX (
    .clk            (clk),
    .rst_n          (rst_n),
    .i_baud_tick    (bg_baud_tick),
    .i_start        (~txbuf_empty),
    .i_data         (tx_wdata),
    .o_done         (tx_done),
    .o_tx           (o_tx)
);


endmodule
