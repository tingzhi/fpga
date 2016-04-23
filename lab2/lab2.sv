module lab2(
	input 	[7:0]	buttons,
	input		switch,
	output	[7:0]	led
);

//Make a priority encoder with inputs from buttons and output to led

	always_comb begin
		if (switch) begin
			led[7] = 1'b1;
			priority case (1'b0)
				buttons[7] : led[6:0] = 7'b0001000;
				buttons[6] : led[6:0] = 7'b0000111;
				buttons[5] : led[6:0] = 7'b0000110;
				buttons[4] : led[6:0] = 7'b0000101;
				buttons[3] : led[6:0] = 7'b0000100;
				buttons[2] : led[6:0] = 7'b0000011;
				buttons[1] : led[6:0] = 7'b0000010;
				buttons[0] : led[6:0] = 7'b0000001;
				default 	  : led[6:0] = 7'b0000000;
			endcase
		end

		else begin
			led[7] = 1'b0;
			casez (buttons)
				8'b0??????? : led[6:0] = 7'b0001000;
				8'b10?????? : led[6:0] = 7'b0000111;
				8'b110????? : led[6:0] = 7'b0000110;
				8'b1110???? : led[6:0] = 7'b0000101;
				8'b11110??? : led[6:0] = 7'b0000100;
				8'b111110?? : led[6:0] = 7'b0000011;
				8'b1111110? : led[6:0] = 7'b0000010;
				8'b11111110 : led[6:0] = 7'b0000001;
				default		: led[6:0] = 7'b0000000;
			endcase
		end
	end
endmodule
