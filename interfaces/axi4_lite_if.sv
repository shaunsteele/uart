// axi4_lite_if.sv

`default_nettype none

interface axi4_lite_if # (
  parameter int ALEN  = 32,
  parameter int DLEN  = 32,
  parameter int SLEN  = DLEN / 8
)(
  input var aclk,
  input var aresetn
);

// Write Address Channel
logic             awvalid;
logic             awready;
logic [ALEN-1:0]  awaddr;
logic [2:0]       awprot;

// Write Data Channel
logic             wvalid;
logic             wready;
logic [DLEN-1:0]  wdata;
logic [SLEN-1:0]  wstrb;

// Write Response Channel
logic             bvalid;
logic             bready;
logic [1:0]       bresp;

// Read Address Channel
logic             arvalid;
logic             arready;
logic [ALEN-1:0]  araddr;
logic [2:0]       arprot;

// Read Data Channel
logic             rvalid;
logic             rready;
logic [DLEN-1:0]  rdata;
logic [1:0]       rresp;

// Modports
modport M (
  input aclk, aresetn,
  output awvalid, awaddr, awprot, input awready,
  output wvalid, wdata, wstrb, input wready,
  output bready, input bvalid, bresp,
  output arvalid, araddr, arprot, input arready,
  output rready, input rvalid, rdata, rresp
);

modport S (
  input aclk, aresetn,
  input awvalid, awaddr, awprot, output awready,
  input wvalid, wdata, wstrb, output wready,
  input bready, output bvalid, bresp,
  input arvalid, araddr, arprot, output arready,
  input rready, output rvalid, rdata, rresp
);

modport M_DRV (
  input aclk, aresetn,
  output awvalid, awaddr, awprot, input awready,
  output wvalid, wdata, wstrb, input wready,
  output bready, input bvalid, bresp,
  output arvalid, araddr, arprot, input arready,
  output rready, input rvalid, rdata, rresp
);

modport S_DRV (
  input aclk, input aresetn,
  input awvalid, awaddr, awprot, output awready,
  input wvalid, wdata, wstrb, output wready,
  input bready, output bvalid, bresp,
  input arvalid, araddr, arprot, output arready,
  input rready, output rvalid, rdata, rresp
);

modport MON (
  input aclk, aresetn,
  input awvalid, awaddr, awprot, awready,
  input wvalid, wdata, wstrb, wready,
  input bready, bvalid, bresp,
  input arvalid, araddr, arprot, arready,
  input rready, rvalid, rdata, rresp
);

endinterface
