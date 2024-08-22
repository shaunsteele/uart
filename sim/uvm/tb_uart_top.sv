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

axi4_lite_if axi(.aclk(clk), .aresetn(rstn));

parameter int BAUD = 9600;
parameter int CLKF = 100000000;

logic sd;

uart # (
  .BAUD (BAUD),
  .CLKF (CLKF)
) u_DUT (
  .clk    (clk),
  .rstn   (rstn),
  .o_tx   (sd),
  .i_rx   (sd),
  .axi    (axi)
);

initial begin
  uvm_config_db #(virtual axi4_lite_if)::set(uvm_root::get(), "*", "axi", axi);
  run_test("uart_test");
end

endmodule
