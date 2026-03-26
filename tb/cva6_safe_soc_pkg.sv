// Copyright (c) 2023-2026 Thales.
// All Rights Reserved.
//
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
// You may obtain a copy of the License at https://solderpad.org/licenses/
//
// Author: Daniel Gracia Pérez, Thales TRT cortAIx Labs
// Date: 06.09.2023
//
// Description: Configuration parameters for NeuroSoC SoC
//
// ========================================================================== //
// Revisions  :
// Date        Version  Author          Description
// 2023-09-06  0.1      D.Gracia Pérez  first release
// ========================================================================== //

package cva6_safe_soc_pkg;
  // *_NUM_SLAVES: actually masters, but slaves on the crossbars
  // *_NUM_MASTERS: actually slaves, but masters on the crossbars
  // number of cores + connection from support bus
  // localparam SYSTEM_BUS_NUM_SLAVES =
  //   cva6_apu_config_pkg::CVA6APUConfigNumCores + 1;
  localparam SYSTEM_BUS_NUM_SLAVES =
      (cva6_safe_apu_config_pkg::NUM_DCLS * 2) + 1;
  // memory + connection to support bus + UART
  localparam SYSTEM_BUS_NUM_MASTERS = 5;
  // localparam SUPPORT_BUS_NUM_MASTERS = cva6_support_pkg::NUM_AXI_SLAVES + 1;

  // the AXI_ID_WIDTH should be set by the CVA6 cores configuration
  // localparam AXI_ID_WIDTH       = 4;
  function automatic int unsigned AXI_ID_WIDTH_SLAVE(int unsigned AxiIdWidth);
    int unsigned ret = AxiIdWidth + $clog2(SYSTEM_BUS_NUM_SLAVES);
    return ret;
  endfunction
  // localparam AXI_ID_WIDTH_SLAVE = AXI_ID_WIDTH + $clog2(SYSTEM_BUS_NUM_SLAVES);

  typedef enum int unsigned {
    SYSTEM_BUS_MASTER_DRAM    = 0,
    SYSTEM_BUS_MASTER_ROM_0   = 1,
    SYSTEM_BUS_MASTER_ROM_1   = 2,
    SYSTEM_BUS_MASTER_SUPPORT = 3,
    SYSTEM_BUS_MASTER_UART    = 4
  } system_bus_master_t;

  typedef enum int unsigned {
    SYSTEM_BUS_SLAVE_CORE_BASE = 0,
    // SYSTEM_BUS_SLAVE_SUPPORT   = cva6_apu_config_pkg::CVA6APUConfigNumCores
    SYSTEM_BUS_SLAVE_SUPPORT   = cva6_safe_apu_config_pkg::NUM_DCLS * 2
  } system_bus_slave_t;

  localparam logic[63:0] SUPPORT_BASE  = 64'h0000_0000;
  // TODO: we should asset that the UART_BASE is after the neurosoc tile
  // length (actually the neurosoc support embedded in the neurosoc tile)
  localparam logic[63:0] UART_BASE      = 64'h2000_0000;
  localparam logic[63:0] ROM_0_BASE     = 64'h7000_0000;
  localparam logic[63:0] ROM_1_BASE     = 64'h7008_0000;
  localparam logic[63:0] DRAM_BASE      = 64'h8000_0000;
  localparam logic[63:0] SYSTEM_BASE    = UART_BASE;

  localparam logic[63:0] UART_LENGTH    = 64'h1000;
  localparam logic[63:0] ROM_0_LENGTH    = 64'h1_0000;
  localparam logic[63:0] ROM_1_LENGTH    = 64'h1_0000;
  localparam logic[63:0] DRAM_LENGTH    = 64'h4000_0000; // 1GByte of DDR (split between two chips on Genesys2)
  localparam logic[63:0] SUPPORT_LENGTH =
      cva6_safe_host_core_support_pkg::SUPPORT_LENGTH;
  localparam logic[63:0] SYSTEM_LENGTH  = (DRAM_BASE - UART_BASE) + DRAM_LENGTH;

  localparam logic[63:0] ROM_BASE =
      SUPPORT_BASE + cva6_safe_host_core_support_pkg::ROM_BASE;
  localparam logic[63:0] ROM_LENGTH =
      cva6_safe_host_core_support_pkg::ROM_LENGTH;
  localparam logic[63:0] DEBUG_BASE =
      SUPPORT_BASE + cva6_safe_host_core_support_pkg::DEBUG_BASE;
  localparam logic[63:0] DEBUG_LENGTH =
      SUPPORT_BASE + cva6_safe_host_core_support_pkg::DEBUG_LENGTH;

  function automatic config_pkg::cva6_cfg_t build_cva6_config(
    config_pkg::cva6_user_cfg_t UserCfg
  );
    config_pkg::cva6_cfg_t cfg;
    cfg = build_config_pkg::build_config(UserCfg);
    cfg.NrExecuteRegionRules = unsigned'(4);
    cfg.ExecuteRegionAddrBase = 1024'( {cva6_safe_soc_pkg::DRAM_BASE,
      cva6_safe_soc_pkg::ROM_0_BASE, cva6_safe_soc_pkg::ROM_1_BASE,
      cva6_safe_soc_pkg::DEBUG_BASE} );
    cfg.ExecuteRegionLength = 1024'( {cva6_safe_soc_pkg::DRAM_LENGTH,
      cva6_safe_soc_pkg::ROM_0_LENGTH, cva6_safe_soc_pkg::ROM_1_LENGTH,
      cva6_safe_soc_pkg::DEBUG_LENGTH} );

    return cfg;
  endfunction

endpackage