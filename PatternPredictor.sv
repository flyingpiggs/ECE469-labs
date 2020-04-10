module PatternPredictor( input logic clk, reset, 
			 input logic X, //X is the current input from the pattern
			output logic[7:0] X_cnt, //How many inputs seen from X
			output logic Y, //prediction
			output logic Y_match, //if current Y is a match w/ X
			output logic[7:0] Y_cnt, //number of Y matches so far
			output logic Z, //prediction from given predictor
			output logic Z_match, //if current Z is match w/ X
			output logic[7:0] Z_cnt //number of Z matches so far );

  pattern_predictor_2bit Z_predictor( clk, reset, X, Z); 

endmodule 
