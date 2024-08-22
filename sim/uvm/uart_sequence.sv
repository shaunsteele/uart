// uart_sequence.sv

`ifndef __UART_SEQUENCE
`define __UART_SEQUENCE

class uart_sequence extends uvm_sequence#(uart_seq_item);

`uvm_object_utils(uart_sequence)

function new(string name = "uart_sequence");
  super.new(name);
endfunction

virtual task body();
  repeat (1) begin
    req = uart_seq_item::type_id::create("req");
    // `uvm_info(get_full_name, "Body - wait_for_grant()", UVM_LOW)
    wait_for_grant();
    // `uvm_info(get_full_name, "Body - randomizing", UVM_LOW)
    assert(req.randomize());
    // `uvm_info(get_full_name, "Body - send_request", UVM_LOW)
    send_request(req);
    // `uvm_info(get_full_name, "Body - wait_for_item_done", UVM_LOW)
    wait_for_item_done();
    // `uvm_info(get_full_name, "Body - item_done", UVM_LOW)
  end
endtask

endclass

`endif
