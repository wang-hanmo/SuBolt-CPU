`include "MacroDef.v"

module PC(
		input 				clk,
		input 				rst,
		input 				wr,
		input 				flush,

		input [31:0] 		ret_addr,
		input [1:0] 		NPCOp,
		input [31:0] 		NPC_op00,
    	input [31:0] 		NPC_op01,
    	input [31:0] 		NPC_op10,
    	input 				flush_condition_00,
    	input 				flush_condition_01,
    	input 				flush_condition_10,
    	input 				flush_condition_11,
    	input [31:0] 		target_addr_final,
    	input 				ee,
    	input [31:0] 		NPC_ee,

		output reg [31:0] 	ret_addr_reg,
		output reg [1:0] 	NPCOp_reg,
		output reg [31:0] 	NPC_op00_reg,
    	output reg [31:0] 	NPC_op01_reg,
    	output reg [31:0] 	NPC_op10_reg,
    	output reg 			flush_condition_00_reg,
    	output reg 			flush_condition_01_reg,
    	output reg 			flush_condition_10_reg,
    	output reg 			flush_condition_11_reg,
    	output reg [31:0] 	target_addr_final_reg,
    	output reg 			ee_reg,
    	output reg [31:0] 	NPC_ee_reg

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
    		target_addr_final_reg <= 32'd0;
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
    		target_addr_final_reg <= target_addr_final;
    		ee_reg <= ee;
    		NPC_ee_reg <= NPC_ee;
		end
endmodule

module PF_IF(
	clk,rst,wr,PF_PC,PF_Exception,PF_ExcCode,PF_TLBRill_Exc,
	PF_TLB_Exc, invalid, icache_sel, uncache_valid,PPC,PF_Flush,

	IF_PC,IF_Exception,IF_ExcCode,IF_TLBRill_Exc,IF_TLB_Exc,
	IF_invalid, IF_icache_sel, IF_uncache_valid, IF_PPC
);
	input 			clk;
	input 			rst;
	input 			wr;
	input 			PF_Exception;
	input [4:0] 	PF_ExcCode;
	input [31:0] 	PPC;
	input [31:0] 	PF_PC;
	input 			PF_TLBRill_Exc;
	input 			PF_TLB_Exc;
	input 			invalid;
	input 			icache_sel;
	input 			uncache_valid;
	input 			PF_Flush;

	output reg [31:0] IF_PC;
	output reg [31:0] IF_PPC;
	output reg 		IF_Exception;
	output reg [4:0] IF_ExcCode;
	output reg 		IF_TLB_Exc;
	output reg 		IF_TLBRill_Exc;
	output reg 		IF_invalid;
	output reg 		IF_icache_sel;
	output reg 		IF_uncache_valid;

    always@(posedge clk)
		if(!rst | PF_Flush)
		begin
			IF_ExcCode <= 5'b0;
			IF_Exception <= 1'b0;
			IF_PC <= 32'hbfbf_fffc;
			IF_TLBRill_Exc <= 1'b0;
			IF_TLB_Exc <= 1'b0;
			IF_invalid <= 1'b0;
			IF_icache_sel <= 1'b0;
			IF_uncache_valid <= 1'b0;
			IF_PPC <= 32'd0;
		end
		else if(wr)
		begin
			IF_ExcCode <= PF_ExcCode;
			IF_Exception <= PF_Exception;
			IF_PC <= PF_PC;
			IF_TLBRill_Exc <= PF_TLBRill_Exc;
			IF_TLB_Exc <= PF_TLB_Exc;
			IF_invalid <= invalid;
			IF_icache_sel <= icache_sel;
			IF_uncache_valid <= uncache_valid;
			IF_PPC <= PPC;
		end

endmodule


module IF_ID(
	input 			clk,
	input 			rst,
	input 			IF_IDWr,
	input 			IF_Flush,
	input 			IF_Exception,
	input [31:0] 	Instr,
	input [31:0] 	IF_PC,
	input [4:0] 	IF_ExcCode,
	input 			IF_TLBRill_Exc,
	input 			IF_TLB_Exc,
	input			IF_BJOp,
	input [31:0]	EPC,

	output reg [31:0] 	ID_PC,
	output reg [31:0]	ID_Instr,
	output reg 			Temp_ID_Excetion,
	output reg [4:0] 	Temp_ID_ExcCode,
	output reg 			ID_TLBRill_Exc,
	output reg 			ID_TLB_Exc,
	output reg      	ID_BJOp,
	output reg [25:0] 	Imm26_forBP,
	output reg [15:0] 	Imm16_forEXT,
	output reg [25:0] 	Imm26_forDFF,
	output reg [5:0] 	op,
	output reg [5:0] 	func,
	output reg [4:0] 	shamt,
	output reg [7:0] 	CP0Addr,
	output reg [4:0] 	rs_forRF,
	output reg [4:0] 	rs_forCtrl,
	output reg [4:0] 	rs_forDFF,
	output reg [4:0] 	rs_forBypass,
	output reg [4:0] 	rs_forStall,
	output reg [4:0] 	rt_forRF,
	output reg [4:0] 	rt_forCtrl,
	output reg [4:0] 	rt_forDFF,
	output reg [4:0] 	rt_forBypass,
	output reg [4:0] 	rt_forStall,
	output reg [4:0] 	rt_forMUX1,
	output reg [4:0] 	rd_forMUX1,
	output reg [4:0] 	rs_forBypass_forCMP,
	output reg [4:0] 	rt_forBypass_forCMP
);


	always@(posedge clk)
		if(!rst || IF_Flush) begin
			ID_PC <= EPC;
			ID_Instr <= 32'h0000_0000;
			Temp_ID_Excetion <= 1'b0;
			Temp_ID_ExcCode <= 5'b0;
			ID_TLBRill_Exc <= 1'b0;
			ID_TLB_Exc <= 1'b0;
			ID_BJOp <= 1'b0;
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
			rs_forBypass_forCMP <= 5'd0;
			rt_forBypass_forCMP <= 5'd0;
		end
		else if(IF_IDWr) begin
			ID_PC <= IF_PC;
			ID_Instr <= Instr;
			Temp_ID_Excetion <= IF_Exception;
			Temp_ID_ExcCode <= IF_ExcCode;
			ID_TLBRill_Exc <= IF_TLBRill_Exc;
			ID_TLB_Exc <= IF_TLB_Exc;
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
	input 			clk,
	input 			rst,
	input 			ID_EXWr,
	input 			ID_Flush,
	input 			DMWr,
	input 			DMRd,
	input 			MUX3Sel,
	input 			ALU1Sel,
	input 			RFWr,
	input 			RHLWr,
	input 			RHLSel_Rd,
	input 			eret_flush,
	input 			CP0WrEn,
	input 			Exception,
	input [4:0] 	ExcCode,
	input 			isBD,
	input 			isBranch,
	input [1:0] 	RHLSel_Wr,
	input [1:0] 	MUX1Sel,
	input [3:0] 	ALU2Op,
	input [2:0] 	MUX2Sel,
	input [3:0] 	DMSel,
	input [4:0] 	ALU1Op,
	input [4:0] 	RS,
	input [4:0]		RT,
	input [4:0]		RD,
	input [4:0]		shamt,
	input [31:0]	PC,
	input [31:0] 	GPR_RS,
	input [31:0] 	GPR_RT,
	input [31:0] 	Imm32,
	input [7:0] 	CP0Addr,
	input 			CP0Rd,
	input 			start,
	input 			ID_dcache_en,
	input 			ID_TLBRill_Exc,
	input 			ID_TLB_Exc,
	input 			ID_MUX11Sel,
	input 			ID_MUX12Sel,
	input 			ID_tlb_searchen,
	input 			TLB_flush,
	input 			TLB_writeen,
	input 			TLB_readen,
	input 			LL_signal,
	input 			SC_signal,
	input 			icache_valid_CI,
	input 			icache_op_CI,
	input 			dcache_valid_CI,
	input [1:0] 	dcache_op_CI,
	input 			ID_WAIT_OP,
	input [1:0]		ID_BrType,
	input [1:0]		ID_JType,
	input [1:0]		ID_NPCOp,
	input			MUX7Sel,
	input [25:0]	ID_Imm26,
	input [1:0]		MUX4Sel,
	input [1:0]		MUX5Sel,
	input [1:0] 	MUX4Sel_forALU1,
	input [1:0]		MUX5Sel_forALU1,
	input [4:0]		ID_MUX1Out,
	input [31:0]	ID_MUX3Out,
	input  			Branch_flush,
	input 			ID_isBL,
	input [31:0]	EPC,
	input [31:0]	ID_Instr,

	output reg 			EX_eret_flush,
	output reg 			EX_CP0WrEn,
	output reg 			EX_Exception,
	output reg [4:0] 	EX_ExcCode,
	output reg 			EX_isBD,
	output reg 			EX_isBranch,
	output reg 			EX_RHLSel_Rd,
	output reg 			EX_DMWr,
	output reg 			EX_DMRd,
	output reg 			EX_MUX3Sel,
	output reg 			EX_ALU1Sel,
	output reg 			EX_RFWr,
	output reg 			EX_RHLWr,
	output reg [3:0] 	EX_ALU2Op,
	output reg [1:0] 	EX_MUX1Sel,
	output reg [1:0] 	EX_RHLSel_Wr,
	output reg [3:0] 	EX_DMSel,
	output reg [2:0] 	EX_MUX2Sel,
	output reg [4:0] 	EX_ALU1Op,
	output reg [4:0] 	EX_RS,
	output reg [4:0] 	EX_RT,
	output reg [4:0] 	EX_RD,
	output reg [4:0] 	EX_shamt,
	output reg [31:0]	EX_PC,
	output reg [31:0]	EX_GPR_RS,
	output reg [31:0]	EX_GPR_RT,
	output reg [31:0]	EX_Imm32,
	output reg [7:0]	EX_CP0Addr,
	output reg 			EX_CP0Rd,
	output reg 			EX_start,
	output reg 			EX_dcache_en,
	output reg 			EX_TLB_Exc,
	output reg 			EX_TLBRill_Exc,
	output reg 			EX_MUX11Sel,
	output reg 			EX_tlb_searchen,
	output reg 			EX_MUX12Sel,
	output reg 			EX_TLB_flush,
	output reg 			EX_TLB_writeen,
	output reg 			EX_TLB_readen,
	output reg 			EX_LL_signal,
	output reg 			EX_SC_signal,
	output reg 			EX_icache_valid_CI,
	output reg 			EX_icache_op_CI,
	output reg 			EX_dcache_valid_CI,
	output reg [1:0]	EX_dcache_op_CI,
	output reg  		EX_WAIT_OP,
	output reg [1:0]	EX_BrType,
	output reg [1:0]	EX_JType,
	output reg [1:0]	EX_NPCOp,
	output reg 			EX_MUX7Sel,
	output reg [25:0]	EX_Imm26,
	output reg 			EX_stall,
	output reg [1:0]	EX_MUX4Sel,
	output reg [1:0]	EX_MUX5Sel,
	output reg [31:0] 	EX_GPR_RS_forALU1,
	output reg [31:0] 	EX_GPR_RT_forALU1,
	output reg [1:0]	EX_MUX4Sel_forALU1, 
	output reg [1:0]	EX_MUX5Sel_forALU1,
	output reg [4:0]	EX_MUX1Out,
	output reg [31:0]	EX_MUX3Out,
	output reg  		EX_Branch_flush,
	output reg  		EX_isBL,
	output reg [31:0]	EX_Instr
);


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
			EX_ALU2Op <= 4'b0;
			EX_MUX1Sel <= 2'b00;
			EX_RHLSel_Wr <= 2'b00;
			EX_DMSel <= 4'b000;
			EX_MUX2Sel <= 3'b000;
			EX_ALU1Op <= 5'h0;
			EX_RS <= 5'd0;
			EX_RT <= 5'd0;
			EX_RD <= 5'd0;
			EX_shamt <= 5'd0;
			EX_PC <= EPC;
			EX_GPR_RS <= 32'd0;
			EX_GPR_RT <= 32'd0;
			EX_Imm32 <= 32'd0;
			EX_CP0Addr <= 8'd0;
			EX_CP0Rd <= 1'b0;
			EX_start <= 1'b0;
			EX_dcache_en<=1'b0;
			EX_TLBRill_Exc <= 1'b0;
			EX_MUX11Sel <= 1'b0;
			EX_MUX12Sel <= 1'b0;
			EX_tlb_searchen <= 1'b0;
			EX_TLB_Exc <= 1'b0;
			EX_TLB_flush <= 1'b0;
			EX_TLB_writeen <= 1'b0;
			EX_TLB_readen <= 1'b0;
			EX_LL_signal <= 1'b0;
			EX_SC_signal <= 1'b0;
			EX_icache_valid_CI <= 1'b0;
			EX_icache_op_CI <= 1'b0;
			EX_dcache_valid_CI <= 1'b0;
			EX_dcache_op_CI <= 2'b00;
			EX_WAIT_OP <= 1'b0;
			EX_BrType <= 2'b00;
			EX_JType <= 2'b00;
			EX_NPCOp <= 2'b00;
			EX_MUX7Sel <= 1'b0;
			EX_Imm26 <= 26'd0;
			EX_stall <= 1'b0;
			EX_MUX4Sel <= 2'b00;
			EX_MUX5Sel <= 2'b00;
			EX_GPR_RS_forALU1 <= 32'd0;
			EX_GPR_RT_forALU1 <= 32'd0;
			EX_MUX4Sel_forALU1 <= 2'b00;
			EX_MUX5Sel_forALU1 <= 2'b00;	
			EX_MUX1Out <= 5'd0;		
			EX_MUX3Out <= 32'd0;
			EX_Branch_flush <= 1'b0;
			EX_isBL <= 1'b0;
			EX_Instr <= 32'd0;
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
			EX_MUX1Sel <= MUX1Sel;
			EX_RHLSel_Wr <= RHLSel_Wr;
			EX_DMSel <= DMSel;
			EX_MUX2Sel <= MUX2Sel;
			EX_ALU1Op <= ALU1Op;
			EX_RS <= RS;
			EX_RT <= RT;
			EX_RD <= RD;
			EX_shamt <= shamt;
			EX_PC <= PC;
			EX_GPR_RS <= GPR_RS;
			EX_GPR_RT <= GPR_RT;
			EX_Imm32 <= Imm32;
			EX_CP0Addr <= CP0Addr;
			EX_CP0Rd <= CP0Rd;
			EX_start <= start;
			EX_dcache_en <= ID_dcache_en;
			EX_TLBRill_Exc <= ID_TLBRill_Exc;
			EX_MUX11Sel <= ID_MUX11Sel;
			EX_MUX12Sel <= ID_MUX12Sel;
			EX_tlb_searchen <= ID_tlb_searchen;
			EX_TLB_Exc <= ID_TLB_Exc;
			EX_TLB_flush <= TLB_flush;
			EX_TLB_writeen <= TLB_writeen;
			EX_TLB_readen <= TLB_readen;
			EX_LL_signal <= LL_signal;
			EX_SC_signal <= SC_signal;
			EX_icache_valid_CI <= icache_valid_CI;
			EX_icache_op_CI <= icache_op_CI;
			EX_dcache_valid_CI <= dcache_valid_CI;
			EX_dcache_op_CI <= dcache_op_CI;
			EX_WAIT_OP  <=  ID_WAIT_OP;
			EX_BrType <= ID_BrType;
			EX_JType <= ID_JType;
			EX_MUX7Sel <= MUX7Sel;
			EX_Imm26 <= ID_Imm26;
			EX_NPCOp <= ID_NPCOp;
			EX_stall <= 1'b0;
			EX_MUX4Sel <= MUX4Sel;
			EX_MUX5Sel <= MUX5Sel;
			EX_GPR_RS_forALU1 <= GPR_RS;
			EX_GPR_RT_forALU1 <= GPR_RT;
			EX_MUX4Sel_forALU1 <= MUX4Sel_forALU1;
			EX_MUX5Sel_forALU1 <= MUX5Sel_forALU1;		
			EX_MUX1Out <= ID_MUX1Out;	
			EX_MUX3Out <= ID_MUX3Out;
			EX_Branch_flush <= Branch_flush;
			EX_isBL <= ID_isBL;
			EX_Instr <= ID_Instr;
		end
		else 
			EX_stall <= 1'b1;
endmodule

module EX_MEM1(
	input 			clk,
	input 			rst,
	input 			EX_MEM1Wr,
	input 			EX_Flush,
	input 			DMWr,
	input 			DMRd,
	input 			RFWr,
	input 			Overflow,
	input 			eret_flush,
	input 			CP0WrEn,
	input 			Exception,
	input [4:0] 	ExcCode,
	input 			isBD,
	input [2:0] 	MUX2Sel,
	input [3:0] 	DMSel,
	input [4:0] 	RD,
	input [31:0] 	EX_PC,
	input [31:0] 	MUX13Out,
	input [31:0] 	ALU1Out,
	input [31:0] 	GPR_RT,
	input [7:0] 	CP0Addr,
	input 			CP0Rd,
	input 			EX_dcache_en,
	input 			EX_TLBRill_Exc,
	input 			EX_tlb_searchen,
	input 			EX_MUX11Sel,
	input 			EX_TLB_Exc,
	input 			EX_TLB_flush,
	input 			EX_TLB_writeen,
	input 			EX_TLB_readen,
	input 			EX_MUX12Sel,
	input [31:0] 	MULOut,
	input 			Trap,
	input	 		EX_LL_signal,
	input	 		EX_SC_signal,
	input 			EX_icache_valid_CI,
	input 			EX_icache_op_CI,
	input 			EX_dcache_valid_CI,
	input [1:0]		EX_dcache_op_CI,
	input			EX_WAIT_OP,
	input [18:0]	EX_s1_vpn2,
	input [3:0]		EX_match1,
	input [31:0]	EPC,
	input 			EX_MUX6Sel,
	input 			EX_MUX10Sel,
	input [31:0]	EX_Instr,

	output reg 			MEM1_DMWr,
	output reg 			MEM1_DMRd,
	output reg 			MEM1_RFWr,
	output reg 			MEM1_eret_flush,
	output reg 			MEM1_CP0WrEn,
	output reg 			MEM1_Exception,
	output reg [4:0]	MEM1_ExcCode,
	output reg 			MEM1_isBD,
	output reg [2:0]	MEM1_MUX2Sel,
	output reg [3:0]	MEM1_DMSel,
	output reg [4:0]	MEM1_RD,
	output reg [31:0] 	MEM1_PC,
	output reg [31:0] 	MEM1_MUX13Out,
	output reg [31:0] 	MEM1_ALU1Out,
	output reg [31:0] 	MEM1_GPR_RT,
	output reg [7:0] 	MEM1_CP0Addr,
	output reg 			MEM1_CP0Rd,
	output reg 			MEM1_dcache_en,
	output reg 			MEM1_Overflow,
	output reg 			MEM1_TLBRill_Exc,
	output reg			MEM1_tlb_searchen,
	output reg			MEM1_MUX11Sel,
	output reg			MEM1_TLB_Exc,
	output reg			MEM1_TLB_flush,
	output reg			MEM1_TLB_writeen,
	output reg			MEM1_TLB_readen,
	output reg 			MEM1_MUX12Sel,
	output reg [31:0] 	MEM1_MULOut,
	output reg 			MEM1_Trap,
	output reg 			MEM1_LL_signal,
	output reg 			MEM1_SC_signal,
	output reg 			MEM1_icache_valid_CI,
	output reg 			MEM1_icache_op_CI,
	output reg 			MEM1_dcache_valid_CI,
	output reg [1:0]	MEM1_dcache_op_CI,
	output reg  		MEM1_WAIT_OP,
	output reg [18:0] 	s1_vpn2,
	output reg [31:0] 	MEM1_ALU1Out_forExPa,
	output reg [3:0]	match1,
	output reg 			MEM1_MUX6Sel,
	output reg   		MEM1_MUX10Sel,
	output reg [31:0]	MEM1_Instr	
);

	always@(posedge clk)
		if(!rst || EX_Flush) begin
			MEM1_DMWr <= 1'b0;
			MEM1_DMRd <= 1'b0;
			MEM1_RFWr <= 1'b0;
			MEM1_eret_flush <= 1'b0;
			MEM1_CP0WrEn <= 1'b0;
			MEM1_isBD <= 1'b0;
			MEM1_DMRd <= 1'b0;
			MEM1_DMSel <= 4'd0;
			MEM1_MUX2Sel <= 3'd0;
			MEM1_RD <= 5'd0;
			MEM1_PC <= EPC;
			MEM1_MUX13Out <= 32'd0;
			MEM1_ALU1Out <= 32'd0;
			MEM1_GPR_RT <= 32'd0;
			MEM1_CP0Addr <= 8'd0;
			MEM1_CP0Rd <= 1'b0;
			MEM1_dcache_en<=1'b0;
			MEM1_ExcCode <= 5'd0;
			MEM1_Exception <= 1'b0;
			MEM1_Overflow <= 1'b0;
			MEM1_TLBRill_Exc   <= 1'b0;
			MEM1_tlb_searchen <= 1'b0;
			MEM1_MUX11Sel <= 1'b0;
			MEM1_MUX12Sel <= 1'b0;
			MEM1_TLB_Exc <= 1'b0;
			MEM1_TLB_flush <= 1'b0;
			MEM1_TLB_writeen <= 1'b0;
			MEM1_TLB_readen <= 1'b0;
			MEM1_MULOut <= 32'b0;
			MEM1_Trap <= 1'b0;
	 		MEM1_LL_signal <= 1'b0;
	 		MEM1_SC_signal <= 1'b0;
			MEM1_icache_valid_CI <= 1'b0;
			MEM1_icache_op_CI <= 1'b0;
			MEM1_dcache_valid_CI <= 1'b0;
			MEM1_dcache_op_CI <= 2'b00;
			MEM1_WAIT_OP <= 1'b0;
			s1_vpn2 <= 19'd0;
			MEM1_ALU1Out_forExPa <= 32'd0;
			match1 <= 4'd0;
			MEM1_MUX6Sel <= 1'b0;
			MEM1_MUX10Sel <= 1'b0;
			MEM1_Instr <= 32'd0;
		end
		else if (EX_MEM1Wr) begin
			MEM1_DMWr <= DMWr;
			MEM1_DMRd <= DMRd;
			MEM1_RFWr <= RFWr;
			MEM1_eret_flush <= eret_flush;
			MEM1_CP0WrEn <= CP0WrEn;
			MEM1_isBD <= isBD;
			MEM1_DMSel <= DMSel;
			MEM1_MUX2Sel <= MUX2Sel;
			MEM1_RD <= RD;
			MEM1_PC <= EX_PC;
			MEM1_MUX13Out <= MUX13Out;
			MEM1_ALU1Out <= ALU1Out;
			MEM1_GPR_RT <= GPR_RT;
			MEM1_CP0Addr <= CP0Addr;
			MEM1_CP0Rd <= CP0Rd;
			MEM1_dcache_en <= EX_dcache_en;
			MEM1_ExcCode <= ExcCode;
			MEM1_Exception <= Exception;
			MEM1_Overflow <= Overflow;
			MEM1_TLBRill_Exc   <= EX_TLBRill_Exc;
			MEM1_tlb_searchen <= EX_tlb_searchen;
			MEM1_MUX11Sel <= EX_MUX11Sel;
			MEM1_MUX12Sel <= EX_MUX12Sel;
			MEM1_TLB_Exc <= EX_TLB_Exc;
			MEM1_TLB_flush <= EX_TLB_flush;
			MEM1_TLB_writeen <= EX_TLB_writeen;
			MEM1_TLB_readen <= EX_TLB_readen;
			MEM1_MULOut <= MULOut;
			MEM1_Trap <= Trap;
			MEM1_LL_signal <= EX_LL_signal;
	 		MEM1_SC_signal <= EX_SC_signal;
			MEM1_icache_valid_CI <= EX_icache_valid_CI;
			MEM1_icache_op_CI <= EX_icache_op_CI;
			MEM1_dcache_valid_CI <= EX_dcache_valid_CI;
			MEM1_dcache_op_CI <= EX_dcache_op_CI;
			MEM1_WAIT_OP <= EX_WAIT_OP;
			s1_vpn2 <= EX_s1_vpn2;
			MEM1_ALU1Out_forExPa <= ALU1Out;
			match1 <= EX_match1;
			MEM1_MUX6Sel <= EX_MUX6Sel;
			MEM1_MUX10Sel <= EX_MUX10Sel;
			MEM1_Instr <= EX_Instr;
		end

endmodule

module MEM1_MEM2(
	input 			clk,
	input 			rst,
	input 			MEM1_Flush,
	input 			MEM1_MEM2Wr,
	input [31:0] 	PC,
	input 			RFWr,
	input [2:0] 	MUX2Sel,
	input [31:0] 	MUX6Out,
	input [31:0] 	ALU1Out,
	input [4:0] 	RD,
	input [31:0] 	CP0Out,
	input 			cache_sel,
	input 			DMWen,
	input 			Exception,
	input 			eret_flush,
	input 			uncache_valid,
	input 			DMen,
	input [31:0] 	Paddr,
	input [3:0] 	MEM1_dCache_wstrb,
	input [31:0] 	GPR_RT,
	input 			DMRd,
	input 			CP0Rd,
	input 			MEM1_TLB_flush,
	input 			MEM1_TLB_writeen,
	input 			MEM1_TLB_readen,
	input [1:0] 	MEM1_LoadOp,
	input [31:0] 	MEM1_wdata,
	input [31:0] 	MEM1_SCOut,
	input			MEM1_icache_valid_CI,
	input			MEM1_dcache_en,
	input			MEM1_invalid,
	input [4:0]		MEM1_rstrb,
	input [2:0]     MEM1_type,
	input [31:0]	EPC,
	input 			MEM1_MUX10Sel,

	output reg [31:0] 	MEM2_PC,
	output reg 			MEM2_RFWr,
	output reg [2:0] 	MEM2_MUX2Sel,
	output reg [31:0] 	MEM2_MUX6Out,
	output reg [31:0] 	MEM2_ALU1Out,
	output reg [4:0] 	MEM2_RD,
	output reg [31:0] 	MEM2_CP0Out,
	output reg 			MEM2_cache_sel,
	output reg 			MEM2_DMWen,
	output reg 			MEM2_Exception,
	output reg 			MEM2_eret_flush,
	output reg 			MEM2_uncache_valid,
	output reg 			MEM2_DMen,
	output reg [31:0] 	MEM2_Paddr,
	output reg [3:0] 	MEM2_unCache_wstrb,
	output reg [31:0] 	MEM2_GPR_RT,
	output reg 			MEM2_DMRd,
	output reg 			MEM2_CP0Rd,
	output reg 			MEM2_TLB_flush,
	output reg 			MEM2_TLB_writeen,
	output reg 			MEM2_TLB_readen,
	output reg [1:0] 	MEM2_LoadOp,
	output reg [31:0] 	MEM2_wdata,
	output reg [31:0] 	MEM2_SCOut,
	output reg			MEM2_icache_valid_CI,
	output reg 			MEM2_dcache_en,
	output reg 			MEM2_invalid,
	output reg [4:0] 	MEM2_rstrb,
	output reg [2:0] 	MEM2_type,
	output reg 			MEM2_MUX10Sel
);

	always@(posedge clk)
		if(!rst || MEM1_Flush) begin
			MEM2_PC <= EPC;
			MEM2_RFWr <= 1'b0;
			MEM2_MUX2Sel <= 3'd0;
			MEM2_MUX6Out <= 32'd0;
			MEM2_ALU1Out <= 32'd0;
			MEM2_RD <= 5'd0;
			MEM2_CP0Out <= 32'd0;
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
			MEM2_CP0Rd <= 1'b0;
			MEM2_TLB_flush  <=   1'b0;
			MEM2_TLB_writeen<=   1'b0;
			MEM2_TLB_readen<= 1'b0;
			MEM2_LoadOp <= 2'b0;
			MEM2_wdata <= 32'b0;
			MEM2_SCOut <= 32'b0;
			MEM2_icache_valid_CI <= 1'b0;
			MEM2_dcache_en <= 1'b0;
			MEM2_invalid <= 1'b0;
			MEM2_rstrb <= 5'd0;
			MEM2_type <= 3'd0;
			MEM2_MUX10Sel <= 1'b0;
		end
		else if(MEM1_MEM2Wr) begin
			MEM2_PC <= PC;
			MEM2_RFWr <= RFWr;
			MEM2_MUX2Sel <= MUX2Sel;
			MEM2_MUX6Out <= MUX6Out;
			MEM2_ALU1Out <= ALU1Out;
			MEM2_RD <= RD;
			MEM2_CP0Out <= CP0Out;
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
			MEM2_CP0Rd <= CP0Rd;
			MEM2_TLB_flush  <=   MEM1_TLB_flush;
			MEM2_TLB_writeen<=   MEM1_TLB_writeen;
			MEM2_TLB_readen<= MEM1_TLB_readen;
			MEM2_LoadOp <= MEM1_LoadOp;
			MEM2_wdata <= MEM1_wdata;
			MEM2_SCOut <= MEM1_SCOut;
			MEM2_icache_valid_CI <= MEM1_icache_valid_CI;
			MEM2_dcache_en <= MEM1_dcache_en;
			MEM2_invalid <= MEM1_invalid;
			MEM2_rstrb <= MEM1_rstrb;
			MEM2_type <= MEM1_type;
			MEM2_MUX10Sel <= MEM1_MUX10Sel;
		end
endmodule

module MEM2_WB(
	input 			clk,
	input 			rst,
	input 			MEM2_WBWr,
	input 			MEM2_Flush,
	input 			MEM2_TLB_writeen,
	input 			MEM2_TLB_readen,
	input 			MEM2_TLB_flush,
	input [31:0]	PC,
	input [31:0] 	MUX2Out,
	input [2:0] 	MUX2Sel,
	input [4:0] 	RD,
	input  			RFWr,
	input [31:0] 	DMOut,
	input 			MEM2_icache_valid_CI,
	input 			MEM2_MUX10Sel,

	output reg [31:0] 	WB_PC,
	output reg [31:0] 	WB_MUX2Out,
	output reg [2:0] 	WB_MUX2Sel,
	output reg [4:0] 	WB_RD,
	output reg  		WB_RFWr,
	output reg [31:0] 	WB_DMOut,
	output reg 			WB_TLB_writeen,
	output reg 			WB_TLB_readen,
	output reg 			WB_TLB_flush,
	output reg 			WB_icache_valid_CI,
	output reg 			WB_MUX10Sel
);

	always@(posedge clk)
		if(!rst || MEM2_Flush) begin
			WB_PC <= 32'd0;
			WB_MUX2Out <= 32'd0;
			WB_MUX2Sel <= 3'd0;
			WB_RD <= 5'd0;
			WB_RFWr <= 1'b0;
			WB_DMOut <= 32'd0;
	    	WB_TLB_writeen<= 1'b0 ;
			WB_TLB_readen <= 1'b0 ;
			WB_TLB_flush  <= 1'b0 ;
			WB_icache_valid_CI <= 1'b0;
			WB_MUX10Sel <= 1'b0;
		end
		else if(MEM2_WBWr) begin
			WB_PC <= PC;
			WB_MUX2Out <= MUX2Out;
			WB_MUX2Sel <= MUX2Sel;
			WB_RD <= RD;
			WB_RFWr <= RFWr;
			WB_DMOut <= DMOut;
	    	WB_TLB_writeen<= MEM2_TLB_writeen ;
			WB_TLB_readen <= MEM2_TLB_readen ;
			WB_TLB_flush  <= MEM2_TLB_flush ;
			WB_icache_valid_CI <= MEM2_icache_valid_CI;
			WB_MUX10Sel <= MEM2_MUX10Sel;
		end

endmodule
