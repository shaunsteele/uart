// uart.sv

`default_nettype none

module uart # (
  parameter int BAUD = 9600,
  parameter int CLKF = 100000000,
  parameter int DLEN = 8,
  parameter int UART_ADDR = 0,
  parameter int ENDIAN = "little"
)(
  input var         clk,
  input var         rstn,

  output var logic  o_tx,
  input var         i_rx,

  axi4_lite_if.S     axi
);

// receiver clock sync
logic rxs;
cdc_sync u_CDC (
  .clk  (clk),
  .i_d  (i_rx),
  .o_q  (rxs)
);

// receiver
logic             rx_rvalid;
logic [DLEN-1:0]  rx_rdata;
uart_rx # (
  .BAUD (BAUD),
  .CLKF (CLKF),
  .DLEN (DLEN)
) u_RX (
  .clk      (clk),
  .rstn     (rstn),
  .i_rxs    (rxs),
  .o_rvalid (rx_rvalid),
  .o_rdata  (rx_rdata)
);

// receiver buffer
logic             ctl_rxb_ren;
logic [DLEN-1:0]  rxb_rdata;

logic rxb_overflow;
logic rxb_empty;
logic rxb_underflow;
fifo # (
  .ALEN   (2),
  .DLEN   (DLEN)
) u_RXB (
  .clk          (clk),
  .rstn         (rstn),
  .i_wen        (rx_rvalid),
  .i_wdata      (rx_rdata),
  .o_wfull      (),
  .o_woverflow  (rxb_overflow),
  .i_ren        (ctl_rxb_ren),
  .o_rdata      (rxb_rdata),
  .o_rempty     (rxb_empty),
  .o_runderflow (rxb_underflow)
);

// Controller
logic             ctl_txb_wen;
logic [DLEN-1:0]  ctl_txb_wdata;
logic             txb_overflow;

uart_controller # (
  .DLEN (DLEN),
  .UART_ADDR  (UART_ADDR),
  .ENDIAN     (ENDIAN)
) u_CTL (
  .clk              (clk),
  .rstn             (rstn),
  .i_rxb_overflow   (rxb_overflow),
  .o_rxb_ren        (ctl_rxb_ren),
  .i_rxb_rdata      (rxb_rdata),
  .i_rxb_empty      (rxb_empty),
  .i_rxb_underflow  (rxb_underflow),
  .o_txb_wen        (ctl_txb_wen),
  .o_txb_wdata      (ctl_txb_wdata),
  .i_txb_full       (txb_full),
  .i_txb_overflow   (txb_overflow),
  .axi              (axi)
);

// Transmit Buffer
logic             txb_full;
logic             tx_wready;
logic [DLEN-1:0]  txb_rdata;
logic             txb_empty;
logic             txb_underflow;
fifo # (
  .ALEN (128),
  .DLEN (DLEN)
) u_TXB (
  .clk          (clk),
  .rstn         (rstn),
  .i_wen        (ctl_txb_wen),
  .i_wdata      (ctl_txb_wdata),
  .o_wfull      (txb_full),
  .o_woverflow  (txb_overflow),
  .i_ren        (tx_wready & ~txb_empty),
  .o_rdata      (txb_rdata),
  .o_rempty     (txb_empty),
  .o_runderflow (txb_underflow)
);

// Transmitter
uart_tx # (
  .BAUD (BAUD),
  .CLKF (CLKF),
  .DLEN (DLEN)
) u_TX (
  .clk      (clk),
  .rstn     (rstn),
  .o_txs    (o_tx),
  .i_wvalid (~txb_empty),
  .o_wready (tx_wready),
  .i_wdata  (txb_rdata)
);

endmodule
