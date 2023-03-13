module mux1(
	RT, RD, MUX1Sel,

	Addr3
	);
	input[4:0] RT, RD;
	input[1:0] MUX1Sel;
	output reg[4:0] Addr3;

	always@(RT, RD, MUX1Sel)
		case(MUX1Sel)
			2'b00:	Addr3 = RT;	//rt
			2'b01:	Addr3 = RD;	//rd
			default:Addr3 = 5'h1f;			//31
		endcase

endmodule

module mux2(
	MUX6Out, CP0Out,
	MUX2Sel, MEM2_SCOut,

	WD
	);
	input [31:0] 		MUX6Out;
	input [31:0]		CP0Out;
	input [31:0]		MEM2_SCOut;
	input [2:0] 		MUX2Sel;

	output reg[31:0] 		WD;

	always@(*)
		case(MUX2Sel)
			3'b101:	WD = CP0Out;
			3'b111: WD = MEM2_SCOut;
			default:WD = MUX6Out;
		endcase

endmodule

module mux3(
	RD2, Imm32, MUX3Sel,

	B
	);
	input[31:0] RD2,Imm32;
	input MUX3Sel;
	output reg[31:0] B;

	always@(RD2, Imm32, MUX3Sel)
		case(MUX3Sel)
			1'b0:	B = RD2;
			default:B = Imm32;
		endcase

endmodule

module mux4(
	GPR_RS, data_EX, 
	data_MEM1, data_MEM2, MUX4Sel, 
	
	out
	);
	input[31:0] GPR_RS, data_EX, data_MEM1, data_MEM2;
	input[1:0] MUX4Sel;
	output reg[31:0] out;

	always@(GPR_RS, data_EX, data_MEM1, data_MEM2, MUX4Sel)
		case(MUX4Sel)
			2'b00, 2'b10:	out = GPR_RS;
			2'b01:	out = data_EX;
			default:out = data_MEM2;
		endcase

endmodule

module mux5(
	GPR_RT, data_EX, 
	data_MEM1, data_MEM2, MUX5Sel, 
	
	out
	);
	input[31:0] GPR_RT, data_EX, data_MEM1, data_MEM2;
	input[1:0] MUX5Sel;
	output reg[31:0] out;

	always@(GPR_RT, data_EX, data_MEM1, data_MEM2, MUX5Sel)
		case(MUX5Sel)
			2'b00, 2'b10:	out = GPR_RT;
			2'b01:	out = data_EX;
			default:out = data_MEM2;
		endcase

endmodule

module mux6(
	ALU1Out, MUX13Out, MUX6Sel,

	out
	);
	input[31:0] ALU1Out, MUX13Out;
	input 		MUX6Sel;
	output [31:0] 	out;

	assign out = MUX6Sel ? ALU1Out: MUX13Out;

endmodule

module mux7(
	WRSign, MUX7Sel,

	MUX7Out
	);
	input[22:0] WRSign;
	input MUX7Sel;
	output[22:0] MUX7Out;

	assign MUX7Out = MUX7Sel ? 23'h0 : WRSign;

endmodule

module mux8(
	GPR_RS, data_MEM1, data_MEM2, MUX8Sel, WD,
	
	out
	);
	input[31:0] GPR_RS, data_MEM1, data_MEM2, WD;
	input[1:0] MUX8Sel;
	output reg[31:0] out;
	

	always@(GPR_RS, data_MEM1, data_MEM2, MUX8Sel, WD)
		if(MUX8Sel == 2'b00)
			out = GPR_RS;
		else 
			case(MUX8Sel)
				2'b10:	out = data_MEM1;
				2'b11:	out = data_MEM2;
				default: out = WD;
			endcase
endmodule 

module mux9(
	GPR_RT, data_MEM1, data_MEM2, MUX9Sel, WD,
	
	out
	);
	input[31:0] GPR_RT, data_MEM1, data_MEM2, WD;
	input[1:0] MUX9Sel;
	output reg[31:0] out;
	
	always@(GPR_RT, data_MEM1, data_MEM2, MUX9Sel, WD)
		if(MUX9Sel == 2'b00)
			out = GPR_RT;
		else 
			case(MUX9Sel)
				2'b10:	out = data_MEM1;
				2'b11:	out = data_MEM2;
				default: out = WD;
			endcase

endmodule 

module mux10(WB_MUX2Out, WB_DMOut, WB_MUX2Sel, MUX10Out);
	input[31:0] WB_MUX2Out;
	input[31:0] WB_DMOut;
	input		WB_MUX2Sel;
	output[31:0] MUX10Out;

	assign MUX10Out = WB_MUX2Sel? WB_DMOut : WB_MUX2Out;
endmodule

module mux11(
	vpn2, alu1out, MUX11_Sel,

	out
);
	input [18:0] vpn2, alu1out;
	input MUX11_Sel;

	output [18:0] out;

	assign out = MUX11_Sel ? vpn2 : alu1out;
endmodule

module mux12 (
	index, random, MUX12_Sel,

	out
);
	input [1:0] index, random;
	input MUX12_Sel;

	output [1:0] out;

	assign out = MUX12_Sel ? index : random;

endmodule

module mux13(
	input [31:0] 	Imm32,
	input [31:0] 	PC,
	input [31:0] 	RHLOut,
	input [31:0]	MULOut,
	input [2:0] 	EX_MUX2Sel,
	output reg [31:0] MUX13Out
);

	always@(*)
		case(EX_MUX2Sel)
			3'b000:	MUX13Out = RHLOut;
			3'b001: MUX13Out = Imm32;
			3'b110: MUX13Out = MULOut;
			default:MUX13Out = PC + 8;
		endcase

	/*  case(MUX2Sel)
			3'b000:	WD = RHLOut;
			3'b001: WD = Imm32;
			3'b010: WD = ALU1Out;
			3'b011: WD = PC + 8;
			3'b100: WD = DMOut;
			3'b101: WD = CP0Out;
			3'b110: WD = MULOut;
			3'b111: WD = SCOut;
	*/


endmodule

module mux14(
	RD1, shamt, ALU1Sel, 
	
	A
	);
	input[31:0] RD1;
	input[4:0] shamt;
	input ALU1Sel;
	output reg[31:0] A;

	always@(RD1, shamt, ALU1Sel)
		case(ALU1Sel)
			1'b0:	A = RD1;
			default:A = {27'd0, shamt};
		endcase	

endmodule