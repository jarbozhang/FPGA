`timescale 1ns/1ps

module pip_tb;

  parameter DATA_WIDTH = 9;
  parameter CLK_PERIOD = 10;

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
    
    // 等待几个时钟周期
    #(CLK_PERIOD*2);
    
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
    
    #(CLK_PERIOD*5);
    
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
    
  
    // 仿真结束等待
    #(CLK_PERIOD*1000);
    $finish;
  end

endmodule