module lab4 (
	input led_button,
	input channel_a,
	input channel_b,
	input clk_50,
	input reset_n,
	
	output logic [6:0] seg_digits,
	output [2:0] sel,
	output en_n,
	output logic en,
	output pwm
);
	
	assign en_n = 1'b0; // for display board

	logic [2:0] state_machine_output;
	logic [3:0] mux_output;

	// instantiations of PLL
	// input 50MHz clock
	// output c0: 2kHz clock
	//	  c1: 10kHz clock

	logic clk_2k, clk_10k;
	
	main_clk  main_clk_inst (
		.inclk0 ( clk_50 ),
		.c0 ( clk_2k ),
		.c1 ( clk_10k )
	);

	// devide a 2kHz clock to a 2Hz clock
	// input: 2kHz clock
	// output: 2Hz clock
	logic [8:0] counter_0;
	logic clk_2;

	always_ff @ (posedge clk_2k, negedge reset_n) begin
		if (!reset_n) begin
			counter_0 <= 0;
			clk_2 <= 0;
		end
		else if (counter_0 == 9'd500) begin
			counter_0 <= 0;
			clk_2 <= !clk_2;
		end
		else
			counter_0 ++;
	end
	
	/*
	// devide a 2kHz clock to a 1kHz clock
	logic counter_1;
	logic switch_sample_clk;

	always_ff @ (posedge clk_2k, negedge reset_n) begin
		if (!reset_n) begin
			counter_1 <= 0;
			switch_sample_clk <= 0;
		end
		else if (counter_1 == 1'b1) begin
			counter_1 <= 0;
			switch_sample_clk <= !switch_sample_clk;
		end
		else
			counter_1 ++;
	end
	
	*/

	// devide a 2kHz clock to a 15Hz clock
	// input: 2kHz clock
	// output: 15Hz clock
	logic counter_2;
	logic clk_15;

	always_ff @ (posedge clk_2k, negedge reset_n) begin
		if (!reset_n) begin
			counter_2 <= 0;
			clk_15 <= 0;
		end
		else if (counter_2 == 6'd64) begin
			counter_2 <= 0;
			clk_15 <= !clk_15;
		end
		else
			counter_2 ++;
	end
	
	// instantiations of debounce for quad encoder channel A input
	logic channel_a_clr;

	debounce debounce_0 (
		.clk		(clk_10k),
		.reset_n	(reset_n),
		.switch_in	(channel_a),
		.switch_state	(channel_a_clr)	
	);

	// instantiations of debounce for quad encoder channel B input
	logic channel_b_clr;

	debounce debounce_1 (
		.clk		(clk_10k),
		.reset_n	(reset_n),
		.switch_in	(channel_b),
		.switch_state	(channel_b_clr)	
	);

	// instantiations of debounce for led brightness control button
	logic led_button_clr;

	debounce debounce_2 (
		.clk		(clk_10k),
		.reset_n	(reset_n),
		.switch_in	(led_button),
		.switch_state	(led_button_clr)	
	);

	// instantiations of quad decoder
	logic up_down_n, quad_en;

	quad_decoder quad_decoder_0 (
		.channel_a	(channel_a_clr), //
		.channel_b	(channel_b_clr), //
		.clk		(clk_10k),
		.reset_n	(reset_n),
		.dir		(up_down_n),
		.quad_en	(quad_en)
	);

	/*
	// devide a quad decoder output into a cap 4 counter for each detent
	logic counter_3;
	//logic cntr_en;
	logic q_en;
	
	always_ff @ (posedge pwm_clk_10k, negedge reset_n) begin
		if (!reset_n) begin
			//u_or_d <= 0;
			q_en <= 0;
		end
		else if (counter_3 == 2'b11 && quad_en == 1'b1) begin
			counter_3 <= 2'b00;
			q_en <= 1;
			//q_en <= quad_en;
		end
		else if (quad_en == 1'b1) begin
			q_en <= 0;
			counter_3 ++;
		end
	end
*/	
//	assign q_en = (counter_3 == 2'b11) ? 1'b1 : 1'b0;
	
	/*
	always_ff @ (posedge quad_en, negedge reset_n) begin
		if (!reset_n) begin
			counter_3 <= 0;
		end
		else if (counter_3 == 2'b11) begin
			cntr_en <= 1;
			counter_3 <= 0;
			//display_scan_clk <= !display_scan_clk;
		end
		else
			counter_3 ++;
			cntr_en <= 0;
	end
	*/
	
	logic carry_out_0, carry_out_1;
	logic sub_out_0, sub_out_1;
	logic [3:0] bcd_0, bcd_1, bcd_2;
	
	// instantiations of display counter 0
	disp_cntr disp_cntr_0 (
		.up_down_n	(up_down_n),
		.cntr_en	(quad_en),
		.clk		(clk_10k), //
		.reset_n	(reset_n),
		.carry_in	(1'b1),
		.sub_in		(1'b1),
		.carry_out	(carry_out_0),
		.sub_out	(sub_out_0),
		.bcd		(bcd_0)
	);

	// instantiations of display counter 1
	disp_cntr disp_cntr_1 (
		.up_down_n	(up_down_n),
		.cntr_en	(quad_en),
		.clk		(clk_10k),//
		.reset_n	(reset_n),
		.carry_in	(carry_out_0),
		.sub_in		(sub_out_0),
		.carry_out	(carry_out_1),
		.sub_out	(sub_out_1),
		.bcd		(bcd_1)
	);

	// instantiations of display counter 2
	disp_cntr disp_cntr_2 (
		.up_down_n	(up_down_n),
		.cntr_en	(quad_en),
		.clk		(clk_10k), //
		.reset_n	(reset_n),
		.carry_in	(carry_out_1),
		.sub_in		(sub_out_1),
		.carry_out	(1'b0),
		.sub_out	(1'b0),
		.bcd		(bcd_2)
	);
	
	// enumerated states
	enum logic [1:0] {
		STATE0 = 2'b00,
		STATE1 = 2'b01,
		STATE3 = 2'b11
	} display_scan_ps, display_scan_ns;

	// display_scan_sm (state machine)
	always_ff @ (posedge clk_15, negedge reset_n)  // changed the clock here
	begin
		if (!reset_n) 
			display_scan_ps <= STATE0;
		else
			display_scan_ps <= display_scan_ns;
	end
	
	// state machin next state decoder
	always_comb begin
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
	
	// 3 to 1 mux to select which counter output digit to display
	always_comb begin
		unique case (state_machine_output) 
			3'b000 : mux_output = bcd_0; // least significant bit
			3'b001 : mux_output = bcd_1;
			3'b011 : mux_output = bcd_2; // most significant bit
		endcase
	end

	// instantiation of BCD to 7-seg decoder
	bcd_to_7seg bcd_to_7seg_0 (
		.bcd		(mux_output),
		.seg_digits	(seg_digits)
	);

	/***************** pwm control led brightness part ***********/
	logic [3:0] count_a, count_b;

	// instantiation of the always on counter
	pwm_cntr pwm_cntr_0 (
		.button		(1'b1),
		.pwm_clk	(clk_10k),
		.reset_n	(reset_n),
		.count		(count_a)
	);

	// instantiation of the button controlled counter
	pwm_cntr pwm_cntr_1 (
		.button		(led_button_clr),
		.pwm_clk	(clk_2),
		.reset_n	(reset_n),
		.count		(count_b)
	);

	// compare output from cntr1 and cntr2 to control pwm pin
	assign pwm = (count_a >= count_b) ? 1'b1 : 1'b0;
	
	// leading zero suppression
	
	always_comb begin
		if (state_machine_output == 3'b001 && bcd_1 == 4'b0000 && bcd_2 == 4'b0000)
			en = 1'b0;
		else if (state_machine_output == 3'b011 && bcd_2 == 4'b0000)
			en = 1'b0;
		else
			en = 1'b1;
	end
endmodule
