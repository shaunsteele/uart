// baud_gen.sv

`default_nettype none

module baud_gen #(
    parameter int DVSR_WIDTH = 11
)(
    input   var logic                       clk,
    input   var logic                       rst_n,

    input   var logic   [DVSR_WIDTH-1:0]    i_divisor,
    output  var logic                       o_tick
);

logic [DVSR_WIDTH-1:0]    curr_ct;
logic [DVSR_WIDTH-1:0]    next_ct;

always_ff @(posedge clk) begin
    if (!rst_n) begin
        curr_ct <= 0;
    end else begin
        curr_ct <= next_ct;
    end
end

always_comb begin
    if (curr_ct == i_divisor) begin
        next_ct = '0;
    end else begin
        next_ct = curr_ct + '1;
    end
    o_tick = curr_ct == '1;
end

endmodule
