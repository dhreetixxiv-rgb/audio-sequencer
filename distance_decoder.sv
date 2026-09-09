module distance_decoder (distance_ticks, speed_level);
	input logic [21:0] distance_ticks;
	output logic [1:0] speed_level;
	
	parameter near = 29000;
	parameter mid  = 87000;
	parameter far  = 174000;
	
	always_comb begin
		if (distance_ticks < near)
			speed_level = 2'b00;
		else if (distance_ticks < mid)
			speed_level = 2'b01;
		else if (distance_ticks < far)
			speed_level = 2'b10;
		else
			speed_level = 2'b11;
	end
	
endmodule

module distance_decoder_testbench()

	logic [21:0] distance_ticks;
	logic [1:0]  speed_level;

	distance_decoder dut (
		.distance_ticks(distance_ticks),
		.speed_level(speed_level)
	);
	

	initial begin
		distance_ticks = 22'd10000;
		#10;

		distance_ticks = 22'd50000;
		#10;

		distance_ticks = 22'd100000;
		#10;

		distance_ticks = 22'd200000;
		#10;

		distance_ticks = 22'h3FFFFF;
		#10;

		$stop();
	end

endmodule