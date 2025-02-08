`include "../ipcore/tdpr_singleclock_rdenab_outputaclrab_w32d64.v"

module hcp #(parameter DATA_WIDTH = 9)(
    input i_clk,
    input i_rst_n,
    input [DATA_WIDTH-1:0] iv_data,
    input i_data_wr
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
reg o_ram_wren;
reg o_ram_rden;
wire [31:0] o_a_ram_data;
wire [31:0] o_b_ram_data;


// 实例化RAM IP核
tdpr_singleclock_rdenab_outputaclrab_w32d64 ram_inst (
    .address_a(address_reg),     // 写地址
    .data_a(rv_data_reg),        // 写数据
    .wren_a(o_ram_wren),        // 写使能
    .rden_a(o_ram_rden),             // 读使能
    .clock(i_clk),              // 共享时钟
    .address_b(6'd0),          // 端口B未使用
    .data_b(32'd0),
    .wren_b(1'b0),
    .rden_b(1'b0),
    .q_a(o_a_ram_data),                     // 读数据暂不连接
    .q_b(o_b_ram_data)
);




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
        o_ram_wren <= 1'b0;    // 复位写使能
        o_ram_rden <= 1'b0;
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
                    //如果为读报文或者写报文，则将地址和数量分别赋值给address_reg和num_reg,地址是iv_data，数量是倒数第5-7个byte
                    if (shift_reg[((GET_ADDR_LENGTH-2)*DATA_WIDTH_REG-1):(GET_ADDR_LENGTH-3)*DATA_WIDTH_REG] == TSMP_TYPE_READ) begin 
                        st_current <= READ_S;
                        address_reg <= iv_data[5:0];
                        num_reg <= shift_reg[DATA_WIDTH_REG*7-1:DATA_WIDTH_REG*5];
                        shift_reg <= {GET_ADDR_LENGTH*DATA_WIDTH_REG{1'b0}};
                        o_ram_rden <= 1'b1;
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
                if (num_reg == 1) begin
                    data_counter_reg <= 2'd0;
                    address_reg <= 6'd0;
                    o_ram_rden <= 1'b0;  // 结束读操作
                    if(iv_data[DATA_WIDTH-1] == 1'b1) begin
                        st_current <= IDLE_S;
                    end else begin
                        st_current <= READ_S;
                    end
                end else begin
                    address_reg <= address_reg + 1;
                    num_reg <= num_reg - 1;
                    o_ram_rden <= 1'b1;
                end
            end
            WRITE_S: begin
                st_current <= WRITE_S;
                if (num_reg == 0) begin
                    rv_data_reg <= 32'd0;
                    data_counter_reg <= 2'd0;
                    address_reg <= 6'd0;
                    o_ram_wren <= 1'b0;  // 结束写操作
                    if(iv_data[DATA_WIDTH-1] == 1'b1) begin
                        st_current <= IDLE_S;
                    end else begin
                        st_current <= WRITE_S;
                    end
                end else begin
                    if (data_counter_reg < 3) begin
                        data_counter_reg <= data_counter_reg + 1;
                        rv_data_reg <= {rv_data_reg[(DATA_WIDTH-1)*3-1:0], iv_data[DATA_WIDTH-2:0]};
                        if (data_counter_reg == 2) begin
                            o_ram_wren <= 1'b1;  // 触发写操作
                        end else begin
                            o_ram_wren <= 1'b0;  // 数据未就绪时不写
                        end
                    end else begin
                        data_counter_reg <= 2'd0;
                        rv_data_reg <= iv_data[DATA_WIDTH-2:0];
                        address_reg <= address_reg + 1;
                        num_reg <= num_reg - 1;
                        o_ram_wren <= 1'b0;  // 触发写结束
                    end
                end
            end
        endcase
    end
end

endmodule