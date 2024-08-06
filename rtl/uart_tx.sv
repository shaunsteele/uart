// uart_tx.sv

`default_nettype none

module uart_tx # (
  parameter int BAUD = 921600,
  parameter int CLKF = 100000000,
  parameter int DLEN = 8,
  parameter int PARITY = 0,
  parameter string ENDIAN = "big"
)(
  input var                     clk,
  input var                     rstn,

  output var logic              o_txs,

  input var                     i_wvalid,
  output var logic              o_wready,
  input var         [DLEN-1:0]  i_wdata
);


/* Baud Counter */
localparam int BaudLimit = (CLKF / BAUD) - 1;
localparam int BaudLen = $clog2(BaudLimit);

logic               baud_ct_en;
logic [BaudLen-1:0] baud_ct;
logic               baud_ct_done;

always_comb begin
  baud_ct_done = baud_ct == BaudLimit;
end

always_ff @(posedge clk) begin
  if (!rstn) begin
    baud_ct <= 0;
  end if (baud_ct_en && !baud_ct_done) begin
    baud_ct <= baud_ct + 1;
  end else begin
    baud_ct <= 0;
  end
end


/* Bit Counter */
localparam int BitLimit = DLEN - 1;
localparam int BitLen = $clog2(BitLimit);

logic               bit_ct_en;
logic [BitLen-1:0]  bit_ct;
logic               bit_ct_done;

always_ff @(posedge clk) begin
  if (!rstn) begin
    bit_ct <= 0;
  end else begin
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
end

always_comb begin
  bit_ct_done = bit_ct == BitLimit;
end


/* Transmitter Shift Register */
logic [DLEN-1:0]  txd;

always_ff @(posedge clk) begin
  if (i_wvalid && o_wready) begin
    txd <= i_wdata;
  end else begin
    if (bit_ct_en && baud_ct_done) begin
      if (ENDIAN == "big") begin
        txd <= txd << 1;
      end else begin
        txd <= txd >> 1;
      end
    end else begin
      txd <= txd;
    end
  end
end


/* Parity Calculator */
logic [DLEN-1:0]  parity_buf;
logic             parity_bit;

always_comb begin
  parity_bit = ^parity_buf;
end

always_ff @(posedge clk) begin
  if (i_wvalid && o_wready) begin
    parity_buf <= i_wdata;
  end else begin
    parity_buf <= parity_buf;
  end
end


/* State Machine */
// States
typedef enum logic [4:0] {
  TX_READY  = 5'b00001,
  TX_START  = 5'b00010,
  TX_DATA   = 5'b00100,
  TX_STOP   = 5'b01000,
  TX_PARITY = 5'b10000
} state_e;
state_e curr_state;
state_e next_state;

// Next State Logic
always_comb begin
  unique case (curr_state)
    TX_READY: begin
      o_wready = 1;
      o_txs = 1;
      baud_ct_en = 0;
      bit_ct_en = 0;

      if (i_wvalid) begin
        next_state = TX_START;
      end else begin
        next_state = curr_state;
      end
    end

    TX_START: begin
      o_wready = 0;
      baud_ct_en = 1;
      bit_ct_en = 0;
      o_txs = 0;

      if (baud_ct_done) begin
        next_state = TX_DATA;
      end else begin
        next_state = curr_state;
      end
    end

    TX_DATA: begin
      o_wready = 0;
      baud_ct_en = 1;
      bit_ct_en = 1;
      if (ENDIAN == "big") begin
        o_txs = txd[DLEN-1];
      end else begin
        o_txs = txd[0];
      end

      if (baud_ct_done && bit_ct_done) begin
        if (PARITY) begin
          next_state = TX_PARITY;
        end else begin
          next_state = TX_STOP;
        end
      end else begin
        next_state = curr_state;
      end
    end

    TX_PARITY: begin
      o_wready = 0;
      baud_ct_en = 1;
      bit_ct_en = 0;
      o_txs = parity_bit;

      if (baud_ct_done) begin
        next_state = TX_STOP;
      end else begin
        next_state = curr_state;
      end
    end

    TX_STOP: begin
      o_wready = 0;
      baud_ct_en = 1;
      bit_ct_en = 0;
      o_txs = 1;

      if (baud_ct_done) begin
        next_state = TX_READY;
      end else begin
        next_state = curr_state;
      end
    end

    default: begin
      o_wready = 0;
      baud_ct_en = 0;
      bit_ct_en = 0;
      o_txs = 1;
      next_state = TX_READY;
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


endmodule
