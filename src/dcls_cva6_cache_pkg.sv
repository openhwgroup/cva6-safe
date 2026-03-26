// Copyright (c) 2023 - 2025 Thales
// All Rights Reserved. 
//
// Author: Abdou Lahat NDIAYE, Thales cortAIx Labs
// Date: 29.01.2025
//
// Description: Includes parameters of data and instruction cache SRAM externalized  
//
// ========================================================================== //
// Revisions  :
// Date        Version  Author              Description
// 2025-01-29  0.1      Abdou Lahat NDIAYE  first functional release
// ========================================================================== //

package dcls_cva6_cache_pkg;

  localparam config_pkg::cva6_cfg_t CVA6Cfg = build_config_pkg::build_config(
      cva6_config_pkg::cva6_cfg
  );
  localparam DCACHE_CL_IDX_WIDTH = $clog2(CVA6Cfg.DCACHE_NUM_WORDS);
  localparam DCACHE_NUM_BANKS = CVA6Cfg.DCACHE_LINE_WIDTH / CVA6Cfg.XLEN;

  localparam DCACHE_TAG_WIDTH_NEW = CVA6Cfg.DCACHE_TAG_WIDTH + 1;
  // Add extra bits to make the SRAM width byte_aligned
  localparam DCACHE_TAG_SRAM_WIDTH = DCACHE_TAG_WIDTH_NEW + (8 - (DCACHE_TAG_WIDTH_NEW % 8)) % 8;
  localparam BE_DCACHE_TAG_WIDTH = DCACHE_TAG_SRAM_WIDTH / 8;

  typedef struct packed {
    logic [DCACHE_NUM_BANKS-1:0] bank_req;
    logic [DCACHE_NUM_BANKS-1:0] bank_we;
    logic [DCACHE_NUM_BANKS-1:0] [CVA6Cfg.DCACHE_SET_ASSOC-1:0][(CVA6Cfg.XLEN/8)-1:0]          bank_be;
    logic [DCACHE_NUM_BANKS-1:0][DCACHE_CL_IDX_WIDTH-1:0] bank_idx;
    logic [DCACHE_NUM_BANKS-1:0] [CVA6Cfg.DCACHE_SET_ASSOC-1:0][CVA6Cfg.XLEN-1:0]              bank_wdata;
    logic [DCACHE_NUM_BANKS-1:0] [CVA6Cfg.DCACHE_SET_ASSOC-1:0][CVA6Cfg.DCACHE_USER_WIDTH-1:0] bank_wuser;

    logic [CVA6Cfg.DCACHE_SET_ASSOC-1:0] tag_req;
    logic                                tag_we;
    logic [DCACHE_CL_IDX_WIDTH-1:0]      tag_idx;
    logic [CVA6Cfg.DCACHE_TAG_WIDTH-1:0] tag_wdata;
    logic [CVA6Cfg.DCACHE_SET_ASSOC-1:0] tag_wdata_vld;
  } dcache_ext_req_t;

  typedef struct packed {
    logic [DCACHE_NUM_BANKS-1:0] [CVA6Cfg.DCACHE_SET_ASSOC-1:0][CVA6Cfg.XLEN-1:0]              bank_rdata;
    logic [DCACHE_NUM_BANKS-1:0] [CVA6Cfg.DCACHE_SET_ASSOC-1:0][CVA6Cfg.DCACHE_USER_WIDTH-1:0] bank_ruser;

    logic [CVA6Cfg.DCACHE_SET_ASSOC-1:0][CVA6Cfg.DCACHE_TAG_WIDTH-1:0] tag_rdata;
    logic [CVA6Cfg.DCACHE_SET_ASSOC-1:0]                               tag_rdata_vld;

    logic ecc_error;
  } dcache_ext_resp_t;


  // Cache Instruction

  localparam ICACHE_OFFSET_WIDTH = $clog2(CVA6Cfg.ICACHE_LINE_WIDTH / 8);
  localparam ICACHE_NUM_WORDS = 2 ** (CVA6Cfg.ICACHE_INDEX_WIDTH - ICACHE_OFFSET_WIDTH);
  localparam ICACHE_CL_IDX_WIDTH = $clog2(ICACHE_NUM_WORDS);
  
  typedef struct packed {
    logic [CVA6Cfg.ICACHE_SET_ASSOC-1:0]       data_req;
    logic                                      data_we;
    logic [ICACHE_CL_IDX_WIDTH-1:0]            data_idx;
    logic [CVA6Cfg.ICACHE_LINE_WIDTH-1:0]      data_wdata;
    logic [CVA6Cfg.ICACHE_USER_LINE_WIDTH-1:0] data_wuser;

    logic [CVA6Cfg.ICACHE_SET_ASSOC-1:0]                             tag_req;
    logic                                                            tag_we;
    logic [ICACHE_CL_IDX_WIDTH-1:0]                                  tag_idx;
    logic [CVA6Cfg.ICACHE_SET_ASSOC-1:0][CVA6Cfg.ICACHE_TAG_WIDTH:0] tag_wdata;
  } icache_ext_req_t;

  typedef struct packed {
    logic [CVA6Cfg.ICACHE_SET_ASSOC-1:0][CVA6Cfg.ICACHE_LINE_WIDTH-1:0]      data_rdata;
    logic [CVA6Cfg.ICACHE_SET_ASSOC-1:0][CVA6Cfg.ICACHE_USER_LINE_WIDTH-1:0] data_ruser;

    logic [CVA6Cfg.ICACHE_SET_ASSOC-1:0][CVA6Cfg.ICACHE_TAG_WIDTH:0] tag_rdata;
    logic                                                            ecc_error;
  } icache_ext_resp_t;

  // ECC 
  function automatic integer calculate_parity_size;
    input integer k;
    integer m;
    begin
      m = 1;
      while (2 ** m < m + k + 1) m++;
      calculate_parity_size = m;
    end
  endfunction  //calculate_parity_size

  localparam bit unsigned ECC_EN = 1;

  localparam int unsigned TAG_ECC_PARITY_SIZE = ECC_EN ? calculate_parity_size(
      CVA6Cfg.ICACHE_TAG_WIDTH + 1
  ) + 1 : 0;
  localparam int unsigned DATA_ECC_PARITY_SIZE = ECC_EN ? calculate_parity_size(
      CVA6Cfg.ICACHE_LINE_WIDTH
  ) + 1 : 0;

  localparam ICACHE_TAG_WIDTH_NEW = CVA6Cfg.ICACHE_TAG_WIDTH + 1 + TAG_ECC_PARITY_SIZE;
  // Add extra bits to make the SRAM width byte_aligned
  localparam ICACHE_TAG_SRAM_WIDTH = ICACHE_TAG_WIDTH_NEW + (8 - (ICACHE_TAG_WIDTH_NEW % 8)) % 8;
  localparam BE_ICACHE_TAG_WIDTH = ICACHE_TAG_SRAM_WIDTH / 8;

  localparam ICACHE_DATA_WIDTH_NEW = CVA6Cfg.ICACHE_LINE_WIDTH + DATA_ECC_PARITY_SIZE;
  // Add extra bits to make the SRAM width byte_aligned
  localparam ICACHE_DATA_SRAM_WIDTH = ICACHE_DATA_WIDTH_NEW + (8 - (ICACHE_DATA_WIDTH_NEW % 8)) % 8;
  localparam BE_ICACHE_DATA_WIDTH = ICACHE_DATA_SRAM_WIDTH / 8;

endpackage
