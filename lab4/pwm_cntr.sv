module pwm_cntr (
	input button,
	input pwm_clk,
	input reset_n,
	output logic [3:0] count
);
	logic sync_reset;

	always_ff @ (posedge pwm_clk, negedge reset_n) begin
		if (!reset_n) 
			count <= 4'b0000;
		else if (sync_reset) 
			count <= 4'b0000;
		else if (button == 1'b0)
			count ++;
		else
			count = count;
	end

	assign sync_reset = (count == 4'hf) ? 1'b1 : 1'b0;
/*
	always_comb begin
		up_reset = 1'b0;
		down_reset = 1'b0;
		if (cntr2_output == 4'hF && !led_brighter)
			up_reset = 1'b1;
		else
			up_reset = 1'b0;
		if (cntr2_output == 4'h0 && !led_dimmer)
			down_reset = 1'b1;
		else
			down_reset = 1'b0;
	end
*/
endmodule
