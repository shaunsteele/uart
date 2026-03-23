// s_axi_lite_mm_write.sv

`default_nettype none

module s_axi_lite_mm_write # (
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

    output  var logic                       o_we,
    output  var logic   [ADDR_WIDTH-1:0]    o_waddr,
    output  var logic   [DATA_WIDTH-1:0]    o_wdata,
    input   var logic                       i_waddr_invalid
);

// constants
localparam bit [1:0]    RespOkay    = 2'b00;
localparam bit [1:0]    RespSlvErr  = 2'b10;

// simplify common signals
logic rst_n;
assign rst_n = s_axi_aresetn;

/* Write Process */
// state definitions
typedef enum logic [4:0] {
    WR_IDLE,
    WR_ADDR_WAIT,
    WR_DATA_WAIT,
    WR_SEND,
    WR_RESP
} wr_state_e;

// state machine register and logic signals
wr_state_e curr_wr_state;
wr_state_e next_wr_state;

// state machine output registers
logic waddr_buf_sel;
logic wdata_buf_sel;

// state machine output logic
logic       next_awready;
logic       next_wready;
logic       next_bvalid;
logic [1:0] next_bresp;
logic       next_waddr_buf_sel;
logic       next_wdata_buf_sel;
logic       next_we;

// current state registering
always_ff @(posedge s_axi_aclk) begin
    if (!rst_n) begin
        s_axi_awready <= 0;
        s_axi_wready <= 0;
        s_axi_bvalid <= 0;
        s_axi_bresp <= RespOkay;
        waddr_buf_sel <= 0;
        wdata_buf_sel <= 0;
        curr_wr_state <= WR_IDLE;
        o_we <= 0;
    end else begin
        s_axi_awready <= next_awready;
        s_axi_wready <= next_wready;
        s_axi_bvalid <= next_bvalid;
        s_axi_bresp <= next_bresp;
        waddr_buf_sel <= next_waddr_buf_sel;
        wdata_buf_sel <= next_wdata_buf_sel;
        curr_wr_state <= next_wr_state;
        o_we <= next_we;
    end
end

// next state logic
always_comb begin
    next_awready = 1;
    next_wready = 1;
    next_bvalid = 0;
    next_bresp = RespOkay;
    next_waddr_buf_sel = 0;
    next_wdata_buf_sel = 0;
    next_wr_state = curr_wr_state;
    next_we = 0;

    unique case (curr_wr_state)
        default: begin
            next_wr_state = WR_IDLE;
        end

        WR_IDLE: begin
            unique case ({s_axi_awvalid, s_axi_wvalid})
                default: next_wr_state = curr_wr_state;
                2'b01: next_wr_state = WR_ADDR_WAIT;
                2'b10: next_wr_state = WR_DATA_WAIT;
                2'b11: next_wr_state = WR_SEND;
            endcase
        end

        WR_ADDR_WAIT: begin
            next_awready = 1;
            next_wready = 0;
            next_waddr_buf_sel = 0;
            if (s_axi_awvalid) begin
                next_wr_state = WR_SEND;
            end
        end

        WR_DATA_WAIT: begin
            next_awready = 0;
            next_wready = 1;
            next_wdata_buf_sel = 0;
            if (s_axi_wvalid) begin
                next_wr_state = WR_SEND;
            end
        end

        WR_SEND: begin
            next_awready = 0;
            next_wready = 0;
            next_bvalid = 1;
            next_wdata_buf_sel = wdata_buf_sel;
            if (s_axi_bready) begin
                next_wr_state = WR_IDLE;
            end else begin
                next_wr_state = WR_RESP;
            end
            next_we = 1;
        end

        WR_RESP: begin
            next_awready = s_axi_bready;
            next_wready = s_axi_bready;
            next_bvalid = ~s_axi_bready;
            if (i_waddr_invalid) begin
                next_bresp = RespSlvErr;
            end
            if (s_axi_bready) begin
                next_wr_state = WR_IDLE;
            end
        end
    endcase
end

// wstrb write mask
logic [DATA_WIDTH-1:0]  wstrb_mask;
always_comb begin
    for (int i = 0; i < STRB_WIDTH; i++) begin
        wstrb_mask[i*8 +: 8] = (s_axi_wstrb[i]) ? 8'hFF : 8'h00;
    end
end

// write channel buffer register
logic [ADDR_WIDTH-1:0]  waddr_buf;
logic [DATA_WIDTH-1:0]  wdata_buf;

always_ff @(posedge s_axi_aclk) begin
    if (s_axi_awvalid) begin
        waddr_buf <= s_axi_awaddr;
    end

    if (s_axi_wvalid) begin
        wdata_buf <= wstrb_mask & s_axi_wdata;
    end
end

// write channel output muxes
always_comb begin
    if (waddr_buf_sel) begin
        o_waddr = waddr_buf;
    end else begin
        o_waddr = s_axi_awaddr;
    end
    if (wdata_buf_sel) begin
        o_wdata = wdata_buf;
    end else begin
        o_wdata = s_axi_wdata;
    end
end


endmodule
