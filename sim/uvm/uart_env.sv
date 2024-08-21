// uart_env.sv

`ifndef __UART_ENV
`define __UART_ENV

class uart_env extends uvm_env;

`uvm_component_utils(uart_env)

// agent declaration
axi4_lite_agent agt;
uart_scoreboard scb;

function new(string name, uvm_component parent);
  super.new(name, parent);
endfunction

virtual function void build_phase(uvm_phase phase);
  super.build_phase(phase);
  `uvm_info(get_full_name(), "build_phase", UVM_LOW)
  agt = axi4_lite_agent::type_id::create("agt", this);
  scb = uart_scoreboard::type_id::create("scb", this);
endfunction

function void connect_phase(uvm_phase phase);
  super.connect_phase(phase);
  `uvm_info(get_full_name(), "connect_phase", UVM_LOW)
  agt.mon.item_collected_port.connect(scb.item_collected_export);
endfunction

endclass

`endif
