module Fetch_cycle(clk,rst,stall,flush,pcsrcE,pctargetE,pcD_out,Instr_outD,pcplus4D);
input clk,rst;
wire [31:0]pcF;
input stall,flush;
wire [31:0] pc_F,pcplus4F,Instr_outF;
input pcsrcE;
input[31:0]pctargetE;
output wire [31:0] Instr_outD,pcplus4D,pcD_out;
wire [31:0]pcD_wire;
PC PC(.clk(clk),.rst(rst),.stall(stall),.flush(flush),.pc_F(pc_F),.pcF(pcF));
PC_Adder PC_Adder(.pcF(pcF),.pcplus4F(pcplus4F));
PC_Mux PC_Mux(.pcplus4F(pcplus4F),.pctargetE(pctargetE),.pcsrcE(pcsrcE),.pc_F(pc_F));
Instruction_Mem Instruction_Mem(.clk(clk),.rst(rst),.pcF(pcF),.Instr_outF(Instr_outF));
IF_ID IF_ID(.clk(clk),.rst(rst),.stall(stall),.flush(flush),.pcF_in(pcF),.Instr_inF(Instr_outF),
.pcplus4_F(pcplus4F),.pcD_out(pcD_wire),.Instr_outD(Instr_outD),.pcplus4_D(pcplus4D));
assign pcD_out=pcD_wire;
endmodule

module PC(clk,rst,stall,flush,pc_F,pcF);
input clk,rst,stall,flush;
input [31:0]pc_F;
output reg [31:0]pcF;
always@(posedge clk)
begin
if(rst==0)
pcF<=32'b0;
else if(stall==1)
pcF<=pcF;
else if(flush==1)
pcF<=pc_F;
else
pcF<=pc_F;
end
endmodule

module PC_Adder(pcF,pcplus4F);
input [31:0]pcF;
output  [31:0]pcplus4F;
assign pcplus4F=pcF+4;
endmodule

module PC_Mux(pcplus4F,pctargetE,pcsrcE,pc_F);
input [31:0]pcplus4F,pctargetE;
input pcsrcE;
output [31:0]pc_F;
assign pc_F=(pcsrcE)?pctargetE:pcplus4F;
endmodule

module Instruction_Mem( clk, rst,pcF, Instr_outF);
input clk,rst;
input [31:0] pcF;
output reg [31:0] Instr_outF;
 reg [31:0]Memory[63:0]; 
 integer k;  
 
 initial begin
    for(k=0; k<64; k=k+1)
      Memory[k] = 0;

    //Memory[0] = 32'h1f400113; //addi x2,x0,500
    //Memory[1] = 32'h003082b3; //add x5,x1,x3
    Memory[0] = 32'h00208263; //beq x1, x2, 8
    Memory[1] = 32'h1f400113; //addi x2,x0,500
    Memory[2] = 32'h003102b3; //add x5,x2,x3    
    Memory[3] = 32'h00022303; //lw x6, 0(x4)
    Memory[4] = 32'h00742223; //sw x7, 4(x8)
    Memory[5] = 32'h010002ef; //jal x5, 16
    Memory[6] = 32'h1f400113; //addi x2,x0,500
    Memory[7] = 32'h003102b3; //add x5,x2,x3     
    Memory[8] = 32'h00022303; //lw x6, 0(x4)
    Memory[9] = 32'h00742223; //sw x7, 4(x8)
    Memory[10] = 32'h1f400113; //addi x2,x0,500
    Memory[11] = 32'h003102b3; //add x5,x2,x3     
    Memory[12] = 32'h00022303; //lw x6, 0(x4)
    Memory[13] = 32'h00742223; //sw x7, 4(x8)
    
    
  end

  always @(*) begin
    if (rst==0) 
      Instr_outF <= 32'b0;  // clear output when reset
    else
      Instr_outF <= Memory[pcF[31:2]];
  end

endmodule

module IF_ID(clk,rst,stall,flush,pcF_in,Instr_inF,pcplus4_F,pcD_out,Instr_outD,pcplus4_D);
input clk,rst,stall,flush;
input [31:0]pcF_in,Instr_inF,pcplus4_F;
output reg [31:0]pcD_out,Instr_outD,pcplus4_D;
always@(posedge clk)
begin
  if(rst==1'b0)
  begin
    pcD_out<=32'b0;
    Instr_outD<=32'b0;
    pcplus4_D<=32'b0;
  end
  else if(stall)
  begin
    pcD_out<=pcD_out;
    Instr_outD<=Instr_outD;
    pcplus4_D<=pcplus4_D;
  end
  else if(flush)
  begin
    pcD_out<=32'b0;
    Instr_outD<=32'b0;
    pcplus4_D<=32'b0;
  end
  else
  begin
    pcD_out<=pcF_in;
    Instr_outD<=Instr_inF;
    pcplus4_D<=pcplus4_F;
  end
end
endmodule

module Decode_Cycle(
    input clk,
    input rst,
    input stall,
    input flush,
    input [31:0]Instr_inD,
    input [4:0]RdW,
    input RegWriteW,
    input [31:0]ResultW,
    input [31:0]PCD,PCPlus4D,
    
    
    output  RegWriteE,
    output  [1:0] ResultSrcE,
    output  MemWriteE,
    output  JumpE,
    output  BranchE,
    output  [5:0] ALUControlE,
    output ALUSrcE,

    // Data signals (to EX stage)
    output  [31:0] RD1E,
    output  [31:0] RD2E,
    output  [4:0] Rs1E,
    output [4:0] Rs2E,
    output [4:0] RdE,
    output [31:0] ImmExtE,
    output  [31:0] PCE,
    output  [31:0] PCPlus4E,
    
    output [4:0] Rs1D,
    output [4:0] Rs2D,
    output MemReadE);
    
    wire RegWriteD;
    wire [1:0]ResultSrcD;
    wire MemWriteD,JumpD,BranchD;
    wire [5:0]ALUControlD;
    wire ALUSrcD;
    wire [1:0]ImmSrcD;
    wire [31:0]RD1D,RD2D;
    wire [31:0]ImmExtD;
    
assign Rs1D = Instr_inD[19:15];
assign Rs2D = Instr_inD[24:20];

wire MemReadD;
assign MemReadE = MemReadD;
    
    
Control_Unit Control_Unit(.op(Instr_inD[6:0]),.funct3(Instr_inD[14:12]),
.funct7(Instr_inD[30]),.RegWrite(RegWriteD),.ResultSrc(ResultSrcD),.MemWrite(MemWriteD),.MemRead(MemReadD),
.Jump(JumpD),.Branch(BranchD),.ALUControl(ALUControlD),.ALUSrc(ALUSrcD),.ImmSrc(ImmSrcD));

Reg_File Reg_File(.clk(clk),.rst(rst),.A1(Instr_inD[19:15]),.A2(Instr_inD[24:20]),.A3(RdW),
.WD3(ResultW),.WE3(RegWriteW),.RD1(RD1D),.RD2(RD2D));

extend extend(.instr(Instr_inD),.immsrc(ImmSrcD),.immext(ImmExtD));

ID_EX ID_EX(.clk(clk),.rst(rst),.stall(stall),.flush(flush),.RegWriteD(RegWriteD),
.ResultSrcD(ResultSrcD),.MemWriteD(MemWriteD),.JumpD(JumpD),.BranchD(BranchD),.ALUControlD(ALUControlD),
.ALUSrcD(ALUSrcD),.RD1D(RD1D),.RD2D(RD2D),.Rs1D(Instr_inD[19:15]),.Rs2D(Instr_inD[24:20]),
.RdD(Instr_inD[11:7]),.ImmExtD(ImmExtD),
.PCD(PCD),.PCPlus4D(PCPlus4D),.RegWriteE(RegWriteE),.ResultSrcE(ResultSrcE),.MemWriteE(MemWriteE),.JumpE(JumpE),
.BranchE(BranchE),.ALUControlE(ALUControlE),.ALUSrcE(ALUSrcE),.RD1E(RD1E),.RD2E(RD2E),.Rs1E(Rs1E),
.Rs2E(Rs2E),.RdE(RdE),.ImmExtE(ImmExtE),.PCE(PCE),.PCPlus4E(PCPlus4E));


endmodule

module Control_Unit(op,funct3,funct7,RegWrite,ResultSrc,MemWrite,MemRead,Jump,Branch,ALUControl,ALUSrc,ImmSrc);
input [6:0]op;
input funct7;
input[2:0]funct3;
output RegWrite,MemWrite,MemRead,ALUSrc,Branch,Jump;
output[1:0]ImmSrc,ResultSrc;
output  [5:0]ALUControl;
wire [1:0]ALUOp;
    
    Main_Decoder Main_Decoder(
                .op(op),
                .RegWrite(RegWrite),
                .ImmSrc(ImmSrc),
                .MemWrite(MemWrite),
                .MemRead(MemRead),
                .ResultSrc(ResultSrc),
                .Branch(Branch),
                .ALUSrc(ALUSrc),
                .ALUOp(ALUOp),
                .Jump(Jump)
    );

    ALU_Decoder ALU_Decoder(
                 .ALUOp(ALUOp),
                 .funct3(funct3),
                 .funct7(funct7),
                 .op(op),
                 .ALUControl(ALUControl)
    );

endmodule

module Main_Decoder(op,RegWrite,ImmSrc,ALUSrc,MemWrite,MemRead,ResultSrc,Branch,ALUOp,Jump);
input [6:0]op;
output RegWrite,MemWrite,MemRead,ALUSrc,Branch,Jump;
output[1:0]ImmSrc,ResultSrc,ALUOp;

parameter RType=7'b0110011;
parameter LW=7'b0000011;
parameter SW=7'b0100011;
parameter BEQ=7'b1100011;
parameter IType=7'b0010011;
parameter JAL=7'b1101111;

assign RegWrite = (op==LW |op==RType|op==IType|op==JAL)?1'b1:1'b0;
assign ImmSrc = (op==SW)?2'b01:(op==BEQ)?2'b10:(op==JAL)?2'b11:2'b00;
assign ALUSrc = (op==LW|op==SW|op==IType)?1'b1:1'b0;
assign MemWrite = (op==SW)?1'b1:1'b0;
assign MemRead=(op == LW) ? 1'b1 : 1'b0;
assign ResultSrc = (op==LW)?2'b01:(op==JAL)?2'b10:2'b00;
assign Branch = (op==BEQ)?1'b1:1'b0;
assign ALUOp = (op==RType|op==IType)?2'b10:(op==BEQ)?2'b01:2'b00;
assign Jump = (op==JAL)?1'b1:1'b0;

endmodule

module ALU_Decoder(ALUOp,funct3,funct7,op,ALUControl);
input [1:0]ALUOp;
input [2:0]funct3;
input[6:0]op;
input funct7;
output reg [5:0]ALUControl;

parameter RType=7'b0110011;
parameter BEQ=7'b1100011;
parameter IType=7'b0010011;
parameter ECALL =7'b1110011;
always @(*)
begin
 case(ALUOp)
           2'b00:ALUControl = 6'b000000; // addition
           2'b01:ALUControl = 6'b000001; // subtraction
           default: case(funct3) // R-type or I-type ALU
                            3'b000:if ((op[5]==1 && funct7==1))
                                    ALUControl = 6'b000001; // sub
                                    else
                                    ALUControl = 6'b000000; // add, addi
                            3'b010: ALUControl = 6'b000101; // slt, slti
                            3'b110: ALUControl = 6'b000011; // or, ori
                            3'b111: ALUControl = 6'b000010; // and, andi
                            default:ALUControl = 6'bxxxxxx; // ???
                         endcase
endcase
end
endmodule

module Reg_File(clk, rst, A1, A2, A3, WD3, WE3, RD1, RD2); 
input [4:0] A1, A2, A3; input [31:0] WD3; 
input WE3, clk, rst; 
output [31:0] RD1, RD2;

reg [31:0] Registers [31:0]; 

assign RD1 = (A1 == 5'b00000) ? 32'b0 : Registers[A1]; 
assign RD2 = (A2 == 5'b00000) ? 32'b0 : Registers[A2]; // Synchronous write + reset 
integer i; 

always @(posedge clk) begin 
if (rst==0) begin 
for (i = 0; i < 32; i = i + 1) 
Registers[i] <= 32'b0; // clear all registers 
Registers[0] = 0; 
Registers[1] <= 32'd10; 
Registers[2] <= 1; 
Registers[3] <= 32'd20; 
Registers[4] <= 32'd6; 
Registers[5] <= 3; 
Registers[6] <= 44; 
Registers[7] <= 32'd55; 
Registers[8] <= 32'd0002; 
Registers[9] <= 1; 
Registers[10] <= 23; 
Registers[11] <= 4; 
Registers[12] <= 90; 
Registers[13] <= 10; 
Registers[14] <= 20; 
Registers[15] <= 30; 
Registers[16] <= 40; 
Registers[17] <= 50; 
Registers[18] <= 60; 
Registers[19] <= 70; 
Registers[20] <= 80; 
Registers[21] <= 80; 
Registers[22] <= 90; 
Registers[23] <= 70; 
Registers[24] <= 60; 
Registers[25] <= 65; 
Registers[26] <= 4; 
Registers[27] <= 32; 
Registers[28] <= 12; 
Registers[29] <= 34; 
Registers[30] <= 5; 
Registers[31] <= 10; 
end 

else if (WE3 && A3 != 0) begin 
Registers[A3] <= WD3; 
end 
end 
endmodule



module extend(input[31:0]instr,input[1:0]immsrc,output reg [31:0] immext);
    always@(*)
    begin
       case(immsrc)
                         // I-type
           2'b00:     immext = {{20{instr[31]}}, instr[31:20]};
                         // S-type (stores)
            2'b01:     immext = {{20{instr[31]}}, instr[31:25],  
 instr[11:7]};
                         // B-type (branches)
           2'b10:      immext = {{20{instr[31]}}, instr[7],  
 instr[30:25], instr[11:8], 1'b0};                                        
                         // J-type (jal)
           2'b11:      immext = {{12{instr[31]}}, instr[19:12],  
 instr[20], instr[30:21], 1'b0};
           default: immext = 32'bx; // undefined
        endcase
 end
 endmodule

module ID_EX (
    input clk, rst, stall, flush,

    // Control signals (from ID stage)
    input RegWriteD,
    input [1:0] ResultSrcD,
    input MemWriteD,
    input JumpD,
    input BranchD,
    input [5:0] ALUControlD,
    input ALUSrcD,

    // Data signals (from ID stage)
    input [31:0] RD1D,
    input [31:0] RD2D,
    input [4:0] Rs1D,
    input [4:0] Rs2D,
    input [4:0] RdD,
    input [31:0] ImmExtD,
    input [31:0] PCD,
    input [31:0] PCPlus4D,

    // Control signals (to EX stage)
    output reg RegWriteE,
    output reg [1:0] ResultSrcE,
    output reg MemWriteE,
    output reg JumpE,
    output reg BranchE,
    output reg [5:0] ALUControlE,
    output reg ALUSrcE,

    // Data signals (to EX stage)
    output reg [31:0] RD1E,
    output reg [31:0] RD2E,
    output reg [4:0] Rs1E,
    output reg [4:0] Rs2E,
    output reg [4:0] RdE,
    output reg [31:0] ImmExtE,
    output reg [31:0] PCE,
    output reg [31:0] PCPlus4E
);

    always @(posedge clk) begin
    if (!rst) begin
        // Reset: clear outputs
        {RegWriteE, ResultSrcE, MemWriteE, JumpE, BranchE,
         ALUControlE, ALUSrcE, RD1E, RD2E, Rs1E, Rs2E, RdE,
         ImmExtE, PCE, PCPlus4E} <= 0;
    end 
    else if (flush) begin
        // Bubble: clear only control signals
        
        RegWriteE   <= 0;
        ResultSrcE  <= 2'b00;
        MemWriteE   <= 0;
        JumpE       <= 0;
        BranchE     <= 0;
        ALUControlE <= 6'b000000;
        ALUSrcE     <= 0;
        // Data could stay as-is (not used), but clearing is okay
        RD1E <= 0; RD2E <= 0; Rs1E <= 0; Rs2E <= 0; RdE <= 0;
        ImmExtE <= 0; PCE <= 0; PCPlus4E <= 0;
    end
    else if (stall) begin
        // Do nothing: hold previous values
    end
    else begin
        // Normal pipeline update
        RegWriteE   <= RegWriteD;
        ResultSrcE  <= ResultSrcD;
        MemWriteE   <= MemWriteD;
        JumpE       <= JumpD;
        BranchE     <= BranchD;
        ALUControlE <= ALUControlD;
        ALUSrcE     <= ALUSrcD;

        RD1E        <= RD1D;
        RD2E        <= RD2D;
        Rs1E        <= Rs1D;
        Rs2E        <= Rs2D;
        RdE         <= RdD;
        ImmExtE     <= ImmExtD;
        PCE         <= PCD;
        PCPlus4E    <= PCPlus4D;
    end
end

endmodule

module execute_cycle(
 input clk,rst,stall,flush,
 input  RegWriteE,
 input  [1:0] ResultSrcE,
 input  MemWriteE,
 input  JumpE,
 input  BranchE,
 input  [5:0] ALUControlE,
 input ALUSrcE,
 input  [31:0] RD1E,
 input  [31:0] RD2E,
 input  [4:0] Rs1E,
 input [4:0] Rs2E,
 input [4:0] RdE,
 input [31:0] ImmExtE,
 input  [31:0] PCE,
 input  [31:0] PCPlus4E,
 input [1:0] ForwardAE,
 input [1:0] ForwardBE,
 input [31:0] ResultW,
 
 output RegWriteM,
 output [1:0] ResultSrcM,
 output MemWriteM,
 output [31:0] ALUResultM,
 output [31:0] WriteDataM,
 output [4:0] RdM,
 output [31:0] PCPlus4M,
 output [31:0] PCTargetE,
 output ZeroE);
 
 wire [31:0] SrcAE,SrcBE,WriteDataE;
 wire [31:0] ALUResultE;
 
 
 Mux_3_by_1 mux31_1(.a(RD1E),.b(ResultW),.c(ALUResultM),
                  .s(ForwardAE),.y(SrcAE));
                  
Mux_3_by_1 mux31_2(.a(RD2E),.b(ResultW),.c(ALUResultM),
                  .s(ForwardBE),.y(WriteDataE));
                  
mux_2_by_1 mux21(.a(WriteDataE),.b(ImmExtE),.s(ALUSrcE),
                 .y(SrcBE)); 
                 
adder adder(.PCE(PCE),.ImmExtE(ImmExtE),.PCTargetE(PCTargetE));

ALU ALU(.A(SrcAE),.B(SrcBE),.ALU_out(ALUResultE),.zero(ZeroE),.ALU_Sel(ALUControlE));               
 
EX_MEM EX_MEM(.clk(clk),.rst(rst),.stall(stall),.flush(flush),
 .RegWriteE(RegWriteE),.ResultSrcE(ResultSrcE),.MemWriteE(MemWriteE),
 .ALUResultE(ALUResultE),.WriteDataE(WriteDataE),
 .RdE(RdE),.PCPlus4E(PCPlus4E),.RegWriteM(RegWriteM),
 .ResultSrcM(ResultSrcM),.MemWriteM(MemWriteM),
 .ALUResultM(ALUResultM),.WriteDataM(WriteDataM),
 .RdM(RdM),.PCPlus4M(PCPlus4M));
endmodule

module Mux_3_by_1(
    input [31:0] a,
    input [31:0] b,
    input [31:0] c,
    input [1:0] s,
    output [31:0] y
    );
    
    assign y=(s==2'b00)?a:(s==2'b01)?b:(s==2'b10)?c:32'h000000;
endmodule

module mux_2_by_1(input [31:0] a,
    input [31:0] b,
    input s,
    output [31:0] y
);

assign y=(s)?b:a;
endmodule

module adder(input [31:0]PCE,
input [31:0]ImmExtE,
output [31:0]PCTargetE,
output carry);

assign {carry,PCTargetE}=PCE+ImmExtE;
endmodule

module ALU(input [31:0]A,B,
input [5:0]ALU_Sel,
output reg [31:0]ALU_out,
output reg zero);

wire [31:0]sum;
reg cout;

always @(*) begin
   case(ALU_Sel)
      6'b000000:ALU_out=A+B;
      6'b000001:ALU_out=(A+(~B+1));
      6'b000011:ALU_out=A|B;
      6'b000010:ALU_out=A&B;
      6'b000101:ALU_out=(A<B)?1:0;
      default: ALU_out=32'hxxxxxx;
   endcase
   
   zero=~|ALU_out;
end
endmodule

module EX_MEM(
 input clk, rst, stall, flush,
 input  RegWriteE,
 input  [1:0] ResultSrcE,
 input MemWriteE,
 input [31:0] ALUResultE,
 input [31:0] WriteDataE,
 input [4:0] RdE,
 input  [31:0] PCPlus4E,
  
 output reg RegWriteM,
 output reg [1:0] ResultSrcM,
 output reg MemWriteM,
 output reg [31:0] ALUResultM,
 output reg [31:0] WriteDataM,
 output reg [4:0] RdM,
 output reg [31:0] PCPlus4M);
 
  always @(posedge clk) begin
    if (!rst) begin
        {RegWriteM,ResultSrcM,MemWriteM,ALUResultM,WriteDataM,
        RdM,PCPlus4M} <= 0;
    end 
    else if (flush) begin
      RegWriteM <= 1'b0;
      ResultSrcM <= 2'b00;
      MemWriteM <= 1'b0;
      ALUResultM <= 32'h000000;
      WriteDataM <= 32'h000000;
      RdM <= 5'b00000;
      PCPlus4M <= 32'h000000;
       
    end
    else if (stall) begin
        // Do nothing: hold previous values
    end
    else begin
        RegWriteM <= RegWriteE;
        ResultSrcM <= ResultSrcE;
        MemWriteM <= MemWriteE;
        ALUResultM <= ALUResultE;
        WriteDataM <= WriteDataE;
        RdM <= RdE;
        PCPlus4M <= PCPlus4E;
    end
end
endmodule

module Mux_3x1(input [1:0]ResultSrcW,
input [31:0] ALUResultW,ReadDataW,PCPlus4W,
output [31:0] ResultW);

assign ResultW=(ResultSrcW==2'b00)?ALUResultW:(ResultSrcW==2'b01)?ReadDataW:(ResultSrcW==2'b10)?PCPlus4W:32'h000000;
endmodule


module Mem_cycle(
    input clk,
    input rst,
    input RegWriteM,
    input stall,
    input flush,
    input MemWriteM,
    input [4:0] RdM,
    input [1:0] ResultSrcM,
    input [31:0] ALUResultM,
    input [31:0] PCPlus4M,
    input [31:0] WriteDataM,
    output RegWriteW,
    output [4:0] RdW,
    output [1:0] ResultSrcW,
    output [31:0] ALUResultW,
    output [31:0] ReadDataW,
    output [31:0] PCPlus4W
);

    // Internal wire for data memory output
    wire [31:0] ReadDataM;

    data_memory data_memory_inst (
        .clk(clk),
        .rst(rst),
        .A(ALUResultM),
        .WD(WriteDataM),
        .RD(ReadDataM),
        .WE(MemWriteM)
    );

    Mem_WB Mem_WB_inst (
        .clk(clk),
        .rst(rst),
        .RegWriteM(RegWriteM),
        .RdM(RdM),
        .stall(stall),
        .flush(flush),
        .ResultSrcM(ResultSrcM),
        .ALUResultM(ALUResultM),
        .ReadDataM(ReadDataM),      
        .PCPlus4M(PCPlus4M),
        .RegWriteW(RegWriteW),
        .RdW(RdW),
        .ResultSrcW(ResultSrcW),
        .ALUResultW(ALUResultW),
        .ReadDataW(ReadDataW),
        .PCPlus4W(PCPlus4W)
    );

endmodule


module data_memory(
    input clk,
    input rst,
    input [31:0] A,
    input [31:0] WD,
    output [31:0] RD,
    input WE
);
    reg [31:0] Data_Mem[63:0];

    initial begin
        Data_Mem[5]  = 32'd0;
        Data_Mem[6]  = 32'd12;
        Data_Mem[16] = 32'd1234;
    end

    // Word-aligned read (combinational)
    assign RD = Data_Mem[A[31:0]];

    // Write: synchronous
    always @(posedge clk) begin
     
        if (WE)
            Data_Mem[A[31:0]] <= WD;
    end
endmodule

module Mem_WB(
    input clk,
    input rst,
    input RegWriteM,
    input stall,
    input flush,
    input [4:0] RdM,
    input [1:0] ResultSrcM,
    input [31:0] ALUResultM,
    input [31:0] ReadDataM,
    input [31:0] PCPlus4M,
    output reg RegWriteW,
    output reg [4:0] RdW,
    output reg [1:0] ResultSrcW,
    output reg [31:0] ALUResultW,
    output reg [31:0] ReadDataW,
    output reg [31:0] PCPlus4W
);
    always @(posedge clk) begin
        if (rst == 0) begin
            RegWriteW  <= 0;
            RdW        <= 0;
            ResultSrcW <= 0;
            ALUResultW <= 0;
            ReadDataW  <= 0;
            PCPlus4W   <= 0;
        end
        else if (flush) begin
            RegWriteW  <= 0;
            RdW        <= 0;
            ResultSrcW <= 0;
            ALUResultW <= 0;
            ReadDataW  <= 0;
            PCPlus4W   <= 0;
        end
        else if (stall) begin
            // hold values
            RegWriteW  <= RegWriteW;
            RdW        <= RdW;
            ResultSrcW <= ResultSrcW;
            ALUResultW <= ALUResultW;
            ReadDataW  <= ReadDataW;
            PCPlus4W   <= PCPlus4W;
        end
        else begin
            RegWriteW  <= RegWriteM;
            RdW        <= RdM;
            ResultSrcW <= ResultSrcM;
            ALUResultW <= ALUResultM;
            ReadDataW  <= ReadDataM;
            PCPlus4W   <= PCPlus4M;
        end
    end
endmodule


module writeback_cycle(ResultSrcW,PCPlus4W,ALUResultW,ReadDataW,ResultW);

input [1:0]ResultSrcW;
input [31:0] ReadDataW,ALUResultW,PCPlus4W;
output [31:0]ResultW;

Mux_3x1 Mux_3x1(.ResultSrcW(ResultSrcW),.ALUResultW(ALUResultW),.ReadDataW(ReadDataW),.PCPlus4W(PCPlus4W),.ResultW(ResultW));

endmodule

module Processor_top(
    input clk,
    input rst
);

    // Hazard & pipeline control signals
    wire stall;
    wire flush;

    // Forwarding paths
    wire [1:0] ForwardAE, ForwardBE;

    // Branch & jump control
    wire pcsrcE;
    wire [31:0] pctargetE;

    // Fetch -> Decode
    wire [31:0] PCD, InstrD, PCPlus4D;

    // Decode -> Execute
    wire RegWriteE, MemWriteE, JumpE, BranchE, ALUSrcE;
    wire MemReadE;                // <── Added this
    wire [1:0] ResultSrcE;
    wire [5:0] ALUControlE;
    wire [31:0] RD1E, RD2E, ImmExtE, PCE, PCPlus4E;
    wire [4:0] Rs1E, Rs2E, RdE;

    // Execute -> Memory
    wire RegWriteM, MemWriteM;
    wire [1:0] ResultSrcM;
    wire [31:0] ALUResultM, WriteDataM, PCPlus4M;
    wire [4:0] RdM;
    wire ZeroE;

    // Memory -> Writeback
    wire RegWriteW;
    wire [1:0] ResultSrcW;
    wire [31:0] ALUResultW, ReadDataW, PCPlus4W;
    wire [4:0] RdW;
    wire [31:0] ResultW;

    // Rs1D and Rs2D are used for stall detection
    wire [4:0] Rs1D, Rs2D;        // <── Added these

    // ----------------------- FETCH -----------------------
    Fetch_cycle Fetch_cycle(
        .clk(clk),
        .rst(rst),
        .stall(stall),
        .flush(flush),
        .pcsrcE(pcsrcE),
        .pctargetE(pctargetE),
        .pcD_out(PCD),
        .Instr_outD(InstrD),
        .pcplus4D(PCPlus4D)
    );

    // ----------------------- DECODE -----------------------
    Decode_Cycle decode_cycle(
        .clk(clk),
        .rst(rst),
        .stall(stall),
        .flush(flush),
        .Instr_inD(InstrD),
        .RdW(RdW),
        .RegWriteW(RegWriteW),
        .ResultW(ResultW),
        .PCD(PCD),
        .PCPlus4D(PCPlus4D),

        // Outputs
        .RegWriteE(RegWriteE),
        .ResultSrcE(ResultSrcE),
        .MemWriteE(MemWriteE),
        .MemReadE(MemReadE),     // <── Added
        .JumpE(JumpE),
        .BranchE(BranchE),
        .ALUControlE(ALUControlE),
        .ALUSrcE(ALUSrcE),
        .RD1E(RD1E),
        .RD2E(RD2E),
        .Rs1E(Rs1E),
        .Rs2E(Rs2E),
        .Rs1D(Rs1D),             // <── Added
        .Rs2D(Rs2D),             // <── Added
        .RdE(RdE),
        .ImmExtE(ImmExtE),
        .PCE(PCE),
        .PCPlus4E(PCPlus4E)
    );

    // ----------------------- EXECUTE -----------------------
    execute_cycle execute_cycle(
        .clk(clk),
        .rst(rst),
        .stall(stall),
        .flush(flush),
        .RegWriteE(RegWriteE),
        .ResultSrcE(ResultSrcE),
        .MemWriteE(MemWriteE),
        .JumpE(JumpE),
        .BranchE(BranchE),
        .ALUControlE(ALUControlE),
        .ALUSrcE(ALUSrcE),
        .RD1E(RD1E),
        .RD2E(RD2E),
        .Rs1E(Rs1E),
        .Rs2E(Rs2E),
        .RdE(RdE),
        .ImmExtE(ImmExtE),
        .PCE(PCE),
        .PCPlus4E(PCPlus4E),
        .ForwardAE(ForwardAE),
        .ForwardBE(ForwardBE),
        .ResultW(ResultW),
        .RegWriteM(RegWriteM),
        .ResultSrcM(ResultSrcM),
        .MemWriteM(MemWriteM),
        .ALUResultM(ALUResultM),
        .WriteDataM(WriteDataM),
        .RdM(RdM),
        .PCPlus4M(PCPlus4M),
        .PCTargetE(pctargetE),
        .ZeroE(ZeroE)
    );

    // ----------------------- MEMORY -----------------------
    Mem_cycle Mem_cycle(
        .clk(clk),
        .rst(rst),
        .RegWriteM(RegWriteM),
        .RdM(RdM),
        .stall(stall),
        .flush(flush),
        .MemWriteM(MemWriteM),
        .ResultSrcM(ResultSrcM),
        .ALUResultM(ALUResultM),
        .PCPlus4M(PCPlus4M),
        .WriteDataM(WriteDataM),
        .RegWriteW(RegWriteW),
        .RdW(RdW),
        .ResultSrcW(ResultSrcW),
        .ALUResultW(ALUResultW),
        .ReadDataW(ReadDataW),
        .PCPlus4W(PCPlus4W)
    );

    // ----------------------- WRITEBACK -----------------------
    writeback_cycle writeback_cycle(
        .ResultSrcW(ResultSrcW),
        .PCPlus4W(PCPlus4W),
        .ALUResultW(ALUResultW),
        .ReadDataW(ReadDataW),
        .ResultW(ResultW)
    );

    // ----------------------- HAZARD UNIT -----------------------
    Hazard_unit hazard_unit(
        .rst(rst),
        .ForwardAE(ForwardAE),
        .ForwardBE(ForwardBE),
        .RegWriteW(RegWriteW),
        .RegWriteM(RegWriteM),
        .RdM(RdM),
        .RdW(RdW),
        .Rs1E(Rs1E),
        .Rs2E(Rs2E)
    );

    // ----------------------- STALL / FLUSH LOGIC -----------------------
    assign pcsrcE = (ZeroE & BranchE) | JumpE;
    assign flush  = pcsrcE; // Flush pipeline on branch or jump
    assign stall  = (MemReadE && ((RdE == Rs1D) || (RdE == Rs2D)));

endmodule
