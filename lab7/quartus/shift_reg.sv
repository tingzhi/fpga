module shift_reg (
	input serial_data,
	input sclk,
	input reset_n,
	input shift_reg_enable,

	output logic [11:0] parallel_data
);

	// shift register
	always_ff @ (posedge sclk, negedge reset_n) begin
		if (!reset_n)
			parallel_data <= 12'd0;
		else if (shift_reg_enable) 
			parallel_data <= {parallel_data[10:0], serial_data};
	end

endmodule
