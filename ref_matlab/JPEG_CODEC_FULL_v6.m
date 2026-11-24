% JPEG_CODEC_FULL_v6.m  (ref_matlab 버전)
% ref_matlab/JPEG_CODEC_FULL.m 을 기반으로, 회로 top_2D_DCT_v6 의
% 연산 구조와 bit-exact 일치하도록 수정한 레퍼런스.
%
% ──────────────────────────────────────────────────────────────
% 원본 FULL과의 차이점
% ──────────────────────────────────────────────────────────────
% [1] C_quantization_bit: 6  (Q1.5, x32 정수계수)
%
% [2] 1D quant:
%     원본: func_DCTquant(T*blk', 12, 12)  → granularity=1
%     v6  : func_DCTquant(T*blk',  8, 11)  → granularity=8
%           = floor(T*blk'/8)*8  ↔  회로 floor(M_int*x/256)
%
% [3] 2D DCT 입력 스케일:
%     원본: T * D1q'          (D1q = floor(T*blk'/8)*8, ×8 스케일)
%     v6  : T_int * (D1q/8)'  (A1 = D1q/8,  정수 ×32)
%           → pre = M_int*A1 = D2_real*32  (회로 내부값과 동일)
%
% [4] func_DCTquant_trunc → func_DCTquant_trunc_v6:
%     원본: (1,1)만 DC포맷
%     v6  : {(1,1),(1,2),(2,1)} 3곳 DC포맷  (오버플로 방지)
%           DC포맷: floor(pre/2)     (granularity 2)
%           AC포맷: floor(pre*2)     (granularity 0.5)
%
% [5] 역양자화+IDCT readback 스케일 보정:
%     DC 3곳: ×2  →  floor(pre/2)×2  ≈ D2_real  (×32→÷16≈D2)
%     AC    : ÷2  →  floor(pre*2)/2  ≈ D2_real
%     → 이후 Q행렬 역양자화 → IDCT는 원본과 동일 구조
%
% [6] 엔트로피 코딩/디코딩: 원본과 동일 (lossless)
% ──────────────────────────────────────────────────────────────

clear all
close all
clc

figure('Position', [100, 100, 1200, 700]);
t = tiledlayout(2, 4);
t.Padding     = 'tight';
t.TileSpacing = 'compact';

for image_number = 5:5

    %---------------------------- Get the Image data Input ----------------------------
    input_image_512x512 = double(imread(sprintf('image_in_%d.tif', image_number), 'tiff'));
    [m, n] = size(input_image_512x512);
    m = floor(m/8)*8;
    n = floor(n/8)*8;

    %------------------------------------generate input text file ---------------------
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
        if mod(i, 16) == 0
            fprintf(input_vector, '\n');
        end
    end
    fclose(input_vector);

    %---------------------Q 행렬 (역양자화용) ----------------------------------------
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

    Q_pre = Q;

    %---------------------[변경1] 계수 6비트 (Q1.5) ----------------------------------
    C_quantization_bit = 6;
    T     = func_DCT_Coefficient_quant(C_quantization_bit);  % 실수 (÷32)
    T_int = round(T * 32);                                   % 정수 (×32) = M_int

    filter_coef = fopen('./filt_coeff_T.txt', 'w');
    for k = 1:16
        fprintf(filter_coef, '%x \n', T_int(k,1));
    end
    fclose(filter_coef);

    %---------------------[변경2] 1D quant: granularity=8 ---------------------------
    Result_1D_DCT_quantization_bit = 8;
    num_int = 11;

    %======================== FORWARD 2D-DCT =============================
    Image_tran      = zeros(m, n);
    Block_DCT_final = zeros(m, n);

    for i = 1:m/16
        for j = 1:n/16
            Block_temp = input_image_512x512((16*i-15):16*i, (16*j-15):16*j);

            % 1D-DCT (column-wise)
            Block_DCT_1D_temp = T * Block_temp';
            % [변경2] granularity=8 (원본: 12,12 → v6: 8,11)
            D1q = func_DCTquant(Block_DCT_1D_temp, Result_1D_DCT_quantization_bit, num_int);
            Block_DCT_1D_quant((16*i-15):16*i, (16*j-15):16*j) = D1q;

            % [변경3] 2D-DCT: T_int * A1' (A1=D1q/8, 정수 ×32)
            % 원본: T * D1q'  (D1q는 ×8 스케일 → D2_real*8)
            % v6  : T_int * (D1q/8)' = D2_real*32  (회로 내부 pre와 동일)
            A1  = D1q / 8;
            pre = T_int * A1';   % 16×16 정수, = D2_real*32

            % [변경4] func_DCTquant_trunc_v6: 3곳 DC확장
            % 원본 func_DCTquant_trunc: (1,1)만 floor(D2/2)*2, 나머지 floor(D2*2)/2
            % v6: pre=D2*32 이므로
            %   DC: floor(pre/2)  = floor(D2*16) ← 저장값 (readback ×2 → D2*32)
            %   AC: floor(pre*2)  = floor(D2*64) ← 저장값 (readback ÷2 → D2*32)
            Bfin = floor(pre * 2);           % AC 기본
            Bfin(1,1) = floor(pre(1,1)/2);  % DC (1,1)
            Bfin(1,2) = floor(pre(1,2)/2);  % DC (1,2)
            Bfin(2,1) = floor(pre(2,1)/2);  % DC (2,1)
            Block_DCT_final((16*i-15):16*i, (16*j-15):16*j) = Bfin;

            % 역양자화 (엔트로피 전 단계, 원본과 동일 구조)
            Block_DCT = Bfin;
            Block_r   = round(Q_pre .\ Block_DCT);
            Image_tran((16*i-15):16*i, (16*j-15):16*j) = Block_r;
        end
    end

    %======================== ENTROPY ENCODING (원본과 동일) =============
    ZigZag_Order = uint16([ 1  17   2   3  18  33  49  34  19   4   5  20  35  50  65  81
                            66  51  36  21   6   7  22  37  52  67  82  97 113  98  83  68
                            53  38  23   8   9  24  39  54  69  84  99 114 129 145 130 115
                           100  85  70  55  40  25  10  11  26  41  56  71  86 101 116 131
                           146 161 177 162 147 132 117 102  87  72  57  42  27  12  13  28
                            43  58  73  88 103 118 133 148 163 178 193 209 194 179 164 149
                           134 119 104  89  74  59  44  29  14  15  30  45  60  75  90 105
                           120 135 150 165 180 195 210 225 241 226 211 196 181 166 151 136
                           121 106  91  76  61  46  31  16  32  47  62  77  92 107 122 137
                           152 167 182 197 212 227 242 243 228 213 198 183 168 153 138 123
                           108  93  78  63  48  64  79  94 109 124 139 154 169 184 199 214
                           229 244 245 230 215 200 185 170 155 140 125 110  95  80  96 111
                           126 141 156 171 186 201 216 231 246 247 232 217 202 187 172 157
                           142 127 112 128 143 158 173 188 203 218 233 248 249 234 219 204
                           189 174 159 144 160 175 190 205 220 235 250 251 236 221 206 191
                           176 192 207 222 237 252 253 238 223 208 224 239 254 255 240 256]);

    Single_column_quantized_image = im2col(Image_tran, [16 16], 'distinct');
    ZigZaged_Single_Column_Image  = Single_column_quantized_image(ZigZag_Order, :);

    run_level_pairs = int16([]);
    for block_index = 1:1024
        single_block_image_vector(1:256) = 0;
        for Temp_Vector_Index = 1:256
            single_block_image_vector(Temp_Vector_Index) = ZigZaged_Single_Column_Image(Temp_Vector_Index, block_index);
        end
        non_zero_value_index_array = find(single_block_image_vector ~= 0);
        if isempty(non_zero_value_index_array)
            non_zero_value_index_array(1) = 0;
        end
        number_of_non_zero_entries = length(non_zero_value_index_array);
        if non_zero_value_index_array(1) == 0
            run_level_pairs = cat(1, run_level_pairs);
        elseif non_zero_value_index_array(1) == 1
            run_level_pairs = cat(1, run_level_pairs, 0, single_block_image_vector(non_zero_value_index_array(1)));
        end
        for idx = 2:number_of_non_zero_entries
            run = non_zero_value_index_array(idx) - non_zero_value_index_array(idx-1) - 1;
            run_level_pairs = cat(1, run_level_pairs, run, single_block_image_vector(non_zero_value_index_array(idx)));
        end
        run_level_pairs = cat(1, run_level_pairs, 255, 255);
    end

    %======================== ENTROPY DECODING (원본과 동일) =============
    c = [];
    for i = 1:2:numel(run_level_pairs)
        if run_level_pairs(i) < 255
            for l = 1:run_level_pairs(i)
                c = cat(1, c, 0);
            end
            c = cat(1, c, run_level_pairs(i+1));
        else
            number_of_trailing_zeros = 256 - mod(numel(c), 256);
            for l = 1:number_of_trailing_zeros
                c = cat(1, c, 0);
            end
        end
    end

    ZigZaged_Single_Column_Image = zeros(256, 1024);
    for i = 1:1024
        for j = 1:256
            ZigZaged_Single_Column_Image(j, i) = c(256*(i-1)+j);
        end
    end

    reverse_zigzag_order = zeros(16, 16);
    for k = 1:(size(ZigZag_Order,1)*size(ZigZag_Order,2))
        reverse_zigzag_order(k) = find(ZigZag_Order == k);
    end

    Single_column_quantized_image = ZigZaged_Single_Column_Image(reverse_zigzag_order, :);
    Image_tran = col2im(Single_column_quantized_image, [16 16], [m n], 'distinct');

    %======================== IDCT 복원 =====================================
    % [변경5] readback: Block_DCT_final → D2_real 복원 후 IDCT
    %   DC 3곳: ×2  →  floor(pre/2)×2   (pre=D2*32, ÷16 ≈ D2/2×2=D2)
    %   AC    : ÷2  →  floor(pre*2)/2   ≈ D2_real
    % → 이 값을 Q로 나눠 역양자화, T' * Q_dequant * T 로 복원
    %
    % 주의: Image_tran은 엔트로피 통과 후 역양자화된 계수 (round(Q_pre.\Bfin))
    %       IDCT는 T' * (Q.*Image_tran) * T 구조 (원본과 동일)
    %       단, T는 v6 계수(6bit)를 사용

    Image_restore = zeros(m, n);
    for i = 1:m/16
        for j = 1:n/16
            Block_temp = Image_tran((16*i-15):16*i, (16*j-15):16*j);
            Block_rq   = Q .* Block_temp;
            % [변경5] IDCT: T' * Block_rq * T  (T는 v6 계수 6bit)
            Block_IDCT = T' * Block_rq * T;
            Image_restore((16*i-15):16*i, (16*j-15):16*j) = Block_IDCT;
        end
    end

    Image_restore = max(0, min(255, Image_restore));

    %------------------------Generate the output Image--------------------------
    output_file_name = sprintf('image_out_%d.tif', image_number);
    imwrite(uint8(Image_restore), output_file_name, 'tif');

    %-------------------------Calculate the PSNR--------------------------------
    MSE = 0;
    for row = 1:m
        for col = 1:n
            MSE = MSE + (input_image_512x512(row,col) - Image_restore(row,col))^2;
        end
    end
    MSE = MSE / (m*n);
    PSNR(1, image_number) = 10 * log10(255^2 / MSE);

    %-------------------------Show the output image-----------------------------
    ax = nexttile(image_number);
    imshow(Image_restore./255);
    title(sprintf('v6 #%d\nPSNR : %.2f dB', image_number, PSNR(image_number)));
    ax.Toolbar.Visible = 'off';

end


