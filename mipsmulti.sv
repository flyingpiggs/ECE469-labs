/*

  Instructions that we need to support

  add, sub, and, or, slt, lw, sw, beq, addi, j

  ** add **
  Operation:  $d = $s + $t; advance_pc (4);
  Syntax:     add $d, $s, $t
  Encoding:   0000 00ss ssst tttt dddd d000 0010 0000

  ** sub **
  Operation:  $d = $s - $t; advance_pc (4);
  Syntax:     sub $d, $s, $t
  Encoding:   0000 00ss ssst tttt dddd d000 0010 0010

  ** and **
  Operation:  $d = $s & $t; advance_pc (4);
  Syntax:     and $d, $s, $t
  Encoding:   0000 00ss ssst tttt dddd d000 0010 0100

  ** or **
  Operation:  $d = $s | $t; advance_pc (4);
  Syntax:     or $d, $s, $t
  Encoding:   0000 00ss ssst tttt dddd d000 0010 0101

  ** slt **
  Operation:  if $s < $t $d = 1; advance_pc (4); else $d = 0; advance_pc (4);
  Syntax:     slt $d, $s, $t
  Encoding:   0000 00ss ssst tttt dddd d000 0010 1010

  ** lw **
  Operation:  $t = MEM[$s + offset]; advance_pc (4);
  Syntax:     lw $t, offset($s)
  Encoding:   1000 11ss ssst tttt iiii iiii iiii iiii

  ** sw **
  Operation:  MEM[$s + offset] = $t; advance_pc (4);
  Syntax:     sw $t, offset($s)
  Encoding:   1010 11ss ssst tttt iiii iiii iiii iiii

  ** beq **
  Operation:  if $s == $t advance_pc (offset << 2)); else advance_pc (4);
  Syntax:     beq $s, $t, offset
  Encoding:   0001 00ss ssst tttt iiii iiii iiii iiii

  ** bne **
  Operation:  if $s != $t advance_pc (offset << 2)); else advance_pc (4);
  Syntax:     beq $s, $t, offset
  Encoding:   0001 01ss ssst tttt iiii iiii iiii iiii

  ** addi **
  Operation:  $t = $s + imm; advance_pc (4);
  Syntax:     addi $t, $s, imm
  Encoding:   0010 00ss ssst tttt iiii iiii iiii iiii

  ** ori **
  Operation:  $t = $s | imm; advance_pc (4);
  Syntax:     ori $t, $s, imm
  Encoding:   0011 01ss ssst tttt iiii iiii iiii iiii

  ** j **
  Operation:  PC = nPC; nPC = (PC & 0xf0000000) | (target << 2);
  Syntax:     j target
  Encoding:   0000 10ii iiii iiii iiii iiii iiii iiii

*/

module top(input logic clk, reset,
             output logic [31:0] writedata, adr,
             output logic        memwrite);
  logic [31:0] readdata;
  // microprocessor (control & datapath)
  mips mips(clk, reset, adr, writedata, memwrite, readdata);
  // memory
  mem mem(clk, memwrite, adr, writedata, readdata);
endmodule

module mem(input logic clk, we,
            input  logic [31:0] a, wd,
            output logic [31:0] rd);

  logic  [31:0] RAM[63:0];

  // initialize memory with instructions
  initial begin
    $readmemh("memfile.dat",RAM);
    /* "memfile.dat" contains your instructions in hex
        you must create this file */
  end

  assign rd = RAM[a[31:2]]; // word aligned

  always_ff @(posedge clk)
    if (we)
      RAM[a[31:2]] <= wd;
endmodule

module mips(input  logic        clk, reset,
             output logic [31:0] adr, writedata,
             output logic        memwrite,
             input  logic [31:0] readdata);

  logic        zero, pcen, irwrite, regwrite,
               alusrca, iord, memtoreg, regdst;
  logic [1:0]  alusrcb, pcsrc;
  logic [2:0]  alucontrol;
  logic [5:0]  op, funct;

  controller c(clk, reset, op, funct, zero,
               pcen, memwrite, irwrite, regwrite,
               alusrca, iord, memtoreg, regdst,
               alusrcb, pcsrc, alucontrol);//Will need to be changed since controller instantiations were changed
  datapath dp(clk, reset,
              pcen, irwrite, regwrite,
              alusrca, iord, memtoreg, regdst,
              alusrcb, pcsrc, alucontrol,
              op, funct, zero,
              adr, writedata, readdata);

endmodule

module controller(input  logic       clk, reset,
                  input  logic [5:0] op, funct,
                  input  logic       zero,
                  output logic       pcen, memwrite, irwrite, regwrite,
                  output logic       alusrca, iord, memtoreg, regdst,
                  output logic [1:0] alusrcb, pcsrc,
                  output logic [2:0] alucontrol);

  logic [1:0] aluop;
  logic       branch, pcwrite;
  logic branchAndZero;

  // Main Decoder and ALU Decoder subunits.
  maindec md(clk, reset, op, 
             pcwrite, memwrite, irwrite, regwrite,
             alusrca, branch, iord, memtoreg, regdst,
             alusrcb, pcsrc, aluop);
  aludec  ad(funct, aluop, alucontrol);

  assign branchAndZero = branch & zero;
  assign pcen = pcwrite | branchAndZero;

endmodule

module maindec(input  logic       clk, reset,
                input  logic [5:0] op,
                output logic       pcwrite, memwrite, irwrite, regwrite,
                output logic       alusrca, branch, iord, memtoreg, regdst,
                output logic [1:0] alusrcb, pcsrc,
                output logic [1:0] aluop);
  /* States */
  parameter   FETCH   = 4'b0000;      // State 0
  parameter   DECODE  = 4'b0001;      // State 1
  parameter   MEMADR  = 4'b0010;      // State 2
  parameter   MEMRD   = 4'b0011;      // State 3
  parameter   MEMWB   = 4'b0100;      // State 4
  parameter   MEMWR   = 4'b0101;      // State 5
  parameter   RTYPEEX = 4'b0110;      // State 6
  parameter   RTYPEWB = 4'b0111;      // State 7
  parameter   BEQEX   = 4'b1000;      // State 8
  parameter   ADDIEX  = 4'b1001;      // State 9
  parameter   ADDIWB  = 4'b1010;      // state 10
  parameter   JEX     = 4'b1011;      // State 11

  parameter   LW      = 6'b100011;    // Opcode for lw
  parameter   SW      = 6'b101011;    // Opcode for sw
  parameter   RTYPE   = 6'b000000;    // Opcode for R-type
  parameter   BEQ     = 6'b000100;    // Opcode for beq
  parameter   ADDI    = 6'b001000;    // Opcode for addi
  parameter   J       = 6'b000010;    // Opcode for j

  logic [3:0]  state, nextstate;
  logic [14:0] controls;

  // state register
  always_ff @(posedge clk or posedge reset)
    if(reset) state <= FETCH;
    else state <= nextstate;

  /* ADD CODE HERE */

  /* Finish entering the next state logic below.
     The first two states, FETCH and DECODE, have been completed for you. */

  /* next state logic */
  always_comb
    case(state)
      FETCH:   nextstate = DECODE;
      DECODE:
        case(op)
          LW:      nextstate = MEMADR;
          SW:      nextstate = MEMADR;
          RTYPE:   nextstate = RTYPEEX;
          BEQ:     nextstate = BEQEX;
          ADDI:    nextstate = ADDIEX;
          J:       nextstate = JEX;
          default: nextstate = 4'bx; // should never happen
       	endcase
  /* Add code here  */
      MEMADR:
        case(op)
          LW:       nextstate = MEMRD;
          SW:       nextstate = MEMWR;
          default:  nextstate = 4'bx;
        endcase
      MEMRD:        nextstate = MEMWB;
      MEMWB:        nextstate = FETCH;
      MEMWR:        nextstate = FETCH;
      RTYPEEX:      nextstate = RTYPEWB;
      RTYPEWB:      nextstate = FETCH;
      BEQEX:        nextstate = FETCH;
      ADDIEX:       nextstate = ADDIWB;
      ADDIWB:       nextstate = FETCH;
      JEX:          nextstate = FETCH;
      default:      nextstate = 4'bx; // should never happen
    endcase

  // output logic
  assign {pcwrite, memwrite, irwrite, regwrite,
           alusrca, branch, iord, memtoreg, regdst,
           alusrcb, pcsrc, aluop} = controls;
  /* ADD CODE HERE */
  /*
    Finish entering the output logic below.
    The output logic for the first two states, S0 and S1, have been completed for you.
  */
  always_comb
    case(state)
      FETCH:    controls = 15'h5010;
      DECODE:   controls = 15'h0030;
      /* your code goes here */
      //The following state controls come from our maindecoder table
      MEMADR:   controls = 15'h0420;
      MEMRD:    controls = 15'h0100;
      MEMWB:    controls = 15'h0880;
      MEMWR:    controls = 15'h2100;
      RTYPEEX:  controls = 15'h0402;
      RTYPEWB:  controls = 15'h0840;
      BEQEX:    controls = 15'h0605;
      ADDIEX:   controls = 15'h0420;
      ADDIWB:   controls = 15'h0800;
      JEX:      controls = 15'h4008;
      default:  controls = 15'hxxxx; // should never happen
    endcase
endmodule

module aludec(input  logic [5:0] funct,
               input  logic [1:0] aluop,
               output logic [2:0] alucontrol);


  always_comb
    case(aluop)
      2'b00: alucontrol = 3'b010;  // add
      2'b01: alucontrol = 3'b110;  // sub
      2'b11: alucontrol = 3'b001;  // ORI?
      default:
        case(funct)          // RTYPE
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


/*
  Complete the datapath module below.
  The datapath unit is a structural verilog module.  That is,
  it is composed of instances of its sub-modules.  For example,
  the instruction register is instantiated as a 32-bit flopenr.
  The other submodules are likewise instantiated.
*/
module datapath(input  logic        clk, reset,
                 input  logic        pcen, irwrite, regwrite,
                 input  logic        alusrca, iord, memtoreg, regdst,
                 input  logic [1:0]  alusrcb, pcsrc,
                 input  logic [2:0]  alucontrol,
                 output logic [5:0]  op, funct,
                 output logic        zero,
                 output logic [31:0] adr, writedata,
                 input  logic [31:0] readdata);

  // Below are the internal signals of the datapath module.
  logic [4:0]  writereg;
  logic [31:0] pcnext, pc;
  logic [31:0] instr, data, srca, srcb;
  logic [31:0] a;
  logic [31:0] aluresult, aluout;
  logic [31:0] signimm;   // the sign-extended immediate
  logic [31:0] signimmsh; // the sign-extended immediate shifted left by 2
  logic [31:0] wd3, rd1, rd2;   // op and funct fields to controller

  assign op = instr[31:26];
  assign funct = instr[5:0];

/*
  Your datapath hardware goes below.  Instantiate each of the submodules
  that you need.  Remember that alu's, mux's and various other
  versions of parameterizable modules are available in textbook 7.6
  Here, parameterizable 3:1 and 4:1 muxes are provided below for your use.
  Remember to give your instantiated modules applicable names
  such as pcreg (PC register), wdmux (Write Data Mux), etc.
  so it's easier to understand.
*/
  /* ADD DATAPATH CODE HERE */

endmodule

//Regfile provided in the textbook------------------------
module regfile(input logic clk,
input logic we3,
input logic [4:0] ra1, ra2, wa3,
input logic [31:0] wd3,
output logic [31:0] rd1, rd2);
logic [31:0] rf[31:0];
// three ported register file
// read two ports combinationally
// write third port on rising edge of clk
// register 0 hardwired to 0
// note: for pipelined processor, write third port
// on falling edge of clk
always_ff @(posedge clk)
if (we3) rf[wa3] <= wd3;
assign rd1 = (ra1 != 0) ? rf[ra1] : 0;
assign rd2 = (ra2 != 0) ? rf[ra2] : 0;
endmodule
//--------------------------------------------------------

//ALU Portion---------------------------------------------
module alu(input logic [31:0] a, b,
 input logic [2:0] f,
 output logic [31:0] y,
 output logic zero/*, OF*/);


	logic[31:0] Bn, BB, S, Sz, D0, D1, D2, D3, _y;
	logic Cout, slt;
	logic OF;
	logic[31:0] A, B, Y;
	assign A = a;
	assign B = b;
	assign Bn = ~B;
	logic [2:0] F;
	assign F = f;

	mux_2to1_32bit n0(B, Bn, F[2], BB);
	rc_adder_32bit n1(A, BB, F[2], S, OF, Cout);
	/*assign slt = OF ^ S[31];
	assign Sz = {31'b0, slt};//zero extends*/
	slt n2(OF, S[31], Sz);

	/*assign D0 = BB & A;
	assign D1 = BB | A;
	assign D2 = S;
	//assign D3 = Sz;*/
	values_for_D0to2 n3(A, BB, S, D0, D1, D2);

	//Pattern Matching
	//pm n4(A, B, _y);
	assign _y = A ^ B;


	mux_2to1_32bit n5(_y, Sz, F[2], D3);//mux to choose PM or SLT for D3 //it's really XOR instead of PM now

	mux_4to1_32bit n6(D0, D1, D2, D3, F[1:0], Y);
	assign y = Y;

	always_comb
	if(Y == 0)	zero = 1;
	else		zero = 0;




endmodule //alu

module values_for_D0to2(input logic [31:0] A, BB, S,
			output logic [31:0] D0, D1, D2);
	assign D0 = BB & A;
	assign D1 = BB | A;
	assign D2 = S;
endmodule //values_for_D0to2

module slt(input logic OF, S_msb,
		output logic [31:0] Sz);
	logic slt;
	assign slt = OF ^ S_msb;
	assign Sz = {31'b0, slt};//zero extends
endmodule //slt

module pm(input logic [31:0] A, B,
		output logic [31:0] y);
	assign y[31:22] = 0; //using small y
	find_match m0(A[31:16], B, y[16]);
	find_match m1(A[30:15], B, y[15]);
	find_match m2(A[29:14], B, y[14]);
	find_match m3(A[28:13], B, y[13]);
	find_match m4(A[27:12], B, y[12]);
	find_match m5(A[26:11], B, y[11]);
	find_match m6(A[25:10], B, y[10]);
	find_match m7(A[24:9], B, y[9]);
	find_match m8(A[23:8], B, y[8]);
	find_match m9(A[22:7], B, y[7]);
	find_match m10(A[21:6], B, y[6]);
	find_match m11(A[20:5], B, y[5]);
	find_match m12(A[19:4], B, y[4]);
	find_match m13(A[18:3], B, y[3]);
	find_match m14(A[17:2], B, y[2]);
	find_match m15(A[16:1], B, y[1]);
	find_match m16(A[15:0], B, y[0]);
	//number of matches, y[21:17]
	hammingWeight_17bits m17( y[16:0], y[21:17]);
endmodule //pm

module rc_adder_32bit(input logic[31:0] A, B,
			input logic Cin0,
			output logic[31:0] S,
			output logic OF, Cout);
	logic Cin8, Cin16, Cin24;
	logic notUsed1, notUsed2, notUsed3;
	rc_adder_8bit b0tob7(A[7:0], B[7:0],
				Cin0, S[7:0], notUsed1, Cin8);
	rc_adder_8bit b8tob15(A[15:8], B[15:8],
				Cin8, S[15:8], notUsed2, Cin16);

	rc_adder_8bit b16tob23(A[23:16], B[23:16],
				Cin16, S[23:16], notUsed3, Cin24);

	rc_adder_8bit b24tob31(A[31:24], B[31:24],
				Cin24, S[31:24], OF, Cout);
endmodule //rc_adder_32bit

module hammingWeight_17bits( input logic[16:0] Y,
				output logic[4:0] count);
	logic[2:0] lvl_1_sum1, lvl_1_sum2, lvl_1_sum3, lvl_1_sum4, lvl_1_sum5, lvl_1_sum6;
	logic[3:0] lvl2_sum1, lvl2_sum2;
	logic[4:0] lvl3_sum1, lvl3_sum2;
	logic notUsed1, notUsed2, notUsed3, notUsed4, notUsed5;
	logic notUsed6, notUsed7, notUsed8, notUsed9, notUsed10;
	logic notUsed11, notUsed12, notUsed13, notUsed14, notUsed15;

	//level 1
	full_adder b0to2 ( Y[0], Y[1], Y[2],
			lvl_1_sum1[0], lvl_1_sum1[1]);
	full_adder b3to5 ( Y[3], Y[4], Y[5],
			lvl_1_sum2[0], lvl_1_sum2[1]);
	full_adder b6to7 ( Y[6], Y[7], Y[8],
			lvl_1_sum3[0], lvl_1_sum3[1]);
	full_adder b8to10 ( Y[9], Y[10], Y[11],
			lvl_1_sum4[0], lvl_1_sum4[1]);
	full_adder b11to13 ( Y[12], Y[13], Y[14],
			lvl_1_sum5[0], lvl_1_sum5[1]);
	full_adder b14to16 ( Y[15], Y[16], 0,
			lvl_1_sum6[0], lvl_1_sum6[1]);

	assign lvl_1_sum1[2] = 0;
	assign lvl_1_sum2[2] = 0;
	assign lvl_1_sum3[2] = 0;
	assign lvl_1_sum4[2] = 0;
	assign lvl_1_sum5[2] = 0;
	assign lvl_1_sum6[2] = 0;
	//level 2, Y[12:16] should output a 4 bit result, but since there
	//isn't another sum to pair with it at level 3, the results are
	//put directly into the 5 bit result

	rc_adder_3bit b0to5( lvl_1_sum1, lvl_1_sum2, 0, lvl2_sum1[2:0], notUsed1, notUsed2 );
	rc_adder_3bit b6to11( lvl_1_sum3, lvl_1_sum4, 0, lvl2_sum2[2:0], notUsed3, notUsed4 );
	rc_adder_3bit b12to16( lvl_1_sum5, lvl_1_sum6, 0, lvl3_sum2[2:0], notUsed5, notUsed6 );

	assign lvl2_sum1[3] = 0;
	assign lvl2_sum2[3] = 0;
	assign lvl3_sum2[3] = 0;
	//level 3

	rc_adder_4bit b0to11( lvl2_sum1, lvl2_sum2, 0, lvl3_sum1, notUsed7, notUsed8 );

	//final output
	assign lvl3_sum1[4] = 0;
	assign lvl3_sum2[4] = 0;
	rc_adder_5bit b0to16(lvl3_sum1, lvl3_sum2, 0, count, notUsed9, notUsed10);

endmodule //hammingWeight_17bits

module rc_adder_8bit(input logic[7:0] A, B,
			input logic Cin0,
			output logic[7:0] S,
			output logic OF, Cout);
	logic Cin1, Cin2, Cin3, Cin4;
	logic Cin5, Cin6, Cin7;
	full_adder b0( A[0], B[0], Cin0,
			S[0], Cin1 );
	full_adder b1( A[1], B[1], Cin1,
			S[1], Cin2 );
	full_adder b2( A[2], B[2], Cin2,
			S[2], Cin3 );
	full_adder b3( A[3], B[3], Cin3,
			S[3], Cin4 );
	full_adder b4( A[4], B[4], Cin4,
			S[4], Cin5 );
	full_adder b5( A[5], B[5], Cin5,
			S[5], Cin6 );
	full_adder b6( A[6], B[6], Cin6,
			S[6], Cin7 );
	full_adder b7( A[7], B[7], Cin7,
			S[7], Cout );
	assign OF = Cin7 ^ Cout;
endmodule //rc_adder_8bit

module rc_adder_5bit(input logic[4:0] A, B,
			input logic Cin0,
			output logic[4:0] S,
			output logic OF, Cout);
	logic Cin1, Cin2, Cin3, Cin4;
	full_adder b0( A[0], B[0], Cin0,
			S[0], Cin1 );
	full_adder b1( A[1], B[1], Cin1,
			S[1], Cin2 );
	full_adder b2( A[2], B[2], Cin2,
			S[2], Cin3 );
	full_adder b3( A[3], B[3], Cin3,
			S[3], Cin4 );
	full_adder b4( A[4], B[4], Cin4,
			S[4], Cout );
endmodule //rc_adder_5bit

module rc_adder_4bit(input logic[3:0] A, B,
			input logic Cin0,
			output logic[3:0] S,
			output logic OF, Cout);
	logic Cin1, Cin2, Cin3;
	full_adder b0( A[0], B[0], Cin0,
			S[0], Cin1 );
	full_adder b1( A[1], B[1], Cin1,
			S[1], Cin2 );
	full_adder b2( A[2], B[2], Cin2,
			S[2], Cin3 );
	full_adder b3( 0, 0, Cin3,
			S[3], Cout );

endmodule //rc_adder_4bit

module rc_adder_3bit(input logic[2:0] A, B,
			input logic Cin0,
			output logic[2:0] S,
			output logic OF, Cout);
	logic Cin1, Cin2;
	full_adder b0( A[0], B[0], Cin0,
			S[0], Cin1 );
	full_adder b1( A[1], B[1], Cin1,
			S[1], Cin2 );
	full_adder b2( A[2], B[2], Cin2,
			S[2], Cout );
endmodule //rc_adder_3bit

module full_adder(
		input logic A, B, Cin,
		output logic S, Cout);
	assign S = A ^ B ^ Cin;
	assign Cout = A & B | Cin & A | Cin & B;
endmodule //full_adder

module mux_4to1_32bit(input logic[31:0] D0, D1, D2, D3,
			input logic[1:0] signal,
			output logic[31:0] Q);
	always_comb
	case (signal)
		2'b00: Q = D0;
		2'b01: Q = D1;
		2'b10: Q = D2;
		2'b11: Q = D3;
	endcase
endmodule //mux_4to1_32bit

module mux_2to1_32bit(
	input logic[31:0] B, Bn,
	input logic F,
	output logic[31:0] BB);

	always_comb
	case(F)
		1'b0:	BB = B;
		1'b1:	BB = Bn;
	endcase
endmodule //mux_2to1_32bit

module find_match(
	input [15:0] A,
	input [31:0] B,
	output Y);

	logic a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15;

	assign a0 = (A[15] ~^ B[15]) | B[31];
	assign a1 = (A[14] ~^ B[14]) | B[30];
	assign a2 = (A[13] ~^ B[13]) | B[29];
	assign a3 = (A[12] ~^ B[12]) | B[28];
	assign a4 = (A[11] ~^ B[11]) | B[27];
	assign a5 = (A[10] ~^ B[10]) | B[26];
	assign a6 = (A[9] ~^ B[9]) | B[25];
	assign a7 = (A[8] ~^ B[8]) | B[24];
	assign a8 = (A[7] ~^ B[7]) | B[23];
	assign a9 = (A[6] ~^ B[6]) | B[22];
	assign a10 = (A[5] ~^ B[5]) | B[21];
	assign a11 = (A[4] ~^ B[4]) | B[20];
	assign a12 = (A[3] ~^ B[3]) | B[19];
	assign a13 = (A[2] ~^ B[2]) | B[18];
	assign a14 = (A[1] ~^ B[1]) | B[17];
	assign a15 = (A[0] ~^ B[0]) | B[16];

	assign Y = a0 & a1 & a2 & a3 & a4 & a5 & a6 & a7 & a8 & a9 & a10 & a11 & a12 & a13 & a14 & a15;
endmodule //find_match
//--------------------------------------------------------

module mux3 #(parameter WIDTH = 8)
              (input  logic [WIDTH-1:0] d0, d1, d2,
               input  logic [1:0]       s,
               output logic [WIDTH-1:0] y);

   assign #1 y = s[1] ? d2 : (s[0] ? d1 : d0);
endmodule

module mux4 #(parameter WIDTH = 8)
              (input  logic [WIDTH-1:0] d0, d1, d2, d3,
               input  logic [1:0]       s,
               output logic [WIDTH-1:0] y);
    always_comb
       case(s)
          2'b00: y = d0;
          2'b01: y = d1;
          2'b10: y = d2;
          2'b11: y = d3;
       endcase
 endmodule
