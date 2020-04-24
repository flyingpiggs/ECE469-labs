module controllertest();

logic clk, reset;
logic [5:0] op, funct;
logic zero;
logic pcen, memwrite, irwrite, regwrite;
logic alusrca, iord, memtoreg, regdst;
logic [1:0] alusrcb, pcsrc;
logic [2:0] alucontrol;
logic [3:0] state;/*ADDED*/

controller dut(clk, reset, op, funct, zero, pcen, memwrite,
		irwrite, regwrite, alusrca, iord, memtoreg,
		regdst, alusrcb, pcsrc, alucontrol, state/*ADDED*/);

always begin
	clk <= 1; #5;
	clk <= 0; #5;
end

initial begin
	//add
	reset = 1;zero = 0;op = 6'b000000; funct = 6'b100000;#10;
	reset = 0;#30;
	//sub
	funct = 6'b100010;#40;
	//and
	funct = 6'b100100;#40; 
	//or
	funct = 6'b100101;#40;
	//slt
	funct = 6'b101010;#40;
	//lw
	op = 6'b100011;#50;
	//sw
	op = 6'b101011;#40;
	//beq-taken
	op = 6'b000100; zero = 1;#30;
	//beq-nottaken
	op = 6'b000100; zero = 0;#30;
	//addi
	op = 6'b001000;#40;
	//j
	op = 6'b000010;#30;
end
endmodule
