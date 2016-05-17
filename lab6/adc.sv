module adc (
	input clk,
	input get_adc_data,
	input reset_n,

	output data_enable,
	output sclk,
	output logic cs_n,
	output logic din,
	output logic adc_data_ready
);

	enum logic [1:0] {
		idle = 2'b00,
		start = 2'b01,
		stop = 2'b10} adc_ns, adc_ps;

	enum logic {
		sclk_low = 1'b0,
		sclk_high =1'b1} sclk_ns, sclk_ps;
	
	// count down bits for control ADC chip
	logic [3:0] bit_cnt;
	always_ff @ (posedge clk, negedge reset_n) begin
		if (!reset_n) 
			bit_cnt <= 15;
		else if (bit_cnt == 0 && sclk == 1'b1 && adc_ps == start)
			bit_cnt <= 15;
		else if (sclk == 1'b1 && adc_ps == start)
			bit_cnt --;
		else
			bit_cnt <= bit_cnt;
	end

	// conversion state machine
	always_ff @ (posedge clk, negedge reset_n) begin
		if (!reset_n) begin 
			adc_ps <= idle;
		end
		else 
			adc_ps <= adc_ns;
	end
	
	always_comb begin
		case (adc_ps) 
			idle : begin
				adc_data_ready = 1'b0;
				cs_n = 1'b1;
				if (get_adc_data == 1'b1)
					adc_ns = start;
			       	else begin
					adc_ns = idle;
				end
			       end
			start : begin
				cs_n = 1'b0;
				adc_data_ready = 1'b0;
				if (bit_cnt == 0 && sclk == 1'b1)
					adc_ns = stop;
				else
					adc_ns = start;
				end
			stop : begin
				cs_n = 1'b1;
				adc_data_ready = 1'b1;
				adc_ns = idle;	
			       end
		endcase		
	end

	// serial clock state machine
	always_ff @ (posedge clk, negedge reset_n) begin
		if (!reset_n)
			sclk_ps <= sclk_low;
		else 
			sclk_ps <= sclk_ns;
	end

	always_comb begin
		case (sclk_ps) 
			sclk_low : if (adc_ps == start)
					sclk_ns = sclk_high;
				   else 
					sclk_ns = sclk_low;
			sclk_high : sclk_ns = sclk_low;
		endcase
	end

	assign sclk = sclk_ps;

	// select signal
	logic [1:0] sel;

	always_ff @ (negedge sclk, negedge reset_n) begin
		if (!reset_n) begin
			sel <= 2'b11;
		end
		else if (bit_cnt == 13)
			sel <= 2'b10;
		else if (bit_cnt == 12)
			sel <= 2'b01;
		else if (bit_cnt == 11)
			sel <= 2'b00;
		else
			sel <= 2'b11; // don't care case
	end

	// address mux
	always_comb begin
		unique case (sel)
			2'b00 : din = 0;
			2'b01 : din = 0;
			2'b10 : din = 0;
			2'b11 : din = 1; // don't care case
		endcase
	end

	assign data_enable = (0 <= bit_cnt && bit_cnt <= 11) ? 1'b1 : 1'b0;	
endmodule
