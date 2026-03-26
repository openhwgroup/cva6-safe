// Copyright (c) 2023-2026 Thales.
// All Rights Reserved.
//
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
// You may obtain a copy of the License at https://solderpad.org/licenses/
//
// Author: Daniel Gracia Pérez, Thales TRT cortAIx Labs
// Date: 12.10.2023
//
// Description:
//   Host core tile for the CVA6-Safe processor.
//   Contains a dual-core CVA6 to be connected to the system bus and a minimal
//   set of peripherals (debug module, CLINT, PLIC, Boot Rom). The peripherals
//   are connected through a single AXI interface.
//   The main interface of this module is the master AXI interfaces from the
//   dual-core and the master/slave AXI interface to communicate with the
//   module peripherals.
//   The AXI interfaces are to be connected to the main system bus.
//
// ============================================================================
// Revisions:
// Date-Version-Author-Description
// ============================================================================

module cva6_safe_host_core #(
  parameter cva6_safe_host_core_support_pkg::config_t CFG =
      cva6_safe_host_core_support_pkg::build_config(
          config_pkg::cva6_cfg_empty, 1, 0, 1),
  // TODO: localparam doesn't seem to work with Questa
  parameter config_pkg::cva6_cfg_t CVA6_CFG = CFG.Cva6Cfg,
  parameter int unsigned NUM_IRQ_SOURCES = CFG.NumExtIrqSources,
  parameter int unsigned NUM_DCLS = CFG.NumDcls,
  parameter type rvfi_probes_instr_t = logic,
  parameter type rvfi_probes_csr_t = logic,
  parameter type rvfi_probes_t = struct packed {
    logic csr;
    logic instr;
  }
) (
  input  logic                       clk_i,
  // input  logic                       rtc_i,
  input  logic [CVA6_CFG.VLEN-1:0]  boot_addr_i,  // reset boot address
  input  logic [CVA6_CFG.VLEN-1:0]  boot_addr_c1_i,  // reset boot address
  input  logic                       rst_ni,
  input  logic                       jtag_TCK_i,
  input  logic                       jtag_TMS_i,
  input  logic                       jtag_TDI_i,
  input  logic                       jtag_TRST_ni,
  output logic                       jtag_TDO_data_o,
  output logic                       jtag_TDO_driven_o,
  input  logic [NUM_IRQ_SOURCES-1:0] irq_i,
  output logic                       ndmreset_o,
  input  logic                       ndmreset_ni,
  // RISC-V formal interface port (`rvfi`):
  // Can be left open when formal tracing is not needed.
  output rvfi_probes_t               rvfi_probes_o[(NUM_DCLS*2)-1:0],
  // 1 => LS mode
  // 0 (other?) => DC mode
  input  logic                       dcls_mode_i,
  output logic                       dcls_error_o[NUM_DCLS-1:0],
  output logic                       ecc_error_o[NUM_DCLS-1:0],
  // there are (NUM_DCLS*2)+1 masters, one for each core of a DCLS and
  // one for the support bus
  AXI_BUS                            ext_slave_bus[(NUM_DCLS*2)-1+1:0],
  AXI_BUS                            ext_master_bus
);

  localparam int unsigned AXI_ADDRESS_WIDTH = CVA6_CFG.AxiAddrWidth;
  localparam int unsigned AXI_DATA_WIDTH    = CVA6_CFG.AxiDataWidth;
  localparam int unsigned AXI_USER_WIDTH    = CVA6_CFG.AxiUserWidth;
  // localparam int unsigned AXI_USER_EN       = CVA6_CFG.AXI_USER_EN;
  localparam int unsigned AXI_ID_WIDTH      = CVA6_CFG.AxiIdWidth;

  logic test_en = 1'b0;
  // logic ndmreset_n;
  // assign ndmreset_no = ndmreset_n;
  logic [(NUM_DCLS*2)-1:0] debug_req_core;

  logic [(NUM_DCLS*2)-1:0] ipi;
  logic [(NUM_DCLS*2)-1:0] time_irq;
  logic [1:0]              irq_to_core[(NUM_DCLS*2)-1:0];

  genvar core_idx;
  typedef logic [CVA6_CFG.XLEN-2:0] hart_id_t;
  typedef hart_id_t hart_ids_t [NUM_DCLS-1:0];
  function hart_ids_t gen_hart_ids();
    hart_ids_t ids;
    for (int i = 0; i < NUM_DCLS; i++) begin
      ids[i] = hart_id_t'(i);
    end
    return ids;
  endfunction
  hart_ids_t hart_ids;
  assign hart_ids = gen_hart_ids(); 

  dcls_cva6_block #(
    .CVA6_CFG          ( CVA6_CFG          ),
    .NUM_DCLS          ( NUM_DCLS          ),
    .rvfi_probes_instr_t ( rvfi_probes_instr_t ),
    .rvfi_probes_csr_t   ( rvfi_probes_csr_t   ),
    .rvfi_probes_t       ( rvfi_probes_t       )
    // let defaults for:
    // - LS_STEPS
  ) i_dlcs_block (
    .clk_i         ( clk_i                           ),
    .rst_ni        ( ndmreset_ni                      ),
    .boot_addr_i   ( boot_addr_i                       ),
    .boot_addr_c1_i( boot_addr_c1_i                 ),
    .hart_id_i     ( hart_ids                        ),
    .irq_i         ( irq_to_core                     ),
    .ipi_i         ( ipi                             ),
    .time_irq_i    ( time_irq                        ),
    .debug_req_i   ( debug_req_core                  ),
    .rvfi_probes_o ( rvfi_probes_o                   ),
    .dcls_mode_i   ( dcls_mode_i                     ),
    .dcls_error_o  ( dcls_error_o                    ),
    .ecc_error_o  ( ecc_error_o                    ),
    .ext_slave_bus ( ext_slave_bus[(NUM_DCLS*2)-1:0] )
  );

  cva6_safe_host_core_support #(
    .CFG ( CFG )
  ) i_cva6_safe_host_core_support (
    .clk_i             ( clk_i                     ),
    // .rtc_i             ( rtc_i                     ),
    .rst_ni            ( rst_ni                    ),
    .test_en_i         ( test_en                   ),
    .ndmreset_o        ( ndmreset_o                ),
    .ndmreset_ni       ( ndmreset_ni               ),
    .jtag_TCK_i        ( jtag_TCK_i                ),
    .jtag_TMS_i        ( jtag_TMS_i                ),
    .jtag_TDI_i        ( jtag_TDI_i                ),
    .jtag_TRST_ni      ( jtag_TRST_ni              ),
    .jtag_TDO_data_o   ( jtag_TDO_data_o           ),
    .jtag_TDO_driven_o ( jtag_TDO_driven_o         ),
    .debug_req_core_o  ( debug_req_core            ),
    .ipi_o             ( ipi                       ),
    .timer_irq_o       ( time_irq                  ),
    .irq_o             ( irq_to_core               ),
    .irq_i             ( irq_i                     ),
    .dcls_mode_i       ( dcls_mode_i               ),
    .ext_slave_bus     ( ext_slave_bus[NUM_DCLS*2] ),
    .ext_master_bus    ( ext_master_bus            )
  );

endmodule