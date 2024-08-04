// tb_uart_top.sv

`default_nettype none

`include "uvm_macros.svh"

module tb_uart_top;

import uvm_pkg::*;
import tb_uart_pkg::*;

initial begin
  run_test("uart_test");
end

endmodule
