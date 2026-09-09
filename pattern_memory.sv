module pattern_memory (clk, reset, change, sw_step, sw_instr, current_step, kick, snare, hi, mid);
	input logic clk, reset, change;
	input logic [2:0] sw_step; // select which of 8 steps u want to edit
	input logic [1:0] sw_instr; // select which instrument u want to add on selected step
	input logic [2:0] current_step;
	output logic kick, snare, hi, mid;
	
	logic [7:0][3:0] pattern;
	
	always_ff @(posedge clk) begin
		if (reset) begin
			pattern <= 32'd0;
		end else if (change) begin
			pattern[sw_step][sw_instr] <= ~pattern[sw_step][sw_instr];
		end
		
	end
	
	always_comb begin
		kick = pattern[current_step][0];
		snare = pattern[current_step][1];
		hi = pattern[current_step][2];
		mid = pattern[current_step][3];
	end
	
endmodule


module pattern_memory_testbench();
	
	logic CLOCK_50;
	logic reset;
	logic change;
	logic [2:0] sw_step;
	logic [1:0] sw_instr;
	logic [2:0] current_step;
	logic kick, snare, hi, mid;

	pattern_memory dut (
		.clk(CLOCK_50),
		.reset(reset),
		.change(change),
		.sw_step(sw_step),
		.sw_instr(sw_instr),
		.current_step(current_step),
		.kick(kick),
		.snare(snare),
		.hi(hi),
		.mid(mid)
	);

	parameter CLOCK_PERIOD = 100;
	initial begin
		CLOCK_50 <= 0;
		forever #(CLOCK_PERIOD/2) CLOCK_50 <= ~CLOCK_50;
	end

	initial begin

		reset = 1'b1;
		change = 1'b0;
		sw_step = 3'b000;
		sw_instr = 2'b00;
		current_step <= 3'b000;
		repeat(2) @(posedge CLOCK_50);

		reset <= 1'b0;
		repeat(2) @(posedge CLOCK_50);

		sw_step <= 3'd2;

		// kick
		sw_instr <= 2'b00;
		repeat(2) @(posedge CLOCK_50);
		change <= 1'b1; @(posedge CLOCK_50);
		change <= 1'b0; repeat(2) @(posedge CLOCK_50);

		// hi
		sw_instr <= 2'b10;
		repeat(2) @(posedge CLOCK_50);
		change <= 1'b1; @(posedge CLOCK_50);
		change <= 1'b0; repeat(2) @(posedge CLOCK_50);

		sw_step <= 3'd5;

		//snare
		sw_instr <= 2'b01;
		repeat(2) @(posedge CLOCK_50);
		change <= 1'b1; @(posedge CLOCK_50);
		change <= 1'b0; repeat(2) @(posedge CLOCK_50);

		// mid
		sw_instr <= 2'b11;
		repeat(2) @(posedge CLOCK_50);
		change <= 1'b1; @(posedge CLOCK_50);
		change <= 1'b0; repeat(2) @(posedge CLOCK_50);

		current_step <= 3'd0; repeat(2) @(posedge CLOCK_50);
		current_step <= 3'd1; repeat(2) @(posedge CLOCK_50);
		current_step <= 3'd2; repeat(2) @(posedge CLOCK_50);
		current_step <= 3'd3; repeat(2) @(posedge CLOCK_50);
		current_step <= 3'd4; repeat(2) @(posedge CLOCK_50);
		current_step <= 3'd5; repeat(2) @(posedge CLOCK_50);

		sw_step <= 3'd2;
		sw_instr <= 2'b00; 
		repeat(2) @(posedge CLOCK_50);
		change <= 1'b1; @(posedge CLOCK_50);
		change <= 1'b0; repeat(2) @(posedge CLOCK_50);

		// only hi plays
		current_step <= 3'd2; repeat(2) @(posedge CLOCK_50);

		$stop;
	end

endmodule
