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
bit [1:0]      bresp;

// read address channel
rand int            ardelay;
rand type_t         artype;
rand bit [ALEN-1:0] araddr;
rand bit [2:0]      arprot;

// read data channel
rand int            rdelay;
bit [DLEN-1:0] rdata;
bit [1:0]      rresp;

// constructor
function new(string name="uart_seq_item");
  super.new(name);
endfunction

// constraints
constraint rw_c {
  write == 1 || read == 1;
}

constraint delay_c {
  awdelay inside {[0:1]};
  wdelay inside {[0:1]};
  bdelay inside {[0:1]};
  ardelay inside {[0:1]};
  rdelay inside {[0:1]};
}

constraint awaddr_c {
  if (awtype == GOOD) awaddr == BASE_ADDR;
  else awaddr != BASE_ADDR;
}

constraint araddr_c {
  if (artype == GOOD) araddr inside {[BASE_ADDR:BASE_ADDR+1]};
  else !(araddr inside {[BASE_ADDR:BASE_ADDR+1]});
}

constraint wstrb_c {
  wstrb == {(SLEN){1'b1}};
}

// functions
function string convert2string();
  string s;

  $sformat(s,"write: %b\tread: %b\n", write, read);

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

endclass

`endif
