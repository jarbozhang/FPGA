module pip #(parameter DATA_WIDTH = 9)(
    input wire i_clk,
    input wire i_rst_n,
    input wire [DATA_WIDTH-1:0] iv_data,
    input wire i_data_wr,
    output wire [DATA_WIDTH-1:0] ov_data,
    output wire o_data_wr
);


parameter IDLE_S = 2'd0;
parameter CHECK_S = 2'd1;
parameter TRANS_S = 2'd2;
parameter TAIL_S = 2'd3;

parameter CHECK_HEAD_LENGTH = 14;

parameter TSMP_TYPE_NONE = 9'h000;
parameter TSMP_TYPE_READ = 9'h001;
parameter TSMP_TYPE_WRITE = 9'h002;
parameter TSMP_TYPE_CONFIG = 9'h003;


reg [1:0] st_current;
reg [3:0] check_head_counter_reg;
reg [1:0] check_type_reg;
reg [(CHECK_HEAD_LENGTH-1)*DATA_WIDTH-1:0] shift_reg;

reg [DATA_WIDTH-1:0] ov_data_reg;
reg o_data_wr_reg;

always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        st_current <= IDLE_S;
        ov_data_reg <= {DATA_WIDTH{1'b0}};
        o_data_wr_reg <= 1'b0;
        shift_reg <= {(CHECK_HEAD_LENGTH-1)*DATA_WIDTH{1'b0}};
        check_head_counter_reg <= 4'd0;
        check_type_reg <= TSMP_TYPE_NONE;
    end else begin
        case (st_current)
            IDLE_S: begin
                o_data_wr_reg <= 1'b0;
                if (i_data_wr && iv_data[DATA_WIDTH-1] == 1'b1) begin
                    st_current <= CHECK_S;
                    shift_reg <= {shift_reg[((CHECK_HEAD_LENGTH-1)*DATA_WIDTH-1):0], iv_data};
                    check_head_counter_reg <= check_head_counter_reg + 1;
                end else begin
                    st_current <= IDLE_S;
                    shift_reg <= {(CHECK_HEAD_LENGTH-1)*DATA_WIDTH{1'b0}};
                    check_head_counter_reg <= 4'd0;
                    check_type_reg <= TSMP_TYPE_NONE;
                end
            end
            CHECK_S: begin
                o_data_wr_reg <= 1'b0;
                shift_reg <= {shift_reg[((CHECK_HEAD_LENGTH-1)*DATA_WIDTH-1):0], iv_data};
                if (check_head_counter_reg < CHECK_HEAD_LENGTH - 1) begin // 为了防止最后一拍的时候（第14拍）跳转，会丢失一拍iv_data的问题，所以提前一拍跳转
                    st_current <= CHECK_S;
                    check_head_counter_reg <= check_head_counter_reg + 1;
                end else begin
                    if (shift_reg[DATA_WIDTH-1:0] == 9'h0ff && iv_data[DATA_WIDTH-1:0] == 9'h001) begin // 提前一拍跳转，所以需要判断当前iv_data是否为9'h001,来判断是否为TSMP报文
                        st_current <= TRANS_S;
                        check_head_counter_reg <= 4'd0;
                        check_type_reg <= shift_reg[((CHECK_HEAD_LENGTH-2)*DATA_WIDTH-1):(CHECK_HEAD_LENGTH-3)*DATA_WIDTH]; //由于是提前一拍跳转，所以需要判断shift_reg的最左侧2-3个byte，来判断TSMP报文的类型
                    end else begin
                        st_current <= TRANS_S; // 不是TSMP报文，但有可能下次碰到的是尾拍的高位1，IDLE_S状态判断会有问题，所以还是需要跳转到TRANS_S继续处理，后续根据check_type_reg来判断输出信号
                    end
                end
            end
            TRANS_S: begin
                shift_reg <= {shift_reg[((CHECK_HEAD_LENGTH-1)*DATA_WIDTH-1):0], iv_data};
                ov_data_reg <= shift_reg[(CHECK_HEAD_LENGTH-1)*DATA_WIDTH-1:(CHECK_HEAD_LENGTH-2)*DATA_WIDTH];
                o_data_wr_reg <= 1'b1;
                if (iv_data[DATA_WIDTH-1] == 1'b1) begin
                    st_current <= TAIL_S;
                end else begin
                    st_current <= TRANS_S;
                end
            end
            TAIL_S: begin
                shift_reg <= {shift_reg[((CHECK_HEAD_LENGTH-1)*DATA_WIDTH-1):0], iv_data};
                ov_data_reg <= shift_reg[(CHECK_HEAD_LENGTH-1)*DATA_WIDTH-1:(CHECK_HEAD_LENGTH-2)*DATA_WIDTH];
                o_data_wr_reg <= 1'b1;
                    
                if (check_head_counter_reg > 0) begin
                    check_head_counter_reg <= check_head_counter_reg + 1;
                end else if (iv_data[DATA_WIDTH-1] == 1'b1 && i_data_wr == 1'b1) begin
                    check_head_counter_reg <= 1;
                end
                if (ov_data_reg[DATA_WIDTH-1] == 1'b1) begin
                    if (check_head_counter_reg > 0) begin
                        st_current <= CHECK_S;
                    end 
                    else if (iv_data[DATA_WIDTH-1] == 1'b1 && i_data_wr == 1'b1) begin
                        // 用以解决移位寄存器中跳转的同时iv_data新数据到来的情况
                        st_current <= CHECK_S;
                    end 
                    else begin
                        st_current <= IDLE_S;
                    end
                end else begin
                    st_current <= TAIL_S;
                end
            end
        endcase
    end
end

assign ov_data = ov_data_reg;
assign o_data_wr = o_data_wr_reg;

endmodule