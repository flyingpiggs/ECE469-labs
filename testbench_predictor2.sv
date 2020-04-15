module testbench_predictor2();

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

//Pattern is 0F0F0F0F0F 00000FFFFF 0FFFF00FFF 000FF0000F 0FFF0F000F 00F00FF0FF 
initial begin //Delay of 40 is 4 bits or 4 clock cycles
	reset = 1; X = 0;#2; 
	reset = 0; X = 0;#40;
	X = 1;#40;
	X = 0;#40;
	X = 1;#40;
	X = 0;#40;
	X = 1;#40;
	X = 0;#40;
	X = 1;#40;
	X = 0;#40;
	X = 1;#40;

	X = 0;#200;
	X = 1;#200;

	X = 0;#40;
	X = 1;#160;
	X = 0;#80;
	X = 1;#120;

	X = 0;#120;
	X = 1;#80;
	X = 0;#160;
	X = 1;#40;

	X = 0;#40;
	X = 1;#120;
	X = 0;#40;
	X = 1;#40;
	X = 0;#120;
	X = 1;#40;

	X = 0;#80;
	X = 1;#40;
	X = 0;#80;
	X = 1;#80;
	X = 0;#40;
	X = 1;#80;
	end
endmodule

