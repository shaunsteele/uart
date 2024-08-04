// uart_test.sv

`ifndef __UART_TEST
`define __UART_TEST

class uart_test extends uvm_test;

`uvm_component_utils(uart_test)

uart_env env;

function new(string name="uart_test", uvm_component parent=null);
  super.new(name, parent);
  env = new("uart_env", this);
endfunction

function void end_of_elaboration();
  `uvm_report_info(get_full_name(), "End of Elaboration", UVM_LOW)
  print();
endfunction

task run();
  #1000;
  global_stop_request();
endtask

endclass

`endif
