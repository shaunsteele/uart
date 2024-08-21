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
  `uvm_info(get_full_name(), "Build", UVM_LOW)
  agt = axi4_lite_agent::type_id::create("agt", this);
  scb = uart_scoreboard::type_id::create("scb", this);
endfunction

function void connect_phase(uvm_phase phase);
  super.connect_phase(phase);
  `uvm_info(get_full_name(), "Connect", UVM_LOW)
  agt.mon.item_collected_port.connect(scb.item_collected_export);
endfunction

// function void end_of_elaboration();
//   `uvm_info(get_full_name(), "End of Elaboration", UVM_LOW);
// endfunction

// function void start_of_simulation();
//   `uvm_info(get_full_name(), "Start of Simulation", UVM_LOW);
// endfunction

// task run_phase(uvm_phase phase);
//   `uvm_info(get_full_name(), "Run", UVM_LOW)
//   repeat (1) begin
//     uart_seq_item txn = uart_seq_item::type_id::create("txn");
//     if (!txn.randomize())
//       `uvm_fatal(get_full_name(), "Failed to randomize")
//     `uvm_info(get_full_name(), $sformatf("%s",txn.convert2string()), UVM_LOW)
//   end
// endtask

// function void extract();
//   `uvm_info(get_full_name(), "Extract", UVM_LOW);
// endfunction

// function void check();
//   `uvm_info(get_full_name(), "Check", UVM_LOW);
// endfunction

// function void report();
//   `uvm_info(get_full_name(), "Report", UVM_LOW);
// endfunction

endclass

`endif
