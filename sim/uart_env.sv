// uart_env.sv

`ifndef __UART_ENV
`define __UART_ENV

class uart_env extends uvm_env;

`uvm_component_utils(uart_env)

// agent declaration

function new(string name, uvm_component parent);
  super.new(name, parent);
endfunction

function void build();
  `uvm_report_info(get_full_name(), "Build", UVM_LOW)
  // agent
endfunction

function void connect();
  `uvm_report_info(get_full_name(), "Connect", UVM_LOW)
endfunction

function void end_of_elaboration();
  `uvm_report_info(get_full_name(), "End of Elaboration", UVM_LOW)
endfunction

function void start_of_simulation();
  `uvm_report_info(get_full_name(), "Start of Simulation", UVM_LOW)
endfunction

task run();
  `uvm_report_info(get_full_name(), "Run", UVM_LOW)
endtask

function void extract();
  `uvm_report_info(get_full_name(), "Extract", UVM_LOW)
endfunction

function void check();
  `uvm_report_info(get_full_name(), "Check", UVM_LOW)
endfunction

function void report();
  `uvm_report_info(get_full_name(), "Report", UVM_LOW)
endfunction

endclass

`endif
