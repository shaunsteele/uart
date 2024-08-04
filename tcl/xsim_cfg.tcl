open_vcd
log_wave -recursive *
log_vcd [get_object /<toplevel_testbench/uut/*>]
run all
close_vcd
exit
