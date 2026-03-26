# Copyright 2026 THALES Research & Technology cortAIx Labs, France

# Author: Daniel Gracia Pérez <daniel.gracia-perez@thalesgroup.com>

set project cva6_safe

create_project $project . -force -part $::env(XILINX_PART)
set_property board_part $::env(XILINX_BOARD) [current_project]

# set number of threads to 8 (maximum, unfortunately)
set_param general.maxThreads 8

set_msg_config -id {[Synth 8-5858]} -new_severity "info"

set_msg_config -id {[Synth 8-4480]} -limit 1000