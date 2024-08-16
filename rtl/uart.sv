// uart.sv

`default_nettype none

module uart # (
  parameter int BAUD = 9600,
  parameter int CLKF = 100000000,
  parameter int DLEN = 8,
  parameter int UART_ADDR = 0,
  parameter int RXB_ALEN = 2,
  parameter int TXB_ALEN = 2
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
logic             rx_tvalid;
logic             rxb_tready;
logic [DLEN-1:0]  rx_tdata;
uart_rx # (
  .BAUD (BAUD),
  .CLKF (CLKF),
  .DLEN (DLEN)
) u_RX (
  .clk      (clk),
  .rstn     (rstn),
  .i_rxs    (rxs),
  .o_tvalid (rx_tvalid),
  .i_tready (rxb_tready),
  .o_tdata  (rx_tdata)
);

// receiver buffer
logic             rxb_tvalid;
logic             ctl_rxb_tready;
logic [DLEN-1:0]  rxb_tdata;

fifo # (
  .ALEN   (RXB_ALEN),
  .DLEN   (DLEN)
) u_RXB (
  .clk          (clk),
  .rstn         (rstn),
  .i_wr_tvalid  (rx_tvalid),
  .o_wr_tready  (rxb_tready),
  .i_wr_tdata   (rx_tdata),
  .o_rd_tvalid  (rxb_tvalid),
  .i_rd_tready  (ctl_rxb_tready),
  .o_rd_tdata   (rxb_tdata)
);

// Controller
logic             ctl_txb_tvalid;
logic             txb_tready;
logic [DLEN-1:0]  ctl_txb_tdata;

uart_controller # (
  .AXI_ALEN   (axi.ALEN),
  .AXI_DLEN   (axi.DLEN),
  .AXI_SLEN   (axi.SLEN),
  .UART_DLEN  (DLEN),
  .UART_ADDR  (UART_ADDR)
) u_CTL (
  .clk              (clk),
  .rstn             (rstn),
  .i_axi_awvalid    (axi.awvalid),
  .o_axi_awready    (axi.awready),
  .i_axi_awaddr     (axi.awaddr),
  .i_axi_wvalid     (axi.wvalid),
  .o_axi_wready     (axi.wready),
  .i_axi_wdata      (axi.wdata),
  .i_axi_wstrb      (axi.wstrb),
  .o_axi_bvalid     (axi.bvalid),
  .i_axi_bready     (axi.bready),
  .o_axi_bresp      (axi.bresp),
  .i_axi_arvalid    (axi.arvalid),
  .o_axi_arready    (axi.arready),
  .i_axi_araddr     (axi.araddr),
  .o_axi_rvalid     (axi.rvalid),
  .i_axi_rready     (axi.rready),
  .o_axi_rdata      (axi.rdata),
  .o_axi_rresp      (axi.rresp),
  .o_txb_tvalid     (ctl_txb_tvalid),
  .i_txb_tready     (txb_tready),
  .o_txb_tdata      (ctl_txb_tdata),
  .i_rxb_tvalid     (rxb_tvalid),
  .o_rxb_tready     (ctl_rxb_tready),
  .i_rxb_tdata      (rxb_tdata)
);

// Transmit Buffer
logic             txb_tvalid;
logic             tx_tready;
logic [DLEN-1:0]  txb_tdata;

fifo # (
  .ALEN (TXB_ALEN),
  .DLEN (DLEN)
) u_TXB (
  .clk          (clk),
  .rstn         (rstn),
  .i_wr_tvalid  (ctl_txb_tvalid),
  .o_wr_tready  (txb_tready),
  .i_wr_tdata   (ctl_txb_tdata),
  .o_rd_tvalid  (txb_tvalid),
  .i_rd_tready  (tx_tready),
  .o_rd_tdata   (txb_tdata)
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
  .i_tvalid (txb_tvalid),
  .o_tready (tx_tready),
  .i_tdata  (txb_tdata)
);

endmodule
