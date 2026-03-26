// Copyright (c) 2023-2026 Thales
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
// Contributors: Abdou Lahat NDIAYE, Thales cortAIx Labs
//
// Description: Creates multiple instances of a CVA6 core
//
// ========================================================================== //
// Revisions  :
// Date        Version  Author              Description
// 2025-09-16  0.3      Abdou Lahat NDIAYE  Proper signal initialization and
//                      added comments for error detection logic across modes.
// 2025-01-29  0.2      Abdou Lahat NDIAYE  Srams of cache outside the cores
// 2023-09-06  0.1      D.Gracia Pérez      first functional release
// ========================================================================== //

`include "axi/assign.svh"
`include "axi/typedef.svh"

module dcls_cva6
#(
  parameter config_pkg::cva6_cfg_t CVA6_CFG = config_pkg::cva6_cfg_empty,
  parameter int unsigned LS_STEPS = 1,
  parameter type rvfi_probes_instr_t = logic,
  parameter type rvfi_probes_csr_t = logic,
  parameter type rvfi_probes_t = struct packed {
    logic csr;
    logic instr;
  }
) (
  input  logic                   clk_i,
  input  logic                   rst_ni,
  // boot address
  input  logic [CVA6_CFG.VLEN-1:0] boot_addr_i,  // reset boot address
  input  logic [CVA6_CFG.VLEN-1:0] boot_addr_c1_i,  // reset boot address for core 1
  // hart ids for each core
  input logic [CVA6_CFG.XLEN-1:0]  hart_id_i[1:0],

  // Interrupt inputs per core START
  // level sensitive IR lines, mip & sip (async)
  input  logic [1:0]             irq_i[1:0],
  // inter-processor interrupts (async)
  input  logic [1:0]             ipi_i,
  // time interrupt in (async)
  input  logic [1:0]             time_irq_i,
  // Interrupt inputs per core END

  // RISC-V formal interface port (`rvfi`):
  // Can be left open when formal tracing is not needed.
  output rvfi_probes_t            rvfi_probes_o[1:0],

  // debug request (async) per core
  input  logic [1:0]             debug_req_i,

  // 1 => LS mode
  // 0 (other?) => DC mode
  input  logic                   dcls_mode_i,
  output logic                   dcls_error_o,
  output logic                   ecc_error_o,

  // memory side, AXI Master
  AXI_BUS                        ext_slave_bus[1:0]
);

  localparam int unsigned AXI_ADDRESS_WIDTH = CVA6_CFG.AxiAddrWidth;
  localparam int unsigned AXI_DATA_WIDTH    = CVA6_CFG.AxiDataWidth;
  localparam int unsigned AXI_USER_WIDTH    = CVA6_CFG.AxiUserWidth;
  // localparam int unsigned AXI_USER_EN       = CVA6_CFG.AXI_USER_EN;
  localparam int unsigned AXI_ID_WIDTH      = CVA6_CFG.AxiIdWidth;

  typedef logic [AXI_ID_WIDTH-1:0]
    axi_mst_id_t;
  typedef logic [AXI_ADDRESS_WIDTH-1:0]
    axi_mst_addr_t;
  typedef logic [AXI_DATA_WIDTH-1:0]
    axi_mst_data_t;
  typedef logic [(AXI_DATA_WIDTH/8)-1:0]
    axi_mst_strb_t;
  typedef logic [AXI_USER_WIDTH-1:0]
    axi_mst_user_t;
  `AXI_TYPEDEF_ALL(axi_mst,
      axi_mst_addr_t,
      axi_mst_id_t,
      axi_mst_data_t,
      axi_mst_strb_t,
      axi_mst_user_t)

  axi_mst_req_t  axi_m_req[1:0];
  axi_mst_resp_t axi_m_resp[1:0];

  `AXI_ASSIGN_FROM_REQ(
    ext_slave_bus[0],
    axi_m_req[0] )
  `AXI_ASSIGN_TO_RESP(
    axi_m_resp[0],
    ext_slave_bus[0] )
  `AXI_ASSIGN_FROM_REQ(
    ext_slave_bus[1],
    axi_m_req[1] )
  `AXI_ASSIGN_TO_RESP(
    axi_m_resp[1],
    ext_slave_bus[1] )

  dcls_cva6_cache_pkg::dcache_ext_req_t dcache_req;
  dcls_cva6_cache_pkg::dcache_ext_resp_t dcache_resp;
  dcls_cva6_cache_pkg::icache_ext_req_t icache_req;
  dcls_cva6_cache_pkg::icache_ext_resp_t icache_resp;

  dcls_cva6_cache_pkg::dcache_ext_req_t dcache_req_c1;
  dcls_cva6_cache_pkg::dcache_ext_resp_t dcache_resp_c1;
  dcls_cva6_cache_pkg::icache_ext_req_t icache_req_c1;
  dcls_cva6_cache_pkg::icache_ext_resp_t icache_resp_c1;

  dcls_cva6_cache_pkg::dcache_ext_req_t dcache_req_sr1;
  dcls_cva6_cache_pkg::dcache_ext_resp_t dcache_resp_sr1;
  dcls_cva6_cache_pkg::icache_ext_req_t icache_req_sr1;
  dcls_cva6_cache_pkg::icache_ext_resp_t icache_resp_sr1;

  logic dcache_ecc_error;

  dcls_cache_sram #(
      .CVA6Cfg(CVA6_CFG)
    ) i_sram_macros (
      .clk_i          (clk_i),
      .rst_ni         (rst_ni),
      .dcache_ecc_error_i(dcache_ecc_error),
      .dcache_req(dcache_req),
      .dcache_resp(dcache_resp),
      .icache_req(icache_req),
      .icache_resp(icache_resp)
  );

  // In LS mode: used for error detection by comparing duplicated data caches in SRAM.
  // In AMP mode: acts as the SRAM data & instruction cache for the second core.
  dcls_cache_sram #(
      .CVA6Cfg(CVA6_CFG)
    ) i_sram_macros_ecc1 (
      .clk_i          (clk_i),
      .rst_ni         (rst_ni),
      .dcache_ecc_error_i(dcache_ecc_error),
      .dcache_req(dcache_req_sr1),
      .dcache_resp(dcache_resp_sr1),
      .icache_req(icache_req_sr1),
      .icache_resp(icache_resp_sr1)
  );

  logic [CVA6_CFG.VLEN-1:0] boot_addr_c1;
    // Routing of output signals
  always_comb begin: dcls_boot_addr_c1
    if (dcls_mode_i == cva6_safe_dcls_types_pkg::LS) begin
      boot_addr_c1 = boot_addr_i;
    end else begin
      boot_addr_c1 = boot_addr_c1_i;;
    end
  end
  // The first core can be directly connected to inputs and outputs
  ariane #(
    .CVA6Cfg             ( CVA6_CFG            ),
    .rvfi_probes_instr_t ( rvfi_probes_instr_t ),
    .rvfi_probes_csr_t   ( rvfi_probes_csr_t   ),
    .rvfi_probes_t       ( rvfi_probes_t       ),
    .axi_ar_chan_t       ( axi_mst_ar_chan_t   ),
    .axi_aw_chan_t       ( axi_mst_aw_chan_t   ),
    .axi_w_chan_t        ( axi_mst_w_chan_t    ),
    .noc_req_t           ( axi_mst_req_t       ),
    .noc_resp_t          ( axi_mst_resp_t      )
  ) i_ariane_0 (
    .clk_i         ( clk_i            ),
    .rst_ni        ( rst_ni           ),
    .boot_addr_i   ( boot_addr_i      ),
    .hart_id_i     ( hart_id_i[0]     ),
    .irq_i         ( irq_i[0]         ),
    .ipi_i         ( ipi_i[0]         ),
    .time_irq_i    ( time_irq_i[0]    ),
    .rvfi_probes_o ( rvfi_probes_o[0] ),
    .debug_req_i   ( debug_req_i[0]   ),
    .noc_req_o     ( axi_m_req[0]     ),
    .noc_resp_i    ( axi_m_resp[0]    ),
    // sram extern ports
    .dcache_req(dcache_req),
    .dcache_resp(dcache_resp),
    .icache_req(icache_req),
    .icache_resp(icache_resp)
  );

  `define STEP_INIT(__STEPVAR__, __VAL__, __NSTEPS__) \
    for (int unsigned idx = 0; idx < __NSTEPS__; idx++) \
      __STEPVAR__[idx] <= __VAL__;

  `define STEP(__STEPVAR__, __IN__, __NSTEPS__) \
    for (int unsigned idx = __NSTEPS__ - 1; idx > 0; idx--) \
      __STEPVAR__[idx] <= __STEPVAR__[idx-1]; \
    __STEPVAR__[0] <= __IN__;

  // Keep track of which step stages have been already initialized.
  // This valid signal has an additional cycle when compared with the
  // rest of stepped signals. We let an additional cycle to the core
  // so it can produce the first outputs to be checked.
  logic step_valid[LS_STEPS:0]; //  = '{LS_STEPS+1{1'b0}};
  // Delay input signals for lockstep mode, one for each of the core inputs.
  axi_mst_resp_t axi_m_resp_step[LS_STEPS-1:0];
  logic [1:0] irq_i_step[LS_STEPS-1:0];
  logic ipi_i_step[LS_STEPS-1:0];
  logic time_irq_i_step[LS_STEPS-1:0];
  logic debug_req_i_step[LS_STEPS-1:0];
  logic rst_ni_step[LS_STEPS-1:0]; //  = '{LS_STEPS{1'b0}};

  // Lockstep of input signals (to the lockstep core)
  // always_ff @(posedge clk_i iff dcls_mode_i == 1'b1) begin: ls_axi_m_resp
  // always_ff @(posedge clk_i or negedge rst_ni iff dcls_mode_i == 1'b1) begin: ls_axi_m_resp
  always_ff @(posedge clk_i or negedge rst_ni) begin: ls_axi_m_resp
    if (!rst_ni) begin
      `STEP_INIT(step_valid, 1'b0, LS_STEPS+1);
      `STEP_INIT(axi_m_resp_step, '0, LS_STEPS);
      `STEP_INIT(irq_i_step, 1'b0, LS_STEPS);
      `STEP_INIT(ipi_i_step, 1'b0, LS_STEPS);
      `STEP_INIT(time_irq_i_step, 1'b0, LS_STEPS);
      `STEP_INIT(debug_req_i_step, 1'b0, LS_STEPS);
      `STEP_INIT(rst_ni_step, 1'b0, LS_STEPS);
    end else if (dcls_mode_i == cva6_safe_dcls_types_pkg::LS) begin
      `STEP(step_valid, rst_ni, LS_STEPS+1);
      `STEP(axi_m_resp_step, axi_m_resp[0], LS_STEPS);
      `STEP(irq_i_step, irq_i[0], LS_STEPS);
      `STEP(ipi_i_step, ipi_i[0], LS_STEPS);
      `STEP(time_irq_i_step, time_irq_i[0], LS_STEPS);
      `STEP(debug_req_i_step, debug_req_i[0], LS_STEPS);
      `STEP(rst_ni_step, rst_ni, LS_STEPS);
    end
  end

  // Delay output signals for lockstep mode, one for each of the core outputs.
  axi_mst_req_t axi_m_req_step[LS_STEPS-1:0];
  // Lockstep of output signals (from the master core)
  always_ff @(posedge clk_i or negedge rst_ni) begin: ls_axi_m_req
    if (!rst_ni) begin
      `STEP_INIT(axi_m_req_step, '0, LS_STEPS);
    end else if (dcls_mode_i == cva6_safe_dcls_types_pkg::LS) begin
      `STEP(axi_m_req_step, axi_m_req[0], LS_STEPS);
    end
  end

  // Delay signals for lockstep mode, one for each of the core.
  dcls_cva6_cache_pkg::dcache_ext_req_t dcache_req_step[LS_STEPS-1:0];
  dcls_cva6_cache_pkg::dcache_ext_resp_t dcache_resp_step[LS_STEPS-1:0];
  dcls_cva6_cache_pkg::icache_ext_req_t icache_req_step[LS_STEPS-1:0];
  dcls_cva6_cache_pkg::icache_ext_resp_t icache_resp_step[LS_STEPS-1:0];
  // Lockstep of input & output signals (from the master core)
  always_ff @(posedge clk_i or negedge rst_ni) begin: ls_dcache
    if (!rst_ni) begin
      `STEP_INIT(dcache_req_step, '0, LS_STEPS);
      `STEP_INIT(dcache_resp_step, '0, LS_STEPS);
    end else if (dcls_mode_i == cva6_safe_dcls_types_pkg::LS) begin
      `STEP(dcache_req_step, dcache_req, LS_STEPS);
      `STEP(dcache_resp_step, dcache_resp, LS_STEPS);
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin: ls_icache
    if (!rst_ni) begin
      `STEP_INIT(icache_req_step, '0, LS_STEPS);
      `STEP_INIT(icache_resp_step, '0, LS_STEPS);
    end else if (dcls_mode_i == cva6_safe_dcls_types_pkg::LS) begin
      `STEP(icache_req_step, icache_req, LS_STEPS);
      `STEP(icache_resp_step, icache_resp, LS_STEPS);
    end
  end

  // Routing for second core signals.
  // ================================
  // Depending on the configuration (DC or LS) the routing will be adapted to
  // get the signals from the dcls module interface in DC mode or to get the
  // signals from the lockstep signals in LS mode.

  // Routing of input signals.
  axi_mst_resp_t axi_m_resp_c1;
  axi_mst_req_t axi_m_req_c1;
  logic [1:0] irq_i_c1;
  logic ipi_i_c1;
  logic time_irq_i_c1;
  logic debug_req_i_c1;
  logic rst_ni_c1;
  always_comb begin: dcls_axi_m_resp_c1
    if (dcls_mode_i == cva6_safe_dcls_types_pkg::LS) begin
      axi_m_resp_c1 = axi_m_resp_step[LS_STEPS-1];
      irq_i_c1 = irq_i_step[LS_STEPS-1];
      ipi_i_c1 = ipi_i_step[LS_STEPS-1];
      time_irq_i_c1 = time_irq_i_step[LS_STEPS-1];
      debug_req_i_c1 = debug_req_i_step[LS_STEPS-1];
      rst_ni_c1 = rst_ni_step[LS_STEPS-1];
    end else begin
      axi_m_resp_c1 = axi_m_resp[1];
      irq_i_c1 = irq_i[1];
      ipi_i_c1 = ipi_i[1];
      time_irq_i_c1 = time_irq_i[1];
      debug_req_i_c1 = debug_req_i[1];
      rst_ni_c1 = rst_ni;
    end
  end

  // Routing of output signals
  always_comb begin: dcls_axi_m_req_c1
    if (dcls_mode_i == cva6_safe_dcls_types_pkg::LS) begin
      axi_m_req[1] = 0;
    end else begin
      axi_m_req[1] = axi_m_req_c1;
    end
  end

  // Routing signals for core 1 & sram 1
  always_comb begin: dcls_dcache_c1
    if (dcls_mode_i == cva6_safe_dcls_types_pkg::LS) begin // Mode LS
      // Core 1 uses delayed data from Core 0's SRAM data and instruction caches
      dcache_resp_c1 = dcache_resp_step[LS_STEPS-1];
      icache_resp_c1 = icache_resp_step[LS_STEPS-1];

      // Duplicate Core 0's data cache request to SRAM 1 (for comparison)
      dcache_req_sr1 = dcache_req;

    // No need to duplicate instruction cache requests:
    // ECC is already used on instruction cache
    icache_req_sr1 = 0;
    end else begin // Mode AMP
      // Core 1 operates independently using its own data and instruction caches
      dcache_resp_c1 = dcache_resp_sr1;
      dcache_req_sr1 = dcache_req_c1;
      icache_resp_c1 = icache_resp_sr1;
      icache_req_sr1 = icache_req_c1;
    end
  end

  // ================================

  // The second core
  ariane #(
    .CVA6Cfg             ( CVA6_CFG            ),
    .rvfi_probes_instr_t ( rvfi_probes_instr_t ),
    .rvfi_probes_csr_t   ( rvfi_probes_csr_t   ),
    .rvfi_probes_t       ( rvfi_probes_t       ),
    .axi_ar_chan_t       ( axi_mst_ar_chan_t   ),
    .axi_aw_chan_t       ( axi_mst_aw_chan_t   ),
    .axi_w_chan_t        ( axi_mst_w_chan_t    ),
    .noc_req_t           ( axi_mst_req_t       ),
    .noc_resp_t          ( axi_mst_resp_t      )
  ) i_ariane_1 (
    .clk_i         ( clk_i            ),
    .rst_ni        ( rst_ni_c1        ),
    .boot_addr_i   ( boot_addr_c1     ),
    .hart_id_i     ( hart_id_i[1]     ),
    .irq_i         ( irq_i_c1         ),
    .ipi_i         ( ipi_i_c1         ),
    .time_irq_i    ( time_irq_i_c1    ),
    .rvfi_probes_o ( rvfi_probes_o[1] ),
    .debug_req_i   ( debug_req_i_c1   ),
    .noc_req_o     ( axi_m_req_c1     ),
    .noc_resp_i    ( axi_m_resp_c1    ),
    // sram extern ports
    .dcache_req(dcache_req_c1),
    .dcache_resp(dcache_resp_c1),
    .icache_req(icache_req_c1),
    .icache_resp(icache_resp_c1)
  );

  // Lockstep error detection logic
  // NOTE: This code might need to be splitted into a multistep process
  // depending on the clock constraints.
  logic dcls_error;
  logic dcls_error_q, dcls_error_d;
  assign dcls_error = dcls_error_q;

  always_comb begin
    dcls_error_d = dcls_error_q;
    if ((dcls_error_q == 1'b0) && (dcls_mode_i ==
        cva6_safe_dcls_types_pkg::LS)) begin
      if (step_valid[LS_STEPS] == 1'b1) begin
        dcls_error_d = | ((axi_m_req_step[LS_STEPS-1] ^ axi_m_req_c1)
            | (dcache_req_step[LS_STEPS-1] ^ dcache_req_c1));
      end
      else begin
        dcls_error_d = 1'b0;
      end
    end
  end

  assign dcls_error_o = (dcls_mode_i == cva6_safe_dcls_types_pkg::LS) ?
      dcls_error : 1'b0;

  // SRAM error detection logic in Lockstep mode.
  // Compares the responses from the two SRAM blocks requested by the same core.
  logic dcache_ecc_error_q, dcache_ecc_error_d;

  always_comb begin
    dcache_ecc_error_d = dcache_ecc_error_q;
    if (dcls_mode_i == cva6_safe_dcls_types_pkg::LS) begin
      if (step_valid[LS_STEPS] == 1'b1) begin
        dcache_ecc_error_d = (dcache_resp ^ dcache_resp_sr1);
      end else
        dcache_ecc_error_d = 1'b0;
    end
  end

  assign dcache_ecc_error = dcache_ecc_error_q;

  // This logic captures and reports a data cache ECC error
  logic dcache_ecc_error_report;
  always_ff @(posedge clk_i) begin
    if (step_valid[LS_STEPS] == 1'b1)
        dcache_ecc_error_report <= dcache_ecc_error_report | dcache_ecc_error_d;
    else
        dcache_ecc_error_report <= 1'b0;
  end

  assign ecc_error_o = dcache_ecc_error_report | icache_resp.ecc_error
      | icache_resp_c1.ecc_error;  
  always_ff @(posedge clk_i or negedge rst_ni) begin: ls_check
    if (~rst_ni) begin
      dcls_error_q <= 1'b0;
      dcache_ecc_error_q <= 1'b0;
    end else begin
      dcls_error_q <= dcls_error_d;
      dcache_ecc_error_q <= dcache_ecc_error_d;
    end
  end
/*
  // -------------
  // Simulation Helper Functions
  // -------------
  // check for response errors
  always_ff @(posedge clk_i) begin : p_assert
    // check that hart_id is the same on the two cores when the module is in
    // lockstep configuration
    if (dcls_mode_i == 1'b1 &&
        hart_id_i[0] != hart_id_i[1]) begin
      $error("Hart id different when configured in lockstep mode");
    end
    if (dcls_mode_i == 1'b0 &&
        hart_id_i[0] == hart_id_i[1]) begin
      $error("Hart id equal when configured in dual-core mode");
    end
    for (int core_idx = 0; core_idx < 2; core_idx++) begin
      if (axi_m_req[core_idx].r_ready &&
          axi_m_resp[core_idx].r_valid &&
          axi_m_resp[core_idx].r.resp inside
            {axi_pkg::RESP_DECERR, axi_pkg::RESP_SLVERR}) begin
        $warning("R Response Errored");
      end
      if (axi_m_req[core_idx].b_ready &&
          axi_m_resp[core_idx].b_valid &&
          axi_m_resp[core_idx].b.resp inside
            {axi_pkg::RESP_DECERR, axi_pkg::RESP_SLVERR}) begin
        $warning("B Response Errored");
      end
    end
  end
*/
endmodule
