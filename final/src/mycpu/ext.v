module ext(
	Imm16, EXTOp,

	Imm32
);
	input [15:0]	Imm16;
	input [1:0] 	EXTOp;
	output reg[31:0]Imm32;

	always@(Imm16,EXTOp)
		case(EXTOp)
			2'b00:	Imm32 = {16'h0000,Imm16};		//zero extension
			2'b01:	if(Imm16[15])
						Imm32 = {16'hffff,Imm16};	//sign extension
					else
						Imm32 = {16'h0000,Imm16};
			default: Imm32 = {Imm16,16'h0000};		//high extension
		endcase

endmodule
