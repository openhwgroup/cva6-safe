# CVA6-Safe design

The **CVA6-Safe** is a processor design based on the CVA6 core that provides
_dual-core lockstep_ and caches error detection and correction.

This project provides a dual-core lockstep (DCLS) module based on CVA6 cores
with a split-mode capability to use the module as a regular dual-core setup for
high-performance applications that do not need the safety provided by the
lockstep mechanism.
The DCLS working mode, lockstep (LS) or split (SP), can be chosen at design time
or at power-on time through a dedicated signal on the DCLS module.
When working on LS mode the DCLS module implements an error detection
and correction (EDAC) mechanism for the cache memories; this EDC mechanism is
deactivated when using the DCLS module in SP mode.

A more detailed description of the CVA6-Safe design and its components can be
found here **TODO**.

# Quick run

## Infrastructure setup

The following instructions will allow you to setup, compile and run a Questa
simulation of the CVA6-Safe design within a testbench.

1. Checkout the repository and initialize all submodules.
```sh
git clone https://github.com/openhwgroup/cva6-safe cva6-safe
cd cva6-safe
git submodule update --init --recursive
```

2. Install the GCC Toolchain
   [build prerequisites](https://github.com/openhwgroup/cva6/blob/master/util/toolchain-builder/README.md#prerequisites)
   then
   [the toolchain itself](https://github.com/openhwgroup/cva6/blob/master/util/toolchain-builder/README.md#getting-started).

:warning: The target configuration in the NeuroSoC project and this quick setup
is a CV32A6 (32bits CVA6) with IMAC, Zicsr and sv32 support.

3. Set the required environment variables (`RISCV`, `QUESTASIM_HOME`)
```sh
export RISCV=/path/to/toolchain/installation/directory
export QUESTASIM_HOME=/path/to/questasim/directory
```

## Running standalone simulations

There are two versions of the standalone simulations that can be launched with
the `Makefile` provided in the testbench folder (`tb` folder):
- One that initializes the memory with the provided binary at address 0x80000000
  and let's the bootrom execute normaly.
  The bootrom will jump at address 0x80000000 to execute the provided binary on
  each core.
  We refer to this simulation as the _system simulation_.
- One that uploads an application binary for each of the cores in system (1 if 
  configured in lockstep mode or 2 if configured in dual-core AMP mode).
  We refer to this simulation as the _application simulation_.

The required binaries are compiled by the `tb/Makefile`.
The _system simulation_ currently only provides an application, the
`clint.riscv` application and can be launched as follows for a dual-core
lockstep (DCLS) host-tile working as an AMP dual-core with the
`cv32a6_imac_sv32` core:
```
make clint.riscv top_level=cva6safe_sys_tb \
  target=cv32a6_imac_sv32 \
  apu_target=cva6safe_apu_1dcls_dc
```

The _application simulation_ provides three applcations: dhrystone, qsort and
towers.
For example, to launch the qsort application simulation in a DCLS host-tile
working as two cores in lockstep mode with the `cv32a6_imac_sv32` core:
```
make qsot.riscv top_level=cva6safe_app_tb \
  target=cv32a6_imac_sv32 \
  apu_target=cva6safe_apu_1dcls_ls
```

# Acknowledgements

Check out the [acknowledgements](ACKNOWLEDGEMENTS.md).