module cam(
	input logic clk,
	input logic [15:0] data_lookup,
	input logic [1:0] init, 
	output logic [2:0] addr,
	output logic valid,
	output logic num_match);

	logic [15:0] RF[2:0]; //16-bit registers; 3 bits to have up to 8 registers

	always_ff@(posedge clk, posedge init) //init is acting as an asynchronous reset signal
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
			/*2'b10:
			2'b01:
			2'b00:*/
			default: begin
				RF[0]<=RF[0];
				RF[1]<=RF[1];
				RF[2]<=RF[2];
				RF[3]<=RF[3];
				RF[4]<=RF[4];
				RF[5]<=RF[5];
				RF[6]<=RF[6];
				RF[7]<=RF[7];	
				end	
		endcase
endmodule

module HammingWeight_8bit( input logic[7:0] value,
			   output logic[3:0] count );
	logic[1:0] level1LeftLeft, level1MidLeft, level1MidRight, level1RightRight;
	logic[2:0] level2Left, level2Right;
	
	assign level1LeftLeft = value[7] + value[6];
	assign level1MidLeft = value[5] + value[4];
	assign level1MidRight = value[3] + value[2];
	assign level1RightRight = value[1] + value[0];

	assign level2Left = level1LeftLeft + level1MidLeft; 
	assign level2Right = level1MidRight + level1RightRight;

	assign count = level2Left + level2Right;

endmodule 
