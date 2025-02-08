`timescale 1ps/1ps


// 此test bench是对pip模块进行的测试梳理
// Quartus中的此test bench运行时间建议设置为10ns
// 更新modelsim.ini文件中的RunLength = 10000 (此时modelsim在每次restart之后，run的时间为10ns)
module hcp_tb();

  // 定义主要参数
  parameter DATA_WIDTH = 9;        // 数据位宽
  parameter CLK_PERIOD = 20;       // 时钟周期
  parameter INIT_DELAY = 18;       // 初始延迟参数
  parameter DELAY_COUNT = 14;     // 从第一拍开始到开始拉高使能信号之间需要间隔多少拍

  // TSMP报文类型定义
  parameter TSMP_TYPE_NONE = 8'hff;    // 非TSMP报文
  parameter TSMP_TYPE_READ = 8'h00;     // TSMP读报文
  parameter TSMP_TYPE_WRITE = 8'h01;    // TSMP写报文
  parameter TSMP_TYPE_CONFIG = 8'h16;   // TSMP配置报文

  // 输入信号定义
  reg i_clk;                      // 时钟信号
  reg i_rst_n;                    // 复位信号，低电平有效
  reg [DATA_WIDTH-1:0] iv_data;   // 输入数据
  reg i_data_wr;                  // 数据写使能
  reg is_tsmp;                    // TSMP报文标志
  reg [7:0] tsmp_type;            // TSMP报文类型

  // 输出信号定义
  wire [DATA_WIDTH-1:0] ov_data_hcp;    // 输出到HCP的数据
  wire o_data_wr_hcp;                   // HCP数据写使能
  wire [DATA_WIDTH-1:0] ov_data_plc;    // 输出到PLC的数据
  wire o_data_wr_plc;                   // PLC数据写使能

  // 修改UUT实例化
  hcp #(DATA_WIDTH) uut(
    .i_clk(i_clk),
    .i_rst_n(i_rst_n),
    .iv_data(iv_data),
    .i_data_wr(i_data_wr)
  );

  initial begin
    i_clk = 1'b1;
    forever #(CLK_PERIOD/2) i_clk = ~i_clk;
  end

  // 定义发送报文的任务
  task send_packet;
    input [1:0] pkt_type;    // 0:普通报文, 1:TSMP配置, 2:TSMP读, 3:TSMP写
    input [7:0] delay;       // 发送前等待的时钟周期数
    
    begin
        #(delay*CLK_PERIOD);
        
        i_data_wr <= 1'b1;
        iv_data <= 9'h101;
        #(CLK_PERIOD);
        
        case(pkt_type)
            2'd1: iv_data <= 9'h016;    // TSMP配置
            2'd2: iv_data <= 9'h000;    // TSMP读
            2'd3: iv_data <= 9'h001;    // TSMP写
        endcase
        #(CLK_PERIOD);
        
        // 填充0
        repeat(pkt_type == 0 ? 7 : 10) begin
            iv_data <= 9'h000;
            #(CLK_PERIOD);
        end
        
        // TSMP特有字段
        if (pkt_type != 0) begin
            iv_data <= 9'h0ff;
            #(CLK_PERIOD);
            iv_data <= 9'h001;
            #(CLK_PERIOD);
        end

        repeat(DELAY_COUNT-14) begin
            iv_data <= 9'h000;
            #(CLK_PERIOD);
        end
        
        // 设置TSMP标志
        is_tsmp <= (pkt_type != 0);
        case(pkt_type)
            2'd1: tsmp_type <= TSMP_TYPE_CONFIG;
            2'd2: tsmp_type <= TSMP_TYPE_READ;
            2'd3: tsmp_type <= TSMP_TYPE_WRITE;
            default: tsmp_type <= TSMP_TYPE_NONE;
        endcase
        
        // 通用头部结束
        repeat(2) begin
            iv_data <= 9'h000;
            #(CLK_PERIOD);
        end
        
        // payload部分
        iv_data <= 9'h000;
        #(CLK_PERIOD);
        iv_data <= 9'h005;
        #(CLK_PERIOD);
        repeat(5) begin
            iv_data <= 9'h000;
            #(CLK_PERIOD);
        end
        repeat(64) begin
            iv_data <= iv_data + 1;
            #(CLK_PERIOD);
        end
        iv_data <= 9'h100;
        #(CLK_PERIOD);
        i_data_wr <= 1'b0;
    end
  endtask

  initial begin
    // 初始化
    i_rst_n <= 1'b0;
    i_data_wr <= 1'b0;
    iv_data <= {DATA_WIDTH{1'b0}};
    is_tsmp <= 1'b0;
    tsmp_type <= TSMP_TYPE_NONE;
    #(CLK_PERIOD) i_rst_n <= 1'b1;
    
    #(INIT_DELAY*CLK_PERIOD);

    // 发送四个报文
    send_packet(3, 0);       // 第一个TSMP写报文
    send_packet(2, 0);       // 第二个TSMP读报文，紧接着发送
    // send_packet(3, DELAY_COUNT-1);      // 第三个TSMP写报文，延迟DELAY_COUNT-1拍，模拟寄存器最后一位输出的同时，有新的一拍进来的情况

    // 仿真结束等待
    #(CLK_PERIOD*20);
    // $finish;
  end

  // 性能统计计数器
  integer pass_count;             // 数据检查通过计数
  integer error_count;            // 数据检查错误计数
  integer enable_pass_count;      // 使能信号检查通过计数
  integer enable_error_count;     // 使能信号检查错误计数

  // 初始化计数器
  initial begin
    pass_count = 0;
    error_count = 0;
    enable_pass_count = 0;
    enable_error_count = 0;
  end

  task check_output;
    input [DATA_WIDTH-1:0] expected_data;
    input [1:0] port_sel;  // 添加端口选择参数：0-pip2hcp, 1-pip2plc
    begin
      case(port_sel)
        0: begin  // 检查pip2hcp输出
          if (ov_data_hcp !== expected_data) begin
            error_count = error_count + 1;
            $display("**ERROR**: Time=%0t ps: HCP Output data mismatch!", $time);
            $display("Expected: %h, Got: %h", expected_data, ov_data_hcp);
          end else begin
            pass_count = pass_count + 1;
            $display("PASS: Time=%0t ps: HCP Output data match. Data=%h", $time, ov_data_hcp);
          end
        end
        1: begin  // 检查pip2plc输出
          if (ov_data_plc !== expected_data) begin
            error_count = error_count + 1;
            $display("**ERROR**: Time=%0t ps: PLC Output data mismatch!", $time);
            $display("Expected: %h, Got: %h", expected_data, ov_data_plc);
          end else begin
            pass_count = pass_count + 1;
            $display("PASS: Time=%0t ps: PLC Output data match. Data=%h", $time, ov_data_plc);
          end
        end
      endcase
    end
  endtask

  // 数据历史记录寄存器
  reg [DATA_WIDTH-1:0] iv_data_reg[DELAY_COUNT-1:0];   // 存储最近DELAY_COUNT拍的数据历史
  reg i_data_wr_reg[DELAY_COUNT-1:0];                  // 存储最近DELAY_COUNT拍的写使能历史
  integer i;

  // 在每个时钟上升沿记录iv_data和i_data_wr的历史值
  always @(posedge i_clk) begin
    if (!i_rst_n) begin
      for (i = 0; i < DELAY_COUNT; i = i + 1) begin
        iv_data_reg[i] <= 0;
        i_data_wr_reg[i] <= 0;
      end
    end
    else begin
      // 移位操作
      for (i = DELAY_COUNT-1; i > 0; i = i - 1) begin
        iv_data_reg[i] <= iv_data_reg[i-1];
        i_data_wr_reg[i] <= i_data_wr_reg[i-1];
      end
      iv_data_reg[0] <= iv_data;
      i_data_wr_reg[0] <= i_data_wr;
    end
  end

  // 检查输出序列
  always @(posedge i_clk) begin
    if (!i_rst_n) begin
    end
    else if (o_data_wr_hcp) begin
      // 检查写使能信号是否对应
      if (i_data_wr_reg[DELAY_COUNT-1] !== 1'b1) begin
        enable_error_count = enable_error_count + 1;
        $display("**ERROR**: Time=%0t ps: Write enable mismatch!", $time);
        $display("Expected i_data_wr_reg[DELAY_COUNT-1]=1, Got: %b", i_data_wr_reg[DELAY_COUNT-1]);
      end else if (tsmp_type !==  TSMP_TYPE_READ && tsmp_type !== TSMP_TYPE_WRITE) begin
        enable_error_count = enable_error_count + 1;
        $display("**ERROR**: Time=%0t ps: TSMP type mismatch!", $time);
        $display("Expected tsmp_type=TSMP_TYPE_CONFIG, Got: %h", tsmp_type);
      end else begin
        enable_pass_count = enable_pass_count + 1;
      end
      // 检查数据值
      check_output(iv_data_reg[DELAY_COUNT-1], 0);
    end
    else if (o_data_wr_plc) begin
      // 检查写使能信号是否对应
      if (i_data_wr_reg[DELAY_COUNT-1] !== 1'b1) begin
        enable_error_count = enable_error_count + 1;
        $display("**ERROR**: Time=%0t ps: Write enable mismatch!", $time);
        $display("Expected i_data_wr_reg[DELAY_COUNT-1]=1, Got: %b", i_data_wr_reg[DELAY_COUNT-1]);
      end else if (tsmp_type !== TSMP_TYPE_CONFIG) begin
        enable_error_count = enable_error_count + 1;
        $display("**ERROR**: Time=%0t ps: TSMP type mismatch!", $time);
        $display("Expected tsmp_type=TSMP_TYPE_READ or TSMP_TYPE_WRITE, Got: %h", tsmp_type);
      end else begin
        enable_pass_count = enable_pass_count + 1;
      end
      // 检查数据值
      check_output(iv_data_reg[DELAY_COUNT-1], 1);
    end
    // 如果普通报文则先不考虑
    else if (i_data_wr_reg[DELAY_COUNT-1] === 1'b1) begin
      if (is_tsmp == 1'b1) begin
        enable_error_count = enable_error_count + 1;
        $display("**ERROR**: Time=%0t ps: Missing output data!", $time);
      end
    end
  end

  // 在仿真结束时输出总结
  initial begin
    #(CLK_PERIOD*400);  // 等待仿真结束
    $display("\n----------------------------------------");
    $display("Simulation Summary:");
    $display("Data Check Results:");
    $display("  Total Checks: %0d", pass_count + error_count);
    $display("  PASS: %0d", pass_count);
    $display("  ERROR: %0d", error_count);
    $display("\nWrite Enable Check Results:");
    $display("  Total Checks: %0d", enable_pass_count + enable_error_count);
    $display("  PASS: %0d", enable_pass_count);
    $display("  ERROR: %0d", enable_error_count);
    $display("----------------------------------------\n");
  end

endmodule