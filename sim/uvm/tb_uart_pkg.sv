// tb_uart_pkg.sv

`default_nettype none

`include "uvm_macros.svh"

package tb_uart_pkg;

import uvm_pkg::*;

parameter ALEN = 32;
parameter DLEN = 32;
parameter SLEN = DLEN / 8;

parameter BASE_ADDR = 32'h0000_1000;
parameter TIMEOUT = 5;

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
