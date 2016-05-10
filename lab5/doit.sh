#!/bin/bash

echo start compiling modules
vlog bcd_to_7seg.sv
vlog debounce.sv
vlog cntr.sv
vlog quad_decoder.sv
vlog bin_to_bcd.sv
vlog addresser.sv
vlog lab5.sv
echo finished compiling modules
