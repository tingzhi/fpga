module quad_decoder (
	input channel_a,
	input channel_b,
	input clk,
	input reset_n,
	output dir,
	output quad_en
);

	logic channel_a_delayed, channel_b_delayed;

	always_ff @ (posedge clk, negedge reset_n) begin
		if (!reset_n) begin
			channel_a_delayed <= 1'b0;
			channel_b_delayed <= 1'b0;
		end
		else begin
			channel_a_delayed <= channel_a;
			channel_b_delayed <= channel_b;
		end
	end

	assign quad_en = channel_a ^ channel_a_delayed ^ channel_b ^ channel_b_delayed;
	assign dir = channel_a ^ channel_b_delayed;
endmodule
