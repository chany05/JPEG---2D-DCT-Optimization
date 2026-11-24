% diag_all.m - 이미지 1~5 골든 vs Verilog 차이 패턴 일괄 진단
clear; clc; addpath('matlab');
C_quantization_bit = 8; Result_1D_DCT_quantization_bit = 11; num_int = 11;
T = func_DCT_Coefficient_quant(C_quantization_bit);

for IMG = 1:5
  input_image = double(imread(sprintf('matlab/image_in_%d.tif',IMG),'tiff'));
  [m,n]=size(input_image); m=floor(m/8)*8; n=floor(n/8)*8;
  Block_DCT_final=zeros(m,n); ovf_1d=zeros(m/16,n/16);
  for i=1:m/16, for j=1:n/16
    B=input_image((16*i-15):16*i,(16*j-15):16*j);
    D1=T*B'; ovf_1d(i,j)=max(abs(floor(D1(:))));
    D1q=func_DCTquant(D1,Result_1D_DCT_quantization_bit,num_int);
    D2=T*D1q';
    Block_DCT_final((16*i-15):16*i,(16*j-15):16*j)=func_DCTquant_trunc(D2);
  end, end

  M=textread(sprintf('DCT_image_%d.txt',IMG),'%12c');
  M_2=char(zeros(size(M,1),16));
  for i=1:size(M,1), M_2(i,1:4)=M(i,1); M_2(i,5:16)=M(i,1:12); end
  DCT_img_temp=typecast(uint16(bin2dec(char(M_2))),'int16');
  DCT_image=zeros(m,n); x=1;
  for k=1:32, for ii=1:32, for jj=1:16
    if jj==1, DCT_image(16*(k-1)+jj,16*(ii-1)+1)=double(DCT_img_temp(x,1)*2);
    else,     DCT_image(16*(k-1)+jj,16*(ii-1)+1)=double(DCT_img_temp(x,1))/2; end
    for c=2:16, DCT_image(16*(k-1)+jj,16*(ii-1)+c)=double(DCT_img_temp(x+c-1,1))/2; end
    x=x+16;
  end, end, end

  D=DCT_image-Block_DCT_final; nz=find(abs(D)>1e-9);
  [r,cc]=ind2sub(size(D),nz);
  ndiff=numel(nz);
  in_lastrow = sum(r==m);                 % 이미지 맨 마지막 행에 있는 차이 수
  in_lastblk = sum(ceil(r/16)==m/16 & ceil(cc/16)==n/16);  % 마지막 블록(32,32)
  ovfcnt = sum(ovf_1d(:)>2^(num_int-1));
  fprintf('IMG%d: 1Dmax=%4d ovfBlk=%d | diff=%d  (lastRow=%d, lastBlk=%d)  maxAbsDiff=%.1f  rows{%s}\n',...
    IMG, max(ovf_1d(:)), ovfcnt, ndiff, in_lastrow, in_lastblk, max(abs(D(:))), ...
    num2str(unique(r')));
end
