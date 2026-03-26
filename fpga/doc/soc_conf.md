# NeuroSoC SoC configuration notes

## Memory mapping

| **Device**  | **Base addr.** |    **Length** |
|-------------|----------------|---------------|
| Debug       |    0x00000000  |       0x1000  |
| ROM         |    0x00010000  |      0x10000  |
| CLINT       |    0x02000000  |      0xC0000  |
| PLIC        |    0x0C000000  |    0x3FFFFFF  |
| Timer       |    0x10000000  |       0x1000  |
| SPI         |    0x20000000  |     0x800000  |
| Ethernet    |    0x30000000  |      0x10000  |
| GPIO        |    0x40000000  |       0x1000  |
| UART        |    0x50000000  |       0x1000  |
| DRAM        |    0x80000000  |   0x40000000  |

## Interrupts mapping

The following describe the interrupts mapping in the PLIC as provided in the
FPGA design of the NeuroSoC SoC.

### Input interrupts

- `3:0`: timer
- `4`: UART
- `5`: SPI
- `6`: Ethernet
- `7`: DCLS error signal (**to be removed**)

### Output interrupts

Dual-core configuration:

- `1:0`: interrupts to core 0
- `3:2`: interrupts to core 1

Lockstep configuration:

- `1:0`: interrupts to core 0 and core 1 (the later working in lockstep)
- `3:2`: disconnected

## DCLS error signal

Currently the DCLS error signal is connected as interrupt into the PLIC port 7
(see previous section).
In a final design this should be mapped to an output pin of the SoC.