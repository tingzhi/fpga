module bcd_to_7seg (
	input [3:0] bcd,
	output [6:0] seg_digits // logic is added for modelsim
);
	always_comb begin
                unique case (bcd)
                        4'b0000 : seg_digits = 7'b0000001; // 0
                        4'b0001 : seg_digits = 7'b1001111; // 1
                        4'b0010 : seg_digits = 7'b0010010; // 2
                        4'b0011 : seg_digits = 7'b0000110; // 3
                        4'b0100 : seg_digits = 7'b1001100; // 4
                        4'b0101 : seg_digits = 7'b0100100; // 5
                        4'b0110 : seg_digits = 7'b0100000; // 6
                        4'b0111 : seg_digits = 7'b0001111; // 7
                        4'b1000 : seg_digits = 7'b0000000; // 8
                        4'b1001 : seg_digits = 7'b0000100; // 9
                       // default : seg_digits = 7'b1111111;      // when receive any code out of 0-9, display nothing
                endcase
        end
endmodule

