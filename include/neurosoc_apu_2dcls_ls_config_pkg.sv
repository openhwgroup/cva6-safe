// Copyright 2024 Thales SA (Thales Research and Technology)
//
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
// You may obtain a copy of the License at https://solderpad.org/licenses/
//
// Original Author: Daniel GRACIA PEREZ - Thales

package neurosoc_apu_config_pkg;

  typedef enum bit[0:0] {
    DC = 0,
    LS = 1
  } dcls_mode_t;

  localparam int NUM_DCLS = 2;
  localparam dcls_mode_t DCLS_MODE = LS;

endpackage