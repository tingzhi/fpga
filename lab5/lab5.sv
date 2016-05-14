module lab5 (
	input channel_a,
	input channel_b,
	input clk_50,
	input reset_n,
	
	output logic [6:0] seg_digits,
	output [2:0] sel,
	output en_n,
	output logic en,
	output pwm,
	output logic [7:0] data
);
	
	assign en_n = 1'b0; // for display board
	assign pwm = 1'b0;

	// instantiations of PLL
	// input 50MHz clock
	// output c0: 16MHz clock
	//	  c1: 10kHz clock

	logic clk_16m, clk_10k;
	
	main_clk	main_clk_inst (
		.inclk0 ( clk_50 ),
		.c0 ( clk_16m ),
		.c1 ( clk_10k ),
		.c2 ()
	);

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

	// instantiations of quad decoder
	logic up_down_n, quad_en;

	quad_decoder quad_decoder_0 (
		.channel_a	(channel_a_clr), 
		.channel_b	(channel_b_clr), 
		.clk		(clk_10k),
		.reset_n	(reset_n),
		.dir		(up_down_n),
		.quad_en	(quad_en)
	);

	// instantiations of 14 bits counter
	logic [13:0] count;

	cntr cntr_0 (
		.direction	(up_down_n),
		.enable		(quad_en),
		.clk		(clk_10k),
		.reset_n	(reset_n),
		.count		(count)
	);
	
	// instantiations of binary to bcd module
	logic [3:0] bcd_0, bcd_1, bcd_2, bcd_3;
	bin_to_bcd bin_to_bcd_0 (
		.binary 	(count),
		.thousands	(bcd_3),
		.hundreds	(bcd_2),
		.tens		(bcd_1),
		.ones		(bcd_0)
	);
	
	logic [2:0] state_machine_output;
	logic [3:0] mux_output;
	
	// enumerated states
	enum logic [2:0] {
		STATE0 = 3'b000,
		STATE1 = 3'b001,
		STATE3 = 3'b011,
		STATE4 = 3'b100
	} display_scan_ps, display_scan_ns;

	// display_scan_sm (state machine)
	always_ff @ (posedge clk_10k, negedge reset_n)  
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
				display_scan_ns = STATE4;
				state_machine_output = 3'b011;
			end
			STATE4 : begin
				display_scan_ns = STATE0;
				state_machine_output = 3'b100;
			end
		endcase	
	end
	assign sel = state_machine_output; 
	
	// 4 to 1 mux to select which counter output digit to display
	always_comb begin
		unique case (state_machine_output) 
			3'b000 : mux_output = bcd_0; // least significant bit
			3'b001 : mux_output = bcd_1;
			3'b011 : mux_output = bcd_2;  
			3'b100 : mux_output = bcd_3; // msb
		endcase
	end

	// instantiation of BCD to 7-seg decoder
	bcd_to_7seg bcd_to_7seg_0 (
		.bcd		(mux_output),
		.seg_digits	(seg_digits)
	);

	// leading zero suppression
	always_comb begin
		if (state_machine_output == 3'b001 && bcd_1 == 4'b0000 && bcd_2 == 4'b0000 && bcd_3 == 4'b0000)
			en = 1'b0;
		else if (state_machine_output == 3'b011 && bcd_2 == 4'b0000 && bcd_3 == 4'b0000)
			en = 1'b0;
		else if (state_machine_output == 3'b100 && bcd_3 == 4'b0000)
			en = 1'b0;
		else
			en = 1'b1;
	end
	
	// instantiations of addresser
	logic [10:0] addr;
	
	addresser addresser_0 (
		.cntr_in 	(count),
		.clk		(clk_16m),
		.reset_n	(reset_n),
		.addr		(addr)
	);

	
	// instantiations of ROM
	rom	rom_inst (
		.address ( addr ),
		.clock ( clk_16m ),
		.q ( data )
	);
endmodule
