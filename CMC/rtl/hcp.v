module hcp #(parameter DATA_WIDTH = 9)(
    input i_clk,
    input i_rst_n,
    input [DATA_WIDTH-1:0] iv_data,
    input i_data_wr
    //output wire [31:0] q_a,
    //output wire [5:0] address_a
);

parameter GET_ADDR_LENGTH = 24;
parameter DATA_WIDTH_REG = 8;

parameter IDLE_S = 2'd0;
parameter GET_ADDR_S = 2'd1;
parameter READ_S = 2'd2;
parameter WRITE_S = 2'd3;

parameter TSMP_TYPE_NONE = 8'hff;
parameter TSMP_TYPE_READ = 8'h00;
parameter TSMP_TYPE_WRITE = 8'h01;
parameter TSMP_TYPE_CONFIG = 8'h16;

reg [1:0] st_current;
reg [GET_ADDR_LENGTH*DATA_WIDTH_REG-1:0] shift_reg;
reg [4:0] check_addr_counter_reg;
reg [5:0] address_reg;
reg [5:0] num_reg;
reg [1:0] data_counter_reg;
reg [31:0] rv_data_reg;
reg [7:0] tsmp_type_reg;


always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        st_current <= IDLE_S;
        shift_reg <= {GET_ADDR_LENGTH*DATA_WIDTH_REG{1'b0}};
        check_addr_counter_reg <= 4'd0;
        data_counter_reg <= 2'd0;
        address_reg <= 6'd0;
        num_reg <= 6'd0;
        rv_data_reg <= 32'd0;
        tsmp_type_reg <= 8'd0;
    end else begin
        case (st_current)
            IDLE_S: begin
                if (i_data_wr && iv_data[DATA_WIDTH-1] == 1'b1) begin
                    st_current <= GET_ADDR_S;
                    shift_reg <= {shift_reg[(GET_ADDR_LENGTH-1)*DATA_WIDTH_REG-1:0], iv_data[DATA_WIDTH_REG-1:0]};
                    check_addr_counter_reg <= check_addr_counter_reg + 1;
                end else begin
                    st_current <= IDLE_S;
                    shift_reg <= {GET_ADDR_LENGTH*DATA_WIDTH_REG{1'b0}};
                    check_addr_counter_reg <= 5'd0;
                end
            end
            GET_ADDR_S: begin
                shift_reg <= {shift_reg[(GET_ADDR_LENGTH-1)*DATA_WIDTH_REG-1:0], iv_data[DATA_WIDTH_REG-1:0]};
                if (check_addr_counter_reg < GET_ADDR_LENGTH - 1) begin // 为了防止最后一拍的时候跳转，会丢失一拍iv_data的问题，所以提前一拍跳转
                    st_current <= GET_ADDR_S;
                    check_addr_counter_reg <= check_addr_counter_reg + 1;
                end else begin
                    check_addr_counter_reg <= 5'd0;
                    tsmp_type_reg <= shift_reg[((GET_ADDR_LENGTH-2)*DATA_WIDTH_REG-1):(GET_ADDR_LENGTH-3)*DATA_WIDTH_REG];
                    //首先查看shift_reg中左侧的第2个byte,来判断是读报文还是写报文
                    //如果为读报文或者写报文，则将地址和数量分别赋值给address_reg和num_reg,地址是iv_data，数量是
                    if (shift_reg[((GET_ADDR_LENGTH-2)*DATA_WIDTH_REG-1):(GET_ADDR_LENGTH-3)*DATA_WIDTH_REG] == TSMP_TYPE_READ) begin 
                        st_current <= READ_S;
                        address_reg <= iv_data[5:0];
                        num_reg <= shift_reg[DATA_WIDTH_REG*7-1:DATA_WIDTH_REG*5-1];
                        shift_reg <= {GET_ADDR_LENGTH*DATA_WIDTH_REG{1'b0}};
                        rv_data_reg <= iv_data[DATA_WIDTH-1:0];
                    end else if (shift_reg[((GET_ADDR_LENGTH-2)*DATA_WIDTH_REG-1):(GET_ADDR_LENGTH-3)*DATA_WIDTH_REG] == TSMP_TYPE_WRITE) begin
                        st_current <= WRITE_S;
                        address_reg <= iv_data[5:0];
                        num_reg <= shift_reg[DATA_WIDTH_REG*7-1:DATA_WIDTH_REG*5];
                        shift_reg <= {GET_ADDR_LENGTH*DATA_WIDTH_REG{1'b0}};
                        rv_data_reg <= iv_data[DATA_WIDTH-1:0];
                    end else begin
                        st_current <= IDLE_S;
                    end
                end
            end
            READ_S: begin
                st_current <= READ_S;
                if (num_reg == 0) begin
                    st_current <= IDLE_S;
                end 
                // 设置计数器，每四拍组装成一个32位的数据
                if (data_counter_reg < 4) begin
                    data_counter_reg <= data_counter_reg + 1;
                    rv_data_reg <= {rv_data_reg[(DATA_WIDTH-2)*3-1:0], iv_data[DATA_WIDTH-2:0]};
                end else begin
                    data_counter_reg <= 2'd0;
                    rv_data_reg <= iv_data[DATA_WIDTH-2:0];
                    address_reg <= address_reg + 1;
                    num_reg <= num_reg - 1;
                end
            end
            WRITE_S: begin
                st_current <= WRITE_S;
                // 设置计数器，每四拍组装成一个32位的数据
                if (num_reg == 0) begin
                    st_current <= IDLE_S;
                    rv_data_reg <= 32'd0;
                    data_counter_reg <= 2'd0;
                    address_reg <= 6'd0;
                end else begin
                    if (data_counter_reg < 3) begin
                        data_counter_reg <= data_counter_reg + 1;
                        rv_data_reg <= {rv_data_reg[(DATA_WIDTH-1)*3-1:0], iv_data[DATA_WIDTH-2:0]};
                    end else begin
                        data_counter_reg <= 2'd0;
                        rv_data_reg <= iv_data[DATA_WIDTH-2:0];
                        address_reg <= address_reg + 1;
                        num_reg <= num_reg - 1;
                    end
                end
            end
        endcase
    end
end

endmodule