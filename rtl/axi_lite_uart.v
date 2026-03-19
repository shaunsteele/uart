// axi_lite_uart.v

`default_nettype none

module axi_lite_uart #(
    parameter integer AXI_ADDR_WIDTH       = 32,
    parameter integer AXI_DATA_WIDTH       = 32,
    parameter integer UART_DATA_WIDTH      = 8,
    parameter integer UART_DVSR_WIDTH      = 11,
    parameter integer UART_SAMPLE_RATE     = 16,
    parameter integer UART_FIFO_ADDR_WIDTH = 2
) (
    /* AXI-Lite Slave Interface */
    // System Signals
    input wire s_axi_aclk,
    input wire s_axi_aresetn,

    // Write Address Channel
    input  wire                      s_axi_awvalid,
    output wire                      s_axi_awready,
    input  wire [AXI_ADDR_WIDTH-1:0] s_axi_awaddr,
    input  wire [               2:0] s_axi_awprot,

    // Write Data Channel
    input  wire                            s_axi_wvalid,
    output wire                            s_axi_wready,
    input  wire [      AXI_DATA_WIDTH-1:0] s_axi_wdata,
    input  wire [((AXI_DATA_WIDTH)/8)-1:0] s_axi_wstrb,

    // Write Response Channel
    output wire       s_axi_bvalid,
    input  wire       s_axi_bready,
    output wire [1:0] s_axi_bresp,

    // Read Address Channel
    input  wire                      s_axi_arvalid,
    output wire                      s_axi_arready,
    input  wire [AXI_ADDR_WIDTH-1:0] s_axi_araddr,
    input  wire [               2:0] s_axi_arprot,

    // Read Data Channel
    output wire                      s_axi_rvalid,
    input  wire                      s_axi_rready,
    output wire [AXI_DATA_WIDTH-1:0] s_axi_rdata,
    output wire [               1:0] s_axi_rresp,

    /* UART Physical Interface */
    input  wire uart_rxd,
    output wire uart_txd
);


  s_axi_lite_mm #(
      .ADDR_WIDTH(32),
      .DATA_WIDTH(32)
  ) u_MM (
      .s_axi_aclk   (s_axi_aclk),
      .s_axi_aresetn(s_axi_aresetn),
      .s_axi_awvalid(s_axi_awvalid),
      .s_axi_awready(s_axi_awready),
      .s_axi_awaddr (s_axi_awaddr),
      .s_axi_awprot (s_axi_awprot),
      .s_axi_wvalid (s_axi_wvalid),
      .s_axi_wready (s_axi_wready),
      .s_axi_wdata  (s_axi_wdata),
      .s_axi_wstrb  (s_axi_wstrb),
      .s_axi_bvalid (s_axi_bvalid),
      .s_axi_bready (s_axi_bready),
      .s_axi_bresp  (s_axi_bresp),
      .s_axi_arvalid(s_axi_arvalid),
      .s_axi_arready(s_axi_arready),
      .s_axi_araddr (s_axi_araddr),
      .s_axi_arprot (s_axi_arprot),
      .s_axi_rvalid (s_axi_rvalid),
      .s_axi_rready (s_axi_rready),
      .s_axi_rdata  (s_axi_rdata),
      .s_axi_rresp  (s_axi_rresp),
      .o_we         (),
      .o_waddr      (),
      .o_wdata      (),
      .o_re         (),
      .o_raddr      (),
      .i_rdata      ()
  );


  uart_core #(
      .DATA_WIDTH     (UART_DATA_WIDTH),
      .DVSR_WIDTH     (UART_DVSR_WIDTH),
      .SAMPLE_RATE    (UART_SAMPLE_RATE),
      .FIFO_ADDR_WIDTH(UART_FIFO_ADDR_WIDTH)
  ) u_UC (
      .clk        (s_axi_aclk),
      .rst_n      (s_axi_aresetn),
      .i_rx       (uart_rxd),
      .o_tx       (uart_txd),
      .i_divisor  (),
      .i_tx_we    (),
      .i_tx_wdata (),
      .o_tx_wfull (),
      .i_rx_re    (),
      .o_rx_rdata (),
      .o_rx_rempty()
  );

endmodule
