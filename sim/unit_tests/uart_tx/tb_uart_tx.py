# tb_uart_tx.py

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge, RisingEdge


async def baud_test(dut, expected_bit):
    ct_limit = int(int(dut.CLKF.value) / int(dut.BAUD.value)) - 1
    ct = 0
    while (ct <= ct_limit):
        assert dut.o_txs.value == expected_bit
        assert dut.o_wready.value == 0
        await RisingEdge(dut.clk)
        await FallingEdge(dut.clk)
        ct += 1


async def write_test(dut, data):
    d = data
    assert dut.o_wready.value == 1
    dut.i_wvalid.value = 1
    dut.i_wdata.value = data

    await RisingEdge(dut.clk)
    await FallingEdge(dut.clk)
    dut.i_wvalid.value = 0
    dut.i_wdata.value = 0

    # start bit
    await baud_test(dut, 0)

    # data bits
    mask = 0x01
    for _ in range(int(dut.DLEN.value)):
        await baud_test(dut, d & mask)
        d >>= 1

    # parity bit
    if (dut.PARITY.value):
        await baud_test(dut, bool(bin(data).count('1') % 2))

    # stop bit
    await baud_test(dut, 1)


@cocotb.test()
async def tb_uart_tx(dut):
    cocotb.log.info(f"BAUD: {dut.BAUD.value}")
    cocotb.log.info(f"CLKF: {dut.CLKF.value}")
    cocotb.log.info(f"DLEN: {dut.DLEN.value}")

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

    await write_test(dut, 0x00)
    await write_test(dut, 0x7F)
    await write_test(dut, 0x55)
    await write_test(dut, 0x2A)
    await write_test(dut, 0x33)
    await write_test(dut, 0x4C)

    await ClockCycles(dut.clk, 10)
