% JPEG_CODEC_FULL_v6.m
% JPEG_CODEC_FULL_DCT_generate.m 기반, 회로 top_2D_DCT_v6 과 bit-exact 일치.
% DCT forward + IDCT 복원 + PSNR 계산 + 이미지 표시까지 포함.
%
% 변경점 (vs JPEG_CODEC_FULL_DCT_generate.m):
%   1. C_quantization_bit = 6  (Q1.5, x32)
%   2. 1D quant: func_DCTquant(T*blk', 8, 11)  → granularity=8
%   3. 2D: T_int(정수×32) * A1(=D1q/8)  직접 사용  → 회로 스케일 일치
%   4. trunc: {(1,1),(1,2),(2,1)} 3곳 DC확장 포맷 (오버플로 방지)
%   5. 복원용 IDCT: T_int 기반으로 스케일 보정하여 복원
%
% 파일쓰기 포맷 (DCT_image_N.txt):
%   DC 3곳 pixel=floor(pre/2):  파일=pixel/2   readback: x2  → floor(pre/2)
%   AC      pixel=floor(pre*2):  파일=pixel*2   readback: /2  → floor(pre*2)
%   (Verilog_IO.m readback 루프와 동일)

clear
close all
clc

figure('Position', [100, 100, 1400, 700]);
t_layout = tiledlayout(2, 8);
t_layout.Padding = 'tight';
t_layout.TileSpacing = 'compact';

% Q 행렬 (복원용 역양자화)
Q = [ 16  14  11  11  10  13  16  20  24  32  40  46  51  56  61 61
      14  13  12  12  12  15  18  21  25  37  49  52  56  57  58 58
      12  12  12  13  14  17  19  23  26  42  58  59  60  58  55 55
      13  13  13  14  15  18  22  27  33  45  58  61  65  60  56 56
      14  14  13  15  16  20  24  32  40  49  57  63  69  63  56 56
      14  15  15  17  19  23  27  36  46  59  72  73  75  67  59 59
      14  16  17  20  22  26  29  40  51  69  87  84  80  71  62 62
      16  18  20  25  30  36  43  51  60  79  98  95  92  81  70 70
      18  20  22  30  37  47  56  62  68  89 109 106 103  90  77 77
      21  25  29  37  46  53  60  67  75  91 107 107 108  96  85 85
      24  30  35  45  55  60  64  73  81  93 104 109 113 103  92 92
      37  43  50  58  67  71  76  84  92 102 113 115 117 107  97 97
      49  57  64  71  78  83  87  95 103 112 121 121 120 111 101 101
      61  69  78  82  87  90  93 100 108 109 111 111 112 106 100 100
      72  82  92  94  95  97  98 105 112 106 100 102 103 101  99  99
      72  82  92  94  95  97  98 105 112 106 100 102 103 101  99  99];

Q_pre = Q;   % 역양자화 행렬 (동일)
PSNR  = zeros(1, 8);

for image_number = 1:8

    input_image_512x512 = double(imread(sprintf('image_in_%d.tif', image_number), 'tiff'));
    [m, n] = size(input_image_512x512);
    m = floor(m/8)*8;
    n = floor(n/8)*8;

    %-------- generate input text file --------
    x = 1;
    for l = 1:32
        for k = 1:32
            for i = 1:16
                for j = 1:16
                    vector_temp(1, x) = input_image_512x512((i+16*(l-1)), (j+16*(k-1)));
                    x = x + 1;
                end
            end
        end
    end

    input_vector = fopen(sprintf('image_in_%d.txt', image_number), 'w');
    for i = 1:(512*512)
        fprintf(input_vector, '%s', dec2hex(vector_temp(1,i), 2));
        if mod(i,16) == 0
            fprintf(input_vector, '\n');
        end
    end
    fclose(input_vector);

    %-------- 계수 행렬 (Q1.5, x32) --------
    C_quantization_bit = 6;
    T = func_DCT_Coefficient_quant(C_quantization_bit);   % 실수 (÷32)
    T_int = round(T * 32);                                % 정수 (×32), 회로 M_int

    filter_coef = fopen('./filt_coeff_T.txt', 'w');
    for k = 1:16
        fprintf(filter_coef, '%x \n', T_int(k,1));
    end
    fclose(filter_coef);

    %======================================================
    %               FORWARD 2D-DCT  (회로 v6 모델)
    %======================================================
    % 1D quant: granularity=8 → 회로 floor(M_int*x/256) 과 동일
    Result_1D_quant_bit = 8;
    num_int_1D = 11;

    Block_DCT_final = zeros(m, n);

    dct_file = fopen(sprintf('DCT_image_%d.txt', image_number), 'w');

    for i = 1:m/16
        for j = 1:n/16
            Block_temp = input_image_512x512((16*i-15):16*i, (16*j-15):16*j);

            % 1D-DCT (column-wise)
            D1_temp = T * Block_temp';
            D1q = func_DCTquant(D1_temp, Result_1D_quant_bit, num_int_1D);
            % D1q = floor(T*blk'/8)*8,  A1 = D1q/8 = 회로 8bit x_in2

            % 2D-DCT: 정수 연산 (회로와 동일 스케일)
            % pre = T_int * A1' = T_int * (D1q/8)' = D2_real * 32
            A1  = D1q / 8;
            pre = T_int * A1';    % 16x16 정수, = D2_real*32

            % trunc: 회로 출력 포맷 (bit-exact)
            %   DC {(1,1),(1,2),(2,1)}: floor(pre/2)
            %   AC 나머지             : floor(pre*2)
            Bfin = floor(pre * 2);          % AC 기본
            Bfin(1,1) = floor(pre(1,1)/2); % DC (1,1)
            Bfin(1,2) = floor(pre(1,2)/2); % DC (1,2)
            Bfin(2,1) = floor(pre(2,1)/2); % DC (2,1)
            Block_DCT_final((16*i-15):16*i, (16*j-15):16*j) = Bfin;

            % 파일 쓰기 (DCT_image_N.txt)
            for fi = 1:16
                for fj = 1:16
                    pixel = Bfin(fi, fj);
                    if (fi==1 && fj==1) || (fi==1 && fj==2) || (fi==2 && fj==1)
                        % DC확장: pixel/2 (12bit)
                        val = dec2bin(pixel/2, 12);
                        fprintf(dct_file, '%12s\n', val);
                    else
                        % AC: pixel*2 (12bit), 포화
                        if pixel >  1023, pixel =  1023; end
                        if pixel < -1024, pixel = -1024; end
                        val = dec2bin(pixel*2, 12);
                        fprintf(dct_file, '%12s\n', val);
                    end
                end
            end

        end
    end
    fclose(dct_file);

    %======================================================
    %    IDCT 복원  (Verilog_IO.m readback 구조 동일)
    %======================================================
    % readback: DC 3곳 ×2,  AC ÷2  → DCT_image 행렬 복원
    DCT_image = zeros(m, n);
    for i = 1:m/16
        for j = 1:n/16
            Bfin = Block_DCT_final((16*i-15):16*i, (16*j-15):16*j);
            Brec = Bfin / 2;                    % AC: floor(pre*2)/2 = D2_real
            Brec(1,1) = Bfin(1,1) * 2;         % DC(1,1): floor(pre/2)*2
            Brec(1,2) = Bfin(1,2) * 2;         % DC(1,2)
            Brec(2,1) = Bfin(2,1) * 2;         % DC(2,1)
            DCT_image((16*i-15):16*i, (16*j-15):16*j) = Brec;
        end
    end

    % 엔트로피 코딩 생략 (lossless 가정)
    % 역양자화 + IDCT
    % 복원용 IDCT 계수: Verilog_IO와 동일하게 C_quantization_bit=8 T 사용
    T_idct = func_DCT_Coefficient_quant(8);
    Image_restore = zeros(m, n);

    for i = 1:m/16
        for j = 1:n/16
            Brec  = DCT_image((16*i-15):16*i, (16*j-15):16*j);
            Block_r  = round(Q_pre .\ Brec);     % 역양자화
            Block_rq = Q .* Block_r;
            Block_IDCT = T_idct' * Block_rq * T_idct;
            Image_restore((16*i-15):16*i, (16*j-15):16*j) = Block_IDCT;
        end
    end

    % 클리핑
    Image_restore = max(0, min(255, Image_restore));

    % 출력 이미지 저장
    imwrite(uint8(Image_restore), sprintf('image_out_%d.tif', image_number), 'tif');

    %======================================================
    %               PSNR 계산
    %======================================================
    MSE = sum(sum((input_image_512x512(1:m,1:n) - Image_restore).^2)) / (m*n);
    PSNR(image_number) = 10 * log10(255^2 / MSE);

    %-------- 표시 --------
    nexttile(image_number);
    imshow(input_image_512x512./255);
    title(sprintf('Original #%d', image_number));

    nexttile(image_number + 8);
    imshow(Image_restore./255);
    title(sprintf('v6 #%d\nPSNR: %.2f dB', image_number, PSNR(image_number)));

    fprintf('image %d: PSNR = %.4f dB\n', image_number, PSNR(image_number));

end

fprintf('\n평균 PSNR: %.4f dB\n', mean(PSNR));
