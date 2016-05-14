module cntr (
	input direction,
	input enable,
	input [9:0] step,
	input clk,
	input reset_n,

	output logic [13:0] count
);
	logic lock;

	always_ff @ (posedge clk, negedge reset_n) begin
		if (!reset_n)
			count <= 14'd1000;
		else if (enable == 1'b1 && direction == 1'b1 && !lock)
			count <= count + step;
		else if (enable == 1'b1 && direction == 1'b0 && !lock)
			count <= count - step;
		else if (enable == 1'b1 && lock == 1'b1)
			count <= count;
	end
	
	always_comb begin
		if (direction == 1'b1 && count >= 14'd9000 && step == 10'd1000)
			lock = 1'b1;
		else if (direction == 1'b1 && count >= 14'd9900 && step == 10'd100)
			lock = 1'b1;
		else if (direction == 1'b1 && count >= 14'd9990 && step == 10'd10)
			lock = 1'b1;
		else if (direction == 1'b1 && count == 14'd9999 && step == 10'd1)
			lock = 1'b1;
		else if (direction == 1'b0 && count <= 14'd999 && step == 10'd1000)
			lock = 1'b1;
		else if (direction == 1'b0 && count <= 14'd99 && step == 10'd100)
			lock = 1'b1;
		else if (direction == 1'b0 && count <= 14'd9 && step == 10'd10)
			lock = 1'b1;
		else if (direction == 1'b0 && count == 14'd0 && step == 19'd1)
			lock = 1'b1;
		else 
			lock = 1'b0;
	end

endmodule
