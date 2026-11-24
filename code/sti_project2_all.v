`timescale 1ns / 10ps
// sti_project2_all.v
// image_in_1~8 을 8개 DUT에 병렬로 넣고 동시에 DCT_image_1~8.txt 출력

module sti_project2_all;

reg clk;
reg rstn;

// ── 8개 DUT ──────────────────────────────────────────────
top_2D_DCT_v7 top1(clk, rstn);
top_2D_DCT_v7 top2(clk, rstn);
top_2D_DCT_v7 top3(clk, rstn);
top_2D_DCT_v7 top4(clk, rstn);
top_2D_DCT_v7 top5(clk, rstn);
top_2D_DCT_v7 top6(clk, rstn);
top_2D_DCT_v7 top7(clk, rstn);
top_2D_DCT_v7 top8(clk, rstn);

// ── 클럭 / 리셋 ──────────────────────────────────────────
always #5 clk <= ~clk;

initial begin
    clk = 1; rstn = 0;
    #30
    rstn = 1;
end

// ── 입력 이미지 로드 ──────────────────────────────────────
initial $readmemh("image_in_1.txt", top1.MEM_IN.array);
initial $readmemh("image_in_2.txt", top2.MEM_IN.array);
initial $readmemh("image_in_3.txt", top3.MEM_IN.array);
initial $readmemh("image_in_4.txt", top4.MEM_IN.array);
initial $readmemh("image_in_5.txt", top5.MEM_IN.array);
initial $readmemh("image_in_6.txt", top6.MEM_IN.array);
initial $readmemh("image_in_7.txt", top7.MEM_IN.array);
initial $readmemh("image_in_8.txt", top8.MEM_IN.array);

// ── 출력 덤프 (8개 동시, 같은 타이밍) ───────────────────
integer i;
integer fp1, fp2, fp3, fp4, fp5, fp6, fp7, fp8;

initial begin
    fp1 = $fopen("DCT_image_1.txt","w");
    fp2 = $fopen("DCT_image_2.txt","w");
    fp3 = $fopen("DCT_image_3.txt","w");
    fp4 = $fopen("DCT_image_4.txt","w");
    fp5 = $fopen("DCT_image_5.txt","w");
    fp6 = $fopen("DCT_image_6.txt","w");
    fp7 = $fopen("DCT_image_7.txt","w");
    fp8 = $fopen("DCT_image_8.txt","w");

    #164210;

    for (i = 0; i < 16384; i = i+1) begin
        $fwrite(fp1, "%b\n", top1.MEM_OUT.array[i]);
        $fwrite(fp2, "%b\n", top2.MEM_OUT.array[i]);
        $fwrite(fp3, "%b\n", top3.MEM_OUT.array[i]);
        $fwrite(fp4, "%b\n", top4.MEM_OUT.array[i]);
        $fwrite(fp5, "%b\n", top5.MEM_OUT.array[i]);
        $fwrite(fp6, "%b\n", top6.MEM_OUT.array[i]);
        $fwrite(fp7, "%b\n", top7.MEM_OUT.array[i]);
        $fwrite(fp8, "%b\n", top8.MEM_OUT.array[i]);
    end

    #100
    $fclose(fp1); $fclose(fp2); $fclose(fp3); $fclose(fp4);
    $fclose(fp5); $fclose(fp6); $fclose(fp7); $fclose(fp8);

    $finish;
end

endmodule
