module Hazard_unit(
    input rst,
    input RegWriteM,
    input RegWriteW,
    input [4:0] RdM,
    input [4:0] RdW,
    input [4:0] Rs1E,
    input [4:0] Rs2E,
    output [1:0] ForwardAE,
    output [1:0] ForwardBE
    );
    
    assign ForwardAE=(rst==1'b0)?2'b00:((RegWriteM==1)&(RdM!=5'h00)&(RdM==Rs1E))?2'b10:
    ((RegWriteW==1'b1)&(RdW!=5'h00)&(RdW==Rs1E))?2'b01:2'b00;
    
     assign ForwardBE=(rst==1'b0)?2'b00:((RegWriteM==1)&(RdM!=5'h00)&(RdM==Rs2E))?2'b10:
    ((RegWriteW==1'b1)&(RdW!=5'h00)&(RdW==Rs2E))?2'b01:2'b00;
    
endmodule
