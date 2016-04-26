module disp_cntr (
	input up_down_n,
	input cntr_en,
	input clk,
	input reset_n,
	input carry_in,
	input sub_in,
	output carry_out,
	output sub_out,
	output logic [3:0] bcd
);

//	logic [3:0] cntr_output;

	always_ff @ (posedge clk, negedge reset_n) begin
		if (!reset_n)
			bcd <= 4'b0000;
		else if (carry_in ==1'b1 && bcd == 4'h9 && up_down_n == 1'b1 && cntr_en == 1'b1) begin
			bcd <= 4'b0000;
		end
		else if (sub_in == 1'b1 && bcd == 4'h0 && up_down_n == 1'b0 && cntr_en == 1'b1) begin
			bcd <= 4'b1001;
		end		
		else if (carry_in == 1'b1 && up_down_n == 1'b1 && cntr_en == 1'b1) begin
			bcd ++;
		end
		else if (sub_in == 1'b1 && up_down_n == 1'b0 && cntr_en == 1'b1) begin
			bcd --;
		end
		else
			bcd <= bcd;
	end

	assign carry_out = (bcd == 4'h9 && carry_in == 1'b1) ? 1'b1 : 1'b0;
	assign sub_out = (bcd == 4'h0 && sub_in == 1'b1) ? 1'b1 : 1'b0;

endmodule
