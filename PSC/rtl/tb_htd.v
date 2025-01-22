`timescale 1ns/1ps

module tb_htd();
    // Parameters
    parameter DATA_WIDTH = 8;
    parameter CLK_PERIOD = 10;

    // Signals
    reg                   i_clk;
    reg                   i_rst_n;
    reg  [DATA_WIDTH-1:0] iv_data;
    reg                   i_data_wr;
    wire [DATA_WIDTH:0]   ov_data;
    wire                  o_data_wr;

    // Clock generation
    initial begin
        i_clk = 1'b1;
        forever #(CLK_PERIOD/2) i_clk = ~i_clk;
    end

    // DUT instantiation
    htd #(
        .DATA_WIDTH(DATA_WIDTH)
    ) htd_inst (
        .i_clk     (i_clk),
        .i_rst_n   (i_rst_n),
        .iv_data   (iv_data),
        .i_data_wr (i_data_wr),
        .ov_data   (ov_data),
        .o_data_wr (o_data_wr)
    );

    // Test stimulus
    initial begin
        // Initialize
        i_rst_n   <= 1'b0;
        iv_data   <= 8'h00;
        i_data_wr <= 1'b0;

        // Wait 100ns for global reset
        #10; i_rst_n <= 1'b1;
        #20;

        // Test cases: Send numbers 1 to 16
        repeat(6) begin
            iv_data   <= iv_data + 8'h01;  // 从1递增到16
            i_data_wr <= 1'b1;
            #10;
        end

        i_data_wr <= 1'b0;
        #10;

        repeat(6) begin
            iv_data   <= iv_data + 8'h01;  // 从1递增到16
            i_data_wr <= 1'b1;
            #10;
        end

        i_data_wr <= 1'b0;
        // End simulation
        #100;
        $finish;
    end

    // Monitor changes
    initial begin
        $monitor("Time=%0t rst_n=%0b data_wr=%0b iv_data=%0h ov_data=%0h o_data_wr=%0b",
                 $time, i_rst_n, i_data_wr, iv_data, ov_data, o_data_wr);
    end

    initial begin            
        $dumpfile("htd.vcd");        //生成的vcd文件名称
        $dumpvars(0, tb_htd);    //tb模块名称
    end

endmodule