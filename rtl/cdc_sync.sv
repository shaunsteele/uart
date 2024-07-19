// cdc_sync.sv

`default_nettype none

module cdc_sync # (
  parameter int REGS = 2,
  parameter bit INIT = 0
)(
  input var         clk,
  input var         i_d,
  output var logic  o_q
);

(* ASYNC_REGS = "TRUE" *) logic [REGS-1:0] r = {(REGS){INIT}};
always_ff @(posedge clk) begin
  r[REGS-1:0] <= {r[REGS-2:0], i_d};
end

assign o_q = r[REGS-1];

endmodule
