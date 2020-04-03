module cam(
	input logic clk,
	input logic [15:0] data_lookup,
	input logic [1:0] init, 
	output logic [2:0] addr,
	output logic valid,
	output logic num_match);

	logic [15:0] RF[2:0]; //16-bit registers; 3 bits to have up to 8 registers

	always_ff@(clk, init); //init is acting as the reset signal
		case(init)
			2'b11:	begin
				RF[0]<=16'b0000000000000000;
				RF[1]<=16'b0000000000000001;
				RF[2]<=16'b0000000000000010;
				RF[3]<=16'b0000000000000011;
				RF[4]<=16'b0000000000000100;
				RF[5]<=16'b0000000000000101;
				RF[6]<=16'b0000000000000110;
				RF[7]<=16'b0000000000000111;
				end
			2'b10:
			2'b01:
			2'b00:


endmodule
