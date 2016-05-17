module lab6 (
	input reset_n,
	input clk_50,
	input button,
	input dout,

	output sclk,
	output cs_n, 
	output din,
	output [6:0] seg_digits,
	output [2:0] sel,
	output en_n,
	output en,
	output pwm,
	output dp,
	output [7:0] led
);

	assign en_n = 1'b0;
	assign pwm = 1'b0;
	assign en = 1'b1;

	assign led = parallel_data[11:4];
	
	// PLL
	logic clk_16m, clk_3m, clk_10k;
	
	main_clk	main_clk_inst (
		.inclk0 ( clk_50 ),
		.c0 ( clk_16m ),
		.c1 ( clk_3m ),
		.c2 ( clk_10k )
	);

	// 3.2MHz clk for ADC chip

	// instantiations of debounce for button
	logic button_clr;
	debounce debounce_0 (
		.clk		(clk_10k),
		.reset_n	(reset_n),
		.switch_in	(button),
		.switch_state	(button_clr)	
	);

	// instantiations of adc module
	logic data_enable, adc_data_ready;

	adc adc_0 (
		 .clk		(clk_3m),
		 .get_adc_data	(button_clr),
		 .reset_n	(reset_n),

		 .data_enable	(data_enable),
		 .sclk		(sclk),
		 .cs_n		(cs_n),
		 .din		(din),
		 .adc_data_ready	(adc_data_ready)
	);

	// instantiations of shift register module
	logic [11:0] parallel_data;

	shift_reg shift_reg_0 (
		.serial_data	(dout),
		.sclk		(sclk),
		.reset_n	(reset_n),
		.data_enable	(data_enable),
 	   .parallel_data	(parallel_data)
	);
	
	logic [11:0] rom_input;

	always_ff @ (posedge clk_3m, negedge reset_n) begin
		if (!reset_n) begin
			rom_input <= 12'd0;
		end
		else if (adc_data_ready)
			rom_input <= parallel_data;
	end
	
	logic [11:0] q_out;
	rom	rom_inst (
	.address ( rom_input ),
	.clock ( clk_16m ), 
	.q ( q_out )
	);
	
	// instantiations of binary to bcd module
	logic [3:0] bcd_0, bcd_1, bcd_2, bcd_3;
	bin_to_bcd bin_to_bcd_0 (
		.binary 	(q_out),
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

	assign dp = (state_machine_output ==  3'b100) ? 1'b0 : 1'b1;	
	
	// instantiation of BCD to 7-seg decoder
	bcd_to_7seg bcd_to_7seg_0 (
		.bcd		(mux_output),
		.seg_digits	(seg_digits)
	);
	
	

	
endmodule
