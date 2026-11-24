function out = dct1d_2nd_v1(A1)
% dct1d_2nd: 회로 DCT_1D_2nd (coeffi 8bit Q1.7, 입력 11bit) bit-exact MATLAB 구현
%
% 입력:
%   A1  - 16×16 signed 정수 (dct1d_1st 출력, 11bit)
%         A1(k, c) : k=주파수행(1~16), c=공간열(1~16)
%
% 출력:
%   out - 16×16 signed 정수 (12bit 저장값)
%         out(k2, k1) : k2=2nd주파수행, k1=1st주파수행
%         DC {(1,1),(1,2),(2,1)}: floor(pre/8)   readback ×8  (y[19:8])
%         AC 나머지             : floor(pre/2)   readback ×2  (y[17:6])
%         ※ W=21, s2=4:  AC→y[14:3]=floor(y/8), DC→y[16:5]=floor(y/32)
%            pre=y=D2_real×128 기준: AC=floor(pre/8), DC=floor(pre/32)
%
% 동작:
%   TPMEM 전치 후 2nd DCT는 A1의 k1번째 행(A1(k1,:))을 한 클럭에 처리.
%   is_dc  = (k1==1)  → y0,y1 모두 DC포맷
%   is_dc2 = (k1==2)  → y0만 DC포맷
%   나머지 k1          → 전부 AC포맷
%
% 1st와 동일한 x128 상수/연산 구조, 차이점:
%   - 입력: signed 11bit (sign-extend, MATLAB double로 자동 처리)
%   - W=11+8+2=21, y wire [20:0]

out = zeros(16, 16);

for k1 = 1:16
    % A1(k1, :) = 16개 값 (공간 열 방향)
    x = A1(k1, :);   % 1×16, x(1)=x0 ... x(16)=x15

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

    % ── [4단계] odd-8 3-mult rotation (x128 상수, W=21)
    t=4*o8_sum0;  Ay10=41*d0+t; By10=t-(49)*d7;
    t=13*o8_sum1; Ay11=30*d1+t; By11=56*d6-t;
    t=21*o8_sum2; Ay12=19*d2+t; By12=t-(61)*d5;
    t=29*o8_sum3; Ay13=6*d3+t;  By13=64*d4-t;

    t=-13*o8_sum0;Ay30=56*d0+t; By30=30*d7-t;
    t=-35*o8_sum1;Ay31=64*d1+t; By31=t-(-6)*d6;
    t=-45*o8_sum2;Ay32=49*d2+t; By32=(-41)*d5-t;
    t=-40*o8_sum3;Ay33=19*d3+t; By33=t-(-61)*d4;

    t=21*o8_sum0; Ay50=19*d0+t; By50=t-(61)*d7;
    t=45*o8_sum1; Ay51=-41*d1+t;By51=49*d6-t;
    t=29*o8_sum2; Ay52=-64*d2+t;By52=t-(-6)*d5;
    t=-13*o8_sum3;Ay53=-30*d3+t;By53=(-56)*d4-t;

    t=-29*o8_sum0;Ay70=64*d0+t; By70=6*d7-t;
    t=-40*o8_sum1;Ay71=19*d1+t; By71=t-(-61)*d6;
    t=13*o8_sum2; Ay72=-56*d2+t;By72=(-30)*d5-t;
    t=45*o8_sum3; Ay73=-41*d3+t;By73=t-(49)*d4;

    % ── [5단계] even-8
    ss0=s0+s7; sd0=s0-s7;
    ss1=s1+s6; sd1=s1-s6;
    ss2=s2+s5; sd2=s2-s5;
    ss3=s3+s4; sd3=s3-s4;

    % ── [6단계] odd-4 3-mult rotation
    o4_sum0=sd0+sd3; o4_sum1=sd1+sd2;

    t=9*o4_sum0;  Ay20=35*sd0+t; By20=t-(53)*sd3;
    t=25*o4_sum1; Ay21=13*sd1+t; By21=63*sd2-t;

    t=-25*o4_sum0;Ay60=63*sd0+t; By60=13*sd3-t;
    t=-44*o4_sum1;Ay61=35*sd1+t; By61=t-(-53)*sd2;

    % ── [7단계] even-4
    sss0=ss0+ss3; ssd0=ss0-ss3;
    sss1=ss1+ss2; ssd1=ss1-ss2;

    % ── [8단계] odd-2 3-mult rotation
    o2_sum0=ssd0+ssd1;
    t=17*o2_sum0; Ay40=25*ssd0+t; By40=t-(59)*ssd1;

    % ── [9단계] DC (h=32)
    y0=32*(sss0+sss1); y8=32*(sss0-sss1);

    % ── [10단계] 출력 조합 → pre = y (= D2_real × 32)
    Y(1) =y0;
    Y(2) =Ay10+Ay11+Ay12+Ay13;
    Y(3) =Ay20+Ay21;
    Y(4) =Ay30+Ay31+Ay32+Ay33;
    Y(5) =Ay40;
    Y(6) =Ay50+Ay51+Ay52+Ay53;
    Y(7) =Ay60+Ay61;
    Y(8) =Ay70+Ay71+Ay72+Ay73;
    Y(9) =y8;
    Y(10)=By70+By71+By72+By73;
    Y(11)=By60+By61;
    Y(12)=By50+By51+By52+By53;
    Y(13)=By40;
    Y(14)=By30+By31+By32+By33;
    Y(15)=By20+By21;
    Y(16)=By10+By11+By12+By13;

    % ── [11단계] 출력 포맷 (회로 x_out)
    % W=21, pre=y=D2_real×128
    % AC: y[17:6] = floor(y/64)  → AC저장 = floor(pre/64)
    % DC: y[19:8] = floor(y/256) → DC저장 = floor(pre/256)
    %
    % is_dc  = (k1==1): y0→DC, y1→DC
    % is_dc2 = (k1==2): y0→DC만
    is_dc  = (k1 == 1);
    is_dc2 = (k1 == 2);

    for k2 = 1:16
        % if k2==1 && (is_dc || is_dc2)
        %     out(k2, k1) = floor(Y(k2) / 256);  % DC포맷: y[19:8]
        % elseif k2==2 && is_dc
        %     out(k2, k1) = floor(Y(k2) / 256);  % DC포맷: y[19:8]
        % else
        %     out(k2, k1) = floor(Y(k2) / 64);   % AC포맷: y[17:6]
        % end
        if k2==1 && is_dc
            out(k2, k1) = floor(Y(k2) / 256);  % DC포맷: y[19:8]
        % elseif k2==2 && is_dc
        %     out(k2, k1) = floor(Y(k2) / 256);  % DC포맷: y[19:8]
        else
            out(k2, k1) = floor(Y(k2) / 64);   % AC포맷: y[17:6]
        end
    end

end
