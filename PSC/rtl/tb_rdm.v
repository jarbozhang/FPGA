`timescale 1ns/1ns

module tb_rdm();
    // Parameters
    parameter CLK_PERIOD = 10;

    // Signals
    reg        i_clk;
    reg        i_rst_n;
    reg        i_fifo_empty;
    reg        i_fifo_ae;
    reg  [7:0] iv_fifo_data;
    wire       o_fifo_rd;
    wire [7:0] ov_data;
    wire       o_data_wr;

    // Clock generation
    initial begin
        i_clk = 1'b1;
        forever #(CLK_PERIOD/2) i_clk = ~i_clk;
    end

    // DUT instantiation
    rdm u_rdm (
        .i_clk     (i_clk),
        .i_rst_n   (i_rst_n),
        .i_fifo_empty (i_fifo_empty),
        .i_fifo_ae  (i_fifo_ae),
        .iv_fifo_data (iv_fifo_data),
        .o_fifo_rd  (o_fifo_rd),
        .ov_data    (ov_data),
        .o_data_wr  (o_data_wr)
    );  

    // Test stimulus
    initial begin
        // Initialize
        i_rst_n   <= 1'b0;
        i_fifo_empty <= 1'b1;
        i_fifo_ae <= 1'b1;
        iv_fifo_data <= 8'h00;

        #(CLK_PERIOD);

        i_rst_n <= 1'b1;

        #(CLK_PERIOD);

        // Test cases: Send numbers 1 to 16
        repeat(16) begin
            iv_fifo_data <= iv_fifo_data + 8'h01;
            i_fifo_empty <= 1'b0;
            i_fifo_ae <= 1'b0;
            #(CLK_PERIOD);
        end

        i_fifo_ae <= 1'b1;
        iv_fifo_data <= iv_fifo_data + 8'h01;

        #(CLK_PERIOD);
        i_fifo_empty <= 1'b1;

        // End simulation
        #(CLK_PERIOD*20);
        $finish;
    end

    // Monitor changes
    // initial begin
    //     $monitor("Time=%0t rst_n=%0b data_wr=%0b iv_data=%0h ov_data=%0h o_data_wr=%0b",
    //              $time, i_rst_n, i_data_wr, iv_data, ov_data, o_data_wr);
    // end

endmodule