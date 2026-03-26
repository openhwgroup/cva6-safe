# Recent versions of GCC seem to require the following line to enable the
# usage of the csr instructions
.option arch, +zicsr
.section .text.start, "ax", @progbits
.globl _start
_start:
# bootrom.sv need to be functional in 64 and 32 bits,
# li s0, DRAM_BASE creates instructions not compatible with both
# versions. That's why we have replaced it by li and slli instructions
# to generates code compatible with both versions.
  csrr a0, mhartid
  # The following creates an start address different for each hart:
  # - hart 0 => 0x80000000
  # - hart 1 => 0x81000000
  # - hart 2 => 0x82000000
  # ...
  li s0, 1
  slli s0, s0, 7
  add s0, s0, a0
  slli s0, s0, 24
  la a1, _dtb
  jr s0

.section .text.hang, "ax", @progbits
.globl _hang
_hang:
  csrr a0, mhartid
  la a1, _dtb
1:
  wfi
  j 1b

.section .rodata.dtb, "a", @progbits
.globl _dtb
.align 5, 0
_dtb:
.incbin "cva6_safe.dtb"
