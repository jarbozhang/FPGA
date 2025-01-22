module rdm (input wire i_clk,
            input wire i_rst_n,
            input wire i_fifo_empty,       // fifo empty
            input wire i_fifo_ae,          // fifo almost empty
            input wire [7:0] iv_fifo_data, // fifo data
            output wire o_fifo_rd,         // fifo read
            output wire [7:0] ov_data,     // data
            output wire o_data_wr);        // data write
    
    parameter IDLE = 1'b0;
    parameter READ = 1'b1;
    
    reg r_state;
    reg [7:0] ov_data_reg;
    reg       o_data_wr_reg;
    reg       o_fifo_rd_reg;
    
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            r_state   <= IDLE;
            ov_data_reg <= 8'b0;
            o_data_wr_reg <= 1'b0;
            o_fifo_rd_reg <= 1'b0;
        end else begin
            case (r_state)
                IDLE: begin
                    if (!i_fifo_empty) begin
                        o_fifo_rd_reg <= 1'b1;
                        r_state <= READ;
                    end else begin
                        o_fifo_rd_reg <= 1'b0;
                        o_data_wr_reg <= 1'b0;
                        r_state <= IDLE;
                    end
                end
                READ: begin
                    ov_data_reg <= iv_fifo_data;
                    o_data_wr_reg <= 1'b1;
                    if (i_fifo_ae && !i_fifo_empty) begin
                        o_fifo_rd_reg <= 1'b0;
                        r_state <= IDLE;
                    end else begin
                        o_fifo_rd_reg <= 1'b1;
                    end
                end
                default: begin
                    o_fifo_rd_reg <= 1'b0;
                    o_data_wr_reg <= 1'b0;
                    r_state <= IDLE;
                end
            endcase
        end
    end
        
    assign ov_data   = ov_data_reg;
    assign o_data_wr = o_data_wr_reg;
    assign o_fifo_rd = o_fifo_rd_reg;

endmodule
