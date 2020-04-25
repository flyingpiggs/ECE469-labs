module controllertest();

logic CLK, Reset;
logic [5:0] OP, Funct;
logic Zero;
logic [3:0] state;
logic [2:0] ALUControl;
logic PCEn;
logic [15:0] control_word;//FSM control word
/*
logic memwrite, irwrite, regwrite;
logic alusrca, iord, memtoreg, regdst;
logic [1:0] alusrcb, pcsrc;
*/

controller dut(CLK, Reset, OP, Funct, Zero, PCEn, control_word[13],
		control_word[12], control_word[11], control_word[10], control_word[8], 
		control_word[7], control_word[6], control_word[5:4], control_word[3:2], ALUControl, state, control_word[14], 
		control_word[1:0], control_word[9]);
assign control_word[15] = 1'b0;
always begin
	CLK <= 1; #5;
	CLK <= 0; #5;
end

initial begin
	//add
	Reset = 1;Zero = 0;OP = 6'b000000; Funct = 6'b100000;#10;
	Reset = 0;#30;
	//sub
	Funct = 6'b100010;#40;
	//and
	Funct = 6'b100100;#40; 
	//or
	Funct = 6'b100101;#40;
	//slt
	Funct = 6'b101010;#40;
	//lw
	OP = 6'b100011;#50;
	//sw
	OP = 6'b101011;#40;
	//beq-taken
	OP = 6'b000100; Zero = 1;#30;
	//beq-nottaken
	OP = 6'b000100; Zero = 0;#30;
	//addi
	OP = 6'b001000;#40;
	//j
	OP = 6'b000010;#30;
end
endmodule
