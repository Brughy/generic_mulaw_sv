///-----------------------------------------------------------------------------
// Title         : Mu-Law Functionality Package
// Project       : 
//-----------------------------------------------------------------------------
// File          : mulaw_pkg.sv
//-----------------------------------------------------------------------------
// Description :
//
//  Generic Mu-law Functionality Package.
//  It implements encoder and deconder convertion and it separate step-by-step phases.
//
//-----------------------------------------------------------------------------
// Copyright (c) 2022
//------------------------------------------------------------------------------

`ifndef MULAW_PKG_SV_
`define MULAW_PKG_SV_

 package mulaw_pkg;
 
    import parameter_mulaw_pkg::*;
    
 	`define mu_law_encoded_data_struct_name(NAME) ``NAME``_t 
 
	`define mu_law_encoded_data_struct(NAME) `mu_law_encoded_data_struct_name(``NAME``)
   
	`define mu_law_encoded_data_table_struct(NAME, RQ_QUAL, DT, SIGN, DATA_GOOD, CHORD_LOG) \
		typedef struct packed { \
		    RQ_QUAL [``SIGN``-1:0]             sign; \
			RQ_QUAL [``CHORD_LOG``-1:0]       chord; \
			RQ_QUAL [``DATA_GOOD``-1:0]        data; \
		} `mu_law_encoded_data_struct_name(``NAME``); 
		
		
 	`define mu_law_decoded_data_struct_name(NAME) ``NAME``_t 
 
	`define mu_law_decoded_data_struct(NAME) `mu_law_decoded_data_struct_name(``NAME``)
         
	`define mu_law_decoded_data_table_struct(NAME, RQ_QUAL, DT, SIGN, DATA_GOOD, CHORD) \
		typedef struct packed { \
		    RQ_QUAL [``SIGN``-1:0]                                sign; \
			RQ_QUAL [``CHORD``-1:0]                              chord; \
			RQ_QUAL [``DATA_GOOD``-1:0]                           data; \
		//	RQ_QUAL [``FILL``-1:0]                                 fill; \
	             // RQ_QUAL [``DT``-``SIGN``-``CHORD``-``DATA_GOOD``-1:0] fill; \
		} `mu_law_decoded_data_struct_name(``NAME``); 		

 // v class
 
	virtual class mulaw_c #( parameter mu_law_t cfg_t = parameter_mu_law_g711_t ); 

		 localparam int ST 		 = cfg_t.P_DECODED_DW; 
		 localparam int S  		 = cfg_t.P_SIGN;
		 localparam int V  		 = cfg_t.P_SIGN_VALUE;     
		 localparam int T  		 = ST - S;    
		 localparam int C  		 = cfg_t.P_NUM_CHORD;
		 localparam int C_L		 = $clog2(C);			  
	         localparam int FILL		 = T - C - cfg_t.P_DATA_GOOD;
	         localparam int P_BIAS_LSB 	 = (FILL > 0) ? 1 << FILL-1 : 0; // gabelli?????
	         localparam int P_BIAS	         = (1<<cfg_t.P_DATA_GOOD+FILL) + P_BIAS_LSB;     
	         localparam int VV  		 = (2<<(T-1)) - 1 - P_BIAS;
		 
		`mu_law_encoded_data_table_struct ( mulaw_encoded_data, 
	                                     logic, 
					     cfg_t.P_ENCODED_DW,
					     S, 
					     cfg_t.P_DATA_GOOD,
					     C_L ) 
		`mu_law_encoded_data_struct(mulaw_encoded_data) encoded_data; 
	
		`mu_law_decoded_data_table_struct( mulaw_decoded_data, 
	                                     logic, 
					     ST,
					     S, 
					     cfg_t.P_DATA_GOOD+FILL,
					     C ) 
		`mu_law_decoded_data_struct(mulaw_decoded_data) decoded_data;  
         
		static function [C_L-1:0] pipe2cnt_f;           
				input mulaw_decoded_data_t i_decoded_data;
			begin
				integer i;
				logic [C-1:0] buffer;
				logic [C_L-1:0] tmp;
				logic break_v;
				
				break_v = 1'b0;
				for (i=0; i<C; i++) begin
				        buffer = {(C){1'b1}} >> ( C - 1 - i );
				        if ( (break_v == 1'b0) && (i_decoded_data.chord <= buffer) ) begin 
						tmp = i;
						break_v = 1'b1;
					end
				end
				
				pipe2cnt_f = tmp;
				
			end
		endfunction

		static function [C-1:0] cnt2pipe_f;           
				input mulaw_encoded_data_t i_encoded_data;
			begin
				cnt2pipe_f = 1 << i_encoded_data.chord;
			end
		endfunction

		static function mulaw_decoded_data_t data2mulaw_decoded_data_f;           
				input wire [ST-1:0] i_dt ;
			begin	
			         mulaw_decoded_data_t decoded_data;
			      	  decoded_data.sign  = i_dt[(FILL +  cfg_t.P_DATA_GOOD  +  C) +: S];
	                          decoded_data.chord = i_dt[(FILL +  cfg_t.P_DATA_GOOD)       +: C];
	                          decoded_data.data  = i_dt[ 0                                +: (FILL +  cfg_t.P_DATA_GOOD)];
				  
	                         data2mulaw_decoded_data_f = decoded_data;
			end
		endfunction
		
		static function mulaw_encoded_data2data_f;           
				input mulaw_encoded_data_t i_encoded_data;
			begin
			         mulaw_encoded_data2data_f = '0;			
			end
		endfunction

		static function mulaw_decoded_data_t encode_datascaled_f;
				input wire          i_enable;		           
				input wire [ST-1:0] i_dt ;
			begin
				
			    mulaw_decoded_data_t decoded_data;
				mulaw_decoded_data_t decoded_data_biased;
				
				logic [T-1:0] data, data_biased;
			        logic th;
				
			       if (i_enable) begin
				data = i_dt[T-1:0];
				decoded_data = data2mulaw_decoded_data_f(i_dt);
				th = ( decoded_data.sign == V ) ? 1'b1 : 1'b0;
				
			        if ( th == 1'b1 ) begin
					data_biased = ~data;
				end else begin
					data_biased = data ;
				end
			       end	
				decoded_data_biased = data2mulaw_decoded_data_f( {decoded_data.sign, data_biased} );
			       				
				encode_datascaled_f = decoded_data_biased;
				
			end
		endfunction
		
		static function mulaw_decoded_data_t encode_stub_f;
				input wire                 i_enable;           
				input mulaw_decoded_data_t i_decoded_data;
			begin				

				mulaw_decoded_data_t decoded_data_stub;
				logic [T-1:0] data, data_stub;
			        logic th;
				
			      if (i_enable) begin
			       
				data               = i_decoded_data;				
				th                 = (data > VV) ? 1'b1 : 1'b0;
				
				if ( th == 1'b1 ) begin
					data_stub = VV + 1;
				end else begin
					data_stub = data + P_BIAS;
				end
				
				decoded_data_stub = mulaw_decoded_data_t'({i_decoded_data.sign, data_stub});
			       end 					
			       
				encode_stub_f = decoded_data_stub;
				
			end
		endfunction		
		
		static function mulaw_encoded_data_t mulaw_encode_stuff_f;
				input wire                 i_enable;			  
				input mulaw_decoded_data_t i_decoded_data;
			begin
				 
			    mulaw_encoded_data_t encoded_data;
				logic [T-1:0] data;
				
			      if (i_enable) begin
				data               = i_decoded_data;
				encoded_data.chord = pipe2cnt_f(i_decoded_data);
				encoded_data.data  = data >> ((encoded_data.chord) + FILL);
				encoded_data.sign  = i_decoded_data.sign;
			       end 
			    mulaw_encode_stuff_f = encoded_data;
					  
			end
		endfunction 
		
		static function mulaw_encoded_data_t mulaw_encode_neg_f;
				input wire                 i_enable;			  
				input mulaw_encoded_data_t i_encoded_data;
			begin
				 
			    mulaw_encoded_data_t encoded_data;

			      if(i_enable) begin
				encoded_data.chord =  ~i_encoded_data.chord;
				encoded_data.data  =  ~i_encoded_data.data;
				encoded_data.sign  =  ~i_encoded_data.sign;
			       end 
			    mulaw_encode_neg_f = encoded_data;
					  
			end
		endfunction 		
	        
          ////////////////////////////////////////////////////////////////////////// decode
	  
		static function mulaw_decoded_data_t mulaw_decode_stuff_f;
				input wire                 i_enable;	  
				input mulaw_encoded_data_t i_encoded_data;
			begin				
				
				logic [T-1:0] data = '0;
				logic [T-1:0] data_tmp, data_stuff;
			        mulaw_decoded_data_t decoded_data_tmp;
				mulaw_decoded_data_t decoded_data;
			      
			      if (i_enable) begin
				decoded_data_tmp.chord = cnt2pipe_f(i_encoded_data);
				/*
					Case of 10000... lsb bits inserted! 
				*/
				if (FILL != 0) begin
					data_tmp = { decoded_data_tmp.chord, {(cfg_t.P_DATA_GOOD){1'b0}}, {(FILL){1'b0}} };
					data = data_tmp | {i_encoded_data.data, 1'b1} << i_encoded_data.chord + (FILL - 1);
				end else begin
					data_tmp = { decoded_data_tmp.chord, {(cfg_t.P_DATA_GOOD){1'b0}} };
				 	if ( i_encoded_data.chord == 0) begin
				 		data = data_tmp | {i_encoded_data.data};
					end else begin
						data = data_tmp | {i_encoded_data.data, 1'b1} << i_encoded_data.chord - 1;
					end
				end	
			      end
			      
				mulaw_decode_stuff_f = mulaw_decoded_data_t'({i_encoded_data.sign, data});
			end
		endfunction 	  

		static function mulaw_decoded_data_t mulaw_decode_datascaled_f; 
		                input wire                 i_enable;
				input mulaw_decoded_data_t i_decoded_data;
			begin
				logic [T-1:0] data, data_biased;
			        logic th;
				
			      if (i_enable) begin
				data = i_decoded_data;
				th = ( i_decoded_data.sign == V ) ? 1'b1 : 1'b0;
				
			        if ( th == 1'b1 ) begin
				        data_biased = ~data + P_BIAS;
			        end else begin
				        data_biased = data + P_BIAS;
			        end
			      end
				mulaw_decode_datascaled_f = mulaw_decoded_data_t'({i_decoded_data.sign, data_biased});
			end	
		endfunction	
					  
	endclass

 endpackage: mulaw_pkg

`endif // MULAW_PKG_SV_

