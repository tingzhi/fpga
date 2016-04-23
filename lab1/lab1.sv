module lab1	(
	input 	[3:0]	switches,
	output 	[7:0]	led
);


assign led[3:0] = switches;

endmodule



