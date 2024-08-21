// uart_sequence.sv

`ifndef __UART_SEQUENCE
`define __UART_SEQUENCE

class uart_sequence extends uvm_sequence#(uart_seq_item);

`uvm_object_utils(uart_sequence)

function new(string name = "uart_sequence");
  super.new(name);
endfunction

virtual task body();
  uart_seq_item req = uart_seq_item::type_id::create("req");
  wait_for_grant();
  assert(req.randomize());
  send_request(req);
  wait_for_item_done();
endtask


endclass

`endif
