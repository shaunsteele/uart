// s_axi_lite_mm.sv

`default_nettype none

module s_axi_lite_mm # (
    parameter int   ADDR_WIDTH  = 32,
    parameter int   DATA_WIDTH  = 32,
    parameter int   STRB_WIDTH  = DATA_WIDTH / 8
)(
    axi_lite_if.slave   s_axi,

    output  logic                       o_we,
    output  logic   [ADDR_WIDTH-1:0]    o_waddr,
    output  logic   [DATA_WIDTH-1:0]    o_wdata,

    output  logic                       o_re,
    output  logic   [ADDR_WIDTH-1:0]    o_raddr,
    input   logic   [DATA_WIDTH-1:0]    i_rdata
);

endmodule
