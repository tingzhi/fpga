module debounce (
	input clk,
	input reset_n,
	input switch_in,
	output logic switch_state // logic is added for modelsim
);

	logic switch_sync_0, switch_sync_1;
	logic [9:0] switch_cntr;
	
	// synchronize the switch input to the clock
	// store the raw input in the first FF and invert the logic
	// button pushed: circuit 0 -> debounce output 1
	// button released: circuit 1 -> debounce output 0

	always_ff @ (posedge clk, negedge reset_n) begin
		if (!reset_n) begin
			switch_sync_0 <= 1'b0;
		end
		else
			switch_sync_0 <= !switch_in; // invert the logic
	end

	// store the sync switch input into a second FF
	always_ff @ (posedge clk, negedge reset_n ) begin
		if (!reset_n)
			switch_sync_1 <= 1'b0;
		else
			switch_sync_1 <= switch_sync_0;
	end

	// debounce the switch using a 10-bit counter, max cap 1024
	always_ff @ (posedge clk, negedge reset_n) begin
		if (!reset_n) begin
			switch_cntr <= 10'd0;
			switch_state <= 1'b0;
		end
		if (switch_state == switch_sync_1)
			switch_cntr <= 10'd0;
		else begin
			switch_cntr <= switch_cntr + 1'b1;
			if (switch_cntr == 10'd200) // for 10k clk about 20ms
				switch_state <= !switch_state;
		end
	end
endmodule	
