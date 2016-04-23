module lab3 (
	input		[7:0]	buttons,
	output	[6:0]	seg_digits,
	output	[2:0]	sel,
	output 	en_n,
	output	pwm,
	output	en
);

	logic [2:0] encoder_out;
	logic [3:0] mux_output;
	assign en_n = 1'b0;
	assign pwm = 1'b0;
	assign en =1'b1;
	//Seven segment control code here
	
	// 8 to 3 encoder
	always_comb begin
		case (buttons)
			8'b11110111 : encoder_out = 3'b011;
			8'b11111011 : encoder_out = 3'b010;
			8'b11111101 : encoder_out = 3'b001;
			8'b11111110 : encoder_out = 3'b000;
			default     : encoder_out = 3'b111; 
		endcase
	end
	
	//  8 to 3 encoder's decoder for 7 seg display
	always_comb begin
	  case (encoder_out)
			3'b000 : sel = 3'b000;
			3'b001 : sel = 3'b001;
			3'b010 : sel = 3'b011;
			3'b011 : sel = 3'b100;
			default: sel = 3'b101; // select 6th digit	
		endcase		
	end

	// 4 to 1 mux for last 4 digits of my student id
	always_comb begin
		case (encoder_out)
			3'b011 : mux_output = 4'b0110; // 6 in decimal
			3'b010 : mux_output = 4'b0011; // 3 in decimal
			3'b001 : mux_output = 4'b0101; // 5 in decimal
			3'b000 : mux_output = 4'b0001; // 1 in decimal
			default: mux_output = 4'b1111; // using 1111 to indicate error 
		endcase
	end	

	// BCD to 7-seg decoder
	always_comb begin
		case (mux_output)
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
			default : seg_digits = 7'b1111111;	// when receive any code out of 0-9, display nothing
		endcase
	end	
endmodule
