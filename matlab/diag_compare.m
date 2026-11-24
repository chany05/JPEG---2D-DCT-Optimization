% diag_compare.m  - golden 2D-DCT vs Verilog output(DCT_image_N.txt) 차이 진단
% Verilog v4 파라미터에 맞춤: 계수 8bit, 1D 11bit(num_int=11), 2차 trunc DC[19:8]/AC[17:6]
clear; clc;
addpath('matlab');

IMG = 1;                       % 진단할 이미지 번호
C_quantization_bit = 8;        % Verilog coeffi_quant=8
Result_1D_DCT_quantization_bit = 11;
num_int = 11;                  % Verilog DCT_1st_res_BW=11

T = func_DCT_Coefficient_quant(C_quantization_bit);

input_image = double(imread(sprintf('matlab/image_in_%d.tif',IMG),'tiff'));
[m,n] = size(input_image); m = floor(m/8)*8; n = floor(n/8)*8;

% ---------- 골든 2D-DCT ----------
Block_DCT_1D_quant = zeros(m,n);
Block_DCT_final    = zeros(m,n);
ovf_1d = zeros(m/16, n/16);     % 블록별 1D 결과 최대 |값|
ovf_cnt = 0;
for i=1:m/16
  for j=1:n/16
    B = input_image((16*i-15):16*i,(16*j-15):16*j);
    D1 = T*B';                                  % 1D-DCT (실수)
    ovf_1d(i,j) = max(abs(floor(D1(:))));
    if ovf_1d(i,j) > 2^(num_int-1), ovf_cnt = ovf_cnt+1; end
    D1q = func_DCTquant(D1, Result_1D_DCT_quantization_bit, num_int);
    Block_DCT_1D_quant((16*i-15):16*i,(16*j-15):16*j) = D1q;
    D2 = T*D1q';
    Block_DCT_final((16*i-15):16*i,(16*j-15):16*j) = func_DCTquant_trunc(D2);
  end
end
fprintf('1D-DCT 결과 |값| 최대 = %g  (num_int=%d 한계 = %d)\n', max(ovf_1d(:)), num_int, 2^(num_int-1));
fprintf('1D 오버플로우(>한계) 블록 수 = %d / %d\n', ovf_cnt, (m/16)*(n/16));

% ---------- Verilog 출력 복원 (JPEG_CODEC_Verilog_IO.m 와 동일) ----------
M = textread(sprintf('DCT_image_%d.txt',IMG),'%12c');
M_2 = char(zeros(size(M,1),16));
for i=1:size(M,1)
  M_2(i,1)=M(i,1); M_2(i,2)=M(i,1); M_2(i,3)=M(i,1); M_2(i,4)=M(i,1);
  M_2(i,5:16)=M(i,1:12);
end
DCT_img_temp = typecast(uint16(bin2dec(char(M_2))),'int16');
DCT_image = zeros(m,n);
x=1;
for k=1:32
  for ii=1:32
    for jj=1:16
      if jj==1
        DCT_image(16*(k-1)+jj,16*(ii-1)+1)=double(DCT_img_temp(x,1)*2);
      else
        DCT_image(16*(k-1)+jj,16*(ii-1)+1)=double(DCT_img_temp(x,1))/2;
      end
      for c=2:16
        DCT_image(16*(k-1)+jj,16*(ii-1)+c)=double(DCT_img_temp(x+c-1,1))/2;
      end
      x=x+16;
    end
  end
end

% ---------- 비교 ----------
D = DCT_image - Block_DCT_final;
nz = find(abs(D)>1e-9);
fprintf('\n총 계수 = %d, 다른 계수 = %d (%.4f%%)\n', numel(D), numel(nz), 100*numel(nz)/numel(D));

% 다른 좌표들이 어느 블록에 몰려있나 / 그 블록이 1D 오버플로우였나
[r,cc] = ind2sub(size(D), nz);
blkr = ceil(r/16); blkc = ceil(cc/16);
ublk = unique([blkr blkc],'rows');
ovf_diff = 0; nonovf_diff = 0;
for t=1:size(ublk,1)
  if ovf_1d(ublk(t,1),ublk(t,2)) > 2^(num_int-1), ovf_diff=ovf_diff+1; else nonovf_diff=nonovf_diff+1; end
end
fprintf('차이 발생 블록 수 = %d  (그중 1D오버플로우 블록 = %d, 비오버플로우 블록 = %d)\n', ...
        size(ublk,1), ovf_diff, nonovf_diff);

% 샘플 20개 출력
fprintf('\n[샘플] row col | golden  verilog  diff | 블록내(br,bc) 1Dmax\n');
for t=1:min(20,numel(nz))
  br=blkr(t); bc=blkc(t);
  fprintf('  %3d %3d | %8.1f %8.1f %8.1f | blk(%d,%d) 1Dmax=%d %s\n', ...
    r(t),cc(t),Block_DCT_final(nz(t)),DCT_image(nz(t)),D(nz(t)), ...
    br,bc,ovf_1d(br,bc), (ovf_1d(br,bc)>2^(num_int-1))*'<OVF');
end
