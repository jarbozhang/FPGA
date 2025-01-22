module psc (
  input   wire        i_clk,
  input   wire        i_rst_n,
  input   wire [7:0]  iv_data,
  input   wire        i_data_wr,
  output  wire [8:0]  ov_data,
  output  wire        o_data_wr
);
  wire [7:0] wv_data_dly2htd;
  wire       w_wr_dly2htd;

  cdc cdc_inst(
    .i_clk(i_clk),
    .i_rst_n(i_rst_n),
    .iv_data(iv_data),
    .i_data_wr(i_data_wr),
    .ov_data(wv_data_dly2htd),
    .o_data_wr(w_wr_dly2htd)
  );

  htd #(
    .DATA_WIDTH(8)
  ) htd_inst(
    .i_clk(i_clk),
    .i_rst_n(i_rst_n),
    .iv_data(wv_data_dly2htd),
    .i_data_wr(w_wr_dly2htd),
    .ov_data(ov_data),
    .o_data_wr(o_data_wr)
  );
    

endmodule

