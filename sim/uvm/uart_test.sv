// uart_test.sv

`ifndef __UART_TEST
`define __UART_TEST

class uart_test extends uvm_test;

`uvm_component_utils(uart_test)

uart_env env;
uart_sequence seq;

function new(string name="uart_test", uvm_component parent=null);
  super.new(name, parent);
endfunction

virtual function void build_phase(uvm_phase phase);
  super.build_phase(phase);
  env = uart_env::type_id::create("env", this);
  seq = uart_sequence::type_id::create("seq", this);
endfunction

task run_phase(uvm_phase phase);
  phase.raise_objection(this);
  `uvm_info(get_full_name(), "run_phase", UVM_LOW)
  #100;
  `uvm_info(get_full_name(), "starting sequencer", UVM_LOW)
  seq.start(env.agt.sqr);
  #10000;
  `uvm_info(get_full_name(), "global_stop_request()", UVM_LOW)
  global_stop_request();
  phase.drop_objection(this);
endtask

endclass

`endif
