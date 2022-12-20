///----------------------------------------------------------------------------
// Title         : Mu-Law Configuration Package
// Project       : 
//-----------------------------------------------------------------------------
// File          : parameter_mulaw_pkg.sv
//-----------------------------------------------------------------------------
// Description :
//
//  Generic Mu-law Configuration Package.
//  It has some parameters to have different behaviours.
//
//-----------------------------------------------------------------------------
// Copyright (c) 2022 
//-----------------------------------------------------------------------------

`ifndef PARAMETER_MULAW_PKG_SV_
`define PARAMETER_MULAW_PKG_SV_

 package parameter_mulaw_pkg;
 
    typedef struct {
                     int        P_SIGN;
		     int        P_SIGN_VALUE;
                     int        P_NUM_CHORD;
                     int        P_DECODED_DW;  		                            
                     int        P_ENCODED_DW; 		                            
		     int        P_DATA_GOOD; 
                     string     P_ASSERT_DISABLE;     
                     string   	P_VERBOSE;		            
    } mu_law_t; 
    
   /*
      Standar ITU G711
    */  
      
    parameter mu_law_t parameter_mu_law_g711_t = '{ 
             P_SIGN	        : 1,
	     P_SIGN_VALUE       : 1,
    	     P_NUM_CHORD	: 8,
    	     P_DECODED_DW	: 14, 
    	     P_ENCODED_DW	: 8,
    	     P_ASSERT_DISABLE	: "ON",
    	     P_VERBOSE 	: "ON", 
	     P_DATA_GOOD	: 4  // FILL == 1
    } ;   
    
    parameter mu_law_t parameter_mu_law_16_11_t = '{ 
             P_SIGN	        : 1,
	     P_SIGN_VALUE       : 1,
    	     P_NUM_CHORD	: 8,
    	     P_DECODED_DW	: 16, 
    	     P_ENCODED_DW	: 11,
    	     P_ASSERT_DISABLE	: "ON",
    	     P_VERBOSE 	: "ON", 
	     P_DATA_GOOD	: 7  // FILL == 0
    };
    
    parameter mu_law_t parameter_mu_law_16_12_t = '{ 
             P_SIGN	        : 1,
	     P_SIGN_VALUE       : 1,
    	     P_NUM_CHORD	: 7,
    	     P_DECODED_DW	: 16, 
    	     P_ENCODED_DW	: 12,
    	     P_ASSERT_DISABLE	: "ON",
    	     P_VERBOSE 	: "ON", 
	     P_DATA_GOOD	: 8  // FILL == 0
    };
    
 endpackage: parameter_mulaw_pkg
  
`endif // PARAMETER_MULAW_PKG_SV_
