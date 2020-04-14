module PatternPredictor( input logic clk, reset, 
			 input logic X, //X is the current input from the pattern
			output logic[7:0] X_cnt, //How many inputs seen from X
			output logic Y, //prediction for current cycle
			output logic Y_match, //if current Y is a match w/ X
			output logic[7:0] Y_cnt, //number of Y matches so far
			output logic Z, //prediction from given predictor for current cycle
			output logic Z_match, //if current Z is match w/ X
			output logic[7:0] Z_cnt );//number of Z matches so far

  logic predictY, predictZ; 

  pattern_predictor_2bit Z_predictor( clk, reset, X, predictZ ); 
  pattern_predictor_3bit Y_predictor( clk, reset, X, predictY );

  always_ff @ (posedge clk, posedge reset) begin
		Z_match <= ( predictZ == X );
		Y_match <= ( predictY == X );
		Z <= predictZ;
		Y <= predictY;
		if(reset) begin
			X_cnt <= 0;
			if(predictY == X)	Y_cnt <= 1;
			else			Y_cnt <= 0;
			if(predictZ == X)	Z_cnt <= 1;
			else			Z_cnt <= 0;
			end
		else begin
			X_cnt <= X_cnt + 1;
			if(predictY == X)	Y_cnt <= Y_cnt + 1;
			else		Y_cnt <= Y_cnt;
			if(predictZ == X)	Z_cnt <= Z_cnt + 1;
			else		Z_cnt <= Z_cnt;
			end
	end
endmodule 

module pattern_predictor_3bit( input logic clk, reset,
				input logic X,
				output logic forNextCycle );

typedef enum logic [2:0] { P1_1, P1_2, P1_3, P1_4, P0_1, P0_2, P0_3, P0_4 } StateType;
StateType state, nextState; 

always_ff @( posedge clk, posedge reset)
    if (reset) state <= P1_1; 
    else state <= nextState; 

//state logic
always_comb
  case ( state )
    P1_1: 
      if ( X == 1 ) nextState = P1_2; 
      else nextState = P0_2;
    P1_2: 
      if ( X == 1 ) nextState = P1_3; 
      else nextState = P0_2;
    P1_3: 
      if ( X == 1 ) nextState = P1_4; 
      else nextState = P0_2;
    P1_4: 
      if ( X == 1 ) nextState = P1_1; 
      else nextState = P0_2;
    P0_1: 
      if ( X == 0 ) nextState = P0_2; 
      else nextState = P1_2;
    P0_2: 
      if ( X == 0 ) nextState = P0_3; 
      else nextState = P1_2;
    P0_3: 
      if ( X == 0 ) nextState = P0_4; 
      else nextState = P1_2;
    P0_4: 
      if ( X == 0 ) nextState = P0_1; 
      else nextState = P1_2;
    default:
        nextState = P1_1; 
  endcase 

//output logic
assign forNextCycle = ( ( state == P1_1 ) || ( state == P1_2 ) || ( state == P1_3 ) || ( state == P1_4 ) ); 

endmodule 

/*module PatPredData ();

endmodule */
