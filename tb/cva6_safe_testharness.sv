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
// Date: 19.03.2017
//
// Additional contributions by:
//         Sebastien Jacq - sjthales on github.com
//         Daniel Gracia Pérez - dgptha on github.com
//
// Description: Test-harness for Ariane
//              Instantiates an AXI-Bus and memories
//
// ========================================================================== //
// Revisions  :
// Date        Version  Author       Description
// 2020-10-06  0.1      S.Jacq       modification for CVA6 softcore
// 2023-07-21  0.2      D.Gracia Pérez  add support for AMP configurations
// ========================================================================== //

`include "axi/assign.svh"
`include "rvfi_types.svh"

module cva6_safe_testharness #(
  parameter config_pkg::cva6_cfg_t CVA6_CFG = config_pkg::cva6_cfg_empty,
  parameter int unsigned NUM_DCLS = 1,
  parameter int unsigned NUM_WORDS         = 2**25,         // memory size
  parameter bit          StallRandomOutput = 1'b0,
  parameter bit          StallRandomInput  = 1'b0
) (
  input  logic        clk_i,
  input  logic        rst_ni,
  input  logic        jtag_TCK,
  input  logic        jtag_TMS,
  input  logic        jtag_TDI,
  input  logic        jtag_TRSTn,
  output logic        jtag_TDO_data,
  output logic        jtag_TDO_driven,
  output logic dcls_error_o [NUM_DCLS-1:0],
  output logic ecc_error_o [NUM_DCLS-1:0]
);

  function automatic cva6_safe_host_core_support_pkg::config_t
      build_cva6_safe_host_core_config(
          config_pkg::cva6_cfg_t cva6_cfg,
          int unsigned num_dcls,
          int unsigned axi_id_width_slave,
          int unsigned num_ext_irq_sources);
    cva6_safe_host_core_support_pkg::config_t cfg;
    cfg = cva6_safe_host_core_support_pkg::build_config(
        cva6_cfg, num_dcls, axi_id_width_slave, num_ext_irq_sources );
    // The host core requires a bus adapter between the system bus
    // and the support bus.
    // The adapter might be too big if the system bus ID width for slaves
    // is to big as it requires 2**slave_id_width counters to track each
    // of the IDs that could appear (SlvPortMaxUniqIds). We can limit
    // the maximum number of slave IDs through the configuration as
    // follows:
    cfg.SystemToSupportAxiSlvPortMaxUniqIds = axi_id_width_slave;
    return cfg;
  endfunction

  // RVFI types
  localparam type rvfi_instr_t = `RVFI_INSTR_T(CVA6_CFG);
  localparam type rvfi_csr_elmt_t = `RVFI_CSR_ELMT_T(CVA6_CFG);
  localparam type rvfi_csr_t = `RVFI_CSR_T(CVA6_CFG, rvfi_csr_elmt_t);

  // RVFI PROBES types
  localparam type rvfi_probes_instr_t = `RVFI_PROBES_INSTR_T(CVA6_CFG);
  localparam type rvfi_probes_csr_t = `RVFI_PROBES_CSR_T(CVA6_CFG);
  localparam type rvfi_probes_t = struct packed {
    rvfi_probes_csr_t csr;
    rvfi_probes_instr_t instr;
  };

  localparam int unsigned AXI_ADDRESS_WIDTH = CVA6_CFG.AxiAddrWidth;
  localparam int unsigned AXI_DATA_WIDTH    = CVA6_CFG.AxiDataWidth;
  localparam int unsigned AXI_USER_WIDTH    = CVA6_CFG.AxiUserWidth;
  localparam int unsigned AXI_USER_EN       = CVA6_CFG.AXI_USER_EN;
  localparam int unsigned AXI_ID_WIDTH      = CVA6_CFG.AxiIdWidth;

  // IRQ sources connected to the host core tile in this module.
  localparam int NUM_IRQ_SOURCES = 1;

  localparam int NUM_CORES = NUM_DCLS * 2;
  localparam cva6_safe_dcls_types_pkg::dcls_mode_t DCLS_MODE =
    cva6_safe_apu_config_pkg::DCLS_MODE;

  // disable test-enable
  logic                 test_en;
  logic                 ndmreset, ndmreset_n;
  logic [(NUM_DCLS*2)-1:0] debug_req_core; // half of the entries will be used
                                           // in lockstep mode,
                                           // all of them in dual-core mode

  int                   jtag_enable;
  logic                 init_done; // TODO: check who uses it
  logic [31:0]          jtag_exit, dmi_exit;
  logic [31:0]          rvfi_exit[(NUM_DCLS*2)-1:0];

  logic                 debug_req_valid;
  logic                 debug_req_ready;
  logic                 debug_resp_valid;
  logic                 debug_resp_ready;

  logic                 jtag_req_valid;

  logic                 jtag_resp_ready;
  logic                 jtag_resp_valid;

  dm::dmi_req_t         jtag_dmi_req;
  dm::dmi_req_t         debug_req;
  dm::dmi_resp_t        debug_resp;

  assign test_en = 1'b0;

  rstgen i_rstgen_main (
      .clk_i        ( clk_i                    ),
      .rst_ni       ( rst_ni & (~ndmreset) ),
      .test_mode_i  ( test_en                  ),
      .rst_no       ( ndmreset_n               ),
      .init_no      (                          ) // keep open
  );

  // CVA6-Safe host core tile (NUM_CORES+support) = NUM_CORES+1
  // TOTAL                         = NUM_CORES+1
  AXI_BUS #(
    .AXI_ADDR_WIDTH ( AXI_ADDRESS_WIDTH   ),
    .AXI_DATA_WIDTH ( AXI_DATA_WIDTH      ),
    .AXI_ID_WIDTH   ( AXI_ID_WIDTH ),
    .AXI_USER_WIDTH ( AXI_USER_WIDTH      )
  ) slave_system_bus[cva6_safe_soc_pkg::SYSTEM_BUS_NUM_SLAVES-1:0]();

  // Main memory                  = 1
  // support_bus slave connection = 1
  // TOTAL                        = 2
  AXI_BUS #(
    .AXI_ADDR_WIDTH ( AXI_ADDRESS_WIDTH        ),
    .AXI_DATA_WIDTH ( AXI_DATA_WIDTH           ),
    .AXI_ID_WIDTH   ( cva6_safe_soc_pkg::AXI_ID_WIDTH_SLAVE(AXI_ID_WIDTH) ),
    .AXI_USER_WIDTH ( AXI_USER_WIDTH           )
  ) master_system_bus[cva6_safe_soc_pkg::SYSTEM_BUS_NUM_MASTERS-1:0]();

  // Some shortcuts to access the different interfaces and ports in the
  // system bus
  `define SB(__MS__) ``__MS__``_system_bus
  `define SB_P(__MS__, __PORT__) \
    `SB(__MS__)[cva6_safe_soc_pkg::SYSTEM_BUS_``__PORT__``]
  `define MSB `SB(master)
  `define SSB `SB(slave)
  `define MSB_P(__PORT__) `SB_P(master, MASTER_``__PORT__)
  `define SSB_P(__PORT__) `SB_P(slave,  SLAVE_``__PORT__)

  // logic                 uart_irq;
  logic [0:0]           irqs_to_core;
  // assign irqs_to_core[0] = uart_irq;

  // Host core tile
  rvfi_probes_t rvfi_probes[(NUM_DCLS*2)-1:0];
  localparam cva6_safe_host_core_support_pkg::config_t cshcs_cfg =
      build_cva6_safe_host_core_config ( CVA6_CFG, NUM_DCLS,
          cva6_safe_soc_pkg::AXI_ID_WIDTH_SLAVE(AXI_ID_WIDTH),
          NUM_IRQ_SOURCES );
  cva6_safe_host_core #(
    .CFG ( cshcs_cfg ),
    .rvfi_probes_instr_t  ( rvfi_probes_instr_t ),
    .rvfi_probes_csr_t    ( rvfi_probes_csr_t   ),
    .rvfi_probes_t        ( rvfi_probes_t       )
  ) i_cva6_safe_host_core (
    .clk_i        ( clk_i ),
    .boot_addr_i   ( cva6_safe_soc_pkg::ROM_0_BASE[31:0] ),
    .boot_addr_c1_i( cva6_safe_soc_pkg::ROM_1_BASE[31:0] ),
    .rst_ni       ( rst_ni ),
    .jtag_TCK_i   ( jtag_TCK ),
    .jtag_TMS_i   ( jtag_TMS ),
    .jtag_TDI_i   ( jtag_TDI ),
    .jtag_TRST_ni ( jtag_TRSTn ),
    .jtag_TDO_data_o ( jtag_TDO_data ),
    .jtag_TDO_driven_o ( jtag_TDO_driven ),
    .irq_i             ( irqs_to_core ),
    .ndmreset_o   ( ndmreset ),
    .ndmreset_ni  ( ndmreset_n ),
    .rvfi_probes_o     ( rvfi_probes ),
    .dcls_mode_i       ( cva6_safe_apu_config_pkg::DCLS_MODE ), // 0 => DC mode; 1 => LS mode
    .dcls_error_o      ( dcls_error_o ),
    .ecc_error_o      ( ecc_error_o ),
    .ext_slave_bus ( `SSB[(NUM_DCLS*2)-1+1:0] ),
    .ext_master_bus ( `MSB_P(SUPPORT) )
  );

  // assign dcls_error_o = | dcls_error;

  // ---------------
  // ROM
  // ---------------
  logic                         rom_req;
  logic [AXI_ADDRESS_WIDTH-1:0] rom_addr;
  logic [AXI_DATA_WIDTH-1:0]    rom_rdata;

  axi2mem #(
    .AXI_ID_WIDTH   ( cva6_safe_soc_pkg::AXI_ID_WIDTH_SLAVE(AXI_ID_WIDTH)  ),
    .AXI_ADDR_WIDTH ( AXI_ADDRESS_WIDTH                                ),
    .AXI_DATA_WIDTH ( AXI_DATA_WIDTH                                   ),
    .AXI_USER_WIDTH ( AXI_USER_WIDTH                                   )
  ) i_axi2rom (
    .clk_i  ( clk_i        ),
    .rst_ni ( rst_ni  ),
    .slave  ( master_system_bus[cva6_safe_soc_pkg::SYSTEM_BUS_MASTER_ROM_0]   ),
    .req_o  ( rom_req      ),
    .we_o   (              ),
    .addr_o ( rom_addr     ),
    .be_o   (              ),
    .user_o (              ),
    .data_o (              ),
    .user_i ( '0           ),
    .data_i ( rom_rdata    )
  );

  bootrom i_bootrom_c0 (
    .clk_i      ( clk_i     ),
    .req_i      ( rom_req   ),
    .addr_i     ( rom_addr  ),
    .rdata_o    ( rom_rdata )
  );

  // ---------------
  // ROM c 1
  // ---------------
  logic                         rom_c1_req;
  logic [AXI_ADDRESS_WIDTH-1:0] rom_c1_addr;
  logic [AXI_DATA_WIDTH-1:0]    rom_c1_rdata;
  axi2mem #(
    .AXI_ID_WIDTH   ( cva6_safe_soc_pkg::AXI_ID_WIDTH_SLAVE(AXI_ID_WIDTH)     ),
    .AXI_ADDR_WIDTH ( AXI_ADDRESS_WIDTH       ),
    .AXI_DATA_WIDTH ( AXI_DATA_WIDTH       ),
    .AXI_USER_WIDTH ( AXI_USER_WIDTH       )
  ) i_axi2rom_bootrom_c1 (
    .clk_i  ( clk_i         ),
    .rst_ni ( rst_ni       ),
    .slave  ( master_system_bus[cva6_safe_soc_pkg::SYSTEM_BUS_MASTER_ROM_1] ),
    .req_o  ( rom_c1_req      ),
    .we_o   (              ),
    .addr_o ( rom_c1_addr     ),
    .be_o   (              ),
    .user_o (              ),
    .data_o (              ),
    .user_i ( '0           ),
    .data_i ( rom_c1_rdata    )
  );

  bootrom i_bootrom_c1 (
    .clk_i      ( clk_i     ),
    .req_i      ( rom_c1_req   ),
    .addr_i     ( rom_c1_addr  ),
    .rdata_o    ( rom_c1_rdata )
  );

  // ------------------------------
  // Memory + Exclusive Access
  // ------------------------------
  AXI_BUS #(
    .AXI_ADDR_WIDTH ( AXI_ADDRESS_WIDTH        ),
    .AXI_DATA_WIDTH ( AXI_DATA_WIDTH           ),
    .AXI_ID_WIDTH   ( cva6_safe_soc_pkg::AXI_ID_WIDTH_SLAVE(AXI_ID_WIDTH) ),
    .AXI_USER_WIDTH ( AXI_USER_WIDTH           )
  ) dram();

  logic                         req;
  logic                         we;
  logic [AXI_ADDRESS_WIDTH-1:0] addr;
  logic [AXI_DATA_WIDTH/8-1:0]  be;
  logic [AXI_DATA_WIDTH-1:0]    wdata;
  logic [AXI_DATA_WIDTH-1:0]    rdata;
  logic [AXI_USER_WIDTH-1:0]    wuser;
  logic [AXI_USER_WIDTH-1:0]    ruser;

  axi_riscv_atomics_wrap #(
    .AXI_ADDR_WIDTH ( AXI_ADDRESS_WIDTH        ),
    .AXI_DATA_WIDTH ( AXI_DATA_WIDTH           ),
    .AXI_ID_WIDTH   ( cva6_safe_soc_pkg::AXI_ID_WIDTH_SLAVE(AXI_ID_WIDTH) ),
    .AXI_USER_WIDTH ( AXI_USER_WIDTH           ),
    .AXI_MAX_WRITE_TXNS ( 1  ),
    .RISCV_WORD_WIDTH   ( 64 )
  ) i_axi_riscv_atomics (
    .clk_i,
    .rst_ni ( ndmreset_n               ),
    .slv    ( `MSB_P(DRAM) ),
    .mst    ( dram                     )
  );

  AXI_BUS #(
    .AXI_ADDR_WIDTH ( AXI_ADDRESS_WIDTH        ),
    .AXI_DATA_WIDTH ( AXI_DATA_WIDTH           ),
    // .AXI_ID_WIDTH   ( cva6_amp_soc::IdWidthSlave ),
    .AXI_ID_WIDTH   ( cva6_safe_soc_pkg::AXI_ID_WIDTH_SLAVE(AXI_ID_WIDTH) ),
    .AXI_USER_WIDTH ( AXI_USER_WIDTH           )
  ) dram_delayed();

  axi_delayer_intf #(
    // .AXI_ID_WIDTH        ( cva6_amp_soc::IdWidthSlave ),
    .AXI_ID_WIDTH        ( cva6_safe_soc_pkg::AXI_ID_WIDTH_SLAVE(AXI_ID_WIDTH) ),
    .AXI_ADDR_WIDTH      ( AXI_ADDRESS_WIDTH        ),
    .AXI_DATA_WIDTH      ( AXI_DATA_WIDTH           ),
    .AXI_USER_WIDTH      ( AXI_USER_WIDTH           ),
    .STALL_RANDOM_INPUT  ( StallRandomInput         ),
    .STALL_RANDOM_OUTPUT ( StallRandomOutput        ),
    .FIXED_DELAY_INPUT   ( 0                        ),
    .FIXED_DELAY_OUTPUT  ( 0                        )
  ) i_axi_delayer (
    .clk_i  ( clk_i        ),
    .rst_ni ( ndmreset_n   ),
    .slv    ( dram         ),
    .mst    ( dram_delayed )
  );

  axi2mem #(
    // .AXI_ID_WIDTH   ( cva6_amp_soc::IdWidthSlave ),
    .AXI_ID_WIDTH   ( cva6_safe_soc_pkg::AXI_ID_WIDTH_SLAVE(AXI_ID_WIDTH) ),
    .AXI_ADDR_WIDTH ( AXI_ADDRESS_WIDTH        ),
    .AXI_DATA_WIDTH ( AXI_DATA_WIDTH           ),
    .AXI_USER_WIDTH ( AXI_USER_WIDTH           )
  ) i_axi2mem (
    .clk_i  ( clk_i        ),
    .rst_ni ( ndmreset_n   ),
    .slave  ( dram_delayed ),
    .req_o  ( req          ),
    .we_o   ( we           ),
    .addr_o ( addr         ),
    .be_o   ( be           ),
    .user_o ( wuser        ),
    .data_o ( wdata        ),
    .user_i ( ruser        ),
    .data_i ( rdata        )
  );

  sram #(
    .DATA_WIDTH ( AXI_DATA_WIDTH ),
    .USER_WIDTH ( AXI_USER_WIDTH ),
    .USER_EN    ( AXI_USER_EN    ),
    .SIM_INIT   ( "zeros"        ),
    .NUM_WORDS  ( NUM_WORDS      )
  ) i_sram (
    .clk_i      ( clk_i    ),
    .rst_ni     ( rst_ni   ),
    .req_i      ( req      ),
    .we_i       ( we       ),
    .addr_i     ( addr[$clog2(NUM_WORDS)-1+$clog2(AXI_DATA_WIDTH/8):
                       $clog2(AXI_DATA_WIDTH/8)] ),
    .wuser_i    ( wuser    ),
    .wdata_i    ( wdata    ),
    .be_i       ( be       ),
    .ruser_o    ( ruser    ),
    .rdata_o    ( rdata    )
  );

  // -------------------
  // UART
  // -------------------

  logic         uart_penable;
  logic         uart_pwrite;
  logic [31:0]  uart_paddr;
  logic         uart_psel;
  logic [31:0]  uart_pwdata;
  logic [31:0]  uart_prdata;
  logic         uart_pready;
  logic         uart_pslverr;

  axi2apb_64_32 #(
      .AXI4_ADDRESS_WIDTH ( AXI_ADDRESS_WIDTH ),
      .AXI4_RDATA_WIDTH   ( AXI_DATA_WIDTH ),
      .AXI4_WDATA_WIDTH   ( AXI_DATA_WIDTH ),
      .AXI4_ID_WIDTH      ( cva6_safe_soc_pkg::AXI_ID_WIDTH_SLAVE(AXI_ID_WIDTH) ),
      .AXI4_USER_WIDTH    ( AXI_USER_WIDTH ),
      .BUFF_DEPTH_SLAVE   ( 2              ),
      .APB_ADDR_WIDTH     ( 32             )
  ) i_axi2apb_64_32_uart (
      .ACLK      ( clk_i          ),
      .ARESETn   ( rst_ni         ),
      .test_en_i ( 1'b0           ),
      .AWID_i    ( `MSB_P(UART).aw_id     ),
      .AWADDR_i  ( `MSB_P(UART).aw_addr   ),
      .AWLEN_i   ( `MSB_P(UART).aw_len    ),
      .AWSIZE_i  ( `MSB_P(UART).aw_size   ),
      .AWBURST_i ( `MSB_P(UART).aw_burst  ),
      .AWLOCK_i  ( `MSB_P(UART).aw_lock   ),
      .AWCACHE_i ( `MSB_P(UART).aw_cache  ),
      .AWPROT_i  ( `MSB_P(UART).aw_prot   ),
      .AWREGION_i( `MSB_P(UART).aw_region ),
      .AWUSER_i  ( `MSB_P(UART).aw_user   ),
      .AWQOS_i   ( `MSB_P(UART).aw_qos    ),
      .AWVALID_i ( `MSB_P(UART).aw_valid  ),
      .AWREADY_o ( `MSB_P(UART).aw_ready  ),
      .WDATA_i   ( `MSB_P(UART).w_data    ),
      .WSTRB_i   ( `MSB_P(UART).w_strb    ),
      .WLAST_i   ( `MSB_P(UART).w_last    ),
      .WUSER_i   ( `MSB_P(UART).w_user    ),
      .WVALID_i  ( `MSB_P(UART).w_valid   ),
      .WREADY_o  ( `MSB_P(UART).w_ready   ),
      .BID_o     ( `MSB_P(UART).b_id      ),
      .BRESP_o   ( `MSB_P(UART).b_resp    ),
      .BVALID_o  ( `MSB_P(UART).b_valid   ),
      .BUSER_o   ( `MSB_P(UART).b_user    ),
      .BREADY_i  ( `MSB_P(UART).b_ready   ),
      .ARID_i    ( `MSB_P(UART).ar_id     ),
      .ARADDR_i  ( `MSB_P(UART).ar_addr   ),
      .ARLEN_i   ( `MSB_P(UART).ar_len    ),
      .ARSIZE_i  ( `MSB_P(UART).ar_size   ),
      .ARBURST_i ( `MSB_P(UART).ar_burst  ),
      .ARLOCK_i  ( `MSB_P(UART).ar_lock   ),
      .ARCACHE_i ( `MSB_P(UART).ar_cache  ),
      .ARPROT_i  ( `MSB_P(UART).ar_prot   ),
      .ARREGION_i( `MSB_P(UART).ar_region ),
      .ARUSER_i  ( `MSB_P(UART).ar_user   ),
      .ARQOS_i   ( `MSB_P(UART).ar_qos    ),
      .ARVALID_i ( `MSB_P(UART).ar_valid  ),
      .ARREADY_o ( `MSB_P(UART).ar_ready  ),
      .RID_o     ( `MSB_P(UART).r_id      ),
      .RDATA_o   ( `MSB_P(UART).r_data    ),
      .RRESP_o   ( `MSB_P(UART).r_resp    ),
      .RLAST_o   ( `MSB_P(UART).r_last    ),
      .RUSER_o   ( `MSB_P(UART).r_user    ),
      .RVALID_o  ( `MSB_P(UART).r_valid   ),
      .RREADY_i  ( `MSB_P(UART).r_ready   ),
      .PENABLE   ( uart_penable   ),
      .PWRITE    ( uart_pwrite    ),
      .PADDR     ( uart_paddr     ),
      .PSEL      ( uart_psel      ),
      .PWDATA    ( uart_pwdata    ),
      .PRDATA    ( uart_prdata    ),
      .PREADY    ( uart_pready    ),
      .PSLVERR   ( uart_pslverr   )
  );

  logic tx, rx;

  apb_uart i_apb_uart (
      .CLK     ( clk_i           ),
      .RSTN    ( rst_ni          ),
      .PSEL    ( uart_psel       ),
      .PENABLE ( uart_penable    ),
      .PWRITE  ( uart_pwrite     ),
      .PADDR   ( uart_paddr[4:2] ),
      .PWDATA  ( uart_pwdata     ),
      .PRDATA  ( uart_prdata     ),
      .PREADY  ( uart_pready     ),
      .PSLVERR ( uart_pslverr    ),
      .INT     ( irqs_to_core[0] ),
      .OUT1N   (                 ), // keep open
      .OUT2N   (                 ), // keep open
      .RTSN    (                 ), // no flow control
      .DTRN    (                 ), // no flow control
      .CTSN    ( 1'b0            ),
      .DSRN    ( 1'b0            ),
      .DCDN    ( 1'b0            ),
      .RIN     ( 1'b0            ),
      .SIN     ( rx              ),
      .SOUT    ( tx              )
  );

  uart_bus #(
    .BAUD_RATE(115200),
    .PARITY_EN(0)
  ) i_uart_bus (
    .rx(tx),
    .tx(rx),
    .rx_en(1'b1)
  );

  // -------------------
  // BUSES
  // -------------------

  axi_pkg::xbar_rule_64_t [cva6_safe_soc_pkg::SYSTEM_BUS_NUM_MASTERS-1:0]
    system_bus_addr_map;

  assign system_bus_addr_map = '{
    '{ idx: cva6_safe_soc_pkg::SYSTEM_BUS_MASTER_DRAM,
       start_addr: cva6_safe_soc_pkg::DRAM_BASE,
       end_addr: cva6_safe_soc_pkg::DRAM_BASE + cva6_safe_soc_pkg::DRAM_LENGTH},
  '{ idx: cva6_safe_soc_pkg::SYSTEM_BUS_MASTER_ROM_0,
     start_addr: cva6_safe_soc_pkg::ROM_0_BASE,
     end_addr: cva6_safe_soc_pkg::ROM_0_BASE + cva6_safe_soc_pkg::ROM_0_LENGTH },
  '{ idx: cva6_safe_soc_pkg::SYSTEM_BUS_MASTER_ROM_1,
     start_addr: cva6_safe_soc_pkg::ROM_1_BASE,
     end_addr: cva6_safe_soc_pkg::ROM_1_BASE + cva6_safe_soc_pkg::ROM_1_LENGTH },
    '{ idx: cva6_safe_soc_pkg::SYSTEM_BUS_MASTER_SUPPORT,
       start_addr: cva6_safe_soc_pkg::SUPPORT_BASE,
       end_addr: cva6_safe_soc_pkg::SUPPORT_BASE + cva6_safe_soc_pkg::SUPPORT_LENGTH},
    '{ idx: cva6_safe_soc_pkg::SYSTEM_BUS_MASTER_UART,
       start_addr: cva6_safe_soc_pkg::UART_BASE,
       end_addr: cva6_safe_soc_pkg::UART_BASE + cva6_safe_soc_pkg::UART_LENGTH}
  };

  localparam axi_pkg::xbar_cfg_t SYSTEM_AXI_XBAR_CFG = '{
    NoSlvPorts: unsigned'(cva6_safe_soc_pkg::SYSTEM_BUS_NUM_SLAVES),
    NoMstPorts: unsigned'(cva6_safe_soc_pkg::SYSTEM_BUS_NUM_MASTERS),
    MaxMstTrans: unsigned'(1), // Probably requires update
    MaxSlvTrans: unsigned'(1), // Probably requires update
    FallThrough: 1'b0,
    LatencyMode: axi_pkg::NO_LATENCY,
    AxiIdWidthSlvPorts: unsigned'(AXI_ID_WIDTH),
    AxiIdUsedSlvPorts: unsigned'(AXI_ID_WIDTH),
    UniqueIds: 1'b0,
    AxiAddrWidth: unsigned'(AXI_ADDRESS_WIDTH),
    AxiDataWidth: unsigned'(AXI_DATA_WIDTH),
    NoAddrRules: unsigned'(cva6_safe_soc_pkg::SYSTEM_BUS_NUM_MASTERS)
  };

  axi_xbar_intf #(
    .AXI_USER_WIDTH ( AXI_USER_WIDTH          ),
    .Cfg            ( SYSTEM_AXI_XBAR_CFG     ),
    .rule_t         ( axi_pkg::xbar_rule_64_t )
  ) i_system_axi_xbar (
    .clk_i                 ( clk_i               ),
    .rst_ni                ( ndmreset_n          ),
    .test_i                ( test_en             ),
    .slv_ports             ( slave_system_bus    ),
    .mst_ports             ( master_system_bus   ),
    .addr_map_i            ( system_bus_addr_map ),
    .en_default_mst_port_i ( '0                  ),
    .default_mst_port_i    ( '0                  )
  );

  // -------------
  // RVFI modules
  // -------------
  rvfi_csr_t rvfi_csr[(NUM_DCLS*2)-1:0];
  rvfi_instr_t [CVA6_CFG.NrCommitPorts-1:0]  rvfi_instr[(NUM_DCLS*2)-1:0];

  genvar core_idx;

  generate
    for (core_idx = 0; core_idx < (NUM_DCLS * 2); core_idx++) begin
      cva6_rvfi #(
          .CVA6Cfg             ( CVA6_CFG            ),
          .rvfi_instr_t        ( rvfi_instr_t        ),
          .rvfi_csr_t          ( rvfi_csr_t          ),
          .rvfi_probes_instr_t ( rvfi_probes_instr_t ),
          .rvfi_probes_csr_t   ( rvfi_probes_csr_t   ),
          .rvfi_probes_t       ( rvfi_probes_t       )
      ) i_cva6_rvfi (
          .clk_i         ( clk_i                 ),
          .rst_ni        ( rst_ni                ),
          .rvfi_probes_i ( rvfi_probes[core_idx] ),
          .rvfi_instr_o  ( rvfi_instr[core_idx]  ),
          .rvfi_csr_o    ( rvfi_csr[core_idx]    )
      );

      rvfi_tracer  #(
        .CVA6Cfg      ( CVA6_CFG                 ),
        .rvfi_instr_t ( rvfi_instr_t             ),
        .rvfi_csr_t   ( rvfi_csr_t               ),
        //
        .HART_ID      ( CVA6_CFG.XLEN'(core_idx) ),
        .DEBUG_START  ( 0                        ),
        .DEBUG_STOP   ( 0                        )
      ) i_rvfi_tracer (
        .clk_i         ( clk_i                ),
        .rst_ni        ( rst_ni               ),
        .rvfi_i        ( rvfi_instr[core_idx] ),
        .rvfi_csr_i    ( rvfi_csr[core_idx]   ),
        .end_of_test_o ( rvfi_exit[core_idx]  )
      );
    end
  endgenerate

endmodule
