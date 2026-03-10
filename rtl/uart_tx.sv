// uart_tx.sv

`default_nettype none

module uart_tx # (
    parameter int   DATA_WIDTH = 8,
    parameter int   SAMPLE_RATE = 16
)(
    input   var logic                       clk,
    input   var logic                       rst_n,

    // baud rate counter enable
    input   var logic                       i_baud_tick,

    // control interface
    input   var logic                       i_start,
    input   var logic   [DATA_WIDTH-1:0]    i_data,
    output  var logic                       o_done,

    // serial data output
    output  var logic                       o_tx
);

// state generation
typedef enum logic [3:0] {
    TX_IDLE,
    TX_START,
    TX_DATA,
    TX_STOP
} tx_state_e;
tx_state_e curr_state;
tx_state_e next_state;

// sample rate counter
localparam int  SWidth = $clog2(SAMPLE_RATE);

logic [SWidth-1:0]  sample_ct;
logic [SWidth-1:0]  next_sample_ct;
logic               sample_ct_done;

always_comb begin
    sample_ct_done = {{(32-SWidth){1'b0}}, sample_ct} == SAMPLE_RATE - 1;
end


// data bit counter
localparam int  BWidth = $clog2(DATA_WIDTH);

logic [BWidth-1:0]  bit_ct;
logic [BWidth-1:0]  next_bit_ct;
logic               bit_ct_done;

always_comb begin
    bit_ct_done = {{(32-BWidth){1'b0}}, bit_ct} == DATA_WIDTH - 1;
end


// parallel to serial shift register
logic [DATA_WIDTH-1:0]  data_sr;
logic [DATA_WIDTH-1:0]  next_data_sr;


// serial data output
logic txs;
logic next_txs;

assign o_tx = txs;


// output control status
logic tx_done;

assign o_done = tx_done;


// state machine registers
always_ff @(posedge clk) begin
    if (!rst_n) begin
        sample_ct <= 0;
        bit_ct <= 0;
        data_sr <= 0;
        txs <= 0;
        curr_state <= TX_IDLE;
    end else begin
        sample_ct <= next_sample_ct;
        bit_ct <= next_bit_ct;
        data_sr <= next_data_sr;
        txs <= next_txs;
        curr_state <= next_state;
    end
end

// state machine logic
always_comb begin
    // initialize values prior to logic
    next_sample_ct = sample_ct;
    next_bit_ct = bit_ct;
    next_data_sr = data_sr;
    next_txs = txs;
    tx_done = 1'b0;
    next_state = curr_state;

    // next state logic
    unique case (curr_state)
        TX_IDLE: begin
            next_txs = 1'b1;
            if (i_start) begin
                next_sample_ct = 0;
                next_data_sr = i_data;
                next_state = TX_START;
            end
        end

        TX_START: begin
            next_txs = 1'b0;
            if (i_baud_tick) begin
                if (sample_ct_done) begin
                    next_sample_ct = 0;
                    next_state = TX_DATA;
                end else begin
                    next_sample_ct = sample_ct + 1;
                end
            end
        end

        TX_DATA: begin
            next_txs = data_sr[0];
            if (i_baud_tick) begin
                if (sample_ct_done) begin
                    next_sample_ct = 0;
                    next_data_sr = data_sr >> 1;
                    if (bit_ct_done) begin
                        next_state = TX_STOP;
                    end else begin
                        next_bit_ct = bit_ct + 1;
                    end
                end else begin
                    next_sample_ct = sample_ct + 1;
                end
            end
        end

        TX_STOP: begin
            next_txs = 1'b1;
            if (i_baud_tick) begin
                if (sample_ct_done) begin
                    tx_done = 1;
                    next_state = TX_IDLE;
                end else begin
                    next_sample_ct = sample_ct + 1;
                end
            end
        end
    endcase
end


endmodule
