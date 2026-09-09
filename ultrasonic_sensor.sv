module ultrasonic_sensor (clk, reset, echo_raw, trig, distance_ticks, new_sample);
	input logic clk, reset, echo_raw;
	output logic trig;
	output logic [21:0] distance_ticks;
	output logic new_sample;
	

	logic echo;
	button_sync echo_sync_inst (
		.clk(clk),
		.reset(reset),
		.raw_key(echo_raw),
		.clean_key(echo)
	);

	parameter trig_high_cycles = 500;
	parameter count_timeout = 2250000;
	parameter rise_timeout = 5000000;
	parameter gap_cycles = 3000000;

	enum logic [2:0] { IDLE, TRIGGER, WAIT_RISE, COUNTING, GAP } ps, ns;

	integer counter;
	integer echo_count;

	always_comb begin
		case (ps)
			IDLE: begin
				ns = TRIGGER;
			end

			TRIGGER: begin
				if (counter >= trig_high_cycles - 1)
					ns = WAIT_RISE;
				else
					ns = TRIGGER;
			end

			WAIT_RISE: begin
				if (echo)
					ns = COUNTING;
				else if (counter >= rise_timeout)
					ns = GAP;
				else
					ns = WAIT_RISE;
			end

			COUNTING: begin
				if (!echo)
					ns = GAP;
				else if (echo_count >= count_timeout)
					ns = GAP;
				else
					ns = COUNTING;
			end

			GAP: begin
				if (counter >= gap_cycles)
					ns = IDLE;
				else
					ns = GAP;
			end

			default: ns = IDLE;
		
		endcase
	end
	
	assign trig = (ps == TRIGGER);

	always_ff @(posedge clk) begin
		if (reset)
			ps <= IDLE;
		else
			ps <= ns;
	end


	
	// handling updating counter, echo_count, distance_ticks, and new_sample in each state
	// register
	always_ff @(posedge clk) begin
		if (reset) begin
			counter <= 0;
			echo_count <= 0;
			distance_ticks <= 22'd0;
			new_sample <= 1'b0;
		
		end else begin
			new_sample <= 1'b0;

			case (ps)
				IDLE: begin
					counter <= 0;
				end

				TRIGGER: begin
					if (counter >= trig_high_cycles - 1)
						counter <= 0;
					else
						counter <= counter + 1;
				end
				
				// 0011 1111 1111 1111 1111 1111
				WAIT_RISE: begin
					if (echo) begin
						echo_count <= 0;
						counter <= 0;
					end else if (counter >= rise_timeout) begin
						distance_ticks <= 22'h3FFFFF;
						new_sample <= 1'b1;
						counter <= 0;
					end else begin
						counter <= counter + 1;
					end
				end
				
				COUNTING: begin
					if (echo) begin
						if (echo_count >= count_timeout) begin
							distance_ticks <= 22'h3FFFFF;
							new_sample <= 1'b1;
							counter <= 0;
						end else begin
							echo_count <= echo_count + 1;
						end
						
					end else begin
						distance_ticks <= echo_count[21:0];
						new_sample <= 1'b1;
						counter <= 0;
					end
				end

				GAP: begin
					if (counter >= gap_cycles)
						counter <= 0;
					else
						counter <= counter+ 1;
					end

				default: counter <= counter;
	
			endcase
		end
	end

endmodule


module ultrasonic_sensor_testbench();

	logic CLOCK_50;
	logic reset;
	logic echo_raw;
	logic trig;
	logic [21:0] distance_ticks;
	logic new_sample;

	ultrasonic_sensor dut (
		.clk(CLOCK_50),
		.reset(reset),
		.echo_raw(echo_raw),
		.trig(trig),
		.distance_ticks(distance_ticks),
		.new_sample(new_sample)
	);

	parameter CLOCK_PERIOD = 100;
	initial begin
		CLOCK_50 <= 0;
		forever #(CLOCK_PERIOD/2) CLOCK_50 <= ~CLOCK_50;
	end

	initial begin

		reset = 1'b1;
		echo_raw = 1'b0; 
		#100;
		reset = 1'b0;
		#40;


		#10500;

		echo_raw = 1'b1;
		#2000;
		echo_raw = 1'b0;

		#500;


		#60010000;

		#10500;

		echo_raw = 1'b1;
		#6000;
		echo_raw = 1'b0;

		#1000;
		$stop;
	end
	
endmodule