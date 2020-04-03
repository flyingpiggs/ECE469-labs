module testbench_HammingWeight();

	logic[7:0] value;
	logic[3:0] count; 
	HammingWeight_8bit duts( value, count );

	initial begin
		value = 8'b00000000; #10;
		value = 8'b00000001; #10;
		value = 8'b00000011; #10;
		value = 8'b00000111; #10;
		value = 8'b00001111; #10;
		value = 8'b00011111; #10;
		value = 8'b00111111; #10;
		value = 8'b01111111; #10;
		value = 8'b11111111; #10;
	end  
endmodule 
