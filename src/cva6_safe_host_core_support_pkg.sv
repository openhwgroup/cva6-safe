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
// Description: Configuration parameters of the neurosoc support module which
//              itself is embedded in the neurosoco host core tile.
//
// ========================================================================== //
// Revisions  :
// Date        Version  Author       Description
// ========================================================================== //

package cva6_safe_host_core_support_pkg;
  localparam int unsigned SUPPORT_BUS_NUM_MASTERS = 5;
  localparam int unsigned SUPPORT_BUS_NUM_SLAVES  = 2;
  // 4 is recommended by AXI standard, so lets stick to it, do not change
  localparam SUPPORT_BUS_ID_WIDTH = 4;
  localparam SUPPORT_BUS_ID_WIDTH_SLAVE =
    SUPPORT_BUS_ID_WIDTH + $clog2(SUPPORT_BUS_NUM_SLAVES);
  
  // port indexes for support bus master connectons
  typedef enum int unsigned {
    SUPPORT_BUS_MASTER_DEBUG_PORT = 0,
    //SUPPORT_BUS_MASTER_ROM_PORT = 1,
    SUPPORT_BUS_MASTER_CLINT_PORT = 1,
    SUPPORT_BUS_MASTER_PLIC_PORT = 2,
    SUPPORT_BUS_MASTER_TIMER_PORT = 3,
    SUPPORT_BUS_MASTER_SYSTEM_PORT = 4
  } support_bus_master_port_idx_t;
  // port indexes for support bus slave connections
  typedef enum int unsigned {
    SUPPORT_BUS_SLAVE_DEBUG_PORT = 0,
    SUPPORT_BUS_SLAVE_SYSTEM_PORT = 1
  } support_bus_slave_port_idx_t;

  localparam logic[63:0] DEBUG_BASE    = 64'h0000_0000;
  localparam logic[63:0] ROM_BASE      = 64'h0001_0000;
  localparam logic[63:0] CLINT_BASE    = 64'h0200_0000;
  localparam logic[63:0] PLIC_BASE     = 64'h0C00_0000;
  localparam logic[63:0] TIMER_BASE    = 64'h1000_0000;

  localparam logic[63:0] DEBUG_LENGTH    = 64'h1000;
  localparam logic[63:0] ROM_LENGTH      = 64'h10000;
  localparam logic[63:0] CLINT_LENGTH    = 64'hC0000;
  localparam logic[63:0] PLIC_LENGTH     = 64'h3FF_FFFF;
  localparam logic[63:0] TIMER_LENGTH    = 64'h1000;
  localparam logic[63:0] SUPPORT_LENGTH = TIMER_BASE + TIMER_LENGTH;

  typedef struct packed {
    config_pkg::cva6_cfg_t Cva6Cfg;
    int unsigned NumDcls;
    int unsigned AxiIdWidthSlave;
    // Number of IRQ input port instantiated for external IRQs in the PLIC
    int unsigned NumExtIrqSources;
    // Maximum interrupt priority supported by the PLIC (7 == 8 priorities)
    int unsigned MaxInterruptPrio;
    // Support base address
    logic[63:0]  SupportBase;
    // System base address and length
    logic[63:0]  SystemBase;
    logic[63:0]  SystemLength;
    // Parameters for the system bus to support bus converter
    int unsigned SystemToSupportAxiSlvPortMaxUniqIds;
    int unsigned SystemToSupportAxiSlvPortMaxTxnsPerId;
    int unsigned SystemToSupportAxiSlvPortMaxTxns;
    int unsigned SystemToSupportAxiMstPortMaxUniqIds;
    int unsigned SystemToSupportAxiMstPortMaxTxnsPerId;
    // Parameters for the support bus to system bus converter
    int unsigned SupportToSystemAxiSlvPortMaxUniqIds;
    int unsigned SupportToSystemAxiSlvPortMaxTxnsPerId;
    int unsigned SupportToSystemAxiSlvPortMaxTxns;
    int unsigned SupportToSystemAxiMstPortMaxUniqIds;
    int unsigned SupportToSystemAxiMstPortMaxTxnsPerId;
  } config_t;

  function automatic config_t build_config(
      config_pkg::cva6_cfg_t cva6_cfg,
      int unsigned num_dcls,
      int unsigned axi_id_width_slave,
      int unsigned num_ext_irq_sources);
    config_t cfg;
    cfg.Cva6Cfg = cva6_cfg;
    cfg.NumDcls = num_dcls;
    cfg.AxiIdWidthSlave = axi_id_width_slave;
    cfg.NumExtIrqSources = num_ext_irq_sources;
    cfg.MaxInterruptPrio = 7;
    cfg.SupportBase = 64'h0000_0000;
    // we set SYSTEM_BASE as the first aligned 256MB after
    // the value of cva6_safe_host_core_support_pkg::SUPPORT_LENGTH (64'h10001000)
    cfg.SystemBase = 64'h2000_0000;
    cfg.SystemLength = 64'h8000_0000; // 2GByte
    cfg.SystemToSupportAxiSlvPortMaxUniqIds =
        unsigned'(2**axi_id_width_slave);
    cfg.SystemToSupportAxiSlvPortMaxTxnsPerId = unsigned'(1);
    cfg.SystemToSupportAxiSlvPortMaxTxns = unsigned'(1);
    cfg.SystemToSupportAxiMstPortMaxUniqIds =
        unsigned'(2**SUPPORT_BUS_ID_WIDTH);
    cfg.SystemToSupportAxiMstPortMaxTxnsPerId = unsigned'(1);
    cfg.SupportToSystemAxiSlvPortMaxUniqIds =
        unsigned'(2**SUPPORT_BUS_ID_WIDTH_SLAVE);
    cfg.SupportToSystemAxiSlvPortMaxTxnsPerId = unsigned'(1);
    cfg.SupportToSystemAxiSlvPortMaxTxns = unsigned'(1);
    cfg.SupportToSystemAxiMstPortMaxUniqIds =
        unsigned'(2**cva6_cfg.AxiIdWidth);
    cfg.SupportToSystemAxiMstPortMaxTxnsPerId = unsigned'(1);
    return cfg;
  endfunction

endpackage