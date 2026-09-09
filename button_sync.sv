module button_sync (clk, reset, raw_key, clean_key);
    input logic clk;
    input logic reset;
    input logic raw_key; 
    output logic clean_key; 

    logic dff1; 

    always_ff @(posedge clk) begin
        if (reset) begin
            dff1 <= 1'b0;
            clean_key <= 1'b0;
        end else begin
            dff1 <= raw_key; 
            clean_key <= dff1; 
        end
    end

endmodule

