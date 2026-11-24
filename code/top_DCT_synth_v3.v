module top_2D_DCT_synth_v3 (
    input clk, rstn
);

    wire [16*8-1:0] x_in;
    wire [16*12-1:0] x_out;

    reg [14-1:0] counter;

    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin counter <= 14'd0; end
        else counter <= counter + 14'd1;
    end

    reg running;
    always @(posedge clk or negedge rstn) begin
        if (!rstn)
            running <= 1'b0;
        else if (counter == 5'd0)
            running <= 1'b1;
    end

    D_FF128_v3 D_IN(.q(x_in),.d(128'b0),.clk(clk), .rstn(rstn));

    DCT_2D_v3 DCT(clk, rstn, x_in, x_out, counter[4:0], running);

    D_FF192_v3 D_OUT(.q(),.d(x_out),.clk(clk), .rstn(rstn));

endmodule


module DCT_2D_v3 (
    input clk, rstn,
    input [16*8-1:0] x_in,
    output [16*12-1:0] x_out,
    input [5-1:0] counter,
    input running
);

    ///////////////////////////////////////////////////////////////////
    ///////////////////////     coefficient     ///////////////////////
    ///////////////////////////////////////////////////////////////////
    wire signed [8-1:0] c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13,c14,c15;

    // 16-point DCT-II unique coefficients, Q1.7 signed (sign + 7 frac bits)
    assign c1  = 8'h2D;
    assign c2  = 8'h2C;
    assign c3  = 8'h2B;
    assign c4  = 8'h2A;
    assign c5  = 8'h28;
    assign c6  = 8'h26;
    assign c7  = 8'h23;
    assign c8  = 8'h20;
    assign c9  = 8'h1D;
    assign c10 = 8'h19;
    assign c11 = 8'h15;
    assign c12 = 8'h11;
    assign c13 = 8'h0D;
    assign c14 = 8'h09;
    assign c15 = 8'h04;

    ///////////////////////////////////////////////////////////////////
    ///////////////////////////     DCT     ///////////////////////////
    ///////////////////////////////////////////////////////////////////

    // 1st DCT : input 8bit -> output 11bit (176 = 16*11)

    wire [16*11-1:0] DCT_1st_out;
    //16x8bit
    DCT_1D_1st_v3 DCT_1st(x_in, DCT_1st_out, c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13,c14,c15);
    //DCT_1st out : 16x12(1D-DCT_res_qunatization)bit

    wire o_en1, o_en2;
    wire [16*11-1:0] TPmem_out1;

    wire [5-1:0] counter_TP12 = counter - 5'd1;

    TPmem_16x16_single_1st #(.BW(11)) TP_MEM_1(.i_data(DCT_1st_out),
                        .i_clk(clk), .i_Reset(rstn), .o_data(TPmem_out1), .o_en(o_en1));

    //wire [16*DCT_1st_res_BW-1:0] x_in2 = (TPmem_out1 | TPmem_out2);
    wire [16*11-1:0] x_in2 = TPmem_out1;
    wire [16*12-1:0] x_out2;
    wire is_dc = (counter_TP12[3:0] == 1);

    //DCT_2nd_in : 16x(DCT_1st_res_BW)bit
    DCT_1D_2nd_v3 DCT_2nd(x_in2, x_out2, c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13,c14,c15, is_dc);

    TPmem_16x16_single_2nd #(.BW(12)) TP_MEM_2(.i_data(x_out2),
                        .i_clk(clk), .i_Reset(rstn), .o_data(x_out), .o_en(o_en2));

endmodule


//===========================================================================
//  DCT_1D_1st : input 8bit (unsigned, zero-extend), output 11bit
//    W = 8 + 8 + 2 = 18,  truncation [17:7]  (MSB-anchored, x1 scale)
//===========================================================================
//===========================================================================
//  DCT_1D_1st_v3 : input 8bit (unsigned, zero-extend), output 11bit
//    3-mult rotation, 계수 합/차 상수 내장. 합성용 (파라미터 없음, BW=11 고정)
//    W = 8+8+2 = 18, truncation [17:7]
//===========================================================================
module DCT_1D_1st_v3
(   input  [16*8-1:0]  x_in,
    output [16*11-1:0] x_out,
    input  signed [7:0] c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13,c14,c15  // 미사용(인터페이스 호환)
);
    wire signed [8:0] x0,x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12,x13,x14,x15;
    assign x15 = {1'b0, x_in[8*1-1 : 8*0]};
    assign x0 = {1'b0, x_in[8*16-1 : 8*15]};
    assign x14 = {1'b0, x_in[8*2-1 : 8*1]};
    assign x1 = {1'b0, x_in[8*15-1 : 8*14]};
    assign x13 = {1'b0, x_in[8*3-1 : 8*2]};
    assign x2 = {1'b0, x_in[8*14-1 : 8*13]};
    assign x12 = {1'b0, x_in[8*4-1 : 8*3]};
    assign x3 = {1'b0, x_in[8*13-1 : 8*12]};
    assign x11 = {1'b0, x_in[8*5-1 : 8*4]};
    assign x4 = {1'b0, x_in[8*12-1 : 8*11]};
    assign x10 = {1'b0, x_in[8*6-1 : 8*5]};
    assign x5 = {1'b0, x_in[8*11-1 : 8*10]};
    assign x9 = {1'b0, x_in[8*7-1 : 8*6]};
    assign x6 = {1'b0, x_in[8*10-1 : 8*9]};
    assign x8 = {1'b0, x_in[8*8-1 : 8*7]};
    assign x7 = {1'b0, x_in[8*9-1 : 8*8]};
    wire signed [9:0] s0,s1,s2,s3,s4,s5,s6,s7;
    wire signed [8:0] d0,d1,d2,d3,d4,d5,d6,d7;
    assign s0=x0+x15; assign d0=x0-x15;
    assign s1=x1+x14; assign d1=x1-x14;
    assign s2=x2+x13; assign d2=x2-x13;
    assign s3=x3+x12; assign d3=x3-x12;
    assign s4=x4+x11; assign d4=x4-x11;
    assign s5=x5+x10; assign d5=x5-x10;
    assign s6=x6+x9; assign d6=x6-x9;
    assign s7=x7+x8; assign d7=x7-x8;
    wire signed [9:0] o8_sum0=d0+d7;
    wire signed [9:0] o8_sum1=d1+d6;
    wire signed [9:0] o8_sum2=d2+d5;
    wire signed [9:0] o8_sum3=d3+d4;
    wire signed [19:0] t_o8_y10=4*o8_sum0;
    wire signed [19:0] A_o8_y10=41*d0+t_o8_y10;
    wire signed [19:0] B_o8_y10=t_o8_y10-(49)*d7;
    wire signed [19:0] t_o8_y11=13*o8_sum1;
    wire signed [19:0] A_o8_y11=30*d1+t_o8_y11;
    wire signed [19:0] B_o8_y11=56*d6-t_o8_y11;
    wire signed [19:0] t_o8_y12=21*o8_sum2;
    wire signed [19:0] A_o8_y12=19*d2+t_o8_y12;
    wire signed [19:0] B_o8_y12=t_o8_y12-(61)*d5;
    wire signed [19:0] t_o8_y13=29*o8_sum3;
    wire signed [19:0] A_o8_y13=6*d3+t_o8_y13;
    wire signed [19:0] B_o8_y13=64*d4-t_o8_y13;
    wire signed [19:0] t_o8_y30=-13*o8_sum0;
    wire signed [19:0] A_o8_y30=56*d0+t_o8_y30;
    wire signed [19:0] B_o8_y30=30*d7-t_o8_y30;
    wire signed [19:0] t_o8_y31=-35*o8_sum1;
    wire signed [19:0] A_o8_y31=64*d1+t_o8_y31;
    wire signed [19:0] B_o8_y31=t_o8_y31-(-6)*d6;
    wire signed [19:0] t_o8_y32=-45*o8_sum2;
    wire signed [19:0] A_o8_y32=49*d2+t_o8_y32;
    wire signed [19:0] B_o8_y32=-41*d5-t_o8_y32;
    wire signed [19:0] t_o8_y33=-40*o8_sum3;
    wire signed [19:0] A_o8_y33=19*d3+t_o8_y33;
    wire signed [19:0] B_o8_y33=t_o8_y33-(-61)*d4;
    wire signed [19:0] t_o8_y50=21*o8_sum0;
    wire signed [19:0] A_o8_y50=19*d0+t_o8_y50;
    wire signed [19:0] B_o8_y50=t_o8_y50-(61)*d7;
    wire signed [19:0] t_o8_y51=45*o8_sum1;
    wire signed [19:0] A_o8_y51=-41*d1+t_o8_y51;
    wire signed [19:0] B_o8_y51=49*d6-t_o8_y51;
    wire signed [19:0] t_o8_y52=29*o8_sum2;
    wire signed [19:0] A_o8_y52=-64*d2+t_o8_y52;
    wire signed [19:0] B_o8_y52=t_o8_y52-(-6)*d5;
    wire signed [19:0] t_o8_y53=-13*o8_sum3;
    wire signed [19:0] A_o8_y53=-30*d3+t_o8_y53;
    wire signed [19:0] B_o8_y53=-56*d4-t_o8_y53;
    wire signed [19:0] t_o8_y70=-29*o8_sum0;
    wire signed [19:0] A_o8_y70=64*d0+t_o8_y70;
    wire signed [19:0] B_o8_y70=6*d7-t_o8_y70;
    wire signed [19:0] t_o8_y71=-40*o8_sum1;
    wire signed [19:0] A_o8_y71=19*d1+t_o8_y71;
    wire signed [19:0] B_o8_y71=t_o8_y71-(-61)*d6;
    wire signed [19:0] t_o8_y72=13*o8_sum2;
    wire signed [19:0] A_o8_y72=-56*d2+t_o8_y72;
    wire signed [19:0] B_o8_y72=-30*d5-t_o8_y72;
    wire signed [19:0] t_o8_y73=45*o8_sum3;
    wire signed [19:0] A_o8_y73=-41*d3+t_o8_y73;
    wire signed [19:0] B_o8_y73=t_o8_y73-(49)*d4;
    wire signed [10:0] ss0,ss1,ss2,ss3;
    wire signed [9:0] sd0,sd1,sd2,sd3;
    assign ss0=s0+s7; assign sd0=s0-s7;
    assign ss1=s1+s6; assign sd1=s1-s6;
    assign ss2=s2+s5; assign sd2=s2-s5;
    assign ss3=s3+s4; assign sd3=s3-s4;
    wire signed [10:0] o4_sum0=sd0+sd3;
    wire signed [10:0] o4_sum1=sd1+sd2;
    wire signed [19:0] t_o4_y20=9*o4_sum0;
    wire signed [19:0] A_o4_y20=35*sd0+t_o4_y20;
    wire signed [19:0] B_o4_y20=t_o4_y20-(53)*sd3;
    wire signed [19:0] t_o4_y21=25*o4_sum1;
    wire signed [19:0] A_o4_y21=13*sd1+t_o4_y21;
    wire signed [19:0] B_o4_y21=63*sd2-t_o4_y21;
    wire signed [19:0] t_o4_y60=-25*o4_sum0;
    wire signed [19:0] A_o4_y60=63*sd0+t_o4_y60;
    wire signed [19:0] B_o4_y60=13*sd3-t_o4_y60;
    wire signed [19:0] t_o4_y61=-44*o4_sum1;
    wire signed [19:0] A_o4_y61=35*sd1+t_o4_y61;
    wire signed [19:0] B_o4_y61=t_o4_y61-(-53)*sd2;
    wire signed [11:0] sss0,sss1;
    wire signed [10:0] ssd0,ssd1;
    assign sss0=ss0+ss3; assign ssd0=ss0-ss3;
    assign sss1=ss1+ss2; assign ssd1=ss1-ss2;
    wire signed [11:0] o2_sum0=ssd0+ssd1;
    wire signed [19:0] t_o2_y40=17*o2_sum0;
    wire signed [19:0] A_o2_y40=25*ssd0+t_o2_y40;
    wire signed [19:0] B_o2_y40=t_o2_y40-(59)*ssd1;
    wire signed [17:0] y0,y1,y2,y3,y4,y5,y6,y7,y8,y9,y10,y11,y12,y13,y14,y15;
    assign y0 = 32*(sss0+sss1);
    assign y8 = 32*(sss0-sss1);
    assign y1 = A_o8_y10+A_o8_y11+A_o8_y12+A_o8_y13;
    assign y2 = A_o4_y20+A_o4_y21;
    assign y3 = A_o8_y30+A_o8_y31+A_o8_y32+A_o8_y33;
    assign y4 = A_o2_y40;
    assign y5 = A_o8_y50+A_o8_y51+A_o8_y52+A_o8_y53;
    assign y6 = A_o4_y60+A_o4_y61;
    assign y7 = A_o8_y70+A_o8_y71+A_o8_y72+A_o8_y73;
    assign y9 = B_o8_y70+B_o8_y71+B_o8_y72+B_o8_y73;
    assign y10 = B_o4_y60+B_o4_y61;
    assign y11 = B_o8_y50+B_o8_y51+B_o8_y52+B_o8_y53;
    assign y12 = B_o2_y40;
    assign y13 = B_o8_y30+B_o8_y31+B_o8_y32+B_o8_y33;
    assign y14 = B_o4_y20+B_o4_y21;
    assign y15 = B_o8_y10+B_o8_y11+B_o8_y12+B_o8_y13;
    assign x_out = {y0[17:7],y1[17:7],y2[17:7],y3[17:7],y4[17:7],y5[17:7],y6[17:7],y7[17:7],y8[17:7],y9[17:7],y10[17:7],y11[17:7],y12[17:7],y13[17:7],y14[17:7],y15[17:7]};
endmodule


//===========================================================================
//  DCT_1D_2nd : input 11bit (signed, sign-extend), output 12bit
//    W = 11 + 8 + 2 = 21
//    DC (is_dc & y0) : [19:8]  (real / 2)
//    AC              : [17:6]  (real * 2)
//===========================================================================
module DCT_1D_2nd_v3
(   input  [16*11-1:0] x_in,
    output [16*12-1:0] x_out,
    input  signed [8-1:0] c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13,c14,c15,
    input is_dc
);

    // x preparation : 11bit signed -> sign-extend to 12bit signed
    wire signed [12-1:0] x0,x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12,x13,x14,x15;

    assign x15 = {x_in[11*1 -1], x_in[11*1 -1 : 11*0 ]};
    assign x0  = {x_in[11*16-1], x_in[11*16-1 : 11*15]};
    assign x14 = {x_in[11*2 -1], x_in[11*2 -1 : 11*1 ]};
    assign x1  = {x_in[11*15-1], x_in[11*15-1 : 11*14]};
    assign x13 = {x_in[11*3 -1], x_in[11*3 -1 : 11*2 ]};
    assign x2  = {x_in[11*14-1], x_in[11*14-1 : 11*13]};
    assign x12 = {x_in[11*4 -1], x_in[11*4 -1 : 11*3 ]};
    assign x3  = {x_in[11*13-1], x_in[11*13-1 : 11*12]};
    assign x11 = {x_in[11*5 -1], x_in[11*5 -1 : 11*4 ]};
    assign x4  = {x_in[11*12-1], x_in[11*12-1 : 11*11]};
    assign x10 = {x_in[11*6 -1], x_in[11*6 -1 : 11*5 ]};
    assign x5  = {x_in[11*11-1], x_in[11*11-1 : 11*10]};
    assign x9  = {x_in[11*7 -1], x_in[11*7 -1 : 11*6 ]};
    assign x6  = {x_in[11*10-1], x_in[11*10-1 : 11*9 ]};
    assign x8  = {x_in[11*8 -1], x_in[11*8 -1 : 11*7 ]};
    assign x7  = {x_in[11*9 -1], x_in[11*9 -1 : 11*8 ]};

    // s,d preparation
    wire signed [13-1:0] s0,s1,s2,s3,s4,s5,s6,s7;
    wire signed [12-1:0] d0,d1,d2,d3,d4,d5,d6,d7;

    assign s0 = x0 + x15;  assign d0 = x0 - x15;
    assign s1 = x1 + x14;  assign d1 = x1 - x14;
    assign s2 = x2 + x13;  assign d2 = x2 - x13;
    assign s3 = x3 + x12;  assign d3 = x3 - x12;
    assign s4 = x4 + x11;  assign d4 = x4 - x11;
    assign s5 = x5 + x10;  assign d5 = x5 - x10;
    assign s6 = x6 + x9 ;  assign d6 = x6 - x9 ;
    assign s7 = x7 + x8 ;  assign d7 = x7 - x8 ;

    // y operation  (W = 21)
    wire signed [21-1:0] y0,y1,y2,y3,y4,y5,y6,y7,y8,y9,y10,y11,y12,y13,y14,y15;

    // 8-point odd part
    assign y1  =  c1*d0 +  c3*d1 +  c5*d2 +  c7*d3 +  c9*d4 + c11*d5 + c13*d6 + c15*d7;
    assign y15 = c15*d0 - c13*d1 + c11*d2 -  c9*d3 +  c7*d4 -  c5*d5 +  c3*d6 -  c1*d7;
    assign y3  =  c3*d0 +  c9*d1 + c15*d2 - c11*d3 -  c5*d4 -  c1*d5 -  c7*d6 - c13*d7;
    assign y13 = c13*d0 -  c7*d1 +  c1*d2 -  c5*d3 + c11*d4 + c15*d5 -  c9*d6 +  c3*d7;
    assign y5  =  c5*d0 + c15*d1 -  c7*d2 -  c3*d3 - c13*d4 +  c9*d5 +  c1*d6 + c11*d7;
    assign y11 = c11*d0 -  c1*d1 +  c9*d2 + c13*d3 -  c3*d4 +  c7*d5 + c15*d6 -  c5*d7;
    assign y7  =  c7*d0 - c11*d1 -  c3*d2 + c15*d3 +  c1*d4 + c13*d5 -  c5*d6 -  c9*d7;
    assign y9  =  c9*d0 -  c5*d1 - c13*d2 +  c1*d3 - c15*d4 -  c3*d5 + c11*d6 +  c7*d7;

    // 8-point even part : 2nd butterfly on s
    wire signed [14-1:0] ss0, ss1, ss2, ss3;
    wire signed [13-1:0] sd0, sd1, sd2, sd3;

    assign ss0 = s0 + s7;  assign sd0 = s0 - s7;
    assign ss1 = s1 + s6;  assign sd1 = s1 - s6;
    assign ss2 = s2 + s5;  assign sd2 = s2 - s5;
    assign ss3 = s3 + s4;  assign sd3 = s3 - s4;

    // 4-point odd part
    assign y2  =  c2*sd0 +  c6*sd1 + c10*sd2 + c14*sd3;
    assign y14 = c14*sd0 - c10*sd1 +  c6*sd2 -  c2*sd3;
    assign y6  =  c6*sd0 - c14*sd1 -  c2*sd2 - c10*sd3;
    assign y10 = c10*sd0 -  c2*sd1 + c14*sd2 +  c6*sd3;

    // 4-point even part : 3rd butterfly on ss
    wire signed [15-1:0] sss0, sss1;
    wire signed [14-1:0] ssd0, ssd1;

    assign sss0 = ss0 + ss3;  assign ssd0 = ss0 - ss3;
    assign sss1 = ss1 + ss2;  assign ssd1 = ss1 - ss2;

    // 2-point odd part
    assign y4  =  c4*ssd0 + c12*ssd1;
    assign y12 = c12*ssd0 -  c4*ssd1;

    // 2-point even part
    assign y0 = c8 * (sss0 + sss1);
    assign y8 = c8 * (sss0 - sss1);

    // result truncation
    //   DC (is_dc & y0) : [19:8] = real/2
    //   AC              : [17:6] = real*2
    assign x_out = {
        is_dc ? y0[19:8] : y0[17:6],
        y1 [17:6], y2 [17:6], y3 [17:6],
        y4 [17:6], y5 [17:6], y6 [17:6], y7 [17:6],
        y8 [17:6], y9 [17:6], y10[17:6], y11[17:6],
        y12[17:6], y13[17:6], y14[17:6], y15[17:6]
    };

endmodule


module D_FF128_v3(q, d, clk, rstn);
    output reg [127:0] q;
    input [127:0] d;
    input clk, rstn;
    always @(posedge clk)
        if (!rstn) q <= 128'b0;
        else q <= d;
endmodule


module D_FF192_v3(q, d, clk, rstn);
    output reg [191:0] q;
    input [191:0] d;
    input clk, rstn;
    always @(posedge clk)
        if (!rstn) q <= 192'b0;
        else q <= d;
endmodule