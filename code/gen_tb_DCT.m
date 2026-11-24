%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%   Multi-vector 16-point 1D-DCT testbench stimulus generator               %%%
%%%   - Generates N random 16-pixel blocks (unsigned 8-bit [0,255])           %%%
%%%   - Computes the golden y_int with the same Q1.(W-1) integer matrix that  %%%
%%%     DCT.v uses (bit-exact)                                                %%%
%%%   - Then applies the SAME truncation as DCT.v:                            %%%
%%%         x_out byte_k = y_k[7+BW-1 : 7]                                    %%%
%%%     i.e. drop 7 LSB frac bits, keep BW MSBs of integer part.              %%%
%%%   - Output files (current working dir):                                   %%%
%%%       tb_input.hex   : N lines, 32-hex-digit 128-bit packed pixels        %%%
%%%       tb_input.dec   : N lines, "vec K : x0 x1 ... x15"                   %%%
%%%       tb_golden.hex  : N lines, ceil(16*BW/4)-hex-digit packed truncated y%%%
%%%       tb_golden.dec  : N lines, "vec K : y0=.. y1=.. ..."                 %%%
%%%   - Pack convention matches DCT.v:                                        %%%
%%%       x_in [8*k +: 8] = x_k           -> pixel 0 is LSB byte              %%%
%%%       x_out[BW*(15-k)+:BW] = y_k_trunc-> y0 is MSB byte                   %%%
%%%
%%%   matlab/ folder is read-only reference; this file lives in code/.
%%%
%%%   Usage:
%%%       gen_tb_DCT();                       % defaults: N=8, random, BW=8
%%%       gen_tb_DCT(16);                     % 16 vectors
%%%       gen_tb_DCT(16, 12345);              % fixed seed
%%%       gen_tb_DCT(16, 12345, 8, 11);       % +quant_bit, +BW
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function gen_tb_DCT(num_vectors, seed, quant_bit, BW)

    if nargin < 1 || isempty(num_vectors), num_vectors = 8;  end
    if nargin < 2,                          seed        = []; end
    if nargin < 3 || isempty(quant_bit),    quant_bit   = 8;  end
    if nargin < 4 || isempty(BW),           BW          = 8;  end

    %--- RNG ---------------------------------------------------------------------
    if isempty(seed)
        rng('shuffle');
        seed_used = randi(2^31-1);
        rng(seed_used);
    else
        seed_used = seed;
        rng(seed_used);
    end

    %--- Q1.(W-1) coefficient integers (round-to-nearest, matches DCT.v) -------
    scale = 2^(quant_bit-1);
    coef  = zeros(1,15);
    for kk = 1:15
        coef(kk) = round( (1/sqrt(8)) * cos(kk*pi/32) * scale );
    end
    a=coef(1);  b=coef(2);  c=coef(3);  d=coef(4);  e=coef(5);
    f=coef(6);  g=coef(7);  h=coef(8);  i=coef(9);  j=coef(10);
    k=coef(11); l=coef(12); m=coef(13); n=coef(14); o=coef(15);

    %--- 16x16 integer DCT-II matrix (structure : matlab/func_DCT_Coefficient_quant.m)
    T_int = [   h  h  h  h  h  h  h  h  h  h  h  h  h  h  h  h
                a  c  e  g  i  k  m  o -o -m -k -i -g -e -c -a
                b  f  j  n -n -j -f -b -b -f -j -n  n  j  f  b
                c  i  o -k -e -a -g -m  m  g  a  e  k -o -i -c
                d  l -l -d -d -l  l  d  d  l -l -d -d -l  l  d
                e  o -g -c -m  i  a  k -k -a -i  m  c  g -o -e
                f -n -b -j  j  b  n -f -f  n  b  j -j -b -n  f
                g -k -c  o  a  m -e -i  i  e -m -a -o  c  k -g
                h -h -h  h  h -h -h  h  h -h -h  h  h -h -h  h
                i -e -m  a -o -c  k  g -g -k  c  o -a  m  e -i
                j -b  n  f -f -n  b -j -j  b -n -f  f  n -b  j
                k -a  i  m -c  g  o -e  e -o -g  c -m -i  a -k
                l -d  d -l -l  d -d  l  l -d  d -l -l  d -d  l
                m -g  a -e  k  o -i  c -c  i -o -k  e -a  g -m
                n -j  f -b  b -f  j -n -n  j -f  b -b  f -j  n
                o -m  k -i  g -e  c -a  a -c  e -g  i -k  m -o ];

    Y_WIDTH    = 18;
    Y_INT_BITS = 11;
    if BW > Y_INT_BITS
        error('BW (%d) > 11 = full int width. slice y[7+BW-1:7] reads past sign bit.', BW);
    end

    %--- open files --------------------------------------------------------------
    fid_ih = fopen('tb_input.hex',  'w');
    fid_id = fopen('tb_input.dec',  'w');
    fid_gh = fopen('tb_golden.hex', 'w');
    fid_gd = fopen('tb_golden.dec', 'w');

    fprintf(fid_id, '# seed=%d  quant_bit=%d  BW=%d  num_vectors=%d\n', ...
                    seed_used, quant_bit, BW, num_vectors);
    fprintf(fid_gd, '# seed=%d  quant_bit=%d  BW=%d  num_vectors=%d\n', ...
                    seed_used, quant_bit, BW, num_vectors);

    fprintf('--- gen_tb_DCT: %d vector(s), seed=%d, BW=%d ---\n', ...
            num_vectors, seed_used, BW);

    overflow_cnt = 0;

    for v = 1:num_vectors
        %--- random pixel block -----------------------------------------------
        pixels = randi([0, 255], 16, 1);          % double col vector
        y_int  = T_int * pixels;                  % 16x1 signed integer (double)

        if any(y_int >  2^(Y_WIDTH-1)-1) || any(y_int < -2^(Y_WIDTH-1))
            warning('gen_tb_DCT:y_overflow', ...
                    'vec %d : y_int exceeds 18-bit signed range', v-1);
        end

        %--- truncation : verilog slice y[7+BW-1:7] ---------------------------
        % equivalent to (y_int_2sComp >> 7) & ((1<<BW)-1) on 18-bit 2's-comp
        y_18b   = mod(y_int, 2^Y_WIDTH);                       % unsigned 18-bit
        y_trunc = mod(floor(y_18b ./ 128), 2^BW);              % BW-bit slice

        %--- overflow check : does y_int/128 fit BW-bit signed slice ? --------
        for kk = 1:16
            v_int_real = floor(y_int(kk) / 128);
            if v_int_real >= 2^(BW-1) || v_int_real < -2^(BW-1)
                overflow_cnt = overflow_cnt + 1;
            end
        end

        %--- write input.hex : x0 = LSB byte ----------------------------------
        fprintf(fid_ih, '%s\n', pack_lsb_first_hex(pixels, 8, 128));

        %--- write golden.hex : y0 = MSB byte (matches DCT.v concat order) ---
        fprintf(fid_gh, '%s\n', pack_msb_first_hex(y_trunc, BW, 16*BW));

        %--- decimal logs (human readable) ------------------------------------
        fprintf(fid_id, 'vec %2d :', v-1);
        fprintf(fid_id, ' %3d', pixels);
        fprintf(fid_id, '\n');

        fprintf(fid_gd, 'vec %2d :', v-1);
        for kk = 1:16
            vs    = signed_of(y_trunc(kk), BW);
            yreal = y_int(kk) / 128;
            fprintf(fid_gd, ' y%-2d=%5d(%+7.2f)', kk-1, vs, yreal);
        end
        fprintf(fid_gd, '\n');
    end

    fclose(fid_ih); fclose(fid_id); fclose(fid_gh); fclose(fid_gd);

    if overflow_cnt > 0
        warning('gen_tb_DCT:trunc_overflow', ...
                '%d y_k truncation overflow(s). BW=%d may be too narrow (try BW>=11).', ...
                overflow_cnt, BW);
    end
    fprintf('  written : tb_input.hex/dec , tb_golden.hex/dec\n');
end

%----------------------------------------------------------------------------
function h = pack_lsb_first_hex(vals, w, total_bits)
% pack vals(1)..vals(end) into total_bits where vals(1) is the LSB w-bit slot,
% return as zero-padded uppercase hex string.
    bin_str = '';
    for idx = numel(vals):-1:1                       % MSB end first
        bin_str = [bin_str, dec2bin(vals(idx), w)];  %#ok<AGROW>
    end
    h = bin2hex(bin_str, total_bits);
end

%----------------------------------------------------------------------------
function h = pack_msb_first_hex(vals, w, total_bits)
% pack vals(1)..vals(end) into total_bits where vals(1) is the MSB w-bit slot,
% return as zero-padded uppercase hex string.
    bin_str = '';
    for idx = 1:numel(vals)                          % MSB end first
        bin_str = [bin_str, dec2bin(vals(idx), w)];  %#ok<AGROW>
    end
    h = bin2hex(bin_str, total_bits);
end

%----------------------------------------------------------------------------
function h = bin2hex(bin_str, total_bits)
% Pad MSB to a nibble boundary, then convert 4-bit chunks to uppercase hex.
    nibbles = ceil(total_bits / 4);
    pad     = nibbles*4 - length(bin_str);
    if pad > 0
        bin_str = [repmat('0', 1, pad), bin_str];
    elseif pad < 0
        bin_str = bin_str(end-nibbles*4+1:end);      % rare : trim MSB
    end
    h = blanks(nibbles);
    for nn = 1:nibbles
        nyb_val = bin2dec(bin_str((nn-1)*4 + (1:4)));
        if nyb_val < 10
            h(nn) = char('0' + nyb_val);
        else
            h(nn) = char('A' + nyb_val - 10);
        end
    end
end

%----------------------------------------------------------------------------
function s = signed_of(u, w)
% interpret unsigned u (0..2^w-1) as w-bit 2's-complement signed integer.
    if u >= 2^(w-1)
        s = u - 2^w;
    else
        s = u;
    end
end
