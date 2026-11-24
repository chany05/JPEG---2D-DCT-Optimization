onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix hexadecimal /sti_project2/clk
add wave -noupdate /sti_project2/top/DCT/TP_MEM_1/array
add wave -noupdate /sti_project2/top/DCT/TP_MEM_1/BW
add wave -noupdate /sti_project2/top/DCT/TP_MEM_1/col
add wave -noupdate -radix unsigned /sti_project2/top/DCT/TP_MEM_1/counter
add wave -noupdate /sti_project2/top/DCT/TP_MEM_1/data_out
add wave -noupdate /sti_project2/top/DCT/TP_MEM_1/i_clk
add wave -noupdate /sti_project2/top/DCT/TP_MEM_1/i_data
add wave -noupdate /sti_project2/top/DCT/TP_MEM_1/i_Reset
add wave -noupdate /sti_project2/top/DCT/TP_MEM_1/index
add wave -noupdate /sti_project2/top/DCT/TP_MEM_1/o_data
add wave -noupdate /sti_project2/top/DCT/TP_MEM_1/o_en
add wave -noupdate /sti_project2/top/DCT/TP_MEM_1/w_data
add wave -noupdate /sti_project2/top/DCT/TP_MEM_1/w_en
add wave -noupdate -radix hexadecimal /sti_project2/fp
add wave -noupdate -radix hexadecimal /sti_project2/i
add wave -noupdate -radix hexadecimal /sti_project2/rstn
add wave -noupdate -radix binary /sti_project2/top/DCT/TPmem_out1
add wave -noupdate -radix hexadecimal /sti_project2/top/DCT/counter
add wave -noupdate -radix unsigned -childformat {{{/sti_project2/top/DCT/counter_TP12[4]} -radix unsigned} {{/sti_project2/top/DCT/counter_TP12[3]} -radix unsigned} {{/sti_project2/top/DCT/counter_TP12[2]} -radix unsigned} {{/sti_project2/top/DCT/counter_TP12[1]} -radix unsigned} {{/sti_project2/top/DCT/counter_TP12[0]} -radix unsigned}} -subitemconfig {{/sti_project2/top/DCT/counter_TP12[4]} {-height 15 -radix unsigned} {/sti_project2/top/DCT/counter_TP12[3]} {-height 15 -radix unsigned} {/sti_project2/top/DCT/counter_TP12[2]} {-height 15 -radix unsigned} {/sti_project2/top/DCT/counter_TP12[1]} {-height 15 -radix unsigned} {/sti_project2/top/DCT/counter_TP12[0]} {-height 15 -radix unsigned}} /sti_project2/top/DCT/counter_TP12
add wave -noupdate /sti_project2/top/DCT/DCT_1st_out
add wave -noupdate /sti_project2/top/DCT/DCT_2st/overflow
add wave -noupdate -expand -group DCT_1D /sti_project2/top/DCT/DCT_1st/x0
add wave -noupdate -expand -group DCT_1D /sti_project2/top/DCT/DCT_1st/x1
add wave -noupdate -expand -group DCT_1D /sti_project2/top/DCT/DCT_1st/x2
add wave -noupdate -expand -group DCT_1D /sti_project2/top/DCT/DCT_1st/x3
add wave -noupdate -expand -group DCT_1D /sti_project2/top/DCT/DCT_1st/x4
add wave -noupdate -expand -group DCT_1D /sti_project2/top/DCT/DCT_1st/x5
add wave -noupdate -expand -group DCT_1D /sti_project2/top/DCT/DCT_1st/x6
add wave -noupdate -expand -group DCT_1D /sti_project2/top/DCT/DCT_1st/x7
add wave -noupdate -expand -group DCT_1D /sti_project2/top/DCT/DCT_1st/x8
add wave -noupdate -expand -group DCT_1D /sti_project2/top/DCT/DCT_1st/x9
add wave -noupdate -expand -group DCT_1D /sti_project2/top/DCT/DCT_1st/x10
add wave -noupdate -expand -group DCT_1D /sti_project2/top/DCT/DCT_1st/x11
add wave -noupdate -expand -group DCT_1D /sti_project2/top/DCT/DCT_1st/x12
add wave -noupdate -expand -group DCT_1D /sti_project2/top/DCT/DCT_1st/x13
add wave -noupdate -expand -group DCT_1D /sti_project2/top/DCT/DCT_1st/x14
add wave -noupdate -expand -group DCT_1D /sti_project2/top/DCT/DCT_1st/x15
add wave -noupdate /sti_project2/top/DCT/s1_y0
add wave -noupdate /sti_project2/top/DCT/s1_y1
add wave -noupdate /sti_project2/top/DCT/s1_y2
add wave -noupdate /sti_project2/top/DCT/s1_y3
add wave -noupdate /sti_project2/top/DCT/s1_y4
add wave -noupdate /sti_project2/top/DCT/s1_y5
add wave -noupdate /sti_project2/top/DCT/s1_y6
add wave -noupdate /sti_project2/top/DCT/s1_y7
add wave -noupdate /sti_project2/top/DCT/s1_y8
add wave -noupdate /sti_project2/top/DCT/s1_y9
add wave -noupdate /sti_project2/top/DCT/s1_y10
add wave -noupdate /sti_project2/top/DCT/s1_y11
add wave -noupdate -expand -group DCT_2nd -expand -group y2 /sti_project2/top/DCT/s2_y0
add wave -noupdate -expand -group DCT_2nd -expand -group y2 /sti_project2/top/DCT/s2_y1
add wave -noupdate -expand -group DCT_2nd -expand -group y2 /sti_project2/top/DCT/s2_y2
add wave -noupdate -expand -group DCT_2nd -expand -group y2 /sti_project2/top/DCT/s2_y3
add wave -noupdate -expand -group DCT_2nd -expand -group y2 /sti_project2/top/DCT/s2_y4
add wave -noupdate -expand -group DCT_2nd -expand -group y2 /sti_project2/top/DCT/s2_y5
add wave -noupdate -expand -group DCT_2nd -expand -group y2 /sti_project2/top/DCT/s2_y6
add wave -noupdate -expand -group DCT_2nd -expand -group y2 /sti_project2/top/DCT/s2_y7
add wave -noupdate -expand -group DCT_2nd -expand -group y2 /sti_project2/top/DCT/s2_y8
add wave -noupdate -expand -group DCT_2nd -expand -group y2 /sti_project2/top/DCT/s2_y9
add wave -noupdate -expand -group DCT_2nd -expand -group y2 /sti_project2/top/DCT/s2_y10
add wave -noupdate -expand -group DCT_2nd -expand -group y2 /sti_project2/top/DCT/s2_y11
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {24305660 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 151
configure wave -valuecolwidth 102
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {24259420 ps} {24435980 ps}
