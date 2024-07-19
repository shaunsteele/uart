AXI UART Transceiver

Description:
Simply writes 1 byte to transmitter, and reads 1 byte from receiver.

Modules:
- uart_tx: axi stream uart transmitter
- uart_rx: axi stream uart receiver
- rx_fifo: axi stream receiver buffer fifo
- uart_controller: axi lite controller
  - writes directly to uart tx
  - reads from rx fifo buffer
    - rx fifo buffer written from

controller
- write address channel
  - aw_en from valid awvalid and txb not full and correct awaddr
  - aw_en falls once load shifter started
  - awready from txb not full and txb_wen not busy
- write data channel
  - wen from wvalid and txb not full
  - wen falls once load shifter started
  - txb shifter loaded with wstrb
  - txb data loaded with wdata
  - txb