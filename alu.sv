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

/*module rc_adder_8bit(input logic[7:0] A, B,
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
endmodule //rc_adder_8bit*/

//---------------------------------------------------
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

//---------------------------------------------------

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
