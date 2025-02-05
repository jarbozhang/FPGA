# 清空现有库
vdel -lib rtl_work -all

# 创建并映射工作库
vlib rtl_work
vmap work rtl_work

# 编译设计文件
vlog -work rtl_work ../rtl/pip_tb.v
vlog -work rtl_work ../rtl/pip.v

# 启动仿真
vsim -voptargs=+acc rtl_work.pip_tb

# 运行仿真
run 10ns
quit -f
