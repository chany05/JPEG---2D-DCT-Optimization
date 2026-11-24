import re, os

def gen_tpmem(rows, cols, modname, BW_default=9):
    L = []
    L.append(f"// {rows}행x{cols}열 전치 메모리 (1st stage용, {rows}lane 출력)")
    L.append(f"module {modname}")
    L.append(f"#( parameter BW = {BW_default} )")
    L.append(f"(  input        [{rows}*BW-1:0] i_data,")
    L.append(f"   input                    i_clk,")
    L.append(f"   input                    i_Reset,")
    L.append(f"   output reg   [{rows}*BW-1:0] o_data,")
    L.append(f"   output reg               o_en")
    L.append(f");")
    L.append(f"reg  [5-1:0]      counter;")
    L.append(f"reg  [{rows}*BW-1:0]  array [{cols}-1:0];")
    L.append(f"reg  [{rows}*BW-1:0]  data_out;")
    L.append(f"wire [{rows}*BW-1:0]  col   [{cols}-1:0];")
    L.append(f"wire [4-1:0]      index = counter[4-1:0];")
    L.append(f"wire [{rows}*BW-1:0]  w_data;")
    L.append(f"wire              w_en;")
    L.append(f"always@(posedge i_clk) begin")
    L.append(f"    if(~i_Reset) begin")
    L.append(f"        counter <= 5'd31;")
    L.append(f"        o_data  <= {{{rows}*BW{{1'b0}}}};")
    L.append(f"        o_en    <= 1'b0;")
    L.append(f"    end else begin")
    L.append(f"        o_data  <= w_data; o_en <= w_en;")
    L.append(f"        counter <= counter + 5'b1;")
    L.append(f"    end")
    L.append(f"end")
    L.append(f"always@(*) begin")
    L.append(f"    if (counter[4]==1'b0)")
    L.append(f"        data_out = (index < 4'd{cols}) ? array[index] : {{{rows}*BW{{1'b0}}}};")
    L.append(f"    else")
    L.append(f"        data_out = (index < 4'd{rows}) ? col[index]   : {{{rows}*BW{{1'b0}}}};")
    L.append(f"end")
    L.append(f"always@(posedge i_clk) begin")
    L.append(f"    if(~i_Reset) begin")
    for c in range(cols):
        L.append(f"        array[{c:2d}] <= {{{rows}*BW{{1'b0}}}};")
    L.append(f"    end else begin")
    L.append(f"        if (counter[4]==1'b0) begin")
    L.append(f"            if (index < 4'd{cols}) array[index] <= i_data;")
    L.append(f"        end else begin")
    L.append(f"            case (index)")
    for r in range(rows):
        slot_hi = rows - r
        slot_lo = rows - r - 1
        L.append(f"            4'd{r}: begin")
        for row in range(rows):
            lane_hi = rows - row
            lane_lo = rows - row - 1
            L.append(f"                array[{row:2d}][{slot_hi}*BW-1:{slot_lo}*BW] <= i_data[{lane_hi}*BW-1:{lane_lo}*BW];")
        L.append(f"            end")
    L.append(f"            default: ;")
    L.append(f"            endcase")
    L.append(f"        end")
    L.append(f"    end")
    L.append(f"end")
    for r in range(rows):
        slot_hi = rows - r
        slot_lo = rows - r - 1
        parts = ", ".join(f"array[{c:2d}][{slot_hi}*BW-1:{slot_lo}*BW]" for c in range(cols))
        L.append(f"assign col[{r:2d}] = {{{parts}}};")
    for r in range(rows, cols):
        L.append(f"assign col[{r:2d}] = {{{rows}*BW{{1'b0}}}};")
    L.append(f"assign w_en   = counter[4];")
    L.append(f"assign w_data = data_out;")
    L.append(f"endmodule")
    return "\n".join(L)

tpmem_12x16 = gen_tpmem(12, 16, "TPmem_12x16_single_1st", 9)

src = open("code/top_2D_DCT_v8.v", encoding="utf-8").read()

# v8 -> v9
out = src.replace("_v8", "_v9")

# ── DCT_2D_v9: 1st out/mem 폭 ──
out = out.replace("[16*9-1:0] DCT_1st_out;", "[12*9-1:0] DCT_1st_out;")
out = out.replace("[16*9-1:0] TPmem_out1;", "[12*9-1:0] TPmem_out1;")
out = out.replace("[16*9-1:0] x_in2 = TPmem_out1;", "[12*9-1:0] x_in2 = TPmem_out1;")
out = out.replace(
    "TPmem_16x16_single_1st #(.BW(9)) TP_MEM_1(.i_data(DCT_1st_out),",
    "TPmem_12x16_single_1st #(.BW(9)) TP_MEM_1(.i_data(DCT_1st_out),"
)

# ── DCT_1D_1st_v9: output 포트 ──
out = out.replace(
    "    output [16*9-1:0] x_out,\n    input  signed [5:0] c1",
    "    output [12*9-1:0] x_out,\n    input  signed [5:0] c1"
)

# ── DCT_1D_1st_v9: y 선언+assign (y12~y15 제거, B 제거) ──
OLD_1ST_Y = (
    "    wire signed [15:0] y0,y1,y2,y3,y4,y5,y6,y7,y8,y9,y10,y11,y12,y13,y14,y15;\n\n    \n"
    "assign y0 = 8*(sss0+sss1); //2point even dct\n"
    "    assign y8 = 8*(sss0-sss1); //2point even dct\n\n"
    "    assign y1 = A_o8_y10+A_o8_y11+A_o8_y12+A_o8_y13;\n"
    "    assign y2 = A_o4_y20+A_o4_y21;\n"
    "    assign y3 = A_o8_y30+A_o8_y31+A_o8_y32+A_o8_y33;\n"
    "    assign y4 = A_o2_y40;\n"
    "    assign y5 = A_o8_y50+A_o8_y51+A_o8_y52+A_o8_y53;\n"
    "    assign y6 = A_o4_y60+A_o4_y61;\n"
    "    assign y7 = A_o8_y70+A_o8_y71+A_o8_y72+A_o8_y73;\n"
    "    assign y9 = B_o8_y70+B_o8_y71+B_o8_y72+B_o8_y73;\n"
    "    assign y10 = B_o4_y60+B_o4_y61;\n"
    "    assign y11 = B_o8_y50+B_o8_y51+B_o8_y52+B_o8_y53;\n"
    "    assign y12 = B_o2_y40;\n"
    "    assign y13 = B_o8_y30+B_o8_y31+B_o8_y32+B_o8_y33;\n"
    "    assign y14 = B_o4_y20+B_o4_y21;\n"
    "    assign y15 = B_o8_y10+B_o8_y11+B_o8_y12+B_o8_y13;\n"
    "    assign x_out = {y0[15:7],y1[15:7],y2[15:7],y3[15:7],y4[15:7],y5[15:7],y6[15:7],\n"
    "                y7[15:7],y8[15:7],y9[15:7],y10[15:7],y11[15:7],\n"
    "                9'h000,9'h000,9'h000,9'h000};"
)
NEW_1ST_Y = (
    "    wire signed [15:0] y0,y1,y2,y3,y4,y5,y6,y7,y8,y9,y10,y11;\n"
    "    assign y0  = 8*(sss0+sss1);\n"
    "    assign y8  = 8*(sss0-sss1);\n"
    "    assign y1  = A_o8_y10+A_o8_y11+A_o8_y12+A_o8_y13;\n"
    "    assign y2  = A_o4_y20+A_o4_y21;\n"
    "    assign y3  = A_o8_y30+A_o8_y31+A_o8_y32+A_o8_y33;\n"
    "    assign y4  = A_o2_y40;\n"
    "    assign y5  = A_o8_y50+A_o8_y51+A_o8_y52+A_o8_y53;\n"
    "    assign y6  = A_o4_y60+A_o4_y61;\n"
    "    assign y7  = A_o8_y70+A_o8_y71+A_o8_y72+A_o8_y73;\n"
    "    assign y9  = B_o8_y70+B_o8_y71+B_o8_y72+B_o8_y73;\n"
    "    assign y10 = B_o4_y60+B_o4_y61;\n"
    "    assign y11 = B_o8_y50+B_o8_y51+B_o8_y52+B_o8_y53;\n"
    "    assign x_out = {y0[15:7],y1[15:7],y2[15:7],y3[15:7],y4[15:7],y5[15:7],\n"
    "                y6[15:7],y7[15:7],y8[15:7],y9[15:7],y10[15:7],y11[15:7]};"
)
if OLD_1ST_Y in out:
    out = out.replace(OLD_1ST_Y, NEW_1ST_Y)
    print("1st y block: replaced")
else:
    print("WARN: 1st y block not found, trying regex")
    # fallback regex
    out = re.sub(
        r'wire signed \[15:0\] y0.*?9\'h000,9\'h000,9\'h000,9\'h000\};',
        NEW_1ST_Y, out, flags=re.S
    )

# ── DCT_1D_2nd_v9: input 포트 ──
out = out.replace(
    "    input  [16*9-1:0] x_in,\n    output [16*12-1:0] x_out,",
    "    input  [12*9-1:0] x_in,\n    output [16*12-1:0] x_out,"
)

# ── DCT_1D_2nd_v9: x 파싱 (12lane + x12~x15=0) ──
OLD_XPARSE = (
    "    assign x15 = {x_in[9*1-1],  x_in[9*1-1:9*0]};\n"
    "    assign x0  = {x_in[9*16-1], x_in[9*16-1:9*15]};\n"
    "    assign x14 = {x_in[9*2-1],  x_in[9*2-1:9*1]};\n"
    "    assign x1  = {x_in[9*15-1], x_in[9*15-1:9*14]};\n"
    "    assign x13 = {x_in[9*3-1],  x_in[9*3-1:9*2]};\n"
    "    assign x2  = {x_in[9*14-1], x_in[9*14-1:9*13]};\n"
    "    assign x12 = {x_in[9*4-1],  x_in[9*4-1:9*3]};\n"
    "    assign x3  = {x_in[9*13-1], x_in[9*13-1:9*12]};\n"
    "    assign x11 = {x_in[9*5-1],  x_in[9*5-1:9*4]};\n"
    "    assign x4  = {x_in[9*12-1], x_in[9*12-1:9*11]};\n"
    "    assign x10 = {x_in[9*6-1],  x_in[9*6-1:9*5]};\n"
    "    assign x5  = {x_in[9*11-1], x_in[9*11-1:9*10]};\n"
    "    assign x9  = {x_in[9*7-1],  x_in[9*7-1:9*6]};\n"
    "    assign x6  = {x_in[9*10-1], x_in[9*10-1:9*9]};\n"
    "    assign x8  = {x_in[9*8-1],  x_in[9*8-1:9*7]};\n"
    "    assign x7  = {x_in[9*9-1],  x_in[9*9-1:9*8]};"
)
NEW_XPARSE = (
    "    // 12lane 입력: x0=MSB(주파수0), ..., x11=주파수11\n"
    "    assign x0  = {x_in[9*12-1], x_in[9*12-1:9*11]};\n"
    "    assign x1  = {x_in[9*11-1], x_in[9*11-1:9*10]};\n"
    "    assign x2  = {x_in[9*10-1], x_in[9*10-1:9*9]};\n"
    "    assign x3  = {x_in[9*9-1],  x_in[9*9-1:9*8]};\n"
    "    assign x4  = {x_in[9*8-1],  x_in[9*8-1:9*7]};\n"
    "    assign x5  = {x_in[9*7-1],  x_in[9*7-1:9*6]};\n"
    "    assign x6  = {x_in[9*6-1],  x_in[9*6-1:9*5]};\n"
    "    assign x7  = {x_in[9*5-1],  x_in[9*5-1:9*4]};\n"
    "    assign x8  = {x_in[9*4-1],  x_in[9*4-1:9*3]};\n"
    "    assign x9  = {x_in[9*3-1],  x_in[9*3-1:9*2]};\n"
    "    assign x10 = {x_in[9*2-1],  x_in[9*2-1:9*1]};\n"
    "    assign x11 = {x_in[9*1-1],  x_in[9*1-1:9*0]};\n"
    "    wire signed [9:0] x12=10'd0, x13=10'd0, x14=10'd0, x15=10'd0;"
)
if OLD_XPARSE in out:
    out = out.replace(OLD_XPARSE, NEW_XPARSE)
    print("2nd xparse: replaced")
else:
    print("WARN: 2nd xparse not found")

# ── DCT_1D_2nd_v9: y 선언 (y12~y15 제거, B 일부 삭제) ──
OLD_2ND_Y = (
    "    wire signed [16:0] y0,y1,y2,y3,y4,y5,y6,y7,y8,y9,y10,y11,y12,y13,y14,y15;\n\n"
    "    assign y0 = 8*(sss0+sss1);\n"
    "    assign y8 = 8*(sss0-sss1);\n"
    "    assign y1 = A_o8_y10+A_o8_y11+A_o8_y12+A_o8_y13;\n"
    "    assign y2 = A_o4_y20+A_o4_y21;\n"
    "    assign y3 = A_o8_y30+A_o8_y31+A_o8_y32+A_o8_y33;\n"
    "    assign y4 = A_o2_y40;\n"
    "    assign y5 = A_o8_y50+A_o8_y51+A_o8_y52+A_o8_y53;\n"
    "    assign y6 = A_o4_y60+A_o4_y61;\n"
    "    assign y7 = A_o8_y70+A_o8_y71+A_o8_y72+A_o8_y73;\n"
    "    assign y9 = B_o8_y70+B_o8_y71+B_o8_y72+B_o8_y73;\n"
    "    assign y10 = B_o4_y60+B_o4_y61;\n"
    "    assign y11 = B_o8_y50+B_o8_y51+B_o8_y52+B_o8_y53;\n"
    "    assign y12 = B_o2_y40;\n"
    "    assign y13 = B_o8_y30+B_o8_y31+B_o8_y32+B_o8_y33;\n"
    "    assign y14 = B_o4_y20+B_o4_y21;\n"
    "    assign y15 = B_o8_y10+B_o8_y11+B_o8_y12+B_o8_y13;\n"
    "    assign x_out = {\n"
    "        (is_dc | is_dc2) ? y0[15:4] : y0[13:2],\n"
    "        is_dc ? y1[15:4] : y1[13:2], y2[13:2], y3[13:2],\n"
    "        y4[13:2], y5[13:2], y6[13:2], y7[13:2],\n"
    "        y8[13:2], y9[13:2], y10[13:2], y11[13:2],\n"
    "        12'h000, 12'h000, 12'h000, 12'h000\n"
    "    };"
)
NEW_2ND_Y = (
    "    wire signed [16:0] y0,y1,y2,y3,y4,y5,y6,y7,y8,y9,y10,y11;\n"
    "    assign y0  = 8*(sss0+sss1);\n"
    "    assign y8  = 8*(sss0-sss1);\n"
    "    assign y1  = A_o8_y10+A_o8_y11+A_o8_y12+A_o8_y13;\n"
    "    assign y2  = A_o4_y20+A_o4_y21;\n"
    "    assign y3  = A_o8_y30+A_o8_y31+A_o8_y32+A_o8_y33;\n"
    "    assign y4  = A_o2_y40;\n"
    "    assign y5  = A_o8_y50+A_o8_y51+A_o8_y52+A_o8_y53;\n"
    "    assign y6  = A_o4_y60+A_o4_y61;\n"
    "    assign y7  = A_o8_y70+A_o8_y71+A_o8_y72+A_o8_y73;\n"
    "    assign y9  = B_o8_y70+B_o8_y71+B_o8_y72+B_o8_y73;\n"
    "    assign y10 = B_o4_y60+B_o4_y61;\n"
    "    assign y11 = B_o8_y50+B_o8_y51+B_o8_y52+B_o8_y53;\n"
    "    assign x_out = {\n"
    "        (is_dc | is_dc2) ? y0[15:4] : y0[13:2],\n"
    "        is_dc ? y1[15:4] : y1[13:2], y2[13:2], y3[13:2],\n"
    "        y4[13:2], y5[13:2], y6[13:2], y7[13:2],\n"
    "        y8[13:2], y9[13:2], y10[13:2], y11[13:2],\n"
    "        12'h000, 12'h000, 12'h000, 12'h000\n"
    "    };"
)
if OLD_2ND_Y in out:
    out = out.replace(OLD_2ND_Y, NEW_2ND_Y)
    print("2nd y block: replaced")
else:
    print("WARN: 2nd y block not found, regex fallback")
    out = re.sub(
        r'wire signed \[16:0\] y0.*?12\'h000\n    \};',
        NEW_2ND_Y, out, flags=re.S
    )

# ── debug wire s1: 12개 ──
old_dbg = (
    "    // 1st out: 16x9bit = 144bit\n"
    "    wire signed [8:0] s1_y0  = DCT_1st_out[144-1  -: 9];\n"
    "    wire signed [8:0] s1_y1  = DCT_1st_out[135-1  -: 9];\n"
    "    wire signed [8:0] s1_y2  = DCT_1st_out[126-1  -: 9];\n"
    "    wire signed [8:0] s1_y3  = DCT_1st_out[117-1  -: 9];\n"
    "    wire signed [8:0] s1_y4  = DCT_1st_out[108-1  -: 9];\n"
    "    wire signed [8:0] s1_y5  = DCT_1st_out[ 99-1  -: 9];\n"
    "    wire signed [8:0] s1_y6  = DCT_1st_out[ 90-1  -: 9];\n"
    "    wire signed [8:0] s1_y7  = DCT_1st_out[ 81-1  -: 9];\n"
    "    wire signed [8:0] s1_y8  = DCT_1st_out[ 72-1  -: 9];\n"
    "    wire signed [8:0] s1_y9  = DCT_1st_out[ 63-1  -: 9];\n"
    "    wire signed [8:0] s1_y10 = DCT_1st_out[ 54-1  -: 9];\n"
    "    wire signed [8:0] s1_y11 = DCT_1st_out[ 45-1  -: 9];\n"
    "    wire signed [8:0] s1_y12 = DCT_1st_out[ 36-1  -: 9];\n"
    "    wire signed [8:0] s1_y13 = DCT_1st_out[ 27-1  -: 9];\n"
    "    wire signed [8:0] s1_y14 = DCT_1st_out[ 18-1  -: 9];\n"
    "    wire signed [8:0] s1_y15 = DCT_1st_out[  9-1  -: 9];"
)
new_dbg = (
    "    // 1st out: 12x9bit = 108bit\n"
    "    wire signed [8:0] s1_y0  = DCT_1st_out[108-1  -: 9];\n"
    "    wire signed [8:0] s1_y1  = DCT_1st_out[ 99-1  -: 9];\n"
    "    wire signed [8:0] s1_y2  = DCT_1st_out[ 90-1  -: 9];\n"
    "    wire signed [8:0] s1_y3  = DCT_1st_out[ 81-1  -: 9];\n"
    "    wire signed [8:0] s1_y4  = DCT_1st_out[ 72-1  -: 9];\n"
    "    wire signed [8:0] s1_y5  = DCT_1st_out[ 63-1  -: 9];\n"
    "    wire signed [8:0] s1_y6  = DCT_1st_out[ 54-1  -: 9];\n"
    "    wire signed [8:0] s1_y7  = DCT_1st_out[ 45-1  -: 9];\n"
    "    wire signed [8:0] s1_y8  = DCT_1st_out[ 36-1  -: 9];\n"
    "    wire signed [8:0] s1_y9  = DCT_1st_out[ 27-1  -: 9];\n"
    "    wire signed [8:0] s1_y10 = DCT_1st_out[ 18-1  -: 9];\n"
    "    wire signed [8:0] s1_y11 = DCT_1st_out[  9-1  -: 9];"
)
if old_dbg in out:
    out = out.replace(old_dbg, new_dbg)
    print("debug s1: replaced")
else:
    print("WARN: debug s1 not found")

# ── TPmem_12x16_single_1st 모듈 삽입 ──
out = out.replace("module D_FF128_v9", tpmem_12x16 + "\n\nmodule D_FF128_v9", 1)

# 저장
open("code/top_2D_DCT_v9.v", "w", encoding="utf-8").write(out)
print(f"wrote {len(out.splitlines())} lines -> code/top_2D_DCT_v9.v")

# 검증
checks = [
    ("[12*9-1:0] DCT_1st_out", True),
    ("TPmem_12x16_single_1st", True),
    ("wire signed [15:0] y0,y1,y2,y3,y4,y5,y6,y7,y8,y9,y10,y11;", True),
    ("wire signed [16:0] y0,y1,y2,y3,y4,y5,y6,y7,y8,y9,y10,y11;", True),
    ("[12*9-1:0] x_in,", True),
    ("x12=10'd0", True),
    ("s1_y11 = DCT_1st_out[  9-1  -: 9]", True),
    ("[16*9-1:0]", False),  # 이게 없어야 함
]
for s, expect in checks:
    found = s in out
    ok = found == expect
    print(f"  [{'OK' if ok else 'FAIL'}] '{s[:55]}' expect={expect} got={found}")
