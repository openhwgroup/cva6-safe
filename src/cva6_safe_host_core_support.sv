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
// Description: Module containing base sub-modules to build a cva6-amp design
//              for the NeuroSoC project.
//
// ========================================================================== //
// Revisions  :
// Date        Version  Author       Description
// 11.09.2023  0.1      D. Gracia    First functional version. Contains all
//                                   peripherals from orignal corev_apu design.
// 27.05.2024  0.2      D. Gracia    Includes support bus internally, showing
//                                   only one master and a slave connection. 
// 29.01.2025  0.3      A. L. NDIAYE Bootrom removal
// ========================================================================== //

`include "axi/assign.svh"
`include "axi/typedef.svh"
`include "register_interface/typedef.svh"
`include "register_interface/assign.svh"

module cva6_safe_host_core_support #(
  parameter cva6_safe_host_core_support_pkg::config_t CFG =
      cva6_safe_host_core_support_pkg::build_config(
          config_pkg::cva6_cfg_empty, 1, 0, 1)
) (
  input  logic                      clk_i,
  // input  logic                      rtc_i,
  input  logic                      rst_ni,
  input  logic                      test_en_i,
  output logic                      ndmreset_o,
  input  logic                      ndmreset_ni,
  input  logic                      jtag_TCK_i,
  input  logic                      jtag_TMS_i,
  input  logic                      jtag_TDI_i,
  input  logic                      jtag_TRST_ni,
  output logic                      jtag_TDO_data_o,
  output logic                      jtag_TDO_driven_o,
  output logic [(CFG.NumDcls*2)-1:0] debug_req_core_o,
  output logic [(CFG.NumDcls*2)-1:0] ipi_o,
  output logic [(CFG.NumDcls*2)-1:0] timer_irq_o,
  output logic [1:0]                irq_o[(CFG.NumDcls*2)-1:0],
  input  logic [CFG.NumExtIrqSources-1:0] irq_i,
  input  logic                       dcls_mode_i,
  AXI_BUS ext_slave_bus,
  AXI_BUS ext_master_bus
);

  localparam SUPPORT_BUS_ID_WIDTH =
      cva6_safe_host_core_support_pkg::SUPPORT_BUS_ID_WIDTH;
  localparam SUPPORT_BUS_NUM_SLAVES =
      cva6_safe_host_core_support_pkg::SUPPORT_BUS_NUM_SLAVES;
  localparam SUPPORT_BUS_ID_WIDTH_SLAVE =
      cva6_safe_host_core_support_pkg::SUPPORT_BUS_ID_WIDTH_SLAVE;
  localparam SUPPORT_BUS_NUM_MASTERS =
      cva6_safe_host_core_support_pkg::SUPPORT_BUS_NUM_MASTERS;
  localparam SUPPORT_BUS_MASTER_DEBUG_PORT =
      cva6_safe_host_core_support_pkg::SUPPORT_BUS_MASTER_DEBUG_PORT;
  localparam SUPPORT_DEBUG_BASE =
      cva6_safe_host_core_support_pkg::DEBUG_BASE;
  localparam SUPPORT_DEBUG_LENGTH =
      cva6_safe_host_core_support_pkg::DEBUG_LENGTH;
  localparam SUPPORT_BUS_MASTER_CLINT_PORT =
      cva6_safe_host_core_support_pkg::SUPPORT_BUS_MASTER_CLINT_PORT;
  localparam SUPPORT_CLINT_BASE =
      cva6_safe_host_core_support_pkg::CLINT_BASE;
  localparam SUPPORT_CLINT_LENGTH =
      cva6_safe_host_core_support_pkg::CLINT_LENGTH;
  localparam SUPPORT_BUS_MASTER_PLIC_PORT =
      cva6_safe_host_core_support_pkg::SUPPORT_BUS_MASTER_PLIC_PORT;
  localparam SUPPORT_PLIC_BASE =
      cva6_safe_host_core_support_pkg::PLIC_BASE;
  localparam SUPPORT_PLIC_LENGTH =
      cva6_safe_host_core_support_pkg::PLIC_LENGTH;
  localparam SUPPORT_BUS_MASTER_TIMER_PORT =
      cva6_safe_host_core_support_pkg::SUPPORT_BUS_MASTER_TIMER_PORT;
  localparam SUPPORT_TIMER_BASE =
      cva6_safe_host_core_support_pkg::TIMER_BASE;
  localparam SUPPORT_TIMER_LENGTH =
      cva6_safe_host_core_support_pkg::TIMER_LENGTH;
  localparam SUPPORT_BUS_MASTER_SYSTEM_PORT =
      cva6_safe_host_core_support_pkg::SUPPORT_BUS_MASTER_SYSTEM_PORT;

  localparam AXI_ADDRESS_WIDTH = CFG.Cva6Cfg.AxiAddrWidth;
  localparam AXI_DATA_WIDTH    = CFG.Cva6Cfg.AxiDataWidth;
  localparam AXI_USER_WIDTH    = CFG.Cva6Cfg.AxiUserWidth;
  localparam AXI_ID_WIDTH      = CFG.Cva6Cfg.AxiIdWidth;

  localparam int unsigned NUM_CORES = CFG.NumDcls * 2;

  // The total number of IRQ sources is equal to the number of external IRQ
  // sources plus the internal sources which are the timer IRQs (4 IRQs)
  localparam int unsigned NUM_INT_IRQ_SOURCES = 4;
  localparam int unsigned NUM_USED_IRQ_SOURCES =
    NUM_INT_IRQ_SOURCES + CFG.NumExtIrqSources;
  localparam int unsigned NUM_IRQ_SOURCES = 30;
  logic[NUM_IRQ_SOURCES-1:0] irq_sources_i;
  assign irq_sources_i[NUM_USED_IRQ_SOURCES-1:NUM_INT_IRQ_SOURCES] =
    irq_i[CFG.NumExtIrqSources-1:0];
  assign irq_sources_i[NUM_IRQ_SOURCES-1:NUM_USED_IRQ_SOURCES] =
    {(NUM_IRQ_SOURCES-NUM_USED_IRQ_SOURCES){1'b0}};

  genvar core_idx;

  // dm_master                    = 1
  // system_bus master connection = 1
  // TOTAL                        = 2
  AXI_BUS #(
    .AXI_ADDR_WIDTH ( AXI_ADDRESS_WIDTH                          ),
    .AXI_DATA_WIDTH ( AXI_DATA_WIDTH                             ),
    .AXI_ID_WIDTH   ( SUPPORT_BUS_ID_WIDTH ),
    .AXI_USER_WIDTH ( AXI_USER_WIDTH                             )
  ) support_bus_slave[SUPPORT_BUS_NUM_SLAVES-1:0]();

  // cva6_support module slaves  = 6
  // system_bus slave connection = 1
  // TOTAL                       = 7
  AXI_BUS #(
    .AXI_ADDR_WIDTH ( AXI_ADDRESS_WIDTH                                ),
    .AXI_DATA_WIDTH ( AXI_DATA_WIDTH                                   ),
    .AXI_ID_WIDTH   ( SUPPORT_BUS_ID_WIDTH_SLAVE ),
    .AXI_USER_WIDTH ( AXI_USER_WIDTH                                   )
  ) support_bus_master[SUPPORT_BUS_NUM_MASTERS-1:0]();

  // Some shortcuts to access the different interfaces and ports in the
  // support bus.
  // E.g.:
  // - `MSB_P(DEBUG) gets transformed into
  //   support_bus_master[cva6_safe_host_core_support_pkg::SUPPORT_BUS_MASTER_DEBUG_PORT]
  // - `SSB_P(DEBUG) gets transformed into
  //   support_bus_slave[cva6_safe_host_core_support_pkg::SUPPORT_BUS_SLAVE_DEBUG_PORT]
  `define SB_P(__MS__, __PORT__) \
    support_bus_``__MS__``[cva6_safe_host_core_support_pkg::SUPPORT_BUS_``__PORT__``_PORT]
  `define MSB_P(__PORT__) `SB_P(master, MASTER_``__PORT__)
  `define SSB_P(__PORT__) `SB_P(slave,  SLAVE_``__PORT__)

  dm::dmi_req_t  debug_req;
  logic          debug_req_valid;
  logic          debug_req_ready;
  dm::dmi_resp_t debug_resp;
  logic          debug_resp_valid;
  logic          debug_resp_ready;

  dmi_jtag i_dmi_jtag (
    .clk_i            ( clk_i             ),
    .rst_ni           ( rst_ni            ),
    .testmode_i       ( test_en_i         ),
    .dmi_req_o        ( debug_req         ),
    .dmi_req_valid_o  ( debug_req_valid   ),
    .dmi_req_ready_i  ( debug_req_ready   ),
    .dmi_resp_i       ( debug_resp        ),
    .dmi_resp_ready_o ( debug_resp_ready  ),
    .dmi_resp_valid_i ( debug_resp_valid  ),
    .dmi_rst_no       (                   ), // not connected
    .tck_i            ( jtag_TCK_i        ),
    .tms_i            ( jtag_TMS_i        ),
    .trst_ni          ( jtag_TRST_ni      ),
    .td_i             ( jtag_TDI_i        ),
    .td_o             ( jtag_TDO_data_o   ),
    .tdo_oe_o         ( jtag_TDO_driven_o )
  );

  // debug module
  dm::hartinfo_t [NUM_CORES-1:0] hartinfo;
  generate
    for (core_idx = 0; core_idx < NUM_CORES; core_idx++) begin
      assign hartinfo[core_idx] = ariane_pkg::DebugHartInfo;
    end
  endgenerate

  logic [NUM_CORES-1:0] unavailable_mask;
  generate
    for (core_idx = 0; core_idx < NUM_CORES; core_idx++) begin
      if (core_idx < CFG.NumDcls) begin
        assign unavailable_mask[core_idx] = 0;
      end else begin
        assign unavailable_mask[core_idx] =
            (dcls_mode_i == cva6_safe_dcls_types_pkg::LS) ? 1'b1 : 1'b0;
      end
    end
  endgenerate

  logic                         dm_slave_req;
  logic                         dm_slave_we;
  logic [AXI_ADDRESS_WIDTH-1:0] dm_slave_addr;
  logic [AXI_DATA_WIDTH/8-1:0]  dm_slave_be;
  logic [AXI_DATA_WIDTH-1:0]    dm_slave_wdata;
  logic [AXI_DATA_WIDTH-1:0]    dm_slave_rdata;

  logic                         dm_master_req;
  logic [AXI_ADDRESS_WIDTH-1:0] dm_master_add;
  logic                         dm_master_we;
  logic [AXI_DATA_WIDTH-1:0]    dm_master_wdata;
  logic [AXI_DATA_WIDTH/8-1:0]  dm_master_be;
  logic                         dm_master_gnt;
  logic                         dm_master_r_valid;
  logic [AXI_DATA_WIDTH-1:0]    dm_master_r_rdata;

  dm_top #(
    .NrHarts              ( NUM_CORES         ),
    .BusWidth             ( AXI_DATA_WIDTH    ),
    .SelectableHarts      ( {NUM_CORES{1'b1}} )
  ) i_dm_top (
    .clk_i                ( clk_i             ),
    .rst_ni               ( rst_ni            ), // PoR
    .testmode_i           ( test_en_i         ),
    .ndmreset_o           ( ndmreset_o        ),
    .dmactive_o           (                   ), // active debug session
    .debug_req_o          ( debug_req_core_o  ),
    .unavailable_i        ( unavailable_mask  ),
    .hartinfo_i           ( hartinfo          ),
    .slave_req_i          ( dm_slave_req      ),
    .slave_we_i           ( dm_slave_we       ),
    .slave_addr_i         ( dm_slave_addr     ),
    .slave_be_i           ( dm_slave_be       ),
    .slave_wdata_i        ( dm_slave_wdata    ),
    .slave_rdata_o        ( dm_slave_rdata    ),
    .master_req_o         ( dm_master_req     ),
    .master_add_o         ( dm_master_add     ),
    .master_we_o          ( dm_master_we      ),
    .master_wdata_o       ( dm_master_wdata   ),
    .master_be_o          ( dm_master_be      ),
    .master_gnt_i         ( dm_master_gnt     ),
    .master_r_valid_i     ( dm_master_r_valid ),
    .master_r_rdata_i     ( dm_master_r_rdata ),
    .dmi_rst_ni           ( rst_ni            ),
    .dmi_req_valid_i      ( debug_req_valid   ),
    .dmi_req_ready_o      ( debug_req_ready   ),
    .dmi_req_i            ( debug_req         ),
    .dmi_resp_valid_o     ( debug_resp_valid  ),
    .dmi_resp_ready_i     ( debug_resp_ready  ),
    .dmi_resp_o           ( debug_resp        )
  );

  axi2mem #(
    .AXI_ID_WIDTH   ( SUPPORT_BUS_ID_WIDTH_SLAVE ),
    .AXI_ADDR_WIDTH ( AXI_ADDRESS_WIDTH          ),
    .AXI_DATA_WIDTH ( AXI_DATA_WIDTH             ),
    .AXI_USER_WIDTH ( AXI_USER_WIDTH             )
  ) i_dm_axi2mem (
    .clk_i      ( clk_i          ),
    .rst_ni     ( rst_ni         ),
    .slave      ( `MSB_P(DEBUG)  ),
    .req_o      ( dm_slave_req   ),
    .we_o       ( dm_slave_we    ),
    .addr_o     ( dm_slave_addr  ),
    .be_o       ( dm_slave_be    ),
    .user_o     (                ),
    .data_o     ( dm_slave_wdata ),
    .user_i     ( '0             ),
    .data_i     ( dm_slave_rdata )
  );
  
  typedef logic [SUPPORT_BUS_ID_WIDTH-1:0]
    support_bus_axi_mst_id_t;
  typedef logic [AXI_ADDRESS_WIDTH-1:0]
    support_bus_axi_mst_addr_t;
  typedef logic [AXI_DATA_WIDTH-1:0]
    support_bus_axi_mst_data_t;
  typedef logic [(AXI_DATA_WIDTH/8)-1:0]
    support_bus_axi_mst_strb_t;
  typedef logic [AXI_USER_WIDTH-1:0]
    support_bus_axi_mst_user_t;
  `AXI_TYPEDEF_ALL(support_bus_axi_mst,
      support_bus_axi_mst_addr_t,
      support_bus_axi_mst_id_t,
      support_bus_axi_mst_data_t,
      support_bus_axi_mst_strb_t,
      support_bus_axi_mst_user_t)

  support_bus_axi_mst_req_t  dm_axi_m_req;
  support_bus_axi_mst_resp_t dm_axi_m_resp;

  `AXI_ASSIGN_FROM_REQ(
    `SSB_P(DEBUG),
    dm_axi_m_req);
  `AXI_ASSIGN_TO_RESP(
    dm_axi_m_resp,
    `SSB_P(DEBUG));

  axi_adapter #(
    .CVA6Cfg               ( CFG.Cva6Cfg                ),
    .DATA_WIDTH            ( AXI_DATA_WIDTH             ),
    .axi_req_t             ( support_bus_axi_mst_req_t  ),
    .axi_rsp_t             ( support_bus_axi_mst_resp_t )
  ) i_dm_axi_master (
    .clk_i                 ( clk_i                          ),
    .rst_ni                ( rst_ni                         ),
    .req_i                 ( dm_master_req                  ),
    .type_i                ( ariane_pkg::SINGLE_REQ         ),
    .amo_i                 ( ariane_pkg::AMO_NONE           ),
    .gnt_o                 ( dm_master_gnt                  ),
    //.gnt_id_o              (                                ),
    // TODO: To check.
    //   The address size doesn't match here, dm_master_add is 64 bits,
    //   while the address port addr_i is only 32 bits.
    //   For the moment, just remove high bits from dm_master_add.
    .addr_i                ( dm_master_add[riscv::XLEN-1:0] ),
    .we_i                  ( dm_master_we                   ),
    .wdata_i               ( dm_master_wdata                ),
    .be_i                  ( dm_master_be                   ),
    // .size_i: always do 64bit here and use byte enables to gate
    .size_i                ( 2'b11                          ),
    .id_i                  ( '0                             ),
    .valid_o               ( dm_master_r_valid              ),
    .rdata_o               ( dm_master_r_rdata              ),
    .id_o                  (                                ),
    .critical_word_o       (                                ),
    .critical_word_valid_o (                                ),
    .axi_req_o             ( dm_axi_m_req                   ),
    .axi_resp_i            ( dm_axi_m_resp                  )
  );

  // ---------------
  // CLINT
  // ---------------
  logic rtc;
  always_ff @(posedge clk_i or negedge ndmreset_ni) begin
    if (~ndmreset_ni) begin
      rtc <= 0;
    end else begin
      rtc <= rtc ^ 1'b1;
    end
  end

  typedef logic [SUPPORT_BUS_ID_WIDTH_SLAVE-1:0]
    support_bus_axi_slv_id_t;
  typedef logic [AXI_ADDRESS_WIDTH-1:0]
    support_bus_axi_slv_addr_t;
  typedef logic [AXI_DATA_WIDTH-1:0]
    support_bus_axi_slv_data_t;
  typedef logic [(AXI_DATA_WIDTH/8)-1:0]
    support_bus_axi_slv_strb_t;
  typedef logic [AXI_USER_WIDTH-1:0]
    support_bus_axi_slv_user_t;
  `AXI_TYPEDEF_ALL(support_bus_axi_slv,
      support_bus_axi_slv_addr_t,
      support_bus_axi_slv_id_t,
      support_bus_axi_slv_data_t,
      support_bus_axi_slv_strb_t,
      support_bus_axi_slv_user_t)

  support_bus_axi_slv_req_t axi_clint_req;
  support_bus_axi_slv_resp_t axi_clint_resp;
  // The clint ignores and doesn't set the user bits, cable them to 0
  // NOTE: probably not needed wut allows to make sure the user field is
  // is connected in the bus.
  support_bus_axi_slv_resp_t axi_clint_resp_fixed;
  always_comb begin
    axi_clint_resp_fixed = axi_clint_resp;
    axi_clint_resp_fixed.b.user = '{AXI_USER_WIDTH{1'b0}};
    axi_clint_resp_fixed.r.user = '{AXI_USER_WIDTH{1'b0}};
  end

  `AXI_ASSIGN_TO_REQ(
    axi_clint_req,
    `MSB_P(CLINT) )
  `AXI_ASSIGN_FROM_RESP(
    `MSB_P(CLINT),
    axi_clint_resp_fixed)

  clint #(
    .CVA6Cfg        ( CFG.Cva6Cfg                ),
    .AXI_ADDR_WIDTH ( AXI_ADDRESS_WIDTH          ),
    .AXI_DATA_WIDTH ( AXI_DATA_WIDTH             ),
    .AXI_ID_WIDTH   ( SUPPORT_BUS_ID_WIDTH_SLAVE ),
    .NR_CORES       ( NUM_CORES                  ),
    .axi_req_t      ( support_bus_axi_slv_req_t  ),
    .axi_resp_t     ( support_bus_axi_slv_resp_t )
  ) i_clint (
    .clk_i       ( clk_i          ),
    .rst_ni      ( ndmreset_ni    ),
    .testmode_i  ( test_en_i      ),
    .axi_req_i   ( axi_clint_req  ),
    .axi_resp_o  ( axi_clint_resp ),
    .rtc_i       ( rtc            ),
    .timer_irq_o ( timer_irq_o    ),
    .ipi_o       ( ipi_o          )
  );

  // ---------------
  // PLIC
  // ---------------
  REG_BUS #(
    .ADDR_WIDTH ( 32 ),
    .DATA_WIDTH ( 32 )
  ) reg_bus ( clk_i );

  logic         plic_penable;
  logic         plic_pwrite;
  logic [31:0]  plic_paddr;
  logic         plic_psel;
  logic [31:0]  plic_pwdata;
  logic [31:0]  plic_prdata;
  logic         plic_pready;
  logic         plic_pslverr;

  axi2apb_64_32 #(
    .AXI4_ADDRESS_WIDTH ( AXI_ADDRESS_WIDTH          ),
    .AXI4_RDATA_WIDTH   ( AXI_DATA_WIDTH             ),
    .AXI4_WDATA_WIDTH   ( AXI_DATA_WIDTH             ),
    .AXI4_ID_WIDTH      ( SUPPORT_BUS_ID_WIDTH_SLAVE ),
    .AXI4_USER_WIDTH    ( AXI_USER_WIDTH             ),
    .BUFF_DEPTH_SLAVE   ( 2                          ),
    .APB_ADDR_WIDTH     ( 32                         )
  ) i_axi2apb_64_32_plic (
    .ACLK      ( clk_i                  ),
    .ARESETn   ( rst_ni                 ),
    .test_en_i ( 1'b0                   ),
    .AWID_i    ( `MSB_P(PLIC).aw_id     ),
    .AWADDR_i  ( `MSB_P(PLIC).aw_addr   ),
    .AWLEN_i   ( `MSB_P(PLIC).aw_len    ),
    .AWSIZE_i  ( `MSB_P(PLIC).aw_size   ),
    .AWBURST_i ( `MSB_P(PLIC).aw_burst  ),
    .AWLOCK_i  ( `MSB_P(PLIC).aw_lock   ),
    .AWCACHE_i ( `MSB_P(PLIC).aw_cache  ),
    .AWPROT_i  ( `MSB_P(PLIC).aw_prot   ),
    .AWREGION_i( `MSB_P(PLIC).aw_region ),
    .AWUSER_i  ( `MSB_P(PLIC).aw_user   ),
    .AWQOS_i   ( `MSB_P(PLIC).aw_qos    ),
    .AWVALID_i ( `MSB_P(PLIC).aw_valid  ),
    .AWREADY_o ( `MSB_P(PLIC).aw_ready  ),
    .WDATA_i   ( `MSB_P(PLIC).w_data    ),
    .WSTRB_i   ( `MSB_P(PLIC).w_strb    ),
    .WLAST_i   ( `MSB_P(PLIC).w_last    ),
    .WUSER_i   ( `MSB_P(PLIC).w_user    ),
    .WVALID_i  ( `MSB_P(PLIC).w_valid   ),
    .WREADY_o  ( `MSB_P(PLIC).w_ready   ),
    .BID_o     ( `MSB_P(PLIC).b_id      ),
    .BRESP_o   ( `MSB_P(PLIC).b_resp    ),
    .BVALID_o  ( `MSB_P(PLIC).b_valid   ),
    .BUSER_o   ( `MSB_P(PLIC).b_user    ),
    .BREADY_i  ( `MSB_P(PLIC).b_ready   ),
    .ARID_i    ( `MSB_P(PLIC).ar_id     ),
    .ARADDR_i  ( `MSB_P(PLIC).ar_addr   ),
    .ARLEN_i   ( `MSB_P(PLIC).ar_len    ),
    .ARSIZE_i  ( `MSB_P(PLIC).ar_size   ),
    .ARBURST_i ( `MSB_P(PLIC).ar_burst  ),
    .ARLOCK_i  ( `MSB_P(PLIC).ar_lock   ),
    .ARCACHE_i ( `MSB_P(PLIC).ar_cache  ),
    .ARPROT_i  ( `MSB_P(PLIC).ar_prot   ),
    .ARREGION_i( `MSB_P(PLIC).ar_region ),
    .ARUSER_i  ( `MSB_P(PLIC).ar_user   ),
    .ARQOS_i   ( `MSB_P(PLIC).ar_qos    ),
    .ARVALID_i ( `MSB_P(PLIC).ar_valid  ),
    .ARREADY_o ( `MSB_P(PLIC).ar_ready  ),
    .RID_o     ( `MSB_P(PLIC).r_id      ),
    .RDATA_o   ( `MSB_P(PLIC).r_data    ),
    .RRESP_o   ( `MSB_P(PLIC).r_resp    ),
    .RLAST_o   ( `MSB_P(PLIC).r_last    ),
    .RUSER_o   ( `MSB_P(PLIC).r_user    ),
    .RVALID_o  ( `MSB_P(PLIC).r_valid   ),
    .RREADY_i  ( `MSB_P(PLIC).r_ready   ),
    .PENABLE   ( plic_penable           ),
    .PWRITE    ( plic_pwrite            ),
    .PADDR     ( plic_paddr             ),
    .PSEL      ( plic_psel              ),
    .PWDATA    ( plic_pwdata            ),
    .PRDATA    ( plic_prdata            ),
    .PREADY    ( plic_pready            ),
    .PSLVERR   ( plic_pslverr           )
  );

  apb_to_reg i_apb_to_reg (
    .clk_i     ( clk_i        ),
    .rst_ni    ( rst_ni       ),
    .penable_i ( plic_penable ),
    .pwrite_i  ( plic_pwrite  ),
    .paddr_i   ( plic_paddr   ),
    .psel_i    ( plic_psel    ),
    .pwdata_i  ( plic_pwdata  ),
    .prdata_o  ( plic_prdata  ),
    .pready_o  ( plic_pready  ),
    .pslverr_o ( plic_pslverr ),
    .reg_o     ( reg_bus      )
  );

  // define reg type according to REG_BUS above
  `REG_BUS_TYPEDEF_ALL(plic, logic[31:0], logic[31:0], logic[3:0])
  plic_req_t plic_req;
  plic_rsp_t plic_rsp;

  // assign REG_BUS.out to (req_t, rsp_t) pair
  `REG_BUS_ASSIGN_TO_REQ(plic_req, reg_bus)
  `REG_BUS_ASSIGN_FROM_RSP(reg_bus, plic_rsp)

  logic [(NUM_CORES * 2) - 1:0] irq_targets_o;
  generate
    for (core_idx = 0; core_idx < NUM_CORES; core_idx++) begin
      assign irq_o[core_idx][1] = irq_targets_o[1 + (core_idx * 2)];
      assign irq_o[core_idx][0] = irq_targets_o[core_idx * 2];
    end
  endgenerate

  plic_top #(
    .N_SOURCE    ( NUM_IRQ_SOURCES         ),
    // two irqs defined per core: M-Mode Hart, S-Mode Hart
    .N_TARGET    ( NUM_CORES * 2           ),
    .MAX_PRIO    ( CFG.MaxInterruptPrio    ),
    .reg_req_t   ( plic_req_t              ),
    .reg_rsp_t   ( plic_rsp_t              )
  ) i_plic (
    .clk_i         ( clk_i         ),
    .rst_ni        ( rst_ni        ),
    .req_i         ( plic_req      ),
    .resp_o        ( plic_rsp      ),
    .le_i          ( '0            ), // 0:level 1:edge
    .irq_sources_i ( irq_sources_i ),
    .eip_targets_o ( irq_targets_o )
  );

  // ---------------
  // Timer
  // ---------------
  logic         timer_penable;
  logic         timer_pwrite;
  logic [31:0]  timer_paddr;
  logic         timer_psel;
  logic [31:0]  timer_pwdata;
  logic [31:0]  timer_prdata;
  logic         timer_pready;
  logic         timer_pslverr;

  axi2apb_64_32 #(
      .AXI4_ADDRESS_WIDTH ( AXI_ADDRESS_WIDTH          ),
      .AXI4_RDATA_WIDTH   ( AXI_DATA_WIDTH             ),
      .AXI4_WDATA_WIDTH   ( AXI_DATA_WIDTH             ),
      .AXI4_ID_WIDTH      ( SUPPORT_BUS_ID_WIDTH_SLAVE ),
      .AXI4_USER_WIDTH    ( AXI_USER_WIDTH             ),
      .BUFF_DEPTH_SLAVE   ( 2                          ),
      .APB_ADDR_WIDTH     ( 32                         )
  ) i_axi2apb_64_32_timer (
      .ACLK      ( clk_i                   ),
      .ARESETn   ( rst_ni                  ),
      .test_en_i ( 1'b0                    ),
      .AWID_i    ( `MSB_P(TIMER).aw_id     ),
      .AWADDR_i  ( `MSB_P(TIMER).aw_addr   ),
      .AWLEN_i   ( `MSB_P(TIMER).aw_len    ),
      .AWSIZE_i  ( `MSB_P(TIMER).aw_size   ),
      .AWBURST_i ( `MSB_P(TIMER).aw_burst  ),
      .AWLOCK_i  ( `MSB_P(TIMER).aw_lock   ),
      .AWCACHE_i ( `MSB_P(TIMER).aw_cache  ),
      .AWPROT_i  ( `MSB_P(TIMER).aw_prot   ),
      .AWREGION_i( `MSB_P(TIMER).aw_region ),
      .AWUSER_i  ( `MSB_P(TIMER).aw_user   ),
      .AWQOS_i   ( `MSB_P(TIMER).aw_qos    ),
      .AWVALID_i ( `MSB_P(TIMER).aw_valid  ),
      .AWREADY_o ( `MSB_P(TIMER).aw_ready  ),
      .WDATA_i   ( `MSB_P(TIMER).w_data    ),
      .WSTRB_i   ( `MSB_P(TIMER).w_strb    ),
      .WLAST_i   ( `MSB_P(TIMER).w_last    ),
      .WUSER_i   ( `MSB_P(TIMER).w_user    ),
      .WVALID_i  ( `MSB_P(TIMER).w_valid   ),
      .WREADY_o  ( `MSB_P(TIMER).w_ready   ),
      .BID_o     ( `MSB_P(TIMER).b_id      ),
      .BRESP_o   ( `MSB_P(TIMER).b_resp    ),
      .BVALID_o  ( `MSB_P(TIMER).b_valid   ),
      .BUSER_o   ( `MSB_P(TIMER).b_user    ),
      .BREADY_i  ( `MSB_P(TIMER).b_ready   ),
      .ARID_i    ( `MSB_P(TIMER).ar_id     ),
      .ARADDR_i  ( `MSB_P(TIMER).ar_addr   ),
      .ARLEN_i   ( `MSB_P(TIMER).ar_len    ),
      .ARSIZE_i  ( `MSB_P(TIMER).ar_size   ),
      .ARBURST_i ( `MSB_P(TIMER).ar_burst  ),
      .ARLOCK_i  ( `MSB_P(TIMER).ar_lock   ),
      .ARCACHE_i ( `MSB_P(TIMER).ar_cache  ),
      .ARPROT_i  ( `MSB_P(TIMER).ar_prot   ),
      .ARREGION_i( `MSB_P(TIMER).ar_region ),
      .ARUSER_i  ( `MSB_P(TIMER).ar_user   ),
      .ARQOS_i   ( `MSB_P(TIMER).ar_qos    ),
      .ARVALID_i ( `MSB_P(TIMER).ar_valid  ),
      .ARREADY_o ( `MSB_P(TIMER).ar_ready  ),
      .RID_o     ( `MSB_P(TIMER).r_id      ),
      .RDATA_o   ( `MSB_P(TIMER).r_data    ),
      .RRESP_o   ( `MSB_P(TIMER).r_resp    ),
      .RLAST_o   ( `MSB_P(TIMER).r_last    ),
      .RUSER_o   ( `MSB_P(TIMER).r_user    ),
      .RVALID_o  ( `MSB_P(TIMER).r_valid   ),
      .RREADY_i  ( `MSB_P(TIMER).r_ready   ),
      .PENABLE   ( timer_penable           ),
      .PWRITE    ( timer_pwrite            ),
      .PADDR     ( timer_paddr             ),
      .PSEL      ( timer_psel              ),
      .PWDATA    ( timer_pwdata            ),
      .PRDATA    ( timer_prdata            ),
      .PREADY    ( timer_pready            ),
      .PSLVERR   ( timer_pslverr           )
  );

  apb_timer #(
          .APB_ADDR_WIDTH ( 32 ),
          .TIMER_CNT      ( 2  )
  ) i_timer (
      .HCLK    ( clk_i              ),
      .HRESETn ( rst_ni             ),
      .PSEL    ( timer_psel         ),
      .PENABLE ( timer_penable      ),
      .PWRITE  ( timer_pwrite       ),
      .PADDR   ( timer_paddr        ),
      .PWDATA  ( timer_pwdata       ),
      .PRDATA  ( timer_prdata       ),
      .PREADY  ( timer_pready       ),
      .PSLVERR ( timer_pslverr      ),
      .irq_o   ( irq_sources_i[NUM_INT_IRQ_SOURCES-1:0] )
  );

  // --------------------------------------
  // Adapter to the external bus connection
  // --------------------------------------

  // We need to reduce the IDs from the system bus (master) to the support
  // bus (slave). The system bus IDs will be typically larger than the support
  // bus IDs.
  // The number of SLV/MST_PORT_MAX_UNIQ_IDS can probably be reduced, but we
  // leave them to the maximum that can be achieved with the available width.
  axi_iw_converter_intf #(
    .AXI_SLV_PORT_ID_WIDTH        ( CFG.AxiIdWidthSlave ),
    .AXI_MST_PORT_ID_WIDTH        ( SUPPORT_BUS_ID_WIDTH ),
    .AXI_SLV_PORT_MAX_UNIQ_IDS    (
        CFG.SystemToSupportAxiSlvPortMaxUniqIds ),
    .AXI_SLV_PORT_MAX_TXNS_PER_ID (
        CFG.SystemToSupportAxiSlvPortMaxTxnsPerId ),
    .AXI_SLV_PORT_MAX_TXNS        (
        CFG.SystemToSupportAxiSlvPortMaxTxns ),
    .AXI_MST_PORT_MAX_UNIQ_IDS    (
        CFG.SystemToSupportAxiMstPortMaxUniqIds ),
    .AXI_MST_PORT_MAX_TXNS_PER_ID (
        CFG.SystemToSupportAxiMstPortMaxTxnsPerId ),
    .AXI_ADDR_WIDTH               ( AXI_ADDRESS_WIDTH  ),
    .AXI_DATA_WIDTH               ( AXI_DATA_WIDTH     ),
    .AXI_USER_WIDTH               ( AXI_USER_WIDTH     )
  ) i_system_to_support_bus (
    .clk_i  ( clk_i          ),
    .rst_ni ( ndmreset_ni    ),
    .slv    ( ext_master_bus ),
    .mst    ( `SSB_P(SYSTEM) )
  );

  // Same comments than for i_system_to_support_bus, but with the direction
  // inversed.
  axi_iw_converter_intf #(
    .AXI_SLV_PORT_ID_WIDTH        ( SUPPORT_BUS_ID_WIDTH_SLAVE ),
    .AXI_MST_PORT_ID_WIDTH        ( AXI_ID_WIDTH       ),
    .AXI_SLV_PORT_MAX_UNIQ_IDS    (
        CFG.SupportToSystemAxiSlvPortMaxUniqIds ),
    .AXI_SLV_PORT_MAX_TXNS_PER_ID (
        CFG.SupportToSystemAxiSlvPortMaxTxnsPerId ),
    .AXI_SLV_PORT_MAX_TXNS        (
        CFG.SupportToSystemAxiSlvPortMaxTxns ),
    .AXI_MST_PORT_MAX_UNIQ_IDS    (
        CFG.SupportToSystemAxiMstPortMaxUniqIds ),
    .AXI_MST_PORT_MAX_TXNS_PER_ID (
        CFG.SupportToSystemAxiMstPortMaxTxnsPerId ),
    .AXI_ADDR_WIDTH               ( AXI_ADDRESS_WIDTH  ),
    .AXI_DATA_WIDTH               ( AXI_DATA_WIDTH     ),
    .AXI_USER_WIDTH               ( AXI_USER_WIDTH     )
  ) i_support_to_system_bus (
    .clk_i  ( clk_i          ),
    .rst_ni ( ndmreset_ni    ),
    .slv    ( `MSB_P(SYSTEM) ),
    .mst    ( ext_slave_bus  )
  );

  // -----------
  // Support bus
  // -----------
  axi_pkg::xbar_rule_64_t [SUPPORT_BUS_NUM_MASTERS-1:0]
    support_bus_addr_map;

  assign support_bus_addr_map = '{
    '{ idx: SUPPORT_BUS_MASTER_DEBUG_PORT,
       start_addr: CFG.SupportBase + SUPPORT_DEBUG_BASE,
       end_addr: CFG.SupportBase + SUPPORT_DEBUG_BASE + SUPPORT_DEBUG_LENGTH },
    '{ idx: SUPPORT_BUS_MASTER_CLINT_PORT,
       start_addr: CFG.SupportBase + SUPPORT_CLINT_BASE,
       end_addr: CFG.SupportBase + SUPPORT_CLINT_BASE + SUPPORT_CLINT_LENGTH },
    '{ idx: SUPPORT_BUS_MASTER_PLIC_PORT,
       start_addr: CFG.SupportBase + SUPPORT_PLIC_BASE,
       end_addr: CFG.SupportBase + SUPPORT_PLIC_BASE + SUPPORT_PLIC_LENGTH },
    '{ idx: SUPPORT_BUS_MASTER_TIMER_PORT,
       start_addr: CFG.SupportBase + SUPPORT_TIMER_BASE,
       end_addr: CFG.SupportBase + SUPPORT_TIMER_BASE + SUPPORT_TIMER_LENGTH },
    '{ idx: SUPPORT_BUS_MASTER_SYSTEM_PORT,
       start_addr: CFG.SystemBase,
       end_addr: CFG.SystemBase + CFG.SystemLength }
  };

  localparam axi_pkg::xbar_cfg_t SUPPORT_AXI_XBAR_CFG = '{
    NoSlvPorts: unsigned'(SUPPORT_BUS_NUM_SLAVES),
    NoMstPorts: unsigned'(SUPPORT_BUS_NUM_MASTERS),
    MaxMstTrans: unsigned'(1), // Probably requires update
    MaxSlvTrans: unsigned'(1), // Probably requires update
    FallThrough: 1'b0,
    LatencyMode: axi_pkg::NO_LATENCY,
    AxiIdWidthSlvPorts: unsigned'(SUPPORT_BUS_ID_WIDTH),
    AxiIdUsedSlvPorts: unsigned'(SUPPORT_BUS_ID_WIDTH),
    UniqueIds: 1'b0,
    AxiAddrWidth: unsigned'(AXI_ADDRESS_WIDTH),
    AxiDataWidth: unsigned'(AXI_DATA_WIDTH),
    NoAddrRules: unsigned'(SUPPORT_BUS_NUM_MASTERS)
  };

  axi_xbar_intf #(
    .AXI_USER_WIDTH ( AXI_USER_WIDTH          ),
    .Cfg            ( SUPPORT_AXI_XBAR_CFG    ),
    .rule_t         ( axi_pkg::xbar_rule_64_t )
  ) i_support_axi_xbar (
    .clk_i                 ( clk_i                ),
    .rst_ni                ( ndmreset_ni          ),
    .test_i                ( test_en_i            ),
    .slv_ports             ( support_bus_slave    ),
    .mst_ports             ( support_bus_master   ),
    .addr_map_i            ( support_bus_addr_map ),
    .en_default_mst_port_i ( '0                   ),
    .default_mst_port_i    ( '0                   )
  );

endmodule
