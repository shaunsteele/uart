// uart_scoreboard.sv

`ifndef __UART_SCOREBOARD
`define __UART_SCOREBOARD

class uart_scoreboard extends uvm_scoreboard;

`uvm_component_utils(uart_scoreboard)

uvm_analysis_imp#(uart_seq_item, uart_scoreboard) item_collected_export;

function new(string name, uvm_component parent);
  super.new(name, parent);
endfunction

virtual function void build_phase(uvm_phase phase);
  super.build_phase(phase);
  item_collected_export = new("item_collected_export", this);
endfunction

virtual function void write(uart_seq_item data);
  `uvm_info(get_full_name(), "write - printing data", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("%s", data.convert2string()), UVM_LOW)
endfunction

virtual task run_phase(uvm_phase phase);
  // comparison
endtask

virtual function void check_phase(uvm_phase phase);
  super.check_phase(phase);
endfunction

endclass

`endif
