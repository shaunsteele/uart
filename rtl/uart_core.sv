// uart_core.sv

`default_nettype none

module uart_core # (
    parameter int   DATA_WIDTH = 8
)(
    input   var logic           clk,
    input   var logic           rst_n,

    // uart phy
    input   var logic           i_rx,
    output  var logic           o_tx,

    // transmitter control
    input   var logic                       i_wen,
    input   var logic   [DATA_WIDTH-1:0]    i_wdata,
    output  var logic                       o_wfull,

    // receiver control
    input   var logic                       i_ren,
    output  var logic   [DATA_WIDTH-1:0]    o_rdata,
    output  var logic                       o_rempty
);

logic bg_baud_tick;
baud_gen # (
    .DVSR_WIDTH ()
) u_BG (
    .clk        (clk),
    .rst_n      (rst_n),
    .i_divisor  (),
    .o_tick     (bg_baud_tick)
);

logic rx_done;
uart_rx # (
    .DATA_WIDTH     (),
    .SAMPLE_RATE    ()
) u_RX (
    .clk            (clk),
    .rst_n          (rst_n),
    .i_rx           (i_rx),
    .i_baud_tick    (bg_baud_tick),
    .o_done         (rx_done),
    .o_data         (o_rdata)
);

logic tx_done;
uart_tx # (
    .DATA_WIDTH     (),
    .SAMPLE_RATE    ()
) u_TX (
    .clk            (clk),
    .rst_n          (rst_n),
    .i_baud_tick    (bg_baud_tick),
    .i_start        (),
    .i_data         (i_wdata),
    .o_done         (tx_done),
    .o_tx           (o_tx)
);


endmodule
