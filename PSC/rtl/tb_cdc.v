`timescale 1ns/1ps

module tb_cdc();
    // Parameters
    parameter CLK_PERIOD = 10;

    // Signals
    reg i_clk;
    reg i_rst_n;
    reg [7:0] iv_data;
    reg i_data_wr;
    wire [7:0] ov_data;
    wire o_data_wr;
    
    // Clock generation
    initial begin
        i_clk            = 1'b1;
        forever #5 i_clk = ~i_clk;  // 100MHz时钟
    end
    
    // Instantiate CDC module
    cdc cdc_inst(
    .i_clk(i_clk),
    .i_rst_n(i_rst_n),
    .iv_data(iv_data),
    .i_data_wr(i_data_wr),
    .ov_data(ov_data),
    .o_data_wr(o_data_wr)
    );
    
    // Test stimulus
    initial begin
        // Initialize signals
        i_rst_n   <= 1'b1;
        iv_data   <= 8'd0;
        i_data_wr <= 1'b0;
        
        // Reset
        #(CLK_PERIOD);
        i_rst_n <= 1'b0;
        #(CLK_PERIOD);
        i_rst_n <= 1'b1;
        
        // Wait for a while to ensure reset is complete
        #(CLK_PERIOD*10);
        
        // Test case 1: Write 5 consecutive numbers
        repeat(16) begin
            iv_data   <= iv_data + 8'd1;
            i_data_wr <= 1'b1;
            #(CLK_PERIOD);
        end
        
        i_data_wr <= 1'b0;
        // Wait for data processing to complete
        #(CLK_PERIOD*20);
        
        $display("Simulation completed!");
        $finish;
    end
    
    // 数据监控
    // initial begin
    //     $monitor("Time = %0t rst_n = %b data_wr = %b data = %h out_data = %h out_data_wr = %b",
    //              $time, i_rst_n, i_data_wr, iv_data, ov_data, o_data_wr);
    // end
    
    // 输出数据验证
    // reg [7:0] expect_data;
    // initial begin
    //     expect_data = 8'd1;
    //     forever begin
    //         @(posedge o_data_wr);
    //         if (ov_data ! = expect_data) begin
    //             $display("Error: Expected data = %h, Actual data = %h", expect_data, ov_data);
    //         end
    //         expect_data = expect_data + 8'd1;
    //     end
    // end
    
endmodule
