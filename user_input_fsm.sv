module user_input_fsm (clk, reset, K, Z);
	input logic clk, reset, K;
	output logic Z;
	
	enum { WAIT, EDIT, HOLD } ps, ns;
	
	always_comb begin
		case (ps)
			WAIT: begin
				if (K)
					ns = EDIT;
				else
					ns = WAIT;
			end
			
			EDIT: begin
				ns = HOLD;
			end
			
			HOLD: begin
				if (~K) 
					ns = WAIT;
				else
					ns = HOLD;
			end
			
			default: ns = WAIT;
		endcase
		
	end
	
	// output is only 1 when in edit state
	assign Z = (ps == EDIT);
	
	always_ff @(posedge clk) begin
		if (reset)
			ps <= WAIT;
		else 
			ps <= ns;
	end

endmodule

module user_input_fsm_testbench();
	logic CLOCK_50;
	logic reset;
	logic K;
	logic Z;

	user_input_fsm dut (
		.clk(CLOCK_50),
		.reset(reset),
		.K(K),
		.Z(Z)
	);

	parameter CLOCK_PERIOD = 100;
	initial begin
		CLOCK_50 <= 0;
		forever #(CLOCK_PERIOD/2) CLOCK_50 <= ~CLOCK_50;
	end


	initial begin

		reset <= 1'b1;
		K <= 1'b0;
		repeat(2) @(posedge CLOCK_50);

		reset <= 1'b0;
		repeat(2) @(posedge CLOCK_50);

		// long button press
		K <= 1'b1;
		repeat(6) @(posedge CLOCK_50);

		// release button
		K <= 1'b0;
		repeat(4) @(posedge CLOCK_50);

		// second button press
		K <= 1'b1;
		repeat(3) @(posedge CLOCK_50);

		K <= 1'b0;
		repeat(4) @(posedge CLOCK_50);

		$stop;
	end

endmodule
