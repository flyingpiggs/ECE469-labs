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
		init = 2'b11; data_lookup = 16'b011; #10;
		data_lookup = 16'b101; #10;
		data_lookup = 16'b100; #10;
		data_lookup = 16'b11110000; #10;
		data_lookup = 16'b111; #10;
		init = 2'b10; data_lookup = 16'b1111111111111110; #10;
		data_lookup = 16'b110; #10;
		data_lookup = 16'b001; #10;
		data_lookup = 16'b0; #10;
		data_lookup = 16'b1111111111111010; #10;
		init = 2'b01; data_lookup = 16'b101; #10;
		data_lookup = 16'b110; #10;
		data_lookup = 16'b01; #10;
		data_lookup = 16'b0; #10;
		data_lookup = 16'b1111111111111111; #10;
		init = 2'b00; data_lookup = 16'b01; #10;
		data_lookup = 16'b1111111111111010; #10;
		data_lookup = 16'b111; #10;
		data_lookup = 16'b011; #10;
		data_lookup = 16'b100; #10;
	end
endmodule
		