///----------------------------------------------------------------------------
// Title         : Mu-Law Decoder
// Project       : 
//-----------------------------------------------------------------------------
// File          : mulaw_dec.sv
//-----------------------------------------------------------------------------
// Description :
//
//  Generic Mu-law decoder.
//  It is generated with its .pkg file.
//
//  It is possible to have standard ITU-G77 or any type of customization.
//
//-----------------------------------------------------------------------------
// Copyright (c) 2022
//-----------------------------------------------------------------------------

module mulaw_dec import parameter_mulaw_pkg::*; #(
	 parameter mu_law_t cfg_t = parameter_mu_law_g711_t	
)
(
     input wire                          i_clk
	,input wire [cfg_t.P_ENCODED_DW-1:0] i_dt
	,input wire			                 i_enable
	,output logic    [cfg_t.P_DECODED_DW-1:0] o_dt
	,output logic 			                 o_enable	
);

  import mulaw_pkg::*;
  
  localparam MU_LAW_DELAY = 10;
  localparam P_NUM_CHORD_LOG  = $clog2(cfg_t.P_NUM_CHORD);
    
 `ifndef SV_ASSERTION_OFF 
  // synopsys translate_off
	generate
		if ( cfg_t.P_ASSERT_DISABLE=="ON" ) begin
			if ( cfg_t.P_DECODED_DW < ( cfg_t.P_SIGN + cfg_t.P_NUM_CHORD + cfg_t.P_DATA_GOOD ) )
				$error("** Wrong parameter configuration [decoding]");
			if ( cfg_t.P_ENCODED_DW != ( cfg_t.P_SIGN + P_NUM_CHORD_LOG + cfg_t.P_DATA_GOOD ) )
				$error("** Wrong parameter configuration [encoding]");								
		end	
	endgenerate
  // synopsys translate_on 
 `endif //SV_ASSERTION_OFF
 
 		 localparam ST                  = cfg_t.P_DECODED_DW; 
		 localparam S                   = cfg_t.P_SIGN; 	
		 localparam T                   = ST - S;	 
		 localparam C                   = cfg_t.P_NUM_CHORD;
		 localparam C_L                 = $clog2(C);		     
	         localparam FILL                = T - C - cfg_t.P_DATA_GOOD;
	         localparam P_BIAS_LSB          = (FILL > 0) ? 1 << FILL-1 : 0; // gabelli?????
	         localparam P_BIAS	        = (1<<cfg_t.P_DATA_GOOD+FILL) + P_BIAS_LSB;	
	         
		 //localparam FILL_ENC            = (FILL == 0) ? 1 : FILL;  
		 
	`mu_law_encoded_data_table_struct( mulaw_encoded_data, 
	                                   logic, 
					                   cfg_t.P_ENCODED_DW,
					                   cfg_t.P_SIGN, 
					                   cfg_t.P_DATA_GOOD,
					                   P_NUM_CHORD_LOG ) 
	`mu_law_encoded_data_struct(mulaw_encoded_data) encoded_data; 	
		`mu_law_decoded_data_table_struct( mulaw_decoded_data, 
	                                     logic, 
					     cfg_t.P_DECODED_DW,
					     cfg_t.P_SIGN, 
					     cfg_t.P_DATA_GOOD + FILL,
					     C )			     
		`mu_law_decoded_data_struct(mulaw_decoded_data) decoded_data_neg;
		`mu_law_decoded_data_struct(mulaw_decoded_data) decoded_data_stuff; 
		`mu_law_decoded_data_struct(mulaw_decoded_data) decoded_data;
		logic [cfg_t.P_ENCODED_DW-1:0] dt;
	        logic [MU_LAW_DELAY:0] enable;
					    
	 always_ff @( posedge i_clk ) begin : mulaw_decode_f
	 	 dt <= i_dt;
		 encoded_data <= mulaw_encoded_data_t'(dt);
		 enable[MU_LAW_DELAY:0] <= {enable[MU_LAW_DELAY-1:0] , i_enable};
		 decoded_data_neg       <= mulaw_c#( .cfg_t (cfg_t) )::mulaw_encode_neg_f(enable[1], encoded_data);
		 decoded_data_stuff     <= mulaw_c#( .cfg_t (cfg_t) )::mulaw_decode_stuff_f(enable[2], decoded_data_neg);
		 decoded_data           <= mulaw_c#( .cfg_t (cfg_t) )::mulaw_decode_datascaled_f(enable[3], decoded_data_stuff); 		 
		 o_dt <= decoded_data;
		 o_enable <= enable[4];
	end
	
endmodule
