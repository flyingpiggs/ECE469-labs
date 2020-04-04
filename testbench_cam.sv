module testbench_cam();

	logic clk;
	logic [15:0] data_lookup;
	logic [1:0] init;
	logic [2:0] addr;
	logic valid;
	logic [3:0] num_match;

	cam dut(clk, data_lookup, init, addr, valid, num_match);

	always begin
		clk<=1;#5;
		clk<=0;#5;
	end

	initial begin
		init = 2'b11; data_lookup = 16'b0; #10;
		/*init = 0;*/ data_lookup = 16'b11; #10;
		data_lookup = 16'b100; #10;
		data_lookup = 16'b11110000; #10;
		data_lookup = 16'b0; #10;
	end
endmodule
		