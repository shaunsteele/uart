// uart_seq_item.sv

`ifndef __UART_SEQ_ITEM
`define __UART_SEQ_ITEM

class uart_seq_item extends uvm_sequence_item;

`uvm_object_utils(uart_seq_item)

// transaction types
rand bit write;
rand bit read;

// write address channel
rand int            awdelay;
rand type_t         awtype;
rand bit [ALEN-1:0] awaddr;
rand bit [2:0]      awprot;

// write data channel
rand int            wdelay;
rand bit [DLEN-1:0] wdata;
// rand type_t         wtype;
rand bit [SLEN-1:0] wstrb;

// write response channel
rand int            bdelay;
bit [1:0]           bresp;

// read address channel
rand int            ardelay;
rand type_t         artype;
rand bit [ALEN-1:0] araddr;
rand bit [2:0]      arprot;

// read data channel
rand int            rdelay;
bit [DLEN-1:0]      rdata;
bit [1:0]           rresp;

// constructor
function new(string name="uart_seq_item");
  super.new(name);
endfunction

// constraints
constraint rw_c {
  // write == 1 || read == 1;
  write == 1;
  read == 0;
}

constraint delay_c {
  awdelay inside {[0:1]};
  wdelay inside {[0:1]};
  bdelay inside {[0:1]};
  ardelay inside {[0:1]};
  rdelay inside {[0:1]};
}

constraint awaddr_c {
  // if (awtype == GOOD) awaddr == BASE_ADDR;
  // else awaddr != BASE_ADDR;
  awtype == GOOD;
  awaddr == BASE_ADDR;
}

constraint araddr_c {
  if (artype == GOOD) araddr inside {[BASE_ADDR:BASE_ADDR+1]};
  else !(araddr inside {[BASE_ADDR:BASE_ADDR+1]});
}

constraint wdata_c {
  wdata == 32'hAA;
}

constraint wstrb_c {
  wstrb == {(SLEN){1'b1}};
}

// functions
function string convert2string();
  string s;

  $sformat(s,"\nwrite: %b\tread: %b\n", write, read);

  if (write) begin
    $sformat(s,"%sawdelay:%01d\tawtype:\t%s\tawaddr:\t0x%08h\n", s, awdelay, awtype.name(), awaddr);
    $sformat(s,"%swdelay: %01d\twdata:\t0x%08h\twstrb:\t0b%04b\n", s, wdelay, wdata, wstrb);
    $sformat(s,"%sbdelay: %01d\tbresp:\t0b%02b\n", s, bdelay, bresp);
  end

  if (read) begin
    $sformat(s,"%sardelay: %01d\tartype:\t%s\taraddr:\t0x%08h\n", s, ardelay, artype.name(), araddr);
    $sformat(s,"%srdelay:  %01d\trdata:\t0x%08h\trresp:\t0b%02b\n", s, rdelay, rdata, rresp);
  end

  return s;
endfunction

function bit compare(uart_seq_item rhs);
  bit status = 1;

  if (this.write != rhs.write) begin
    status = 0;
    `uvm_info(get_full_name(), $sformatf("lhs.write = %b\trhs.write = %b", this.write, rhs.write), UVM_MEDIUM)
  end else if (this.awdelay != rhs.awdelay || this.awtype != rhs.awtype || this.awaddr != rhs.awaddr || this.awprot != rhs.awprot) begin
    status = 0;
    `uvm_info(get_full_name(), $sformatf("lhs.awdelay = %d\trhs.awdelay = %d", this.awdelay, rhs.awdelay), UVM_MEDIUM)
    `uvm_info(get_full_name(), $sformatf("lhs.awtype = %s\trhs.awtype = %s", this.awtype.name(), rhs.awtype.name()), UVM_MEDIUM)
    `uvm_info(get_full_name(), $sformatf("lhs.awaddr = 0x%08h\trhs.awaddr = %08h", this.awaddr, rhs.awaddr), UVM_MEDIUM)
    `uvm_info(get_full_name(), $sformatf("lhs.awprot = 0b%03b\trhs.awprot = 0b%03b", this.awprot, rhs.awprot), UVM_MEDIUM)
  end else if (this.wdelay != rhs.wdelay || this.wdata != rhs.wdata || this.wstrb != rhs.wstrb) begin
    status = 0;
    `uvm_info(get_full_name(), $sformatf("lhs.wdelay = %d\trhs.wdelay = %d", this.wdelay, rhs.wdelay), UVM_MEDIUM)
    `uvm_info(get_full_name(), $sformatf("lhs.wdata = 0x%08h\trhs.wdata = 0x%08h", this.wdata, rhs.wdata), UVM_MEDIUM)
    `uvm_info(get_full_name(), $sformatf("lhs.wstrb = 0b%04b\trhs.wstrb = 0b%04b", this.wdata, rhs.wdata), UVM_MEDIUM)
  end else if (this.bdelay != rhs.bdelay || this.bresp != rhs.bresp) begin
    status = 0;
    `uvm_info(get_full_name(), $sformatf("lhs.bdelay = %d\trhs.bdelay = %d", this.bdelay, rhs.bdelay), UVM_MEDIUM)
    `uvm_info(get_full_name(), $sformatf("lhs.bresp = 0b%02b\trhs.bresp = 0b%02b", this.bresp, rhs.bresp), UVM_MEDIUM)
  end else if (this.read != rhs.read) begin
    status = 0;
    `uvm_info(get_full_name(), $sformatf("lhs.read = %b\trhs.read = %b", this.read, rhs.read), UVM_MEDIUM)
  end else if (this.ardelay != rhs.ardelay || this.artype != rhs.artype || this.araddr != rhs.araddr || this.arprot != rhs.arprot) begin
    status = 0;
    `uvm_info(get_full_name(), $sformatf("lhs.ardelay = %d\trhs.ardelay = %d", this.ardelay, rhs.ardelay), UVM_MEDIUM)
    `uvm_info(get_full_name(), $sformatf("lhs.artype = %s\trhs.artype = %s", this.artype.name(), rhs.artype.name()), UVM_MEDIUM)
    `uvm_info(get_full_name(), $sformatf("lhs.araddr = 0x%08h\trhs.araddr = %08h", this.araddr, rhs.araddr), UVM_MEDIUM)
    `uvm_info(get_full_name(), $sformatf("lhs.arprot = 0b%03b\trhs.arprot = 0b%03b", this.arprot, rhs.arprot), UVM_MEDIUM)
  end else if (this.rdelay != rhs.rdelay || this.rdata != rhs.rdata || this.rresp != rhs.rresp) begin
    status = 0;
    `uvm_info(get_full_name(), $sformatf("lhs.rdelay = %d\trhs.rdelay = %d", this.rdelay, rhs.rdelay), UVM_MEDIUM)
    `uvm_info(get_full_name(), $sformatf("lhs.rdata = 0x%08h\trhs.rdata = 0x%08h", this.rdata, rhs.rdata), UVM_MEDIUM)
    `uvm_info(get_full_name(), $sformatf("lhs.rresp = 0b%02b\trhs.rresp = 0b%02b", this.rresp, rhs.rresp), UVM_MEDIUM)
  end
  return status;
endfunction

endclass

`endif
