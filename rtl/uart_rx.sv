// uart_rx.sv

`default_nettype none

module uart_rx # (
    parameter int   DATA_WIDTH = 8,
    parameter int   SAMPLE_RATE = 16
)(
    input   var logic                       clk,
    input   var logic                       rst_n,

    input   var logic                       i_rx,
    input   var logic                       i_baud_tick,

    output  var logic                       o_done,
    output  var logic   [DATA_WIDTH-1:0]    o_data
);

// state generation
typedef enum logic [3:0] {
    RX_IDLE,
    RX_START,
    RX_DATA,
    RX_STOP
} rx_state_e;
rx_state_e  curr_state;
rx_state_e  next_state;


// sample rate counter
localparam int SWidth = $clog2(SAMPLE_RATE);
localparam int SampleRateHalf = SAMPLE_RATE / 2;

logic [SWidth-1:0]  sample_ct;
logic [SWidth-1:0]  next_sample_ct;
logic               half_sample_ct_done;
logic               sample_ct_done;

always_comb begin
    half_sample_ct_done = {{(32-SWidth){1'b0}}, sample_ct} == SampleRateHalf;
    sample_ct_done = {{(32-SWidth){1'b0}}, sample_ct} == SAMPLE_RATE;
end


// data bit counter
localparam int  BWidth = $clog2(DATA_WIDTH);

logic [BWidth-1:0]  bit_ct;
logic [BWidth-1:0]  next_bit_ct;
logic               bit_ct_done;

always_comb begin
    bit_ct_done = {{(32-BWidth){1'b0}}, bit_ct} == DATA_WIDTH;
end


// serial to parallel shift register
logic [DATA_WIDTH-1:0]  data_sr;
logic [DATA_WIDTH-1:0]  next_data_sr;

assign o_data = data_sr;

// output control status
logic rx_done;

assign o_done = rx_done;


// state machine registers
always_ff @(posedge clk) begin
    if (!rst_n) begin
        sample_ct <= 0;
        bit_ct <= 0;
        data_sr <= 0;
        curr_state <= RX_IDLE;
    end else begin
        sample_ct <= next_sample_ct;
        bit_ct <= next_bit_ct;
        data_sr <= next_data_sr;
        curr_state <= next_state;
    end
end


// state machine logic
always_comb begin
    // initialize values prior to logic
    next_sample_ct = sample_ct;
    next_bit_ct = bit_ct;
    next_data_sr = data_sr;
    rx_done = 1'b0;

    // next state logic
    unique case (curr_state)
        RX_IDLE: begin
            if (i_rx == 1'b0) begin // UART start bit
                next_sample_ct = 0;
                next_state = RX_START;
            end
        end

        RX_START: begin
            if (i_baud_tick) begin
                if (half_sample_ct_done) begin  // center samples on midpoint of data
                    next_sample_ct = 0;
                    next_state = RX_DATA;
                end else begin
                    next_sample_ct = sample_ct + 1;
                end
            end
        end

        RX_DATA: begin
            if (i_baud_tick) begin
                if (sample_ct_done) begin
                    next_sample_ct = 0;
                    next_data_sr = {i_rx, data_sr[DATA_WIDTH-1:1]};
                    if (bit_ct_done) begin
                        next_state = RX_STOP;
                    end else begin
                        next_bit_ct = bit_ct + 1;
                    end
                end else begin
                    next_sample_ct = sample_ct + 1;
                end
            end
        end

        RX_STOP: begin
            if (i_baud_tick) begin
                if (sample_ct_done) begin
                    rx_done = 1'b1;
                    next_state = RX_IDLE;
                end else begin
                    next_sample_ct = sample_ct + 1;
                end
            end
        end
    endcase
end

endmodule
