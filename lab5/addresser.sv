module addresser (
	input [13:0] cntr_in,
	input clk,
	input reset_n,
	
	output logic [10:0] addr
);

	logic [23:0] counter_input;
	assign counter_input = {10'd0 , cntr_in}; // concatenation

	logic [23:0] acculator_out;

	always_ff @ (posedge clk, negedge reset_n) begin
		if (!reset_n) begin
			acculator_out <= 24'd0;
		end
		else begin
			acculator_out <= counter_input + acculator_out;
		end
	end
	
	assign addr = acculator_out [23:13];

endmodule
