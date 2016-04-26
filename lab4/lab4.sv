module lab4 (
	input led_brighter,
	input led_dimmer,
	input pwm_clk,
	input switch_sample_clk,
	input display_scan_clk,
	input reset_n,
	
	// unclear about quadrature decoder part
	
	output logic [6:0] seg_digits,
	output [2:0] sel,
	output en_n,
	output en,
	output pwm
);

	logic s1_reset;
	logic up_reset, down_reset, up_reset1, down_reset1, up_reset2, down_reset2, up_reset3, down_reset3;
	logic [3:0] cntr1_output;
	logic [3:0] cntr2_output;
	logic carry1, carry2, carry3,sub1, sub2, sub3;
	
	logic [2:0] state_machine_output;

	logic [3:0] lsb_counter_output;
	logic [3:0] middle_counter_output;
	logic [3:0] msb_counter_output;

	logic [3:0] mux_output;

	logic up;
	logic down;
	logic pulse;

	assign en = 1'b1;
	assign en_n = 1'b0;
	
	// enumerated states
	enum logic [1:0] {
		STATE0 = 2'b00,
		STATE1 = 2'b01,
		STATE3 = 2'b11
	} display_scan_ps, display_scan_ns;

	// display_scan_sm (state machine)
	always_ff @ (posedge display_scan_clk, negedge reset_n) 
	begin
		if (!reset_n) 
			display_scan_ps <= STATE0;
		else
			display_scan_ps <= display_scan_ns;
	end
	
	// state machin next state decoder
	always_comb begin
		//state_machine_output = 3'b000; // default state machine output
		unique case (display_scan_ps)
			STATE0 : begin
				display_scan_ns = STATE1;
				state_machine_output = 3'b000;
			end			
			STATE1 : begin 
				display_scan_ns = STATE3;
				state_machine_output = 3'b001;
			end
			STATE3 : begin
				display_scan_ns = STATE0;
				state_machine_output = 3'b011;
			end
		endcase	
	end
	assign sel = state_machine_output; 
	

	// 3 to 1 mux to select which counter output bit to display
	always_comb begin
		unique case (state_machine_output) 
			3'b000 : mux_output = lsb_counter_output; // least significant bit
			3'b001 : mux_output = middle_counter_output;
			3'b011 : mux_output = msb_counter_output; // most significant bit
		endcase
	end

	// BCD to 7-seg decoder
	always_comb begin
		case (mux_output)
			4'b0000 : seg_digits = 7'b0000001; // 0
			4'b0001 : seg_digits = 7'b1001111; // 1
			4'b0010 : seg_digits = 7'b0010010; // 2
			4'b0011 : seg_digits = 7'b0000110; // 3
			4'b0100 : seg_digits = 7'b1001100; // 4
			4'b0101 : seg_digits = 7'b0100100; // 5
			4'b0110 : seg_digits = 7'b0100000; // 6
			4'b0111 : seg_digits = 7'b0001111; // 7
			4'b1000 : seg_digits = 7'b0000000; // 8
			4'b1001 : seg_digits = 7'b0000100; // 9
			default : seg_digits = 7'b1111111;	// when receive any code out of 0-9, display nothing
		endcase
	end	

	/***************** pwm control led brightness part ***********/

	// control counter
	always_ff @ (posedge pwm_clk, negedge reset_n) begin
		if (!reset_n) // async reset
			cntr1_output <= 4'b0000;
		else if (s1_reset) // sync reset
			cntr1_output <= 4'b0000;
		else
			cntr1_output <= cntr1_output + 1'b1;
	end

	always_comb begin
		s1_reset = 1'b0; // assign default sync reset value
		if (cntr1_output == 4'hF)
			s1_reset = 1'b1;
		else
			s1_reset = 1'b0;
	end

	// user input button counter
	always_ff @ (posedge pwm_clk, negedge reset_n) begin
		if (!reset_n) 
			cntr2_output <= 4'b0000;
		else if (up_reset) 
			cntr2_output <= 4'b0000;
		else if (down_reset)
			cntr2_output <= 4'b1111;
		else if (led_brighter == 1'b0)
			cntr2_output ++;
		else if (led_dimmer == 1'b0)
			cntr2_output --;
		else
			cntr2_output = cntr2_output;
	end

	always_comb begin
		up_reset = 1'b0;
		down_reset = 1'b0;
		if (cntr2_output == 4'hF && !led_brighter)
			up_reset = 1'b1;
		else
			up_reset = 1'b0;
		if (cntr2_output == 4'h0 && !led_dimmer)
			down_reset = 1'b1;
		else
			down_reset = 1'b0;
	end

	// compare output from cntr1 and cntr2 to control pwm pin
	assign pwm = (cntr1_output >= cntr2_output) ? 1'b1 : 1'b0;

	/************** three up and down counters part *********************/
	// lsb counter

	always_ff @ (posedge pulse, negedge reset_n) begin
		if (!reset_n)
			lsb_counter_output <= 4'b0000;
		else if (lsb_counter_output == 4'h9 && up == 1'b1) begin
			lsb_counter_output <= 4'b0000;
		end
		else if (lsb_counter_output == 4'h0 && down == 1'b1) begin
			lsb_counter_output <= 4'b1001;
		end		
		else if (up) begin
			lsb_counter_output ++;
		end
		else if (down) begin
			lsb_counter_output --;
		end
		else
			lsb_counter_output <= lsb_counter_output;
	end

	assign carry1 = (lsb_counter_output == 4'h9 && up == 1'b1) ? 1'b1 : 1'b0;
	assign sub1 = (lsb_counter_output == 4'h0 && down == 1'b1) ? 1'b1 : 1'b0;
	

// second digit
	always_ff @ (posedge pulse, negedge reset_n) begin
		if (!reset_n)
			middle_counter_output <= 4'b0000;
		else if (carry1 == 1'b1 && middle_counter_output == 4'h9) begin
			middle_counter_output <= 4'b0000;
		end
		else if (carry1 == 1'b1 && lsb_counter_output == 4'h9) begin
			middle_counter_output ++;
		end
		
		else if (sub1 ==1'b1 && middle_counter_output == 4'h0) begin
			middle_counter_output <= 4'h9;
		end		
		else if (sub1 == 1'b1 && lsb_counter_output == 4'h0) begin
			middle_counter_output --;			
		end
		
	end
	
	assign carry2 = (lsb_counter_output == 4'h9 && middle_counter_output == 4'h9 && up == 1'b1) ? 1'b1 : 1'b0;
	assign sub2 = (lsb_counter_output == 4'h0 && middle_counter_output ==4'h0 && down == 1'b1)? 1'b1 : 1'b0;

// third digit
	always_ff @ (posedge pulse, negedge reset_n) begin
		if (!reset_n)
			msb_counter_output <= 4'b0000;
		else if (carry2 == 1'b1 && msb_counter_output == 4'h9) begin
			msb_counter_output <= 4'b0000;
			
		end
		else if (carry2 == 1'b1 && middle_counter_output == 4'h9) begin
			msb_counter_output ++;
			
		end
		
		else if (sub2 ==1'b1 && msb_counter_output == 4'h0) begin
			msb_counter_output <= 4'h9;
			
		end		
		else if (sub2 == 1'b1 && middle_counter_output == 4'h0) begin
			msb_counter_output --;			
			
		end
	end
endmodule
