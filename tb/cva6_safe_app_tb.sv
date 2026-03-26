// Copyright (c) 2020, 2023-2026 Thales.
// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// Author: Florian Zaruba, ETH Zurich
// Date: 15/04/2017
//
// Additional contributions by:
//         Sebastien Jacq - sjthales on github.com
//         Daniel Gracia Pérez - dgptha on github.com
//
// Description: Top level testbench module. Instantiates the top level DUT, configures
//              the virtual interfaces and starts the test passed by +UVM_TEST+
//
// ========================================================================== //
// Revisions  :
// Date        Version  Author          Description
// 2020-10-06  0.1      S.Jacq          modification of the Test for CVA6
//                                      softcore
// 2023-07-21  0.2      D.Gracia Pérez  add support for AMP configurations
// ========================================================================== //

import ariane_pkg::*;
import jtag_pkg::*;

`define EXIT_SUCCESS  0
`define EXIT_FAIL     1
`define EXIT_ERROR   -1

`define MAIN_MEM(P) dut.i_sram.gen_cut[0].i_tc_sram_wrapper.i_tc_sram.init_val[(``P``)]

module cva6_safe_app_tb;

  logic [255:0][31:0]   jtag_data;

  jtag_pkg::debug_mode_if_t  debug_mode_if = new;

  logic [8:0] jtag_conf_reg, jtag_conf_rego; // 22bits but actually only the
                                             // last 9bits are used

  int exit_status = `EXIT_ERROR;

  localparam int unsigned CLOCK_PERIOD = 40ns; //25MHz as for the Zybo kit
  // toggle with RTC period
  localparam int unsigned RTC_CLOCK_PERIOD = 2*30.517us;

  // localparam NUM_WORDS = cva6_apu_config_pkg::CVA6APUConfigNumCores * 2**18;
  localparam NUM_WORDS = cva6_safe_apu_config_pkg::NUM_DCLS * 2 * 2**18;
  logic clk_i;
  logic rst_ni;
  logic rtc_i;
  logic dcls_error_o [cva6_safe_apu_config_pkg::NUM_DCLS-1:0];
  logic ecc_error_o [cva6_safe_apu_config_pkg::NUM_DCLS-1:0];

  logic        jtag_TDO_driven;

  logic        jtag_TRSTn = 1'b0;
  logic        jtag_TCK   = 1'b0;
  logic        jtag_TDI   = 1'b0;
  logic        jtag_TMS   = 1'b0;
  logic        jtag_TDO_data;

  string binary_mem;

  // Device under test instance
  cva6_safe_testharness #(
    .CVA6_CFG          ( cva6_safe_soc_pkg::build_cva6_config(
                           cva6_config_pkg::cva6_cfg)      ),
    .NUM_DCLS          ( cva6_safe_apu_config_pkg::NUM_DCLS ),
    .NUM_WORDS         ( NUM_WORDS                         ),
    .StallRandomOutput ( 1'b1                              ),
    .StallRandomInput  ( 1'b1                              )
  ) dut (
    .clk_i,
    .rst_ni,
    .jtag_TCK,
    .jtag_TMS,
    .jtag_TDI,
    .jtag_TRSTn,
    .jtag_TDO_data,
    .jtag_TDO_driven,
    .dcls_error_o,
    .ecc_error_o
  );

  function string split_using_delimiter_fn(input int offset,
      string str, string del, output int cnt);
    int i;
    cnt = offset;
    for (i = offset; i < str.len(); i=i+1)
      if (str.getc(i) == del) begin
        cnt = i;
        return str.substr(offset,i-1);
      end
    return str.substr(offset,i-1);
  endfunction

  typedef struct {
    string file;
    int unsigned base_addr;
    int unsigned start_addr;
  } binary_entry_t;
  typedef binary_entry_t binary_array_t [];

  function binary_array_t parse_binaries(input string str,
      output int cnt);
    string bs; // binary slot
    int i_offset;
    int i_next_offset;
    string bs_file;
    int bs_addr;
    int bs_next_offset;
    string bs_addr_str;
    binary_array_t ret;

    i_offset = 0;
    i_next_offset = 0;
    bs_next_offset = 0;
    cnt = 0;

    bs = split_using_delimiter_fn(i_offset, str, ",", i_next_offset);
    bs_file = split_using_delimiter_fn(0, bs, ":", bs_next_offset);
    bs_addr_str = split_using_delimiter_fn(bs_next_offset+1,
        bs, ":", bs_next_offset);
    bs_addr = bs_addr_str.atohex();
    ret = new [1];
    ret[cnt] = '{ bs_file, bs_addr, bs_addr + 'h1000 };
    cnt = cnt + 1;

    while (i_next_offset > i_offset) begin
      i_offset = i_next_offset + 1;
      bs = split_using_delimiter_fn(i_offset, str, ",", i_next_offset);
      if (i_next_offset == i_offset) continue;
      bs_file = split_using_delimiter_fn(0, bs, ":", bs_next_offset);
      bs_addr_str = split_using_delimiter_fn(bs_next_offset+1,
          bs, ":", bs_next_offset);
      bs_addr = bs_addr_str.atohex();
      ret = new [ret.size() + 1] (ret);
      ret[cnt] = '{ bs_file, bs_addr, bs_addr + 'h1000 };
      cnt = cnt + 1;
    end
    return ret;
  endfunction

  typedef logic [19:0] coreid_array_t [];
  function coreid_array_t gen_coreids();
    static int num_cores =
      (cva6_safe_apu_config_pkg::DCLS_MODE == cva6_safe_dcls_types_pkg::DC) ?
      cva6_safe_apu_config_pkg::NUM_DCLS * 2 :
      cva6_safe_apu_config_pkg::NUM_DCLS;
    automatic coreid_array_t res = new[num_cores];
    for (int unsigned coreid = 0; coreid < num_cores; coreid++) begin
      res[coreid] = 20'(coreid);
    end
    return res;
  endfunction

  initial begin
    forever begin
      rtc_i = 1'b0;
      #(RTC_CLOCK_PERIOD/2) rtc_i = 1'b1;
      #(RTC_CLOCK_PERIOD/2) rtc_i = 1'b0;
    end
  end

  // Clock process
  initial begin
    clk_i = 1'b0;
    repeat(8)
      #(CLOCK_PERIOD/2) clk_i = ~clk_i;
    forever begin
      #(CLOCK_PERIOD/2) clk_i = 1'b1;
      #(CLOCK_PERIOD/2) clk_i = 1'b0;
    end
  end

  logic dcls_error [cva6_safe_apu_config_pkg::NUM_DCLS-1:0] = '{default:0};
  always_ff @(posedge clk_i) begin
    if (dcls_error_o != dcls_error) begin
      $error("DCLS error signal change (%x)", dcls_error_o);
      dcls_error <= dcls_error_o;
    end
  end

  int binaries_count;
  binary_array_t binaries;
  int num_cores;

  // testbench driver process
  initial
  begin
    logic [1:0]  dm_op;
    logic [31:0] dm_data;
    logic [6:0]  dm_addr;
    logic        error;
    automatic logic [19:0]  FC_CORE_ID[] = gen_coreids();

    if (! $value$plusargs("binary_mem=%s", binary_mem)) begin
      $error("\"binary_mem\" variable not defined");
      $finish;
    end

    wait(clk_i);

    binaries_count = 0;
    binaries = parse_binaries(binary_mem, binaries_count);
    num_cores =
        (cva6_safe_apu_config_pkg::DCLS_MODE == cva6_safe_dcls_types_pkg::DC) ?
        cva6_safe_apu_config_pkg::NUM_DCLS * 2 :
        cva6_safe_apu_config_pkg::NUM_DCLS;

    if (binaries_count != num_cores) begin
      $error(
          "Number of binaries provided (%i) does not match number of cores (%i)",
          binaries_count, num_cores);
      $finish;
    end

    for (int unsigned coreidx = 0; coreidx < num_cores; coreidx++) begin
      $display("Loading '%s' to memory address 0x%x",
          binaries[coreidx].file, binaries[coreidx].base_addr);
      $readmemh(binaries[coreidx].file,
          dut.i_sram.gen_cut[0].i_tc_sram_wrapper.i_tc_sram.init_val,
          (binaries[coreidx].base_addr - 'h8000_0000)/64);
    end

    $display("[TB] %t - Asserting hard reset", $realtime);
    rst_ni = 1'b0;

    #10ns

    jtag_pkg::jtag_reset(jtag_TCK, jtag_TMS, jtag_TRSTn, jtag_TDI);
    jtag_pkg::jtag_softreset(jtag_TCK, jtag_TMS, jtag_TRSTn, jtag_TDI);
    #5us;
    
    rst_ni = 1'b1;

    debug_mode_if.init_dmi_access(jtag_TCK, jtag_TMS, jtag_TRSTn, jtag_TDI);

    debug_mode_if.set_dmactive(1'b1, jtag_TCK, jtag_TMS, jtag_TRSTn, jtag_TDI,
                               jtag_TDO_data);
    
    $display("Checking available harts START");
    debug_mode_if.test_discover_harts(error,
                                      jtag_TCK, jtag_TMS, jtag_TRSTn, jtag_TDI,
                                      jtag_TDO_data);
    $display("Checking available harts DONE");

    // Setup cores
    for (int unsigned coreidx = 0; coreidx < num_cores; coreidx++) begin
      debug_mode_if.set_hartsel(FC_CORE_ID[coreidx],
          jtag_TCK, jtag_TMS, jtag_TRSTn, jtag_TDI, jtag_TDO_data);
      $display("[TB] %t - Halting the Core %x", $realtime, FC_CORE_ID[coreidx]);
      debug_mode_if.halt_harts(jtag_TCK, jtag_TMS, jtag_TRSTn, jtag_TDI,
          jtag_TDO_data);

      // write dpc to addr_i so that we know where we resume
      $display(
        "[TB] %t - Writing the boot address (0x%x) into dpc of Core %x",
        $realtime, binaries[coreidx].start_addr, FC_CORE_ID[coreidx]);
      debug_mode_if.write_reg_abstract_cmd(
          riscv::CSR_DPC, binaries[coreidx].start_addr,
          jtag_TCK, jtag_TMS, jtag_TRSTn, jtag_TDI, jtag_TDO_data);
    end

    // Launch cores
    for (int unsigned coreidx = 0; coreidx < num_cores; coreidx++) begin
      debug_mode_if.set_hartsel(FC_CORE_ID[coreidx],
          jtag_TCK, jtag_TMS, jtag_TRSTn, jtag_TDI, jtag_TDO_data);
      // we have set dpc and loaded the binary, we can go now
      $display("[TB] %t - Resuming Core %x", $realtime, FC_CORE_ID[coreidx]);
      debug_mode_if.resume_harts(jtag_TCK, jtag_TMS, jtag_TRSTn, jtag_TDI,
                                 jtag_TDO_data);
    end

  end

  endmodule
