# tb_uart_tx.py

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge, RisingEdge


@cocotb.test()
async def tb_uart_tx(dut):
    dut.rstn.value = 0
    dut.i_wvalid.value = 0
    dut.i_wdata.value = 0

    cocotb.start_soon(Clock(dut.clk, 10, "ns").start())

    await ClockCycles(dut.clk, 10)
    await FallingEdge(dut.clk)
    dut.rstn.value = 1

    await RisingEdge(dut.clk)
    await FallingEdge(dut.clk)
    assert dut.o_txs.value
    assert dut.o_wready.value

    data = 0xAA
    dut.i_wvalid.value = 1
    dut.i_wdata.value = data

    await RisingEdge(dut.clk)
    await FallingEdge(dut.clk)
    while (dut.o_wready.value == 0):
        await RisingEdge(dut.clk)
        await FallingEdge(dut.clk)

    dut.i_wvalid.value = 0
    dut.i_wdata.value = 0

    await RisingEdge(dut.clk)
    await FallingEdge(dut.clk)

    ct_limit = int(dut.CLKF.value) / int(dut.BAUD.value)
    ct = 0
    while (ct < ct_limit):
        assert dut.o_txs.value == 0
        assert dut.o_wready.value == 0
        await RisingEdge(dut.clk)
        await FallingEdge(dut.clk)
        ct += 1

    ct = 0
    mask = (2 ** dut.DLEN.value) >> 1
    for _ in range(int(dut.DLEN.value)):
        bit = (data & mask) >> 7
        while (ct < ct_limit):
            assert dut.o_txs.value == bit
            assert dut.o_wready.value == 0
            await RisingEdge(dut.clk)
            await FallingEdge(dut.clk)
            ct += 1
        data <<= 1

    ct = 0
    while (ct < ct_limit):
        assert dut.o_txs.value == 1
        assert dut.o_wready.value == 0
        await RisingEdge(dut.clk)
        await FallingEdge(dut.clk)
        ct += 1

    await RisingEdge(dut.clk)
    await FallingEdge(dut.clk)
    await RisingEdge(dut.clk)
    await FallingEdge(dut.clk)
    assert dut.o_wready.value == 1

    await ClockCycles(dut.clk, 10)
