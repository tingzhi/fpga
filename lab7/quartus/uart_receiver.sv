module uart_receive (
	input reset_n,
	input rx_sample_clk, // for 9600Hz incoming clock data, it shoudl be 153.6kHz
	input serial_data_in,
		
	output logic [7:0] hold_reg
);
	logic sync_0, clean_serial_data_in;
	always_ff @ (posedge rx_sample_clk, negedge reset_n) begin
		if (!reset_n)
			sync_0 <= 1'b1;
		else
			sync_0 <= serial_data_in;
	end
	
	always_ff @ (posedge rx_sample_clk, negedge reset_n) begin
		if (!reset_n)
			clean_serial_data_in <= 1'b1;
		else
			clean_serial_data_in <= sync_0;
	end
	
	// sample counter state machine
	enum logic [3:0] {
		S0 = 4'd0,
		S1 = 4'd1,
		S2 = 4'd2,
		S3 = 4'd3,
		S4 = 4'd4,
		S5 = 4'd5,
		S6 = 4'd6,
		S7 = 4'd7,
		S8 = 4'd8,
		S9 = 4'd9,
		S10 = 4'd10,
		S11 = 4'd11,
		S12 = 4'd12,
		S13 = 4'd13,
		S14 = 4'd14,
		S15 = 4'd15
	} sample_cntr_ps, sample_cntr_ns;

	enum logic [1:0] {
		idle = 2'b00,
		edge_detect = 2'b01,
		start_valid = 2'b10,
		stop = 2'b11
	} receiver_control_ps, receiver_control_ns;

	enum logic [3:0] {
		bit0 = 4'd0,
		bit1 = 4'd1,
		bit2 = 4'd2,
		bit3 = 4'd3,
		bit4 = 4'd4,
		bit5 = 4'd5,
		bit6 = 4'd6,
		bit7 = 4'd7,
		stop_bit = 4'd8
	} bit_cntr_ps, bit_cntr_ns;
	
	always_ff @ (posedge rx_sample_clk, negedge reset_n) begin
		if (!reset_n)
			sample_cntr_ps <= S9;
		else
			sample_cntr_ps <= sample_cntr_ns;
	end

	logic bit_frame;
	always_comb begin
		bit_frame = 1'b0;
		unique case (sample_cntr_ps)
			S0 : sample_cntr_ns = S1;
			S1 : sample_cntr_ns = S2;
			S2 : sample_cntr_ns = S3;
			S3 : sample_cntr_ns = S4;
			S4 : sample_cntr_ns = S5;
			S5 : sample_cntr_ns = S6;
			S6 : sample_cntr_ns = S7;
			S7 : sample_cntr_ns = S8;
			S8 : sample_cntr_ns = S9;
			S9 : if (receiver_control_ps ==  edge_detect || receiver_control_ps == start_valid )
				sample_cntr_ns = S10;
			     else
				sample_cntr_ns = S9;
			S10 : sample_cntr_ns = S11;
			S11 : sample_cntr_ns = S12;
			S12 : sample_cntr_ns = S13;
			S13 : sample_cntr_ns = S14;
			S14 : sample_cntr_ns = S15;
			S15 : begin
			      bit_frame = 1'b1;
			      if (receiver_control_ps == edge_detect || receiver_control_ps == start_valid)
				sample_cntr_ns = S0;
			      else
				sample_cntr_ns = S9;
			      end
		endcase
	end

	// receiver control state machine

	always_ff @ (posedge rx_sample_clk, negedge reset_n) begin
		if (!reset_n)
			receiver_control_ps <= idle;
		else
			receiver_control_ps <= receiver_control_ns;
	end

	logic serial_data_ready;
	logic final_bit;
//	assign final_bit = (bit_frame && bit_cntr_ps == bit7) ? 1'b1 : 1'b0;

	always_comb begin
		serial_data_ready = 1'b0;
		unique case (receiver_control_ps)
			idle : if (clean_serial_data_in == 1'b0) 
				receiver_control_ns = edge_detect;
			       else
				receiver_control_ns = idle; 
			edge_detect : if (clean_serial_data_in == 1'b0 && bit_frame == 1'b1)
				   receiver_control_ns = start_valid;
				 else if (clean_serial_data_in == 1'b0 && bit_frame == 1'b0)
				   receiver_control_ns = edge_detect;
				 else
				   receiver_control_ns = idle;
			start_valid : if (bit_frame == 1'b1 && final_bit == 1'b1)
				receiver_control_ns = stop;
			       else
				receiver_control_ns = start_valid;
			stop : begin
				serial_data_ready = 1'b1;
			     //  if (bit_frame == 1'b1)
				receiver_control_ns = idle;
			      // else
			//	receiver_control_ns = stop;
			       end
		endcase	
	end

	// bit counter state machine
	
	always_ff @ (posedge rx_sample_clk, negedge reset_n) begin
		if (!reset_n)
			bit_cntr_ps <= stop_bit;
		else
			bit_cntr_ps <= bit_cntr_ns;
	end

	always_comb begin
		final_bit = 1'b0;
		unique case (bit_cntr_ps)
			bit0 : begin
				if (bit_frame == 1'b1)
					bit_cntr_ns = bit1;
				else
					bit_cntr_ns = bit0;
			       end
			bit1 : begin
				if (bit_frame == 1'b1) begin
					bit_cntr_ns = bit2;
				end
				else
					bit_cntr_ns = bit1;
			       end
			bit2 : begin
				if (bit_frame == 1'b1) begin
					bit_cntr_ns = bit3;
				end
				else
					bit_cntr_ns = bit2;
			       end
			bit3 : begin
				if (bit_frame == 1'b1) begin
					bit_cntr_ns = bit4;
				end
				else
					bit_cntr_ns = bit3;
			       end
			bit4 : begin
				if (bit_frame == 1'b1) begin
					bit_cntr_ns = bit5;
				end
				else
					bit_cntr_ns = bit4;
			       end
			bit5 : begin
				if (bit_frame == 1'b1) begin
					bit_cntr_ns = bit6;
				end
				else
					bit_cntr_ns = bit5;
			       end
			bit6 : begin
				if (bit_frame == 1'b1) begin
					bit_cntr_ns = bit7;
				end
				else
					bit_cntr_ns = bit6;
			       end
			bit7 : begin
				final_bit = 1'b1;
				if (bit_frame == 1'b1) begin
					bit_cntr_ns = stop_bit;
				end
				else
					bit_cntr_ns = bit7;
			       end
			stop_bit : begin
					if (bit_frame == 1'b1 && receiver_control_ps == start_valid) bit_cntr_ns = bit0;
					else bit_cntr_ns = stop_bit;
				   end
		endcase
	end

	logic [8:0] rx_data;
	logic enable;
	assign enable = (bit_frame == 1'b1 && receiver_control_ps == start_valid) ? 1'b1 : 1'b0;
	// instantiation of 8 bit shift register (shift right)
	shift_reg_9bit shift_reg_9bit_0 (
		.serial_data	  (clean_serial_data_in),
		.sclk		  (rx_sample_clk),
		.reset_n	  (reset_n),	
		.shift_reg_enable (enable),
		
		.parallel_data    (rx_data)
	);

	logic [7:0] raw_data;
	assign raw_data = rx_data[7:0];

	always_ff @ (posedge rx_sample_clk, negedge reset_n) begin
		if (!reset_n) 
			hold_reg <= 8'd48;
		else if (serial_data_ready)
			hold_reg <= raw_data;
		else
			hold_reg <= hold_reg;
	end

endmodule
