module shift_reg (
	input serial_data,
	input sclk,
	input reset_n,
	input data_enable,

	output logic [11:0] parallel_data
);
	
	// shift register
	always_ff @ (posedge sclk, negedge reset_n) begin
		if (!reset_n) begin
			parallel_data <= 12'd0;
		end
		else if (data_enable) 
			parallel_data <= {parallel_data[10:0], serial_data};
	end

endmodule
