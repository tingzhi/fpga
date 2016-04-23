module lab2alternative (
	input 	[7:0]	buttons,
	input		switch,
	output  [7:0]	led
);

logic [7:0] first_encoder_out;
logic [7:0] second_encoder_out;

 
//Make a priority encoder with inputs from buttons and output to led
	
	// 2 to 1 mux to choose which output we want to see  	
	always_comb begin
		if (switch) 
			led[7:0] = first_encoder_out;		
		else
			led[7:0] = second_encoder_out;
	end
	
	// 8 to 3 encoder first method to implement
	always_comb begin
		priority case (1'b0)
			buttons[7] : first_encoder_out[7:0] = 8'b00001000;
			buttons[6] : first_encoder_out[7:0] = 8'b00000111;
			buttons[5] : first_encoder_out[7:0] = 8'b00000110;
			buttons[4] : first_encoder_out[7:0] = 8'b00000101;
			buttons[3] : first_encoder_out[7:0] = 8'b00000100;
			buttons[2] : first_encoder_out[7:0] = 8'b00000011;
			buttons[1] : first_encoder_out[7:0] = 8'b00000010;
			buttons[0] : first_encoder_out[7:0] = 8'b00000001;
			default    : first_encoder_out[7:0] = 8'b00000000;
		endcase
	end
	
	// 8 to 3 encoder second method to implement
	always_comb begin
		casez (buttons)
			8'b0??????? : second_encoder_out[7:0] = 8'b00001000;
			8'b10?????? : second_encoder_out[7:0] = 8'b00000111;
			8'b110????? : second_encoder_out[7:0] = 8'b00000110;
			8'b1110???? : second_encoder_out[7:0] = 8'b00000101;
			8'b11110??? : second_encoder_out[7:0] = 8'b00000100;
			8'b111110?? : second_encoder_out[7:0] = 8'b00000011;
			8'b1111110? : second_encoder_out[7:0] = 8'b00000010;
			8'b11111110 : second_encoder_out[7:0] = 8'b00000001;
			default	    : second_encoder_out[7:0] = 8'b00000000;
		endcase
	end

endmodule