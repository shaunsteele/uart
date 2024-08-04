// tb_uart_pkg.sv

`default_nettype none

`include "uvm_macros.svh"

package tb_uart_pkg;

import uvm_pkg::*;

`include "uart_env.sv"
`include "uart_test.sv"

endpackage
