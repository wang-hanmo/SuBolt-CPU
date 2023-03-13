`include "MacroDef.v"

module PC(
		input clk,
		input rst,
		input wr,
		input flush,

		input[31:0] ret_addr,
		input[1:0] NPCOp,
		input[31:0] NPC_op00,
    	input[31:0] NPC_op01,
    	input[31:0] NPC_op10,
    	input flush_condition_00,
    	input flush_condition_01,
    	input flush_condition_10,
    	input flush_condition_11,
    	input[31:0] target_address_final,
    	input predict_final,
    	input ee,
    	input[31:0] NPC_ee,

		output reg[31:0] ret_addr_reg,
		output reg[1:0] NPCOp_reg,
		output reg[31:0] NPC_op00_reg,
    	output reg[31:0] NPC_op01_reg,
    	output reg[31:0] NPC_op10_reg,
    	output reg flush_condition_00_reg,
    	output reg flush_condition_01_reg,
    	output reg flush_condition_10_reg,
    	output reg flush_condition_11_reg,
    	output reg[31:0] target_address_final_reg,
    	output reg predict_final_reg,
    	output reg ee_reg,
    	output reg[31:0] NPC_ee_reg

);


	always@(posedge clk)
		if(!rst || flush) begin
			ret_addr_reg <= 32'd0;
			NPCOp_reg <= 2'b00;
			NPC_op00_reg <= 32'hbfc0_0000;
    		NPC_op01_reg <= 32'd0;
    		NPC_op10_reg <= 32'd0;
    		flush_condition_00_reg <= 1'b1;
    		flush_condition_01_reg <= 1'b0;
    		flush_condition_10_reg <= 1'b0;
    		flush_condition_11_reg <= 1'b0;
    		target_address_final_reg <= 32'd0;
    		predict_final_reg <= 1'b0;
    		ee_reg <= 1'b0;
    		NPC_ee_reg <= 32'd0;
		end
		else if(wr) begin
			ret_addr_reg <= ret_addr;
			NPCOp_reg <= NPCOp;
			NPC_op00_reg <= NPC_op00;
    		NPC_op01_reg <= NPC_op01;
    		NPC_op10_reg <= NPC_op10;
    		flush_condition_00_reg <= flush_condition_00;
    		flush_condition_01_reg <= flush_condition_01;
    		flush_condition_10_reg <= flush_condition_10;
    		flush_condition_11_reg <= flush_condition_11;
    		target_address_final_reg <= target_address_final;
    		predict_final_reg <= predict_final;
    		ee_reg <= ee;
    		NPC_ee_reg <= NPC_ee;
		end
endmodule


module PF_IF(
	clk, rst, wr, flush,
	NPC,PF_Exception,PF_ExcCode, PF_icache_valid,

	PC,IF_Exception,IF_ExcCode, IF_icache_valid,
	IF_stall
);
	input clk, rst, wr,flush;
	input PF_Exception;
	input [4:0] PF_ExcCode;
	input[31:0] NPC;
	input PF_icache_valid;

	output reg [31:0] PC;
	output reg IF_Exception;
	output reg [4:0] IF_ExcCode;
	output reg IF_icache_valid;
	output reg IF_stall;

    always@(posedge clk)
		if(!rst || flush)
		begin
			IF_ExcCode <= 5'b0;
			IF_Exception <= 1'b0;
			PC <= 32'hbfbf_fffc;
			IF_icache_valid <= 1'b0;
			IF_stall <= 1'b0;
		end
		else if(wr)
		begin
			IF_ExcCode <= PF_ExcCode;
			IF_Exception <= PF_Exception;
			PC <= NPC;
			IF_icache_valid <= PF_icache_valid;
			IF_stall <= 1'b0;
		end else
			IF_stall <= 1'b1;

endmodule


module IF_ID(
	clk, rst,IF_IDWr, IF_Flush, 
	PC, Instr, IF_Exception, IF_ExcCode,
	IF_BJOp,

	ID_PC, ID_Instr, Temp_ID_Excetion,Temp_ID_ExcCode,
	Imm26_forBP, Imm16_forEXT, Imm26_forDFF, op, func, shamt, CP0Addr, rs_forRF, 
	rs_forCtrl, rs_forDFF, rs_forBypass, rs_forStall, rt_forRF, rt_forCtrl, 
	rt_forDFF, rt_forBypass, rt_forStall, rt_forMUX1, rd_forMUX1,
	ID_BJOp, rs_forBypass_forCMP, rt_forBypass_forCMP
);
	input clk, rst,IF_IDWr, IF_Flush, IF_Exception;
	input[31:0] PC, Instr;
	input [4:0] IF_ExcCode;
	input IF_BJOp;

	output reg [31:0] ID_PC;
	output reg [31:0] ID_Instr;
	output reg Temp_ID_Excetion;
	output reg [4:0] Temp_ID_ExcCode;
	
	output reg[25:0] Imm26_forBP;
	output reg[15:0] Imm16_forEXT;
	output reg[25:0] Imm26_forDFF;
	output reg[5:0] op;
	output reg[5:0] func;
	output reg[4:0] shamt;
	output reg[7:0] CP0Addr;
	output reg[4:0] rs_forRF;
	output reg[4:0] rs_forCtrl;
	output reg[4:0] rs_forDFF;
	output reg[4:0] rs_forBypass;
	output reg[4:0] rs_forStall;
	output reg[4:0] rt_forRF;
	output reg[4:0] rt_forCtrl;
	output reg[4:0] rt_forDFF;
	output reg[4:0] rt_forBypass;
	output reg[4:0] rt_forStall;
	output reg[4:0] rt_forMUX1;
	output reg[4:0] rd_forMUX1;
	output reg ID_BJOp;
	output reg[4:0] rs_forBypass_forCMP;
	output reg[4:0] rt_forBypass_forCMP;

	always@(posedge clk)
		if(!rst || IF_Flush) begin
			ID_PC <= 32'h0000_0000;
			ID_Instr <= 32'h0000_0000;
			Temp_ID_Excetion <= 1'b0;
			Temp_ID_ExcCode <= 5'b0;
			Imm26_forBP <= 26'd0;
			Imm16_forEXT <= 16'd0;
			Imm26_forDFF <= 26'd0;
			op <= 6'd0;
			func <= 6'd0;
			shamt <= 5'd0;
			CP0Addr <= 8'd0;
			rs_forRF <= 5'd0;
			rs_forCtrl <= 5'd0;
			rs_forDFF <= 5'd0;
			rs_forBypass <= 5'd0;
			rs_forStall <= 5'd0;
			rt_forRF <= 5'd0;
			rt_forCtrl <= 5'd0;
			rt_forDFF <= 5'd0;
			rt_forBypass <= 5'd0;
			rt_forStall <= 5'd0;
			rt_forMUX1 <= 5'd0;
			rd_forMUX1 <= 5'd0;
			ID_BJOp <= 1'b0;
			rs_forBypass_forCMP <= 5'd0;
			rt_forBypass_forCMP <= 5'd0;
		end
		else if(IF_IDWr) begin
			ID_PC <= PC;
			ID_Instr <= Instr;
			Temp_ID_Excetion <= IF_Exception;
			Temp_ID_ExcCode <= IF_ExcCode;
			Imm26_forBP <= Instr[25:0];
			Imm16_forEXT <= Instr[15:0];
			Imm26_forDFF <= Instr[25:0];
			op <= Instr[31:26];
			func <= Instr[5:0];
			shamt <= Instr[10:6];
			CP0Addr <= {Instr[15:11], Instr[2:0]};
			rs_forRF <= Instr[25:21];
			rs_forCtrl <= Instr[25:21];
			rs_forDFF <= Instr[25:21];
			rs_forBypass <= Instr[25:21];
			rs_forStall <= Instr[25:21];
			rt_forRF <= Instr[20:16];
			rt_forCtrl <= Instr[20:16];
			rt_forDFF <= Instr[20:16];
			rt_forBypass <= Instr[20:16];
			rt_forStall <= Instr[20:16];
			rt_forMUX1 <= Instr[20:16];
			rd_forMUX1 <= Instr[15:11];
			ID_BJOp <= IF_BJOp;
			rs_forBypass_forCMP <= Instr[25:21];
			rt_forBypass_forCMP <= Instr[20:16];
		end

endmodule

module ID_EX(
	clk, rst, ID_EXWr,ID_Flush, RHLSel_Rd, PC, ALU1Op, ALU2Op, MUX1Out, MUX3Sel, ALU1Sel, DMWr, DMSel, 
	DMRd, RFWr, RHLWr, RHLSel_Wr, MUX11Sel, GPR_RS, GPR_RT, RS, RT, Imm32, shamt, 
	eret_flush, CP0WrEn, Exception, ExcCode, isBD, isBranch, CP0Addr, CP0Rd, start,ID_dcache_en,
	MUX4Sel, MUX5Sel,	ID_BrType, ID_Imm26, ID_NPCOp,
	ID_JType, MUX7Sel, MUX4Sel_forALU1, MUX5Sel_forALU1,

	EX_eret_flush, EX_CP0WrEn, EX_Exception, EX_ExcCode, EX_isBD, EX_isBranch, EX_RHLSel_Rd,
	EX_DMWr, EX_DMRd, EX_MUX3Sel, EX_ALU1Sel, EX_RFWr, EX_RHLWr, EX_ALU2Op, EX_RD, EX_RHLSel_Wr,
	EX_DMSel, EX_MUX11Sel, EX_ALU1Op, EX_RS, EX_RT, EX_shamt, EX_PC, EX_GPR_RS, EX_GPR_RT, 
	EX_Imm32, EX_CP0Addr, EX_CP0Rd, EX_start,EX_dcache_en,
	EX_MUX4Sel, EX_MUX5Sel, EX_BrType, EX_Imm26, EX_NPCOp,
	EX_GPR_RS_forALU1, EX_GPR_RT_forALU1,
	EX_JType, EX_MUX7Sel, EX_stall, EX_MUX4Sel_forALU1, EX_MUX5Sel_forALU1
);
	input clk, rst, ID_EXWr,ID_Flush, DMWr, DMRd, MUX3Sel, ALU1Sel, RFWr, RHLWr,RHLSel_Rd;
	input eret_flush;
	input CP0WrEn;
	input Exception;
	input [4:0] ExcCode;
	input isBD;
	input isBranch;
	input[1:0] ALU2Op, RHLSel_Wr;
	input[2:0] DMSel, MUX11Sel;
	input[3:0] ALU1Op;
	input[4:0] RS, RT, shamt, MUX1Out;
	input[31:0] PC, GPR_RS, GPR_RT, Imm32;
	input [7:0] CP0Addr;
	input CP0Rd;
	input start;
	input ID_dcache_en;
	input[1:0] MUX4Sel, MUX5Sel;
	input [1:0] ID_BrType;
	input [25:0] ID_Imm26;
	input [1:0] ID_NPCOp;
	input [1:0] ID_JType;
	input MUX7Sel;
	input[1:0] MUX4Sel_forALU1, MUX5Sel_forALU1;

	output reg EX_eret_flush;
	output reg EX_CP0WrEn;
	output reg EX_Exception;
	output reg [4:0] EX_ExcCode, EX_RD;
	output reg EX_isBD;
	output reg EX_isBranch;
	output reg EX_RHLSel_Rd;
	output reg EX_DMWr;
	output reg EX_DMRd;
	output reg EX_MUX3Sel;
	output reg EX_ALU1Sel;
	output reg EX_RFWr;
	output reg EX_RHLWr;
	output reg [1:0] EX_ALU2Op;
	output reg [1:0] EX_RHLSel_Wr;
	output reg [2:0] EX_DMSel;
	output reg [2:0] EX_MUX11Sel;
	output reg [3:0] EX_ALU1Op;
	output reg [4:0] EX_RS;
	output reg [4:0] EX_RT;
	output reg [4:0] EX_shamt;
	output reg [31:0] EX_PC, EX_GPR_RS, EX_GPR_RT, EX_Imm32;
	output reg [7:0] EX_CP0Addr;
	output reg EX_CP0Rd;
	output reg EX_start;
	output reg EX_dcache_en;
	output reg[1:0] EX_MUX4Sel, EX_MUX5Sel;
	output reg [1:0] EX_BrType;
	output reg [25:0] EX_Imm26;
	output reg [1:0] EX_NPCOp;

	output reg[31:0] EX_GPR_RS_forALU1;
	output reg[31:0] EX_GPR_RT_forALU1;

	output reg [1:0] EX_JType;
	output reg EX_MUX7Sel;
	output reg EX_stall;
	output reg[1:0] EX_MUX4Sel_forALU1, EX_MUX5Sel_forALU1;

	always@(posedge clk)
		if(!rst || ID_Flush) begin
			EX_eret_flush <= 1'b0;
			EX_CP0WrEn <= 1'b0;
			EX_Exception <= 1'b0;
			EX_ExcCode <= 5'd0;
			EX_isBD <= 1'b0;
			EX_isBranch <= 1'b0;
			EX_RHLSel_Rd <= 1'b0;
			EX_DMWr <= 1'b0;
			EX_DMRd <= 1'b0;
			EX_MUX3Sel <= 1'b0;
			EX_ALU1Sel <= 1'b0;
			EX_RFWr <= 1'b0;
			EX_RHLWr <= 1'b0;
			EX_ALU2Op <= 2'b00;
			EX_RD <= 5'd0;
			EX_RHLSel_Wr <= 2'b00;
			EX_DMSel <= 3'b000;
			EX_MUX11Sel <= 3'b000;
			EX_ALU1Op <= 4'h0;
			EX_RS <= 5'd0;
			EX_RT <= 5'd0;
			EX_shamt <= 5'd0;
			EX_PC <= 32'd0;
			EX_GPR_RS <= 32'd0;
			EX_GPR_RT <= 32'd0;
			EX_Imm32 <= 32'd0;
			EX_CP0Addr <= 8'd0;
			EX_CP0Rd <= 1'b0;
			EX_start <= 1'b0;
			EX_dcache_en<=1'b0;
			EX_MUX4Sel <= 2'b00;
			EX_MUX5Sel <= 2'b00;
			EX_BrType <= 2'b00;
			EX_NPCOp <= 2'b00;
			EX_Imm26 <= 26'd0;
			EX_GPR_RS_forALU1 <= 32'd0;
			EX_GPR_RT_forALU1 <= 32'd0;
			EX_JType <= 2'b00;
			EX_MUX7Sel <= 1'b0;
			EX_stall <= 1'b0;
			EX_MUX4Sel_forALU1 <= 2'b00;
			EX_MUX5Sel_forALU1 <= 2'b00;
		end
		else if(ID_EXWr) 
		begin
			EX_eret_flush <= eret_flush;
			EX_CP0WrEn <= CP0WrEn;
			EX_Exception <= Exception;
			EX_ExcCode <= ExcCode;
			EX_isBD <= isBD;
			EX_isBranch <= isBranch;
			EX_RHLSel_Rd <= RHLSel_Rd;
			EX_DMWr <= DMWr;
			EX_DMRd <= DMRd;
			EX_MUX3Sel <= MUX3Sel;
			EX_ALU1Sel <= ALU1Sel;
			EX_RFWr <= RFWr;
			EX_RHLWr <= RHLWr;
			EX_ALU2Op <= ALU2Op;
			EX_RD <= MUX1Out;
			EX_RHLSel_Wr <= RHLSel_Wr;
			EX_DMSel <= DMSel;
			EX_MUX11Sel <= MUX11Sel;
			EX_ALU1Op <= ALU1Op;
			EX_RS <= RS;
			EX_RT <= RT;
			EX_shamt <= shamt;
			EX_PC <= PC;
			EX_GPR_RS <= GPR_RS;
			EX_GPR_RT <= GPR_RT;
			EX_Imm32 <= Imm32;
			EX_CP0Addr <= CP0Addr;
			EX_CP0Rd <= CP0Rd;
			EX_start <= start;
			EX_dcache_en <= ID_dcache_en;
			EX_MUX4Sel <= MUX4Sel;
			EX_MUX5Sel <= MUX5Sel;
			EX_BrType <= ID_BrType;
			EX_NPCOp <= ID_NPCOp;
			EX_Imm26 <= ID_Imm26;
			EX_GPR_RS_forALU1 <= GPR_RS;
			EX_GPR_RT_forALU1 <= GPR_RT;
			EX_JType <= ID_JType;
			EX_MUX7Sel <= MUX7Sel;
			EX_stall <= 1'b0;
			EX_MUX4Sel_forALU1 <= MUX4Sel_forALU1;
			EX_MUX5Sel_forALU1 <= MUX5Sel_forALU1;
		end else
			EX_stall <= 1'b1;
endmodule

module EX_MEM1(
		clk, rst, EX_MEM1Wr, EX_PC, DMWr, DMSel, DMRd, RFWr, MUX11Out, 
        ALU1Out, GPR_RT, RD, EX_Flush, eret_flush, CP0WrEn, Exception, ExcCode, isBD,
        CP0Addr, CP0Rd, EX_dcache_en, Overflow, MUX6Sel, MUX2Sel, MUX10Sel,

		MEM1_DMWr, MEM1_DMRd, MEM1_RFWr,MEM1_eret_flush, MEM1_CP0WrEn, MEM1_Exception, MEM1_ExcCode, 
        MEM1_isBD, MEM1_DMSel, MEM1_RD, MEM1_PC, MEM1_MUX11Out, MEM1_ALU1Out, MEM1_GPR_RT, 
        MEM1_CP0Addr, MEM1_CP0Rd, MEM1_dcache_en, MEM1_Overflow,
		MEM1_ALU1Out_forExPa, MEM1_MUX6Sel, MEM1_MUX2Sel, MEM1_MUX10Sel, MEM1_MUX6Sel_forEX
	);
	input clk, rst, EX_MEM1Wr,EX_Flush, DMWr, DMRd, RFWr;
	input Overflow;
	input eret_flush;
	input CP0WrEn;
	input Exception;
	input [4:0] ExcCode;
	input isBD;
	input[2:0] DMSel;
	input[4:0] RD;
	input[31:0] EX_PC, MUX11Out,ALU1Out, GPR_RT;
	input [7:0] CP0Addr;
	input CP0Rd;
	input EX_dcache_en;
	input MUX6Sel, MUX2Sel, MUX10Sel;

	output reg MEM1_DMWr, MEM1_DMRd, MEM1_RFWr;
	output reg MEM1_eret_flush;
	output reg MEM1_CP0WrEn;
	output reg MEM1_Exception;
	output reg [4:0] MEM1_ExcCode;
	output reg MEM1_isBD;
	output reg[2:0] MEM1_DMSel;
	output reg[4:0] MEM1_RD;
	output reg[31:0] MEM1_ALU1Out;
	output reg[31:0] MEM1_PC, MEM1_MUX11Out, MEM1_GPR_RT;
	output reg [7:0] MEM1_CP0Addr;
	output reg MEM1_CP0Rd;
	output reg MEM1_dcache_en;
	output reg MEM1_Overflow;
	output reg[31:0] MEM1_ALU1Out_forExPa;
	output reg MEM1_MUX6Sel, MEM1_MUX2Sel, MEM1_MUX10Sel, MEM1_MUX6Sel_forEX;

	always@(posedge clk)
		if(!rst || EX_Flush) begin
			MEM1_DMWr <= 1'b0;
			MEM1_DMRd <= 1'b0;
			MEM1_RFWr <= 1'b0;
			MEM1_eret_flush <= 1'b0;
			MEM1_CP0WrEn <= 1'b0;
			MEM1_isBD <= 1'b0;
			MEM1_DMSel <= 3'd0;
			MEM1_RD <= 5'd0;
			MEM1_PC <= 32'd0;
			MEM1_MUX11Out <= 32'd0;
			MEM1_ALU1Out <= 32'd0;
			MEM1_GPR_RT <= 32'd0;
			MEM1_CP0Addr <= 8'd0;
			MEM1_CP0Rd <= 1'b0;
			MEM1_dcache_en<=1'b0;
			MEM1_ExcCode <= 5'd0;
			MEM1_Exception <= 1'b0;
			MEM1_Overflow <= 1'b0;
			MEM1_ALU1Out_forExPa <= 32'd0;
			MEM1_MUX6Sel <= 1'b0;
			MEM1_MUX2Sel <= 1'b0;
			MEM1_MUX10Sel <= 1'b0;
			MEM1_MUX6Sel_forEX <= 1'b0;
		end
		else if (EX_MEM1Wr) begin
			MEM1_DMWr <= DMWr;
			MEM1_DMRd <= DMRd;
			MEM1_RFWr <= RFWr;
			MEM1_eret_flush <= eret_flush;
			MEM1_CP0WrEn <= CP0WrEn;
			MEM1_isBD <= isBD;
			MEM1_DMSel <= DMSel;
			MEM1_RD <= RD;
			MEM1_PC <= EX_PC;
			MEM1_MUX11Out <= MUX11Out;
			MEM1_ALU1Out <= ALU1Out;
			MEM1_GPR_RT <= GPR_RT;
			MEM1_CP0Addr <= CP0Addr;
			MEM1_CP0Rd <= CP0Rd;
			MEM1_dcache_en <= EX_dcache_en;
			MEM1_ExcCode <= ExcCode;
			MEM1_Exception <= Exception;
			MEM1_Overflow <= Overflow;
			MEM1_ALU1Out_forExPa <= ALU1Out;
			MEM1_MUX6Sel <= MUX6Sel;
			MEM1_MUX2Sel <= MUX2Sel;
			MEM1_MUX10Sel <= MUX10Sel;
			MEM1_MUX6Sel_forEX <= MUX6Sel;
		end

endmodule

module MEM1_MEM2(clk, rst, PC, RFWr, MUX2Sel, MUX6Out, RD, MEM1_Flush, 
		MUX10Sel, CP0Out, MEM1_MEM2Wr, DMSel, cache_sel, DMWen, Exception,
        eret_flush, uncache_valid, DMen, Paddr, MEM1_dCache_wstrb, GPR_RT, DMRd, MEM1_rstrb,

		MEM2_RFWr,MEM2_MUX2Sel, MEM2_RD, MEM2_PC, MEM2_MUX10Sel, MEM2_MUX6Out, MEM2_CP0Out,
        MEM2_DMSel, MEM2_cache_sel, MEM2_DMWen, MEM2_Exception, MEM2_eret_flush,
		MEM2_uncache_valid, MEM2_DMen, MEM2_Paddr, MEM2_unCache_wstrb, MEM2_GPR_RT, 
		MEM2_DMRd, MEM2_rstrb, MEM2_MUX2Sel_forEX
		);
	input clk;
	input rst;
	input MEM1_Flush;
	input MEM1_MEM2Wr;

	input[31:0] PC;
	input RFWr;
	input[31:0] MUX6Out;
	input[4:0] RD;
	input[31:0] CP0Out;
	input[2:0] DMSel;
	input cache_sel;
	input DMWen;
	input Exception;
	input eret_flush;
	input uncache_valid;
	input DMen;
	input[31:0] Paddr;
	input[3:0] MEM1_dCache_wstrb;
	input[31:0] GPR_RT;
	input DMRd;
	input[3:0] MEM1_rstrb;
	input MUX2Sel, MUX10Sel;

	output reg[31:0] MEM2_PC;
	output reg MEM2_RFWr;
	output reg[31:0] MEM2_MUX6Out;	
	output reg[4:0] MEM2_RD;
	output reg[31:0] MEM2_CP0Out;
	output reg[2:0] MEM2_DMSel;
	output reg MEM2_cache_sel;
	output reg MEM2_DMWen;
	output reg MEM2_Exception;
	output reg MEM2_eret_flush;
	output reg MEM2_uncache_valid;
	output reg MEM2_DMen;
	output reg[31:0] MEM2_Paddr;
	output reg[3:0] MEM2_unCache_wstrb;
	output reg[31:0] MEM2_GPR_RT;
	output reg MEM2_DMRd;
	output reg[3:0] MEM2_rstrb;
	output reg MEM2_MUX2Sel, MEM2_MUX10Sel, MEM2_MUX2Sel_forEX;

	always@(posedge clk)
		if(!rst || MEM1_Flush) begin
			MEM2_PC <= 32'd0;
			MEM2_RFWr <= 1'b0;
			MEM2_MUX6Out <= 32'd0;
			MEM2_RD <= 5'd0;
			MEM2_CP0Out <= 32'd0;
			MEM2_DMSel <= 3'd0;
			MEM2_cache_sel <= 1'b0;
			MEM2_DMWen <= 1'b0;
			MEM2_Exception <= 1'b0;
			MEM2_eret_flush <= 1'b0;
			MEM2_uncache_valid <= 1'b0;
			MEM2_DMen <= 1'b0;
			MEM2_Paddr <= 32'd0;
			MEM2_unCache_wstrb <= 4'd0;
			MEM2_GPR_RT <= 32'd0;
			MEM2_DMRd <= 1'b0;
			MEM2_rstrb <= 4'h0;
			MEM2_MUX2Sel <= 1'b0;
			MEM2_MUX10Sel <= 1'b0;
			MEM2_MUX2Sel_forEX <= 1'b0;
		end
		else if(MEM1_MEM2Wr) begin
			MEM2_PC <= PC;
			MEM2_RFWr <= RFWr;
			MEM2_MUX6Out <= MUX6Out;
			MEM2_RD <= RD;
			MEM2_CP0Out <= CP0Out;
			MEM2_DMSel <= DMSel;
			MEM2_cache_sel <= cache_sel;
			MEM2_DMWen <= DMWen;
			MEM2_Exception <= Exception;
			MEM2_eret_flush <= eret_flush;
			MEM2_uncache_valid <= uncache_valid;
			MEM2_DMen <= DMen;
			MEM2_Paddr <= Paddr;
			MEM2_unCache_wstrb <= MEM1_dCache_wstrb;
			MEM2_GPR_RT <= GPR_RT;
			MEM2_DMRd <= DMRd;
			MEM2_rstrb <= MEM1_rstrb;
			MEM2_MUX2Sel <= MUX2Sel;
			MEM2_MUX10Sel <= MUX10Sel;
			MEM2_MUX2Sel_forEX <= MUX2Sel;
		end
endmodule

module MEM2_WB(
	clk, rst,MEM2_WBWr, MEM2_Flush,
	PC, MUX2Out, MUX10Sel, RD, RFWr, DMOut,

	WB_PC, WB_MUX2Out, WB_MUX10Sel, WB_RD, WB_RFWr, WB_DMOut,
	WB_MUX10Sel_forEX
	);
	input clk;
	input rst;
	input MEM2_WBWr;
	input MEM2_Flush;


	input[31:0] PC;
	input[31:0] MUX2Out;
	input MUX10Sel;
	input[4:0] RD;
	input RFWr;
	input[31:0] DMOut;

	output reg[31:0] WB_PC;
	output reg[31:0] WB_MUX2Out;
	output reg WB_MUX10Sel;
	output reg[4:0] WB_RD;
	output reg WB_RFWr;
	output reg[31:0] WB_DMOut;
	output reg WB_MUX10Sel_forEX;

	always@(posedge clk)
		if(!rst || MEM2_Flush) begin
			WB_PC <= 32'd0;
			WB_MUX2Out <= 32'd0;
			WB_MUX10Sel <= 1'b0;
			WB_RD <= 5'd0;
			WB_RFWr <= 1'b0;
			WB_DMOut <= 32'd0;
			WB_MUX10Sel_forEX <= 1'b0;
		end
		else if(MEM2_WBWr) begin
			WB_PC <= PC;
			WB_MUX2Out <= MUX2Out;
			WB_MUX10Sel <= MUX10Sel;
			WB_RD <= RD;
			WB_RFWr <= RFWr;
			WB_DMOut <= DMOut;
			WB_MUX10Sel_forEX <= MUX10Sel;
		end

endmodule