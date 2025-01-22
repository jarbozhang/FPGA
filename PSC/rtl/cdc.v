module cdc (input wire i_clk,
            input wire i_rst_n,
            input wire [7:0] iv_data,
            input wire i_data_wr,
            output wire [7:0] ov_data,
            output wire o_data_wr);

    wire w_fifo_empty_fifo2rdm;
    wire w_fifo_ae_fifo2rdm;
    wire w_fifo_rd_rdm2fifo;
    wire [7:0] wv_data_fifo2rdm;
    
    syncfifo_showahead_sclr_w8d64 fifo_inst (
        .clock(i_clk),
        .data(iv_data),
        .wrreq(i_data_wr),
        .rdreq(w_fifo_rd_rdm2fifo),
        .q(wv_data_fifo2rdm),
        .empty(w_fifo_empty_fifo2rdm),
        .almost_empty(w_fifo_ae_fifo2rdm)
    );

    rdm rdm_inst (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_fifo_empty(w_fifo_empty_fifo2rdm),
        .i_fifo_ae(w_fifo_ae_fifo2rdm),
        .iv_fifo_data(wv_data_fifo2rdm),
        .o_fifo_rd(w_fifo_rd_rdm2fifo),
        .ov_data(ov_data),
        .o_data_wr(o_data_wr)
    );
endmodule
