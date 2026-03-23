// s_axi_lite_read_mm.sv

`default_nettype none

module s_axi_lite_mm_read # (
    parameter int   ADDR_WIDTH  = 32,
    parameter int   DATA_WIDTH  = 32
)(
    input   var logic                       s_axi_aclk,
    input   var logic                       s_axi_aresetn,

    input   var logic                       s_axi_arvalid,
    output  var logic                       s_axi_arready,
    input   var logic   [ADDR_WIDTH-1:0]    s_axi_araddr,

    output  var logic                       s_axi_rvalid,
    input   var logic                       s_axi_rready,
    output  var logic   [DATA_WIDTH-1:0]    s_axi_rdata,
    output  var logic   [1:0]               s_axi_rresp,

    output  var logic                       o_re,
    output  var logic   [ADDR_WIDTH-1:0]    o_raddr,
    input   var logic   [DATA_WIDTH-1:0]    i_rdata,
    input   var logic                       i_raddr_invalid
);

// constants
localparam bit [1:0]    RespOkay    = 2'b00;
localparam bit [1:0]    RespSlvErr  = 2'b10;

// simplify common signals
logic rst_n;
assign rst_n = s_axi_aresetn;

logic clk;
assign clk = s_axi_aclk;

/* Read Process */
// state definitions
typedef enum logic [1:0] {
    RD_IDLE,
    RD_DATA
} rd_state_e;

// state machine register and logic signals
rd_state_e curr_rd_state;
rd_state_e next_rd_state;

// state machine output registers

// state machine output logic
logic       next_arready;
logic       next_rvalid;
logic [1:0] next_rresp;

// current state registering
always_ff @(posedge clk) begin
    if (!rst_n) begin
        s_axi_arready <= 0;
        s_axi_rvalid <= 0;
        s_axi_rresp <= RespOkay;
        curr_rd_state <= RD_IDLE;
    end else begin
        s_axi_arready <= next_arready;
        s_axi_rvalid <= next_rvalid;
        s_axi_rresp <= next_rresp;
        curr_rd_state <= next_rd_state;
    end
end

// next state logic
always_comb begin
    next_arready = 1;
    next_rvalid = 0;
    next_rresp = RespOkay;
    next_rd_state = curr_rd_state;

    unique case (curr_rd_state)
        default: begin
            next_rd_state = RD_IDLE;
        end

        RD_IDLE: begin
            next_arready = ~s_axi_arvalid;
            next_rvalid = s_axi_arvalid;
            if (s_axi_arvalid) begin
                next_rd_state = RD_DATA;
            end
        end

        RD_DATA: begin
            next_arready = 0;
            if (i_raddr_invalid) begin
                next_rresp = RespSlvErr;
            end
            if (s_axi_rready) begin
                next_rvalid = 0;
                next_rd_state = RD_IDLE;
            end
        end
    endcase
end

always_comb begin
    o_re = s_axi_arvalid && s_axi_arready;
end

assign o_raddr = s_axi_araddr;
assign s_axi_rdata = i_rdata;

endmodule
