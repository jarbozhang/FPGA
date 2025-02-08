if ![file isdirectory simulation] {
	file mkdir simulation
}
cd simulation

if ![file isdirectory terminal] {
	file mkdir terminal
}
cd terminal


### 以上为初始化，以下需要根据实际情况修改 ###


# 运行simulation，这里需要根据实际情况修改
source ../../simulation/modelsim/CMC_run_msim_rtl_verilog.do

# 添加波形
add wave -position insertpoint sim:/hcp_tb/uut/*
# 放大波形
wave zoom in 3

# 设置magic button: toggle leaf names
configure wave -signalnamewidth 1
restart -force
run

# 将波形左右移动到指定的地址
wave cursor add -time 0 -name start_marker
wave cursor see start_marker
