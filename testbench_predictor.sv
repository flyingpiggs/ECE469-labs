module testbench_predictor();

logic clk, reset, X;
logic [7:0] X_cnt;
logic Y, Y_match;
logic [7:0] Y_cnt;
logic Z, Z_match;
logic [7:0] Z_cnt;

PatternPredictor dut(clk, reset, X, X_cnt, Y, Y_match, Y_cnt, Z, Z_match, Z_cnt);

always
	begin
		clk = 0; #5;
		clk = 1; #5;
	end

//Pattern is 000011111111000011110000000011110000
initial begin
	reset = 1; X = 0;#2; 
	reset = 0; X = 0;#40;
	X = 1;#80;
	X = 0;#40;
	X = 1;#40;
	X = 0;#80;
	X = 1;#40;
	X = 0;#40;
	end
endmodule
/*initial begin
	reset = 1; X = 0;#10; 
	reset = 0; X = 0;#30;
	X = 1;#80;
	X = 0;#40;
	X = 1;#40;
	X = 0;#80;
	X = 1;#40;
	X = 0;#40;
	end
endmodule*/
