// Copyright (c) 2024 Thales SA
//
// Author: Daniel Gracia Pérez, Thales Research and Technology cortAIx Labs
//         <daniel.gracia-perez@thalesgroup.com>
//
// Description: Configuration parameters for cva6-safe SoC for FPGA
//
// ========================================================================== //
// Revisions  :
// Date        Version  Author          Description
// 2024-03     0.1      D.Gracia Pérez  first release
// ========================================================================== //

package dcls_soc_pkg;
  // *_NUM_SLAVES: actually masters, but slaves on the crossbars
  // *_NUM_MASTERS: actually slaves, but masters on the crossbars
  // number of cores + connection from support bus
  // localparam SYSTEM_BUS_NUM_SLAVES =
  //   cva6_apu_config_pkg::CVA6APUConfigNumCores + 1;
  localparam SYSTEM_BUS_NUM_SLAVES =
      (cva6_safe_apu_config_pkg::NUM_DCLS * 2) + 1;
  // memory + connection to support bus + UART + SPI + Ethernet + GPIO
  localparam SYSTEM_BUS_NUM_MASTERS = 8;
  // localparam SUPPORT_BUS_NUM_MASTERS = cva6_support_pkg::NUM_AXI_SLAVES + 1;
  localparam NUM_EXT_IRQ_SOURCES = 3; // UART + SPI + Ethernet

  // the AXI_ID_WIDTH should be set by the CVA6 cores configuration
  // localparam AXI_ID_WIDTH       = 4;
  function automatic int unsigned AXI_ID_WIDTH_SLAVE(int unsigned AxiIdWidth);
    int unsigned ret = AxiIdWidth + $clog2(SYSTEM_BUS_NUM_SLAVES);
    return ret;
  endfunction
  // localparam AXI_ID_WIDTH_SLAVE = AXI_ID_WIDTH + $clog2(SYSTEM_BUS_NUM_SLAVES);

  typedef enum int unsigned {
    SYSTEM_BUS_MASTER_SUPPORT  = 0,
    SYSTEM_BUS_MASTER_UART     = 1,
    SYSTEM_BUS_MASTER_SPI      = 2,
    SYSTEM_BUS_MASTER_ETHERNET = 3,
    SYSTEM_BUS_MASTER_GPIO     = 4,
    SYSTEM_BUS_MASTER_ROM_0    = 5,
    SYSTEM_BUS_MASTER_ROM_1    = 6,
    SYSTEM_BUS_MASTER_DRAM     = 7
  } system_bus_master_t;

  typedef enum int unsigned {
    SYSTEM_BUS_SLAVE_CORE_BASE = 0,
    // SYSTEM_BUS_SLAVE_SUPPORT   = cva6_apu_config_pkg::CVA6APUConfigNumCores
    SYSTEM_BUS_SLAVE_SUPPORT   = cva6_safe_apu_config_pkg::NUM_DCLS * 2
  } system_bus_slave_t;

  localparam logic[63:0] SUPPORT_BASE  = 64'h0000_0000;
  // TODO: we should assess that the UART_BASE is after the cva6_safe tile
  // length (actually the cva6_safe support embedded in the cva6_safe tile)
  localparam logic[63:0] UART_BASE      = 64'h5000_0000;
  localparam logic[63:0] SPI_BASE       = 64'h2000_0000;
  localparam logic[63:0] ETHERNET_BASE  = 64'h3000_0000;
  localparam logic[63:0] GPIO_BASE      = 64'h4000_0000;
  localparam logic[63:0] ROM_0_BASE      = 64'h7000_0000;
  localparam logic[63:0] ROM_1_BASE      = 64'h7008_0000;
  localparam logic[63:0] DRAM_BASE      = 64'h8000_0000;
  localparam logic[63:0] SYSTEM_BASE    = SPI_BASE;

  localparam logic[63:0] UART_LENGTH     = 64'h1000;
  localparam logic[63:0] SPI_LENGTH      = 64'h80_0000;
  localparam logic[63:0] ETHERNET_LENGTH = 64'h1_0000;
  localparam logic[63:0] GPIO_LENGTH     = 64'h1000;
  localparam logic[63:0] ROM_0_LENGTH     = 64'h1_0000;
  localparam logic[63:0] ROM_1_LENGTH     = 64'h1_0000;
  localparam logic[63:0] DRAM_LENGTH     = 64'h4000_0000; // 1GByte of DDR (split between two chips on Genesys2)
  localparam logic[63:0] SUPPORT_LENGTH  = cva6_safe_host_core_support_pkg::SUPPORT_LENGTH;
  localparam logic[63:0] SYSTEM_LENGTH   = (DRAM_BASE - SYSTEM_BASE) + DRAM_LENGTH;

  localparam logic[63:0] ROM_BASE =
    SUPPORT_BASE + cva6_safe_host_core_support_pkg::ROM_BASE;
  localparam logic[63:0] ROM_LENGTH = cva6_safe_host_core_support_pkg::ROM_LENGTH;
  localparam logic[63:0] DEBUG_BASE =
    SUPPORT_BASE + cva6_safe_host_core_support_pkg::DEBUG_BASE;
  localparam logic[63:0] DEBUG_LENGTH =
    SUPPORT_BASE + cva6_safe_host_core_support_pkg::DEBUG_LENGTH;

endpackage
