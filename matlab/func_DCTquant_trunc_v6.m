function Block_quant = func_DCTquant_trunc_v6(Block)
% func_DCTquant_trunc_v6: 회로 top_2D_DCT_v6의 출력 포맷과 bit-exact 일치.
%
% 회로는 저주파 3곳 {(1,1),(1,2),(2,1)} 을 DC확장 포맷으로 저장:
%   DC포맷: floor(D2/2)*2   (granularity=2, 오버플로 방지)
%   AC포맷: floor(D2*2)/2   (granularity=0.5, func_DCTquant_trunc 원본과 동일)
%
% 이유: (1,2),(2,1)은 고에너지 이미지(img 3,4,7)에서 12bit AC포맷 오버플로 발생
%       → (1,1)과 함께 3곳 모두 DC확장 포맷으로 처리.

for i = 1:16
    for j = 1:16
        if (i==1 && j==1) || (i==1 && j==2) || (i==2 && j==1)
            % DC확장 포맷 (회로 is_dc/is_dc2 신호로 선택)
            Block_quant(i,j) = floor(Block(i,j)/2)*2;
        else
            % AC 포맷 (원본 func_DCTquant_trunc 동일)
            Block_quant(i,j) = floor(Block(i,j)*2)/2;
        end
    end
end
