module uart_receive (
	input reset_n,
	input rx_sample_clk, // for 9600Hz incoming clock data, it shoudl be 153.6kHz
	input serial_data_in,
		
	output [2:0] addr
);

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
		detect = 2'b01,
		send = 2'b10,
		done = 2'b11
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
		bit8 = 4'd8,
		bit9 = 4'd9
	} bit_cntr_ps, bit_cntr_ns;
	
	always_ff @ (posedge rx_sample_clk, negedge reset_n) begin
		if (!reset_n)
			sample_cntr_ps <= S7;
		else
			sample_cntr_ps <= sample_cntr_ns;
	end

	always_comb begin
		unique case (sample_cntr_ps)
			S7 : if (receiver_control_ps == detect || receiver_control_ps == send)
				sample_cntr_ns = S8;
			     else
				sample_cntr_ns = S7;
			S8 : sample_cntr_ns = S9;
			S9 : sample_cntr_ns = S10;
			S10 : sample_cntr_ns = S11;
			S11 : sample_cntr_ns = S12;
			S12 : sample_cntr_ns = S13;
			S13 : sample_cntr_ns = S14;
			S14 : sample_cntr_ns = S15;

			S15 : if (receiver_control_ps == idle)
				sample_cntr_ns = S7;
			      else
				sample_cntr_ns = S0;

			S0 : sample_cntr_ns = S1;
			S1 : sample_cntr_ns = S2;
			S2 : sample_cntr_ns = S3;
			S3 : sample_cntr_ns = S4;
			S4 : sample_cntr_ns = S5;
			S5 : sample_cntr_ns = S6;
			S6 : sample_cntr_ns = S7;
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

	always_comb begin
		serial_data_ready = 1'b0;
		unique case (receiver_control_ps)
			idle : if (serial_data_in == 1'b0) 
				receiver_control_ns = detect;
			       else
				receiver_control_ns = idle; 
			detect : if (serial_data_in == 1'b1)
				   receiver_control_ns = idle;
				 else if (sample_cntr_ps == S15)
				   receiver_control_ns = send;
				 else
				   receiver_control_ns = detect;
			send : if (bit_cntr_ps == bit9)
				receiver_control_ns = done;
			       else
				receiver_control_ns = send;
			done : begin
				serial_data_ready = 1'b1;
				receiver_control_ns = idle;
			       end
		endcase	
	end
	// bit counter state machine
	
	always_ff @ (posedge rx_sample_clk, negedge reset_n) begin
		if (!reset_n)
			bit_cntr_ps <= bit0;
		else
			bit_cntr_ps <= bit_cntr_ns;
	end

	logic [7:0] rx_data;

	always_comb begin
		unique case (bit_cntr_ps)
			bit0 : begin
				if (sample_cntr_ps == S15)
					bit_cntr_ns = bit1;
				else
					bit_cntr_ns = bit0;
			       end
			bit1 : begin
				if (sample_cntr_ps == S15) begin
					bit_cntr_ns = bit2;
					rx_data[0] = serial_data_in;
				end
				else
					bit_cntr_ns = bit1;
			       end
			bit2 : begin
				if (sample_cntr_ps == S15) begin
					bit_cntr_ns = bit3;
					rx_data[1] = serial_data_in;
				end
				else
					bit_cntr_ns = bit2;
			       end
			bit3 : begin
				if (sample_cntr_ps == S15) begin
					bit_cntr_ns = bit4;
					rx_data[2] = serial_data_in;
				end
				else
					bit_cntr_ns = bit3;
			       end
			bit4 : begin
				if (sample_cntr_ps == S15) begin
					bit_cntr_ns = bit5;
					rx_data[3] = serial_data_in;
				end
				else
					bit_cntr_ns = bit4;
			       end
			bit5 : begin
				if (sample_cntr_ps == S15) begin
					bit_cntr_ns = bit6;
					rx_data[4] = serial_data_in;
				end
				else
					bit_cntr_ns = bit5;
			       end
			bit6 : begin
				if (sample_cntr_ps == S15) begin
					bit_cntr_ns = bit7;
					rx_data[5] = serial_data_in;
				end
				else
					bit_cntr_ns = bit6;
			       end
			bit7 : begin
				if (sample_cntr_ps == S15) begin
					bit_cntr_ns = bit8;
					rx_data[6] = serial_data_in;
				end
				else
					bit_cntr_ns = bit7;
			       end
			bit8 : begin
				if (sample_cntr_ps == S15) begin
					bit_cntr_ns = bit9;
					rx_data[7] = serial_data_in;
				end
				else
					bit_cntr_ns = bit8;
			       end
			bit9 : if (receiver_control_ps == send)
				bit_cntr_ns = bit0;
			       else
				bit_cntr_ns = bit9;
		endcase
	end

	logic [7:0] bcd;
	always_comb begin
		if (!reset_n)
			bcd = 8'd0;
		else if (serial_data_ready)
			bcd = rx_data - 8'd48;
	end

	assign addr = bcd[2:0];
endmodule
