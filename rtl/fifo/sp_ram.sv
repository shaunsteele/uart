// sp_ram.sv

`default_nettype none

module sp_ram # (
  parameter int DLEN = 8,
  parameter int ALEN = 1
)(
  input var                     clk,
  input var                     rstn,

  input var                     i_wen,
  input var         [ALEN-1:0]  i_waddr,
  input var         [DLEN-1:0]  i_wdata,

  input var                     i_ren,
  input var         [ALEN-1:0]  i_raddr,
  output var logic  [DLEN-1:0]  o_rdata
);


logic [DLEN-1:0] ram[2 ** ALEN];

always_ff @(posedge clk) begin
  if (i_wen) begin
      ram[i_waddr[ALEN-1:0]] <= i_wdata[DLEN-1:0];
  end else begin
    ram[i_waddr] <= ram[i_waddr];
  end
end

always_ff @(posedge clk) begin
  if (!rstn) begin
    o_rdata <= 0;
  end else begin
    if (i_ren) begin
      o_rdata <= ram[i_raddr[ALEN-1:0]];
    end else begin
      o_rdata <= o_rdata;
    end
  end
end

endmodule
