XLEN ?= 64
CROSSCOMPILE ?= riscv64-unknown-elf-
CC = ${CROSSCOMPILE}gcc

ifeq ($(XLEN), 64)
CFLAGS = -Os -ggdb -march=rv64imac -mabi=lp64 -Wall -mcmodel=medany -mexplicit-relocs
else
CFLAGS = -O2 -ggdb  -march=rv32im -mabi=ilp32 -W -Wall -mcmodel=medany -mexplicit-relocs -fno-builtin
endif

CCASFLAGS = -mcmodel=medany -mexplicit-relocs
LDFLAGS = -nostdlib -nodefaultlibs -nostartfiles

mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
mkfile_dir := $(dir $(mkfile_path))

INCLUDES = -I$(mkfile_dir)/ -I$(mkfile_dir)/src

SRCS_C = src/main.c src/uart.c src/spi.c src/sd.c src/gpt.c
SRCS_ASM = startup.S
OBJS_C = $(SRCS_C:.c=.o)
OBJS_S = $(SRCS_ASM:.S=.o)

MAIN = bootrom.elf
MAIN_BIN = $(MAIN:.elf=.bin)
MAIN_IMG = $(MAIN:.elf=.img)
MAIN_SV = $(MAIN:.elf=.sv)

DTB = cv$(XLEN)a6.dtb
LDS = linker.lds

#.PHONY: clean

all: $(MAIN) $(MAIN_BIN) $(MAIN_IMG) $(MAIN_SV)
	@echo "zero stage bootloader has been compiled!"

$(MAIN): $(DTB) $(OBJS_C) $(OBJS_S) $(mkfile_dir)/$(LDS)
	$(CC) $(CFLAGS) $(LDFLAGS) $(INCLUDES) -T$(mkfile_dir)/$(LDS) $(OBJS_S) $(OBJS_C) -o $(MAIN)
	@echo "LD    >= $(MAIN)"

$(MAIN_IMG): %.img: %.bin
	dd if=$< of=$@ bs=128

$(MAIN_BIN): %.bin: %.elf
	$(CROSSCOMPILE)objcopy -O binary $< $@

$(OBJS_C): %.o: $(mkfile_dir)/%.c
	mkdir -p $(dir $@)
	@$(CC) $(CFLAGS) $(INCLUDES) -c $<  -o $@
	@echo "CC    <= $<"

$(OBJS_S): %.o: $(mkfile_dir)/%.S
	mkdir -p $(dir $@)
	@$(CC) $(CFLAGS) $(CCASFLAGS) $(INCLUDES) -c $<  -o $@
	@echo "CC    <= $<"

$(DTB): %.dtb: $(mkfile_dir)/%.dts
	dtc -I dts $< -O dtb -o $@

$(MAIN_SV): %.sv: %.img
	$(mkfile_dir)/gen_rom.py $<
	@echo "PYTHON >= $(MAIN_SV)"

clean:
	$(RM) $(OBJS_C) $(OBJS_S) $(MAIN) $(MAIN_BIN) $(MAIN_IMG) *.dtb

# DO NOT DELETE THIS LINE -- make depend needs it
