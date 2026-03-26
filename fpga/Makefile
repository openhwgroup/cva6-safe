# Author: Florian Zaruba, ETH Zurich
# Date: 03/19/2017
# Description: Makefile for linting and testing Ariane.

# root path
mkfile_path := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
root-dir := $(abspath $(mkfile_path)/..)/
gen-dir := $(abspath $(mkfile_path)/generated)
$(info mkfile_path = $(mkfile_path))
$(info root-dir    = $(root-dir))
$(info gen-dir     = $(gen-dir))

# target takes one of the following cva6 hardware configuration:
# cv64a6_imafdc_sv39, cv32a6_imac_sv0, cv32a6_imac_sv32, cv32a6_imafc_sv32, cv32a6_ima_sv32_fpga
# Changing the default target to cv32a60x for Step1 verification
target     ?= cv32a6_imac_sv32
ifndef TARGET_CFG
	export TARGET_CFG = $(target)
endif
apu_target ?= cva6_safe_apu_ls
ifndef APU_TARGET_CFG
  export APU_TARGET_CFG = $(apu_target)
endif

ifeq ($(findstring cv64,$(target)),cv64)
  xlen=64
else
  xlen=32
endif
$(info XLEN = $(xlen))

ifndef CVA6_REPO_DIR
$(warning must set CVA6_REPO_DIR to point at the root of CVA6 sources -- doing it for you...)
export CVA6_REPO_DIR = $(abspath $(root-dir)/cva6)
endif
$(info CVA6_REPO_DIR = $(CVA6_REPO_DIR))
$(info MAKEFILE_LIST = $(MAKEFILE_LIST))

# HPDcache directory
HPDCACHE_DIR ?= $(CVA6_REPO_DIR)/core/cache_subsystem/hpdcache
export HPDCACHE_DIR

export SRC_DIR = $(abspath $(root-dir)/src)

# Target HPDcache configuration package.
#   The HPDCACHE_TARGET_CFG variable contains the path (relative or absolute)
#   to your target configuration package
HPDCACHE_TARGET_CFG ?= ${CVA6_REPO_DIR}/core/include/cva6_hpdcache_default_config_pkg.sv
export HPDCACHE_TARGET_CFG

APU_TARGET_CFG_FILE = $(root-dir)include/$(APU_TARGET_CFG)_config_pkg.sv

NUM_DCLS?=$(shell sed -n 's/.*NUM_DCLS\s*=\s*\(.*\)\s*;/\1/p' < $(APU_TARGET_CFG_FILE))
DCLS_MODE?=$(shell sed -n 's/.*DCLS_MODE\s*=\s*.*::\(.*\)\s*;/\1/p' < $(APU_TARGET_CFG_FILE))
ifeq ($(DCLS_MODE),)
  $(error ERROR: \
Could not extract DCLS_MODE from configuration file "($(APU_TARGET_CFG_FILE))".\
Fix the configuration file or set the DCLS_MODE when calling the Makefile, e.g.\
"DCLS_MODE=LS make ....")
endif
ifeq ($(NUM_DCLS),)
  $(error ERROR: \
Could not extract NUM_DCLS from configuration file "($(APU_TARGET_CFG_FILE))".\
Fix the configuration file or set the NUM_DCLS when calling the Makefile, e.g.\
"NUM_DCLS=1 make ....")
endif
ifneq ($(NUM_DCLS),1)
  $(error ERROR: Currently only NUM_DCLS=1 is supported (NUM_DCLS=$(NUM_DCLS) provided).)
endif
NUM_CORES=$(shell echo $$(( $(NUM_DCLS) * 2 )))
ifeq ($(DCLS_MODE),DC)
  NUM_APP_CORES=$(NUM_CORES)
else
  NUM_APP_CORES=$(NUM_DCLS)
endif
NUM_PLIC_TARGETS=$(shell echo $$(( $(NUM_CORES) * 2 )) )
$(info APU_TARGET_CFG   = $(APU_TARGET_CFG))
$(info NUM_DCLS         = $(NUM_DCLS))
$(info DCLS_MODE        = $(DCLS_MODE))
$(info NUM_CORES        = $(NUM_CORES))
$(info NUM_APP_CORES    = $(NUM_APP_CORES))
$(info NUM_PLIC_TARGETS = $(NUM_PLIC_TARGETS))

# questa library
library        ?= work/$(NUM_DCLS)dcls_$(DCLS_MODE)
# verilator lib
ver-library    ?= work-ver
# vcs lib
vcs-library    ?= work-vcs
# library for DPI
dpi-library    ?= work-dpi
# Top level module to compile
#   options:
#  - cva6_safe_app_tb
#  - cva6_safe_sys_tb
top_level      ?= cva6_amp_app_tb
# Maximum amount of cycles for a successful simulation run
max_cycles     ?= 10000000
# Test case to run
test_case      ?= core_test
# QuestaSim Version
questa_version ?= ${QUESTASIM_VERSION}
VLOG ?= vlog$(questa_version)
VSIM ?= vsim$(questa_version)
VOPT ?= vopt$(questa_version)
VCOM ?= vcom$(questa_version)
VLIB ?= vlib$(questa_version)
VMAP ?= vmap$(questa_version)
QUESTA_CMD ?= -do " log -r /*; run -all;"
QUESTA_BATCH_CMD ?= -do "coverage save -onexit tmp/$@.ucdb; run -a; quit -code [coverage attribute -name TESTSTATUS -concise]"
# verilator version
verilator      ?= verilator
# traget option
target-options ?=
# additional definess
defines        ?=
# test name for torture runs (binary name)
test-location  ?= output/test
# set to either nothing or -log
torture-logs   :=
# custom elf bin to run with sim or sim-verilator
elf-bin        ?= tmp/riscv-tests/build/benchmarks/dhrystone.riscv
# board name for bitstream generation. Currently supported: kc705, genesys2
BOARD          ?= genesys2

support_verilator_4 := $(shell ($(verilator) --version | grep '4\.') > /dev/null 2>&1 ; echo $$?)
ifeq ($(support_verilator_4), 0)
	verilator_threads := 1
endif

ifndef RISCV
$(error RISCV not set - please point your RISCV variable to your RISCV installation)
endif

# By default assume spike resides at the RISCV prefix.
SPIKE_ROOT     ?= $(RISCV)

# setting additional xilinx board parameters for the selected board
ifeq ($(BOARD), genesys2)
	XILINX_PART              := xc7k325tffg900-2
	XILINX_BOARD             := digilentinc.com:genesys2:part0:1.1
	CLK_PERIOD_NS            := 20
else ifeq ($(BOARD), kc705)
	XILINX_PART              := xc7k325tffg900-2
	XILINX_BOARD             := xilinx.com:kc705:part0:1.5
	CLK_PERIOD_NS            := 20
else ifeq ($(BOARD), vc707)
	XILINX_PART              := xc7vx485tffg1761-2
	XILINX_BOARD             := xilinx.com:vc707:part0:1.3
	CLK_PERIOD_NS            := 20
else
$(error Unknown board - please specify a supported FPGA board)
endif

# spike tandem verification
ifdef spike-tandem
    compile_flag += -define SPIKE_TANDEM
    ifndef preload
        $(error Tandem verification requires preloading)
    endif
endif

# determine the cva6 core source files depending on the target name, and
# particularly on the virtual memory space size (sv0, sv32 or sv39)
sv_cfg := $(patsubst %sv0,sv0,\
  $(patsubst %sv32,sv32,\
  $(patsubst %sv39,sv39,$(target))))
$(info "sv_cfg = $(sv_cfg)")
flist_file := $(gen-dir)/Flist.cva6_${sv_cfg}

# Sources
# Package files -> compile first

cva6_pkg := \
  cva6/corev_apu/register_interface/src/reg_intf.sv \
  cva6/corev_apu/riscv-dbg/src/dm_pkg.sv \
  cva6/corev_apu/tb/ariane_axi_pkg.sv \
  cva6/corev_apu/riscv-dbg/src/dm_pkg.sv \
  cva6/corev_apu/tb/axi_intf.sv

PLIC_FILE = $(gen-dir)/plic/plic_regmap.$(NUM_PLIC_TARGETS)-targets.sv

cva6_safe_pkg := \
  $(cva6_pkg) \
  include/cva6_safe_dcls_types_pkg.sv \
  src/cva6_safe_host_core_support_pkg.sv \
  include/$(APU_TARGET_CFG)_config_pkg.sv \
  tb/cva6_safe_soc_pkg.sv \
  fpga/src/dcls_soc_pkg.sv
#   $(FPGA_REPO_DIR)/fpga/src/dcls_soc_pkg.sv
cva6_safe_pkg := $(addprefix $(root-dir), $(cva6_safe_pkg))
# cva6_safe_pkg := $(cva6_safe_pkg) \
#   $(root-dir)/cva6/corev_apu/rv_plic/rtl/plic_regmap.sv \
#   $(PLIC_FILE)
cva6_safe_pkg := $(cva6_safe_pkg) $(PLIC_FILE)

# # OLD
# # Test packages
# test_pkg := $(wildcard tb/test/*/*sequence_pkg.sv*) \
# 			$(wildcard tb/test/*/*_pkg.sv*)
# # End OLD

# # OLD
# # DPI
# # dpi := $(patsubst corev_apu/tb/dpi/%.cc, ${dpi-library}/%.o, $(wildcard corev_apu/tb/dpi/*.cc))
# dpi := $(patsubst dpi/%.cc, ${dpi-library}/%.o, $(wildcard dpi/*.cc))
# 
# # filter spike stuff if tandem is not activated
# ifndef spike-tandem
#     dpi := $(filter-out ${dpi-library}/spike.o ${dpi-library}/sim_spike.o, $(dpi))
# endif
# 
# # dpi_hdr := $(wildcard corev_apu/tb/dpi/*.h)
# dpi_hdr := $(wildcard dpi/*.h)
# $(info dpi_hdr = ${dpi_hdr})
# dpi_hdr := $(addprefix $(root-dir)core_amp_apu/tb/, $(dpi_hdr))
# $(info dpi_hdr = ${dpi_hdr})
# CFLAGS += -I$(QUESTASIM_HOME)/include         \
#           -I$(VCS_HOME)/include               \
#           -I$(RISCV)/include                  \
#           -I$(SPIKE_ROOT)/include             \
#           -std=c++17 -Idpi -O3
# # End OLD
CFLAGS += -I$(QUESTASIM_HOME)/include         \
          -I$(VCS_HOME)/include               \
          -I$(RISCV)/include                  \
          -std=c++17 -O3

# # OLD
# ifdef XCELIUM_HOME
# CFLAGS += -I$(XCELIUM_HOME)/tools/include
# else
# $(warning XCELIUM_HOME not set which is necessary for compiling DPIs when using XCELIUM)
# endif
# 
# ifdef spike-tandem
#   CFLAGS += -Itb/riscv-isa-sim/install/include/spike
# endif
# # End OLD


# this list contains the standalone components
# START Standalone components
# src := \
#   generated/bootrom/bootrom.sv \
#   generated/plic/plic_regmap.$(APU_TARGET_CFG).sv

# cva6 components
src := $(src) \
  src/ariane.sv                                                                    \
  cva6/corev_apu/rv_plic/rtl/rv_plic_target.sv                                     \
  cva6/corev_apu/rv_plic/rtl/rv_plic_gateway.sv                                    \
  cva6/corev_apu/rv_plic/rtl/plic_top.sv                                           \
  cva6/corev_apu/riscv-dbg/src/dmi_cdc.sv                                          \
  cva6/corev_apu/riscv-dbg/src/dmi_jtag.sv                                         \
  cva6/corev_apu/riscv-dbg/src/dmi_jtag_tap.sv                                     \
  cva6/corev_apu/riscv-dbg/src/dm_csrs.sv                                          \
  cva6/corev_apu/riscv-dbg/src/dm_mem.sv                                           \
  cva6/corev_apu/riscv-dbg/src/dm_sba.sv                                           \
  cva6/corev_apu/riscv-dbg/src/dm_top.sv                                           \
  cva6/corev_apu/riscv-dbg/debug_rom/debug_rom.sv                                  \
  cva6/corev_apu/register_interface/src/apb_to_reg.sv                              \
  cva6/vendor/pulp-platform/axi/src/axi_multicut.sv                                \
  cva6/vendor/pulp-platform/common_cells/src/rstgen_bypass.sv                      \
  cva6/vendor/pulp-platform/common_cells/src/rstgen.sv                             \
  cva6/vendor/pulp-platform/common_cells/src/addr_decode.sv                        \
  cva6/vendor/pulp-platform/common_cells/src/stream_register.sv                    \
  cva6/vendor/pulp-platform/axi/src/axi_cut.sv                                     \
  cva6/vendor/pulp-platform/axi/src/axi_join.sv                                    \
  cva6/vendor/pulp-platform/axi/src/axi_delayer.sv                                 \
  cva6/vendor/pulp-platform/axi/src/axi_to_axi_lite.sv                             \
  cva6/vendor/pulp-platform/axi/src/axi_id_prepend.sv                              \
  cva6/vendor/pulp-platform/axi/src/axi_atop_filter.sv                             \
  cva6/vendor/pulp-platform/axi/src/axi_err_slv.sv                                 \
  cva6/vendor/pulp-platform/axi/src/axi_mux.sv                                     \
  cva6/vendor/pulp-platform/axi/src/axi_demux.sv                                   \
  cva6/vendor/pulp-platform/axi/src/axi_xbar.sv                                    \
  cva6/vendor/pulp-platform/axi/src/axi_id_remap.sv                                \
  cva6/vendor/pulp-platform/axi/src/axi_id_serialize.sv                            \
  cva6/vendor/pulp-platform/axi/src/axi_iw_converter.sv                            \
  cva6/vendor/pulp-platform/axi/src/axi_serializer.sv                              \
  cva6/vendor/pulp-platform/common_cells/src/cdc_2phase.sv                         \
  cva6/vendor/pulp-platform/common_cells/src/spill_register_flushable.sv           \
  cva6/vendor/pulp-platform/common_cells/src/spill_register.sv                     \
  cva6/vendor/pulp-platform/common_cells/src/deprecated/fifo_v1.sv                 \
  cva6/vendor/pulp-platform/common_cells/src/deprecated/fifo_v2.sv                 \
  cva6/vendor/pulp-platform/common_cells/src/stream_delay.sv                       \
  cva6/vendor/pulp-platform/common_cells/src/lfsr_16bit.sv                         \
  cva6/vendor/pulp-platform/tech_cells_generic/src/deprecated/cluster_clk_cells.sv \
  cva6/vendor/pulp-platform/tech_cells_generic/src/deprecated/pulp_clk_cells.sv    \
  cva6/vendor/pulp-platform/tech_cells_generic/src/rtl/tc_clk.sv                   \
  cva6/corev_apu/tb/rvfi_tracer.sv

# add uart module from corev_apu
src := $(src) \
  cva6/corev_apu/tb/common/uart.sv

src := $(src) \
  src/cva6_safe_host_core_support.sv \
  src/cva6_safe_host_core.sv \
  src/dcls_cva6_block.sv \
  src/dcls_cva6.sv

src := $(addprefix $(root-dir), $(src))

src := $(src) \
  $(wildcard $(root-dir)/cva6/corev_apu/clint/*.sv)                                \
  $(wildcard $(root-dir)/cva6/corev_apu/fpga/src/axi2apb/src/*.sv)                 \
  $(wildcard $(root-dir)/cva6/corev_apu/fpga/src/apb_timer/*.sv)                   \
  $(wildcard $(root-dir)/cva6/corev_apu/fpga/src/axi_slice/src/*.sv)               \
  $(wildcard $(root-dir)/cva6/corev_apu/src/axi_riscv_atomics/src/*.sv)            \
  $(wildcard $(root-dir)/cva6/corev_apu/axi_mem_if/src/*.sv)

# END Standalone components

# $(gen-dir)/Flist.cva6_sv39: $(CVA6_REPO_DIR)/core/Flist.cva6
$(gen-dir)/Flist.cva6_sv39: $(SRC_DIR)/Flist.cva6
	mkdir -p $(dir $@)
	grep -v sv32 $< > $@

#$(gen-dir)/Flist.cva6_sv32: $(CVA6_REPO_DIR)/core/Flist.cva6
$(gen-dir)/Flist.cva6_sv32: $(SRC_DIR)/Flist.cva6
	mkdir -p $(dir $@)
	grep -v sv39 $< > $@

# $(gen-dir)/bootrom/bootrom.sv:
# 	# Generating bootrom module ($@)
# 	mkdir -p $(dir $@)
# 	cp -r $(root-dir)/fpga/bootrom/bootrom.sv $@
#	XLEN=$(xlen) CROSSCOMPILE=$(RISCV)/bin/riscv$(xlen)-unknown-elf- \
#	  make -C $(dir $@) -f $(root-dir)/fpga/bootrom/Makefile

# NUM_CORES=$(NUM_CORES) MEM_SIZE=$(CORE_APU_MEM_SIZE) \
    make -C $(dir $@) -f $(root-dir)/bootrom/Makefile

copro_src := $(CVA6_REPO_DIR)/core/cvxif_example/include/cvxif_instr_pkg.sv \
  $(wildcard $(CVA6_REPO_DIR)/core/cvxif_example/*.sv)

# uart_src := $(wildcard $(root-dir)/cva6/corev_apu/fpga/src/apb_uart/src/*.vhd)
uart_src := $(wildcard $(CVA6_REPO_DIR)/corev_apu/fpga/src/apb_uart/src/*.vhd)

# fpga_src := src/dcls_soc_pkg.sv src/dcls_soc.sv \
#   $(CVA6_REPO_DIR)/corev_apu/fpga/src/fan_ctrl.sv \
#   $(wildcard $(CVA6_REPO_DIR)/corev_apu/fpga/src/bootrom/*.sv)   \
# 	$(wildcard $(CVA6_REPO_DIR)/corev_apu/fpga/src/ariane-ethernet/*.sv)
FPGA_REPO_DIR =  $(abspath $(root-dir)/fpga)
fpga_src := $(FPGA_REPO_DIR)/src/dcls_soc_pkg.sv $(FPGA_REPO_DIR)/src/dcls_soc.sv \
  $(CVA6_REPO_DIR)/corev_apu/fpga/src/fan_ctrl.sv \
  $(root-dir)/fpga/bootrom/bootrom.sv \
	$(wildcard $(CVA6_REPO_DIR)/corev_apu/fpga/src/ariane-ethernet/*.sv)
fpga_src := $(fpga_src) \
  $(CVA6_REPO_DIR)/common/local/util/tc_sram_fpga_wrapper.sv \
  $(CVA6_REPO_DIR)/vendor/pulp-platform/fpga-support/rtl/SyncSpRamBeNx64.sv
# Generate plic_regmap for the PLIC
# This depends on the number of cores in the selected configuration.
# The number of cores is automatically extracted from
# the '$(APU_TARGET_CFG)_config_pkg.sv' file.
# The number of PLIC targets is derived from the number of cores.

$(PLIC_FILE): \
  $(root-dir)cva6/corev_apu/rv_plic/rtl/gen_plic_addrmap.py \
  $(root-dir)include/$(APU_TARGET_CFG)_config_pkg.sv
	# Generate plic_regmap ($@)
	mkdir -p $(dir $@)
	$< -t $(NUM_PLIC_TARGETS) -s 30 -p 7 > $@

# # RISCV asm tests and benchmark setup (used for CI)
# # there is a definesd test-list with selected CI tests
# riscv-test-dir            := tmp/riscv-tests/build/isa/
# riscv-benchmarks-dir      := tmp/riscv-tests/build/benchmarks/
# riscv-asm-tests-list      := ci/riscv-asm-tests.list
# riscv-amo-tests-list      := ci/riscv-amo-tests.list
# riscv-mul-tests-list      := ci/riscv-mul-tests.list
# riscv-fp-tests-list       := ci/riscv-fp-tests.list
# riscv-benchmarks-list     := ci/riscv-benchmarks.list
# riscv-asm-tests           := $(shell \
#   xargs printf '\n%s' < $(riscv-asm-tests-list)  | cut -b 1-)
# riscv-amo-tests           := $(shell \
#   xargs printf '\n%s' < $(riscv-amo-tests-list)  | cut -b 1-)
# riscv-mul-tests           := $(shell \
#   xargs printf '\n%s' < $(riscv-mul-tests-list)  | cut -b 1-)
# riscv-fp-tests            := $(shell \
#   xargs printf '\n%s' < $(riscv-fp-tests-list)   | cut -b 1-)
# riscv-benchmarks          := $(shell \
#   xargs printf '\n%s' < $(riscv-benchmarks-list) | cut -b 1-)
riscv-benchmarks := dhrystone.riscv qsort.riscv towers.riscv
riscv-benchmarks-amp := $(addsuffix .amp,$(riscv-benchmarks))
riscv-benchmarks-build-dir := $(abspath $(root-dir)riscv-tests/build/benchmarks)/
riscv-systests := clint.riscv
riscv-systests-build-dir := $(abspath $(root-dir)riscv-tests/build/sys/$(NUM_DCLS)$(DCLS_MODE))

CORE_APU_CORE_LIST = $(shell \
  i=0; \
  while [ $$i -lt $(NUM_APP_CORES) ]; do \
    echo $$i; \
    i=$$(($$i + 1)); \
  done)
# TODO: CORE_APU_MEM_BASE_ADDR and CORE_APU_CORE_MEM_SIZE should be extracted
#       from a configuration file or provided in input variables
CORE_APU_MEM_BASE_ADDR = 0x80000000
CORE_APU_CORE_MEM_SIZE = 0x01000000
CORE_APU_MEM_SIZE = $(shell \
  printf "0x%x" $$(( $(NUM_CORES) * $(CORE_APU_CORE_MEM_SIZE) )) )
CORE_APU_CORE_BASE_ADDR_LIST = $(shell \
  for i in $(CORE_APU_CORE_LIST); do \
    printf "%x\n" \
      $$(( ($$i * $(CORE_APU_CORE_MEM_SIZE)) + $(CORE_APU_MEM_BASE_ADDR) )); \
  done)

# Search here for include files (e.g.: non-standalone components)
incdir := cva6/vendor/pulp-platform/common_cells/include/ \
  cva6/vendor/pulp-platform/axi/include/                  \
  cva6/corev_apu/register_interface/include/              \
  cva6/core/include
incdir := $(addprefix $(root-dir),$(incdir))

# Compile and sim flags
compile_flag     += +cover=bcfst+/dut -incr -64 -nologo -quiet \
  -suppress 13262 -permissive -svinputport=compat +define+$(defines)

uvm-flags        += +UVM_NO_RELNOTES +UVM_VERBOSITY=LOW
questa-flags     += -t 1ns -64 -coverage -classdebug $(gui-sim) \
  $(QUESTASIM_FLAGS) +tohost_addr=$(tohost_addr)
compile_flag_vhd += -64 -nologo -quiet -2008

# Iterate over all include directories and write them with +incdir+ prefixed
# +incdir+ works for Verilator and QuestaSim
list_incdir := $(foreach dir, ${incdir}, +incdir+$(dir))

# RISCV torture setup
riscv-torture-dir    := tmp/riscv-torture
# old java flags  -Xmx1G -Xss8M -XX:MaxPermSize=128M
# -XshowSettings -Xdiag
riscv-torture-bin    := java -jar sbt-launch.jar

# if defined, calls the questa targets in batch mode
ifdef batch-mode
  questa-flags += -c
#	questa-cmd   := -do "coverage save -onexit tmp/$@.ucdb; run -a; \
#	                     quit -code \
#											 [coverage attribute -name TESTSTATUS -concise]"
#	questa-cmd   += -do " log -r /*; run -all;"
  questa-cmd := $(QUESTA_BATCH_CMD)
  questa-cmd += $(QUESTA_CMD)
else
#	questa-cmd   := -do " log -r /*; run -all;"
  questa-cmd := $(QUESTA_CMD)
endif
# we want to preload the memories
ifdef preload
  questa-cmd += +PRELOAD=$(preload)
  elf-bin = none
endif

ifdef spike-tandem
  questa-cmd += -gblso tb/riscv-isa-sim/install/lib/libriscv.so
endif

# remote bitbang is enabled
ifdef rbb
  questa-cmd += +jtag_rbb_enable=1
else
  questa-cmd += +jtag_rbb_enable=0
endif

src_flist = $(shell \
	    CVA6_REPO_DIR=$(CVA6_REPO_DIR) \
	    TARGET_CFG=$(TARGET_CFG) \
	    HPDCACHE_TARGET_CFG=$(HPDCACHE_TARGET_CFG) \
	    HPDCACHE_DIR=$(HPDCACHE_DIR) \
	    python3 $(CVA6_REPO_DIR)/util/flist_flattener.py $(flist_file))
# fpga_filter := $(CVA6_REPO_DIR)/corev_apu/bootrom/bootrom.sv
fpga_filter := $(root-dir)/fpga/bootrom/bootrom.sv
fpga_filter += $(CVA6_REPO_DIR)/core/include/instr_tracer_pkg.sv
fpga_filter += $(CVA6_REPO_DIR)/common/local/util/ex_trace_item.svh
fpga_filter += $(CVA6_REPO_DIR)/common/local/util/instr_trace_item.svh
fpga_filter += $(CVA6_REPO_DIR)/common/local/util/instr_tracer_if.sv
#fpga_filter += $(CVA6_REPO_DIR)/common/local/util/instr_tracer.sv
fpga_filter += $(CVA6_REPO_DIR)/vendor/pulp-platform/tech_cells_generic/src/rtl/tc_sram.sv
fpga_filter += $(CVA6_REPO_DIR)/common/local/util/tc_sram_wrapper.sv

generated/flat_src_flist: $(flist_file)
	@mkdir -p generated
	CVA6_REPO_DIR=$(CVA6_REPO_DIR) \
	  TARGET_CFG=$(TARGET_CFG) \
	  HPDCACHE_TARGET_CFG=$(HPDCACHE_TARGET_CFG) \
	  HPDCACHE_DIR=$(HPDCACHE_DIR) \
	python3 $(CVA6_REPO_DIR)/util/flist_flattener.py $< $@

fpga: $(cva6_safe_pkg) $(src) $(fpga_src) $(uart_src) generated/flat_src_flist
	@mkdir -p scripts
	@echo "[FPGA] Generate sources"
	@echo read_vhdl        {$(uart_src)}    > scripts/add_sources.tcl
	@echo read_verilog -sv {$(cva6_safe_pkg)} >> scripts/add_sources.tcl
	# @echo read_verilog -sv {$(filter-out $(fpga_filter), $(src_flist))}		>> scripts/add_sources.tcl
	@echo read_verilog -sv {$(filter-out $(fpga_filter), $(shell cat generated/flat_src_flist))}		>> scripts/add_sources.tcl
	@echo read_verilog -sv {$(filter-out $(fpga_filter), $(src))} 	   >> scripts/add_sources.tcl
	@echo read_verilog -sv {$(fpga_src)}   >> scripts/add_sources.tcl
	@echo "[FPGA] Generate Bitstream"
	make -f Makefile.fpga BOARD=$(BOARD) XILINX_PART=$(XILINX_PART) XILINX_BOARD=$(XILINX_BOARD) CLK_PERIOD_NS=$(CLK_PERIOD_NS)

.PHONY: fpga

build-spike:
	cd tb/riscv-isa-sim && mkdir -p build && cd build && ../configure --prefix=`pwd`/../install --with-fesvr=$(RISCV) --enable-commitlog && make -j8 install

clean:
	rm -rf $(riscv-torture-dir)/output/test*
	rm -rf $(library)/ $(dpi-library)/ $(ver-library)/ $(vcs-library)/ generated work-fpga *.hw *.cache
	rm -f tmp/*.ucdb tmp/*.log *.wlf *vstf wlft* *.ucdb *.xpr scripts/add_sources.tcl	
	cd $(CVA6_REPO_DIR)/corev_apu/fpga && make clean && cd ../..
	rm -rf $(root-dir)core_amp_apu/riscv-tests/build \
    $(root-dir)core_amp_apu/riscv-tests/generated \
    $(gen-dir)

.PHONY:
	build sim sim-verilate clean                                              \
	$(riscv-asm-tests) $(addsuffix _verilator,$(riscv-asm-tests))             \
	$(riscv-benchmarks) $(addsuffix _verilator,$(riscv-benchmarks))           \
	check-benchmarks check-asm-tests                                          \
	torture-gen torture-itest torture-rtest                                   \
	run-torture run-torture-verilator check-torture check-torture-verilator

$(info end of Makefile)
