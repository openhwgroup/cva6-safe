// Copyright (c) 2024-2026 Thales.
// All Rights Reserved.
//
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
// You may obtain a copy of the License at https://solderpad.org/licenses/
//
// Author: Daniel Gracia Pérez, THALES Research and Technology
// Date: 22.01.2024
//
// Description: Creates multiple instances of a CVA6 core
//
// ========================================================================== //
// Revisions  :
// Date        Version  Author          Description
// 2024-01-22  0.1      D.Gracia Pérez  First implementation
// ========================================================================== //

module dcls_cva6_block #(
  parameter config_pkg::cva6_cfg_t CVA6_CFG = config_pkg::cva6_cfg_empty,
  parameter int unsigned NUM_DCLS = 1,
  parameter int unsigned LS_STEPS = 1,
  parameter type rvfi_probes_instr_t = logic,
  parameter type rvfi_probes_csr_t = logic,
  parameter type rvfi_probes_t = struct packed {
    logic csr;
    logic instr;
  }
) (
  input  logic                    clk_i,
  input  logic                    rst_ni,
  /* Core ID, Cluster ID and boot address are considered more or less static */
  input  logic [CVA6_CFG.VLEN-1:0]  boot_addr_i,  // reset boot address
  input  logic [CVA6_CFG.VLEN-1:0]  boot_addr_c1_i,  // reset boot address
  /* hart ids in a multicore environment (reflected in a CSR)
   * represented as an array, with one hart id for each dcls.
   * The hart ids provided are transformed when provided to each dcls depending
   * on the dcls_mode selected.
   * If the dcls_mode is dual-core then dcls[i] receives two hart ids built as
   * follows:
   * - dcls[i].core_0_hart_id = {hart_id_i[i], 0'b0}
   * - dcls[i].core_1_hart_id = {hart_id_i[i], 0'b1}
   * If the dcls_mode is lockstep then dcls[i] receives the same hart id for
   * each built as follows:
   * - dcls[i].core_0_hart_id = {1'b0, hart_id_i[i]}
   * - dcls[i].core_1_hart_id = {1'b0, hart_id_i[i]}
   */
  input  logic [CVA6_CFG.XLEN-2:0]  hart_id_i [NUM_DCLS-1:0],

  // Interrupt inputs per core START
  // level sensitive IR lines, mip & sip (async)
  input  logic [1:0]              irq_i[(NUM_DCLS*2)-1:0],
  // inter-processor interrupts (async)
  input  logic [(NUM_DCLS*2)-1:0] ipi_i,
  // time interrupt in (async)
  input  logic [(NUM_DCLS*2)-1:0] time_irq_i,
  // Interrupt inputs per core END

  // RISC-V formal interface port (`rvfi`):
  // Can be left open when formal tracing is not needed.
  output rvfi_probes_t            rvfi_probes_o[(NUM_DCLS*2)-1:0],

  // debug request (async) per core
  input  logic [(NUM_DCLS*2)-1:0] debug_req_i,

  // 1 => LS mode
  // 0 (other?) => DC mode
  input  logic                    dcls_mode_i,
  output logic                    dcls_error_o[NUM_DCLS-1:0],
  output logic                    ecc_error_o[NUM_DCLS-1:0],
  // memory side, AXI Master
  AXI_BUS                         ext_slave_bus[(NUM_DCLS*2)-1:0]
);

  genvar dcls_idx;

  generate
    for (dcls_idx = 0;
         dcls_idx < NUM_DCLS;
         dcls_idx++) begin: dcls_instantiation
      logic [CVA6_CFG.XLEN-1:0] hart_id[1:0];
      logic [1:0] irq[1:0];
      logic [1:0] ipi;
      logic [1:0] time_irq;
      logic [1:0] debug_req;
      always_comb begin: dcls_cva6_routing
        if (dcls_mode_i == cva6_safe_dcls_types_pkg::LS) begin
          // lockstep mode, pass the provided hart_id to both cores of the
          // dcls module
          hart_id[0] = { 1'b0, hart_id_i[dcls_idx] };
          hart_id[1] = { 1'b0, hart_id_i[dcls_idx] };
          irq[0] = irq_i[dcls_idx];
          irq[1] = 1'b0;
          ipi[0] = ipi_i[dcls_idx];
          ipi[1] = 1'b0;
          time_irq[0] = time_irq_i[dcls_idx];
          time_irq[1] = 1'b0;
          debug_req[0] = debug_req_i[dcls_idx];
          debug_req[1] = 1'b0;
        end else begin
          // dual-core mode, each core of the dcls requires a different hart_id
          // pass the provided hart_id shifted left by one bit and setting the
          // low bit to 0 and 1 to each of the cores respectively
          hart_id[0] = { hart_id_i[dcls_idx], 1'b0 };
          hart_id[1] = { hart_id_i[dcls_idx], 1'b1 };
          irq[0] = irq_i[dcls_idx*2];
          irq[1] = irq_i[(dcls_idx*2)+1];
          ipi[0] = ipi_i[dcls_idx*2];
          ipi[1] = ipi_i[(dcls_idx*2)+1];
          time_irq[0] = time_irq_i[dcls_idx*2];
          time_irq[1] = time_irq_i[(dcls_idx*2)+1];
          debug_req[0] = debug_req_i[dcls_idx*2];
          debug_req[1] = debug_req_i[(dcls_idx*2)+1];
        end
      end

      dcls_cva6 #(
        .CVA6_CFG            ( CVA6_CFG            ),
        .LS_STEPS            ( LS_STEPS            ),
        .rvfi_probes_instr_t ( rvfi_probes_instr_t ),
        .rvfi_probes_csr_t   ( rvfi_probes_csr_t   ),
        .rvfi_probes_t       ( rvfi_probes_t       )
      ) i_dcls_cva6 (
        .clk_i         ( clk_i                                    ),
        .rst_ni        ( rst_ni                                   ),
        .boot_addr_i   ( boot_addr_i                              ),
        .boot_addr_c1_i   ( boot_addr_c1_i                              ),
        .hart_id_i     ( hart_id[1:0]                             ),
        .irq_i         ( irq[1:0]                                 ),
        .ipi_i         ( ipi[1:0]                                 ),
        .time_irq_i    ( time_irq[1:0]                            ),
        .rvfi_probes_o ( rvfi_probes_o[(dcls_idx*2)+1:dcls_idx*2] ),
        .debug_req_i   ( debug_req[1:0]                           ),
        .dcls_mode_i   ( dcls_mode_i                              ),
        .dcls_error_o  ( dcls_error_o[dcls_idx]                   ),
        .ecc_error_o  ( ecc_error_o[dcls_idx]                   ),
        .ext_slave_bus ( ext_slave_bus[(dcls_idx*2)+1:dcls_idx*2] )
      );
    end
  endgenerate

endmodule