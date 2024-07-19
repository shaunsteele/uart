// uart_rx.sv

`default_nettype none

module uart_rx # (
  parameter int BAUD = 9600,
  parameter int CLKF = 100000000,
  parameter int DLEN = 8
)(
  input var                     clk,
  input var                     rstn,

  input var                     i_rxs,

  output var logic              o_rvalid,
  output var logic  [DLEN-1:0]  o_rdata
);

typedef enum logic [3:0] {
  RX_IDLE,
  RX_START,
  RX_DATA,
  RX_STOP
} state_e;
state_e curr_state;
state_e next_state;

always_ff @(posedge clk) begin
  if (!rstn) begin
    curr_state <= RX_IDLE;
  end else begin
    curr_state <= next_state;
  end
end

logic baud_ct_en;
logic baud_ct_done;
logic bit_ct_done;

always_comb begin
  unique case (RX_IDLE)
    RX_IDLE: begin
      baud_ct_en = 0;
      baud_limit_half = 0;
      bit_ct_en = 0;
      rxd_en = 0;
      tdata_en = 0;

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
      tdata_en = 0;

      if (!rxs && baud_ct_done) begin
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
      tdata_en = 0;

      if (!rxs && bit_ct_done) begin
        next_state = RX_DATA;
      end else begin
        next_state = curr_state;
      end
    end

    RX_STOP: begin
      baud_ct_en = 1;
      baud_limit_half = 0;
      bit_ct_en = 0;
      rxd_en = 0;

      if (rxs && baud_ct_done) begin
        tdata_en = 1;
        next_state = RX_IDLE;
      end else begin
        tdata_en = 0;
        next_state = curr_state;
      end
    end

    default: begin
      $error("Illegal State: 0x%0h", curr_state);
      baud_ct_en = 0;
      baud_limit_half = 0;
      bit_ct_en = 0;
      rxd_en = 0;
      tdata_en = 0;
      next_state = RX_IDLE;
    end
  endcase
end 


// Baud Counter
localparam int BaudLimit = CLKF / BAUD;
localparam int BaudCtLen = $clog2(BaudLimit);
logic [BaudCtLen-1:0] baud_ct;

always_comb begin
  if (baud_limit_half) begin
    baud_ct_done = baud_ct >= BaudLimit / 2;
  end else begin
    baud_ct_done = baud_ct >= BaudLimit;
  end
end

always_ff @(posedge clk) begin
  if (!rstn) begin
    baud_ct <= 0;
  end else begin
    if (baud_ct_en) begin
      if (!baud_ct_done) begin
        baud_ct <= baud_ct + 1;
      end else begin
        baud_ct <= baud_ct;
      end
    end else begin
      baud_ct <= 0;
    end
  end
end


// Bit Counter
logic [DLEN-1:0]  bit_ct;

always_comb begin
  bit_ct_done = &bit_ct;
end

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


// Serial to Parallel Shift Register
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

// Output Registering
always_ff @(posedge clk) begin
  if (tdata_en) begin
    o_rdata <= rxd;
  end else begin
    o_rdata <= o_rdata;
  end
end

always_ff @(posedge clk) begin
  if (!rstn) begin
    o_rvalid <= 0;
  end else begin
    o_rvalid <= tdata_en;
  end
end

endmodule
