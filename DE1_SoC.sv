module DE1_SoC (
    CLOCK_50, 
    HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, 
    KEY, 
    LEDR, 
    SW, 
    AUD_ADCDAT,
    AUD_ADCLRCK,
    AUD_BCLK,
    AUD_DACDAT,
    AUD_DACLRCK,
    FPGA_I2C_SCLK,
    FPGA_I2C_SDAT,
    AUD_XCK,
	 GPIO_0
);
	
	inout logic [35:0] GPIO_0;

	input logic CLOCK_50; // 50MHz clock.
	output logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
	output logic [9:0] LEDR;
	input logic [3:0] KEY;
	input logic [9:0] SW;

	output FPGA_I2C_SCLK;
	inout FPGA_I2C_SDAT;
	output AUD_XCK;
	input AUD_DACLRCK, AUD_ADCLRCK, AUD_BCLK;
	input AUD_ADCDAT;
	output AUD_DACDAT;

	assign HEX0 = 7'b1111111;
	assign HEX1 = 7'b1111111;
	assign HEX2 = 7'b1111111;
	assign HEX3 = 7'b1111111;
	assign HEX4 = 7'b1111111;
	assign HEX5 = 7'b1111111;
	
	logic reset;
	logic button_in;
	logic tempo_pulse;
	logic advance_pulse;
	logic edit_pulse;
	logic [2:0] current_step;
	logic kick_trigger;
	logic snare_trigger;
	logic hi_trigger;
	logic mid_trigger;
	logic [23:0] pcm_data;

	assign reset = ~KEY[3];
	assign button_in = ~KEY[0];

	assign LEDR[8] = 1'b0;
	assign LEDR[9] = kick_trigger | snare_trigger | hi_trigger | mid_trigger;

	logic tempo_sel;
	assign tempo_sel = SW[7];


	logic [21:0] distance_ticks;
	logic new_sample;
	logic [1:0] speed_level;
	
	logic step_valid; 
	
	 
	ultrasonic_sensor us0 (
		.clk(CLOCK_50),
		.reset(reset),
		.echo_raw(GPIO_0[34]),
		.trig(GPIO_0[35]),
		.distance_ticks(distance_ticks),
		.new_sample(new_sample)
	);
 
	 
	 
	distance_decoder d0 (
		.distance_ticks(distance_ticks),
		.speed_level(speed_level)
	);
	 
	metronome m (
		.clk(CLOCK_50),
		.reset(reset),
		.speed_level(speed_level),
		.tempo(tempo_pulse),
		.freq() 
	);


	step_counter s0 (
		.clk(CLOCK_50),
		.reset(reset),
		.tempo(tempo_pulse),
		.current_step(current_step),
		.step_valid(step_valid),
		.leds(LEDR[7:0])
	);

	logic synced_button;
	
	 button_sync sync0 (
		.clk(CLOCK_50),
		.reset(reset),
		.raw_key(button_in),
		.clean_key(synced_button)
    );

    user_input_fsm fsm0 (
		.clk(CLOCK_50),
		.reset(reset),
		.K(synced_button),
		.Z(edit_pulse)
    );

    pattern_memory mem0 (
		.clk(CLOCK_50),
		.reset(reset),
		.change(edit_pulse),
		.sw_step(SW[2:0]),
		.sw_instr(SW[9:8]),
		.current_step(current_step),
		.kick(kick_trigger),
		.snare(snare_trigger),
		.hi(hi_trigger),
		.mid(mid_trigger)
    );
	 
	audio_synthesizer synth0 (
		.clk(CLOCK_50),
		.reset(reset),
		.freq(advance_pulse),
		.step_valid(step_valid), 
		.kick(kick_trigger),
		.snare(snare_trigger),
		.hi(hi_trigger),
		.mid(mid_trigger),
		.pcm_out(pcm_data)
	);


	audio_driver audio_subsystem (
		.CLOCK_50(CLOCK_50),
		.reset(reset),

		.dac_left(pcm_data),
		.dac_right(pcm_data),

		.adc_left(),
		.adc_right(),

		.advance(advance_pulse),

		.FPGA_I2C_SCLK(FPGA_I2C_SCLK),
		.FPGA_I2C_SDAT(FPGA_I2C_SDAT),
		.AUD_XCK(AUD_XCK),
		.AUD_DACLRCK(AUD_DACLRCK),
		.AUD_ADCLRCK(AUD_ADCLRCK),
		.AUD_BCLK(AUD_BCLK),
		.AUD_ADCDAT(AUD_ADCDAT),
		.AUD_DACDAT(AUD_DACDAT)
	);
	 
	 
endmodule 

module DE1_SoC_testbench();
	logic CLOCK_50;
	logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
	logic [9:0] LEDR;
	logic [3:0] KEY;
	logic [9:0] SW;

	logic FPGA_I2C_SCLK;
	wire PGA_I2C_SDAT;
	logic AUD_XCK;
	logic AUD_DACLRCK, AUD_ADCLRCK, AUD_BCLK;
	logic AUD_ADCDAT;
	logic AUD_DACDAT;

	wire [35:0] GPIO_0;
	logic echo_sim;
	assign GPIO_0[34] = echo_sim;

	DE1_SoC dut (
		.CLOCK_50 (CLOCK_50),
		.HEX0 (HEX0),
		.HEX1 (HEX1),
		.HEX2 (HEX2),
		.HEX3 (HEX3),
		.HEX4 (HEX4),
		.HEX5 (HEX5),
		.LEDR (LEDR),
		.KEY (KEY),
		.SW (SW),
		.AUD_ADCDAT (AUD_ADCDAT),
		.AUD_ADCLRCK (AUD_ADCLRCK),
		.AUD_BCLK (AUD_BCLK),
		.AUD_DACDAT (AUD_DACDAT),
		.AUD_DACLRCK (AUD_DACLRCK),
		.FPGA_I2C_SCLK (FPGA_I2C_SCLK),
		.FPGA_I2C_SDAT (FPGA_I2C_SDAT),
		.AUD_XCK (AUD_XCK),
		.GPIO_0 (GPIO_0)
	);

	parameter CLOCK_PERIOD = 100;
	initial begin
		CLOCK_50 <= 0;
		forever #(CLOCK_PERIOD/2) CLOCK_50 <= ~CLOCK_50;
	end

	
	initial begin
		KEY = 4'b1111;
		SW = 10'd0;
		echo_sim = 1'b0;
		AUD_BCLK = 1'b0;
		AUD_DACLRCK = 1'b0;
		AUD_ADCLRCK = 1'b0;
		AUD_ADCDAT = 1'b0;

		KEY[3] = 1'b0;
		repeat (5) @(posedge CLOCK_50);
		KEY[3] = 1'b1;
		repeat (5) @(posedge CLOCK_50);

		

		// snare
		SW[2:0] = 3'b100; 
		SW[4:3] = 2'b01; 
		repeat (2) @(posedge CLOCK_50);
		
		// edit
		KEY[0] = 1'b0;
		repeat (10) @(posedge CLOCK_50);
		KEY[0] = 1'b1;
		repeat (10) @(posedge CLOCK_50);
		
		// reset
		KEY[3] = 1'b0;
		repeat (5) @(posedge CLOCK_50);
		KEY[3] = 1'b1;
		repeat (5) @(posedge CLOCK_50);
		
		
		// kick
		SW[2:0] = 3'b000;
		SW[4:3] = 2'b00;
		repeat (2) @(posedge CLOCK_50);
		
		// edit
		KEY[0] = 1'b0;
		repeat (10) @(posedge CLOCK_50);
		KEY[0] = 1'b1;
		repeat (10) @(posedge CLOCK_50);
		
		// reset
		KEY[3] = 1'b0;
		repeat (5) @(posedge CLOCK_50);
		KEY[3] = 1'b1;
		repeat (5) @(posedge CLOCK_50);
		

		// hi
		SW[2:0] = 3'b010; 
		SW[4:3] = 2'b10;  
		repeat (2) @(posedge CLOCK_50);
		
		// edit
		KEY[0] = 1'b0;
		repeat (10) @(posedge CLOCK_50);
		KEY[0] = 1'b1;
		repeat (10) @(posedge CLOCK_50);
		
		
		
		
		@(posedge GPIO_0[35]);
		repeat (10) @(posedge CLOCK_50);

		echo_sim = 1'b1;
		repeat (1000) @(posedge CLOCK_50);
		echo_sim = 1'b0;

		repeat (5000) @(posedge CLOCK_50);


		SW[2:0] = 3'b100; // Step 4
		SW[4:3] = 2'b11;  // Mid-Tom
		repeat (2) @(posedge CLOCK_50);
		
		// edit
		KEY[0] = 1'b0;
		repeat (10) @(posedge CLOCK_50);
		KEY[0] = 1'b1;
		repeat (10) @(posedge CLOCK_50);

		// testing removing kick from step 0
		SW[2:0] = 3'b000;
		SW[4:3] = 2'b00;
		repeat (2) @(posedge CLOCK_50);
		
		// edit
		KEY[0] = 1'b0;
		repeat (10) @(posedge CLOCK_50);
		KEY[0] = 1'b1;
		repeat (10) @(posedge CLOCK_50);

		// medium range
		@(posedge GPIO_0[35]);
		repeat (10) @(posedge CLOCK_50);
		echo_sim = 1'b1;
		repeat (50000) @(posedge CLOCK_50);
		echo_sim = 1'b0;

		repeat (20000) @(posedge CLOCK_50);
		
		// reset
		KEY[3] = 1'b0;
		repeat (5) @(posedge CLOCK_50);
		KEY[3] = 1'b1;
		repeat (5) @(posedge CLOCK_50);
		

		$stop;
	end

endmodule