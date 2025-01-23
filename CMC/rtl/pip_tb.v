`timescale 1ps/1ps

module pip_tb();

  parameter DATA_WIDTH = 9;
  parameter CLK_PERIOD = 6;
  parameter INIT_DELAY = 18;  // 添加初始延迟参数
  parameter MAX_SEQ_LENGTH = 64;

  reg i_clk;
  reg i_rst_n;
  reg [DATA_WIDTH-1:0] iv_data;
  reg i_data_wr;
  wire [DATA_WIDTH-1:0] ov_data;
  wire o_data_wr;

  pip #(DATA_WIDTH) uut(
    .i_clk(i_clk),
    .i_rst_n(i_rst_n),
    .iv_data(iv_data),
    .i_data_wr(i_data_wr),
    .ov_data(ov_data),
    .o_data_wr(o_data_wr)
  );

  initial begin
    i_clk = 1'b1;
    forever #(CLK_PERIOD/2) i_clk = ~i_clk;
  end

  initial begin
    i_rst_n <= 1'b0;
    i_data_wr <= 1'b0;
    iv_data <= {DATA_WIDTH{1'b0}};
    #(CLK_PERIOD) i_rst_n <= 1'b1;
    
    // 等待INIT_DELAY个时钟周期
    #(INIT_DELAY*CLK_PERIOD);


    // 第一个报文
    // 模拟TSMP报文
    i_data_wr <= 1'b1;
    iv_data <= 9'h101; 
    #(CLK_PERIOD);
    iv_data <= 9'h001; 
    #(CLK_PERIOD);
    repeat(10) begin
        iv_data <= 9'h000; 
        #(CLK_PERIOD);
    end
    iv_data <= 9'h0ff; 
    #(CLK_PERIOD);
    iv_data <= 9'h001; 
    #(CLK_PERIOD);
    iv_data <= 9'h000;
    #(CLK_PERIOD);
    iv_data <= 9'h000;
    #(CLK_PERIOD);

    // payload
    iv_data <= 9'h000;
    #(CLK_PERIOD);
    iv_data <= 9'h001;
    #(CLK_PERIOD);
    repeat(64) begin
        iv_data <= iv_data + 1; 
        #(CLK_PERIOD);
    end
    iv_data <= 9'h100;
    #(CLK_PERIOD);
    i_data_wr <= 1'b0;

    #(5*CLK_PERIOD);// 第二个普通报文，和第一个报文相差5拍

    
    // 模拟非TSMP报文
    i_data_wr <= 1'b1;
    iv_data <= 9'h101; 
    #(CLK_PERIOD);
    iv_data <= 9'h001; 
    #(CLK_PERIOD);
    repeat(10) begin
        iv_data <= 9'h000; 
        #(CLK_PERIOD);
    end
    iv_data <= 9'h0f1; 
    #(CLK_PERIOD);
    iv_data <= 9'h000; 
    #(CLK_PERIOD);
    iv_data <= 9'h000;
    #(CLK_PERIOD);
    iv_data <= 9'h000;
    #(CLK_PERIOD);

    // payload
    iv_data <= 9'h000;
    #(CLK_PERIOD);
    iv_data <= 9'h001;
    #(CLK_PERIOD);
    repeat(64) begin
        iv_data <= iv_data + 1; 
        #(CLK_PERIOD);
    end
    iv_data <= 9'h100;
    #(CLK_PERIOD);
    i_data_wr <= 1'b0;
    





     // 第三个TSMP报文，紧接着第二个报文
    i_data_wr <= 1'b1;
    iv_data <= 9'h101; 
    #(CLK_PERIOD);
    iv_data <= 9'h001; 
    #(CLK_PERIOD);
    repeat(10) begin
        iv_data <= 9'h000; 
        #(CLK_PERIOD);
    end
    iv_data <= 9'h0ff; 
    #(CLK_PERIOD);
    iv_data <= 9'h001; 
    #(CLK_PERIOD);
    iv_data <= 9'h000;
    #(CLK_PERIOD);
    iv_data <= 9'h000;
    #(CLK_PERIOD);

    // payload
    iv_data <= 9'h000;
    #(CLK_PERIOD);
    iv_data <= 9'h001;
    #(CLK_PERIOD);
    repeat(64) begin
        iv_data <= iv_data + 1; 
        #(CLK_PERIOD);
    end
    iv_data <= 9'h100;
    #(CLK_PERIOD);
    i_data_wr <= 1'b0; 







    // 第四个TSMP报文，和第三个报文相差13拍
    #(CLK_PERIOD*13);
    i_data_wr <= 1'b1;
    iv_data <= 9'h101; 
    #(CLK_PERIOD);
    iv_data <= 9'h001; 
    #(CLK_PERIOD);
    repeat(10) begin
        iv_data <= 9'h000; 
        #(CLK_PERIOD);
    end
    iv_data <= 9'h0ff; 
    #(CLK_PERIOD);
    iv_data <= 9'h001; 
    #(CLK_PERIOD);
    iv_data <= 9'h000;
    #(CLK_PERIOD);
    iv_data <= 9'h000;
    #(CLK_PERIOD);

    // payload
    iv_data <= 9'h000;
    #(CLK_PERIOD);
    iv_data <= 9'h001;
    #(CLK_PERIOD);
    repeat(64) begin
        iv_data <= iv_data + 1; 
        #(CLK_PERIOD);
    end
    iv_data <= 9'h100;
    #(CLK_PERIOD);
    i_data_wr <= 1'b0;  
  
    // 仿真结束等待
    #(CLK_PERIOD*500);
    $finish;
  end

  // 添加计数器
  integer pass_count;
  integer error_count;
  integer enable_pass_count;
  integer enable_error_count;

  // 初始化计数器
  initial begin
    pass_count = 0;
    error_count = 0;
    enable_pass_count = 0;
    enable_error_count = 0;
  end

  task check_output;
    input [DATA_WIDTH-1:0] expected_data;
    begin
      if (ov_data !== expected_data) begin
        error_count = error_count + 1;
        $display("**ERROR**: Time=%0t ns: Output data mismatch!", $time);
        $display("Expected: %h, Got: %h", expected_data, ov_data);
      end else begin
        pass_count = pass_count + 1;
        $display("PASS: Time=%0t ns: Output data match. Data=%h", $time, ov_data);
      end
    end
  endtask

  // 添加寄存器声明
  reg [DATA_WIDTH-1:0] iv_data_reg[13:0];  // 数据历史
  reg i_data_wr_reg[13:0];                 // 写使能历史
  integer i;

  // 在每个时钟上升沿记录iv_data和i_data_wr的历史值
  always @(posedge i_clk) begin
    if (!i_rst_n) begin
      for (i = 0; i < 14; i = i + 1) begin
        iv_data_reg[i] <= 0;
        i_data_wr_reg[i] <= 0;
      end
    end
    else begin
      // 移位操作
      for (i = 13; i > 0; i = i - 1) begin
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
    else if (o_data_wr) begin
      // 检查写使能信号是否对应
      if (i_data_wr_reg[13] !== 1'b1) begin
        enable_error_count = enable_error_count + 1;
        $display("**ERROR**: Time=%0t ns: Write enable mismatch!", $time);
        $display("Expected i_data_wr_reg[13]=1, Got: %b", i_data_wr_reg[13]);
      end else begin
        enable_pass_count = enable_pass_count + 1;
      end
      // 检查数据值
      check_output(iv_data_reg[13]);
    end
    // 如果普通报文则先不考虑
    // else if (i_data_wr_reg[13] === 1'b1) begin
    //   enable_error_count = enable_error_count + 1;
    //   $display("**ERROR**: Time=%0t ns: Missing output data!", $time);
    // end
  end

  // 在仿真结束时输出总结
  initial begin
    #(CLK_PERIOD*500);  // 等待仿真结束
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