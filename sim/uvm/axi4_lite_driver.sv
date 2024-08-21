// axi4_lite_driver.sv

`ifndef __AXI4_LITE_DRIVER
`define __AXI4_LITE_DRIVER

class axi4_lite_driver extends uvm_driver#(uart_seq_item);

`uvm_component_utils(axi4_lite_driver)

virtual axi4_lite_if axi;

function new(string name, uvm_component parent);
  super.new(name, parent);
endfunction

virtual function void build_phase(uvm_phase phase);
  super.build_phase(phase);
  if (!uvm_config_db #(virtual axi4_lite_if)::get(this, "", "axi", axi))
    `uvm_fatal(get_type_name(), "Didn't get handle to virtual interface axi")
endfunction

virtual task run_phase(uvm_phase phase);
  uart_seq_item req;
  forever begin
    seq_item_port.get_next_item(req);

    fork
      if (req.write) begin
        write_address(req);
        write_data(req);
        write_resp(req);
      end

      if (req.read) begin
        read_address(req);
        read_data(req);
      end
    join

    seq_item_port.item_done();
  end
endtask

task write_address(uart_seq_item req);
  repeat (req.awdelay) @(posedge axi.aclk);
  @(negedge axi.aclk);
  axi.awvalid <= 1;
  axi.awaddr <= req.awaddr;
  axi.awprot <= req.awprot;

  while (!axi.awready) begin
    @(posedge axi.aclk);
  end
  @(negedge axi.aclk);
  axi.awvalid <= 0;
endtask

task write_data(uart_seq_item req);
  repeat (req.wdelay) @(posedge axi.aclk);
  @(negedge axi.aclk);
  axi.wvalid <= 1;
  axi.wdata <= req.wdata;
  axi.wstrb <= req.wstrb;

  while (!axi.wready) begin
    @(posedge axi.aclk);
  end
  @(negedge axi.aclk);
  axi.wvalid <= 0;
endtask

task write_resp(uart_seq_item req);
  repeat (req.bdelay) @(posedge axi.aclk);
  @(negedge axi.aclk);
  axi.bready <= 1;

  while (!axi.bvalid) begin
    @(posedge axi.aclk);
  end
  @(negedge axi.aclk);
  axi.bready <= 0;
endtask

task read_address(uart_seq_item req);
  repeat (req.ardelay) @(posedge axi.aclk);
  @(negedge axi.aclk);
  axi.arvalid <= 1;
  axi.araddr <= req.araddr;
  axi.arprot <= req.arprot;

  while (!axi.arready) begin
    @(posedge axi.aclk);
  end
  @(negedge axi.aclk);
  axi.arvalid <= 0;
endtask

task read_data(uart_seq_item req);
  repeat (req.rdelay) @(posedge axi.aclk);
  @(negedge axi.aclk);
  axi.rready <= 1;

  while (!axi.rvalid) begin
    @(posedge axi.aclk);
  end
  @(negedge axi.aclk);
  axi.rready <= 0;
endtask

endclass

`endif
