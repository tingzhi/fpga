module shift_reg_9bit (
	input serial_data,
	input sclk,
	input reset_n,
	input shift_reg_enable,

	output logic [8:0] parallel_data
);

	// shift register
	always_ff @ (posedge sclk, negedge reset_n) begin
		if (!reset_n)
			parallel_data <= 9'd0;
		else if (shift_reg_enable) 
			parallel_data <= {serial_data, parallel_data[8:1]};
	end

endmodule
