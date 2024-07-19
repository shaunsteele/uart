// rd_ptr.sv

`default_nettype none

module rd_ptr # (
  parameter int ALEN = 8,
  parameter int INCR = 1
)(
  input var                     clk,
  input var                     rstn,

  input var                     i_ren,
  output var logic  [ALEN-1:0]  o_raddr,
  output var logic  [ALEN:0]    o_rptr,
  input var         [ALEN:0]    i_wptr,
  output var logic              o_rempty,
  output var logic              o_runderflow,
  output var logic              o_ram_ren
);

// Read Pointer Increment Logic
logic [ALEN:0]  next_rptr;
always_comb begin
  next_rptr = o_rptr + INCR[ALEN:0];
end

// FIFO Empty on next read
logic next_rempty;
always_comb begin
  next_rempty = next_rptr == i_wptr;
end

// Valid RAM Read Flag
always_comb begin
  o_ram_ren = i_ren & ~o_rempty;
end

// Next Read Pointer Logic
logic [ALEN:0]  rptr_d;
always_comb begin
  if (o_ram_ren) begin
    rptr_d = o_rptr + INCR[ALEN-1:0];
  end else begin
    rptr_d = o_rptr;
  end
end

// Read Pointer Register
always_ff @(posedge clk) begin
  if (!rstn) begin
    o_rptr <= 0;
  end else begin
    o_rptr <= rptr_d;
  end
end

assign o_raddr = o_rptr[ALEN-1:0];

// Empty Logic
always_ff @(posedge clk) begin
  if (!rstn) begin
    o_rempty <= 1;
  end else begin
    if (o_rempty) begin
      o_rempty <= i_wptr == o_rptr;
    end else begin
      o_rempty <= next_rempty & i_ren;
    end
  end
end

// Underflow Latch
always_ff @(posedge clk) begin
  if (!rstn) begin
    o_runderflow <= 0;
  end else begin
    if (i_ren & o_rempty) begin
      o_runderflow <= 1;
    end else begin
      o_runderflow <= o_runderflow;
    end
  end
end


endmodule
