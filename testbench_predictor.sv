module testbench_predictor();

logic clk, reset, actual_pattern, predicted_pattern;

pattern_predictor_2bit dut(clk, reset, actual_pattern, predicted_pattern);

always
	begin
		clk = 1; #5;
		clk = 0; #5;
	end

//Pattern is 000011111111000011110000000011110000
initial begin
	reset = 1; #10;
	reset = 0; 
	actual_pattern = 0;#40;
	actual_pattern = 1;#80;
	actual_pattern = 0;#40;
	actual_pattern = 1;#40;
	actual_pattern = 0;#80;
	actual_pattern = 1;#40;
	actual_pattern = 0;#40;
	end
endmodule
