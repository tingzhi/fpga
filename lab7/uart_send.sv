module uart_send (
	input baud_clk,
	input reset_n,
	input [3:0] ones,
	input [3:0] tens,
	input [3:0] hundreds,
	input [3:0] thousands,
	input adc_data_ready,
	input clk,

	output pc_serial_data_out 
);

	// toggle synchronizer
	// referenced from http://www.edn.com/electronics-blogs/day-in-the-life-of-a-chip-designer/4435339/Synchronizer-techniques-for-multi-clock-domain-SoCs
	// generate the adc_data_ready_stretch signal
	logic adc_data_ready_stretch;
	logic q_0;
	always_ff @ (posedge clk, negedge reset_n) begin
		if (!reset_n) 
			q_0 <= 0;
		else if (adc_data_ready)
			q_0 <= ~q_0;
		else
			q_0 <= q_0;	
	end

	logic q_1, q_2, q_3;
	always_ff @ (posedge baud_clk, negedge reset_n) begin
		if (!reset_n)
			q_1 <= 0;
		else 
			q_1 <= q_0;
	end

	always_ff @ (posedge baud_clk, negedge reset_n) begin
		if (!reset_n)
			q_2 <= 0;
		else 
			q_2 <= q_1;
	end

	always_ff @ (posedge baud_clk, negedge reset_n) begin
		if (!reset_n)
			q_3 <= 0;
		else 
			q_3 <= q_2;
		adc_data_ready_stretch <= q_3 ^ q_2;
	end

//	assign adc_data_stretch = q_3 ^ q_2;

	// start the sender design
	parameter digit_1000s = 2'b00;
	parameter digit_100s = 2'b01;
	parameter digit_10s = 2'b10;
	parameter digit_1s = 2'b11;

	logic [1:0] digit_mux_sel;
	logic [3:0] bcd;

	always_comb begin
		unique case (digit_mux_sel)
			digit_1000s : bcd = thousands;
			digit_100s  : bcd = hundreds;
	             	digit_10s   : bcd = tens;
                        digit_1s    : bcd = ones;
		endcase
	end 
	
	logic [7:0] ascii;
	assign ascii = bcd + 8'd48;

	// CR: carriage return
	// LF: line feed
	parameter select_ASCII = 2'b00;
	parameter select_DP = 2'b01;
	parameter select_CR = 2'b10;
	parameter select_LF = 2'b11;
	
	logic [1:0] char_mux_sel;
	logic [7:0] char_out;

	always_comb begin
		unique case(char_mux_sel) 
			select_ASCII  : char_out = ascii;
			select_DP     : char_out = 8'd46;
			select_CR     : char_out = 8'd13;
			select_LF     : char_out = 8'd10;
		endcase	
	end

	logic [3:0] bit_mux_sel;
	logic data_out;
	always_comb begin
		unique case (bit_mux_sel) 
			4'd0 : data_out = 1'b0; 
			4'd1 : data_out = char_out[0];
			4'd2 : data_out = char_out[1];
			4'd3 : data_out = char_out[2];
			4'd4 : data_out = char_out[3];
			4'd5 : data_out = char_out[4];
			4'd6 : data_out = char_out[5];
			4'd7 : data_out = char_out[6];
			4'd8 : data_out = char_out[7];
			4'd9 : data_out = 1'b1;
		endcase
	end
	assign pc_serial_data_out = data_out;

	enum logic [3:0] {
		BIT_0 = 4'b0000,
		BIT_1 = 4'b0001,
		BIT_2 = 4'b0010,
		BIT_3 = 4'b0011,
		BIT_4 = 4'b0100,
		BIT_5 = 4'b0101,
		BIT_6 = 4'b0110,
		BIT_7 = 4'b0111,
		BIT_8 = 4'b1000,
		BIT_9 = 4'b1001
	} bit_cntr_ps, bit_cntr_ns;

	// uart_main_sm
	enum logic [2:0] {
		CHAR_0 = 3'b000,
		CHAR_1 = 3'b001,
		CHAR_2 = 3'b010,
		CHAR_3 = 3'b011,
		CHAR_4 = 3'b100,
		CHAR_5 = 3'b101,
		CHAR_6 = 3'b110
	} uart_main_ps, uart_main_ns;

	// the big state machine
	enum logic {
		done = 1'b0,
		send = 1'b1
	} uart_control_ps, uart_control_ns;

	always_ff @ (posedge baud_clk, negedge reset_n) begin
		if (!reset_n) 
			uart_control_ps <= done;
		else
			uart_control_ps <= uart_control_ns;
	end

	always_comb begin
		unique case (uart_control_ps)
			done : if (adc_data_ready_stretch == 1'b1) uart_control_ns = send;
			       else uart_control_ns = done;
			send : begin
			       if (uart_main_ps == CHAR_6 && bit_cntr_ps == BIT_8) uart_control_ns = done;
			       else
					uart_control_ns = send;
			end
		endcase
	end


	always_ff @ (posedge baud_clk, negedge reset_n) begin
		if (!reset_n)
			uart_main_ps <= CHAR_6;
		else 
			uart_main_ps <= uart_main_ns;
	end

	always_comb begin
		unique case (uart_main_ps)
			CHAR_0 : begin
					digit_mux_sel = digit_1000s;
					char_mux_sel = select_ASCII;
					if (bit_cntr_ps == BIT_9)
						uart_main_ns = CHAR_1;
					else
						uart_main_ns = CHAR_0;
				 end
			CHAR_1 : begin
					char_mux_sel = select_DP;
					if (bit_cntr_ps == BIT_9)
						uart_main_ns = CHAR_2;
					else
						uart_main_ns = CHAR_1;
				 end
			CHAR_2 : begin
					digit_mux_sel = digit_100s;
					char_mux_sel = select_ASCII;
					if (bit_cntr_ps == BIT_9)
						uart_main_ns = CHAR_3;
					else
						uart_main_ns = CHAR_2;
				 end
			CHAR_3 : begin
					digit_mux_sel = digit_10s;
					char_mux_sel = select_ASCII;
					if (bit_cntr_ps == BIT_9)
						uart_main_ns = CHAR_4;
					else
						uart_main_ns = CHAR_3;
				 end
			CHAR_4 : begin
					digit_mux_sel = digit_1s;
					char_mux_sel = select_ASCII;
					if (bit_cntr_ps == BIT_9)
						uart_main_ns = CHAR_5;
					else
						uart_main_ns = CHAR_4;
				 end
			CHAR_5 : begin
					char_mux_sel = select_CR;
					if (bit_cntr_ps == BIT_9)
						uart_main_ns = CHAR_6;
					else
						uart_main_ns = CHAR_5;
				 end
			CHAR_6 : begin
					char_mux_sel = select_LF;
					if (uart_control_ps == send && bit_cntr_ps == BIT_9)
						uart_main_ns = CHAR_0;
					else
						uart_main_ns = CHAR_6;
				 end
		endcase
	end

	// bit_cntr_sm
	always_ff @ (posedge baud_clk, negedge reset_n) begin
		if (!reset_n) 
			bit_cntr_ps <= BIT_9;
		else
			bit_cntr_ps <= bit_cntr_ns;
	end

	always_comb begin
		unique case (bit_cntr_ps)
			BIT_0 : begin
					bit_cntr_ns = BIT_1; 
					bit_mux_sel = 4'd0;
				end
			BIT_1 : begin
					bit_cntr_ns = BIT_2; 
					bit_mux_sel = 4'd1;
				end
			BIT_2 : begin
					bit_cntr_ns = BIT_3; 
					bit_mux_sel = 4'd2;
				end
			BIT_3 : begin
					bit_cntr_ns = BIT_4; 
					bit_mux_sel = 4'd3;
				end
                        BIT_4 : begin
					bit_cntr_ns = BIT_5; 
					bit_mux_sel = 4'd4;
				end
                        BIT_5 : begin
					bit_cntr_ns = BIT_6; 
					bit_mux_sel = 4'd5;
				end
                        BIT_6 : begin
					bit_cntr_ns = BIT_7; 
					bit_mux_sel = 4'd6;
				end
                        BIT_7 : begin
					bit_cntr_ns = BIT_8; 
					bit_mux_sel = 4'd7;
				end
                        BIT_8 : begin
					bit_cntr_ns = BIT_9; 
					bit_mux_sel = 4'd8;
				end
                        BIT_9 : begin
				bit_mux_sel = 4'd9;
				if (uart_control_ps == send) bit_cntr_ns = BIT_0;
				else
					bit_cntr_ns = BIT_9; 
				end
		endcase 
	end             

endmodule               
