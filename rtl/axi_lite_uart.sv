// axi_lite_uart.sv

`default_nettype none

module axi_lite_uart # (
    parameter int   UART_DATA_WIDTH         = 8,
    parameter int   UART_DVSR_WIDTH         = 11,
    parameter int   UART_SAMPLE_RATE        = 16,
    parameter int   UART_FIFO_ADDR_WIDTH    = 2
)(
    axi_lite_if.slave   s_axi,

    input   var logic   i_uart_rx,
    output  var logic   o_uart_tx
);


module

uart_core # (
    .DATA_WIDTH         (UART_DATA_WIDTH),
    .DVSR_WIDTH         (UART_DVSR_WIDTH),
    .SAMPLE_RATE        (UART_SAMPLE_RATE),
    .FIFO_ADDR_WIDTH    (UART_FIFO_ADDR_WIDTH)
) u_UC (
    .clk            (s_axi.aclk),
    .rst_n          (s_axi.aresetn),
    .i_rx           (i_uart_rx),
    .o_tx           (o_uart_tx),
    .i_divisor      (),
    .i_tx_we        (),
    .i_tx_wdata     (),
    .o_tx_wfull     (),
    .i_rx_re        (),
    .o_rx_rdata     (),
    .o_rx_rempty    ()
);

endmodule
