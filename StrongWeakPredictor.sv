module pattern_predictor_2bit ( input logic clk, reset, actual_pattern,
				output logic predicted_pattern);

typedef enum logic [1:0] { Strong_0, Weak_0, Weak_1, Strong_1 } statetype; 

statetype state, nextstate;

//state register
always_ff @(posedge clk, posedge reset)
  if (reset) state <= Weak_0;
  else 	state <= nextstate;

// next state logic
always_comb
  case(state)
    Strong_0: if( actual_pattern == 1 ) nextstate = Weak_0; 
		else 	nextstate = Strong_0;
    Weak_0: if( actual_pattern == 1 ) nextstate = Weak_1; 
		else 	nextstate = Strong_0;
    Weak_1: if( actual_pattern == 1 ) nextstate = Strong_1; 
		else 	nextstate = Weak_0;
    Strong_1: if( actual_pattern == 1 ) nextstate = Strong_1; 
		else 	nextstate = Weak_1;
    default: nextstate = Weak_0; 	
  endcase

//output logic
  assign predicted_pattern = ( ( state == Strong_1 ) || ( state == Weak_1 ) );

endmodule
