// fifo.sv

`default_nettype none

module fifo # (
  parameter int ALEN = 8,
  parameter int DLEN = 8,
  parameter int INCR = 1
)(
  input var                     clk,
  input var                     rstn,

  input var                     i_wen,
  input var         [DLEN-1:0]  i_wdata,
  output var logic              o_wfull,
  output var logic              o_woverflow,

  input var                     i_ren,
  output var logic  [DLEN-1:0]  o_rdata,
  output var logic              o_rempty,
  output var logic              o_runderflow
);

/* Pointer Instantiations */
logic [ALEN-1:0]  waddr;
logic [ALEN:0]    wptr;
logic [ALEN-1:0]  raddr;
logic [ALEN:0]    rptr;

// Write Pointer
logic ram_wen;
wr_ptr # (
  .ALEN (ALEN),
  .INCR (INCR)
) u_WR (
  .clk          (clk),
  .rstn         (rstn),
  .i_wen        (i_wen),
  .o_waddr      (waddr),
  .o_wptr       (wptr),
  .i_rptr       (rptr),
  .o_wfull      (o_wfull),
  .o_woverflow  (o_woverflow),
  .o_ram_wen    (ram_wen)
);

// Read Pointer
logic ram_ren;
rd_ptr # (
  .ALEN (ALEN),
  .INCR (INCR)
) u_RD (
  .clk          (clk),
  .rstn         (rstn),
  .i_ren        (i_ren),
  .o_raddr      (raddr),
  .o_rptr       (rptr),
  .i_wptr       (wptr),
  .o_rempty     (o_rempty),
  .o_runderflow (o_runderflow),
  .o_ram_ren    (ram_ren)
);

/* Memory Instantiation */
sp_ram # (
  .DLEN (DLEN),
  .ALEN (ALEN)
) u_RAM (
  .clk      (clk),
  .rstn     (rstn),
  .i_wen    (ram_wen),
  .i_waddr  (waddr),
  .i_wdata  (i_wdata),
  .i_ren    (ram_ren),
  .i_raddr  (raddr),
  .o_rdata  (o_rdata)
);


endmodule
