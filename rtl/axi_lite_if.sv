// axi_lite_if.sv

`default_nettype none

interface axi_lite_if # (
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    parameter int STRB_WIDTH = DATA_WIDTH / 8
)(
    input   var logic   aclk,
    input   var logic   aresetn
);


// write address channel
logic                       awvalid;
logic                       awready;
logic   [ADDR_WIDTH-1:0]    awaddr;
logic   [2:0]               awprot;


// write data channel
logic                       wvalid;
logic                       wready;
logic   [DATA_WIDTH-1:0]    wdata;
logic   [STRB_WIDTH-1:0]    wstrb;


// write response channel
logic                       bvalid;
logic                       bready;
logic   [1:0]               bresp;


// read address channel
logic                       arvalid;
logic                       arready;
logic   [ADDR_WIDTH-1:0]    araddr;
logic   [2:0]               arprot;


// read data channel
logic                       rvalid;
logic                       rready;
logic   [DATA_WIDTH-1:0]    rdata;
logic   [1:0]               rresp;


// modports
modport master (
    input   aclk, aresetn,

    output  awvalid, awaddr, awprot,
    input   awready,

    output  wvalid, wdata, wstrb,
    input   wready,

    input   bvalid, bresp,
    output  bready,

    output  arvalid, araddr, arprot,
    input   arready,

    input   rvalid, rdata, rresp,
    output  rready
);

modport slave (
    input   aclk, aresetn,

    input   awvalid, awaddr, awprot,
    output  awready,

    input   wvalid, wdata, wstrb,
    output  wready,

    output  bvalid, bresp,
    input   bready,

    input   arvalid, araddr, arprot,
    output  arready,

    output  rvalid, rdata, rresp,
    input   rready
);


endinterface
