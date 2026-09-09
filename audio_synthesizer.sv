module audio_synthesizer (clk, reset, freq, step_valid, kick, snare, hi, mid, pcm_out);
	input logic clk, reset, freq, step_valid, kick, snare, hi, mid;
	output logic [23:0] pcm_out;

	integer kick_timer, snare_timer, hi_timer, mid_timer;

	logic [15:0] kick_tone_count, snare_tone_count, hi_tone_count, mid_tone_count;
	
	// step_valid = go for drum on current step

	// kick counter
	always_ff @(posedge clk) begin
		if (reset) begin
			kick_timer <= 0;
			kick_tone_count <= 16'd0;
		end else begin
			if (step_valid && kick) begin
				kick_timer <= 6000; // 0.125s
				kick_tone_count <= 16'd0;
			end else if (freq && (kick_timer > 0)) begin
				kick_timer <= kick_timer - 1;
				kick_tone_count <= kick_tone_count + 1'b1;
			end
		end
	end

	// snare
	always_ff @(posedge clk) begin
		if (reset) begin
			snare_timer <= 0;
			snare_tone_count <= 16'd0;
		end else begin
			if (step_valid && snare) begin
				snare_timer <= 3000; // 31ms
				snare_tone_count <= 16'd0;
			end else if (freq && (snare_timer > 0)) begin
				snare_timer <= snare_timer - 1;
				snare_tone_count <= snare_tone_count + 1'b1;
			end
		end
	end
	
	// hi
	always_ff @(posedge clk) begin
		if (reset) begin
			hi_timer <= 0;
			hi_tone_count <= 16'd0;
		end else begin
			if (step_valid && hi) begin
				hi_timer <= 1500;
				hi_tone_count <= 16'd0;
			end else if (freq && (hi_timer > 0)) begin
				hi_timer <= hi_timer - 1;
				hi_tone_count <= hi_tone_count + 1'b1;
			end
		end
	end
	
	// mid
	always_ff @(posedge clk) begin
		if (reset) begin
			mid_timer <= 0;
			mid_tone_count <= 16'd0;
		end else begin
			if (step_valid && mid) begin
				mid_timer <= 4500; 
				mid_tone_count <= 16'd0;
			end else if (freq && (mid_timer > 0)) begin
				mid_timer <= mid_timer - 1;
				mid_tone_count <= mid_tone_count + 1'b1;
			end
		end
	end

	always_comb begin
		pcm_out = 24'sh0; 

		if (kick_timer > 3600) begin
			// 1 to 0 to 1 to 0 etc etc to generate the beep
			if (kick_tone_count[8])
				pcm_out = 24'sh7FFFFF;
			else
				pcm_out = -24'sh7FFFFF;
				
		end else if (kick_timer > 0) begin
			if (kick_tone_count[8])
				pcm_out = 24'sh2FFFFF;
			else
				pcm_out = -24'sh2FFFFF;
				
		end else if (snare_timer > 0) begin
			if (snare_tone_count[6])
				pcm_out = 24'sh5FFFFF;
			else
				pcm_out = -24'sh5FFFFF;
				
		end else if (mid_timer > 0) begin
			if (mid_tone_count[7])
				pcm_out = 24'sh5FFFFF;
			else
				pcm_out = -24'sh5FFFFF;
				
		end else if (hi_timer > 0) begin
			if (hi_tone_count[3])
				pcm_out = 24'sh4FFFFF;
			else
				pcm_out = -24'sh4FFFFF;
				
		end else begin
			pcm_out = 24'sh0;
		end
	end

endmodule

module audio_synthesizer_testbench();

	logic CLOCK_50;
	logic reset;
	logic freq;
	logic step_valid;
	logic kick;
	logic snare;
	logic hi;
	logic mid;
	logic [23:0] pcm_out;

	audio_synthesizer dut (
		.clk(CLOCK_50),
		.reset(reset),
		.freq(freq),
		.step_valid(step_valid),
		.kick(kick),
		.snare(snare),
		.hi(hi),
		.mid(mid),
		.pcm_out(pcm_out)
	);

	parameter CLOCK_PERIOD = 100;
	initial begin
		CLOCK_50 <= 0;
		forever #(CLOCK_PERIOD/2) CLOCK_50 <= ~CLOCK_50;
	end

	// fake clock only for testing not real
	initial begin
		freq = 1'b0;
		forever begin
			repeat (3) @(posedge CLOCK_50);
			freq = 1'b1;
			@(posedge CLOCK_50);
			freq = 1'b0;
		end
	end

	initial begin
		reset = 1'b1;
		step_valid = 1'b0;
		kick = 1'b0;
		snare = 1'b0;
		hi = 1'b0;
		mid = 1'b0;
		repeat (4) @(posedge CLOCK_50);

		reset = 1'b0;
		repeat (4) @(posedge CLOCK_50);

		kick = 1'b1;
		step_valid = 1'b1;
		@(posedge CLOCK_50);
		step_valid = 1'b0;
		kick = 1'b0;

		repeat (12000) @(posedge CLOCK_50);

		snare = 1'b1;
		step_valid = 1'b1;
		@(posedge CLOCK_50);
		step_valid = 1'b0;
		snare = 1'b0;
		repeat (12000) @(posedge CLOCK_50);

		hi = 1'b1;
		step_valid = 1'b1;
		@(posedge CLOCK_50);
		step_valid = 1'b0;
		hi = 1'b0;
		repeat (8000) @(posedge CLOCK_50);

		mid = 1'b1;
		step_valid = 1'b1;
		@(posedge CLOCK_50);
		step_valid = 1'b0;
		mid = 1'b0;
		repeat (18000) @(posedge CLOCK_50);

		$stop;
	end

endmodule