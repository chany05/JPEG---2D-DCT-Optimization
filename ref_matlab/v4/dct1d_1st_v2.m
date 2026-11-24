function out = dct1d_1st_v1(blk)
% dct1d_1st: 회로 DCT_1D_1st (coeffi 8bit Q1.7, 1D res 11bit) bit-exact MATLAB 구현
%
% 입력: blk  - 16×16 uint8/double 블록 (행=공간행, 열=DCT 방향)
%              회로는 열 단위로 1D-DCT 수행 (T*blk')
% 출력: out  - 16×16 signed 정수 (A1 = floor(M_int*col/256), 11bit 범위)
%              = 회로 x_in2 와 동일한 값
%
% 연산:
%   coeffi 8bit Q1.7 (x128): W = 8+8+2 = 18
%   1D res 11bit: 출력 truncation y[17:7] = floor(y/128)
%   상수: x128 기준 (x32 대비 ×4 스케일)
%   1. 입력 16픽셀 → x0..x15 (9bit, zero-extend)
%   2. 대칭/반대칭 → s0..s7, d0..d7
%   3. odd-8 사전합 → o8_sum0..3
%   4. 3-mult rotation × 16쌍 → t,A,B (y1,y3,y5,y7,y9,y11,y13,y15)
%   5. even-8 → ss,sd
%   6. odd-4 rotation × 4쌍 → y2,y6,y10,y14
%   7. even-4 → sss,ssd
%   8. odd-2 rotation × 1쌍 → y4,y12
%   9. DC × 2 → y0,y8
%  10. 출력 truncation: y[17:7] = floor(y/128), 16×16 결과

blk = double(blk);
[~, ncols] = size(blk);  % 열 수 = 16 (열 단위로 DCT)

out = zeros(16, ncols);

for col = 1:ncols
    % ── 입력 파싱: 회로는 MSB부터 x0=row1, x1=row2, ..., x15=row16
    px = blk(:, col)';   % 1×16 행벡터, px(1)=x0 ... px(16)=x15
    x = px;              % x(1)=x0, x(16)=x15

    % ── [1단계] zero-extend (9bit, 양수 픽셀이므로 MSB=0)
    x0=x(1);  x1=x(2);  x2=x(3);  x3=x(4);
    x4=x(5);  x5=x(6);  x6=x(7);  x7=x(8);
    x8=x(9);  x9=x(10); x10=x(11);x11=x(12);
    x12=x(13);x13=x(14);x14=x(15);x15=x(16);

    % ── [2단계] 대칭/반대칭
    s0=x0+x15; d0=x0-x15;
    s1=x1+x14; d1=x1-x14;
    s2=x2+x13; d2=x2-x13;
    s3=x3+x12; d3=x3-x12;
    s4=x4+x11; d4=x4-x11;
    s5=x5+x10; d5=x5-x10;
    s6=x6+x9;  d6=x6-x9;
    s7=x7+x8;  d7=x7-x8;

    % ── [3단계] odd-8 사전합
    o8_sum0=d0+d7; o8_sum1=d1+d6;
    o8_sum2=d2+d5; o8_sum3=d3+d4;

    % ── [4단계] odd-8 3-mult rotation (x128 상수, W=18)
    t=4*o8_sum0;  A_y10=41*d0+t; B_y10=t-(49)*d7;
    t=13*o8_sum1; A_y11=30*d1+t; B_y11=56*d6-t;
    t=21*o8_sum2; A_y12=19*d2+t; B_y12=t-(61)*d5;
    t=29*o8_sum3; A_y13=6*d3+t;  B_y13=64*d4-t;

    t=-13*o8_sum0;A_y30=56*d0+t; B_y30=30*d7-t;
    t=-35*o8_sum1;A_y31=64*d1+t; B_y31=t-(-6)*d6;
    t=-45*o8_sum2;A_y32=49*d2+t; B_y32=(-41)*d5-t;
    t=-40*o8_sum3;A_y33=19*d3+t; B_y33=t-(-61)*d4;

    t=21*o8_sum0; A_y50=19*d0+t; B_y50=t-(61)*d7;
    t=45*o8_sum1; A_y51=-41*d1+t;B_y51=49*d6-t;
    t=29*o8_sum2; A_y52=-64*d2+t;B_y52=t-(-6)*d5;
    t=-13*o8_sum3;A_y53=-30*d3+t;B_y53=(-56)*d4-t;

    t=-29*o8_sum0;A_y70=64*d0+t; B_y70=6*d7-t;
    t=-40*o8_sum1;A_y71=19*d1+t; B_y71=t-(-61)*d6;
    t=13*o8_sum2; A_y72=-56*d2+t;B_y72=(-30)*d5-t;
    t=45*o8_sum3; A_y73=-41*d3+t;B_y73=t-(49)*d4;

    % ── [5단계] even-8
    ss0=s0+s7; sd0=s0-s7;
    ss1=s1+s6; sd1=s1-s6;
    ss2=s2+s5; sd2=s2-s5;
    ss3=s3+s4; sd3=s3-s4;

    % ── [6단계] odd-4 3-mult rotation
    o4_sum0=sd0+sd3; o4_sum1=sd1+sd2;

    t=9*o4_sum0;  A_y20=35*sd0+t; B_y20=t-(53)*sd3;
    t=25*o4_sum1; A_y21=13*sd1+t; B_y21=63*sd2-t;

    t=-25*o4_sum0;A_y60=63*sd0+t; B_y60=13*sd3-t;
    t=-44*o4_sum1;A_y61=35*sd1+t; B_y61=t-(-53)*sd2;

    % ── [7단계] even-4
    sss0=ss0+ss3; ssd0=ss0-ss3;
    sss1=ss1+ss2; ssd1=ss1-ss2;

    % ── [8단계] odd-2 3-mult rotation
    o2_sum0=ssd0+ssd1;

    % y4 (d=42, l=17)
    t=17*o2_sum0; A_y40=25*ssd0+t; B_y40=t-59*ssd1;

    % ── [9단계] DC (h=32)
    y0 = 32*(sss0+sss1);
    y8 = 32*(sss0-sss1);

    % ── [10단계] 출력 조합
    y1  = A_y10+A_y11+A_y12+A_y13;
    y2  = A_y20+A_y21;
    y3  = A_y30+A_y31+A_y32+A_y33;
    y4  = A_y40;
    y5  = A_y50+A_y51+A_y52+A_y53;
    y6  = A_y60+A_y61;
    y7  = A_y70+A_y71+A_y72+A_y73;
    y9  = B_y70+B_y71+B_y72+B_y73;
    y10 = B_y60+B_y61;
    y11 = B_y50+B_y51+B_y52+B_y53;
    y12 = B_y40;
    y13 = B_y30+B_y31+B_y32+B_y33;
    y14 = B_y20+B_y21;
    y15 = B_y10+B_y11+B_y12+B_y13;

    % ── [11단계] truncation: y[17:7] = floor(y/128)
    % W=18, BW=11 → y[17:7] = floor(y/2^7) = floor(y/128)
    % = A1 (11bit 정수, 회로 x_in2 스케일)
    out(1,  col) = floor(y0  / 128);
    out(2,  col) = floor(y1  / 128);
    out(3,  col) = floor(y2  / 128);
    out(4,  col) = floor(y3  / 128);
    out(5,  col) = floor(y4  / 128);
    out(6,  col) = floor(y5  / 128);
    out(7,  col) = floor(y6  / 128);
    out(8,  col) = floor(y7  / 128);
    out(9,  col) = floor(y8  / 128);
    out(10, col) = floor(y9  / 128);
    out(11, col) = floor(y10 / 128);
    out(12, col) = floor(y11 / 128);
    out(13, col) = floor(y12 / 128);
    out(14, col) = floor(y13 / 128);
    out(15, col) = floor(y14 / 128);
    out(16, col) = floor(y15 / 128);
end
