%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%   Verilog assign-statement generator for 16-point DCT coefficients   %%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% gen_DCT_coeffi_verilog(quant_bit)
%
%   Prints 15 Verilog 'assign cN = <quant_bit>'h<VAL>;' lines (c1..c15) for the
%   15 unique magnitudes of the 16-point DCT-II matrix:
%       a..o = (1/sqrt(8)) * cos(k*pi/32),  k = 1..15
%
%   Format     : Q1.(quant_bit-1) signed -- MSB reserved as sign bit, the
%                remaining (quant_bit-1) bits are fractional.  All 15
%                magnitudes are positive, so the MSB is always 0 and the
%                bit pattern is identical under both signed (2's complement)
%                and unsigned interpretation.  The sign of each matrix
%                entry is applied by the surrounding add/sub structure in
%                the Verilog (matches func_DCT_Coefficient_quant.m).
%   Rounding   : round(coef * 2^(quant_bit-1))  -- round-to-nearest.
%                Matches func_Dec2Bin_mag.m (which is what
%                func_DCT_Coefficient_quant.m actually calls).
%                Note: func_DCTquant.m uses floor, so it can produce
%                slightly different values for the same input.
%   Hex width  : ceil(quant_bit / 4) nibbles (zero-padded)
%
%   Example:
%       >> gen_DCT_coeffi_verilog(8)
%       // 16-point DCT-II unique coefficients, Q1.7 signed (1 sign + 7 frac)
%       assign c1  = 8'h2D;  // a = 0.351851 -> 0.351562 (err -0.000289)
%       assign c2  = 8'h2C;  // b = 0.346759 -> 0.343750 (err -0.003009)
%       ...
%
%   The printed text is ready to paste straight into DCT.v.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function gen_DCT_coeffi_verilog(quant_bit)

    if nargin < 1
        quant_bit = 8;
    end
    if quant_bit < 2 || quant_bit > 32
        error('quant_bit must be in [2,32].');
    end

    %--- 15 unique 16-point DCT-II magnitudes (a..o) -----------------------------
    coeff = zeros(1,15);
    for k = 1:15
        coeff(k) = (1/sqrt(8)) * cos(k*pi/32);
    end

    %--- hex width: round up to nearest nibble -----------------------------------
    hex_w = ceil(quant_bit / 4);
    hfmt  = sprintf('%%0%dX', hex_w);     % e.g. '%02X' for 8-bit, '%03X' for 12

    name  = 'abcdefghijklmno';
    scale = 2^(quant_bit-1);              % 1 bit reserved for sign

    fprintf('// 16-point DCT-II unique coefficients, Q1.%d signed (1 sign + %d frac)\n', ...
            quant_bit-1, quant_bit-1);

    for k = 1:15
        q_int   = round(coeff(k) * scale);    % match func_Dec2Bin_mag (round-to-nearest)
        actual  = q_int / scale;
        err     = actual - coeff(k);
        hex_str = sprintf(hfmt, q_int);
        fprintf('assign c%-2d = %d''h%s;  // %s = %.6f -> %.6f (err %+.6f)\n', ...
                k, quant_bit, hex_str, name(k), coeff(k), actual, err);
    end
end
