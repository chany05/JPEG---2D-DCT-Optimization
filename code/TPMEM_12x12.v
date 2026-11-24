
// TPMEM_2: 12행×12bit (16→12 행 축소, 입출력도 12*BW)
// 2nd DCT 유효 출력 12개(y0~y11)만 저장, 타이밍 제어는 원본과 동일
module TPmem_12x12_single_2nd
#( parameter BW = 12 )
(  input        [12*BW-1:0] i_data,
   input                    i_clk,
   input                    i_Reset,
   output reg   [12*BW-1:0] o_data,
   output reg               o_en
);

reg  [5-1:0]      counter;
reg  [12*BW-1:0]  array [12-1:0];
reg  [12*BW-1:0]  data_out;
wire [12*BW-1:0]  col   [12-1:0];
wire [4-1:0]      index = counter[4-1:0];
wire [12*BW-1:0]  w_data;
wire              w_en;

always@(posedge i_clk) begin
    if(~i_Reset) begin
        counter <= 5'd14;
        o_data  <= {12*BW{1'b0}};
        o_en    <= 1'b0;
    end else begin
        o_data  <= w_data;
        o_en    <= w_en;
        counter <= counter + 5'b1;
    end
end

always@(*) begin
    if (counter[4]==1'b0)
        data_out = array[index];
    else
        data_out = col[index];
end

always@(posedge i_clk) begin
    if(~i_Reset) begin
        array[ 0] <= {12*BW{1'b0}};
        array[ 1] <= {12*BW{1'b0}};
        array[ 2] <= {12*BW{1'b0}};
        array[ 3] <= {12*BW{1'b0}};
        array[ 4] <= {12*BW{1'b0}};
        array[ 5] <= {12*BW{1'b0}};
        array[ 6] <= {12*BW{1'b0}};
        array[ 7] <= {12*BW{1'b0}};
        array[ 8] <= {12*BW{1'b0}};
        array[ 9] <= {12*BW{1'b0}};
        array[10] <= {12*BW{1'b0}};
        array[11] <= {12*BW{1'b0}};
    end else begin
        if (counter[4]==1'b0) begin
            array[index] <= i_data;
        end else begin
            case (index)
            4'd0: begin
                array[ 0][12*BW-1:11*BW] <= i_data[12*BW-1:11*BW];
                array[ 1][12*BW-1:11*BW] <= i_data[11*BW-1:10*BW];
                array[ 2][12*BW-1:11*BW] <= i_data[10*BW-1: 9*BW];
                array[ 3][12*BW-1:11*BW] <= i_data[ 9*BW-1: 8*BW];
                array[ 4][12*BW-1:11*BW] <= i_data[ 8*BW-1: 7*BW];
                array[ 5][12*BW-1:11*BW] <= i_data[ 7*BW-1: 6*BW];
                array[ 6][12*BW-1:11*BW] <= i_data[ 6*BW-1: 5*BW];
                array[ 7][12*BW-1:11*BW] <= i_data[ 5*BW-1: 4*BW];
                array[ 8][12*BW-1:11*BW] <= i_data[ 4*BW-1: 3*BW];
                array[ 9][12*BW-1:11*BW] <= i_data[ 3*BW-1: 2*BW];
                array[10][12*BW-1:11*BW] <= i_data[ 2*BW-1: 1*BW];
                array[11][12*BW-1:11*BW] <= i_data[ 1*BW-1: 0*BW];
            end
            4'd1: begin
                array[ 0][11*BW-1:10*BW] <= i_data[12*BW-1:11*BW];
                array[ 1][11*BW-1:10*BW] <= i_data[11*BW-1:10*BW];
                array[ 2][11*BW-1:10*BW] <= i_data[10*BW-1: 9*BW];
                array[ 3][11*BW-1:10*BW] <= i_data[ 9*BW-1: 8*BW];
                array[ 4][11*BW-1:10*BW] <= i_data[ 8*BW-1: 7*BW];
                array[ 5][11*BW-1:10*BW] <= i_data[ 7*BW-1: 6*BW];
                array[ 6][11*BW-1:10*BW] <= i_data[ 6*BW-1: 5*BW];
                array[ 7][11*BW-1:10*BW] <= i_data[ 5*BW-1: 4*BW];
                array[ 8][11*BW-1:10*BW] <= i_data[ 4*BW-1: 3*BW];
                array[ 9][11*BW-1:10*BW] <= i_data[ 3*BW-1: 2*BW];
                array[10][11*BW-1:10*BW] <= i_data[ 2*BW-1: 1*BW];
                array[11][11*BW-1:10*BW] <= i_data[ 1*BW-1: 0*BW];
            end
            4'd2: begin
                array[ 0][10*BW-1: 9*BW] <= i_data[12*BW-1:11*BW];
                array[ 1][10*BW-1: 9*BW] <= i_data[11*BW-1:10*BW];
                array[ 2][10*BW-1: 9*BW] <= i_data[10*BW-1: 9*BW];
                array[ 3][10*BW-1: 9*BW] <= i_data[ 9*BW-1: 8*BW];
                array[ 4][10*BW-1: 9*BW] <= i_data[ 8*BW-1: 7*BW];
                array[ 5][10*BW-1: 9*BW] <= i_data[ 7*BW-1: 6*BW];
                array[ 6][10*BW-1: 9*BW] <= i_data[ 6*BW-1: 5*BW];
                array[ 7][10*BW-1: 9*BW] <= i_data[ 5*BW-1: 4*BW];
                array[ 8][10*BW-1: 9*BW] <= i_data[ 4*BW-1: 3*BW];
                array[ 9][10*BW-1: 9*BW] <= i_data[ 3*BW-1: 2*BW];
                array[10][10*BW-1: 9*BW] <= i_data[ 2*BW-1: 1*BW];
                array[11][10*BW-1: 9*BW] <= i_data[ 1*BW-1: 0*BW];
            end
            4'd3: begin
                array[ 0][ 9*BW-1: 8*BW] <= i_data[12*BW-1:11*BW];
                array[ 1][ 9*BW-1: 8*BW] <= i_data[11*BW-1:10*BW];
                array[ 2][ 9*BW-1: 8*BW] <= i_data[10*BW-1: 9*BW];
                array[ 3][ 9*BW-1: 8*BW] <= i_data[ 9*BW-1: 8*BW];
                array[ 4][ 9*BW-1: 8*BW] <= i_data[ 8*BW-1: 7*BW];
                array[ 5][ 9*BW-1: 8*BW] <= i_data[ 7*BW-1: 6*BW];
                array[ 6][ 9*BW-1: 8*BW] <= i_data[ 6*BW-1: 5*BW];
                array[ 7][ 9*BW-1: 8*BW] <= i_data[ 5*BW-1: 4*BW];
                array[ 8][ 9*BW-1: 8*BW] <= i_data[ 4*BW-1: 3*BW];
                array[ 9][ 9*BW-1: 8*BW] <= i_data[ 3*BW-1: 2*BW];
                array[10][ 9*BW-1: 8*BW] <= i_data[ 2*BW-1: 1*BW];
                array[11][ 9*BW-1: 8*BW] <= i_data[ 1*BW-1: 0*BW];
            end
            4'd4: begin
                array[ 0][ 8*BW-1: 7*BW] <= i_data[12*BW-1:11*BW];
                array[ 1][ 8*BW-1: 7*BW] <= i_data[11*BW-1:10*BW];
                array[ 2][ 8*BW-1: 7*BW] <= i_data[10*BW-1: 9*BW];
                array[ 3][ 8*BW-1: 7*BW] <= i_data[ 9*BW-1: 8*BW];
                array[ 4][ 8*BW-1: 7*BW] <= i_data[ 8*BW-1: 7*BW];
                array[ 5][ 8*BW-1: 7*BW] <= i_data[ 7*BW-1: 6*BW];
                array[ 6][ 8*BW-1: 7*BW] <= i_data[ 6*BW-1: 5*BW];
                array[ 7][ 8*BW-1: 7*BW] <= i_data[ 5*BW-1: 4*BW];
                array[ 8][ 8*BW-1: 7*BW] <= i_data[ 4*BW-1: 3*BW];
                array[ 9][ 8*BW-1: 7*BW] <= i_data[ 3*BW-1: 2*BW];
                array[10][ 8*BW-1: 7*BW] <= i_data[ 2*BW-1: 1*BW];
                array[11][ 8*BW-1: 7*BW] <= i_data[ 1*BW-1: 0*BW];
            end
            4'd5: begin
                array[ 0][ 7*BW-1: 6*BW] <= i_data[12*BW-1:11*BW];
                array[ 1][ 7*BW-1: 6*BW] <= i_data[11*BW-1:10*BW];
                array[ 2][ 7*BW-1: 6*BW] <= i_data[10*BW-1: 9*BW];
                array[ 3][ 7*BW-1: 6*BW] <= i_data[ 9*BW-1: 8*BW];
                array[ 4][ 7*BW-1: 6*BW] <= i_data[ 8*BW-1: 7*BW];
                array[ 5][ 7*BW-1: 6*BW] <= i_data[ 7*BW-1: 6*BW];
                array[ 6][ 7*BW-1: 6*BW] <= i_data[ 6*BW-1: 5*BW];
                array[ 7][ 7*BW-1: 6*BW] <= i_data[ 5*BW-1: 4*BW];
                array[ 8][ 7*BW-1: 6*BW] <= i_data[ 4*BW-1: 3*BW];
                array[ 9][ 7*BW-1: 6*BW] <= i_data[ 3*BW-1: 2*BW];
                array[10][ 7*BW-1: 6*BW] <= i_data[ 2*BW-1: 1*BW];
                array[11][ 7*BW-1: 6*BW] <= i_data[ 1*BW-1: 0*BW];
            end
            4'd6: begin
                array[ 0][ 6*BW-1: 5*BW] <= i_data[12*BW-1:11*BW];
                array[ 1][ 6*BW-1: 5*BW] <= i_data[11*BW-1:10*BW];
                array[ 2][ 6*BW-1: 5*BW] <= i_data[10*BW-1: 9*BW];
                array[ 3][ 6*BW-1: 5*BW] <= i_data[ 9*BW-1: 8*BW];
                array[ 4][ 6*BW-1: 5*BW] <= i_data[ 8*BW-1: 7*BW];
                array[ 5][ 6*BW-1: 5*BW] <= i_data[ 7*BW-1: 6*BW];
                array[ 6][ 6*BW-1: 5*BW] <= i_data[ 6*BW-1: 5*BW];
                array[ 7][ 6*BW-1: 5*BW] <= i_data[ 5*BW-1: 4*BW];
                array[ 8][ 6*BW-1: 5*BW] <= i_data[ 4*BW-1: 3*BW];
                array[ 9][ 6*BW-1: 5*BW] <= i_data[ 3*BW-1: 2*BW];
                array[10][ 6*BW-1: 5*BW] <= i_data[ 2*BW-1: 1*BW];
                array[11][ 6*BW-1: 5*BW] <= i_data[ 1*BW-1: 0*BW];
            end
            4'd7: begin
                array[ 0][ 5*BW-1: 4*BW] <= i_data[12*BW-1:11*BW];
                array[ 1][ 5*BW-1: 4*BW] <= i_data[11*BW-1:10*BW];
                array[ 2][ 5*BW-1: 4*BW] <= i_data[10*BW-1: 9*BW];
                array[ 3][ 5*BW-1: 4*BW] <= i_data[ 9*BW-1: 8*BW];
                array[ 4][ 5*BW-1: 4*BW] <= i_data[ 8*BW-1: 7*BW];
                array[ 5][ 5*BW-1: 4*BW] <= i_data[ 7*BW-1: 6*BW];
                array[ 6][ 5*BW-1: 4*BW] <= i_data[ 6*BW-1: 5*BW];
                array[ 7][ 5*BW-1: 4*BW] <= i_data[ 5*BW-1: 4*BW];
                array[ 8][ 5*BW-1: 4*BW] <= i_data[ 4*BW-1: 3*BW];
                array[ 9][ 5*BW-1: 4*BW] <= i_data[ 3*BW-1: 2*BW];
                array[10][ 5*BW-1: 4*BW] <= i_data[ 2*BW-1: 1*BW];
                array[11][ 5*BW-1: 4*BW] <= i_data[ 1*BW-1: 0*BW];
            end
            4'd8: begin
                array[ 0][ 4*BW-1: 3*BW] <= i_data[12*BW-1:11*BW];
                array[ 1][ 4*BW-1: 3*BW] <= i_data[11*BW-1:10*BW];
                array[ 2][ 4*BW-1: 3*BW] <= i_data[10*BW-1: 9*BW];
                array[ 3][ 4*BW-1: 3*BW] <= i_data[ 9*BW-1: 8*BW];
                array[ 4][ 4*BW-1: 3*BW] <= i_data[ 8*BW-1: 7*BW];
                array[ 5][ 4*BW-1: 3*BW] <= i_data[ 7*BW-1: 6*BW];
                array[ 6][ 4*BW-1: 3*BW] <= i_data[ 6*BW-1: 5*BW];
                array[ 7][ 4*BW-1: 3*BW] <= i_data[ 5*BW-1: 4*BW];
                array[ 8][ 4*BW-1: 3*BW] <= i_data[ 4*BW-1: 3*BW];
                array[ 9][ 4*BW-1: 3*BW] <= i_data[ 3*BW-1: 2*BW];
                array[10][ 4*BW-1: 3*BW] <= i_data[ 2*BW-1: 1*BW];
                array[11][ 4*BW-1: 3*BW] <= i_data[ 1*BW-1: 0*BW];
            end
            4'd9: begin
                array[ 0][ 3*BW-1: 2*BW] <= i_data[12*BW-1:11*BW];
                array[ 1][ 3*BW-1: 2*BW] <= i_data[11*BW-1:10*BW];
                array[ 2][ 3*BW-1: 2*BW] <= i_data[10*BW-1: 9*BW];
                array[ 3][ 3*BW-1: 2*BW] <= i_data[ 9*BW-1: 8*BW];
                array[ 4][ 3*BW-1: 2*BW] <= i_data[ 8*BW-1: 7*BW];
                array[ 5][ 3*BW-1: 2*BW] <= i_data[ 7*BW-1: 6*BW];
                array[ 6][ 3*BW-1: 2*BW] <= i_data[ 6*BW-1: 5*BW];
                array[ 7][ 3*BW-1: 2*BW] <= i_data[ 5*BW-1: 4*BW];
                array[ 8][ 3*BW-1: 2*BW] <= i_data[ 4*BW-1: 3*BW];
                array[ 9][ 3*BW-1: 2*BW] <= i_data[ 3*BW-1: 2*BW];
                array[10][ 3*BW-1: 2*BW] <= i_data[ 2*BW-1: 1*BW];
                array[11][ 3*BW-1: 2*BW] <= i_data[ 1*BW-1: 0*BW];
            end
            4'd10: begin
                array[ 0][ 2*BW-1: 1*BW] <= i_data[12*BW-1:11*BW];
                array[ 1][ 2*BW-1: 1*BW] <= i_data[11*BW-1:10*BW];
                array[ 2][ 2*BW-1: 1*BW] <= i_data[10*BW-1: 9*BW];
                array[ 3][ 2*BW-1: 1*BW] <= i_data[ 9*BW-1: 8*BW];
                array[ 4][ 2*BW-1: 1*BW] <= i_data[ 8*BW-1: 7*BW];
                array[ 5][ 2*BW-1: 1*BW] <= i_data[ 7*BW-1: 6*BW];
                array[ 6][ 2*BW-1: 1*BW] <= i_data[ 6*BW-1: 5*BW];
                array[ 7][ 2*BW-1: 1*BW] <= i_data[ 5*BW-1: 4*BW];
                array[ 8][ 2*BW-1: 1*BW] <= i_data[ 4*BW-1: 3*BW];
                array[ 9][ 2*BW-1: 1*BW] <= i_data[ 3*BW-1: 2*BW];
                array[10][ 2*BW-1: 1*BW] <= i_data[ 2*BW-1: 1*BW];
                array[11][ 2*BW-1: 1*BW] <= i_data[ 1*BW-1: 0*BW];
            end
            4'd11: begin
                array[ 0][ 1*BW-1: 0*BW] <= i_data[12*BW-1:11*BW];
                array[ 1][ 1*BW-1: 0*BW] <= i_data[11*BW-1:10*BW];
                array[ 2][ 1*BW-1: 0*BW] <= i_data[10*BW-1: 9*BW];
                array[ 3][ 1*BW-1: 0*BW] <= i_data[ 9*BW-1: 8*BW];
                array[ 4][ 1*BW-1: 0*BW] <= i_data[ 8*BW-1: 7*BW];
                array[ 5][ 1*BW-1: 0*BW] <= i_data[ 7*BW-1: 6*BW];
                array[ 6][ 1*BW-1: 0*BW] <= i_data[ 6*BW-1: 5*BW];
                array[ 7][ 1*BW-1: 0*BW] <= i_data[ 5*BW-1: 4*BW];
                array[ 8][ 1*BW-1: 0*BW] <= i_data[ 4*BW-1: 3*BW];
                array[ 9][ 1*BW-1: 0*BW] <= i_data[ 3*BW-1: 2*BW];
                array[10][ 1*BW-1: 0*BW] <= i_data[ 2*BW-1: 1*BW];
                array[11][ 1*BW-1: 0*BW] <= i_data[ 1*BW-1: 0*BW];
            end
            endcase
        end
    end
end

assign col[ 0] = {array[ 0][12*BW-1:11*BW], array[ 1][12*BW-1:11*BW], array[ 2][12*BW-1:11*BW], array[ 3][12*BW-1:11*BW], array[ 4][12*BW-1:11*BW], array[ 5][12*BW-1:11*BW], array[ 6][12*BW-1:11*BW], array[ 7][12*BW-1:11*BW], array[ 8][12*BW-1:11*BW], array[ 9][12*BW-1:11*BW], array[10][12*BW-1:11*BW], array[11][12*BW-1:11*BW]};
assign col[ 1] = {array[ 0][11*BW-1:10*BW], array[ 1][11*BW-1:10*BW], array[ 2][11*BW-1:10*BW], array[ 3][11*BW-1:10*BW], array[ 4][11*BW-1:10*BW], array[ 5][11*BW-1:10*BW], array[ 6][11*BW-1:10*BW], array[ 7][11*BW-1:10*BW], array[ 8][11*BW-1:10*BW], array[ 9][11*BW-1:10*BW], array[10][11*BW-1:10*BW], array[11][11*BW-1:10*BW]};
assign col[ 2] = {array[ 0][10*BW-1: 9*BW], array[ 1][10*BW-1: 9*BW], array[ 2][10*BW-1: 9*BW], array[ 3][10*BW-1: 9*BW], array[ 4][10*BW-1: 9*BW], array[ 5][10*BW-1: 9*BW], array[ 6][10*BW-1: 9*BW], array[ 7][10*BW-1: 9*BW], array[ 8][10*BW-1: 9*BW], array[ 9][10*BW-1: 9*BW], array[10][10*BW-1: 9*BW], array[11][10*BW-1: 9*BW]};
assign col[ 3] = {array[ 0][ 9*BW-1: 8*BW], array[ 1][ 9*BW-1: 8*BW], array[ 2][ 9*BW-1: 8*BW], array[ 3][ 9*BW-1: 8*BW], array[ 4][ 9*BW-1: 8*BW], array[ 5][ 9*BW-1: 8*BW], array[ 6][ 9*BW-1: 8*BW], array[ 7][ 9*BW-1: 8*BW], array[ 8][ 9*BW-1: 8*BW], array[ 9][ 9*BW-1: 8*BW], array[10][ 9*BW-1: 8*BW], array[11][ 9*BW-1: 8*BW]};
assign col[ 4] = {array[ 0][ 8*BW-1: 7*BW], array[ 1][ 8*BW-1: 7*BW], array[ 2][ 8*BW-1: 7*BW], array[ 3][ 8*BW-1: 7*BW], array[ 4][ 8*BW-1: 7*BW], array[ 5][ 8*BW-1: 7*BW], array[ 6][ 8*BW-1: 7*BW], array[ 7][ 8*BW-1: 7*BW], array[ 8][ 8*BW-1: 7*BW], array[ 9][ 8*BW-1: 7*BW], array[10][ 8*BW-1: 7*BW], array[11][ 8*BW-1: 7*BW]};
assign col[ 5] = {array[ 0][ 7*BW-1: 6*BW], array[ 1][ 7*BW-1: 6*BW], array[ 2][ 7*BW-1: 6*BW], array[ 3][ 7*BW-1: 6*BW], array[ 4][ 7*BW-1: 6*BW], array[ 5][ 7*BW-1: 6*BW], array[ 6][ 7*BW-1: 6*BW], array[ 7][ 7*BW-1: 6*BW], array[ 8][ 7*BW-1: 6*BW], array[ 9][ 7*BW-1: 6*BW], array[10][ 7*BW-1: 6*BW], array[11][ 7*BW-1: 6*BW]};
assign col[ 6] = {array[ 0][ 6*BW-1: 5*BW], array[ 1][ 6*BW-1: 5*BW], array[ 2][ 6*BW-1: 5*BW], array[ 3][ 6*BW-1: 5*BW], array[ 4][ 6*BW-1: 5*BW], array[ 5][ 6*BW-1: 5*BW], array[ 6][ 6*BW-1: 5*BW], array[ 7][ 6*BW-1: 5*BW], array[ 8][ 6*BW-1: 5*BW], array[ 9][ 6*BW-1: 5*BW], array[10][ 6*BW-1: 5*BW], array[11][ 6*BW-1: 5*BW]};
assign col[ 7] = {array[ 0][ 5*BW-1: 4*BW], array[ 1][ 5*BW-1: 4*BW], array[ 2][ 5*BW-1: 4*BW], array[ 3][ 5*BW-1: 4*BW], array[ 4][ 5*BW-1: 4*BW], array[ 5][ 5*BW-1: 4*BW], array[ 6][ 5*BW-1: 4*BW], array[ 7][ 5*BW-1: 4*BW], array[ 8][ 5*BW-1: 4*BW], array[ 9][ 5*BW-1: 4*BW], array[10][ 5*BW-1: 4*BW], array[11][ 5*BW-1: 4*BW]};
assign col[ 8] = {array[ 0][ 4*BW-1: 3*BW], array[ 1][ 4*BW-1: 3*BW], array[ 2][ 4*BW-1: 3*BW], array[ 3][ 4*BW-1: 3*BW], array[ 4][ 4*BW-1: 3*BW], array[ 5][ 4*BW-1: 3*BW], array[ 6][ 4*BW-1: 3*BW], array[ 7][ 4*BW-1: 3*BW], array[ 8][ 4*BW-1: 3*BW], array[ 9][ 4*BW-1: 3*BW], array[10][ 4*BW-1: 3*BW], array[11][ 4*BW-1: 3*BW]};
assign col[ 9] = {array[ 0][ 3*BW-1: 2*BW], array[ 1][ 3*BW-1: 2*BW], array[ 2][ 3*BW-1: 2*BW], array[ 3][ 3*BW-1: 2*BW], array[ 4][ 3*BW-1: 2*BW], array[ 5][ 3*BW-1: 2*BW], array[ 6][ 3*BW-1: 2*BW], array[ 7][ 3*BW-1: 2*BW], array[ 8][ 3*BW-1: 2*BW], array[ 9][ 3*BW-1: 2*BW], array[10][ 3*BW-1: 2*BW], array[11][ 3*BW-1: 2*BW]};
assign col[10] = {array[ 0][ 2*BW-1: 1*BW], array[ 1][ 2*BW-1: 1*BW], array[ 2][ 2*BW-1: 1*BW], array[ 3][ 2*BW-1: 1*BW], array[ 4][ 2*BW-1: 1*BW], array[ 5][ 2*BW-1: 1*BW], array[ 6][ 2*BW-1: 1*BW], array[ 7][ 2*BW-1: 1*BW], array[ 8][ 2*BW-1: 1*BW], array[ 9][ 2*BW-1: 1*BW], array[10][ 2*BW-1: 1*BW], array[11][ 2*BW-1: 1*BW]};
assign col[11] = {array[ 0][ 1*BW-1: 0*BW], array[ 1][ 1*BW-1: 0*BW], array[ 2][ 1*BW-1: 0*BW], array[ 3][ 1*BW-1: 0*BW], array[ 4][ 1*BW-1: 0*BW], array[ 5][ 1*BW-1: 0*BW], array[ 6][ 1*BW-1: 0*BW], array[ 7][ 1*BW-1: 0*BW], array[ 8][ 1*BW-1: 0*BW], array[ 9][ 1*BW-1: 0*BW], array[10][ 1*BW-1: 0*BW], array[11][ 1*BW-1: 0*BW]};

assign w_en   = (counter >= 5'd12) && (counter <= 5'd23);
assign w_data = data_out;

endmodule

