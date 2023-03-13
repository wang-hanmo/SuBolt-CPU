 `include "MacroDef.v"

 module ctrl(
	 	clk, rst, OP, Funct, rs, rt, CMPOut1, CMPOut2, EXE_isBranch,
 		Temp_ID_Excetion, IF_Flush,Temp_ID_ExcCode,

		MUX1Sel, MUX11Sel, MUX3Sel, RFWr, RHLWr, DMWr, DMRd, NPCOp, EXTOp, ALU1Op, ALU1Sel, ALU2Op, 
		RHLSel_Rd, RHLSel_Wr, DMSel, eret_flush, CP0WrEn, ID_ExcCode, ID_Exception, isBD, isBranch,
		CP0Rd, start, RHL_visit,dcache_en, BrType, J_Type
	);
	input clk;
	input rst;
	input [5:0] OP;
	input [5:0] Funct;
	input [4:0] rs;
	input [4:0] rt;
	input CMPOut1;
	input [1:0] CMPOut2;
	input EXE_isBranch;
	input Temp_ID_Excetion;
	input IF_Flush;
	input [4:0] Temp_ID_ExcCode;

	output reg [1:0] MUX1Sel;
	output reg [2:0] MUX11Sel;
	output reg MUX3Sel;
	output reg RFWr;
	output reg RHLWr;
	output reg DMWr;
	output reg DMRd;
	output reg RHLSel_Rd;
	output reg [1:0] NPCOp;
	output reg [1:0] EXTOp;
	output reg [3:0] ALU1Op;
	output reg ALU1Sel;
	output reg [1:0] ALU2Op;
	output reg [1:0] RHLSel_Wr;
	output reg [2:0] DMSel;
	output reg eret_flush;
	output reg CP0WrEn;
	output reg CP0Rd;
	output reg ID_Exception;
	output reg [4:0] ID_ExcCode;
	output isBD;
	output reg isBranch;
	output reg start;
	output reg RHL_visit;
	output reg dcache_en;
	output reg [1:0] BrType;

	wire ri;			//reserved instr		
	reg rst_sign;				

	reg B_cmp;
	reg[2:0] B_Type;
	output reg[1:0] J_Type;


	always @(posedge clk) begin
		if (!rst)
			rst_sign = 1'b1;
		else
			rst_sign = 1'b0;
		
	end

	assign ri =
		RFWr || RHLWr || DMWr || (OP == `R_type && (Funct == `break || Funct == `syscall)) ||
		(OP == `cop0) || isBranch;

	

	always @(OP or Funct) begin		/* the generation of eret_flush */
		if (OP == `cop0 && Funct == `eret)
			eret_flush = 1'b1;
		else
			eret_flush = 1'b0;
	end

	always @(OP or rs) begin		/* the generation of CP0WrEn */
		if (OP == `cop0 && rs == `mtc0)
			CP0WrEn = 1'b1;
		else
			CP0WrEn = 1'b0;
	end

	always @(OP or Funct or ri or rst or IF_Flush or Temp_ID_ExcCode
	or Temp_ID_Excetion or rst_sign) begin	/* the generation of Exception and ExcCode */
		if (Temp_ID_Excetion) begin
			ID_Exception = 1'b1;
			ID_ExcCode = Temp_ID_ExcCode;
		end
		else if (!ri && !rst_sign && !IF_Flush) begin
			ID_Exception = 1'b1;
			ID_ExcCode = `RI;
		end
		else if (OP == `R_type && Funct == `break) begin
			ID_Exception = 1'b1;
			ID_ExcCode = `Bp;
		end
		else if (OP == `R_type && Funct == `syscall) begin
			ID_Exception = 1'b1;
			ID_ExcCode = `Sys;
		end
		else begin
			ID_Exception = 1'b0;
			ID_ExcCode = 5'd0;
		end
	end

	always @(OP or Funct) begin		/* the genenration of isBranch */
		 case (OP)
			6'b000100: isBranch = 1;		/* BEQ */
			6'b000101: isBranch = 1;		/* BNE */
			6'b000001: isBranch = 1;		/* BGEZ, BLTZ, BGEZAL, BLTZAL */
			6'b000111: isBranch = 1;		/* BGTZ */
			6'b000110: isBranch = 1;		/* BLEZ */
			6'b000000:
			if (Funct == 6'b001000 || Funct == 6'b001001)	/* JR, JALR */
				isBranch = 1;
			else
				isBranch = 0;
			6'b000010: isBranch = 1;        /* J */
			6'b000011: isBranch = 1;        /* JAL */
			default: isBranch = 0;
		endcase
	end

	assign isBD = EXE_isBranch;		/* the generation of isBD */


//	always @(OP or Funct) begin		/* the genenration of B_JOp */
		// case (OP)
		//	6'b000100: B_JOp = 1;		/* BEQ */
		//	6'b000101: B_JOp = 1;		/* BNE */
		//	6'b000001: B_JOp = 1;		/* BGEZ, BLTZ, BGEZAL, BLTZAL */
		//	6'b000111: B_JOp = 1;		/* BGTZ */
		//	6'b000110: B_JOp = 1;		/* BLEZ */
		//	6'b000000:
		//	if (Funct == 6'b001000 || Funct == 6'b001001)	/* JR, JALR */
		//		B_JOp = 1;
		//	else
		//		B_JOp = 0;
		//	default:   B_JOp = 0;
	//	endcase
//	end 


	always @(OP or Funct or rt or rs) begin			/* the generation of RFWr */ 
		case (OP)
			6'b000000:
			case (Funct)
				6'b100000: RFWr = 1;	/* ADD */
				6'b100001: RFWr = 1;	/* ADDU */
				6'b100010: RFWr = 1;	/* SUB */
				6'b100011: RFWr = 1;	/* SUBU */
				6'b100101: RFWr = 1;	/* OR */
				6'b100100: RFWr = 1;	/* AND */
				6'b100111: RFWr = 1;	/* NOR */
				6'b100110: RFWr = 1;	/* XOR */
				6'b000100: RFWr = 1;	/* SLLV */
				6'b000000: RFWr = 1;	/* SLL */
				6'b000110: RFWr = 1;	/* SRLV */
				6'b000010: RFWr = 1;	/* SRL */
				6'b000111: RFWr = 1;	/* SRAV */
				6'b000011: RFWr = 1;	/* SRA */
				6'b101010: RFWr = 1;	/* SLT */
				6'b101011: RFWr = 1;	/* SLTU */
				6'b001001: RFWr = 1;	/* JALR */
				6'b010000: RFWr = 1;	/* MFHI */
				6'b010010: RFWr = 1;	/* MFLO */
				default: RFWr = 0;
			endcase
			6'b001000: RFWr = 1;		/* ADDI */
			6'b001001: RFWr = 1;		/* ADDUI */
			6'b001111: RFWr = 1;		/* LUI */
			6'b001101: RFWr = 1;		/* ORI */
			6'b001100: RFWr = 1;		/* ANDI */
			6'b001110: RFWr = 1;		/* XORI */
			6'b001010: RFWr = 1;		/* SLTI */
			6'b001011: RFWr = 1;		/* SLTIU */
			6'b000001: 
			if (rt == 5'b10001)
				RFWr = 1;		/* BGEZAL */
			else if (rt == 5'b10000)
				RFWr = 1;		/* BLTZAL */
			else
				RFWr = 0;
			6'b000011: RFWr = 1;		/* JAL */
			6'b100100: RFWr = 1;		/* LBU */
			6'b100000: RFWr = 1;		/* LB */
			6'b100101: RFWr = 1;		/* LHU */
			6'b100001: RFWr = 1;		/* LH */
			6'b100011: RFWr = 1;		/* LW */
			`cop0:
			if (rs == `mfc0)
				RFWr = 1;
			else
				RFWr = 0;
			default: RFWr = 0;
		endcase
	end


	always @(OP or Funct) begin			/* the generation of RHLWr */
		if (OP == 6'b000000) begin
			case (Funct)
				6'b010001: RHLWr = 1;	/* MTHI */
				6'b010011: RHLWr = 1;	/* MTLO */
				6'b011010: RHLWr = 1;	/* DIV */
				6'b011011: RHLWr = 1;	/* DIVU */
				6'b011000: RHLWr = 1;	/* MULT */
				6'b011001: RHLWr = 1;	/* MULTU */
				default: RHLWr = 0;
			endcase
		end
		else
			RHLWr = 0;
	end
	
	always @(OP or Funct) begin			/* the generation of start */
		if (OP == 6'b000000) begin
			case (Funct)
				6'b011010: start = 1;	/* DIV */
				6'b011011: start = 1;	/* DIVU */
				6'b011000: start = 1;	/* MULT */
				6'b011001: start = 1;	/* MULTU */
				default: start = 0;
			endcase
		end
		else
			start = 0;
	end
		
	always @(OP) begin			/* the generation of DMWr */
		case (OP)
			6'b101000: DMWr = 1;	/* SB */
			6'b101001: DMWr = 1;	/* SH */
			6'b101011: DMWr = 1;	/* SW */
			default: DMWr = 0;
		endcase
	end
	
	always @(OP) begin		/* the generation of DMRd */
		case (OP)
			6'b100100: DMRd = 1;		/* LBU */
			6'b100000: DMRd = 1;		/* LB */
			6'b100101: DMRd = 1;		/* LHU */
			6'b100001: DMRd = 1;		/* LH */
			6'b100011: DMRd = 1;		/* LW */
			default: DMRd = 0;
		endcase
	end

	always @(OP or rs) begin		/* the generation of CP0Rd */
		if (OP == `cop0 && rs == `mfc0)
			CP0Rd = 1'b1;
		else
			CP0Rd = 1'b0;
	end

	always @(OP or Funct) begin		/* the generation of ALU1Op */
		case (OP)
			6'b000000:
			case (Funct)
				6'b100000: ALU1Op = 4'b0000;	/* ADD */
				6'b100001: ALU1Op = 4'b1011;	/* ADDU */
				6'b100010: ALU1Op = 4'b0001;	/* SUB */
				6'b100011: ALU1Op = 4'b1100;	/* SUBU */
				6'b100101: ALU1Op = 4'b0010;	/* OR */
				6'b100100: ALU1Op = 4'b0011;	/* AND */
				6'b100111: ALU1Op = 4'b0100;	/* NOR */
				6'b100110: ALU1Op = 4'b0101;	/* XOR */
				6'b000100: ALU1Op = 4'b0110;	/* SLLV */
				6'b000000: ALU1Op = 4'b0110;	/* SLL */
				6'b000110: ALU1Op = 4'b0111;	/* SRLV */
				6'b000010: ALU1Op = 4'b0111;	/* SRL */
				6'b000111: ALU1Op = 4'b1000;	/* SRAV */
				6'b000011: ALU1Op = 4'b1000;	/* SRA */
				6'b101010: ALU1Op = 4'b1001;	/* SLT */
				6'b101011: ALU1Op = 4'b1010;	/* SLTU */
				default: ALU1Op = 4'b1111;
			endcase
			6'b001000: ALU1Op = 4'b0000;		/* ADDI */
			6'b001001: ALU1Op = 4'b1011;		/* ADDUI */
			6'b001101: ALU1Op = 4'b0010;		/* ORI */
			6'b001100: ALU1Op = 4'b0011;		/* ANDI */
			6'b001110: ALU1Op = 4'b0101;		/* XORI */
			6'b001010: ALU1Op = 4'b1001;		/* SLTI */
			6'b001011: ALU1Op = 4'b1010;		/* SLTIU */
			6'b101000: ALU1Op = 4'b0000;		/* SB */
			6'b101001: ALU1Op = 4'b0000;		/* SH */
			6'b101011: ALU1Op = 4'b0000;		/* SW */
			6'b100100: ALU1Op = 4'b0000;		/* LBU */
			6'b100000: ALU1Op = 4'b0000;		/* LB */
			6'b100101: ALU1Op = 4'b0000;		/* LHU */
			6'b100001: ALU1Op = 4'b0000;		/* LH */
			6'b100011: ALU1Op = 4'b0000;		/* LW */
			default: ALU1Op = 4'b1111;
		endcase
	end

	always @(OP or Funct) begin		/* the generation of ALU2Op */
		case (OP)
			6'b000000: 
			case (Funct)
				6'b011001: ALU2Op = 2'b00;		/* MULTU */
				6'b011000: ALU2Op = 2'b01;		/* MULT */
				6'b011011: ALU2Op = 2'b10;		/* DIVU */
				6'b011010: ALU2Op = 2'b11;		/* DIV */
				default: ALU2Op = 2'b00;
			endcase
			default: ALU2Op = 2'b00;
		endcase
	end

	always @(OP or Funct) begin		/* the generation of ALU1Sel */
		if (OP == 6'b000000) begin
			case (Funct)
				6'b000000: ALU1Sel = 1'b1;		/* SLL */
				6'b000011: ALU1Sel = 1'b1;		/* SRA */
				6'b000010: ALU1Sel = 1'b1;		/* SRL */
				default: ALU1Sel = 1'b0;
			endcase
		end
		else
			ALU1Sel = 1'b0;
	end
	
	always @(OP or Funct) begin		/* the generation of RHLSel_Wr */
		case (OP)
			6'b000000:
			case (Funct)
				6'b011001: RHLSel_Wr = 2'b10;		/* MULTU */
				6'b011000: RHLSel_Wr = 2'b10;		/* MULT */
				6'b011011: RHLSel_Wr = 2'b10;		/* DIVU */
				6'b011010: RHLSel_Wr = 2'b10;		/* DIV */
				6'b010001: RHLSel_Wr = 2'b01;		/* MTHI */
				6'b010011: RHLSel_Wr = 2'b00;		/* MTLO */
				default: RHLSel_Wr = 2'b00;
			endcase
			default: RHLSel_Wr = 2'b00;
		endcase
	end
	

	always @(OP or Funct) begin		/* the generation of RHL_visit */
		case (OP)
			6'b000000:
			case (Funct)
				6'b011001: RHL_visit = 1'b1;		/* MULTU */
				6'b011000: RHL_visit = 1'b1;		/* MULT */
				6'b011011: RHL_visit = 1'b1;		/* DIVU */
				6'b011010: RHL_visit = 1'b1;		/* DIV */
				6'b010001: RHL_visit = 1'b1;		/* MTHI */
				6'b010011: RHL_visit = 1'b1;		/* MTLO */
				6'b010000: RHL_visit = 1'b1;		/* MFHI */
				6'b010010: RHL_visit = 1'b1;		/* MFLO */
				default:   RHL_visit = 1'b0;
			endcase
			default: RHL_visit = 1'b0;
		endcase
	end

	always @(OP or Funct) begin		/* the generation of RHLSel_Rd */
		case (OP)
			6'b000000:
			case (Funct)
				6'b010000: RHLSel_Rd = 1'b1;		/* MFHI */
				6'b010010: RHLSel_Rd = 1'b0;		/* MFLO */
				default: RHLSel_Rd = 1'b0;
			endcase
			default: RHLSel_Rd = 1'b0;
		endcase
	end	
			
	always @(OP) begin		/* the generation of EXTOp */
		case (OP)
			6'b001000: EXTOp = 2'b01;			/* ADDI */
			6'b001001: EXTOp = 2'b01;			/* ADDUI */
			6'b001010: EXTOp = 2'b01;			/* SLTI */
			6'b001011: EXTOp = 2'b01;			/* SLTUI */
			6'b001101: EXTOp = 2'b00;			/* ORI */
			6'b001100: EXTOp = 2'b00;			/* ANDI */
			6'b001110: EXTOp = 2'b00;			/* XORI */
			6'b001111: EXTOp = 2'b10;			/* LUI */
			6'b101000: EXTOp = 2'b01;	      	/* SB */
			6'b101001: EXTOp = 2'b01;	      	/* SH */
			6'b101011: EXTOp = 2'b01;	   		/* SW */
			6'b100100: EXTOp = 2'b01;	  		/* LBU */
			6'b100000: EXTOp = 2'b01;	  		/* LB */
			6'b100101: EXTOp = 2'b01;	   		/* LHU */
			6'b100001: EXTOp = 2'b01;	   		/* LH */
			6'b100011: EXTOp = 2'b01;	        /* LW */
			default: EXTOp = 2'b00;
		endcase
	end

	always @(OP or rt or Funct or rs) begin		/* the generation of BrType */
		case (OP)
			6'b000011: BrType = 2'b11;		//JAL
			6'b000100,						//BEQ
			6'b000101: BrType = 2'b10;		//BNE
			6'b000001: 
			case (rt)
				5'b00001,					//BGEZ
				5'b00000: BrType = 2'b10;	//BLTZ
				5'b10001,					//BGEZAL
				5'b10000: BrType = 2'b11;	//BLTZAL
				default: BrType = 2'b00;
			endcase
			6'b000010,						//J
			6'b000110,						//BLEZ
			6'b000111: BrType = 2'b10;		//BGTZ
			6'b000000:
			case (Funct)
				6'b001000: 
				if (rs == 5'd31)
					BrType = 2'b01;	//JR $31
				else
					BrType = 2'b10;	//JR 其它间接跳转
				6'b001001: BrType = 2'b10;	//JALR 其它间接跳转
				default: BrType = 2'b00;
			endcase
			default: BrType = 2'b00;
		endcase
	end

	always @(OP or rt) begin							/* the generation of B_Type */
		case (OP)
			6'b000100: B_Type = 3'b000;				/* BEQ */
			6'b000101: B_Type = 3'b001;				/* BNE */
			6'b000001:
			case (rt)
				5'b00001: B_Type = 3'b010; 			/* BGEZ */
				5'b00000: B_Type = 3'b011;			/* BLTZ */
				5'b10001: B_Type = 3'b010;			/* BGEZAL */
				5'b10000: B_Type = 3'b011;			/* BLTZAL */
				default:  B_Type = 3'b111;
			endcase
			6'b000110: B_Type = 3'b100;				/* BLEZ */
			6'b000111: B_Type = 3'b101;				/* BGTZ */
			default:   B_Type = 3'b111;
		endcase
	end

	always @(OP or Funct) begin								/* the generation of J_Type */
		case (OP)
			6'b000010: J_Type = 2'b01;				/* J */
			6'b000011: J_Type = 2'b01;				/* JAL */
			6'b000000: 
			case (Funct)
				6'b001000: J_Type = 2'b10;			/* JR */
				6'b001001: J_Type = 2'b10;			/* JALR */
			default: J_Type = 2'b00;
			endcase
			default: J_Type = 2'b00;
		endcase
	end

	always @(OP or rt or Funct) begin							/* the generation of B_cmp */
		case (OP)
			6'b000100: B_cmp = 1'b1;				/* BEQ */
			6'b000101: B_cmp = 1'b1;				/* BNE */
			6'b000001:
			case (rt)
				5'b00001: B_cmp = 1'b1; 			/* BGEZ */
				5'b00000: B_cmp = 1'b1;				/* BLTZ */
				5'b10001: B_cmp = 1'b1;				/* BGEZAL */
				5'b10000: B_cmp = 1'b1;				/* BLTZAL */
				default: B_cmp = 1'b0;
			endcase
			6'b000010: B_cmp = 1'b0;				/* J */
			6'b000011: B_cmp = 1'b0;				/* JAL */
			6'b000110: B_cmp = 1'b1;				/* BLEZ */
			6'b000111: B_cmp = 1'b1;				/* BGTZ */
			6'b000000: 
			case (Funct)
				6'b001000: B_cmp = 1'b0;			/* JR */
				6'b001001: B_cmp = 1'b0;			/* JALR */
			default: B_cmp = 1'b0;
			endcase
			default: B_cmp = 1'b0;
		endcase
	end

	always@(B_cmp, B_Type, J_Type, CMPOut1, CMPOut2)
		if(B_cmp) begin
			case(B_Type)
				3'b000://BEQ
					if(CMPOut1 == 1'b0)	
						NPCOp = 2'b01;
					else 
						NPCOp = 2'b00;
				3'b001://BNE
					if(CMPOut1 == 1'b1)	
						NPCOp = 2'b01;
					else 
						NPCOp = 2'b00;
				3'b010://BGEZ,BGEZAL
					if (CMPOut2 != 2'b10)
						NPCOp = 2'b01;
					else
						NPCOp = 2'b00;
				3'b011://BLTZ,BLTZAL
					if (CMPOut2 == 2'b10)
						NPCOp = 2'b01;
					else
						NPCOp = 2'b00;
				3'b100://BLEZ
					if(CMPOut2 != 2'b01)
						NPCOp = 2'b01;
					else
						NPCOp = 2'b00;
				default://BGTZ
					if(CMPOut2 == 2'b01)
						NPCOp = 2'b01;
					else
						NPCOp = 2'b00;
			endcase
		end
		else begin
			case(J_Type)
				2'b01:	NPCOp = 2'b10;
				2'b10:	NPCOp = 2'b11;
				default:NPCOp = 2'b00;
			endcase
		end


	always @(OP or Funct) begin		/* the genenration of MUX1Sel */
		 case (OP)
			6'b000000: MUX1Sel = 2'b01;
			6'b000001: MUX1Sel = 2'b10;		/* BGEZAL or BLTZAL*/
			6'b000011: MUX1Sel = 2'b10;		/* JAL */
			default: MUX1Sel = 2'b00;		
		endcase
	end

	always @(OP or Funct or rs) begin		/* the genenration of MUX11Sel */
		 case (OP)
			6'b000000: 
			case (Funct)
				6'b010000: MUX11Sel = 3'b000;	/* MFHI */
				6'b010010: MUX11Sel = 3'b000;	/* MFLO */
				6'b001001: MUX11Sel = 3'b011;	/* JALR */
				6'b011001: MUX11Sel = 3'b000;	/* MULTU */
				6'b011000: MUX11Sel = 3'b000;	/* MULT */
				6'b011011: MUX11Sel = 3'b000;	/* DIVU */
				6'b011010: MUX11Sel = 3'b000;	/* DIV */
				default: MUX11Sel = 3'b010;
			endcase
			6'b100000: MUX11Sel = 3'b100;		/* LB */
			6'b100100: MUX11Sel = 3'b100;		/* LBU */
			6'b100001: MUX11Sel = 3'b100;		/* LH */
			6'b100101: MUX11Sel = 3'b100;		/* LHU */
			6'b100011: MUX11Sel = 3'b100;		/* LW */
			6'b000001: MUX11Sel = 3'b011;		/* BGEZAL or BLTZAL */
			6'b001111: MUX11Sel = 3'b001;		/* LUI */
			6'b000011: MUX11Sel = 3'b011;		/* JAL */
			`cop0:
			if (rs == `mfc0)
				MUX11Sel = 3'b101;
			else
				MUX11Sel = 3'b010;
			default: MUX11Sel = 3'b010;
		endcase
	end

	always @(OP or Funct) begin		/* the genenration of MUX3Sel */
		 case (OP)
			6'b000000: MUX3Sel = 0;
			default: MUX3Sel = 1;
		endcase
	end


	always @(OP or Funct) begin		/* the genenration of DMSel */
		 case (OP)
			6'b101000: DMSel = 3'b000;		/* SB */
			6'b101001: DMSel = 3'b001;		/* SH */
			6'b101011: DMSel = 3'b010;		/* SW */
			6'b100100: DMSel = 3'b011;		/* LBU */
			6'b100000: DMSel = 3'b100;		/* LB */
			6'b100101: DMSel = 3'b101;		/* LHU */
			6'b100001: DMSel = 3'b110;		/* LH */
			default:   DMSel = 3'b111;		/* LW */
		endcase
	end

	always @(OP) begin
		case(OP)
			6'b101000: dcache_en= 1'b1;	      	/* SB */
			6'b101001: dcache_en= 1'b1;	      	/* SH */
			6'b101011: dcache_en= 1'b1;	   		/* SW */
			6'b100100: dcache_en= 1'b1;	  		/* LBU */
			6'b100000: dcache_en= 1'b1;	  		/* LB */
			6'b100101: dcache_en= 1'b1;	   		/* LHU */
			6'b100001: dcache_en= 1'b1;	   		/* LH */
			6'b100011: dcache_en= 1'b1;	        /* LW */
			default: dcache_en = 1'b0;
	endcase
	end


endmodule