module debounce (
	input clk,
	//input reset_n,
	input switch_in,
	output logic switch_state // logic is added for modelsim
);
	logic switch_sync_0;
	logic switch_sync_1;
	logic [15:0] switch_cntr;
	
	// synchronize the switch input to the clock
	always_ff @ (posedge clk) begin
		switch_sync_0 <= !switch_in; // invert the logic
	end

	always_ff @ (posedge clk) begin
		switch_sync_1 <= switch_sync_0;
	end

	// debounce the switch using a 16-bit counter
	always_ff @ (posedge clk) begin
		if (switch_state == switch_sync_1)
			switch_cntr <= 16'h0000;
		else begin
			switch_cntr <= switch_cntr + 1'b1;
			if (switch_cntr == 16'hffff) 
				switch_state <= !switch_state;
		end
	end
endmodule	
