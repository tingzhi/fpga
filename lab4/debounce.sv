module debounce (
	input clk,
	//input reset_n,
	input switch_in,
	output logic switch_state // logic is added for modelsim
);
	logic switch_sync_0;
	logic switch_sync_1;
	logic [9:0] switch_cntr;
	
	// synchronize the switch input to the clock
	always_ff @ (posedge clk) begin
		//if (!reset_n)
			//switch_sync_0 <= 1'b0;
		//else
			switch_sync_0 <= !switch_in; // invert the logic
	end

	always_ff @ (posedge clk) begin
		//if (!reset_n)
			//switch_sync_1 <= 1'b0;
		//else
			switch_sync_1 <= switch_sync_0;
	end

	// debounce the switch using a 16-bit counter
	always_ff @ (posedge clk) begin
		//if (!reset_n) begin
			//switch_cntr <= 8'h00;
			//switch_state <= 1'b0;
		//end
		if (switch_state == switch_sync_1)
			switch_cntr <= 10'd0;
		else begin
			switch_cntr <= switch_cntr + 1'b1;
			if (switch_cntr == 10'd256) 
				switch_state <= !switch_state;
		end
	end
endmodule	
