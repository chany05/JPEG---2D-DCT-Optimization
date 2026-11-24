clear; clc;

image_number = 3;
block_to_show = 10;   % 보고 싶은 블록 번호 (0~1023). 블록10 = 입력 addr160

% ---- txt 읽기 (회로 출력: 16384줄 × 192문자, 줄당 16계수×12bit) ----
M = textread(sprintf('DCT_image_%d.txt', image_number), '%12c');
% M: 262144 × 12  (계수당 12문자)

% 12bit → 16bit 부호확장 후 signed로
M_2 = char(zeros(262144, 16));
for i = 1:262144
    M_2(i, 1:4)  = M(i, 1);      % 상위 4비트에 부호(MSB) 복제
    M_2(i, 5:16) = M(i, 1:12);
end
coef = double(typecast(uint16(bin2dec(M_2)), 'int16'));  % 262144 × 1, signed

% ---- 블록 단위로 16×16 재구성 ----
% 읽기 순서: 블록 b의 16개 워드(=16 row), 각 워드 16계수(=16 col)
% coef 인덱스 = b*256 + row*16 + col + 1
b = block_to_show;
DCTblock = zeros(16, 16);
for row = 0:15
    for col = 0:15
        DCTblock(row+1, col+1) = coef(b*256 + row*16 + col + 1);
    end
end

% ---- 출력 ----
fprintf('=== Block %d DCT coefficients ===\n', b);
fprintf('DC = %d\n\n', DCTblock(1,1));
disp(DCTblock);