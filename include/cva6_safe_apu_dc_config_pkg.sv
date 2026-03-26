// Copyright 2026 Thales SA (Thales Research and Technology)
//
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
// You may obtain a copy of the License at https://solderpad.org/licenses/
//
// Original Author: Daniel GRACIA PEREZ - Thales

package cva6_safe_apu_config_pkg;

  // Currently only NUM_DCLS = 1 is supported
  localparam int NUM_DCLS = 1;
  localparam cva6_safe_dcls_types_pkg::dcls_mode_t DCLS_MODE = cva6_safe_dcls_types_pkg::DC;

endpackage
