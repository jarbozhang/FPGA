module pip #(parameter DATA_WIDTH = 9)(
    input wire i_clk,
    input wire i_rst_n,
    input wire [DATA_WIDTH-1:0] iv_data,
    input wire i_data_wr,
    output wire [DATA_WIDTH-1:0] wv_data_pip2hcp,
    output wire w_data_wr_pip2hcp,
    output wire [DATA_WIDTH-1:0] wv_data_pip2plc,
    output wire w_data_wr_pip2plc
);


parameter IDLE_S = 2'd0;
parameter CHECK_S = 2'd1;
parameter TRANS_S = 2'd2;
parameter TAIL_S = 2'd3;

parameter CHECK_HEAD_LENGTH = 14;

parameter TSMP_TYPE_NONE = 8'hff;
parameter TSMP_TYPE_READ = 8'h00;
parameter TSMP_TYPE_WRITE = 8'h01;
parameter TSMP_TYPE_CONFIG = 8'h16;


reg [1:0] st_current;
reg [3:0] check_head_counter_reg;
reg [7:0] check_type_reg;
reg check_is_tsmp_reg;
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
        check_is_tsmp_reg <= 0;
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
                    check_is_tsmp_reg <= 0;
                end
            end
            CHECK_S: begin
                shift_reg <= {shift_reg[((CHECK_HEAD_LENGTH-1)*DATA_WIDTH-1):0], iv_data};
                if (check_head_counter_reg < CHECK_HEAD_LENGTH - 1) begin // 为了防止最后一拍的时候（第14拍）跳转，会丢失一拍iv_data的问题，所以提前一拍跳转
                    st_current <= CHECK_S;
                    check_head_counter_reg <= check_head_counter_reg + 1;
                end else begin
                    check_head_counter_reg <= 4'd0;
                    st_current <= TRANS_S;
                    check_type_reg <= shift_reg[((CHECK_HEAD_LENGTH-2)*DATA_WIDTH-1):(CHECK_HEAD_LENGTH-3)*DATA_WIDTH]; //由于是提前一拍跳转，所以需要判断shift_reg的最左侧2-3个byte，来判断TSMP报文的类型
                    ov_data_reg <= shift_reg[(CHECK_HEAD_LENGTH-1)*DATA_WIDTH-1:(CHECK_HEAD_LENGTH-2)*DATA_WIDTH];
                    if (shift_reg[DATA_WIDTH-1:0] == 9'h0ff && iv_data[DATA_WIDTH-1:0] == 9'h001) begin // 提前一拍跳转，所以需要判断当前iv_data是否为9'h001,来判断是否为TSMP报文
                        check_is_tsmp_reg <= 1;
                        o_data_wr_reg <= 1'b1;
                    end 
                end
            end
            TRANS_S: begin
                shift_reg <= {shift_reg[((CHECK_HEAD_LENGTH-1)*DATA_WIDTH-1):0], iv_data};
                ov_data_reg <= shift_reg[(CHECK_HEAD_LENGTH-1)*DATA_WIDTH-1:(CHECK_HEAD_LENGTH-2)*DATA_WIDTH];
                if (check_is_tsmp_reg == 1) begin
                    o_data_wr_reg <= 1'b1;
                end
                if (iv_data[DATA_WIDTH-1] == 1'b1) begin
                    st_current <= TAIL_S;
                end else begin
                    st_current <= TRANS_S;
                end
            end
            TAIL_S: begin
                shift_reg <= {shift_reg[((CHECK_HEAD_LENGTH-1)*DATA_WIDTH-1):0], iv_data};
                ov_data_reg <= shift_reg[(CHECK_HEAD_LENGTH-1)*DATA_WIDTH-1:(CHECK_HEAD_LENGTH-2)*DATA_WIDTH];
                if (check_is_tsmp_reg == 1) begin
                    o_data_wr_reg <= 1'b1;
                end
                if (check_head_counter_reg > 0) begin
                    check_head_counter_reg <= check_head_counter_reg + 1;
                end else if (iv_data[DATA_WIDTH-1] == 1'b1 && i_data_wr == 1'b1) begin
                    check_head_counter_reg <= 1;
                end
                // 此时开始通过这一拍决定跳转到哪个状态
                if (ov_data_reg[DATA_WIDTH-1] == 1'b1) begin
                    o_data_wr_reg <= 1'b0;
                    check_is_tsmp_reg <= 0;
                    // 如果check_head_counter_reg > 0，则说明shift_reg缓冲区中同时存在前后两个报文(可能紧挨，可能中间间隔几拍)
                    if (check_head_counter_reg > 0) begin
                        st_current <= CHECK_S;
                        // shift_reg中如果最右侧的值是9'h0ff，同时iv_data的值是9'h001，则说明是TSMP报文，同时两个报文中间没有间隔
                        if (shift_reg[DATA_WIDTH-1:0] == 9'h0ff && iv_data[DATA_WIDTH-1:0] == 9'h001) begin
                            check_is_tsmp_reg <= 1;
                            o_data_wr_reg <= 1'b1;
                            check_type_reg <= shift_reg[((CHECK_HEAD_LENGTH-2)*DATA_WIDTH-1):(CHECK_HEAD_LENGTH-3)*DATA_WIDTH]; 
                            st_current <= TRANS_S;
                        end
                        else begin
                            st_current <= CHECK_S;
                        end
                    end 
                    // 用以解决移位寄存器中跳转的同时iv_data新数据到来的情况
                    else if (iv_data[DATA_WIDTH-1] == 1'b1 && i_data_wr == 1'b1) begin
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

assign wv_data_pip2hcp = check_is_tsmp_reg ? ov_data_reg : 9'h000;
assign w_data_wr_pip2hcp = o_data_wr_reg && (check_type_reg == TSMP_TYPE_READ || check_type_reg == TSMP_TYPE_WRITE);
assign wv_data_pip2plc = check_is_tsmp_reg ? ov_data_reg : 9'h000;
assign w_data_wr_pip2plc = o_data_wr_reg && check_type_reg == TSMP_TYPE_CONFIG;

endmodule