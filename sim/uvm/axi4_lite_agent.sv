// axi4_lite_agent.sv

`ifndef __AXI4_LITE_AGENT
`define __AXI4_LITE_AGENT

class axi4_lite_agent extends uvm_agent;

`uvm_component_utils(axi4_lite_agent)

axi4_lite_driver drv;
axi4_lite_monitor mon;
uvm_sequencer#(uart_seq_item) sqr;

function new(string name, uvm_component parent);
  super.new(name, parent);
endfunction

virtual function void build_phase(uvm_phase phase);
  super.build_phase(phase);
  if (get_is_active() == UVM_ACTIVE) begin
    sqr = uvm_sequencer#(uart_seq_item)::type_id::create("sqr", this);
    drv = axi4_lite_driver::type_id::create("drv", this);
  end
  mon = axi4_lite_monitor::type_id::create("mon", this);
endfunction

virtual function void connect_phase(uvm_phase phase);
  super.connect_phase(phase);
  if (get_is_active()) begin
    drv.seq_item_port.connect(sqr.seq_item_export);
  end
endfunction

endclass

`endif
