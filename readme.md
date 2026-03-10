# Universal Asynchronous Receiver Transmitter (UART) Core

## Overview
AXI-Lite controlled UART core intended for logging information and debug messages to a serial terminal in other projects. Based on the UART design from the book FPGA Prototyping by Systemverilog Examples by Pong P. Chu.

## Features
- 32-bit AXI-Lite interface
- Programmable baud rate
- 8-bit word
- No parity bit

## Register Map
|  Offset | Access | Name               | Bit Fields|
|---------|--------|--------------------|-----------|
| 0       | R      | Read Data / Status | 9: transmit full, 8: receive empty, 7-0: receive data |
| 1       | W      | Baud Rate Divisor  | 10-0: 11-bit divisor value |
| 2       | W      | Write Data         | 7-0: 8-bit transmit data |
| 3       | W      | Read Data Removal  | Don't care|
