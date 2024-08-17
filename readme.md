# Specification

## Parameters
- Clock frequency: 50 MHz
- Baud rate: 9600 bps
- Data bits: 8
- Parity: None
- Stop bits: 1

## Inputs
- clk: System clock (50 MHz)
- rstn: Active low reset
- tx_start: Signal to start transmission
- rx: UART receive line
- tx_data: 8-bit data to be transmitted

## Outputs
- tx: UART transmit line
- rx_data: 8-bit received data
- rx_done: Signal indicating reception complete
- tx_done: Signal indicating transmission complete
- rx_busy: Signal indicating receiver is active
- tx_busy: Signal indicating transmitter is active
- rx_error: Signal indicating receive protocol eror

## Functionality
1. Transmitter:
- Idle state: Keep tx line high
- When tx_start is asserted, begin transmission of tx_data
- Generate proper start bit, 8 data bits, and stop bit
- Assert tx_done for one clock cycle when transmission is complete

2. Receiver:
- Continuously sample rx line
- Implement a 2-stage synchronizer to handle metastability on rx input
- Detect start bit and begin data reception
- Sample rx line at mid-bit points to read data
- Assert rx_done for one clock cycle when full byte is received
- Output received byte on rx_data

3. Baud Rate Generator:
- Generate enable signals for transmitter and receiver to match 9600 bps rate


