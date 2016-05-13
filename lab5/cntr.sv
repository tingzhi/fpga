module cntr (
	input direction,
	input enable,
//	input [9:0] step,
	input clk,
	input reset_n,

	output logic [13:0] count
);

	always_ff @ (posedge clk, negedge reset_n) begin
		if (!reset_n)
			count <= 14'd1000;
		else if (count == 14'd9999 && enable == 1'b1 && direction == 1'b1)
			count <= 14'd9999;
		else if (count == 14'd0 && enable == 1'b1 && direction == 1'b0)
			count <= 14'd0;
		else if (enable == 1'b1 && direction == 1'b1)
			count <= count + 1'b1;
		else if (enable == 1'b1 && direction == 1'b0)
			count <= count - 1'b1;
		else
			count <= count;
	end
endmodule
