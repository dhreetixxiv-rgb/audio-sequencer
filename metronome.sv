module metronome (clk, reset, speed_level, tempo, freq);
	input logic clk, reset;
	input logic [1:0] speed_level;
	output logic tempo, freq;
	
	// fast -> slow
	parameter TEMPO_LIMIT_0 = 6250000 - 1;
	parameter TEMPO_LIMIT_1 = 9375000 - 1;
	parameter TEMPO_LIMIT_2 = 12500000 - 1; 
	parameter TEMPO_LIMIT_3 = 18750000 - 1;
	parameter FREQ_LIMIT = 2 - 1;
	
	// 32 bit, count up to 12499999 and 1041
	integer tempo_count;
	integer freq_count;
	
	logic [31:0] tempo_limit;
	
	always_comb begin
		case (speed_level)
			2'b00: tempo_limit = TEMPO_LIMIT_0;
			2'b01: tempo_limit = TEMPO_LIMIT_1;
			2'b10: tempo_limit = TEMPO_LIMIT_2;
			2'b11: tempo_limit = TEMPO_LIMIT_3;
			default: tempo_limit = TEMPO_LIMIT_2;
		endcase
	end
	
	always_ff @(posedge clk) begin
		if (reset) begin
			tempo_count <= 0;
			freq_count <= 0;
			tempo <= 1'b0;
			freq <= 1'b0;
			
		end else begin
			tempo <= 1'b0;
			freq <= 1'b0;

			if (tempo_count >= tempo_limit) begin
				tempo_count <= 0;
				tempo <= 1'b1;
			end else begin
				tempo_count <= tempo_count + 1;
			end

			if (freq_count >= FREQ_LIMIT) begin
				freq_count <= 0;
				freq <= 1'b1;
			end else begin
				freq_count <= freq_count +1;
			end

		end
	end
	
endmodule


module metronome_testbench();

    logic CLOCK_50;
    logic reset;
    logic [1:0] speed_level;
    logic tempo;
    logic freq;

	metronome dut (
		.clk(CLOCK_50),
		.reset(reset),
		.speed_level(speed_level),
		.tempo(tempo),
		.freq(freq)
	);

   parameter CLOCK_PERIOD = 100;
	initial begin
		CLOCK_50 <= 0;
		forever #(CLOCK_PERIOD/2) CLOCK_50 <= ~CLOCK_50;
	end

	initial begin
		reset <= 1'b1;
		speed_level <= 2'b00;
		repeat (2) @(posedge CLOCK_50);

		reset = 1'b0;
		repeat (2) @(posedge CLOCK_50);

		speed_level <= 2'b00;
		repeat (12) @(posedge CLOCK_50);

		speed_level <= 2'b01;
		repeat (20) @(posedge CLOCK_50);

		speed_level <= 2'b10;
		repeat (30) @(posedge CLOCK_50);

		speed_level <= 2'b11;
		repeat (40) @(posedge CLOCK_50);

		$stop;
	end

endmodule