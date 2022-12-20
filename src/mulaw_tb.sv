///----------------------------------------------------------------------------
// Title         : Mu-Law Testbench
// Project       : 
//-----------------------------------------------------------------------------
// File          : mulaw_tb.sv
//-----------------------------------------------------------------------------
// Description :
//
//  Generic Mu-law Tb.
//  Tested on Vivado 2020.2.
//
//-----------------------------------------------------------------------------
// Copyright (c) 2022
//-----------------------------------------------------------------------------


//`define MULAW_SIM 1

module mulaw_tb import parameter_mulaw_pkg::*; # (
 //parameter mu_law_t cfg_t = parameter_mulaw_pkg::parameter_mu_law_g711_t
 //parameter mu_law_t cfg_t = parameter_mulaw_pkg::parameter_mu_law_16_12_t
   parameter mu_law_t cfg_t = parameter_mulaw_pkg::parameter_mu_law_16_11_t
  
  //derived
  ,parameter DDW = cfg_t.P_DECODED_DW
  ,parameter EDW = cfg_t.P_ENCODED_DW
)
(
  `ifndef MULAW_SIM
    input wire clk,
  `endif
  
    output [DDW-1:0] o_delta
);

 import mulaw_pkg::*;
 
 /*
  Or new parameter settings
 */

 `ifdef MULAW_SIM
 logic clk ;

 initial begin
    clk = 0;
    forever 
         #5 clk = ~clk;
 end
`endif

 logic [DDW-1:0] dec_dt, dec_dt_new, redec_dt, delta;
 logic [EDW-1:0] enc_dt;
 logic [DDW-1:0] cnt = '1;

 logic [DDW*20-1:0] dec_dt_post = 0;
 
 always_ff @( posedge clk ) begin
 	cnt <= cnt + 1;
	dec_dt_post[DDW*20-1:0] <= {dec_dt_post[DDW*19-1:0]  , dec_dt};
 end
 
// assign dec_dt = {1'b0,cnt[DDW-2:0]};
 assign dec_dt = cnt; 

 localparam MU_LAW_ENC_DELAY = 6;
 localparam MU_LAW_DEC_DELAY = 6; 
 
 mulaw_enc #( .cfg_t ( cfg_t ) ) // delay 6
 enc_inst (
     .i_clk     ( clk )
	,.i_dt      ( dec_dt )
	,.i_enable  ( 1'b1 )
	,.o_dt      ( enc_dt )
	,.o_enable  (  )
 );

 mulaw_dec #( .cfg_t ( cfg_t ) ) // delay 6
 dec_inst (
     .i_clk     ( clk )
	,.i_dt      ( enc_dt )
	,.i_enable  ( 1'b1 )
	,.o_dt      ( redec_dt )
	,.o_enable  (  )
 );
 
 assign dec_dt_new = dec_dt_post[(MU_LAW_ENC_DELAY+MU_LAW_DEC_DELAY-1)*DDW+:DDW];
 assign delta = redec_dt - dec_dt_new;
 assign o_delta = delta;
 
endmodule



