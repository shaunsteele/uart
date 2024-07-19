// wr_ptr.sv

`default_nettype none

module wr_ptr # (
  parameter int ALEN = 8,
  parameter int INCR = 1
)(
  input var                     clk,
  input var                     rstn,

  input var                     i_wen,
  output var logic  [ALEN-1:0]  o_waddr,
  output var logic  [ALEN:0]    o_wptr,
  input var         [ALEN:0]    i_rptr,
  output var logic              o_wfull,
  output var logic              o_woverflow,
  output var logic              o_ram_wen
);


// Write Pointer Increment Logic
logic [ALEN:0]  next_wptr;
always_comb begin
  next_wptr = o_wptr + INCR[ALEN:0];
end

// FIFO Full on next write
logic next_wfull;
always_comb begin
  next_wfull = {~next_wptr[ALEN], next_wptr[ALEN-1:0]} == i_rptr;
end

// Valid RAM Write Flag
always_comb begin
  o_ram_wen = i_wen & ~o_wfull;
end

// Next Pointer Logic
logic [ALEN:0]  wptr_d;
always_comb begin
  if (o_ram_wen) begin
    wptr_d = next_wptr;
  end else begin
    wptr_d = o_wptr;
  end
end

// Write Pointer Register
always_ff @(posedge clk) begin
  if (!rstn) begin
    o_wptr <= 0;
  end else begin
    o_wptr <= wptr_d;
  end
end

assign o_waddr = o_wptr[ALEN-1:0];

// Full Latch
always_ff @(posedge clk) begin
  if (!rstn) begin
    o_wfull <= 0;
  end else begin
    if (o_wfull) begin
      o_wfull <= i_rptr == {~o_wptr[ALEN], o_wptr[ALEN-1:0]};
    end else if (next_wfull) begin
      o_wfull <= i_wen;
    end else begin
      o_wfull <= o_wfull;
    end
  end
end

// Overflow Latch
always_ff @(posedge clk) begin
  if (!rstn) begin
    o_woverflow <= 0;
  end else begin
    if (i_wen & o_wfull) begin
      o_woverflow <= 1;
    end else begin
      o_woverflow <= o_woverflow;
    end
  end
end


endmodule
