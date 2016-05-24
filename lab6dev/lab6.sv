module lab6 (
	input reset_n,
	input clk_50,
	input dout,

	input clk_3m,
	input clk_10k,	
	input clk_2,

	output sclk,
	output cs_n, 
	output logic din,
	output logic [6:0] seg_digits,
	output [2:0] sel,
	output en_n,
	output logic en,
	output pwm,
	output dp
);

	assign en_n = 1'b0;
	assign pwm = 1'b0;
	assign en = 1'b1;

	// PLL

	// 16MHz clk

	// 10kHz clk

	// 3.2MHz clk for ADC chip


	// generate get_adc_data signal from a 2Hz clock
	logic sync_0;

	always_ff @ (posedge clk_3m, negedge reset_n) begin
		if (!reset_n) sync_0 <= 1'b0;
		else sync_0 <= clk_2;
	end

	logic clean_button_sync;
	always_ff @ (posedge clk_3m, negedge reset_n) begin
		if (!reset_n) clean_button_sync <= 1'b0;
		else clean_button_sync <= sync_0;
	end

	logic get_adc_data;

	// state machine
	enum logic [1:0] {
		DETECT = 2'b00,
		PULSE = 2'b01,
		WAIT = 2'b10} pulse_ns, pulse_ps;

	always_ff @ (posedge clk_3m, negedge reset_n) begin
		if (!reset_n) 
			pulse_ps <= DETECT;
		else 
			pulse_ps <= pulse_ns;
	end

	always_comb begin
		get_adc_data = 1'b0;
		case (pulse_ps)
			DETECT : if (clean_button_sync) pulse_ns = PULSE;
				 else pulse_ns = DETECT;
			PULSE : begin
				get_adc_data = 1'b1;
				pulse_ns = WAIT;
			end
			WAIT : if (clean_button_sync) pulse_ns = WAIT;
			       else pulse_ns = DETECT;
		endcase					
	end

	// instantiations of adc module
	logic shift_reg_enable, adc_data_ready;
	logic [1:0] mux_sel;

	adc_control adc_control_0 (
		 .clk		(clk_3m),
		 .get_adc_data	(get_adc_data),
		 .reset_n	(reset_n),

		 .next_address	(mux_sel),
		 .shift_reg_enable	(shift_reg_enable),
		 .sclk		(sclk),
		 .cs_n		(cs_n),
		 .adc_data_ready	(adc_data_ready)
	);

	// address mux
	logic [2:0] addr;
	assign addr = 3'b000;

	always_comb begin
		unique case (mux_sel)
			2'b00 : din = addr[0];
			2'b01 : din = addr[1];
			2'b10 : din = addr[2];
		endcase
	end

	// instantiations of shift register module
	logic [11:0] parallel_data;

	shift_reg shift_reg_0 (
		.serial_data	(dout),
		.sclk		(sclk),
		.reset_n	(reset_n),
		.shift_reg_enable	(shift_reg_enable),
 	        .parallel_data	(parallel_data)
	);

	// instantiations of binary to bcd module
	logic [3:0] bcd_0, bcd_1, bcd_2, bcd_3;
	bin_to_bcd bin_to_bcd_0 (
		.binary 	(parallel_data),
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
