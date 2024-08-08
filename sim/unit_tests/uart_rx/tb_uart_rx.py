# tb_uart_rx.py

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge, RisingEdge


async def drive(dut, data):
    d = data
    baud = int(dut.CLKF.value / dut.BAUD.value)

    await FallingEdge(dut.clk)
    dut.i_rxs.value = 0

    for _ in range(dut.DLEN.value):
        await ClockCycles(dut.clk, baud)
        await FallingEdge(dut.clk)
        dut.i_rxs.value = d & 0x01
        d >>= 1

    await ClockCycles(dut.clk, baud)
    await FallingEdge(dut.clk)
    dut.i_rxs.value = 1

    await ClockCycles(dut.clk, baud)
    await RisingEdge(dut.clk)
    await FallingEdge(dut.clk)
    assert dut.o_tvalid.value
    assert dut.o_tdata.value == data


@cocotb.test()
async def tb_uart_rx(dut):
    cocotb.log.info(f"BAUD: {dut.BAUD.value}")
    cocotb.log.info(f"CLKF: {dut.CLKF.value}")
    cocotb.log.info(f"DLEN: {dut.DLEN.value}")

    dut.rstn.value = 0
    dut.i_rxs.value = 1
    dut.i_tready.value = 1

    cocotb.start_soon(Clock(dut.clk, 10, "ns").start())

    await ClockCycles(dut.clk, 10)
    await FallingEdge(dut.clk)
    dut.rstn.value = 1

    await RisingEdge(dut.clk)
    await FallingEdge(dut.clk)
    assert dut.o_tvalid.value == 0

    await drive(dut, 0x55)
    await drive(dut, 0x00)
    await drive(dut, 0xFF)
    await drive(dut, 0xAA)

    await ClockCycles(dut.clk, 10)
