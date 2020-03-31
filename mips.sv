// files needed for simulation:
//  mipsttest.sv   mipstop.sv, mipsmem.sv,  mips.sv,  mipsparts.sv

// single-cycle MIPS processor
module mips(input  logic        clk, reset,
            output logic [31:0] pc,
            input  logic [31:0] instr,
            output logic        memwrite,
            output logic [31:0] aluout, writedata,
            input  logic [31:0] readdata);

  logic        memtoreg, branch,
               pcsrc, zero,
               alusrc, regdst, regwrite, jump;
  logic [2:0]  alucontrol;

  /* new variables we declared */
  logic [1:0] aluExtControl; //gets its value from controller and used in datapath 
  // added the new variable from above 
  controller c(instr[31:26], instr[5:0], zero,
               memtoreg, memwrite, pcsrc,
               alusrc, regdst, regwrite, jump,
               alucontrol, aluExtControl);
  // added the variable mentioned above 
  datapath dp(clk, reset, memtoreg, pcsrc,
              alusrc, regdst, regwrite, jump,
              alucontrol, aluExtControl,
              zero, pc, instr,
              aluout, writedata, readdata);
endmodule

module controller(input  logic [5:0] op, funct,
                  input  logic       zero,
                  output logic       memtoreg, memwrite,
                  output logic       pcsrc, alusrc,
                  output logic       regdst, regwrite,
                  output logic       jump,
                  output logic [2:0] alucontrol,
		/* New output variables we added */
		  output logic [1:0] aluExtControl);

  logic [1:0] aluop;
  logic       branch;

  /* New variable declaration and definition for the branch not equal instruction */
  logic bne;
  assign bne = ( op == 6'b000101 ) ? 1 : 0; 

  /* New code that sets aluExtControl*/ 
  always_comb begin
    if ( op == 6'b001111 ) //lui
      aluExtControl = 2'b10;
    else if ( op == 6'b000000 ) begin //sll and sltu are both r-types
        if ( funct == 6'b000000 ) //sll
          aluExtControl = 2'b11;
        else if ( funct == 6'b101011 ) //sltu
          aluExtControl = 2'b01;
        else //any other r-type, which we didn't add support for in part C
          aluExtControl = 2'b00; 
      end
    else /*this means it's an i-type or j-type instruction; lui is the only i-type instruction we added support for in part C */
      aluExtControl = 2'b00;    
  end

  maindec md(op, memtoreg, memwrite, branch,
             alusrc, regdst, regwrite, jump,
             aluop);
  aludec  ad(funct, aluop, alucontrol);

  /* Here's where we invert zero based on whether or not the instruction is BNE or BEQ 
     We'll use an intermediate variable to hold the value, and also change the assignment
     statement for pcsrc so that things work properly. 
  */
  logic zeroNot;
  assign zeroNot = ~zero;
  logic branchCondMet;
  assign branchCondMet = ( bne ) ? zeroNot : zero;  
  
  assign pcsrc = branch & branchCondMet;  //We changed the zero of the sample code to the new variable we declared
endmodule

module maindec(input  logic [5:0] op,
               output logic       memtoreg, memwrite,
               output logic       branch, alusrc,
               output logic       regdst, regwrite,
               output logic       jump,
               output logic [1:0] aluop);

  logic [8:0] controls;

  assign {regwrite, regdst, alusrc,
          branch, memwrite,
          memtoreg, jump, aluop} = controls;

  always_comb
    case(op)
      6'b000000: controls = 9'b110000010; //Rtype
      6'b100011: controls = 9'b101001000; //LW
      6'b101011: controls = 9'b001010000; //SW
      6'b000100: controls = 9'b000100001; //BEQ
      6'b001000: controls = 9'b101000000; //ADDI
      6'b000010: controls = 9'b000000100; //J
      6'b001101: controls = 9'b101000011; //ORI
      6'b001111: controls = 9'b100000000; /*LUI, aluop is don't care, but I'm making it 00 so it'll default to add in alu (adder result is discarded) */
					/* alusrc is also don't care now, but making it 0 for reasons */
      default:   controls = 9'bxxxxxxxxx; //???
    endcase
endmodule

//this module will not be relevant for the SLTU, LUI, and SLL instructions
module aludec(input  logic [5:0] funct,
              input  logic [1:0] aluop,
              output logic [2:0] alucontrol);

  always_comb
    case(aluop)
      2'b00: alucontrol = 3'b010;  // add
      2'b01: alucontrol = 3'b110;  // sub
      2'b11: alucontrol = 3'b001;  // ORI? 
      default: case(funct)          // RTYPE
          6'b100000: alucontrol = 3'b010; // ADD
          6'b100010: alucontrol = 3'b110; // SUB
          6'b100100: alucontrol = 3'b000; // AND
          6'b100101: alucontrol = 3'b001; // OR
          6'b101010: alucontrol = 3'b111; // SLT
	  6'b101011: alucontrol = 3'b000; // SLTU, same comment as for SLL
	  6'b100110: alucontrol = 3'b011; // XOR
	  6'b000000: alucontrol = 3'b000; // SLL, it's really 3'bxxx, but I didn't want it to conflict with the default 
          default:   alucontrol = 3'bxxx; // ???
        endcase
    endcase
endmodule

module datapath(input  logic        clk, reset,
                input  logic        memtoreg, pcsrc,
                input  logic        alusrc, regdst,
                input  logic        regwrite, jump,
                input  logic [2:0]  alucontrol,
		input logic [1:0] aluExtCtrl, /* This new variable is used to control the 4-to-1 mux mentioned in the notes */
		//might need to make the variables below internal
		//input logic [31:0] sltu, lui, sll; /* results of the new modules defined later; they'll be computed in the main mips module */
                output logic        zero,
                output logic [31:0] pc,
                input  logic [31:0] instr,
                output logic [31:0] aluout, writedata,
                input  logic [31:0] readdata);

  logic [4:0]  writereg;
  logic [31:0] pcnext, pcnextbr, pcplus4, pcbranch;
  logic [31:0] signimm, signimmsh;
  logic [31:0] srca, srcb;
  logic [31:0] result;
  /*new variables we declared */
  logic [31:0] upperMuxOut, lowerMuxOut; //used for the 4-to-1 mux as intermediates
  logic [31:0] sltu, lui, sll; /* results of the new modules defined later; they'll be computed using the new modules */
  logic [31:0] zeroExtImm, extImm; /* used to get the correct imm value with proper extension */ 
  logic [31:0] aluExt; 
  /* aluExt is basically the output of the mux mentioned in the comments after this module */

  // next PC logic
  flopr #(32) pcreg(clk, reset, pcnext, pc);
  adder       pcadd1(pc, 32'b100, pcplus4);
  sl2         immsh(signimm, signimmsh);
  adder       pcadd2(pcplus4, signimmsh, pcbranch);
  mux2 #(32)  pcbrmux(pcplus4, pcbranch, pcsrc, pcnextbr);
  mux2 #(32)  pcmux(pcnextbr, {pcplus4[31:28], instr[25:0], 2'b00}, 
                    jump, pcnext);

  // register file logic
  regfile     rf(clk, regwrite, instr[25:21],
                 instr[20:16], writereg,
                 result, srca, writedata);
  mux2 #(5)   wrmux(instr[20:16], instr[15:11], regdst, writereg);
  //This mux below had its first parameter changed from the sample code
  mux2 #(32)  resmux(/*aluout*/aluExt, readdata, memtoreg, result);
  signext     se(instr[15:0], signimm);

  /* New Code here to get imm with zero extension for ORI */
  assign zeroExtImm = { 16'b0, instr[15:0] };
  assign extImm = ( instr[31:26] == 6'b001101 ) ? zeroExtImm : signimm; 

  // ALU logic
  /* replaced code in the mux below */
  mux2 #(32)  srcbmux(writedata, extImm/*signimm*/, alusrc, srcb);
  alu         alu(.a(srca), .b(srcb), .f(alucontrol), .y(aluout), .zero(zero));
  /* New code that uses the new modules defined after this */ 
  magComparator SLTU(srca, srcb, sltu );
  loadUpImm LUI(instr[15:0], lui);
  leftShifter SLL( srcb, instr[10:6], sll );  
  /* 
    New code we added for aluExt, which is just a 4-to-1 mux in the data path
    The syntax that we've chosen means that 
      - 00 is all the previous instructions plus xor
      - 01 is sltu
      - 10 is lui
      - 11 is sll 
  */
  assign upperMuxOut = aluExtCtrl[0] ? sltu : aluout;
  assign lowerMuxOut = aluExtCtrl[0] ? sll : lui; //here
  assign aluExt = aluExtCtrl[1] ? lowerMuxOut : upperMuxOut; 
   
endmodule

/* Notes for changes in the data path module:

  The XOR instruction was just added to old ALU, and it just uses the old data path of 
  R-type instructions. The only change is that now it generates signal for alucontrol 
  that is different from the others. 

  For the other three instructions of part C, it's less work to just make them their 
  own modules and control the signal at a 4-to-1 mux for what aluout is in the sample code. 
  This entails sending the old aluout to a mux along with the outputs of the new instructions,
  and replacing aluout with the output of this mux.
    - For the mux's control signal, it'll specifically allow the new instructions when they're
      needed, but otherwise, let the old instructions through (basically, easier case statements).
    - This mux's control signal will come from the controller

*/

/*
  This module is for sltu; it's basically a magnitude comparsion which is done
  by using a priority encoder to determine which bit differs first. 
  * The inputs are the contents of two registers
  * The output is that assuming the registers are unsigned integers
	- result = 1; when a  is less than b
	- result = 0; when a is greater than or equal to b
	- result is kept to be 32 bits even though it's just one bit 
	  to maintain data path structure
*/
module magComparator(input logic [31:0] a, b,
			output logic [31:0] result); 
  logic[4:0] index; //tells us which index a and b differ first at, starting at MSB
  logic isEqual; //being used as the control signal of a mux
  logic valueAtIndex, valueAtIndexNot; 
  logic[31:0] diffBits;

  assign diffBits = a ^ b; 
   
  priorityEncoder_32to5 getIndex( diffBits, index, isEqual ); 
  
  always_comb begin
    if ( isEqual ) 	result = 0; 
    else begin
      case( index )
        5'b00000: 	result = {31'b0, ~a[0]};
        5'b00001: 	result = {31'b0, ~a[1]};
        5'b00010: 	result = {31'b0, ~a[2]};
        5'b00011: 	result = {31'b0, ~a[3]};
        5'b00100: 	result = {31'b0, ~a[4]};
        5'b00101: 	result = {31'b0, ~a[5]};
        5'b00110: 	result = {31'b0, ~a[6]};
        5'b00111: 	result = {31'b0, ~a[7]};
        5'b01000: 	result = {31'b0, ~a[8]};
        5'b01001: 	result = {31'b0, ~a[9]};
        5'b01010: 	result = {31'b0, ~a[10]};
        5'b01011: 	result = {31'b0, ~a[11]};
        5'b01100: 	result = {31'b0, ~a[12]};
        5'b01101: 	result = {31'b0, ~a[13]};
        5'b01110: 	result = {31'b0, ~a[14]};
        5'b01111: 	result = {31'b0, ~a[15]};
        5'b10000: 	result = {31'b0, ~a[16]};
        5'b10001: 	result = {31'b0, ~a[17]};
        5'b10010: 	result = {31'b0, ~a[18]};
        5'b10011: 	result = {31'b0, ~a[19]};
        5'b10100: 	result = {31'b0, ~a[20]};
        5'b10101: 	result = {31'b0, ~a[21]};
        5'b10110: 	result = {31'b0, ~a[22]};
        5'b10111: 	result = {31'b0, ~a[23]};
        5'b11000: 	result = {31'b0, ~a[24]};
        5'b11001: 	result = {31'b0, ~a[25]};
        5'b11010: 	result = {31'b0, ~a[26]};
        5'b11011: 	result = {31'b0, ~a[27]};
        5'b11100: 	result = {31'b0, ~a[28]};
        5'b11101: 	result = {31'b0, ~a[29]};
        5'b11110: 	result = {31'b0, ~a[30]};
        5'b11111: 	result = {31'b0, ~a[31]};
      endcase 
    end 
  end 

endmodule

module priorityEncoder_32to5( input logic[31:0] A,
				output logic[4:0] Y,
				output logic isEqual);
  //this block starts the priority encoder portion
  always_comb begin
    if (A[31]) begin
      Y = 5'b11111;
      isEqual = 0; 
      end
    else if (A[30]) begin
      Y = 5'b11110;
      isEqual = 0; 
      end
    else if (A[29]) begin
      Y = 5'b11101;
      isEqual = 0; 
      end
    else if (A[28]) begin
      Y = 5'b11100;
      isEqual = 0; 
      end
    else if (A[27]) begin
      Y = 5'b11011;
      isEqual = 0; 
      end
    else if (A[26]) begin
      Y = 5'b11010;
      isEqual = 0; 
      end
    else if (A[25]) begin
      Y = 5'b11001;
      isEqual = 0; 
      end
    else if (A[24]) begin
      Y = 5'b11000;
      isEqual = 0; 
      end
    else if (A[23]) begin
      Y = 5'b10111;
      isEqual = 0; 
      end
    else if (A[22]) begin
      Y = 5'b10110;
      isEqual = 0; 
      end
    else if (A[21]) begin
      Y = 5'b10101;
      isEqual = 0; 
      end
    else if (A[20]) begin
      Y = 5'b10100;
      isEqual = 0; 
      end
    else if (A[19]) begin
      Y = 5'b10011;
      isEqual = 0; 
      end
    else if (A[18]) begin
      Y = 5'b10010;
      isEqual = 0; 
      end
    else if (A[17]) begin
      Y = 5'b10001;
      isEqual = 0; 
      end
    else if (A[16]) begin
      Y = 5'b10000;
      isEqual = 0; 
      end
    else if (A[15]) begin
      Y = 5'b01111;
      isEqual = 0; 
      end
    else if (A[14]) begin
      Y = 5'b01110;
      isEqual = 0; 
      end
    else if (A[13]) begin
      Y = 5'b01101;
      isEqual = 0; 
      end
    else if (A[12]) begin
      Y = 5'b01100;
      isEqual = 0; 
      end
    else if (A[11]) begin
      Y = 5'b01011;
      isEqual = 0; 
      end
    else if (A[10]) begin
      Y = 5'b01010;
      isEqual = 0; 
      end
    else if (A[9]) begin
      Y = 5'b01001;
      isEqual = 0; 
      end
    else if (A[8]) begin
      Y = 5'b01000;
      isEqual = 0; 
      end
    else if (A[7]) begin
      Y = 5'b00111;
      isEqual = 0; 
      end
    else if (A[6]) begin
      Y = 5'b00110;
      isEqual = 0; 
      end
    else if (A[5]) begin
      Y = 5'b00101;
      isEqual = 0; 
      end
    else if (A[4]) begin
      Y = 5'b00100;
      isEqual = 0; 
      end
    else if (A[3]) begin
      Y = 5'b00011;
      isEqual = 0; 
      end
    else if (A[2]) begin
      Y = 5'b00010;
      isEqual = 0; 
      end
    else if (A[1]) begin
      Y = 5'b00001;
      isEqual = 0; 
      end
    else if (A[0]) begin
      Y = 5'b00000;
      isEqual = 0; 
      end
    else  begin
      Y = 5'b00000; //doesn't really matter, it's really 5bxxxxx
      isEqual = 1; 
      end
  end
  //end of the priority encoder
endmodule

/*
  This module is used for sll. It takes whatever is in reg_t, 
  shifts the value by <shift> number of bits, and stores the 
  result in reg_d.
    - Zeroes are shifted in

  Inputs:
  * reg_t, the value to be shifted
  * shift, the unsigned number of bits for the value to be shifted
  
  Outputs: 
  * reg_d, where the shifted value is stored 
*/

module leftShifter(input logic[31:0] reg_t,
			input logic[4:0] shift,
			output logic[31:0] reg_d);
  /* shifting to the left means that the input value is trimmed at MSB */
  always_comb begin 
    case( shift ) 
      5'b00000: 	reg_d = reg_t; 
      5'b00001: 	reg_d = { reg_t[30:0], 1'b0 };
      5'b00010: 	reg_d = { reg_t[29:0], 2'b0 };
      5'b00011: 	reg_d = { reg_t[28:0], 3'b0 };
      5'b00100: 	reg_d = { reg_t[27:0], 4'b0 };
      5'b00101: 	reg_d = { reg_t[26:0], 5'b0 };
      5'b00110: 	reg_d = { reg_t[25:0], 6'b0 };
      5'b00111: 	reg_d = { reg_t[24:0], 7'b0 };
      5'b01000: 	reg_d = { reg_t[23:0], 8'b0 };
      5'b01001: 	reg_d = { reg_t[22:0], 9'b0 };
      5'b01010: 	reg_d = { reg_t[21:0], 10'b0 };
      5'b01011: 	reg_d = { reg_t[20:0], 11'b0 };
      5'b01100: 	reg_d = { reg_t[19:0], 12'b0 };
      5'b01101: 	reg_d = { reg_t[18:0], 13'b0 };
      5'b01110: 	reg_d = { reg_t[17:0], 14'b0 };
      5'b01111: 	reg_d = { reg_t[16:0], 15'b0 }; 
      5'b10000: 	reg_d = { reg_t[15:0], 16'b0 };
      5'b10001: 	reg_d = { reg_t[14:0], 17'b0 };
      5'b10010: 	reg_d = { reg_t[13:0], 18'b0 };
      5'b10011: 	reg_d = { reg_t[12:0], 19'b0 };
      5'b10100: 	reg_d = { reg_t[11:0], 20'b0 };
      5'b10101: 	reg_d = { reg_t[10:0], 21'b0 };
      5'b10110: 	reg_d = { reg_t[9:0], 22'b0 };
      5'b10111: 	reg_d = { reg_t[8:0], 23'b0 };
      5'b11000: 	reg_d = { reg_t[7:0], 24'b0 };
      5'b11001: 	reg_d = { reg_t[6:0], 25'b0 };
      5'b11010: 	reg_d = { reg_t[5:0], 26'b0 };
      5'b11011: 	reg_d = { reg_t[4:0], 27'b0 };
      5'b11100: 	reg_d = { reg_t[3:0], 28'b0 };
      5'b11101: 	reg_d = { reg_t[2:0], 29'b0 };
      5'b11110: 	reg_d = { reg_t[1:0], 30'b0 };
      5'b11111: 	reg_d = { reg_t[0], 31'b0 };
    endcase
  end

endmodule

/*
  This module is used for lui, which stands for load upper immediate.
  It takes the value indicates by <imm>, then shifts it 16 bits, and
  stores the value in register_t. 
  
  Inputs: 
  * imm, 16 bits, the value to be shifted to the left by 16 bits
  Output:
  * reg_t, 32 bits, where the shifted value is stored
*/

module loadUpImm(input logic[15:0] imm,
		output logic[31:0] reg_t);
  assign reg_t = { imm, 16'b0 }; 
endmodule
