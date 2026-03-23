// axi_lite_uart.v

`default_nettype none

module axi_lite_uart #(
    parameter integer AXI_ADDR_WIDTH       = 32,
    parameter integer AXI_DATA_WIDTH       = 32,
    parameter integer UART_DATA_WIDTH      = 8,
    parameter integer UART_DVSR_WIDTH      = 11,
    parameter integer UART_SAMPLE_RATE     = 16,
    parameter integer UART_FIFO_ADDR_WIDTH = 8
) (
    /* AXI-Lite Slave Interface */
    // System Signals
    input wire s_axi_aclk,
    input wire s_axi_aresetn,

    // Write Address Channel
    input  wire                      s_axi_awvalid,
    output wire                      s_axi_awready,
    input  wire [AXI_ADDR_WIDTH-1:0] s_axi_awaddr,

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

    // Read Data Channel
    output wire                      s_axi_rvalid,
    input  wire                      s_axi_rready,
    output wire [AXI_DATA_WIDTH-1:0] s_axi_rdata,
    output wire [               1:0] s_axi_rresp,

    /* UART Physical Interface */
    input  wire uart_rxd,
    output wire uart_txd
);

  wire cs_uart_rxd;

  cdc_sync #(
      .REGS(2),
      .INIT(0)
  ) u_CS (
      .clk(s_axi_aclk),
      .i_d(uart_rxd),
      .o_q(cs_uart_rxd)
  );

  // u_MM outputs
  wire                      mm_we;
  wire [AXI_ADDR_WIDTH-1:0] mm_waddr;
  wire [AXI_DATA_WIDTH-1:0] mm_wdata;
  wire                      mm_re;
  wire [AXI_ADDR_WIDTH-1:0] mm_raddr;

  // u_MM inptus
  wire                      rm_waddr_invalid;
  wire [AXI_DATA_WIDTH-1:0] rm_rdata;
  wire                      rm_raddr_invalid;

  s_axi_lite_mm #(
      .ADDR_WIDTH(32),
      .DATA_WIDTH(32)
  ) u_MM (
      .s_axi_aclk     (s_axi_aclk),
      .s_axi_aresetn  (s_axi_aresetn),
      .s_axi_awvalid  (s_axi_awvalid),
      .s_axi_awready  (s_axi_awready),
      .s_axi_awaddr   (s_axi_awaddr),
      .s_axi_wvalid   (s_axi_wvalid),
      .s_axi_wready   (s_axi_wready),
      .s_axi_wdata    (s_axi_wdata),
      .s_axi_wstrb    (s_axi_wstrb),
      .s_axi_bvalid   (s_axi_bvalid),
      .s_axi_bready   (s_axi_bready),
      .s_axi_bresp    (s_axi_bresp),
      .s_axi_arvalid  (s_axi_arvalid),
      .s_axi_arready  (s_axi_arready),
      .s_axi_araddr   (s_axi_araddr),
      .s_axi_rvalid   (s_axi_rvalid),
      .s_axi_rready   (s_axi_rready),
      .s_axi_rdata    (s_axi_rdata),
      .s_axi_rresp    (s_axi_rresp),
      .o_we           (mm_we),
      .o_waddr        (mm_waddr),
      .o_wdata        (mm_wdata),
      .i_waddr_invalid(rm_waddr_invalid),
      .o_re           (mm_re),
      .o_raddr        (mm_raddr),
      .i_rdata        (rm_rdata),
      .i_raddr_invalid(rm_raddr_invalid)
  );


  // u_RM outputs
  wire [UART_DVSR_WIDTH-1:0] rm_divisor;
  wire                       rm_tx_we;
  wire [UART_DATA_WIDTH-1:0] rm_tx_wdata;
  wire                       rm_rx_re;

  // u_RM inputs
  wire                       uc_tx_wfull;
  wire [UART_DATA_WIDTH-1:0] uc_rx_rdata;
  wire                       uc_rx_rempty;

  uart_reg_map #(
      .IF_ADDR_WIDTH  (AXI_ADDR_WIDTH),
      .IF_DATA_WIDTH  (AXI_DATA_WIDTH),
      .MM_OFFSET_WIDTH(2),
      .UART_DATA_WIDTH(UART_DATA_WIDTH),
      .UART_DVSR_WIDTH(UART_DVSR_WIDTH)
  ) u_RM (
      .clk            (s_axi_aclk),
      .rst_n          (s_axi_aresetn),
      .i_we           (mm_we),
      .i_waddr        (mm_waddr),
      .i_wdata        (mm_wdata),
      .o_waddr_invalid(rm_waddr_invalid),
      .i_re           (mm_re),
      .i_raddr        (mm_raddr),
      .o_rdata        (rm_rdata),
      .o_raddr_invalid(rm_raddr_invalid),
      .o_divisor      (rm_divisor),
      .o_tx_we        (rm_tx_we),
      .o_tx_wdata     (rm_tx_wdata),
      .i_tx_wfull     (uc_tx_wfull),
      .o_rx_re        (rm_rx_re),
      .i_rx_rdata     (uc_rx_rdata),
      .i_rx_rempty    (uc_rx_rempty)
  );

  uart_core #(
      .DATA_WIDTH     (UART_DATA_WIDTH),
      .DVSR_WIDTH     (UART_DVSR_WIDTH),
      .SAMPLE_RATE    (UART_SAMPLE_RATE),
      .FIFO_ADDR_WIDTH(UART_FIFO_ADDR_WIDTH)
  ) u_UC (
      .clk        (s_axi_aclk),
      .rst_n      (s_axi_aresetn),
      .i_rx       (cs_uart_rxd),
      .o_tx       (uart_txd),
      .i_divisor  (rm_divisor),
      .i_tx_we    (rm_tx_we),
      .i_tx_wdata (rm_tx_wdata),
      .o_tx_wfull (uc_tx_wfull),
      .i_rx_re    (rm_rx_re),
      .o_rx_rdata (uc_rx_rdata),
      .o_rx_rempty(uc_rx_rempty)
  );

endmodule
