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
  input var                         i_txb_overflow,

  // rx buffer interface
  input var                         i_rxb_tvalid,
  output var logic                  o_rxb_tready,
  input var         [UART_DLEN-1:0] i_rxb_tdata,
  // output var logic                  o_rxb_ren,
  // input var         [UART_DLEN-1:0] i_rxb_rdata,
  input var                         i_rxb_empty,
  input var                         i_rxb_overflow,
  input var                         i_rxb_underflow
);

/* Write Controller */
// transmit buffer enable
logic b_en;
logic aw_en;
logic w_en;
always_comb begin
  b_en = aw_en & w_en;
end


// write data channel ready
always_comb begin
  o_axi_wready = ~w_en | i_txb_tready;
end

// write address enable latch
always_ff @(posedge clk) begin
  if (!rstn) begin
    aw_en <= 0;
  end else begin
    if (aw_en) begin
      aw_en <= ~b_en;
    end else begin
      aw_en <= i_axi_awvalid;
    end
  end
end

// valid write address latch
logic valid_awaddr;
always_ff @(posedge clk) begin
  if (!rstn) begin
    valid_awaddr <= 0;
  end else  begin
    if (valid_awaddr) begin
      valid_awaddr <= ~b_en;
    end else  begin
      valid_awaddr <= i_axi_awvalid & i_axi_awaddr == UART_ADDR;
    end
  end
end

// write address channel ready
logic awready;
always_ff @(posedge clk) begin
  if (!rstn) begin
    o_axi_awready <= 0;
  end else begin
    if (i_axi_awvalid | aw_en) begin
      o_axi_awready <= 0;
    end else begin
      o_axi_awready <= i_txb_tready;
    end
  end
end

// write data enable latch
always_ff @(posedge clk) begin
  if (!rstn) begin
    w_en <= 0;
  end else begin
    if (w_en) begin
      w_en <= ~b_en;
    end else begin
      w_en <= i_axi_wvalid;
    end
  end
end

// valid write address latch
logic valid_wdata;
always_ff @(posedge clk) begin
  if (!rstn) begin
    valid_wdata <= 0;
  end else  begin
    if (valid_wdata) begin
      valid_wdata <= ~b_en;
    end else  begin
      valid_wdata <= i_axi_wvalid & i_axi_wstrb[0];
    end
  end
end

// write data register
always_ff @(posedge clk) begin
  if (i_axi_wvalid & i_txb_tready) begin
    o_txb_tdata <= i_axi_wdata[UART_DLEN-1:0];
  end else begin
    o_txb_tdata <= o_txb_tdata;
  end
end

// buffer write valid
always_ff @(posedge clk) begin
  if (!rstn) begin
    o_txb_tvalid <= 0;
  end else begin
    if (o_txb_tvalid) begin
      o_txb_tvalid <= ~i_txb_tready;
    end else begin
      o_txb_tvalid <= b_en & valid_awaddr & valid_wdata;
    end
  end
end

// write response channel
always_ff @(posedge clk) begin
  if (!rstn) begin
    o_axi_bvalid <= 0;
  end else begin
    if (o_axi_bvalid) begin
      o_axi_bvalid <= ~i_axi_bready;
    end else begin
      if (b_en && (!valid_awaddr || !valid_wdata)) begin
        o_axi_bvalid <= 1;
      end else begin
        o_axi_bvalid <= o_txb_tvalid & i_txb_tready;
      end
    end
  end
end

// errors:
//  - illegal awaddr
//  - illegal wstrb
//  - overflow
always_ff @(posedge clk) begin
  if (!rstn) begin
    o_axi_bresp <= 0;
  end else begin
    if (b_en && !valid_awaddr) begin
      o_axi_bresp <= 2'b11; // DECERR
    end else if (b_en && valid_awaddr && !valid_wdata) begin
      o_axi_bresp <= 2'b10;
    end else begin
      o_axi_bresp <= 2'b0;
    end
  end
end


/* Read Controller */
// rxb read
// logic valid_araddr;
// always_comb begin
//   valid_araddr = (i_axi_araddr == UART_ADDR) | (i_axi_araddr == UART_ADDR + 1);
// end

// always_comb begin
//   o_rxb_ren = i_axi_arvalid & (i_axi_araddr == UART_ADDR) & ~i_rxb_empty;
// end

// logic rxb_valid;
// always_ff @(posedge clk) begin
//   if (!rstn) begin
//     rxb_valid <= 0;
//   end else begin
//     rxb_valid <= o_rxb_ren;
//   end
// end

// logic [axi.DLEN-1:0]  status;
// assign status = {
//   {(axi.DLEN-5){1'b0}},
//   i_rxb_overflow,
//   i_rxb_underflow,
//   i_rxb_empty,
//   i_txb_overflow,
//   i_txb_full
// };

// always_ff @(posedge clk) begin
//   if (rxb_valid && i_axi_rready) begin
//     o_axi_rdata <= i_rxb_rdata;
//   end else if (rxb_valid && !i_axi_rready) begin
//     o_axi_rdata <= o_axi_rdata;
//   end else begin
//     o_axi_rdata <= status;
//   end
// end

// logic ar_en;
// always_comb begin
//   ar_en = i_axi_arvalid & o_axi_arready;
// end

// logic rxb_rvalid;
// always_ff @(posedge clk) begin
//   if (!rstn) begin
//     rxb_rvalid <= 0;
//   end else begin
//     rxb_rvalid <= i_axi_arvalid & (i_axi_araddr == UART_ADDR);
//   end
// end

// always_ff @(posedge clk) begin
//   if (!rstn) begin
//     o_axi_rvalid <= 0;
//   end else begin
//     if (o_axi_rvalid) begin
//       o_axi_rvalid <= ~i_axi_rready | (ar_en & (i_axi_araddr == UART_ADDR + 1));
//     end
//     o_axi_rvalid <= rxb_rvalid | (ar_en & (i_axi_araddr == UART_ADDR + 1));
//   end
// end

// always_comb begin
//   o_axi_arready = ~rxb_rvalid;
// end


endmodule
