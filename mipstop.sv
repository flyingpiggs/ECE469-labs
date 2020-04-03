//------------------------------------------------
// Top level system including MIPS and memories
//------------------------------------------------

/*module top(input  logic       clk, reset, 
           output logic [31:0] writedata, dataadr, 
           output logic       memwrite);*/

module top(input  logic        clk, reset,
            output logic [31:0] pc,
            output logic [31:0] instr,
            output logic        memwrite,
            output logic [31:0] aluout, aluExt,/*------------------ADDED ALUEXT*/
	    output logic [31:0] writedata,
            output logic [31:0] readdata);

  logic [31:0] Pc, Instr, Readdata, Aluout;
  
  // instantiate processor and memories

  mips mips(clk, reset, Pc, Instr, memwrite, Aluout, /*dataadr,*/ writedata, aluExt, Readdata);/*------------------------ADDED ALUEXT*/

  imem imem(Pc[7:2], Instr);

  dmem dmem(clk, memwrite, Aluout, /*dataadr,*/ writedata, Readdata);

  assign pc = Pc;
  assign instr = Instr;
  assign readdata = Readdata;
  assign aluout = Aluout;
endmodule
