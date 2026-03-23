// s_axi_lite_mm.sv

`default_nettype none

module s_axi_lite_mm # (
    parameter int   ADDR_WIDTH  = 32,
    parameter int   DATA_WIDTH  = 32,
    parameter int   STRB_WIDTH  = DATA_WIDTH / 8
)(
    input   var logic                       s_axi_aclk,
    input   var logic                       s_axi_aresetn,

    input   var logic                       s_axi_awvalid,
    output  var logic                       s_axi_awready,
    input   var logic   [ADDR_WIDTH-1:0]    s_axi_awaddr,

    input   var logic                       s_axi_wvalid,
    output  var logic                       s_axi_wready,
    input   var logic   [DATA_WIDTH-1:0]    s_axi_wdata,
    input   var logic   [STRB_WIDTH-1:0]    s_axi_wstrb,

    output  var logic                       s_axi_bvalid,
    input   var logic                       s_axi_bready,
    output  var logic   [1:0]               s_axi_bresp,

    input   var logic                       s_axi_arvalid,
    output  var logic                       s_axi_arready,
    input   var logic   [ADDR_WIDTH-1:0]    s_axi_araddr,

    output  var logic                       s_axi_rvalid,
    input   var logic                       s_axi_rready,
    output  var logic   [DATA_WIDTH-1:0]    s_axi_rdata,
    output  var logic   [1:0]               s_axi_rresp,

    output  var logic                       o_we,
    output  var logic   [ADDR_WIDTH-1:0]    o_waddr,
    output  var logic   [DATA_WIDTH-1:0]    o_wdata,
    input   var logic                       i_waddr_invalid,

    output  var logic                       o_re,
    output  var logic   [ADDR_WIDTH-1:0]    o_raddr,
    input   var logic   [DATA_WIDTH-1:0]    i_rdata,
    input   var logic                       i_raddr_invalid
);


s_axi_lite_mm_write # (
    .ADDR_WIDTH (ADDR_WIDTH),
    .DATA_WIDTH (DATA_WIDTH)
) u_WR (
    .s_axi_aclk         (s_axi_aclk),
    .s_axi_aresetn      (s_axi_aresetn),
    .s_axi_awvalid      (s_axi_awvalid),
    .s_axi_awready      (s_axi_awready),
    .s_axi_awaddr       (s_axi_awaddr),
    .s_axi_wvalid       (s_axi_wvalid),
    .s_axi_wready       (s_axi_wready),
    .s_axi_wdata        (s_axi_wdata),
    .s_axi_wstrb        (s_axi_wstrb),
    .s_axi_bvalid       (s_axi_bvalid),
    .s_axi_bready       (s_axi_bready),
    .s_axi_bresp        (s_axi_bresp),
    .o_we               (o_we),
    .o_waddr            (o_waddr),
    .o_wdata            (o_wdata),
    .i_waddr_invalid    (i_waddr_invalid)
);

s_axi_lite_mm_read # (
    .ADDR_WIDTH (ADDR_WIDTH),
    .DATA_WIDTH (DATA_WIDTH)
) u_RD (
    .s_axi_aclk         (s_axi_aclk),
    .s_axi_aresetn      (s_axi_aresetn),
    .s_axi_arvalid      (s_axi_arvalid),
    .s_axi_arready      (s_axi_arready),
    .s_axi_araddr       (s_axi_araddr),
    .s_axi_rvalid       (s_axi_rvalid),
    .s_axi_rready       (s_axi_rready),
    .s_axi_rdata        (s_axi_rdata),
    .s_axi_rresp        (s_axi_rresp),
    .o_re               (o_re),
    .o_raddr            (o_raddr),
    .i_rdata            (i_rdata),
    .i_raddr_invalid    (i_raddr_invalid)
);

endmodule
