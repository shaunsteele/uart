// uart_tx.sv

`default_nettype none

module uart_tx # (
  parameter int BAUD = 9600,
  parameter int CLKF = 100000000,
  parameter int DLEN = 8
)(
  input var                     clk,
  input var                     rstn,

  output var logic              o_txs,

  input var                     i_wvalid,
  output var logic              o_wready,
  input var         [DLEN-1:0]  i_wdata
);

logic             wvalid;
logic             wready;
logic [DLEN-1:0]  wdata;
skid_buffer # (.DLEN (DLEN)) u_SB (
  .clk  (clk),
  .rstn (rstn),
  .i_valid  (i_wvalid),
  .o_ready  (o_wready),
  .i_data   (i_wdata),
  .o_valid  (wvalid),
  .i_ready  (wready),
  .o_wdata  (wdata)
);

logic baud_ct_done;
logic [DLEN-1:0]  txd;
always_ff @(posedge clk) begin
  if (wvalid) begin
    txd <= wdata;
  end else if (baud_ct_done) begin
    txd <= txd >> 1;
  end else begin
    txd <= txd;
  end
end

typedef enum logic [2:0] {
  TX_READY,
  TX_START,
  TX_DATA,
  TX_STOP
} state_e;
state_e curr_state;
state_e next_state;

// outputs
logic ready;
logic txs;
logic baud_ct_en;
logic bit_ct_en;

// inputs
logic bit_ct_done;

// Next State Logic
always_comb begin
  unique case (curr_state)
    TX_READY: begin
      wready = 1;
      txs = 1;
      baud_ct_en = 0;
      bit_ct_en = 0;

      if (i_wen) begin
        next_state = TX_START;
      end else begin
        next_state = curr_state;
      end
    end

    TX_START: begin
      wready = 0;
      txs = 0;
      baud_ct_en = 1;
      bit_ct_en = 0;

      if (baud_ct_done) begin
        next_state = TX_DATA;
      end else begin
        next_state = curr_state;
      end
    end

    TX_DATA: begin
      wready = 0;
      txs = txd[0];
      baud_ct_en = 1;
      bit_ct_en = 1;

      if (baud_ct_done && bit_ct_done) begin
        next_state = TX_STOP;
      end else begin
        next_state = curr_state;
      end
    end

    TX_STOP: begin
      wready = 0;
      txs = 1;
      baud_ct_en = 1;
      bit_ct_en = 0;

      if (baud_ct_done) begin
        next_state = TX_READY;
      end else begin
        next_state = curr_state;
      end
    end

    default: begin
      wready = 0;
      txs = 1;
      baud_ct_en = 0;
      bit_ct_en = 0;
      next_state = TX_READY;
      $error("Illegal State: 0b%0b", curr_state);
    end
  endcase
end

// Current State Register
always_ff @(posedge clk) begin
  if (!rstn) begin
    curr_state <= TX_READY;
  end else begin
    curr_state <= next_state;
  end
end

// Baud Counter
localparam int BaudLimit = CLKF / BAUD;
localparam int BaudLen = $clog2(BaudLimit);
logic [BaudLen:0] baud_ct = 0;
always_ff @(posedge clk) begin
  if (baud_ct_en && baud_ct < BaudLimit) begin
    baud_ct <= baud_ct + 1;
  end else begin
    baud_ct <= 0;
  end
end

always_comb begin
  baud_ct_done = baud_ct == BaudLimit;
end

// Bit Counter
localparam int BitLen = $clog2(DLEN);
logic [BitLen-1:0]  bit_ct = 0;
always_ff @(posedge clk) begin
  if (bit_ct_en) begin
    if (baud_ct_done) begin
      bit_ct <= bit_ct + 1;
    end else begin
      bit_ct <= bit_ct;
    end
  end else begin
    bit_ct <= 0;
  end
end

always_comb begin
  bit_ct_done = bit_ct == DLEN;
end

// Output Register
always_ff @(posedge clk) begin
  o_txs <= txs;
end

endmodule
