// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright (c) 2026 Thales SA
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

// Description: Xilinx FPGA top-level
// Original author: Florian Zaruba <zarubaf@iis.ee.ethz.ch>
// Author: Daniel Gracia Pérez, Thales Research and Technology cortAIx Labs
//         <daniel.gracia-perez@thalesgroup.com>

`include "rvfi_types.svh"

module cva6_safe_xilinx (
// WARNING: Do not define input parameters. This causes the FPGA build to fail.
`ifdef GENESYSII
  input  logic         sys_clk_p   ,
  input  logic         sys_clk_n   ,
  input  logic         cpu_resetn  ,
  inout  wire  [31:0]  ddr3_dq     ,
  inout  wire  [ 3:0]  ddr3_dqs_n  ,
  inout  wire  [ 3:0]  ddr3_dqs_p  ,
  output logic [14:0]  ddr3_addr   ,
  output logic [ 2:0]  ddr3_ba     ,
  output logic         ddr3_ras_n  ,
  output logic         ddr3_cas_n  ,
  output logic         ddr3_we_n   ,
  output logic         ddr3_reset_n,
  output logic [ 0:0]  ddr3_ck_p   ,
  output logic [ 0:0]  ddr3_ck_n   ,
  output logic [ 0:0]  ddr3_cke    ,
  output logic [ 0:0]  ddr3_cs_n   ,
  output logic [ 3:0]  ddr3_dm     ,
  output logic [ 0:0]  ddr3_odt    ,

  output wire          eth_rst_n   ,
  input  wire          eth_rxck    ,
  input  wire          eth_rxctl   ,
  input  wire [3:0]    eth_rxd     ,
  output wire          eth_txck    ,
  output wire          eth_txctl   ,
  output wire [3:0]    eth_txd     ,
  inout  wire          eth_mdio    ,
  output logic         eth_mdc     ,
  output logic [ 7:0]  led         ,
  input  logic [ 7:0]  sw          ,
  output logic         fan_pwm     ,
  input  logic         trst_n      ,
`elsif KC705
  input  logic         sys_clk_p   ,
  input  logic         sys_clk_n   ,

  input  logic         cpu_reset   ,
  inout  logic [63:0]  ddr3_dq     ,
  inout  logic [ 7:0]  ddr3_dqs_n  ,
  inout  logic [ 7:0]  ddr3_dqs_p  ,
  output logic [13:0]  ddr3_addr   ,
  output logic [ 2:0]  ddr3_ba     ,
  output logic         ddr3_ras_n  ,
  output logic         ddr3_cas_n  ,
  output logic         ddr3_we_n   ,
  output logic         ddr3_reset_n,
  output logic [ 0:0]  ddr3_ck_p   ,
  output logic [ 0:0]  ddr3_ck_n   ,
  output logic [ 0:0]  ddr3_cke    ,
  output logic [ 0:0]  ddr3_cs_n   ,
  output logic [ 7:0]  ddr3_dm     ,
  output logic [ 0:0]  ddr3_odt    ,

  output wire          eth_rst_n   ,
  input  wire          eth_rxck    ,
  input  wire          eth_rxctl   ,
  input  wire [3:0]    eth_rxd     ,
  output wire          eth_txck    ,
  output wire          eth_txctl   ,
  output wire [3:0]    eth_txd     ,
  inout  wire          eth_mdio    ,
  output logic         eth_mdc     ,
  output logic [ 3:0]  led         ,
  input  logic [ 3:0]  sw          ,
  output logic         fan_pwm     ,
  input  logic         trst_n      ,
`elsif VC707
  input  logic         sys_clk_p   ,
  input  logic         sys_clk_n   ,
  input  logic         cpu_reset   ,
  inout  wire  [63:0]  ddr3_dq     ,
  inout  wire  [ 7:0]  ddr3_dqs_n  ,
  inout  wire  [ 7:0]  ddr3_dqs_p  ,
  output logic [13:0]  ddr3_addr   ,
  output logic [ 2:0]  ddr3_ba     ,
  output logic         ddr3_ras_n  ,
  output logic         ddr3_cas_n  ,
  output logic         ddr3_we_n   ,
  output logic         ddr3_reset_n,
  output logic [ 0:0]  ddr3_ck_p   ,
  output logic [ 0:0]  ddr3_ck_n   ,
  output logic [ 0:0]  ddr3_cke    ,
  output logic [ 0:0]  ddr3_cs_n   ,
  output logic [ 7:0]  ddr3_dm     ,
  output logic [ 0:0]  ddr3_odt    ,
  output wire          eth_rst_n   ,
  input  wire          eth_rxck    ,
  input  wire          eth_rxctl   ,
  input  wire [3:0]    eth_rxd     ,
  output wire          eth_txck    ,
  output wire          eth_txctl   ,
  output wire [3:0]    eth_txd     ,
  inout  wire          eth_mdio    ,
  output logic         eth_mdc     ,
  output logic [ 7:0]  led         ,
  input  logic [ 7:0]  sw          ,
  output logic         fan_pwm     ,
  input  logic         trst        ,
`elsif VCU118
  input  wire          c0_sys_clk_p    ,  // 250 MHz Clock for DDR
  input  wire          c0_sys_clk_n    ,  // 250 MHz Clock for DDR
  input  wire          sys_clk_p       ,  // 100 MHz Clock for PCIe
  input  wire          sys_clk_n       ,  // 100 MHz Clock for PCIE
  input  wire          sys_rst_n       ,  // PCIe Reset
  input  logic         cpu_reset       ,  // CPU subsystem reset
  output wire [16:0]   c0_ddr4_adr     ,
  output wire [1:0]    c0_ddr4_ba      ,
  output wire [0:0]    c0_ddr4_cke     ,
  output wire [0:0]    c0_ddr4_cs_n    ,
  inout  wire [7:0]    c0_ddr4_dm_dbi_n,
  inout  wire [63:0]   c0_ddr4_dq      ,
  inout  wire [7:0]    c0_ddr4_dqs_c   ,
  inout  wire [7:0]    c0_ddr4_dqs_t   ,
  output wire [0:0]    c0_ddr4_odt     ,
  output wire [0:0]    c0_ddr4_bg      ,
  output wire          c0_ddr4_reset_n ,
  output wire          c0_ddr4_act_n   ,
  output wire [0:0]    c0_ddr4_ck_c    ,
  output wire [0:0]    c0_ddr4_ck_t    ,
  output wire [7:0]    pci_exp_txp     ,
  output wire [7:0]    pci_exp_txn     ,
  input  wire [7:0]    pci_exp_rxp     ,
  input  wire [7:0]    pci_exp_rxn     ,
  input  logic         trst_n          ,
`endif
  // SPI
  output logic        spi_mosi    ,
  input  logic        spi_miso    ,
  output logic        spi_ss      ,
  output logic        spi_clk_o   ,
  // common part
  // input logic      trst_n      ,
  input  logic        tck         ,
  input  logic        tms         ,
  input  logic        tdi         ,
  output wire         tdo         ,
  input  logic        rx          ,
  output logic        tx
);

// CVA6 Xilinx configuration
function automatic config_pkg::cva6_cfg_t build_fpga_config(config_pkg::cva6_user_cfg_t CVA6UserCfg);
  config_pkg::cva6_user_cfg_t cfg = CVA6UserCfg;
  cfg.ZiCondExtEn = bit'(0);
  cfg.NrNonIdempotentRules = unsigned'(1);
  cfg.NonIdempotentAddrBase = 1024'({64'b0});
  cfg.NonIdempotentLength = 1024'({CVA6UserCfg.ExecuteRegionAddrBase[2]});
  // Define execution regions
  cfg.NrExecuteRegionRules = unsigned'(4);
  cfg.ExecuteRegionAddrBase = 1024'( {dcls_soc_pkg::DRAM_BASE,
    dcls_soc_pkg::ROM_1_BASE, dcls_soc_pkg::ROM_0_BASE, dcls_soc_pkg::DEBUG_BASE} );
  cfg.ExecuteRegionLength = 1024'( {dcls_soc_pkg::DRAM_LENGTH,
    dcls_soc_pkg::ROM_1_LENGTH, dcls_soc_pkg::ROM_0_LENGTH, dcls_soc_pkg::DEBUG_LENGTH} );
  // TLB configuration
  cfg.InstrTlbEntries = int'(16);
  cfg.DataTlbEntries = int'(16);
  cfg.UseSharedTlb = bit'(0);
  cfg.SharedTlbDepth = int'(64);

  return build_config_pkg::build_config(cfg);
endfunction

// CVA6 Safe configuration
function automatic cva6_safe_host_core_support_pkg::config_t
    build_cva6_safe_host_core_config(
        config_pkg::cva6_cfg_t cva6_cfg,
        int unsigned num_dcls,
        int unsigned axi_id_width_slave,
        int unsigned num_ext_irq_sources);
  cva6_safe_host_core_support_pkg::config_t cfg;
  cfg = cva6_safe_host_core_support_pkg::build_config(
      cva6_cfg, num_dcls, axi_id_width_slave, num_ext_irq_sources );
  cfg.SupportBase = dcls_soc_pkg::SUPPORT_BASE;
  cfg.SystemBase = dcls_soc_pkg::SYSTEM_BASE;
  cfg.SystemLength = dcls_soc_pkg::SYSTEM_LENGTH;
  cfg.SystemToSupportAxiSlvPortMaxUniqIds = axi_id_width_slave;
  return cfg;
endfunction

// CVA6 Xilinx configuration
localparam config_pkg::cva6_cfg_t CVA6_CFG =
    build_fpga_config(cva6_config_pkg::cva6_cfg);

localparam type rvfi_probes_instr_t = `RVFI_PROBES_INSTR_T(CVA6_CFG);
localparam type rvfi_probes_csr_t = `RVFI_PROBES_CSR_T(CVA6_CFG);
localparam type rvfi_probes_t = struct packed {
  logic csr;
  logic instr;
};

// 24 MByte in 8 byte words
localparam NumWords = (24 * 1024 * 1024) / 8;
localparam NBMaster = dcls_soc_pkg::SYSTEM_BUS_NUM_MASTERS;
localparam NBSlave = dcls_soc_pkg::SYSTEM_BUS_NUM_SLAVES;
localparam AXI_ADDR_WIDTH = CVA6_CFG.AxiAddrWidth;
localparam AXI_DATA_WIDTH = CVA6_CFG.AxiDataWidth;
localparam AXI_ID_WIDTH = CVA6_CFG.AxiIdWidth;
localparam AXI_ID_WIDTH_SLAVE = AXI_ID_WIDTH + $clog2(NBSlave);
localparam AXI_USER_WIDTH = CVA6_CFG.AxiUserWidth;

localparam NUM_DCLS = cva6_safe_apu_config_pkg::NUM_DCLS;
localparam NUM_CORES = NUM_DCLS * 2;

`AXI_TYPEDEF_ALL(axi_slave,
    logic [    AXI_ADDR_WIDTH-1:0],
    logic [AXI_ID_WIDTH_SLAVE-1:0],
    logic [    AXI_DATA_WIDTH-1:0],
    logic [(AXI_DATA_WIDTH/8)-1:0],
    logic [    AXI_USER_WIDTH-1:0])

AXI_BUS #(
  .AXI_ADDR_WIDTH ( AXI_ADDR_WIDTH ),
  .AXI_DATA_WIDTH ( AXI_DATA_WIDTH ),
  .AXI_ID_WIDTH   ( AXI_ID_WIDTH   ),
  .AXI_USER_WIDTH ( AXI_USER_WIDTH )
) slave[NBSlave-1:0]();

AXI_BUS #(
  .AXI_ADDR_WIDTH ( AXI_ADDR_WIDTH     ),
  .AXI_DATA_WIDTH ( AXI_DATA_WIDTH     ),
  .AXI_ID_WIDTH   ( AXI_ID_WIDTH_SLAVE ),
  .AXI_USER_WIDTH ( AXI_USER_WIDTH     )
) master[NBMaster-1:0]();

// disable test-enable
logic test_en;
logic ndmreset;
logic ndmreset_n;

logic clk;
logic eth_clk;
logic spi_clk_i;
logic phy_tx_clk;
logic sd_clk_sys;

logic ddr_sync_reset;
logic ddr_clock_out;

logic rst_n;
logic rtc;

// we need to switch reset polarity
`ifdef VCU118
logic cpu_resetn;
assign cpu_resetn = ~cpu_reset;
`elsif GENESYSII
logic cpu_reset;
assign cpu_reset  = ~cpu_resetn;
`elsif KC705
assign cpu_resetn = ~cpu_reset;
`elsif VC707
assign cpu_resetn = ~cpu_reset;
assign trst_n = ~trst;
`endif

logic pll_locked;

// IRQ
logic [dcls_soc_pkg::NUM_EXT_IRQ_SOURCES-1:0] irq_sources;
assign test_en    = 1'b0;

logic [NBSlave-1:0] pc_asserted;

rstgen i_rstgen_main (
    .clk_i        ( clk                      ),
    .rst_ni       ( pll_locked & (~ndmreset) ),
    .test_mode_i  ( test_en                  ),
    .rst_no       ( ndmreset_n               ),
    .init_no      (                          ) // keep open
);

assign rst_n = ~ddr_sync_reset;

// ---------------
// AXI Xbar
// ---------------

axi_pkg::xbar_rule_64_t [NBMaster-1:0] addr_map;

assign addr_map = '{
  '{ idx: dcls_soc_pkg::SYSTEM_BUS_MASTER_SUPPORT,
     start_addr: dcls_soc_pkg::SUPPORT_BASE,
     end_addr: dcls_soc_pkg::SUPPORT_BASE + dcls_soc_pkg::SUPPORT_LENGTH },
  '{ idx: dcls_soc_pkg::SYSTEM_BUS_MASTER_UART,
     start_addr: dcls_soc_pkg::UART_BASE,
     end_addr: dcls_soc_pkg::UART_BASE + dcls_soc_pkg::UART_LENGTH },
  '{ idx: dcls_soc_pkg::SYSTEM_BUS_MASTER_SPI,
    start_addr: dcls_soc_pkg::SPI_BASE,
    end_addr: dcls_soc_pkg::SPI_BASE + dcls_soc_pkg::SPI_LENGTH },
  '{ idx: dcls_soc_pkg::SYSTEM_BUS_MASTER_ETHERNET,
     start_addr: dcls_soc_pkg::ETHERNET_BASE,
     end_addr: dcls_soc_pkg::ETHERNET_BASE + dcls_soc_pkg::ETHERNET_LENGTH },
  '{ idx: dcls_soc_pkg::SYSTEM_BUS_MASTER_GPIO,
     start_addr: dcls_soc_pkg::GPIO_BASE,
     end_addr: dcls_soc_pkg::GPIO_BASE + dcls_soc_pkg::GPIO_LENGTH },
  '{ idx: dcls_soc_pkg::SYSTEM_BUS_MASTER_ROM_0,
     start_addr: dcls_soc_pkg::ROM_0_BASE,
     end_addr: dcls_soc_pkg::ROM_0_BASE + dcls_soc_pkg::ROM_0_LENGTH },
  '{ idx: dcls_soc_pkg::SYSTEM_BUS_MASTER_ROM_1,
     start_addr: dcls_soc_pkg::ROM_1_BASE,
     end_addr: dcls_soc_pkg::ROM_1_BASE + dcls_soc_pkg::ROM_1_LENGTH },
  '{ idx: dcls_soc_pkg::SYSTEM_BUS_MASTER_DRAM,
     start_addr: dcls_soc_pkg::DRAM_BASE,
     end_addr: dcls_soc_pkg::DRAM_BASE + dcls_soc_pkg::DRAM_LENGTH }
};

localparam axi_pkg::xbar_cfg_t AXI_XBAR_CFG = '{
  NoSlvPorts:         NBSlave,
  NoMstPorts:         NBMaster,
  MaxMstTrans:        1, // Probably requires update
  MaxSlvTrans:        1, // Probably requires update
  FallThrough:        1'b0,
  LatencyMode:        axi_pkg::CUT_ALL_PORTS,
  AxiIdWidthSlvPorts: AXI_ID_WIDTH,
  AxiIdUsedSlvPorts:  AXI_ID_WIDTH,
  UniqueIds:          1'b0,
  AxiAddrWidth:       AXI_ADDR_WIDTH,
  AxiDataWidth:       AXI_DATA_WIDTH,
  NoAddrRules:        NBMaster
};

axi_xbar_intf #(
  .AXI_USER_WIDTH ( AXI_USER_WIDTH          ),
  .Cfg            ( AXI_XBAR_CFG            ),
  .rule_t         ( axi_pkg::xbar_rule_64_t )
) i_axi_xbar (
  .clk_i                 ( clk        ),
  .rst_ni                ( ndmreset_n ),
  .test_i                ( test_en    ),
  .slv_ports             ( slave      ),
  .mst_ports             ( master     ),
  .addr_map_i            ( addr_map   ),
  .en_default_mst_port_i ( '0         ),
  .default_mst_port_i    ( '0         )
);

// ---------------
// Host tile
// ---------------
logic dcls_error[NUM_DCLS-1:0];
logic ecc_error[NUM_DCLS-1:0];
logic [2*NUM_DCLS-1:0] dcls_led;
genvar dcls_idx;

generate
  for (dcls_idx = 0;
      dcls_idx < NUM_DCLS;
        dcls_idx++) begin: dcls_error_routing
    always_comb begin: dcls_error_comb
        led[dcls_idx] = dcls_error[dcls_idx] | dcls_led[dcls_idx] ;
        led[dcls_idx+NUM_DCLS] = ecc_error[dcls_idx] | dcls_led[dcls_idx+NUM_DCLS] ;
    end
  end
endgenerate

logic dcls_mode, dcls_mode_q;

always_ff @(posedge clk) begin
  if (!ndmreset_n) begin
    dcls_mode_q <= sw[0];
  end
end

assign dcls_mode = dcls_mode_q;

// Clock gating
logic enable_sync1, enable_sync2;
logic gclk;
// Double synchronization of the enable signal to avoid metastability
always_ff @(posedge clk or negedge ndmreset_n) begin
    if (!ndmreset_n) begin
        enable_sync1 <= 1'b0;
        enable_sync2 <= 1'b0;
    end else begin
        enable_sync1 <= sw[1];
        enable_sync2 <= enable_sync1;
    end
end

// Use enable_latched to generate gclk
//assign gclk = clk & enable_sync2;
BUFGCE bufgce_inst (
    .O(gclk),
    .CE(enable_sync2),
    .I(clk)
);

localparam cva6_safe_host_core_support_pkg::config_t cshcs_cfg =
    build_cva6_safe_host_core_config ( CVA6_CFG, NUM_DCLS,
        cva6_safe_soc_pkg::AXI_ID_WIDTH_SLAVE(AXI_ID_WIDTH),
        dcls_soc_pkg::NUM_EXT_IRQ_SOURCES );

cva6_safe_host_core #(
  .CFG ( cshcs_cfg ),
  .rvfi_probes_instr_t ( rvfi_probes_instr_t              ),
  .rvfi_probes_csr_t   ( rvfi_probes_csr_t                ),
  .rvfi_probes_t       ( rvfi_probes_t                    )
  // let defaults for:
  // .AXI_USER_EN (),
) i_cva6_safe_host_core (
  .clk_i             ( gclk                                            ),
  .rst_ni            ( rst_n                                           ),
  .boot_addr_i       ( dcls_soc_pkg::ROM_0_BASE                        ),
  .boot_addr_c1_i    ( dcls_soc_pkg::ROM_1_BASE                        ),
  .jtag_TCK_i        ( tck                                             ),
  .jtag_TMS_i        ( tms                                             ),
  .jtag_TDI_i        ( tdi                                             ),
  .jtag_TRST_ni      ( trst_n                                          ),
  .jtag_TDO_data_o   ( tdo                                             ),
  .jtag_TDO_driven_o (                                                 ),
  .irq_i             ( irq_sources                                     ),
  .ndmreset_o        ( ndmreset                                        ),
  .ndmreset_ni       ( ndmreset_n                                      ),
  .rvfi_probes_o     ( /* open */                                      ),
  .dcls_mode_i       ( dcls_mode                                       ),
  .dcls_error_o      ( dcls_error                                      ),
  .ecc_error_o       ( ecc_error                                       ),
  .ext_slave_bus     ( slave[(NUM_CORES-1)+1:0]                        ),
  .ext_master_bus    ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_SUPPORT] )
);

// ---------------
// Peripherals
// ---------------
`ifdef KC705
  logic [7:0] unused_led;
  logic [3:0] unused_switches = 4'b0000;
`endif

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
  .AXI4_ADDRESS_WIDTH ( AXI_ADDR_WIDTH ),
  .AXI4_RDATA_WIDTH   ( AXI_DATA_WIDTH ),
  .AXI4_WDATA_WIDTH   ( AXI_DATA_WIDTH ),
  .AXI4_ID_WIDTH      ( dcls_soc_pkg::AXI_ID_WIDTH_SLAVE(AXI_ID_WIDTH) ),
  .AXI4_USER_WIDTH    ( AXI_USER_WIDTH ),
  .BUFF_DEPTH_SLAVE   ( 2              ),
  .APB_ADDR_WIDTH     ( 32             )
) i_axi2apb_64_32_uart (
  .ACLK      ( clk            ),
  .ARESETn   ( rst_n          ),
  .test_en_i ( 1'b0           ),
  .AWID_i    ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_UART].aw_id     ),
  .AWADDR_i  ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_UART].aw_addr   ),
  .AWLEN_i   ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_UART].aw_len    ),
  .AWSIZE_i  ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_UART].aw_size   ),
  .AWBURST_i ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_UART].aw_burst  ),
  .AWLOCK_i  ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_UART].aw_lock   ),
  .AWCACHE_i ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_UART].aw_cache  ),
  .AWPROT_i  ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_UART].aw_prot   ),
  .AWREGION_i( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_UART].aw_region ),
  .AWUSER_i  ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_UART].aw_user   ),
  .AWQOS_i   ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_UART].aw_qos    ),
  .AWVALID_i ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_UART].aw_valid  ),
  .AWREADY_o ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_UART].aw_ready  ),
  .WDATA_i   ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_UART].w_data    ),
  .WSTRB_i   ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_UART].w_strb    ),
  .WLAST_i   ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_UART].w_last    ),
  .WUSER_i   ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_UART].w_user    ),
  .WVALID_i  ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_UART].w_valid   ),
  .WREADY_o  ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_UART].w_ready   ),
  .BID_o     ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_UART].b_id      ),
  .BRESP_o   ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_UART].b_resp    ),
  .BVALID_o  ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_UART].b_valid   ),
  .BUSER_o   ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_UART].b_user    ),
  .BREADY_i  ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_UART].b_ready   ),
  .ARID_i    ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_UART].ar_id     ),
  .ARADDR_i  ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_UART].ar_addr   ),
  .ARLEN_i   ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_UART].ar_len    ),
  .ARSIZE_i  ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_UART].ar_size   ),
  .ARBURST_i ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_UART].ar_burst  ),
  .ARLOCK_i  ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_UART].ar_lock   ),
  .ARCACHE_i ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_UART].ar_cache  ),
  .ARPROT_i  ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_UART].ar_prot   ),
  .ARREGION_i( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_UART].ar_region ),
  .ARUSER_i  ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_UART].ar_user   ),
  .ARQOS_i   ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_UART].ar_qos    ),
  .ARVALID_i ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_UART].ar_valid  ),
  .ARREADY_o ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_UART].ar_ready  ),
  .RID_o     ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_UART].r_id      ),
  .RDATA_o   ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_UART].r_data    ),
  .RRESP_o   ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_UART].r_resp    ),
  .RLAST_o   ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_UART].r_last    ),
  .RUSER_o   ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_UART].r_user    ),
  .RVALID_o  ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_UART].r_valid   ),
  .RREADY_i  ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_UART].r_ready   ),
  .PENABLE   ( uart_penable   ),
  .PWRITE    ( uart_pwrite    ),
  .PADDR     ( uart_paddr     ),
  .PSEL      ( uart_psel      ),
  .PWDATA    ( uart_pwdata    ),
  .PRDATA    ( uart_prdata    ),
  .PREADY    ( uart_pready    ),
  .PSLVERR   ( uart_pslverr   )
);

// logic tx, rx;

apb_uart i_apb_uart (
  .CLK     ( clk             ),
  .RSTN    ( rst_n           ),
  .PSEL    ( uart_psel       ),
  .PENABLE ( uart_penable    ),
  .PWRITE  ( uart_pwrite     ),
  .PADDR   ( uart_paddr[4:2] ),
  .PWDATA  ( uart_pwdata     ),
  .PRDATA  ( uart_prdata     ),
  .PREADY  ( uart_pready     ),
  .PSLVERR ( uart_pslverr    ),
  .INT     ( irq_sources[0]  ),
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

// ---------------
// SPI
// ---------------
assign master[dcls_soc_pkg::SYSTEM_BUS_MASTER_SPI].b_user = 1'b0;
assign master[dcls_soc_pkg::SYSTEM_BUS_MASTER_SPI].r_user = 1'b0;

logic [31:0] s_axi_spi_awaddr;
logic [7:0]  s_axi_spi_awlen;
logic [2:0]  s_axi_spi_awsize;
logic [1:0]  s_axi_spi_awburst;
logic [0:0]  s_axi_spi_awlock;
logic [3:0]  s_axi_spi_awcache;
logic [2:0]  s_axi_spi_awprot;
logic [3:0]  s_axi_spi_awregion;
logic [3:0]  s_axi_spi_awqos;
logic        s_axi_spi_awvalid;
logic        s_axi_spi_awready;
logic [31:0] s_axi_spi_wdata;
logic [3:0]  s_axi_spi_wstrb;
logic        s_axi_spi_wlast;
logic        s_axi_spi_wvalid;
logic        s_axi_spi_wready;
logic [1:0]  s_axi_spi_bresp;
logic        s_axi_spi_bvalid;
logic        s_axi_spi_bready;
logic [31:0] s_axi_spi_araddr;
logic [7:0]  s_axi_spi_arlen;
logic [2:0]  s_axi_spi_arsize;
logic [1:0]  s_axi_spi_arburst;
logic [0:0]  s_axi_spi_arlock;
logic [3:0]  s_axi_spi_arcache;
logic [2:0]  s_axi_spi_arprot;
logic [3:0]  s_axi_spi_arregion;
logic [3:0]  s_axi_spi_arqos;
logic        s_axi_spi_arvalid;
logic        s_axi_spi_arready;
logic [31:0] s_axi_spi_rdata;
logic [1:0]  s_axi_spi_rresp;
logic        s_axi_spi_rlast;
logic        s_axi_spi_rvalid;
logic        s_axi_spi_rready;

xlnx_axi_dwidth_converter i_xlnx_axi_dwidth_converter_spi (
  .s_axi_aclk     ( clk   ),
  .s_axi_aresetn  ( rst_n ),

  .s_axi_awid     ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_SPI].aw_id         ),
  .s_axi_awaddr   ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_SPI].aw_addr[31:0] ),
  .s_axi_awlen    ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_SPI].aw_len        ),
  .s_axi_awsize   ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_SPI].aw_size       ),
  .s_axi_awburst  ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_SPI].aw_burst      ),
  .s_axi_awlock   ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_SPI].aw_lock       ),
  .s_axi_awcache  ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_SPI].aw_cache      ),
  .s_axi_awprot   ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_SPI].aw_prot       ),
  .s_axi_awregion ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_SPI].aw_region     ),
  .s_axi_awqos    ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_SPI].aw_qos        ),
  .s_axi_awvalid  ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_SPI].aw_valid      ),
  .s_axi_awready  ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_SPI].aw_ready      ),
  .s_axi_wdata    ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_SPI].w_data        ),
  .s_axi_wstrb    ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_SPI].w_strb        ),
  .s_axi_wlast    ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_SPI].w_last        ),
  .s_axi_wvalid   ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_SPI].w_valid       ),
  .s_axi_wready   ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_SPI].w_ready       ),
  .s_axi_bid      ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_SPI].b_id          ),
  .s_axi_bresp    ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_SPI].b_resp        ),
  .s_axi_bvalid   ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_SPI].b_valid       ),
  .s_axi_bready   ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_SPI].b_ready       ),
  .s_axi_arid     ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_SPI].ar_id         ),
  .s_axi_araddr   ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_SPI].ar_addr[31:0] ),
  .s_axi_arlen    ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_SPI].ar_len        ),
  .s_axi_arsize   ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_SPI].ar_size       ),
  .s_axi_arburst  ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_SPI].ar_burst      ),
  .s_axi_arlock   ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_SPI].ar_lock       ),
  .s_axi_arcache  ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_SPI].ar_cache      ),
  .s_axi_arprot   ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_SPI].ar_prot       ),
  .s_axi_arregion ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_SPI].ar_region     ),
  .s_axi_arqos    ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_SPI].ar_qos        ),
  .s_axi_arvalid  ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_SPI].ar_valid      ),
  .s_axi_arready  ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_SPI].ar_ready      ),
  .s_axi_rid      ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_SPI].r_id          ),
  .s_axi_rdata    ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_SPI].r_data        ),
  .s_axi_rresp    ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_SPI].r_resp        ),
  .s_axi_rlast    ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_SPI].r_last        ),
  .s_axi_rvalid   ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_SPI].r_valid       ),
  .s_axi_rready   ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_SPI].r_ready       ),

  .m_axi_awaddr   ( s_axi_spi_awaddr   ),
  .m_axi_awlen    ( s_axi_spi_awlen    ),
  .m_axi_awsize   ( s_axi_spi_awsize   ),
  .m_axi_awburst  ( s_axi_spi_awburst  ),
  .m_axi_awlock   ( s_axi_spi_awlock   ),
  .m_axi_awcache  ( s_axi_spi_awcache  ),
  .m_axi_awprot   ( s_axi_spi_awprot   ),
  .m_axi_awregion ( s_axi_spi_awregion ),
  .m_axi_awqos    ( s_axi_spi_awqos    ),
  .m_axi_awvalid  ( s_axi_spi_awvalid  ),
  .m_axi_awready  ( s_axi_spi_awready  ),
  .m_axi_wdata    ( s_axi_spi_wdata    ),
  .m_axi_wstrb    ( s_axi_spi_wstrb    ),
  .m_axi_wlast    ( s_axi_spi_wlast    ),
  .m_axi_wvalid   ( s_axi_spi_wvalid   ),
  .m_axi_wready   ( s_axi_spi_wready   ),
  .m_axi_bresp    ( s_axi_spi_bresp    ),
  .m_axi_bvalid   ( s_axi_spi_bvalid   ),
  .m_axi_bready   ( s_axi_spi_bready   ),
  .m_axi_araddr   ( s_axi_spi_araddr   ),
  .m_axi_arlen    ( s_axi_spi_arlen    ),
  .m_axi_arsize   ( s_axi_spi_arsize   ),
  .m_axi_arburst  ( s_axi_spi_arburst  ),
  .m_axi_arlock   ( s_axi_spi_arlock   ),
  .m_axi_arcache  ( s_axi_spi_arcache  ),
  .m_axi_arprot   ( s_axi_spi_arprot   ),
  .m_axi_arregion ( s_axi_spi_arregion ),
  .m_axi_arqos    ( s_axi_spi_arqos    ),
  .m_axi_arvalid  ( s_axi_spi_arvalid  ),
  .m_axi_arready  ( s_axi_spi_arready  ),
  .m_axi_rdata    ( s_axi_spi_rdata    ),
  .m_axi_rresp    ( s_axi_spi_rresp    ),
  .m_axi_rlast    ( s_axi_spi_rlast    ),
  .m_axi_rvalid   ( s_axi_spi_rvalid   ),
  .m_axi_rready   ( s_axi_spi_rready   )
);

xlnx_axi_quad_spi i_xlnx_axi_quad_spi (
  .ext_spi_clk    ( clk                    ),
  .s_axi4_aclk    ( clk                    ),
  .s_axi4_aresetn ( rst_n                  ),
  .s_axi4_awaddr  ( s_axi_spi_awaddr[23:0] ),
  .s_axi4_awlen   ( s_axi_spi_awlen        ),
  .s_axi4_awsize  ( s_axi_spi_awsize       ),
  .s_axi4_awburst ( s_axi_spi_awburst      ),
  .s_axi4_awlock  ( s_axi_spi_awlock       ),
  .s_axi4_awcache ( s_axi_spi_awcache      ),
  .s_axi4_awprot  ( s_axi_spi_awprot       ),
  .s_axi4_awvalid ( s_axi_spi_awvalid      ),
  .s_axi4_awready ( s_axi_spi_awready      ),
  .s_axi4_wdata   ( s_axi_spi_wdata        ),
  .s_axi4_wstrb   ( s_axi_spi_wstrb        ),
  .s_axi4_wlast   ( s_axi_spi_wlast        ),
  .s_axi4_wvalid  ( s_axi_spi_wvalid       ),
  .s_axi4_wready  ( s_axi_spi_wready       ),
  .s_axi4_bresp   ( s_axi_spi_bresp        ),
  .s_axi4_bvalid  ( s_axi_spi_bvalid       ),
  .s_axi4_bready  ( s_axi_spi_bready       ),
  .s_axi4_araddr  ( s_axi_spi_araddr[23:0] ),
  .s_axi4_arlen   ( s_axi_spi_arlen        ),
  .s_axi4_arsize  ( s_axi_spi_arsize       ),
  .s_axi4_arburst ( s_axi_spi_arburst      ),
  .s_axi4_arlock  ( s_axi_spi_arlock       ),
  .s_axi4_arcache ( s_axi_spi_arcache      ),
  .s_axi4_arprot  ( s_axi_spi_arprot       ),
  .s_axi4_arvalid ( s_axi_spi_arvalid      ),
  .s_axi4_arready ( s_axi_spi_arready      ),
  .s_axi4_rdata   ( s_axi_spi_rdata        ),
  .s_axi4_rresp   ( s_axi_spi_rresp        ),
  .s_axi4_rlast   ( s_axi_spi_rlast        ),
  .s_axi4_rvalid  ( s_axi_spi_rvalid       ),
  .s_axi4_rready  ( s_axi_spi_rready       ),
  .io0_i          ( '0                     ),
  .io0_o          ( spi_mosi               ),
  .io0_t          (                        ),
  .io1_i          ( spi_miso               ),
  .io1_o          (                        ),
  .io1_t          (                        ),
  .ss_i           ( '0                     ),
  .ss_o           ( spi_ss                 ),
  .ss_t           (                        ),
  .sck_o          ( spi_clk_o              ),
  .sck_i          ( '0                     ),
  .sck_t          (                        ),
  .ip2intc_irpt   ( irq_sources[1]         )
);

// ---------------
// Ethernet
// ---------------

logic                        clk_200_int, clk_rgmii, clk_rgmii_quad;
logic                        eth_en, eth_we, eth_int_n, eth_pme_n, eth_mdio_i,
                             eth_mdio_o, eth_mdio_oe;
logic [AXI_ADDR_WIDTH-1:0]   eth_addr;
logic [AXI_DATA_WIDTH-1:0]   eth_wrdata, eth_rdata;
logic [AXI_DATA_WIDTH/8-1:0] eth_be;

axi2mem #(
  .AXI_ID_WIDTH   ( AXI_ID_WIDTH_SLAVE   ),
  .AXI_ADDR_WIDTH ( AXI_ADDR_WIDTH       ),
  .AXI_DATA_WIDTH ( AXI_DATA_WIDTH       ),
  .AXI_USER_WIDTH ( AXI_USER_WIDTH       )
) i_axi2rom (
  .clk_i  ( clk         ),
  .rst_ni ( rst_n       ),
  .slave  ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_ETHERNET] ),
  .req_o  ( eth_en      ),
  .we_o   ( eth_we      ),
  .addr_o ( eth_addr    ),
  .be_o   ( eth_be      ),
  .data_o ( eth_wrdata  ),
  .data_i ( eth_rdata   )
);

framing_top eth_rgmii (
  .msoc_clk(clk ),
  .core_lsu_addr(eth_addr[14:0]),
  .core_lsu_wdata(eth_wrdata),
  .core_lsu_be(eth_be),
  .ce_d(eth_en),
  .we_d(eth_en & eth_we),
  .framing_sel(eth_en),
  .framing_rdata(eth_rdata),
  .rst_int(!rst_n),
  .clk_int(phy_tx_clk), // 125 MHz in-phase
  .clk90_int(eth_clk),    // 125 MHz quadrature
  .clk_200_int(ddr_clock_out),
  
   // Ethernet: 1000BASE-T RGMII
   
  .phy_rx_clk(eth_rxck),
  .phy_rxd(eth_rxd),
  .phy_rx_ctl(eth_rxctl),
  .phy_tx_clk(eth_txck),
  .phy_txd(eth_txd),
  .phy_tx_ctl(eth_txctl),
  .phy_reset_n(eth_rst_n),
  .phy_int_n(eth_int_n),
  .phy_pme_n(eth_pme_n),
  .phy_mdc(eth_mdc),
  .phy_mdio_i(eth_mdio_i),
  .phy_mdio_o(eth_mdio_o),
  .phy_mdio_oe(eth_mdio_oe),
  .eth_irq(irq_sources[2])
);

IOBUF #(
  .DRIVE(12), // Specify the output drive strength
  .IBUF_LOW_PWR("TRUE"),  // Low Power - "TRUE", High Performance = "FALSE"
  .IOSTANDARD("DEFAULT"), // Specify the I/O standard
  .SLEW("SLOW") // Specify the output slew rate
) IOBUF_inst (
  .O(eth_mdio_i),     // Buffer output
  .IO(eth_mdio),   // Buffer inout port (connect directly to top-level port)
  .I(eth_mdio_o),     // Buffer input
  .T(~eth_mdio_oe)      // 3-state enable input, high=input, low=output
);


  // ---------------
  // ROM c 0
  // ---------------
  logic                         rom_req;
  logic [AXI_ADDR_WIDTH-1:0] rom_addr;
  logic [AXI_DATA_WIDTH-1:0]    rom_rdata;
  axi2mem #(
    .AXI_ID_WIDTH   ( AXI_ID_WIDTH_SLAVE   ),
    .AXI_ADDR_WIDTH ( AXI_ADDR_WIDTH       ),
    .AXI_DATA_WIDTH ( AXI_DATA_WIDTH       ),
    .AXI_USER_WIDTH ( AXI_USER_WIDTH       )
  ) i_axi2rom_bootrom (
    .clk_i  ( clk         ),
    .rst_ni ( rst_n       ),
    .slave  ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_ROM_0] ),
    .req_o  ( rom_req      ),
    .we_o   (              ),
    .addr_o ( rom_addr     ),
    .be_o   (              ),
    .user_o (              ),
    .data_o (              ),
    .user_i ( '0           ),
    .data_i ( rom_rdata    )
  );

  bootrom i_bootrom (
    .clk_i      ( clk     ),
    .req_i      ( rom_req   ),
    .addr_i     ( rom_addr  ),
    .rdata_o    ( rom_rdata )
  );

  // ---------------
  // ROM c 1
  // ---------------
  logic                         rom_c1_req;
  logic [AXI_ADDR_WIDTH-1:0] rom_c1_addr;
  logic [AXI_DATA_WIDTH-1:0]    rom_c1_rdata;
  axi2mem #(
    .AXI_ID_WIDTH   ( AXI_ID_WIDTH_SLAVE   ),
    .AXI_ADDR_WIDTH ( AXI_ADDR_WIDTH       ),
    .AXI_DATA_WIDTH ( AXI_DATA_WIDTH       ),
    .AXI_USER_WIDTH ( AXI_USER_WIDTH       )
  ) i_axi2rom_bootrom_c1 (
    .clk_i  ( clk         ),
    .rst_ni ( rst_n       ),
    .slave  ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_ROM_1] ),
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
    .clk_i      ( clk     ),
    .req_i      ( rom_c1_req   ),
    .addr_i     ( rom_c1_addr  ),
    .rdata_o    ( rom_c1_rdata )
  );

// ---------------
// GPIO
// ---------------
// assign gpio.b_user = 1'b0;
// assign gpio.r_user = 1'b0;
assign master[dcls_soc_pkg::SYSTEM_BUS_MASTER_GPIO].b_user = 1'b0;
assign master[dcls_soc_pkg::SYSTEM_BUS_MASTER_GPIO].r_user = 1'b0;

logic [31:0] s_axi_gpio_awaddr;
logic [7:0]  s_axi_gpio_awlen;
logic [2:0]  s_axi_gpio_awsize;
logic [1:0]  s_axi_gpio_awburst;
logic [3:0]  s_axi_gpio_awcache;
logic        s_axi_gpio_awvalid;
logic        s_axi_gpio_awready;
logic [31:0] s_axi_gpio_wdata;
logic [3:0]  s_axi_gpio_wstrb;
logic        s_axi_gpio_wvalid;
logic        s_axi_gpio_wready;
logic [1:0]  s_axi_gpio_bresp;
logic        s_axi_gpio_bvalid;
logic        s_axi_gpio_bready;
logic [31:0] s_axi_gpio_araddr;
logic [7:0]  s_axi_gpio_arlen;
logic [2:0]  s_axi_gpio_arsize;
logic [1:0]  s_axi_gpio_arburst;
logic [3:0]  s_axi_gpio_arcache;
logic        s_axi_gpio_arvalid;
logic        s_axi_gpio_arready;
logic [31:0] s_axi_gpio_rdata;
logic [1:0]  s_axi_gpio_rresp;
logic        s_axi_gpio_rlast;
logic        s_axi_gpio_rvalid;
logic        s_axi_gpio_rready;

// system-bus is 64-bit, convert down to 32 bit
xlnx_axi_dwidth_converter i_xlnx_axi_dwidth_converter_gpio (
  .s_axi_aclk     ( clk   ),
  .s_axi_aresetn  ( rst_n ),
  .s_axi_awid     ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_GPIO].aw_id        ),
  .s_axi_awaddr   ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_GPIO].aw_addr[31:0] ),
  .s_axi_awlen    ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_GPIO].aw_len       ),
  .s_axi_awsize   ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_GPIO].aw_size      ),
  .s_axi_awburst  ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_GPIO].aw_burst     ),
  .s_axi_awlock   ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_GPIO].aw_lock      ),
  .s_axi_awcache  ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_GPIO].aw_cache     ),
  .s_axi_awprot   ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_GPIO].aw_prot      ),
  .s_axi_awregion ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_GPIO].aw_region    ),
  .s_axi_awqos    ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_GPIO].aw_qos       ),
  .s_axi_awvalid  ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_GPIO].aw_valid     ),
  .s_axi_awready  ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_GPIO].aw_ready     ),
  .s_axi_wdata    ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_GPIO].w_data       ),
  .s_axi_wstrb    ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_GPIO].w_strb       ),
  .s_axi_wlast    ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_GPIO].w_last       ),
  .s_axi_wvalid   ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_GPIO].w_valid      ),
  .s_axi_wready   ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_GPIO].w_ready      ),
  .s_axi_bid      ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_GPIO].b_id         ),
  .s_axi_bresp    ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_GPIO].b_resp       ),
  .s_axi_bvalid   ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_GPIO].b_valid      ),
  .s_axi_bready   ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_GPIO].b_ready      ),
  .s_axi_arid     ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_GPIO].ar_id        ),
  .s_axi_araddr   (
      master[dcls_soc_pkg::SYSTEM_BUS_MASTER_GPIO].ar_addr[31:0]              ),
  .s_axi_arlen    ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_GPIO].ar_len       ),
  .s_axi_arsize   ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_GPIO].ar_size      ),
  .s_axi_arburst  ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_GPIO].ar_burst     ),
  .s_axi_arlock   ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_GPIO].ar_lock      ),
  .s_axi_arcache  ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_GPIO].ar_cache     ),
  .s_axi_arprot   ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_GPIO].ar_prot      ),
  .s_axi_arregion ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_GPIO].ar_region    ),
  .s_axi_arqos    ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_GPIO].ar_qos       ),
  .s_axi_arvalid  ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_GPIO].ar_valid     ),
  .s_axi_arready  ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_GPIO].ar_ready     ),
  .s_axi_rid      ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_GPIO].r_id         ),
  .s_axi_rdata    ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_GPIO].r_data       ),
  .s_axi_rresp    ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_GPIO].r_resp       ),
  .s_axi_rlast    ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_GPIO].r_last       ),
  .s_axi_rvalid   ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_GPIO].r_valid      ),
  .s_axi_rready   ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_GPIO].r_ready      ),

  .m_axi_awaddr   ( s_axi_gpio_awaddr  ),
  .m_axi_awlen    ( s_axi_gpio_awlen   ),
  .m_axi_awsize   ( s_axi_gpio_awsize  ),
  .m_axi_awburst  ( s_axi_gpio_awburst ),
  .m_axi_awlock   (                    ),
  .m_axi_awcache  ( s_axi_gpio_awcache ),
  .m_axi_awprot   (                    ),
  .m_axi_awregion (                    ),
  .m_axi_awqos    (                    ),
  .m_axi_awvalid  ( s_axi_gpio_awvalid ),
  .m_axi_awready  ( s_axi_gpio_awready ),
  .m_axi_wdata    ( s_axi_gpio_wdata   ),
  .m_axi_wstrb    ( s_axi_gpio_wstrb   ),
  .m_axi_wlast    (                    ),
  .m_axi_wvalid   ( s_axi_gpio_wvalid  ),
  .m_axi_wready   ( s_axi_gpio_wready  ),
  .m_axi_bresp    ( s_axi_gpio_bresp   ),
  .m_axi_bvalid   ( s_axi_gpio_bvalid  ),
  .m_axi_bready   ( s_axi_gpio_bready  ),
  .m_axi_araddr   ( s_axi_gpio_araddr  ),
  .m_axi_arlen    ( s_axi_gpio_arlen   ),
  .m_axi_arsize   ( s_axi_gpio_arsize  ),
  .m_axi_arburst  ( s_axi_gpio_arburst ),
  .m_axi_arlock   (                    ),
  .m_axi_arcache  ( s_axi_gpio_arcache ),
  .m_axi_arprot   (                    ),
  .m_axi_arregion (                    ),
  .m_axi_arqos    (                    ),
  .m_axi_arvalid  ( s_axi_gpio_arvalid ),
  .m_axi_arready  ( s_axi_gpio_arready ),
  .m_axi_rdata    ( s_axi_gpio_rdata   ),
  .m_axi_rresp    ( s_axi_gpio_rresp   ),
  .m_axi_rlast    ( s_axi_gpio_rlast   ),
  .m_axi_rvalid   ( s_axi_gpio_rvalid  ),
  .m_axi_rready   ( s_axi_gpio_rready  )
);

xlnx_axi_gpio i_xlnx_axi_gpio (
  .s_axi_aclk    ( clk                    ),
  .s_axi_aresetn ( rst_n                  ),
  .s_axi_awaddr  ( s_axi_gpio_awaddr[8:0] ),
  .s_axi_awvalid ( s_axi_gpio_awvalid     ),
  .s_axi_awready ( s_axi_gpio_awready     ),
  .s_axi_wdata   ( s_axi_gpio_wdata       ),
  .s_axi_wstrb   ( s_axi_gpio_wstrb       ),
  .s_axi_wvalid  ( s_axi_gpio_wvalid      ),
  .s_axi_wready  ( s_axi_gpio_wready      ),
  .s_axi_bresp   ( s_axi_gpio_bresp       ),
  .s_axi_bvalid  ( s_axi_gpio_bvalid      ),
  .s_axi_bready  ( s_axi_gpio_bready      ),
  .s_axi_araddr  ( s_axi_gpio_araddr[8:0] ),
  .s_axi_arvalid ( s_axi_gpio_arvalid     ),
  .s_axi_arready ( s_axi_gpio_arready     ),
  .s_axi_rdata   ( s_axi_gpio_rdata       ),
  .s_axi_rresp   ( s_axi_gpio_rresp       ),
  .s_axi_rvalid  ( s_axi_gpio_rvalid      ),
  .s_axi_rready  ( s_axi_gpio_rready      ),
  .gpio_io_i     ( '0                     ),
`ifdef KC705
  .gpio_io_o     ( {led[3:2*NUM_DCLS], dcls_led[2*NUM_DCLS-1:0], unused_led[7:4]} ),
`else
  .gpio_io_o     ( {led[7:2*NUM_DCLS], dcls_led[2*NUM_DCLS-1:0]} ),
`endif
  .gpio_io_t     (                        ),
`ifdef KC705
  .gpio2_io_i    ( {sw, unused_switches} )
`else
  .gpio2_io_i    ( sw         )
`endif
);

assign s_axi_gpio_rlast = 1'b1;

// ---------------------
// Board peripherals
// ---------------------
// ---------------
// DDR
// ---------------
logic [AXI_ID_WIDTH_SLAVE-1:0] s_axi_awid;
logic [AXI_ADDR_WIDTH-1:0]     s_axi_awaddr;
logic [7:0]                    s_axi_awlen;
logic [2:0]                    s_axi_awsize;
logic [1:0]                    s_axi_awburst;
logic [0:0]                    s_axi_awlock;
logic [3:0]                    s_axi_awcache;
logic [2:0]                    s_axi_awprot;
logic [3:0]                    s_axi_awregion;
logic [3:0]                    s_axi_awqos;
logic                          s_axi_awvalid;
logic                          s_axi_awready;
logic [AXI_DATA_WIDTH-1:0]     s_axi_wdata;
logic [AXI_DATA_WIDTH/8-1:0]   s_axi_wstrb;
logic                          s_axi_wlast;
logic                          s_axi_wvalid;
logic                          s_axi_wready;
logic [AXI_ID_WIDTH_SLAVE-1:0] s_axi_bid;
logic [1:0]                    s_axi_bresp;
logic                          s_axi_bvalid;
logic                          s_axi_bready;
logic [AXI_ID_WIDTH_SLAVE-1:0] s_axi_arid;
logic [AXI_ADDR_WIDTH-1:0]     s_axi_araddr;
logic [7:0]                    s_axi_arlen;
logic [2:0]                    s_axi_arsize;
logic [1:0]                    s_axi_arburst;
logic [0:0]                    s_axi_arlock;
logic [3:0]                    s_axi_arcache;
logic [2:0]                    s_axi_arprot;
logic [3:0]                    s_axi_arregion;
logic [3:0]                    s_axi_arqos;
logic                          s_axi_arvalid;
logic                          s_axi_arready;
logic [AXI_ID_WIDTH_SLAVE-1:0] s_axi_rid;
logic [AXI_DATA_WIDTH-1:0]     s_axi_rdata;
logic [1:0]                    s_axi_rresp;
logic                          s_axi_rlast;
logic                          s_axi_rvalid;
logic                          s_axi_rready;

AXI_BUS #(
    .AXI_ADDR_WIDTH ( AXI_ADDR_WIDTH     ),
    .AXI_DATA_WIDTH ( AXI_DATA_WIDTH     ),
    .AXI_ID_WIDTH   ( AXI_ID_WIDTH_SLAVE ),
    .AXI_USER_WIDTH ( AXI_USER_WIDTH     )
) dram();

axi_riscv_atomics_wrap #(
    .AXI_ADDR_WIDTH     ( AXI_ADDR_WIDTH     ),
    .AXI_DATA_WIDTH     ( AXI_DATA_WIDTH     ),
    .AXI_ID_WIDTH       ( AXI_ID_WIDTH_SLAVE ),
    .AXI_USER_WIDTH     ( AXI_USER_WIDTH     ),
    .AXI_MAX_WRITE_TXNS ( 1                  ),
    .RISCV_WORD_WIDTH   ( 64                 )
) i_axi_riscv_atomics (
    .clk_i  ( clk                      ),
    .rst_ni ( ndmreset_n               ),
    .slv    ( master[dcls_soc_pkg::SYSTEM_BUS_MASTER_DRAM] ),
    .mst    ( dram                     )
);

`ifdef PROTOCOL_CHECKER
logic pc_status;

xlnx_protocol_checker i_xlnx_protocol_checker (
  .pc_status(),
  .pc_asserted(pc_status),
  .aclk(clk),
  .aresetn(ndmreset_n),
  .pc_axi_awid     (dram.aw_id),
  .pc_axi_awaddr   (dram.aw_addr),
  .pc_axi_awlen    (dram.aw_len),
  .pc_axi_awsize   (dram.aw_size),
  .pc_axi_awburst  (dram.aw_burst),
  .pc_axi_awlock   (dram.aw_lock),
  .pc_axi_awcache  (dram.aw_cache),
  .pc_axi_awprot   (dram.aw_prot),
  .pc_axi_awqos    (dram.aw_qos),
  .pc_axi_awregion (dram.aw_region),
  .pc_axi_awuser   (dram.aw_user),
  .pc_axi_awvalid  (dram.aw_valid),
  .pc_axi_awready  (dram.aw_ready),
  .pc_axi_wlast    (dram.w_last),
  .pc_axi_wdata    (dram.w_data),
  .pc_axi_wstrb    (dram.w_strb),
  .pc_axi_wuser    (dram.w_user),
  .pc_axi_wvalid   (dram.w_valid),
  .pc_axi_wready   (dram.w_ready),
  .pc_axi_bid      (dram.b_id),
  .pc_axi_bresp    (dram.b_resp),
  .pc_axi_buser    (dram.b_user),
  .pc_axi_bvalid   (dram.b_valid),
  .pc_axi_bready   (dram.b_ready),
  .pc_axi_arid     (dram.ar_id),
  .pc_axi_araddr   (dram.ar_addr),
  .pc_axi_arlen    (dram.ar_len),
  .pc_axi_arsize   (dram.ar_size),
  .pc_axi_arburst  (dram.ar_burst),
  .pc_axi_arlock   (dram.ar_lock),
  .pc_axi_arcache  (dram.ar_cache),
  .pc_axi_arprot   (dram.ar_prot),
  .pc_axi_arqos    (dram.ar_qos),
  .pc_axi_arregion (dram.ar_region),
  .pc_axi_aruser   (dram.ar_user),
  .pc_axi_arvalid  (dram.ar_valid),
  .pc_axi_arready  (dram.ar_ready),
  .pc_axi_rid      (dram.r_id),
  .pc_axi_rlast    (dram.r_last),
  .pc_axi_rdata    (dram.r_data),
  .pc_axi_rresp    (dram.r_resp),
  .pc_axi_ruser    (dram.r_user),
  .pc_axi_rvalid   (dram.r_valid),
  .pc_axi_rready   (dram.r_ready)
);
`endif

assign dram.r_user = '0;
assign dram.b_user = '0;

xlnx_axi_clock_converter i_xlnx_axi_clock_converter_ddr (
  .s_axi_aclk     ( clk              ),
  .s_axi_aresetn  ( ndmreset_n       ),
  .s_axi_awid     ( dram.aw_id       ),
  .s_axi_awaddr   ( dram.aw_addr     ),
  .s_axi_awlen    ( dram.aw_len      ),
  .s_axi_awsize   ( dram.aw_size     ),
  .s_axi_awburst  ( dram.aw_burst    ),
  .s_axi_awlock   ( dram.aw_lock     ),
  .s_axi_awcache  ( dram.aw_cache    ),
  .s_axi_awprot   ( dram.aw_prot     ),
  .s_axi_awregion ( dram.aw_region   ),
  .s_axi_awqos    ( dram.aw_qos      ),
  .s_axi_awvalid  ( dram.aw_valid    ),
  .s_axi_awready  ( dram.aw_ready    ),
  .s_axi_wdata    ( dram.w_data      ),
  .s_axi_wstrb    ( dram.w_strb      ),
  .s_axi_wlast    ( dram.w_last      ),
  .s_axi_wvalid   ( dram.w_valid     ),
  .s_axi_wready   ( dram.w_ready     ),
  .s_axi_bid      ( dram.b_id        ),
  .s_axi_bresp    ( dram.b_resp      ),
  .s_axi_bvalid   ( dram.b_valid     ),
  .s_axi_bready   ( dram.b_ready     ),
  .s_axi_arid     ( dram.ar_id       ),
  .s_axi_araddr   ( dram.ar_addr     ),
  .s_axi_arlen    ( dram.ar_len      ),
  .s_axi_arsize   ( dram.ar_size     ),
  .s_axi_arburst  ( dram.ar_burst    ),
  .s_axi_arlock   ( dram.ar_lock     ),
  .s_axi_arcache  ( dram.ar_cache    ),
  .s_axi_arprot   ( dram.ar_prot     ),
  .s_axi_arregion ( dram.ar_region   ),
  .s_axi_arqos    ( dram.ar_qos      ),
  .s_axi_arvalid  ( dram.ar_valid    ),
  .s_axi_arready  ( dram.ar_ready    ),
  .s_axi_rid      ( dram.r_id        ),
  .s_axi_rdata    ( dram.r_data      ),
  .s_axi_rresp    ( dram.r_resp      ),
  .s_axi_rlast    ( dram.r_last      ),
  .s_axi_rvalid   ( dram.r_valid     ),
  .s_axi_rready   ( dram.r_ready     ),
  // to size converter
  .m_axi_aclk     ( ddr_clock_out    ),
  .m_axi_aresetn  ( ndmreset_n       ),
  .m_axi_awid     ( s_axi_awid       ),
  .m_axi_awaddr   ( s_axi_awaddr     ),
  .m_axi_awlen    ( s_axi_awlen      ),
  .m_axi_awsize   ( s_axi_awsize     ),
  .m_axi_awburst  ( s_axi_awburst    ),
  .m_axi_awlock   ( s_axi_awlock     ),
  .m_axi_awcache  ( s_axi_awcache    ),
  .m_axi_awprot   ( s_axi_awprot     ),
  .m_axi_awregion ( s_axi_awregion   ),
  .m_axi_awqos    ( s_axi_awqos      ),
  .m_axi_awvalid  ( s_axi_awvalid    ),
  .m_axi_awready  ( s_axi_awready    ),
  .m_axi_wdata    ( s_axi_wdata      ),
  .m_axi_wstrb    ( s_axi_wstrb      ),
  .m_axi_wlast    ( s_axi_wlast      ),
  .m_axi_wvalid   ( s_axi_wvalid     ),
  .m_axi_wready   ( s_axi_wready     ),
  .m_axi_bid      ( s_axi_bid        ),
  .m_axi_bresp    ( s_axi_bresp      ),
  .m_axi_bvalid   ( s_axi_bvalid     ),
  .m_axi_bready   ( s_axi_bready     ),
  .m_axi_arid     ( s_axi_arid       ),
  .m_axi_araddr   ( s_axi_araddr     ),
  .m_axi_arlen    ( s_axi_arlen      ),
  .m_axi_arsize   ( s_axi_arsize     ),
  .m_axi_arburst  ( s_axi_arburst    ),
  .m_axi_arlock   ( s_axi_arlock     ),
  .m_axi_arcache  ( s_axi_arcache    ),
  .m_axi_arprot   ( s_axi_arprot     ),
  .m_axi_arregion ( s_axi_arregion   ),
  .m_axi_arqos    ( s_axi_arqos      ),
  .m_axi_arvalid  ( s_axi_arvalid    ),
  .m_axi_arready  ( s_axi_arready    ),
  .m_axi_rid      ( s_axi_rid        ),
  .m_axi_rdata    ( s_axi_rdata      ),
  .m_axi_rresp    ( s_axi_rresp      ),
  .m_axi_rlast    ( s_axi_rlast      ),
  .m_axi_rvalid   ( s_axi_rvalid     ),
  .m_axi_rready   ( s_axi_rready     )
);

xlnx_clk_gen i_xlnx_clk_gen (
  .clk_out1 ( clk           ), // 50 MHz
  .clk_out2 ( phy_tx_clk    ), // 125 MHz (for RGMII PHY)
  .clk_out3 ( eth_clk       ), // 125 MHz quadrature (90 deg phase shift)
  .clk_out4 ( sd_clk_sys    ), // 50 MHz clock
  .reset    ( cpu_reset     ),
  .locked   ( pll_locked    ),
  .clk_in1  ( ddr_clock_out )
);

`ifdef KINTEX7
fan_ctrl i_fan_ctrl (
    .clk_i         ( clk        ),
    .rst_ni        ( ndmreset_n ),
    .pwm_setting_i ( '1         ),
    .fan_pwm_o     ( fan_pwm    )
);

xlnx_mig_7_ddr3 i_ddr (
    .sys_clk_p,
    .sys_clk_n,
    .ddr3_dq,
    .ddr3_dqs_n,
    .ddr3_dqs_p,
    .ddr3_addr,
    .ddr3_ba,
    .ddr3_ras_n,
    .ddr3_cas_n,
    .ddr3_we_n,
    .ddr3_reset_n,
    .ddr3_ck_p,
    .ddr3_ck_n,
    .ddr3_cke,
    .ddr3_cs_n,
    .ddr3_dm,
    .ddr3_odt,
    .mmcm_locked     (                ), // keep open
    .app_sr_req      ( '0             ),
    .app_ref_req     ( '0             ),
    .app_zq_req      ( '0             ),
    .app_sr_active   (                ), // keep open
    .app_ref_ack     (                ), // keep open
    .app_zq_ack      (                ), // keep open
    .ui_clk          ( ddr_clock_out  ),
    .ui_clk_sync_rst ( ddr_sync_reset ),
    .aresetn         ( ndmreset_n     ),
    .s_axi_awid,
    .s_axi_awaddr    ( s_axi_awaddr[29:0] ),
    .s_axi_awlen,
    .s_axi_awsize,
    .s_axi_awburst,
    .s_axi_awlock,
    .s_axi_awcache,
    .s_axi_awprot,
    .s_axi_awqos,
    .s_axi_awvalid,
    .s_axi_awready,
    .s_axi_wdata,
    .s_axi_wstrb,
    .s_axi_wlast,
    .s_axi_wvalid,
    .s_axi_wready,
    .s_axi_bready,
    .s_axi_bid,
    .s_axi_bresp,
    .s_axi_bvalid,
    .s_axi_arid,
    .s_axi_araddr     ( s_axi_araddr[29:0] ),
    .s_axi_arlen,
    .s_axi_arsize,
    .s_axi_arburst,
    .s_axi_arlock,
    .s_axi_arcache,
    .s_axi_arprot,
    .s_axi_arqos,
    .s_axi_arvalid,
    .s_axi_arready,
    .s_axi_rready,
    .s_axi_rid,
    .s_axi_rdata,
    .s_axi_rresp,
    .s_axi_rlast,
    .s_axi_rvalid,
    .init_calib_complete (            ), // keep open
    .device_temp         (            ), // keep open
    .sys_rst             ( cpu_resetn )
);
`elsif VC707
fan_ctrl i_fan_ctrl (
    .clk_i         ( clk        ),
    .rst_ni        ( ndmreset_n ),
    .pwm_setting_i ( '1         ),
    .fan_pwm_o     ( fan_pwm    )
);

xlnx_mig_7_ddr3 i_ddr (
    .sys_clk_p,
    .sys_clk_n,
    .ddr3_dq,
    .ddr3_dqs_n,
    .ddr3_dqs_p,
    .ddr3_addr,
    .ddr3_ba,
    .ddr3_ras_n,
    .ddr3_cas_n,
    .ddr3_we_n,
    .ddr3_reset_n,
    .ddr3_ck_p,
    .ddr3_ck_n,
    .ddr3_cke,
    .ddr3_cs_n,
    .ddr3_dm,
    .ddr3_odt,
    .mmcm_locked     (                ), // keep open
    .app_sr_req      ( '0             ),
    .app_ref_req     ( '0             ),
    .app_zq_req      ( '0             ),
    .app_sr_active   (                ), // keep open
    .app_ref_ack     (                ), // keep open
    .app_zq_ack      (                ), // keep open
    .ui_clk          ( ddr_clock_out  ),
    .ui_clk_sync_rst ( ddr_sync_reset ),
    .aresetn         ( ndmreset_n     ),
    .s_axi_awid,
    .s_axi_awaddr    ( s_axi_awaddr[29:0] ),
    .s_axi_awlen,
    .s_axi_awsize,
    .s_axi_awburst,
    .s_axi_awlock,
    .s_axi_awcache,
    .s_axi_awprot,
    .s_axi_awqos,
    .s_axi_awvalid,
    .s_axi_awready,
    .s_axi_wdata,
    .s_axi_wstrb,
    .s_axi_wlast,
    .s_axi_wvalid,
    .s_axi_wready,
    .s_axi_bready,
    .s_axi_bid,
    .s_axi_bresp,
    .s_axi_bvalid,
    .s_axi_arid,
    .s_axi_araddr     ( s_axi_araddr[29:0] ),
    .s_axi_arlen,
    .s_axi_arsize,
    .s_axi_arburst,
    .s_axi_arlock,
    .s_axi_arcache,
    .s_axi_arprot,
    .s_axi_arqos,
    .s_axi_arvalid,
    .s_axi_arready,
    .s_axi_rready,
    .s_axi_rid,
    .s_axi_rdata,
    .s_axi_rresp,
    .s_axi_rlast,
    .s_axi_rvalid,
    .init_calib_complete (            ), // keep open
    .device_temp         (            ), // keep open
    .sys_rst             ( cpu_resetn )
);
`elsif VCU118

  logic [63:0]  dram_dwidth_axi_awaddr;
  logic [7:0]   dram_dwidth_axi_awlen;
  logic [2:0]   dram_dwidth_axi_awsize;
  logic [1:0]   dram_dwidth_axi_awburst;
  logic [0:0]   dram_dwidth_axi_awlock;
  logic [3:0]   dram_dwidth_axi_awcache;
  logic [2:0]   dram_dwidth_axi_awprot;
  logic [3:0]   dram_dwidth_axi_awqos;
  logic         dram_dwidth_axi_awvalid;
  logic         dram_dwidth_axi_awready;
  logic [511:0] dram_dwidth_axi_wdata;
  logic [63:0]  dram_dwidth_axi_wstrb;
  logic         dram_dwidth_axi_wlast;
  logic         dram_dwidth_axi_wvalid;
  logic         dram_dwidth_axi_wready;
  logic         dram_dwidth_axi_bready;
  logic [1:0]   dram_dwidth_axi_bresp;
  logic         dram_dwidth_axi_bvalid;
  logic [63:0]  dram_dwidth_axi_araddr;
  logic [7:0]   dram_dwidth_axi_arlen;
  logic [2:0]   dram_dwidth_axi_arsize;
  logic [1:0]   dram_dwidth_axi_arburst;
  logic [0:0]   dram_dwidth_axi_arlock;
  logic [3:0]   dram_dwidth_axi_arcache;
  logic [2:0]   dram_dwidth_axi_arprot;
  logic [3:0]   dram_dwidth_axi_arqos;
  logic         dram_dwidth_axi_arvalid;
  logic         dram_dwidth_axi_arready;
  logic         dram_dwidth_axi_rready;
  logic         dram_dwidth_axi_rlast;
  logic         dram_dwidth_axi_rvalid;
  logic [1:0]   dram_dwidth_axi_rresp;
  logic [511:0] dram_dwidth_axi_rdata;

axi_dwidth_converter_512_64 i_axi_dwidth_converter_512_64 (
  .s_axi_aclk     ( ddr_clock_out            ),
  .s_axi_aresetn  ( ndmreset_n               ),

  .s_axi_awid     ( s_axi_awid               ),
  .s_axi_awaddr   ( s_axi_awaddr             ),
  .s_axi_awlen    ( s_axi_awlen              ),
  .s_axi_awsize   ( s_axi_awsize             ),
  .s_axi_awburst  ( s_axi_awburst            ),
  .s_axi_awlock   ( s_axi_awlock             ),
  .s_axi_awcache  ( s_axi_awcache            ),
  .s_axi_awprot   ( s_axi_awprot             ),
  .s_axi_awregion ( '0                       ),
  .s_axi_awqos    ( s_axi_awqos              ),
  .s_axi_awvalid  ( s_axi_awvalid            ),
  .s_axi_awready  ( s_axi_awready            ),
  .s_axi_wdata    ( s_axi_wdata              ),
  .s_axi_wstrb    ( s_axi_wstrb              ),
  .s_axi_wlast    ( s_axi_wlast              ),
  .s_axi_wvalid   ( s_axi_wvalid             ),
  .s_axi_wready   ( s_axi_wready             ),
  .s_axi_bid      ( s_axi_bid                ),
  .s_axi_bresp    ( s_axi_bresp              ),
  .s_axi_bvalid   ( s_axi_bvalid             ),
  .s_axi_bready   ( s_axi_bready             ),
  .s_axi_arid     ( s_axi_arid               ),
  .s_axi_araddr   ( s_axi_araddr             ),
  .s_axi_arlen    ( s_axi_arlen              ),
  .s_axi_arsize   ( s_axi_arsize             ),
  .s_axi_arburst  ( s_axi_arburst            ),
  .s_axi_arlock   ( s_axi_arlock             ),
  .s_axi_arcache  ( s_axi_arcache            ),
  .s_axi_arprot   ( s_axi_arprot             ),
  .s_axi_arregion ( '0                       ),
  .s_axi_arqos    ( s_axi_arqos              ),
  .s_axi_arvalid  ( s_axi_arvalid            ),
  .s_axi_arready  ( s_axi_arready            ),
  .s_axi_rid      ( s_axi_rid                ),
  .s_axi_rdata    ( s_axi_rdata              ),
  .s_axi_rresp    ( s_axi_rresp              ),
  .s_axi_rlast    ( s_axi_rlast              ),
  .s_axi_rvalid   ( s_axi_rvalid             ),
  .s_axi_rready   ( s_axi_rready             ),

  .m_axi_awaddr   ( dram_dwidth_axi_awaddr   ),
  .m_axi_awlen    ( dram_dwidth_axi_awlen    ),
  .m_axi_awsize   ( dram_dwidth_axi_awsize   ),
  .m_axi_awburst  ( dram_dwidth_axi_awburst  ),
  .m_axi_awlock   ( dram_dwidth_axi_awlock   ),
  .m_axi_awcache  ( dram_dwidth_axi_awcache  ),
  .m_axi_awprot   ( dram_dwidth_axi_awprot   ),
  .m_axi_awregion (                          ), // left open
  .m_axi_awqos    ( dram_dwidth_axi_awqos    ),
  .m_axi_awvalid  ( dram_dwidth_axi_awvalid  ),
  .m_axi_awready  ( dram_dwidth_axi_awready  ),
  .m_axi_wdata    ( dram_dwidth_axi_wdata    ),
  .m_axi_wstrb    ( dram_dwidth_axi_wstrb    ),
  .m_axi_wlast    ( dram_dwidth_axi_wlast    ),
  .m_axi_wvalid   ( dram_dwidth_axi_wvalid   ),
  .m_axi_wready   ( dram_dwidth_axi_wready   ),
  .m_axi_bresp    ( dram_dwidth_axi_bresp    ),
  .m_axi_bvalid   ( dram_dwidth_axi_bvalid   ),
  .m_axi_bready   ( dram_dwidth_axi_bready   ),
  .m_axi_araddr   ( dram_dwidth_axi_araddr   ),
  .m_axi_arlen    ( dram_dwidth_axi_arlen    ),
  .m_axi_arsize   ( dram_dwidth_axi_arsize   ),
  .m_axi_arburst  ( dram_dwidth_axi_arburst  ),
  .m_axi_arlock   ( dram_dwidth_axi_arlock   ),
  .m_axi_arcache  ( dram_dwidth_axi_arcache  ),
  .m_axi_arprot   ( dram_dwidth_axi_arprot   ),
  .m_axi_arregion (                          ),
  .m_axi_arqos    ( dram_dwidth_axi_arqos    ),
  .m_axi_arvalid  ( dram_dwidth_axi_arvalid  ),
  .m_axi_arready  ( dram_dwidth_axi_arready  ),
  .m_axi_rdata    ( dram_dwidth_axi_rdata    ),
  .m_axi_rresp    ( dram_dwidth_axi_rresp    ),
  .m_axi_rlast    ( dram_dwidth_axi_rlast    ),
  .m_axi_rvalid   ( dram_dwidth_axi_rvalid   ),
  .m_axi_rready   ( dram_dwidth_axi_rready   )
);

  ddr4_0 i_ddr (
    .c0_init_calib_complete (                              ),
    .dbg_clk                (                              ),
    .c0_sys_clk_p           ( c0_sys_clk_p                 ),
    .c0_sys_clk_n           ( c0_sys_clk_n                 ),
    .dbg_bus                (                              ),
    .c0_ddr4_adr            ( c0_ddr4_adr                  ),
    .c0_ddr4_ba             ( c0_ddr4_ba                   ),
    .c0_ddr4_cke            ( c0_ddr4_cke                  ),
    .c0_ddr4_cs_n           ( c0_ddr4_cs_n                 ),
    .c0_ddr4_dm_dbi_n       ( c0_ddr4_dm_dbi_n             ),
    .c0_ddr4_dq             ( c0_ddr4_dq                   ),
    .c0_ddr4_dqs_c          ( c0_ddr4_dqs_c                ),
    .c0_ddr4_dqs_t          ( c0_ddr4_dqs_t                ),
    .c0_ddr4_odt            ( c0_ddr4_odt                  ),
    .c0_ddr4_bg             ( c0_ddr4_bg                   ),
    .c0_ddr4_reset_n        ( c0_ddr4_reset_n              ),
    .c0_ddr4_act_n          ( c0_ddr4_act_n                ),
    .c0_ddr4_ck_c           ( c0_ddr4_ck_c                 ),
    .c0_ddr4_ck_t           ( c0_ddr4_ck_t                 ),
    .c0_ddr4_ui_clk         ( ddr_clock_out                ),
    .c0_ddr4_ui_clk_sync_rst( ddr_sync_reset               ),
    .c0_ddr4_aresetn        ( ndmreset_n                   ),
    .c0_ddr4_s_axi_awid     ( '0                           ),
    .c0_ddr4_s_axi_awaddr   ( dram_dwidth_axi_awaddr[30:0] ),
    .c0_ddr4_s_axi_awlen    ( dram_dwidth_axi_awlen        ),
    .c0_ddr4_s_axi_awsize   ( dram_dwidth_axi_awsize       ),
    .c0_ddr4_s_axi_awburst  ( dram_dwidth_axi_awburst      ),
    .c0_ddr4_s_axi_awlock   ( dram_dwidth_axi_awlock       ),
    .c0_ddr4_s_axi_awcache  ( dram_dwidth_axi_awcache      ),
    .c0_ddr4_s_axi_awprot   ( dram_dwidth_axi_awprot       ),
    .c0_ddr4_s_axi_awqos    ( dram_dwidth_axi_awqos        ),
    .c0_ddr4_s_axi_awvalid  ( dram_dwidth_axi_awvalid      ),
    .c0_ddr4_s_axi_awready  ( dram_dwidth_axi_awready      ),
    .c0_ddr4_s_axi_wdata    ( dram_dwidth_axi_wdata        ),
    .c0_ddr4_s_axi_wstrb    ( dram_dwidth_axi_wstrb        ),
    .c0_ddr4_s_axi_wlast    ( dram_dwidth_axi_wlast        ),
    .c0_ddr4_s_axi_wvalid   ( dram_dwidth_axi_wvalid       ),
    .c0_ddr4_s_axi_wready   ( dram_dwidth_axi_wready       ),
    .c0_ddr4_s_axi_bready   ( dram_dwidth_axi_bready       ),
    .c0_ddr4_s_axi_bid      (                              ),
    .c0_ddr4_s_axi_bresp    ( dram_dwidth_axi_bresp        ),
    .c0_ddr4_s_axi_bvalid   ( dram_dwidth_axi_bvalid       ),
    .c0_ddr4_s_axi_arid     ( '0                           ),
    .c0_ddr4_s_axi_araddr   ( dram_dwidth_axi_araddr[30:0] ),
    .c0_ddr4_s_axi_arlen    ( dram_dwidth_axi_arlen        ),
    .c0_ddr4_s_axi_arsize   ( dram_dwidth_axi_arsize       ),
    .c0_ddr4_s_axi_arburst  ( dram_dwidth_axi_arburst      ),
    .c0_ddr4_s_axi_arlock   ( dram_dwidth_axi_arlock       ),
    .c0_ddr4_s_axi_arcache  ( dram_dwidth_axi_arcache      ),
    .c0_ddr4_s_axi_arprot   ( dram_dwidth_axi_arprot       ),
    .c0_ddr4_s_axi_arqos    ( dram_dwidth_axi_arqos        ),
    .c0_ddr4_s_axi_arvalid  ( dram_dwidth_axi_arvalid      ),
    .c0_ddr4_s_axi_arready  ( dram_dwidth_axi_arready      ),
    .c0_ddr4_s_axi_rready   ( dram_dwidth_axi_rready       ),
    .c0_ddr4_s_axi_rlast    ( dram_dwidth_axi_rlast        ),
    .c0_ddr4_s_axi_rvalid   ( dram_dwidth_axi_rvalid       ),
    .c0_ddr4_s_axi_rresp    ( dram_dwidth_axi_rresp        ),
    .c0_ddr4_s_axi_rid      (                              ),
    .c0_ddr4_s_axi_rdata    ( dram_dwidth_axi_rdata        ),
    .sys_rst                ( cpu_reset                    )
  );


  logic pcie_ref_clk;
  logic pcie_ref_clk_gt;

  logic pcie_axi_clk;
  logic pcie_axi_rstn;

  logic         pcie_axi_awready;
  logic         pcie_axi_wready;
  logic [3:0]   pcie_axi_bid;
  logic [1:0]   pcie_axi_bresp;
  logic         pcie_axi_bvalid;
  logic         pcie_axi_arready;
  logic [3:0]   pcie_axi_rid;
  logic [255:0] pcie_axi_rdata;
  logic [1:0]   pcie_axi_rresp;
  logic         pcie_axi_rlast;
  logic         pcie_axi_rvalid;
  logic [3:0]   pcie_axi_awid;
  logic [63:0]  pcie_axi_awaddr;
  logic [7:0]   pcie_axi_awlen;
  logic [2:0]   pcie_axi_awsize;
  logic [1:0]   pcie_axi_awburst;
  logic [2:0]   pcie_axi_awprot;
  logic         pcie_axi_awvalid;
  logic         pcie_axi_awlock;
  logic [3:0]   pcie_axi_awcache;
  logic [255:0] pcie_axi_wdata;
  logic [31:0]  pcie_axi_wstrb;
  logic         pcie_axi_wlast;
  logic         pcie_axi_wvalid;
  logic         pcie_axi_bready;
  logic [3:0]   pcie_axi_arid;
  logic [63:0]  pcie_axi_araddr;
  logic [7:0]   pcie_axi_arlen;
  logic [2:0]   pcie_axi_arsize;
  logic [1:0]   pcie_axi_arburst;
  logic [2:0]   pcie_axi_arprot;
  logic         pcie_axi_arvalid;
  logic         pcie_axi_arlock;
  logic [3:0]   pcie_axi_arcache;
  logic         pcie_axi_rready;

  logic [63:0]  pcie_dwidth_axi_awaddr;
  logic [7:0]   pcie_dwidth_axi_awlen;
  logic [2:0]   pcie_dwidth_axi_awsize;
  logic [1:0]   pcie_dwidth_axi_awburst;
  logic [0:0]   pcie_dwidth_axi_awlock;
  logic [3:0]   pcie_dwidth_axi_awcache;
  logic [2:0]   pcie_dwidth_axi_awprot;
  logic [3:0]   pcie_dwidth_axi_awregion;
  logic [3:0]   pcie_dwidth_axi_awqos;
  logic         pcie_dwidth_axi_awvalid;
  logic         pcie_dwidth_axi_awready;
  logic [63:0]  pcie_dwidth_axi_wdata;
  logic [7:0]   pcie_dwidth_axi_wstrb;
  logic         pcie_dwidth_axi_wlast;
  logic         pcie_dwidth_axi_wvalid;
  logic         pcie_dwidth_axi_wready;
  logic [1:0]   pcie_dwidth_axi_bresp;
  logic         pcie_dwidth_axi_bvalid;
  logic         pcie_dwidth_axi_bready;
  logic [63:0]  pcie_dwidth_axi_araddr;
  logic [7:0]   pcie_dwidth_axi_arlen;
  logic [2:0]   pcie_dwidth_axi_arsize;
  logic [1:0]   pcie_dwidth_axi_arburst;
  logic [0:0]   pcie_dwidth_axi_arlock;
  logic [3:0]   pcie_dwidth_axi_arcache;
  logic [2:0]   pcie_dwidth_axi_arprot;
  logic [3:0]   pcie_dwidth_axi_arregion;
  logic [3:0]   pcie_dwidth_axi_arqos;
  logic         pcie_dwidth_axi_arvalid;
  logic         pcie_dwidth_axi_arready;
  logic [63:0]  pcie_dwidth_axi_rdata;
  logic [1:0]   pcie_dwidth_axi_rresp;
  logic         pcie_dwidth_axi_rlast;
  logic         pcie_dwidth_axi_rvalid;
  logic         pcie_dwidth_axi_rready;

  // PCIe Reset
  logic sys_rst_n_c;
  IBUF sys_reset_n_ibuf (.O(sys_rst_n_c), .I(sys_rst_n));

  IBUFDS_GTE4 #(
    .REFCLK_HROW_CK_SEL ( 2'b00 )
  ) IBUFDS_GTE4_inst (
    .O     ( pcie_ref_clk_gt ),
    .ODIV2 ( pcie_ref_clk    ),
    .CEB   ( 1'b0            ),
    .I     ( sys_clk_p       ),
    .IB    ( sys_clk_n       )
  );

  // 250 MHz AXI
  xdma_0 i_xdma (
    .sys_clk                  ( pcie_ref_clk     ),
    .sys_clk_gt               ( pcie_ref_clk_gt  ),
    .sys_rst_n                ( sys_rst_n_c      ),
    .user_lnk_up              (                  ),

    // Tx
    .pci_exp_txp              ( pci_exp_txp      ),
    .pci_exp_txn              ( pci_exp_txn      ),
    // Rx
    .pci_exp_rxp              ( pci_exp_rxp      ),
    .pci_exp_rxn              ( pci_exp_rxn      ),
    .usr_irq_req              ( 1'b0             ),
    .usr_irq_ack              (                  ),
    .msi_enable               (                  ),
    .msi_vector_width         (                  ),
    .axi_aclk                 ( pcie_axi_clk     ),
    .axi_aresetn              ( pcie_axi_rstn    ),
    .m_axi_awready            ( pcie_axi_awready ),
    .m_axi_wready             ( pcie_axi_wready  ),
    .m_axi_bid                ( pcie_axi_bid     ),
    .m_axi_bresp              ( pcie_axi_bresp   ),
    .m_axi_bvalid             ( pcie_axi_bvalid  ),
    .m_axi_arready            ( pcie_axi_arready ),
    .m_axi_rid                ( pcie_axi_rid     ),
    .m_axi_rdata              ( pcie_axi_rdata   ),
    .m_axi_rresp              ( pcie_axi_rresp   ),
    .m_axi_rlast              ( pcie_axi_rlast   ),
    .m_axi_rvalid             ( pcie_axi_rvalid  ),
    .m_axi_awid               ( pcie_axi_awid    ),
    .m_axi_awaddr             ( pcie_axi_awaddr  ),
    .m_axi_awlen              ( pcie_axi_awlen   ),
    .m_axi_awsize             ( pcie_axi_awsize  ),
    .m_axi_awburst            ( pcie_axi_awburst ),
    .m_axi_awprot             ( pcie_axi_awprot  ),
    .m_axi_awvalid            ( pcie_axi_awvalid ),
    .m_axi_awlock             ( pcie_axi_awlock  ),
    .m_axi_awcache            ( pcie_axi_awcache ),
    .m_axi_wdata              ( pcie_axi_wdata   ),
    .m_axi_wstrb              ( pcie_axi_wstrb   ),
    .m_axi_wlast              ( pcie_axi_wlast   ),
    .m_axi_wvalid             ( pcie_axi_wvalid  ),
    .m_axi_bready             ( pcie_axi_bready  ),
    .m_axi_arid               ( pcie_axi_arid    ),
    .m_axi_araddr             ( pcie_axi_araddr  ),
    .m_axi_arlen              ( pcie_axi_arlen   ),
    .m_axi_arsize             ( pcie_axi_arsize  ),
    .m_axi_arburst            ( pcie_axi_arburst ),
    .m_axi_arprot             ( pcie_axi_arprot  ),
    .m_axi_arvalid            ( pcie_axi_arvalid ),
    .m_axi_arlock             ( pcie_axi_arlock  ),
    .m_axi_arcache            ( pcie_axi_arcache ),
    .m_axi_rready             ( pcie_axi_rready  ),

    .cfg_mgmt_addr            ( '0               ),
    .cfg_mgmt_write           ( '0               ),
    .cfg_mgmt_write_data      ( '0               ),
    .cfg_mgmt_byte_enable     ( '0               ),
    .cfg_mgmt_read            ( '0               ),
    .cfg_mgmt_read_data       (                  ),
    .cfg_mgmt_read_write_done (                  )
  );

  axi_dwidth_converter_256_64 i_axi_dwidth_converter_256_64 (
    .s_axi_aclk     ( pcie_axi_clk             ),
    .s_axi_aresetn  ( pcie_axi_rstn            ),
    .s_axi_awid     ( pcie_axi_awid            ),
    .s_axi_awaddr   ( pcie_axi_awaddr          ),
    .s_axi_awlen    ( pcie_axi_awlen           ),
    .s_axi_awsize   ( pcie_axi_awsize          ),
    .s_axi_awburst  ( pcie_axi_awburst         ),
    .s_axi_awlock   ( pcie_axi_awlock          ),
    .s_axi_awcache  ( pcie_axi_awcache         ),
    .s_axi_awprot   ( pcie_axi_awprot          ),
    .s_axi_awregion ( '0                       ),
    .s_axi_awqos    ( '0                       ),
    .s_axi_awvalid  ( pcie_axi_awvalid         ),
    .s_axi_awready  ( pcie_axi_awready         ),
    .s_axi_wdata    ( pcie_axi_wdata           ),
    .s_axi_wstrb    ( pcie_axi_wstrb           ),
    .s_axi_wlast    ( pcie_axi_wlast           ),
    .s_axi_wvalid   ( pcie_axi_wvalid          ),
    .s_axi_wready   ( pcie_axi_wready          ),
    .s_axi_bid      ( pcie_axi_bid             ),
    .s_axi_bresp    ( pcie_axi_rresp           ),
    .s_axi_bvalid   ( pcie_axi_bvalid          ),
    .s_axi_bready   ( pcie_axi_bready          ),
    .s_axi_arid     ( pcie_axi_arid            ),
    .s_axi_araddr   ( pcie_axi_araddr          ),
    .s_axi_arlen    ( pcie_axi_arlen           ),
    .s_axi_arsize   ( pcie_axi_arsize          ),
    .s_axi_arburst  ( pcie_axi_arburst         ),
    .s_axi_arlock   ( pcie_axi_arlock          ),
    .s_axi_arcache  ( pcie_axi_arcache         ),
    .s_axi_arprot   ( pcie_axi_arprot          ),
    .s_axi_arregion ( '0                       ),
    .s_axi_arqos    ( '0                       ),
    .s_axi_arvalid  ( pcie_axi_arvalid         ),
    .s_axi_arready  ( pcie_axi_arready         ),
    .s_axi_rid      ( pcie_axi_rid             ),
    .s_axi_rdata    ( pcie_axi_rdata           ),
    .s_axi_rresp    ( pcie_axi_bresp           ),
    .s_axi_rlast    ( pcie_axi_rlast           ),
    .s_axi_rvalid   ( pcie_axi_rvalid          ),
    .s_axi_rready   ( pcie_axi_rready          ),

    .m_axi_awaddr   ( pcie_dwidth_axi_awaddr   ),
    .m_axi_awlen    ( pcie_dwidth_axi_awlen    ),
    .m_axi_awsize   ( pcie_dwidth_axi_awsize   ),
    .m_axi_awburst  ( pcie_dwidth_axi_awburst  ),
    .m_axi_awlock   ( pcie_dwidth_axi_awlock   ),
    .m_axi_awcache  ( pcie_dwidth_axi_awcache  ),
    .m_axi_awprot   ( pcie_dwidth_axi_awprot   ),
    .m_axi_awregion ( pcie_dwidth_axi_awregion ),
    .m_axi_awqos    ( pcie_dwidth_axi_awqos    ),
    .m_axi_awvalid  ( pcie_dwidth_axi_awvalid  ),
    .m_axi_awready  ( pcie_dwidth_axi_awready  ),
    .m_axi_wdata    ( pcie_dwidth_axi_wdata    ),
    .m_axi_wstrb    ( pcie_dwidth_axi_wstrb    ),
    .m_axi_wlast    ( pcie_dwidth_axi_wlast    ),
    .m_axi_wvalid   ( pcie_dwidth_axi_wvalid   ),
    .m_axi_wready   ( pcie_dwidth_axi_wready   ),
    .m_axi_bresp    ( pcie_dwidth_axi_bresp    ),
    .m_axi_bvalid   ( pcie_dwidth_axi_bvalid   ),
    .m_axi_bready   ( pcie_dwidth_axi_bready   ),
    .m_axi_araddr   ( pcie_dwidth_axi_araddr   ),
    .m_axi_arlen    ( pcie_dwidth_axi_arlen    ),
    .m_axi_arsize   ( pcie_dwidth_axi_arsize   ),
    .m_axi_arburst  ( pcie_dwidth_axi_arburst  ),
    .m_axi_arlock   ( pcie_dwidth_axi_arlock   ),
    .m_axi_arcache  ( pcie_dwidth_axi_arcache  ),
    .m_axi_arprot   ( pcie_dwidth_axi_arprot   ),
    .m_axi_arregion ( pcie_dwidth_axi_arregion ),
    .m_axi_arqos    ( pcie_dwidth_axi_arqos    ),
    .m_axi_arvalid  ( pcie_dwidth_axi_arvalid  ),
    .m_axi_arready  ( pcie_dwidth_axi_arready  ),
    .m_axi_rdata    ( pcie_dwidth_axi_rdata    ),
    .m_axi_rresp    ( pcie_dwidth_axi_rresp    ),
    .m_axi_rlast    ( pcie_dwidth_axi_rlast    ),
    .m_axi_rvalid   ( pcie_dwidth_axi_rvalid   ),
    .m_axi_rready   ( pcie_dwidth_axi_rready   )
  );


assign slave[1].aw_user = '0;
assign slave[1].ar_user = '0;
assign slave[1].w_user = '0;

logic [3:0] slave_b_id;
logic [3:0] slave_r_id;

assign slave[1].b_id = slave_b_id[1:0];
assign slave[1].r_id = slave_r_id[1:0];

// PCIe Clock Converter
axi_clock_converter_0 pcie_axi_clock_converter (
  .m_axi_aclk     ( clk                      ),
  .m_axi_aresetn  ( ndmreset_n               ),
  .m_axi_awid     ( {2'b0, slave[1].aw_id} ),
  .m_axi_awaddr   ( slave[1].aw_addr   ),
  .m_axi_awlen    ( slave[1].aw_len    ),
  .m_axi_awsize   ( slave[1].aw_size   ),
  .m_axi_awburst  ( slave[1].aw_burst  ),
  .m_axi_awlock   ( slave[1].aw_lock   ),
  .m_axi_awcache  ( slave[1].aw_cache  ),
  .m_axi_awprot   ( slave[1].aw_prot   ),
  .m_axi_awregion ( slave[1].aw_region ),
  .m_axi_awqos    ( slave[1].aw_qos    ),
  .m_axi_awvalid  ( slave[1].aw_valid  ),
  .m_axi_awready  ( slave[1].aw_ready  ),
  .m_axi_wdata    ( slave[1].w_data    ),
  .m_axi_wstrb    ( slave[1].w_strb    ),
  .m_axi_wlast    ( slave[1].w_last    ),
  .m_axi_wvalid   ( slave[1].w_valid   ),
  .m_axi_wready   ( slave[1].w_ready   ),
  .m_axi_bid      ( slave_b_id         ),
  .m_axi_bresp    ( slave[1].b_resp    ),
  .m_axi_bvalid   ( slave[1].b_valid   ),
  .m_axi_bready   ( slave[1].b_ready   ),
  .m_axi_arid     ( {2'b0, slave[1].ar_id} ),
  .m_axi_araddr   ( slave[1].ar_addr   ),
  .m_axi_arlen    ( slave[1].ar_len    ),
  .m_axi_arsize   ( slave[1].ar_size   ),
  .m_axi_arburst  ( slave[1].ar_burst  ),
  .m_axi_arlock   ( slave[1].ar_lock   ),
  .m_axi_arcache  ( slave[1].ar_cache  ),
  .m_axi_arprot   ( slave[1].ar_prot   ),
  .m_axi_arregion ( slave[1].ar_region ),
  .m_axi_arqos    ( slave[1].ar_qos    ),
  .m_axi_arvalid  ( slave[1].ar_valid  ),
  .m_axi_arready  ( slave[1].ar_ready  ),
  .m_axi_rid      ( slave_r_id         ),
  .m_axi_rdata    ( slave[1].r_data    ),
  .m_axi_rresp    ( slave[1].r_resp    ),
  .m_axi_rlast    ( slave[1].r_last    ),
  .m_axi_rvalid   ( slave[1].r_valid   ),
  .m_axi_rready   ( slave[1].r_ready   ),
  // from size converter
  .s_axi_aclk     ( pcie_axi_clk             ),
  .s_axi_aresetn  ( ndmreset_n               ),
  .s_axi_awid     ( '0                       ),
  .s_axi_awaddr   ( pcie_dwidth_axi_awaddr   ),
  .s_axi_awlen    ( pcie_dwidth_axi_awlen    ),
  .s_axi_awsize   ( pcie_dwidth_axi_awsize   ),
  .s_axi_awburst  ( pcie_dwidth_axi_awburst  ),
  .s_axi_awlock   ( pcie_dwidth_axi_awlock   ),
  .s_axi_awcache  ( pcie_dwidth_axi_awcache  ),
  .s_axi_awprot   ( pcie_dwidth_axi_awprot   ),
  .s_axi_awregion ( pcie_dwidth_axi_awregion ),
  .s_axi_awqos    ( pcie_dwidth_axi_awqos    ),
  .s_axi_awvalid  ( pcie_dwidth_axi_awvalid  ),
  .s_axi_awready  ( pcie_dwidth_axi_awready  ),
  .s_axi_wdata    ( pcie_dwidth_axi_wdata    ),
  .s_axi_wstrb    ( pcie_dwidth_axi_wstrb    ),
  .s_axi_wlast    ( pcie_dwidth_axi_wlast    ),
  .s_axi_wvalid   ( pcie_dwidth_axi_wvalid   ),
  .s_axi_wready   ( pcie_dwidth_axi_wready   ),
  .s_axi_bid      (                          ),
  .s_axi_bresp    ( pcie_dwidth_axi_bresp    ),
  .s_axi_bvalid   ( pcie_dwidth_axi_bvalid   ),
  .s_axi_bready   ( pcie_dwidth_axi_bready   ),
  .s_axi_arid     ( '0                       ),
  .s_axi_araddr   ( pcie_dwidth_axi_araddr   ),
  .s_axi_arlen    ( pcie_dwidth_axi_arlen    ),
  .s_axi_arsize   ( pcie_dwidth_axi_arsize   ),
  .s_axi_arburst  ( pcie_dwidth_axi_arburst  ),
  .s_axi_arlock   ( pcie_dwidth_axi_arlock   ),
  .s_axi_arcache  ( pcie_dwidth_axi_arcache  ),
  .s_axi_arprot   ( pcie_dwidth_axi_arprot   ),
  .s_axi_arregion ( pcie_dwidth_axi_arregion ),
  .s_axi_arqos    ( pcie_dwidth_axi_arqos    ),
  .s_axi_arvalid  ( pcie_dwidth_axi_arvalid  ),
  .s_axi_arready  ( pcie_dwidth_axi_arready  ),
  .s_axi_rid      (                          ),
  .s_axi_rdata    ( pcie_dwidth_axi_rdata    ),
  .s_axi_rresp    ( pcie_dwidth_axi_rresp    ),
  .s_axi_rlast    ( pcie_dwidth_axi_rlast    ),
  .s_axi_rvalid   ( pcie_dwidth_axi_rvalid   ),
  .s_axi_rready   ( pcie_dwidth_axi_rready   )
);
`endif

endmodule
