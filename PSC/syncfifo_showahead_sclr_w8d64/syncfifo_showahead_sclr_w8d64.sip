set_global_assignment -entity "syncfifo_showahead_sclr_w8d64" -library "lib_syncfifo_showahead_sclr_w8d64" -name IP_TOOL_NAME "Qsys"
set_global_assignment -entity "syncfifo_showahead_sclr_w8d64" -library "lib_syncfifo_showahead_sclr_w8d64" -name IP_TOOL_VERSION "19.1"
set_global_assignment -entity "syncfifo_showahead_sclr_w8d64" -library "lib_syncfifo_showahead_sclr_w8d64" -name IP_TOOL_ENV "Qsys"
set_global_assignment -library "lib_syncfifo_showahead_sclr_w8d64" -name SPD_FILE [file join $::quartus(sip_path) "syncfifo_showahead_sclr_w8d64.spd"]
set_global_assignment -library "lib_syncfifo_showahead_sclr_w8d64" -name MISC_FILE [file join $::quartus(sip_path) "../syncfifo_showahead_sclr_w8d64.qsys"]

set_global_assignment -library "lib_syncfifo_showahead_sclr_w8d64" -name MISC_FILE [file join $::quartus(sip_path) "sim/syncfifo_showahead_sclr_w8d64.v"]
set_global_assignment -library "lib_syncfifo_showahead_sclr_w8d64" -name MISC_FILE [file join $::quartus(sip_path) "fifo_191/sim/syncfifo_showahead_sclr_w8d64_fifo_191_qw52ykq.v"]
