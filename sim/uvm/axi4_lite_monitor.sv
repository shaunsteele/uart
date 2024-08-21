// axi4_lite_monitor.sv

`ifndef __AXI4_LITE_MONITOR
`define __AXI4_LITE_MONITOR

class axi4_lite_monitor extends uvm_monitor;

`uvm_component_utils(axi4_lite_monitor)

virtual axi4_lite_if axi;
uvm_analysis_port #(uart_seq_item) item_collected_port;

function new(string name, uvm_component parent);
  super.new(name, parent);
endfunction

virtual function void build_phase(uvm_phase phase);
  super.build_phase(phase);
  item_collected_port = new("mon_ap", this);
  if (!uvm_config_db#(virtual axi4_lite_if)::get(this, "", "axi", axi))
    `uvm_fatal(get_type_name(), "Didn't get handle to virtual interface axi")
endfunction

virtual task run_phase(uvm_phase phase);
  forever begin
    uart_seq_item data = uart_seq_item::type_id::create("data", this);
    while (!((axi.awvalid && axi.awready) || (axi.wvalid && axi.wready) || (axi.arvalid && axi.arready))) begin
      @(posedge axi.aclk);
    end
    fork
      mon_write(data);
      mon_read(data);
    join
    // mon_ap.write(data);
  end
endtask

task mon_aw(ref uart_seq_item data);
  for (int i=0; i < TIMEOUT; i++) begin
    @(negedge axi.aclk);
    if (axi.awvalid && axi.awready) begin
      data.write = 1;
      data.awdelay = i;
      data.awaddr = axi.awaddr;
      data.awprot = axi.awprot;
      break;
    end
    @(posedge axi.aclk);
  end
endtask

task mon_w(ref uart_seq_item data);
  for (int i=0; i < TIMEOUT; i++) begin
    @(negedge axi.aclk);
    if (axi.wvalid && axi.wready) begin
      data.write = 1;
      data.wdelay = i;
      data.wdata = axi.wdata;
      data.wstrb = axi.wstrb;
      break;
    end
    @(posedge axi.aclk);
  end
endtask

task mon_b(ref uart_seq_item data);
  for (int i=0; i < TIMEOUT; i++) begin
    @(negedge axi.aclk);
    if (axi.bvalid && axi.bready) begin
      data.bdelay = i;
      data.bresp = axi.bresp;
    end
    @(posedge axi.aclk);
  end
endtask

task mon_write(ref uart_seq_item data);
  fork
    mon_aw(data);
    mon_w(data);
  join
  if (data.write) begin
    mon_b(data);
  end
endtask

task mon_ar(ref uart_seq_item data);
  for (int i=0; i < TIMEOUT; i++) begin
    @(negedge axi.aclk);
    if (axi.arvalid && axi.arready) begin
      data.read = 1;
      data.ardelay = i;
      data.araddr = axi.araddr;
      data.arprot = axi.arprot;
      break;
    end
    @(posedge axi.aclk);
  end
endtask

task mon_r(ref uart_seq_item data);
  for (int i=0; i < TIMEOUT; i++) begin
    @(negedge axi.aclk);
    if (axi.rvalid && axi.rready) begin
      data.rdelay = i;
      data.rdata = axi.rdata;
      data.rresp = axi.rresp;
    end
    @(posedge axi.aclk);
  end
endtask

task mon_read(ref uart_seq_item data);
  mon_ar(data);
  if (data.read) begin
    mon_r(data);
  end
endtask

endclass

`endif
