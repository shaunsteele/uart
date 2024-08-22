// tb_uart_pkg.sv

`default_nettype none

`include "uvm_macros.svh"

package tb_uart_pkg;

import uvm_pkg::*;

parameter int CLKF = 100000000;
parameter int BAUD = 50000000;

parameter int ALEN = 32;
parameter int DLEN = 32;
parameter int SLEN = DLEN / 8;

parameter bit [ALEN-1:0] BASE_ADDR = 32'h0000_1000;
parameter int TIMEOUT = 5;

typedef enum bit {
  GOOD,
  BAD
} type_t;

`include "uart_seq_item.sv"
`include "uart_sequence.sv"

`include "axi4_lite_driver.sv"
`include "axi4_lite_monitor.sv"
`include "axi4_lite_agent.sv"

`include "uart_scoreboard.sv"
`include "uart_env.sv"
`include "uart_test.sv"

endpackage
