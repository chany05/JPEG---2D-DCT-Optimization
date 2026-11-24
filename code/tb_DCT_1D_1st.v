//-----------------------------------------------------------------------------
// Multi-vector 16-point 1D DCT testbench
//   - reads N stimulus blocks produced by gen_tb_DCT.m
//   - applies each block to DCT_1D_1st with #VEC_PERIOD spacing
//   - compares the (combinational) x_out against pre-packed golden bytes
//
//   inputs (place in simulation working dir):
//     tb_input.hex   : N lines, 32-hex-digit packed pixels (x0 = LSB byte)
//     tb_golden.hex  : N lines, ceil(16*BW/4)-hex-digit packed truncated y
//                      (y0 = MSB byte, matching DCT.v x_out concat order)
//
//   NOTE: $readmemh resolves the path relative to the simulator's working
//         directory (vsim cwd), NOT this file's location. If golden_y shows
//         X in ModelSim, the file wasn't found -- copy the .hex files into
//         the vsim work dir, or run vsim from c:/.../code/.
//
//   parameters:
//     NUM_VEC : number of test vectors (must match num_vectors in matlab)
//     BW      : output truncation width per y_k (must match DCT.v BW arg)
//-----------------------------------------------------------------------------
`timescale 1ns/1ps

module tb_DCT_1D_1st;

    localparam NUM_VEC    = 8;
    localparam BW         = 8;
    localparam VEC_PERIOD = 20;            // ns between vector applies
    localparam OUT_W      = 16 * BW;       // total x_out width
    localparam IN_W       = 16 * 8;        // total x_in width

    //------------------------------------------------------------------ DUT --
    reg  [IN_W-1:0]   x_in;
    wire [OUT_W-1:0]  x_out;

    DCT_1D_1st #(.BW(BW)) dut (
        .x_in (x_in),
        .x_out(x_out)
    );

    //----------------------------------------------------------- file mem --
    reg [IN_W-1:0]  in_mem   [0:NUM_VEC-1];
    reg [OUT_W-1:0] gold_mem [0:NUM_VEC-1];

    //----------------------------------------------------------- compare --
    integer vec, k;
    integer pass_cnt, fail_cnt;
    reg [BW-1:0] dut_byte, gold_byte;
    reg signed [BW-1:0] dut_signed, gold_signed;

    initial begin
        // ---- load files ------------------------------------------------
        $readmemh("tb_input.hex",  in_mem);
        $readmemh("tb_golden.hex", gold_mem);

        // ---- sanity : detect file-not-found (entries left X) -----------
        if (^in_mem[0] === 1'bx) begin
            $display("[FATAL] tb_input.hex not loaded.  vsim cwd != .hex dir?");
            $finish;
        end
        if (^gold_mem[0] === 1'bx) begin
            $display("[FATAL] tb_golden.hex not loaded.  vsim cwd != .hex dir?");
            $finish;
        end

        $display("============================================================");
        $display("  DCT_1D_1st  --  %0d vector(s), BW=%0d", NUM_VEC, BW);
        $display("============================================================");

        pass_cnt = 0;
        fail_cnt = 0;

        // ---- loop : apply each vector, settle, compare -----------------
        for (vec = 0; vec < NUM_VEC; vec = vec + 1) begin

            x_in = in_mem[vec];
            #VEC_PERIOD;                              // settle comb paths

            $display("------------------------------------------------------------");
            $display("  vec %0d   t=%0t   x_in = %h", vec, $time, x_in);

            for (k = 0; k < 16; k = k + 1) begin
                // y0 is at MSB position (k=0 -> bits [OUT_W-1 : OUT_W-BW]).
                dut_byte    =     x_out [BW*(15-k) +: BW];
                gold_byte   = gold_mem[vec][BW*(15-k) +: BW];
                dut_signed  = dut_byte;
                gold_signed = gold_byte;

                if (dut_byte === gold_byte) begin
                    $display("    y%-2d  PASS  dut=%h(%6d)  gold=%h(%6d)",
                             k, dut_byte, dut_signed, gold_byte, gold_signed);
                    pass_cnt = pass_cnt + 1;
                end else begin
                    $display("    y%-2d  FAIL  dut=%h(%6d)  gold=%h(%6d)  diff=%0d  <==",
                             k, dut_byte, dut_signed, gold_byte, gold_signed,
                             dut_signed - gold_signed);
                    fail_cnt = fail_cnt + 1;
                end
            end
        end

        // ---- summary ---------------------------------------------------
        $display("============================================================");
        if (fail_cnt == 0)
            $display("  RESULT: ALL %0d/%0d PASS", pass_cnt, NUM_VEC*16);
        else
            $display("  RESULT: %0d pass, %0d FAIL  (total %0d)",
                     pass_cnt, fail_cnt, NUM_VEC*16);
        $display("============================================================");

        $finish;
    end

endmodule
