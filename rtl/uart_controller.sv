// uart_controller.sv

`default_nettype none

module uart_controller # (
  parameter int AXI_ALEN = 32,
  parameter int AXI_DLEN = 32,
  parameter int AXI_SLEN = AXI_DLEN / 8,
  parameter int UART_DLEN = 8,
  parameter int UART_ADDR = 32'h0
)(
  input var                     clk,
  input var                     rstn,

  // axi write address channel
  input var                         i_axi_awvalid,
  output var logic                  o_axi_awready,
  input var         [AXI_ALEN-1:0]  i_axi_awaddr,

  // axi write data channel
  input var                         i_axi_wvalid,
  output var logic                  o_axi_wready,
  input var         [AXI_DLEN-1:0]  i_axi_wdata,
  input var         [AXI_SLEN-1:0]  i_axi_wstrb,

  // axi write response channel
  output var logic                  o_axi_bvalid,
  input var                         i_axi_bready,
  output var logic  [1:0]           o_axi_bresp,
  
  // axi read address channel
  input var                         i_axi_arvalid,
  output var logic                  o_axi_arready,
  input var         [AXI_ALEN-1:0]  i_axi_araddr,

  // axi read data channel
  output var logic                  o_axi_rvalid,
  input var                         i_axi_rready,
  output var logic  [AXI_DLEN-1:0]  o_axi_rdata,
  output var logic  [1:0]           o_axi_rresp,
  
  // tx buffer interface
  output var logic                  o_txb_tvalid,
  input var                         i_txb_tready,
  output var logic  [UART_DLEN-1:0] o_txb_tdata,
  // output var logic                  o_txb_wen,
  // output var logic  [UART_DLEN-1:0] o_txb_wdata,
  input var                         i_txb_full,
  input var                         i_txb_overflow,

  // rx buffer interface
  input var                         i_rxb_tvalid,
  output var logic                  o_rxb_tready,
  input var         [UART_DLEN-1:0] i_txb_tdata,
  // output var logic                  o_rxb_ren,
  // input var         [UART_DLEN-1:0] i_rxb_rdata,
  input var                         i_rxb_empty,
  input var                         i_rxb_overflow,
  input var                         i_rxb_underflow
);

/* Write Controller */
// transmit buffer enable
logic txb_load;
logic aw_en;
logic w_en;
always_comb begin
  txb_load = aw_en & w_en;
end

// write address channel ready
logic [axi.SLEN-1:0]  txb_shift;
logic awready;
always_comb begin
  o_axi_awready = ~aw_en | ~|txb_shift | ~i_txb_full;
end

// write data channel ready
always_comb begin
  o_axi_wready = ~w_en | ~|txb_shift | ~i_txb_full;
end

// write address enable
logic valid_awaddr;
always_comb begin
  valid_awaddr = i_axi_awaddr == UART_ADDR;
end

always_ff @(posedge clk) begin
  if (!rstn) begin
    aw_en <= 0;
  end else begin
    if (aw_en) begin
      aw_en <= ~txb_load;
    end else begin
      aw_en <= i_axi_awvalid & ~i_txb_full & valid_awaddr;
    end
  end
end

// write data enable 
always_ff @(posedge clk) begin
  if (!rstn) begin
    w_en <= 0;
  end else begin
    if (w_en) begin
      w_en <= ~txb_load;
    end else begin
      w_en <= i_axi_wvalid & ~i_txb_full;
    end
  end
end

// txb enable shifter counter
//// todo: check strobe
always_ff @(posedge clk) begin
  if (!rstn) begin
    txb_shift <= 0;
  end else begin
    if (txb_load) begin
      txb_shift <= i_axi_wstrb;
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
always_ff @(posedge clk) begin
  
end
//// todo: check if needed
// logic [UART_DLEN-1:0]  txb_data;
// always_ff @(posedge clk) begin
//   if (o_txb_wen) begin
//     txb_data <= i_axi_wdata;
//   end else begin
//     txb_data <= {txb_data[UART_DLEN-1:0], {(DLEN){1'b0}}};
//   end
// end

// always_comb begin
//   o_txb_wdata = txb_data[UART_DLEN-1:0];
// end

// detect illegal wstrb values
//// todo: change to check if LSB is raised
logic tx_err;
always_ff @(posedge clk) begin
  if (!rstn) begin
    tx_err <= 0;
  end else begin
    if (tx_err) begin
      tx_err <= axi.bvalid & axi.bready;
    end else begin
      if (o_txb_wen) begin
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
    o_axi_bvalid <= 0;
  end else begin
    if (o_axi_bvalid) begin
      o_axi_bvalid <= ~i_axi_bready | o_txb_wen;
    end else begin
      o_axi_bvalid <= o_txb_wen;
    end
  end
end

assign axi.bresp = {tx_err, 1'b0}; // OKAY or SLVERR


/* Read Controller */
// rxb read
logic valid_araddr;
always_comb begin
  valid_araddr = (i_axi_araddr == UART_ADDR) | (i_axi_araddr == UART_ADDR + 1);
end

always_comb begin
  o_rxb_ren = i_axi_arvalid & (i_axi_araddr == UART_ADDR) & ~i_rxb_empty;
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
  if (rxb_valid && i_axi_rready) begin
    o_axi_rdata <= i_rxb_rdata;
  end else if (rxb_valid && !i_axi_rready) begin
    o_axi_rdata <= o_axi_rdata;
  end else begin
    o_axi_rdata <= status;
  end
end

logic ar_en;
always_comb begin
  ar_en = i_axi_arvalid & o_axi_arready;
end

logic rxb_rvalid;
always_ff @(posedge clk) begin
  if (!rstn) begin
    rxb_rvalid <= 0;
  end else begin
    rxb_rvalid <= i_axi_arvalid & (i_axi_araddr == UART_ADDR);
  end
end

always_ff @(posedge clk) begin
  if (!rstn) begin
    o_axi_rvalid <= 0;
  end else begin
    if (o_axi_rvalid) begin
      o_axi_rvalid <= ~i_axi_rready | (ar_en & (i_axi_araddr == UART_ADDR + 1));
    end
    o_axi_rvalid <= rxb_rvalid | (ar_en & (i_axi_araddr == UART_ADDR + 1));
  end
end

always_comb begin
  o_axi_arready = ~rxb_rvalid;
end


endmodule
