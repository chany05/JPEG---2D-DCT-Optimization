# -*- coding: utf-8 -*-
# Generate top_2D_DCT_v6.v from the validated v5 by:
#   1) rescaling every 3-mult rotation constant from Q1.7 (x128) to Q1.5 (x32)
#   2) reducing 1D-DCT result BW 11 -> 8, coefficient 8 -> 6 bit
#   3) re-deriving the 2nd-stage DC/AC output truncation slices
#
# Rotation algebra (per pair): out = C*d_a + S*d_b implemented 3-mult as
#   t  = S*(d_a+d_b)              -> t-line constant      = S
#   A  = (C-S)*d_a + t            -> A-line constant (k1)  = C-S
#   B  = t - (C+S)*d_b            -> B-line constant (k3)  = C+S   (form preserved)
# So from the file we read S (t-line) and k1 (A-line) -> C = k1 + S.
# Remap |C|,|S| from x128 magnitude to x32 magnitude (round-to-nearest), keep signs,
# then re-emit S' , k1'=C'-S' , k3'=C'+S'.
import re, math

V5 = open('code/top_2D_DCT_v5.v', encoding='utf-8', errors='replace').read()

# x128 magnitude -> coefficient letter (unique), and x32 magnitude (round(coef*32))
name = 'abcdefghijklmno'
mag128 = {}
mag32  = {}
for k in range(1, 16):
    c = (1/math.sqrt(8))*math.cos(k*math.pi/32)
    mag128[round(c*128)] = name[k-1]
    mag32[name[k-1]]     = round(c*32)

def remap(v):
    """map a signed x128 coefficient integer to its x32 equivalent (sign preserved)"""
    s = -1 if v < 0 else 1
    a = abs(v)
    assert a in mag128, f"{a} is not a known x128 coefficient magnitude"
    return s * mag32[mag128[a]]

# ---- collect rotation suffixes present in v5 (o8_yNN, o4_yNN, o2_yNN) ----
suffixes = sorted(set(re.findall(r't_(o\d_y\d+)\s*=', V5)))

# parse S (t-line) and k1 (A-line) for each suffix
S = {}; K1 = {}
for sfx in suffixes:
    mt = re.search(r't_'+sfx+r'\s*=\s*(-?\d+)\*', V5)
    ma = re.search(r'A_'+sfx+r'\s*=\s*(-?\d+)\*', V5)
    S[sfx]  = int(mt.group(1))
    K1[sfx] = int(ma.group(1))

# compute new constants
newS={}; newK1={}; newK3={}
for sfx in suffixes:
    s = S[sfx]; k1 = K1[sfx]; C = k1 + s
    sp = remap(s); Cp = remap(C)
    newS[sfx]  = sp
    newK1[sfx] = Cp - sp
    newK3[sfx] = Cp + sp

def transform_body(body):
    """rescale all rotation constants + the DC '32*' inside a stage body string"""
    out = body
    for sfx in suffixes:
        # t-line:  t_sfx = <S>*sum...
        out = re.sub(r'(\bt_'+sfx+r'\s*=\s*)-?\d+(\*)',
                     lambda m: f"{m.group(1)}{newS[sfx]}{m.group(2)}", out)
        # A-line:  A_sfx = <k1>*d...
        out = re.sub(r'(\bA_'+sfx+r'\s*=\s*)-?\d+(\*)',
                     lambda m: f"{m.group(1)}{newK1[sfx]}{m.group(2)}", out)
        # B-line:  k3 is the integer multiplying the data var (paren or bare),
        #          the other operand is t_sfx. Replace only the d-multiplier.
        def fixB(m):
            line = m.group(0)
            # remove the t_sfx token so the remaining int*var is the k3 term
            tmp = line.replace('t_'+sfx, 'T')
            tmp = re.sub(r'\(?-?\d+\)?(\s*\*\s*(?:d|sd|ssd)\d)',
                         lambda mm: f"({newK3[sfx]}){mm.group(1)}", tmp, count=1)
            return tmp.replace('T', 't_'+sfx)
        out = re.sub(r'\bB_'+sfx+r'\s*=\s*[^;]+;', fixB, out)
    # DC even term: 32*(...) -> 8*(...)   (h: x128=32 -> x32=8)
    out = re.sub(r'\b32\*\(', f'{mag32["h"]}*(', out)
    return out

# ---- sanity print ----
print("suffix   S128 k1_128  C128  ->  S32 k1_32 k3_32   (C,S letters)")
for sfx in suffixes:
    C = K1[sfx]+S[sfx]
    lc = mag128[abs(C)]; ls = mag128[abs(S[sfx])]
    print(f"{sfx:8s} {S[sfx]:4d} {K1[sfx]:5d} {C:5d}  ->  {newS[sfx]:3d} {newK1[sfx]:4d} {newK3[sfx]:4d}    "
          f"C={'-' if C<0 else '+'}{lc} S={'-' if S[sfx]<0 else '+'}{ls}")

# ---- extract stage1 computational body (between port list end and 'assign x_out') ----
m1 = re.search(r'module DCT_1D_1st_v5.*?endmodule', V5, re.S)
stage1 = m1.group(0)
# the shared arithmetic body = everything from 'localparam W' up to the line before 'assign y0'
# We'll rebuild both stages from this transformed arithmetic.
arith_start = stage1.index('localparam W')
arith_end   = stage1.index('assign y0')
arith = stage1[arith_start:arith_end]          # decl of x*, s/d, rotations, ... up to y wires
arith_t = transform_body(arith)

# y assignments (y0..y15) are identical for both stages; transform '32*' there too
ym = re.search(r'(assign y0 .*?assign y15[^;]*;)', stage1, re.S)
yblock = transform_body(ym.group(1))

# =====================================================================
#  Assemble the full top_2D_DCT_v6.v
# =====================================================================
CQ, BW1 = 6, 8          # coefficient bits (6,5) ; 1D-DCT result BW
# 2nd-stage fixed-point (derived, generalises v5):
#   W1 = 8(pixel)+CQ+2 = 16 ;  s1 = (CQ-1)-(W1-BW1) = 5-8 = -3  (1D res = floor(DCT_1d/8))
#   s2 = s1+(CQ-1) = 2          -> 2nd-stage  y2 = DCT_2d * 4
#   AC store = DCT_2d*2 = y2>>1 -> y2[s2-1+11 : s2-1] = y2[12:1]
#   DC store = DCT_2d/2 = y2>>3 -> y2[s2+1+11 : s2+1] = y2[14:3]
W1   = 8 + CQ + 2
s1   = (CQ-1) - (W1-BW1)
s2   = s1 + (CQ-1)
AC_HI, AC_LO = (s2-1)+11, (s2-1)
DC_HI, DC_LO = (s2+1)+11, (s2+1)
print(f"\n[fixed-point] W1={W1} s1={s1} s2={s2}  AC=y[{AC_HI}:{AC_LO}]  DC=y[{DC_HI}:{DC_LO}]")

c_list = ",".join(f"c{i}" for i in range(1,16))

def stage1_module():
    return f"""// 1D-DCT 1st stage. coefficient Q1.{CQ-1} (x{2**(CQ-1)}), output BW bits (top-bit truncation).
// 3-mult rotation, constants re-quantised from v5 Q1.7 by gen_v6.py. bit-exact w/ MATLAB cq={CQ}.
module DCT_1D_1st_v6
#( parameter input_BW=8, parameter BW={BW1}, parameter coeffi_quant={CQ}, parameter SIGNED_IN=0 )
(   input  [16*input_BW-1:0] x_in,
    output [16*BW-1:0]       x_out,
    input  signed [coeffi_quant-1:0] {c_list}  // unused (interface compat)
);
    {arith_t}
{yblock}
    assign x_out = {{y0[W-1:W-BW],y1[W-1:W-BW],y2[W-1:W-BW],y3[W-1:W-BW],y4[W-1:W-BW],y5[W-1:W-BW],y6[W-1:W-BW],y7[W-1:W-BW],y8[W-1:W-BW],y9[W-1:W-BW],y10[W-1:W-BW],y11[W-1:W-BW],y12[W-1:W-BW],y13[W-1:W-BW],y14[W-1:W-BW],y15[W-1:W-BW]}};
endmodule
"""

def stage2_module():
    return f"""// 1D-DCT 2nd stage. input {BW1}bit signed (1D result = floor(DCT_1d/8)), output 12bit.
//   y2 = DCT_2d*4 (s2={s2}).  DC(1,1)->y[{DC_HI}:{DC_LO}] (=DCT_2d/2) ; AC->y[{AC_HI}:{AC_LO}] (=DCT_2d*2)
// same re-quantised constants as 1st stage. output interface stays 12bit (Verilog_IO compat).
module DCT_1D_2nd_v6
#( parameter input_BW={BW1}, parameter coeffi_quant={CQ}, parameter SIGNED_IN=1 )
(   input  [16*input_BW-1:0] x_in,
    output [16*12-1:0]       x_out,
    input  signed [coeffi_quant-1:0] {c_list},  // unused
    input is_dc, is_dc2
);
    localparam BW = 12;   // (unused by arith; arith uses input_BW/coeffi_quant)
    {arith_t}
{yblock}
    assign x_out = {{
        (is_dc | is_dc2) ? y0[{DC_HI}:{DC_LO}] : y0[{AC_HI}:{AC_LO}],
        is_dc ? y1[{DC_HI}:{DC_LO}] : y1[{AC_HI}:{AC_LO}], y2[{AC_HI}:{AC_LO}], y3[{AC_HI}:{AC_LO}],
        y4[{AC_HI}:{AC_LO}], y5[{AC_HI}:{AC_LO}], y6[{AC_HI}:{AC_LO}], y7[{AC_HI}:{AC_LO}],
        y8[{AC_HI}:{AC_LO}], y9[{AC_HI}:{AC_LO}], y10[{AC_HI}:{AC_LO}], y11[{AC_HI}:{AC_LO}],
        y12[{AC_HI}:{AC_LO}], y13[{AC_HI}:{AC_LO}], y14[{AC_HI}:{AC_LO}], y15[{AC_HI}:{AC_LO}]
    }};
endmodule
"""

# ---- wrappers from v5 (rename + param change + regenerated debug wires) ----
def grab(modname):
    return re.search(r'module '+modname+r'\b.*?endmodule', V5, re.S).group(0)

top_tb   = grab('top_2D_DCT_v5')
top_syn  = grab('top_2D_DCT_synth_v5')
dct2d    = grab('DCT_2D_v5')
dff128   = grab('D_FF128_v5')
dff192   = grab('D_FF192_v5')
dff128   = dff128.replace('_v5','_v6')
dff192   = dff192.replace('_v5','_v6')

def rn(s):  # v5 -> v6 identifiers
    return s.replace('_v5','_v6')

top_tb  = rn(top_tb).replace('.coeffi_quant(8), .DCT_1st_res_BW(11)',
                             f'.coeffi_quant({CQ}), .DCT_1st_res_BW({BW1})')
top_syn = rn(top_syn)

# DCT_2D: rename, change param defaults, regenerate debug wires for BW1
dct2d = rn(dct2d)
dct2d = dct2d.replace('parameter DCT_1st_res_BW = 11', f'parameter DCT_1st_res_BW = {BW1}')
dct2d = dct2d.replace('parameter coeffi_quant = 8',  f'parameter coeffi_quant = {CQ}')
# re-emit the (unused, interface-compat) c1..c15 at Q1.{CQ-1} so they are not misleading
hexw = (CQ+3)//4
for k in range(1, 16):
    coef = (1/math.sqrt(8))*math.cos(k*math.pi/32)
    q    = round(coef*2**(CQ-1)); act = q/2**(CQ-1)
    newline = (f"assign c{k:<2d} = {CQ}'h{q:0{hexw}X};  "
               f"// {name[k-1]} = {coef:.6f} -> {act:.6f} (err {act-coef:+.6f})")
    dct2d = re.sub(r"assign c%d\b\s*=\s*8'h[0-9A-Fa-f]+;[^\n]*" % k, newline, dct2d)
# strip old debug block (from first '///debugging' to end of module body) and rebuild
dct2d = re.sub(r'\n\s*///debugging.*?(?=endmodule)', '\n', dct2d, flags=re.S)
dbg = ["\n    // ===== debug: per-lane signed split (ModelSim 파형용) ====="]
TOT1 = 16*BW1
for k in range(16):
    hi = TOT1 - BW1*k
    dbg.append(f"    wire signed [{BW1-1}:0] s1_y{k:<2d} = DCT_1st_out[{hi-1} -: {BW1}];")
for k in range(16):
    hi = 192 - 12*k
    dbg.append(f"    wire signed [11:0] s2_y{k:<2d} = x_out2[{hi-1} -: 12];")
dct2d = dct2d.replace('\nendmodule', '\n'+"\n".join(dbg)+"\n\nendmodule", 1)

HEADER = f"""// =====================================================================
//  top_2D_DCT_v6  -  coefficient {CQ}bit ({CQ},{CQ-1})=Q1.{CQ-1}, 1D-DCT result {BW1}bit
//  derived from validated v5 (overflow-fixed) by code/gen_v6.py
//  - all rotation constants re-quantised Q1.7(x128) -> Q1.5(x32)
//  - 1D result / TPMEM_1 width 11->{BW1} bit ; 2nd-stage output stays 12bit
//  - 2nd-stage trunc re-derived: AC=y[{AC_HI}:{AC_LO}], DC=y[{DC_HI}:{DC_LO}]
// =====================================================================

"""

full = (HEADER + top_tb + "\n\n" + top_syn + "\n\n" + dct2d + "\n\n"
        + stage1_module() + "\n" + stage2_module() + "\n"
        + dff128 + "\n\n" + dff192 + "\n")

open('code/top_2D_DCT_v6.v','w',encoding='utf-8').write(full)
print("wrote code/top_2D_DCT_v6.v  (%d lines)" % full.count(chr(10)))
import os
if os.path.exists('code/_v6_parts.txt'): os.remove('code/_v6_parts.txt')

# =====================================================================
#  Synthesis file: code/top_DCT_synth_v6.v  (parameters removed -> literals)
# =====================================================================
WST = 8 + CQ + 2   # = W for both stages (both have input_BW=8, coeffi_quant=CQ)

def evrange(m):
    return f'[{eval(m.group(1))}:{eval(m.group(2))}]'

def flatten(body, signed_in, input_BW=8):
    s = body
    s = re.sub(r'\s*localparam\s+W\s*=\s*[^;]+;', '', s)             # drop localparam W
    if signed_in:                                                   # resolve SIGNED_IN ?:
        s = re.sub(r"SIGNED_IN\s*\?\s*(x_in\[[^\]]+\])\s*:\s*1'b0", r"\1", s)
    else:
        s = re.sub(r"SIGNED_IN\s*\?\s*x_in\[[^\]]+\]\s*:\s*(1'b0)", r"\1", s)
    s = re.sub(r'\binput_BW\b', str(input_BW), s)
    s = re.sub(r'\bcoeffi_quant\b', str(CQ), s)
    s = re.sub(r'\bW\b', str(WST), s)
    s = re.sub(r'\[\s*([0-9][0-9+\-* ]*?)\s*:\s*([0-9][0-9+\-* ]*?)\s*\]', evrange, s)  # eval ranges
    return s

cdecl = f"signed [{CQ-1}:0] " + ",".join(f"c{i}" for i in range(1,16))
ac = f"[{AC_HI}:{AC_LO}]"; dc = f"[{DC_HI}:{DC_LO}]"

syn_stage1 = f"""//===========================================================================
//  DCT_1D_1st : input 8bit (unsigned, zero-extend), output {BW1}bit
//    W = 8+{CQ}+2 = {WST}, coefficient Q1.{CQ-1} (x{2**(CQ-1)}), truncation [{WST-1}:{WST-BW1}]
//===========================================================================
module DCT_1D_1st_v6
(   input  [16*8-1:0]  x_in,
    output [16*{BW1}-1:0] x_out,
    input  {cdecl}  // unused (interface compat)
);
{flatten(arith_t, signed_in=0)}
{flatten(yblock, signed_in=0)}
    assign x_out = {{{','.join(f'y{k}[{WST-1}:{WST-BW1}]' for k in range(16))}}};
endmodule
"""

syn_stage2 = f"""//===========================================================================
//  DCT_1D_2nd : input {BW1}bit (signed, sign-extend), output 12bit
//    W = {BW1}+{CQ}+2 = {WST}, y=DCT_2d*{2**s2}.  DC(1,1)->y{dc} ; AC->y{ac}
//===========================================================================
module DCT_1D_2nd_v6
(   input  [16*{BW1}-1:0] x_in,
    output [16*12-1:0] x_out,
    input  {cdecl},  // unused
    input is_dc, is_dc2
);
{flatten(arith_t, signed_in=1)}
{flatten(yblock, signed_in=1)}
    assign x_out = {{
        (is_dc | is_dc2) ? y0{dc} : y0{ac},
        is_dc ? y1{dc} : y1{ac}, y2{ac}, y3{ac},
        y4{ac}, y5{ac}, y6{ac}, y7{ac},
        y8{ac}, y9{ac}, y10{ac}, y11{ac},
        y12{ac}, y13{ac}, y14{ac}, y15{ac}
    }};
endmodule
"""

# top + DCT_2D wrappers from v5 synth (rename, widths, 6-bit coeff)
SYN = open('code/top_DCT_synth_v5.v', encoding='utf-8', errors='replace').read()
syn_top   = re.search(r'module top_2D_DCT_synth_v5.*?endmodule', SYN, re.S).group(0).replace('_v5','_v6')
syn_dct2d = re.search(r'module DCT_2D_v5.*?endmodule', SYN, re.S).group(0).replace('_v5','_v6')
hexw=(CQ+3)//4
coeffblk="\n".join(f"    assign c{k:<2d} = {CQ}'h{round((1/math.sqrt(8))*math.cos(k*math.pi/32)*2**(CQ-1)):0{hexw}X};"
                   for k in range(1,16))
syn_dct2d = syn_dct2d.replace('wire signed [8-1:0] c1', f'wire signed [{CQ}-1:0] c1')
syn_dct2d = re.sub(r"    assign c1  = 8'h2D;.*?assign c15 = 8'h04;", coeffblk, syn_dct2d, flags=re.S)
syn_dct2d = syn_dct2d.replace('16*11', f'16*{BW1}').replace('.BW(11)', f'.BW({BW1})')

dff128_s = dff128; dff192_s = dff192   # already renamed to _v6
SYN_HEADER = f"""// =====================================================================
//  top_DCT_synth_v6  -  SYNTHESIS (parameters removed, literals)
//  coefficient {CQ}bit Q1.{CQ-1}, 1D result {BW1}bit, output 12bit
//  generated by code/gen_v6.py ; requires TPMEM_16x16.v
// =====================================================================

"""
synfull = (SYN_HEADER + syn_top + "\n\n\n" + syn_dct2d + "\n\n\n"
           + syn_stage1 + "\n" + syn_stage2 + "\n"
           + dff128_s + "\n\n" + dff192_s + "\n")
open('code/top_DCT_synth_v6.v','w',encoding='utf-8').write(synfull)
print("wrote code/top_DCT_synth_v6.v  (%d lines)" % synfull.count(chr(10)))
