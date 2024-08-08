// uart_rx.sv

`default_nettype none

module uart_rx # (
  parameter int BAUD = 25000000,
  parameter int CLKF = 100000000,
  parameter int DLEN = 8
)(
  input var                     clk,
  input var                     rstn,

  input var                     i_rxs,

  output var logic              o_tvalid,
  input var                     i_tready,
  output var logic  [DLEN-1:0]  o_tdata
);


/* Baud Counter */
localparam int BaudLimit = (CLKF / BAUD) - 1;
localparam int BaudLen = $clog2(BaudLimit);

logic [BaudLen-1:0] baud_ct;
logic               baud_limit_half;
logic               baud_ct_done;
logic               baud_ct_en;

always_ff @(posedge clk) begin
  if (!rstn) begin
    baud_ct <= 0;
  end else begin
    if (baud_ct_en) begin
      if (!baud_ct_done) begin
        baud_ct <= baud_ct + 1;
      end else begin
        baud_ct <= 0;
      end
    end else begin
      baud_ct <= 0;
    end
  end
end

always_comb begin
  if (baud_limit_half) begin
    baud_ct_done = baud_ct == (BaudLimit / 2);
  end else begin
    baud_ct_done = baud_ct == BaudLimit;
  end
end


/* Bit Counter */
logic             bit_ct_done;
logic [DLEN-1:0]  bit_ct;
logic             bit_ct_en;

always_ff @(posedge clk) begin
  if (!rstn) begin
    bit_ct <= 0;
  end else begin
    if (bit_ct_en) begin
      if (baud_ct_done) begin
        bit_ct <= {bit_ct[DLEN-2:0], 1'b1};
      end else begin
        bit_ct <= bit_ct;
      end
    end else begin
      bit_ct <= 0;
    end
  end
end

always_comb begin
  bit_ct_done = &bit_ct;
end


/* Receiver Shift Register */
logic             rxd_en;
logic [DLEN-1:0]  rxd;

always_ff @(posedge clk) begin
  if (!rstn) begin
    rxd <= 0;
  end else begin
    if (rxd_en && baud_ct_done) begin
      rxd <= {i_rxs, rxd[DLEN-1:1]};
    end else begin
      rxd <= rxd;
    end
  end
end


/* Output Registering */
logic rdata_en;

always_ff @(posedge clk) begin
  if (rdata_en) begin
    o_tdata <= rxd;
  end else begin
    o_tdata <= o_tdata;
  end
end

always_ff @(posedge clk) begin
  if (!rstn) begin
    o_tvalid <= 0;
  end else begin
    if (o_tvalid) begin
      o_tvalid <= ~i_tready;
    end else begin
      o_tvalid <= rdata_en;
    end
  end
end


/* State Machine */
// States
typedef enum logic [4:0] {
  RX_IDLE   = 5'b00001,
  RX_START  = 5'b00010,
  RX_DATA   = 5'b00100,
  RX_STOP   = 5'b01000,
  RX_OUT    = 5'b10000
} rx_state_e;

rx_state_e curr_state;
rx_state_e next_state;

// Next State Logic
always_comb begin
  unique case (curr_state)
    RX_IDLE: begin
      baud_ct_en = 0;
      baud_limit_half = 0;
      bit_ct_en = 0;
      rxd_en = 0;
      rdata_en = 0;

      if (!i_rxs) begin
        next_state = RX_START;
      end else begin
        next_state = RX_IDLE;
      end
    end

    RX_START: begin
      baud_ct_en = 1;
      baud_limit_half = 1;
      bit_ct_en = 0;
      rxd_en = 0;
      rdata_en = 0;

      if (!i_rxs && baud_ct_done) begin
        next_state = RX_DATA;
      end else begin
        next_state = curr_state;
      end
    end

    RX_DATA: begin
      baud_ct_en = 1;
      baud_limit_half = 0;
      bit_ct_en = 1;
      rxd_en = 1;
      rdata_en = 0;

      if (bit_ct_done) begin
        next_state = RX_STOP;
      end else begin
        next_state = curr_state;
      end
    end

    RX_STOP: begin
      baud_ct_en = 1;
      baud_limit_half = 0;
      bit_ct_en = 0;
      rxd_en = 0;
      rdata_en = 0;

      if (i_rxs && baud_ct_done) begin
        next_state = RX_OUT;
      end else begin
        rdata_en = 0;
        next_state = curr_state;
      end
    end

    RX_OUT: begin
      baud_ct_en = 1;
      baud_limit_half = 0;
      bit_ct_en = 0;
      rxd_en = 0;
      rdata_en = 1;
      
      if (o_tvalid && i_tready) begin
        next_state = RX_IDLE;
      end else begin
        next_state = curr_state;
      end
    end

    default: begin
      if (rstn) $error("Illegal State: 0x%0h", curr_state);
      baud_ct_en = 0;
      baud_limit_half = 0;
      bit_ct_en = 0;
      rxd_en = 0;
      rdata_en = 0;
      next_state = RX_IDLE;
    end
  endcase
end

// Current State Register
always_ff @(posedge clk) begin
  if (!rstn) begin
    curr_state <= RX_IDLE;
  end else begin
    curr_state <= next_state;
  end
end


endmodule
