# tb_uart_controller.py
# write tests:
#   - basic valid write
#   - invalid address
#   - invalid strobe
#   - delay aw
#   - delay w
# read tests:
#   -

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge, RisingEdge, Combine


async def write_aw(dut, addr, delay=0):
    for _ in range(delay):
        await FallingEdge(dut.clk)
    assert dut.o_axi_awready.value
    dut.i_axi_awvalid.value = 1
    dut.i_axi_awaddr.value = addr

    while (dut.o_axi_awready.value == 0):
        await RisingEdge(dut.clk)
        await FallingEdge(dut.clk)

    await RisingEdge(dut.clk)
    await FallingEdge(dut.clk)
    dut.i_axi_awvalid.value = 0
    dut.i_axi_awaddr.value = 0

    await RisingEdge(dut.clk)


async def write_w(dut, data, strb=1, delay=0):
    for _ in range(delay):
        await FallingEdge(dut.clk)
    assert dut.o_axi_wready.value
    dut.i_axi_wvalid.value = 1
    dut.i_axi_wdata.value = data
    dut.i_axi_wstrb.value = (0x7 << 1) | strb

    while (dut.o_axi_wready.value == 0):
        await RisingEdge(dut.clk)
        await FallingEdge(dut.clk)

    await RisingEdge(dut.clk)
    await FallingEdge(dut.clk)
    dut.i_axi_wvalid.value = 0
    dut.i_axi_wdata.value = 0
    dut.i_axi_wstrb.value = 0

    await RisingEdge(dut.clk)


async def write_b(dut, resp=0b00):
    awdone = 0
    wdone = 0

    ct = 0
    while (not (awdone and wdone)):
        await FallingEdge(dut.clk)
        if (dut.i_axi_awvalid.value and dut.o_axi_awready.value):
            awdone = 1
        if (dut.i_axi_wvalid.value and dut.o_axi_wready.value):
            wdone = 1
        ct += 1
        # if (ct > 5):
        #     cocotb.log.error(f"write_b timeout - awdone: {awdone} wdone: {wdone}")
        #     quit(1)

    dut.i_axi_bready.value = 1

    while (dut.o_axi_bvalid.value == 0):
        await RisingEdge(dut.clk)
        await FallingEdge(dut.clk)
    assert resp == dut.o_axi_bresp.value

    await RisingEdge(dut.clk)
    await FallingEdge(dut.clk)
    dut.i_axi_bready.value = 0

    await RisingEdge(dut.clk)


async def write(dut, addr, data, strb=1, resp=0, ad=0, wd=0):
    await FallingEdge(dut.clk)
    aw = cocotb.start_soon(write_aw(dut, addr, ad))
    w = cocotb.start_soon(write_w(dut, data, strb, wd))
    b = cocotb.start_soon(write_b(dut, resp))

    await Combine(aw, w)
    await FallingEdge(dut.clk)
    if ((addr == dut.UART_ADDR.value) and strb):
        assert dut.o_txb_tvalid.value
        assert dut.o_txb_tdata.value == data

    await b
    await RisingEdge(dut.clk)


@cocotb.test()
async def tb_uart_controller(dut):
    cocotb.log.info(f"AXI_ALEN: {dut.AXI_ALEN.value}")
    cocotb.log.info(f"AXI_DLEN: {dut.AXI_DLEN.value}")
    cocotb.log.info(f"AXI_SLEN: {dut.AXI_SLEN.value}")
    cocotb.log.info(f"UART_DLEN: {dut.UART_DLEN.value}")
    cocotb.log.info(f"UART_ADDR: {dut.UART_ADDR.value}")

    dut.rstn.value = 0
    dut.i_axi_awvalid.value = 0
    dut.i_axi_awaddr.value = 0
    dut.i_axi_wvalid.value = 0
    dut.i_axi_wdata.value = 0
    dut.i_axi_wstrb.value = 0
    dut.i_axi_bready.value = 0
    dut.i_txb_tready.value = 0
    dut.i_txb_overflow.value = 0

    cocotb.start_soon(Clock(dut.clk, 10, "ns").start())

    await ClockCycles(dut.clk, 10)
    await FallingEdge(dut.clk)
    dut.rstn.value = 1

    await RisingEdge(dut.clk)
    await FallingEdge(dut.clk)
    dut.i_txb_tready.value = 1

    await RisingEdge(dut.clk)

    # non delayed transaction
    await write(dut, 0, 0x00)
    await write(dut, 1, 0x11, resp=0b11)
    await write(dut, 0, 0x22, strb=0, resp=0b10)

    # delayed address transaction
    await write(dut, 0, 0x33, ad=1)
    await write(dut, 1, 0x44, ad=1, resp=0b11)
    await write(dut, 0, 0x55, ad=1, strb=0, resp=0b10)
    await write(dut, 0, 0x66, ad=2)
    await write(dut, 1, 0x77, ad=2, resp=0b11)
    await write(dut, 0, 0x88, ad=2, strb=0, resp=0b10)

    # delayed address transaction
    await write(dut, 0, 0x99, wd=1)
    await write(dut, 1, 0xAA, wd=1, resp=0b11)
    await write(dut, 0, 0xBB, wd=1, strb=0, resp=0b10)
    await write(dut, 0, 0xCC, wd=2)
    await write(dut, 1, 0xDD, wd=2, resp=0b11)
    await write(dut, 0, 0xEE, wd=2, strb=0, resp=0b10)

    await ClockCycles(dut.clk, 10)
