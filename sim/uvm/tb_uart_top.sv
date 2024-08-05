// tb_uart_top.sv

`default_nettype none

`include "uvm_macros.svh"

module tb_uart_top;

import uvm_pkg::*;
import tb_uart_pkg::*;

bit clk;
initial begin
  clk = 0;
  #5;
  forever #5 clk = ~clk;
end

bit rstn;
initial begin
  rstn = 0;
  #100;
  @(posedge clk);
  rstn = 1;
end

axi4_lite_if axi(clk, rstn);

parameter int BAUD = 9600;
parameter int CLKF = 100000000;

uart # (
  .BAUD (BAUD),
  .CLKF (CLKF)
) u_DUT (
  .clk    (clk),
  .rstn   (rstn),
  .o_tx   (),
  .i_rx   (1'b0),
  .axi    (axi)
);

initial begin
  uvm_config_db #(virtual axi4_lite_if)::set(null, "uvm_test_top", "axi", axi);
  run_test("uart_test");
end

endmodule
