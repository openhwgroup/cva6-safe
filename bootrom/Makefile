bootrom_img = bootrom.img bootrom.sv bootrom.h

NUM_CORES?=1
MEM_SIZE?=0x10000000

RISCV_PREFIX?=riscv32-unknown-elf-
RISCV_GCC?=$(RISCV_PREFIX)gcc
RISCV_OBJCOPY?=$(RISCV_PREFIX)objcopy
RISCV_OBJDUMP?=$(RISCV_PREFIX)objdump
DTB=cva6_safe.dtb
PYTHON=python3

precious_files=cva6_safe.dtb bootrom.elf bootrom.bin cva6_safe.dts

mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
mkfile_dir := $(dir $(mkfile_path))

.PRECIOUS: $(precious_files)

all: $(bootrom_img)

%.img: %.bin
	dd if=$< of=$@ bs=128

%.bin: %.elf
	$(RISCV_OBJCOPY) -O binary $< $@

%.elf: $(mkfile_dir)%.S $(mkfile_dir)linker.ld $(DTB)
	$(RISCV_GCC) -T"$(mkfile_dir)linker.ld" -march=rv32i -mabi=ilp32 $< -nostdlib -static -Wl,--no-gc-sections -o $@

%.dump: %.elf
	$(RISCV_OBJDUMP) -aD $<

%.dtb: %.dts
	dtc -I dts $< -O dtb -o $@

%.dts:
	$(PYTHON) $(mkfile_dir)gen_dts.py -n $(NUM_CORES) --mem-size $(MEM_SIZE) $@

%.h %.sv: %.img
	$(PYTHON) $(mkfile_dir)gen_rom.py $<

clean:
	rm -f $(bootrom_img) $(precious_files)
