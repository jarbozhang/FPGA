module delay (input wire i_clk,
              input wire i_rst_n,
              input wire [7:0] iv_data,
              input wire i_data_wr,
              output wire [7:0] ov_data,
              output wire o_data_wr);
    reg [7:0] ov_reg1;
    reg [7:0] ov_reg2;
    reg       o_data_wr_reg;
    reg       o_data_wr_reg2;
    
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            ov_reg1        <= 8'b0;
            ov_reg2        <= 8'b0;
            o_data_wr_reg  <= 1'b0;
            o_data_wr_reg2 <= 1'b0;
            end else begin
            ov_reg1        <= iv_data;
            ov_reg2        <= ov_reg1;
            o_data_wr_reg  <= i_data_wr;
            o_data_wr_reg2 <= o_data_wr_reg;
        end
    end
    
    assign ov_data   = ov_reg2;
    assign o_data_wr = o_data_wr_reg2;
    
endmodule
