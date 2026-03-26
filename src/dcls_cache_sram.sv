// Copyright (c) 2023 - 2025 Thales
// All Rights Reserved.
//
// Author: Abdou Lahat NDIAYE, Thales cortAIx Labs
// Date: 29.01.2025
//
// Description: Externalized SRAMs for data cache and instrction cache wich
//              include single & double error correction
//
// ========================================================================== //
// Revisions  :
// Date        Version  Author              Description
// 2025-01-29  0.1      Abdou Lahat NDIAYE  first functional release
// ========================================================================== //

module dcls_cache_sram
  import ariane_pkg::*;
  import wt_cache_pkg::*;
  // import neurosoc_cache_pkg::*;
#(
    parameter config_pkg::cva6_cfg_t CVA6Cfg = config_pkg::cva6_cfg_empty
) (
    input logic clk_i,
    input logic rst_ni,
    input logic dcache_ecc_error_i,
    input  dcls_cva6_cache_pkg::dcache_ext_req_t  dcache_req,
    output dcls_cva6_cache_pkg::dcache_ext_resp_t dcache_resp,
    input  dcls_cva6_cache_pkg::icache_ext_req_t  icache_req,
    output dcls_cva6_cache_pkg::icache_ext_resp_t icache_resp
);

  localparam DCACHE_NUM_BANKS =
      dcls_cva6_cache_pkg::DCACHE_NUM_BANKS;
  localparam DCACHE_TAG_SRAM_WIDTH =
      dcls_cva6_cache_pkg::DCACHE_TAG_SRAM_WIDTH;
  localparam BE_DCACHE_TAG_WIDTH =
      dcls_cva6_cache_pkg::BE_DCACHE_TAG_WIDTH;
  localparam ICACHE_TAG_SRAM_WIDTH =
      dcls_cva6_cache_pkg::ICACHE_TAG_SRAM_WIDTH;
  localparam BE_ICACHE_TAG_WIDTH =
      dcls_cva6_cache_pkg::BE_ICACHE_TAG_WIDTH;
  localparam ICACHE_DATA_SRAM_WIDTH =
      dcls_cva6_cache_pkg::ICACHE_DATA_SRAM_WIDTH;
  localparam BE_ICACHE_DATA_WIDTH =
      dcls_cva6_cache_pkg::BE_ICACHE_DATA_WIDTH;
  localparam ICACHE_TAG_WIDTH_NEW =
      dcls_cva6_cache_pkg::ICACHE_TAG_WIDTH_NEW;
  localparam ICACHE_DATA_WIDTH_NEW =
      dcls_cva6_cache_pkg::ICACHE_DATA_WIDTH_NEW;
  localparam ICACHE_NUM_WORDS =
      dcls_cva6_cache_pkg::ICACHE_NUM_WORDS;

//DATA CACHE
  assign dcache_resp.ecc_error = dcache_ecc_error_i;

  for (genvar k = 0; k < DCACHE_NUM_BANKS; k++) begin : gen_data_banks
    // Data RAM
    sram #(
        .USER_WIDTH(CVA6Cfg.DCACHE_SET_ASSOC * CVA6Cfg.DCACHE_USER_WIDTH),
        .DATA_WIDTH(CVA6Cfg.DCACHE_SET_ASSOC * CVA6Cfg.XLEN),
        .USER_EN   (CVA6Cfg.DATA_USER_EN),
        .NUM_WORDS (CVA6Cfg.DCACHE_NUM_WORDS)
    ) i_data_sram (
        .clk_i  (clk_i),
        .rst_ni (rst_ni),
        .req_i  (dcache_req.bank_req[k]),
        .we_i   (dcache_req.bank_we[k]),
        .addr_i (dcache_req.bank_idx[k]),
        .wuser_i(dcache_req.bank_wuser[k]),
        .wdata_i(dcache_req.bank_wdata[k]),
        .be_i   (dcache_req.bank_be[k]),
        .ruser_o(dcache_resp.bank_ruser[k]),
        .rdata_o(dcache_resp.bank_rdata[k])
    );
  end

  logic [CVA6Cfg.DCACHE_SET_ASSOC*DCACHE_TAG_SRAM_WIDTH -1 :0] dcache_data_sram_wdata;
  logic [CVA6Cfg.DCACHE_SET_ASSOC*DCACHE_TAG_SRAM_WIDTH -1 :0] dcache_data_sram_rdata;
  logic [CVA6Cfg.DCACHE_SET_ASSOC*BE_DCACHE_TAG_WIDTH-1 : 0] dcache_data_sram_be;

  // Linearization
  for (genvar i = 0; i < CVA6Cfg.DCACHE_SET_ASSOC; i++) begin : gen_sram_dcache_concat
    assign dcache_data_sram_wdata[i*DCACHE_TAG_SRAM_WIDTH +:DCACHE_TAG_SRAM_WIDTH ] = {
      1'b0, dcache_req.tag_wdata_vld[i], dcache_req.tag_wdata
    };
    assign dcache_data_sram_be[i*BE_DCACHE_TAG_WIDTH +: BE_DCACHE_TAG_WIDTH] = {BE_DCACHE_TAG_WIDTH{dcache_req.tag_req[i]}};
    assign {dcache_resp.tag_rdata_vld[i],dcache_resp.tag_rdata[i]} = dcache_data_sram_rdata[i*DCACHE_TAG_SRAM_WIDTH  +: DCACHE_TAG_SRAM_WIDTH ];
  end

  // Tag RAM
  sram #(
      // tag + valid bit
      .DATA_WIDTH(CVA6Cfg.DCACHE_SET_ASSOC * DCACHE_TAG_SRAM_WIDTH),
      .NUM_WORDS (CVA6Cfg.DCACHE_NUM_WORDS)
  ) i_tag_sram (
      .clk_i  (clk_i),
      .rst_ni (rst_ni),
      .req_i  ('1),
      .we_i   (dcache_req.tag_we),
      .addr_i (dcache_req.tag_idx),
      .wuser_i('0),
      .wdata_i(dcache_data_sram_wdata),
      .be_i   (dcache_data_sram_be),
      .ruser_o(),
      .rdata_o(dcache_data_sram_rdata)
  );
// end of DATA CACHE


//INSTRUCTION CACHE

  logic [CVA6Cfg.ICACHE_SET_ASSOC*ICACHE_TAG_SRAM_WIDTH-1 : 0] icache_tag_sram_wdata;
  logic [CVA6Cfg.ICACHE_SET_ASSOC*ICACHE_TAG_SRAM_WIDTH-1 : 0] icache_tag_sram_rdata;
  logic [CVA6Cfg.ICACHE_SET_ASSOC*BE_ICACHE_TAG_WIDTH-1 : 0] icache_tag_sram_be;

  logic [CVA6Cfg.ICACHE_SET_ASSOC-1:0][ICACHE_TAG_SRAM_WIDTH-1 : 0] icache_tag_wdata_enc;
  logic [CVA6Cfg.ICACHE_SET_ASSOC-1:0][ICACHE_TAG_SRAM_WIDTH-1 : 0] icache_tag_wdata_enc_q;
  logic [CVA6Cfg.ICACHE_SET_ASSOC-1:0][ICACHE_TAG_SRAM_WIDTH-1 : 0] icache_tag_rdata_pre_dec;

  logic [CVA6Cfg.ICACHE_SET_ASSOC*ICACHE_DATA_SRAM_WIDTH-1 : 0] data_sram_rdata;
  logic [CVA6Cfg.ICACHE_SET_ASSOC*CVA6Cfg.ICACHE_USER_LINE_WIDTH-1 : 0] data_sram_ruser;
  logic [CVA6Cfg.ICACHE_SET_ASSOC*BE_ICACHE_DATA_WIDTH-1 : 0] data_sram_be;

  logic [ICACHE_DATA_SRAM_WIDTH-1 : 0] icache_data_wdata_enc;
  logic [CVA6Cfg.ICACHE_SET_ASSOC-1:0][ICACHE_DATA_SRAM_WIDTH-1 :0] icache_data_rdata_pre_dec;

  logic [CVA6Cfg.ICACHE_SET_ASSOC-1:0] sb_err_tag;
  logic [CVA6Cfg.ICACHE_SET_ASSOC-1:0] db_err_tag;
  logic [CVA6Cfg.ICACHE_SET_ASSOC-1:0] sb_err_data;
  logic [CVA6Cfg.ICACHE_SET_ASSOC-1:0] db_err_data;
  logic [CVA6Cfg.ICACHE_SET_ASSOC-1:0] tmp_sb_err_data;
  logic [CVA6Cfg.ICACHE_SET_ASSOC-1:0] tmp_db_err_data;

  for (genvar i = 0; i < CVA6Cfg.ICACHE_SET_ASSOC; i++) begin : gen_ecc
    assign icache_tag_wdata_enc[i][ICACHE_TAG_SRAM_WIDTH-1:ICACHE_TAG_WIDTH_NEW] = '0;

    if (dcls_cva6_cache_pkg::ECC_EN) begin : gen_ecc

      // Encode tag
      ecc_enc #(
        .K     (CVA6Cfg.ICACHE_TAG_WIDTH + 1),  // tag + valid bit
        .P0_LSB(0)                              // p0 is located at MSB
      ) ecc_enc_tag (
        .d_i (icache_req.tag_wdata[i]),
        .q_o (icache_tag_wdata_enc[i][ICACHE_TAG_WIDTH_NEW-1 : 0]),
        .p_o (),
        .p0_o()
      );

      // Decode tag
      ecc_dec #(
        .K      (CVA6Cfg.ICACHE_TAG_WIDTH + 1),  // tag + valid bit
        .LATENCY(0),                             //0: no latency (combinatorial design)
                                                  //1: registered outputs
                                                  //2: registered inputs+outputs
        .P0_LSB (0)                              //0: p0 is located at MSB
                                                  //1: p0 is located at LSB
      ) ecc_dec_tag (
        //clock/reset ports (if LATENCY > 0)
        .rst_ni(rst_ni),  //asynchronous reset
        .clk_i(clk_i),  //clock input
        .clkena_i(1'b1),  //clock enable input
        //data ports
        .d_i(icache_tag_rdata_pre_dec[i][ICACHE_TAG_WIDTH_NEW-1 : 0]),  //encoded code word input
        //.q_o        (cl_tag_valid_rdata_dec[i]),        //information bit vector output
        .q_o(),  //information bit vector output
        .q_err_o(icache_resp.tag_rdata[i]),  //information bit vector output
        .syndrome_o(),  //syndrome vector output
        //flags
        .sb_err_o(sb_err_tag[i]),  //single bit error detected
        .db_err_o(db_err_tag[i]),  //double bit error detected
        .sb_fix_o()  //repaired error in the information bits
      );

      // Decode data
      ecc_dec #(
        .K      (CVA6Cfg.ICACHE_LINE_WIDTH),
        .LATENCY(0),                          //0: no latency (combinatorial design)
                                              //1: registered outputs
                                              //2: registered inputs+outputs
        .P0_LSB (0)                           //0: p0 is located at MSB
                                              //1: p0 is located at LSB
      ) ecc_dec_data (
        //clock/reset ports (if LATENCY > 0)
        .rst_ni(rst_ni),  //asynchronous reset
        .clk_i(clk_i),  //clock input
        .clkena_i(1'b1),  //clock enable input
        //data ports
        .d_i        (icache_data_rdata_pre_dec[i][ICACHE_DATA_WIDTH_NEW - 1 :0]),        //encoded code word input
        //.q_o        (cl_tag_valid_rdata_dec[i]),        //information bit vector output
        .q_o(),  //information bit vector output
        .q_err_o(icache_resp.data_rdata[i]),  //information bit vector output
        .syndrome_o(),  //syndrome vector output
        //flags
        .sb_err_o(tmp_sb_err_data[i]),  //single bit error detected
        .db_err_o(tmp_db_err_data[i]),  //double bit error detected
        .sb_fix_o()  //repaired error in the information bits
      );
      
      //PZ mask the single bit and double bit error on data in case tag is not valid...
      assign sb_err_data[i] = tmp_sb_err_data[i] && icache_resp.tag_rdata[i][CVA6Cfg.ICACHE_TAG_WIDTH];
      assign db_err_data[i] = tmp_db_err_data[i] && icache_resp.tag_rdata[i][CVA6Cfg.ICACHE_TAG_WIDTH];

    end else begin
      assign icache_tag_wdata_enc[i][ICACHE_TAG_WIDTH_NEW-1 : 0] = icache_req.tag_wdata[i];
      assign icache_resp.tag_rdata[i] = icache_tag_rdata_pre_dec[i][ICACHE_TAG_WIDTH_NEW-1 : 0];

      assign icache_resp.data_rdata[i] = icache_data_rdata_pre_dec[i][ICACHE_DATA_WIDTH_NEW-1 : 0];
    end
  end

  // Encode data
  if (dcls_cva6_cache_pkg::ECC_EN) begin

    ecc_enc #(
      .K     (CVA6Cfg.ICACHE_LINE_WIDTH),  // tag + valid bit
      .P0_LSB(0)                           // p0 is located at MSB
    ) ecc_enc_data (
        .d_i (icache_req.data_wdata),
        .q_o (icache_data_wdata_enc[ICACHE_DATA_WIDTH_NEW-1 : 0]),
        .p_o (),
        .p0_o()
    );
  end else begin
    assign icache_data_wdata_enc[ICACHE_DATA_WIDTH_NEW-1 : 0] = icache_req.data_wdata;
  end
  assign icache_data_wdata_enc[ICACHE_DATA_SRAM_WIDTH-1:ICACHE_DATA_WIDTH_NEW] = '0;

  assign icache_resp.ecc_error = (dcls_cva6_cache_pkg::ECC_EN) ? (|sb_err_tag) | (|db_err_tag) | (|sb_err_data) | (|db_err_data) : 1'b0;

  // Linearization of memory signals
  for (genvar i = 0; i < CVA6Cfg.ICACHE_SET_ASSOC; i++) begin : gen_sram_concat

    assign icache_tag_sram_wdata[i*(ICACHE_TAG_SRAM_WIDTH) +: (ICACHE_TAG_SRAM_WIDTH)] = icache_tag_wdata_enc[i];
    assign icache_tag_sram_be[i*BE_ICACHE_TAG_WIDTH +: BE_ICACHE_TAG_WIDTH] = {BE_ICACHE_TAG_WIDTH{icache_req.tag_req[i]}};
    assign icache_tag_rdata_pre_dec[i] = icache_tag_sram_rdata[i*(ICACHE_TAG_SRAM_WIDTH) +: (ICACHE_TAG_SRAM_WIDTH)];

    assign data_sram_be[i*BE_ICACHE_DATA_WIDTH +: BE_ICACHE_DATA_WIDTH] = {BE_ICACHE_DATA_WIDTH{icache_req.data_req[i]}};
    assign icache_data_rdata_pre_dec[i] = data_sram_rdata[i*ICACHE_DATA_SRAM_WIDTH +: ICACHE_DATA_SRAM_WIDTH];
    assign icache_resp.data_ruser[i] = data_sram_ruser[i*CVA6Cfg.ICACHE_LINE_WIDTH +: CVA6Cfg.ICACHE_LINE_WIDTH];

  end

  // Tag RAM
  sram #(
      // tag + valid bit
      .DATA_WIDTH(CVA6Cfg.ICACHE_SET_ASSOC * (ICACHE_TAG_SRAM_WIDTH)),
      .NUM_WORDS (ICACHE_NUM_WORDS)
  ) tag_sram (
      .clk_i  (clk_i),
      .rst_ni (rst_ni),
      .req_i  ('1),
      .we_i   (icache_req.tag_we),
      .addr_i (icache_req.tag_idx),
      .wuser_i('0),
      .wdata_i(icache_tag_sram_wdata),
      .be_i   (icache_tag_sram_be),
      .ruser_o(),
      .rdata_o(icache_tag_sram_rdata)
  );

  // Data RAM
  sram #(
      .USER_WIDTH(CVA6Cfg.ICACHE_SET_ASSOC*CVA6Cfg.ICACHE_USER_LINE_WIDTH),
      .DATA_WIDTH(CVA6Cfg.ICACHE_SET_ASSOC*ICACHE_DATA_SRAM_WIDTH),
      .USER_EN   (CVA6Cfg.FETCH_USER_EN),
      .NUM_WORDS (ICACHE_NUM_WORDS)
  ) data_sram (
      .clk_i  (clk_i),
      .rst_ni (rst_ni),
      .req_i  ('1),
      .we_i   (icache_req.data_we),
      .addr_i (icache_req.data_idx),
      .wuser_i({CVA6Cfg.ICACHE_SET_ASSOC{icache_req.data_wuser}}),
      .wdata_i({CVA6Cfg.ICACHE_SET_ASSOC{icache_data_wdata_enc}}),
      .be_i   (data_sram_be),
      .ruser_o(data_sram_ruser),
      .rdata_o(data_sram_rdata)
  );
// end of DATA CACHE

endmodule
