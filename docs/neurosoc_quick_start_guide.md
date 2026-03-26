# Requirements

Refer to requirements on the
[`riscv-gnu-toolchain`](https://github.com/riscv/riscv-gnu-toolchain.git) and
[`openhwgroup/cva6` (version 5.0.1)](https://github.com/openhwgroup/cva6/tree/v5.0.1)
repositories.
For the latter you might ignore the simulation requirements and the emulation
target is as for the cva6 project the Genesys2 board.
The bitstream was generated with Vivado 2023.1.

# Quick start

Create an empty folder for your developments, we will name it the
`dcls-project`, and move inside:

```
$ mkdir dcls-project
$ cd dcls-project
```

A C compiler for the targetted architecture is required.
Currently the target is a CV32A6 sv32 with `imac` extensions.
To build the compiler first create a folder, move into it, clone the
[`riscv-gnu-toolchain`](https://github.com/riscv/riscv-gnu-toolchain.git) repository
and build it with the following commands:

```
$ mkdir cv32a6imac-gnu-toolchain
$ cd cv32a6imac-gnu-toolchain
$ git clone https://github.com/riscv/riscv-gnu-toolchain.git
$ cd riscv-gnu-toolchain
$ ./configure --prefix="`cd .. && pwd`" --with-arch=rv32imac --with-abi=ilp32
$ make
```

The above commands should have created the compiler in the `dcls-project/cv32a6imac-gnu-toolchain/bin` folder, look for `riscv32-unknown-elf-gcc`.

Now clone the `neurosoc/core-block` repository (this repository) inside the
`dcls-project` folder, so you have the repository cloned in the
`dcls-project/core-block` folder, and checkout the `feature-fpga` branch with
the following commands:

```
$ cd <path_to_dcls-project>
$ git clone https://git.s3g-labs.fr/trt-fr-lsec/projects/neurosoc/core-block.git
$ cd core-block
$ git checkout feature-fpga
$ git submodule update --init --recursive
```

You can build a bitstream for FPGA (Genesys2) using the Makefile in the `dcls-project/core-block/fpga` folder with the following commands:

```
$ cd <path_to_dcls-project/core-block/fpga>
$ make fpga \
  target=cv32a6_imac_sv32 \
  apu_target=neurosoc_apu_1dcls_ls \
  RISCV=<path_to_dcls-project/cv32a6imac-gnu-toolchain>
```

The produced bitstream is named `neurosoc_xilinx.mcs` and it is available in the `dcls-project/core-block/fpga/work-fpga` folder.

# Host core tile

The host core tile embeds the a dual core (or multiple dual cores) configurable 
through a signal to work as a lockstep core (or as multiple lockstep cores) and
some basic core "peripherals" (a debug, a boot rom, a CLINT, a PLIC,
and a timer modules).
The host core tile is to be connected to the system bus.
The host core tile has as many bus master interfaces as cores it is configured
with, but typically it will be provide just two bus master interfaces when
configured to NeuroSoC requirements (i.e. dual core).
The host core tile has a single bust slave interface.

The host core tile provides the following interface:

```
neurosoc_host_core_tile #(
  .CVA6_CFG            ( ),
  .NUM_DCLS            ( ),
  .BOOT_ADDR           ( ),
  .AXI_ID_WIDTH_SLAVE  ( ),
  .NUM_IRQ_SOURCES     ( ),
  .SUPPORT_BASE        ( ),
  .SYSTEM_BASE         ( ),
  .SYSTEM_LENGTH       ( ),
  .rvfi_probes_instr_t ( ),
  .rvfi_probes_csr_t   ( ),
  .rvfi_probes_t       ( )
) i_neurosoc_host_core_tile (
  .clk_i             ( ),
  .rst_ni            ( ),
  .jtag_TCK_i        ( ),
  .jtag_TMS_i        ( ),
  .jtag_TDI_i        ( ),
  .jtag_TRST_ni      ( ),
  .jtag_TDO_data_o   ( ),
  .jtag_TDO_driven_o ( ),
  .irq_i             ( ),
  .ndmreset_o        ( ),
  .ndmreset_ni       ( ),
  .rvfi_probes_o     ( ),
  .dcls_mode_i       ( ),
  .dcls_error_o      ( ),
  .ext_slave_bus     ( ),
  .ext_master_bus    ( )
);
```

The host core tile module parameters are:

- `CVA6_CFG`: provides the CVA6 cores configuration, refer to CVA6 project for
  the configuration options.
- `NUM_DCLS`: the host core tile can be configured as a dual core
  (`NUM_DCLS = 1`) or as multiple dual cores (`NUM_DCLS = X` with `X` bigger
  than 1, provides `X*2` cores).
  The host core tile design has only been validated as a dual core (i.e.
  `NUM_DCLS = 1`), so this configuration should be used.
- `AXI_ID_WIDTH_SLAVE`: Id width for slave connections to the system bus.
- `NUM_IRQ_SOURCES`: Number of irq sources that will be feed into the host core
  tile.
- `SUPPORT_BASE`: Address at which the host core tile peripherals should be
  mapped.
- `SYSTEM_BASE`: Base address of peripherals and memory connected to the system
  bus.
- `SYSTEM_LENGTH`: Memory address size of all the peripherals and memory
  connected to the system bus.
  `SYSTEM_BASE + SYSTEM_LENGTH` should cover all the addressable space of
  peripherals and memory connected to the system bus.
- `rvfi_probes_instr_t`, `rvfi_probes_csr_t` and `rvfi_probes_t`: configuration
  for the formal verification capabilities of the CVA6 cores.
  Use the same parameters than defined in `dcls_soc.sv` file.

The host core tile module connections are as follows:

- `clk_i`: input clock signal.
- `rst_ni`: reset signal negated.
- `jtag_*`: JTAG input and output signals.
- `irq_i`: input logic array with the irq signals of any peripheral connected
  to the system bus.
  Its length should be equal to the `NUM_IRQ_SOURCES` parameters.
- `ndmreset_o`: output reset signal as generated by the host core tile.
- `ndmreset_ni`: input reset signal derived from the the `ndmreset_o` signal.
  Refer to `dcls_soc.sv` to see an example of how the `ndmreset_ni` signal is
  computed based on `ndmreset_o` signals and othe system signals.
- `rvfi_probes_o`: output of the CVA6 formal verification probes.
  Can be left open if not used.
- `dcls_mode_i`: input logic signal determining if the dual core in the host
  core tile should work as dual core (AMP) or as a lockstep core (i.e. a core
  plus a lockstep core).
  Should be `0` to work as dual core and `1` to work as lockstep.
  **IMPORTANT**: this signal should not change.
- `dcls_error_o`: output logic array of length 2 indicating if an error has
  ocurred.
- `ext_slave_bus`: output array of master bus connections.
  They map the cores master bus interfaces.
  Should be connected to slave interfaces in the system bus.
- `ext_master_bus`:  input slave bus connection.
  Should be connected to a master interface in the system bus.