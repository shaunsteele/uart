// uart_controller.sv

`default_nettype none

module uart_controller # (
  parameter int DLEN = 8,
  parameter UART_ADDR = 32'h0,
  parameter string ENDIAN = "big"
)(
  input var                     clk,
  input var                     rstn,

  input var                     i_rxb_overflow,
  output var logic              o_rxb_ren,
  input var         [DLEN-1:0]  i_rxb_rdata,
  input var                     i_rxb_empty,
  input var                     i_rxb_underflow,

  output var logic              o_txb_wen,
  output var logic  [DLEN-1:0]  o_txb_wdata,
  input var                     i_txb_full,
  input var                     i_txb_overflow,

  axi_lite_if.S   axi
);

initial begin
  assert (DLEN % 8 == 0);
end

/* Write Controller */
// transmit buffer enable
logic txb_load;
logic aw_en;
logic w_en;
always_comb begin
  txb_load = aw_en & w_en;
end

// write address channel ready
always_comb begin
  awready = ~aw_en | ~|txb_shift | ~i_txb_full;
end

// write data channel ready
always_comb begin
  wready = ~w_en | ~|txb_shift | ~i_txb_full;
end

// write address buffer
logic                 awvalid;
logic [axi.ALEN-1:0]  awaddr;
elastic_buffer # (.DLEN(axi.ALEN)) u_AWB (
  .clk      (clk),
  .rstn     (rstn),
  .i_valid  (axi.awvalid),
  .o_ready  (axi.awready),
  .i_data   (axi.awaddr),
  .o_valid  (awvalid),
  .i_ready  (awready),
  .o_data   (awaddr)
);

// write address enable
logic valid_awaddr;
always_comb begin
  valid_awaddr = awaddr == UART_ADDR;
end

always_ff @(posedge clk) begin
  if (!rstn) begin
    aw_en <= 0;
  end else begin
    if (aw_en) begin
      aw_en <= ~txb_load;
    end else begin
      aw_en <= awvalid & ~i_txb_full & valid_awaddr;
    end
  end
end

// write data buffer
logic                 wvalid;
logic [axi.DLEN-1:0]  wdata;
logic [axi.SLEN-1:0]  wstrb;
elastic_buffer # (.DLEN(axi.DLEN + axi.SLEN)) u_AWB (
  .clk      (clk),
  .rstn     (rstn),
  .i_valid  (axi.wvalid),
  .o_ready  (axi.wready),
  .i_data   ({axi.wdata, axi.wstrb}),
  .o_valid  (wvalid),
  .i_ready  (wready),
  .o_data   ({wdata, wstrb})
);

// write data enable 
always_ff @(posedge clk) begin
  if (!rstn) begin
    w_en <= 0;
  end else begin
    if (w_en) begin
      w_en <= ~txb_load;
    end else begin
      w_en <= wvalid & ~i_txb_full;
    end
  end
end

// txb enable shifter counter
logic [axi.SLEN-1:0]  txb_shift;
always_ff @(posedge clk) begin
  if (!rstn) begin
    txb_shift <= 0;
  end else begin
    if (txb_load) begin
      txb_shift <= wstrb;
    end else if (i_txb_full) begin
      txb_shift <= txb_shift;
    end else begin
      txb_shift <= {1'b0, txb_shift[axi.SLEN-1:1]};
    end
  end
end

always_comb begin
  o_txb_wen = |txb_shift & ~i_txb_full;
end

// txb data shifter
logic [axi.DLEN-1:0]  txb_data;
always_ff @(posedge clk) begin
  if (txb_en) begin
    txb_data <= wdata;
  end else begin
    if (ENDIAN == "big") begin
      txb_data <= {txb_data[axi.DLEN-DLEN-1:0], {(DLEN){1'b0}}};
    end else if (ENDIAN == "little") begin
      txb_data <= {{(DLEN){1'b0}}, txb_data[axi.DLEN-1:DLEN]};
    end
  end
end

always_comb begin
  if (ENDIAN == "big") begin
    o_txb_wdata = txb_data[axi.DLEN-1:axi.DLEN-DLEN];
  end else if (ENDIAN == "little") begin
    o_txb_wdata = txb_data[DLEN-1:0];
  end else begin
    o_txb_wdata = 'hx;
    $error("Illegal ENDIAN parameter, choose \"big\" or \"little\".");
  end
end

// detect illegal wstrb values
logic tx_err;
always_ff @(posedge clk) begin
  if (!rstn) begin
    tx_err <= 0;
  end else begin
    if (tx_err) begin
      tx_err <= axi.bvalid & axi.bready;
    end else begin
      if (txb_en) begin
        tx_err <= wstrb == 'h0 || wstrb == 'h1 || wstrb == 'h3 ||
          wstrb == 'h7 || wstrb == 'hF || wstrb == 'h1F || wstrb == 'h3F ||
          wstrb == 'h7F || wstrb == 'hFF;
      end else begin
        tx_err <= tx_err;
      end
    end
  end
end

// write response channel
always_ff @(posedge clk) begin
  if (!rstn) begin
    axi.bvalid <= 0;
  end else begin
    if (axi.bvalid) begin
      axi.bvalid <= ~axi.bready | tx_en;
    end else begin
      axi.bvalid <= tx_en;
    end
  end
end

assign axi.bresp = {tx_err, 1'b0}; // OKAY or SLVERR


/* Read Controller */
// read address buffer
logic                 arvalid;
logic                 arready;
logic [axi.ALEN-1:0]  araddr;
elastic_buffer # (.DLEN(axi.ALEN)) u_ARB (
  .clk      (clk),
  .rstn     (rstn),
  .i_valid  (axi.arvalid),
  .o_ready  (axi.arready),
  .i_data   (axi.araddr),
  .o_valid  (arvalid),
  .i_ready  (arready),
  .o_data   (araddr)
);

// rxb read
logic valid_araddr;
always_comb begin
  valid_araddr = (araddr == UART_ADDR) | (araddr == UART_ADDR + 1);
end

always_comb begin
  o_rxb_ren = arvalid & (araddr == UART_ADDR) & ~i_rxb_rempty;
end

logic rxb_valid;
always_ff @(posedge clk) begin
  if (!rstn) begin
    rxb_valid <= 0;
  end else begin
    rxb_valid <= o_rxb_ren;
  end
end

logic [axi.DLEN-1:0]  status;
assign status = {
  {(axi.DLEN-5){1'b0}},
  i_rxb_overflow,
  i_rxb_underflow,
  i_rxb_empty,
  i_txb_overflow,
  i_txb_full
};

always_ff @(posedge clk) begin
  if (rxb_valid && axi.rready) begin
    axi.rdata <= i_rxb_rdata;
  end else if (rxb_valid && !axi.rready) begin
    axi.rdata <= axi.rdata;
  end else begin
    axi.rdata <= status;
  end
end

logic ar_en;
always_comb begin
  ar_en = arvalid & arready;
end

logic rxb_rvalid;
always_ff @(posedge clk) begin
  if (!rstn) begin
    rxb_rvalid <= 0;
  end else begin
    rxb_rvalid <= arvalid & (araddr == UART_ADDR);
  end
end

always_ff @(posedge clk) begin
  if (!rstn) begin
    axi.rvalid <= 0;
  end else begin
    if (axi.rvalid) begin
      axi.rvalid <= ~axi.ready | (ar_en & (araddr == UART_ADDR + 1));
    end
    axi.rvalid <= rxb_rvalid | (ar_en & (araddr == UART_ADDR + 1));
  end
end

always_comb begin
  axi.arready = ~rxb_rvalid;
end




endmodule
