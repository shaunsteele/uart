// uart_controller.sv

`default_nettype none

module uart_controller # (
  parameter int AXI_ALEN = 32,
  parameter int AXI_DLEN = 32,
  parameter int AXI_SLEN = AXI_DLEN / 8,
  parameter int UART_DLEN = 8,
  parameter int UART_ADDR = 32'h0
)(
  input var                         clk,
  input var                         rstn,

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
  input var                         i_txb_overflow,

  // rx buffer interface
  input var                         i_rxb_tvalid,
  output var logic                  o_rxb_tready,
  input var         [UART_DLEN-1:0] i_rxb_tdata,
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
    end else begin
      valid_awaddr <= i_axi_awvalid & i_axi_awaddr == UART_ADDR;
    end
  end
end

// write address channel ready
always_ff @(posedge clk) begin
  if (!rstn) begin
    o_axi_awready <= 0;
  end else begin
    o_axi_awready <= ~(i_axi_awvalid ^ aw_en ^ o_txb_tvalid);
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

// write data channel ready
always_ff @(posedge clk) begin
  if (!rstn) begin
    o_axi_wready <= 0;
  end else begin
    o_axi_wready <= ~(i_axi_wvalid ^ w_en ^ o_txb_tvalid);
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
      o_axi_bresp <= 2'b10; // SLVERR
    end else begin
      o_axi_bresp <= 2'b0;
    end
  end
end


/* Read Controller */
// read buffer enable
logic rxb_en;
always_comb begin
  rxb_en = i_axi_arvalid & (i_axi_araddr == UART_ADDR);
end

always_ff @(posedge clk) begin
  if (!rstn) begin
    o_rxb_tready <= 0;
  end else begin
    if (o_rxb_tready) begin
      o_rxb_tready <= ~i_axi_rready;
    end else begin
      o_rxb_tready <= rxb_en;
    end
  end
end

// read status enable
logic read_status;
always_comb begin
  read_status = i_axi_arvalid & (i_axi_araddr == UART_ADDR + 1);
end

// status data
logic [AXI_DLEN-1:0]  status;
assign status = {
  {(AXI_DLEN-8){1'b0}},
  1'b0,
  i_rxb_underflow,
  i_rxb_overflow,
  i_rxb_tvalid,
  2'b0,
  i_txb_overflow,
  i_txb_tready
};

logic rxb_flag;
always_ff @(posedge clk) begin
  if (!rstn) begin
    rxb_flag <= 0;
  end else begin
    if (rxb_flag) begin
      rxb_flag <= ~(o_axi_rvalid & i_axi_rready);
    end else begin
      rxb_flag <= rxb_en;
    end
  end
end

logic rstn_q;
always_ff @(posedge clk) begin
  rstn_q <= rstn;
end

always_ff @(posedge clk) begin
  if (!rstn) begin
    o_axi_arready <= 0;
  end else begin
    if (o_axi_arready) begin
      o_axi_arready <= ~i_axi_arvalid;
    end else begin
      if (rstn && !rstn_q) begin
        o_axi_arready <= 1;
      end else begin
        o_axi_arready <= o_axi_rvalid & i_axi_rready;
      end
    end
  end
end

always_ff @(posedge clk) begin
  if (!rstn) begin
    o_axi_rvalid <= 0;
  end else begin
    if (o_axi_rvalid) begin
      o_axi_rvalid <= ~i_axi_rready;
    end else begin
      if (rxb_flag) begin
        o_axi_rvalid <= i_rxb_tvalid;
      end else begin
        o_axi_rvalid <= i_axi_arvalid & o_axi_arready;
      end
    end
  end
end

// read data buffer
always_ff @(posedge clk) begin
  if (!rstn) begin
    o_axi_rdata <= {(AXI_DLEN){1'b1}};
  end else begin
    if (rxb_en || o_rxb_tready) begin
      o_axi_rdata <= {{(AXI_DLEN-UART_DLEN){1'b0}}, i_rxb_tdata};
    end else if (read_status) begin
      o_axi_rdata <= status;
    end else begin
      o_axi_rdata <= o_axi_rdata;
    end
  end
end

always_ff @(posedge clk) begin
  if (!rstn) begin
    o_axi_rresp <= 2'b00;
  end else begin
    if (rxb_en || read_status) begin
      o_axi_rresp <= 2'b00;
    end else if (i_axi_arvalid && (!rxb_en || !read_status)) begin
      o_axi_rresp <= 2'b11; // DECERR
    end else begin
      o_axi_rresp <= o_axi_rresp;
    end
  end
end

endmodule
