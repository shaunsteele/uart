# tb_uart_controller.py

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge, RisingEdge


@cocotb.test()
async def tb_uart_controller(dut):
    cocotb.log.info(f"BAUD: {dut.BAUD.value}")
    cocotb.log.info(f"CLKF: {dut.CLKF.value}")
    cocotb.log.info(f"DLEN: {dut.DLEN.value}")

    dut.rstn.value = 0

    cocotb.start_soon(Clock(dut.clk, 10, "ns").start())

    await ClockCycles(dut.clk, 10)
    await FallingEdge(dut.clk)
    dut.rstn.value = 1

    await ClockCycles(dut.clk, 10)
