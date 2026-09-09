module step_counter (clk, reset, tempo, current_step, step_valid, leds);
	input logic clk, reset, tempo;
	output logic [2:0] current_step;
	output logic step_valid;
	output logic [7:0] leds;

	// 3 bit counter
	always_ff @(posedge clk) begin
		if (reset) begin
			current_step <= 3'b000;
		end else if (tempo) begin
			current_step <= current_step + 1'b1;
		end
	end

	// need delay here, otherwise if you try to read beat on tempo, but current step will have old step number, since current step 
	// takes one cycle to update its value when tempo=1
	
	always_ff @(posedge clk) begin
		if (reset) begin
			step_valid <= 1'b0;
		end else begin
			step_valid <= tempo;
		end
	end

	// 3:8 decoder
	always_comb begin
		case (current_step)
			3'b000: leds = 8'b00000001;
			3'b001: leds = 8'b00000010;
			3'b010: leds = 8'b00000100;
			3'b011: leds = 8'b00001000;
			3'b100: leds = 8'b00010000;
			3'b101: leds = 8'b00100000;
			3'b110: leds = 8'b01000000;
			3'b111: leds = 8'b10000000;
			default: leds = 8'b00000000;
		endcase
	end

endmodule

module step_counter_testbench();
	logic CLOCK_50;
	logic reset;
	logic tempo;
	logic [2:0] current_step;
	logic [7:0] leds;

	step_counter dut (
				.clk(CLOCK_50),
				.reset(reset),
				.tempo(tempo),
				.current_step(current_step),
				.leds(leds)
	);

	parameter CLOCK_PERIOD = 100;
	initial begin
		CLOCK_50 <= 0;
		forever #(CLOCK_PERIOD/2) CLOCK_50 <= ~CLOCK_50;
	end

	initial begin

		reset <= 1'b1;
		tempo <= 1'b0;
		repeat(2) @(posedge CLOCK_50);

		reset <= 1'b0;
		repeat(2) @(posedge CLOCK_50);

		// pulsing tempo 10 times to verify counting 0 to 7 and wrapping back around to 0
		repeat (10) begin
			tempo <= 1'b1; @(posedge CLOCK_50);
			tempo <= 1'b0; repeat(3) @(posedge CLOCK_50);
		end

		reset <= 1'b1; repeat(2) @(posedge CLOCK_50);
		reset <= 1'b0; repeat(2) @(posedge CLOCK_50);

		$stop;
	end

endmodule
	

