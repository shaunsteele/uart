# tb_uart_rx.py

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge, RisingEdge, Timer


async def drive(dut, data):
    d = data

    dut.i_rxs.value = 0

    for _ in range(dut.DLEN.value):
        await Timer(1 / dut.BAUD.value, "sec")
        dut.i_rxs.value = d & 0x01
        d >>= 1

    await Timer(1 / dut.BAUD.value, "sec")
    dut.i_rxs.value = 1

    await Timer(1 / dut.BAUD.value, "sec")


@cocotb.test()
async def tb_uart_rx(dut):
    cocotb.log.info(f"BAUD: {dut.BAUD.value}")
    cocotb.log.info(f"CLKF: {dut.CLKF.value}")
    cocotb.log.info(f"DLEN: {dut.DLEN.value}")

    dut.rstn.value = 0
    dut.i_rxs.value = 1

    cocotb.start_soon(Clock(dut.clk, 10, "ns").start())

    await ClockCycles(dut.clk, 10)
    await FallingEdge(dut.clk)
    dut.rstn.value = 1

    await RisingEdge(dut.clk)
    await FallingEdge(dut.clk)
    assert dut.o_rvalid.value == 0

    await drive(dut, 0x55)

    await ClockCycles(dut.clk, 10)
