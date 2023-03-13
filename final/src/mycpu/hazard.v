module bypass(
	input 			MEM1_RFWr, 
	input			MEM2_RFWr, 
	input			WB_RFWr, 
	input			EX_RFWr,
	input [4:0] 	ID_RS, 
	input [4:0]		ID_RT, 
	input [4:0]		MEM1_RD, 
	input [4:0]		MEM2_RD, 
	input [4:0]		WB_RD, 
	input [4:0]		EX_RD,
	input [4:0] 	ID_RS_forCMP, 
	input [4:0]		ID_RT_forCMP,
	input 			ID_MUX3Sel,
	input 			ALU1Sel,

	output reg [1:0]	MUX4Sel,
	output reg [1:0]	MUX5Sel,
	output reg [1:0] 	MUX8Sel, 
	output reg [1:0]	MUX9Sel,
	output reg [1:0] 	MUX8Sel_forCMP, 
	output reg [1:0]	MUX9Sel_forCMP,
	output [1:0]		MUX5Sel_forALU1,
	output [1:0]		MUX4Sel_forALU1
);


	always@(EX_RFWr, MEM1_RFWr, MEM2_RFWr, ID_RS, MEM1_RD, MEM2_RD, EX_RD)
		if(EX_RFWr && (EX_RD == ID_RS))
			MUX4Sel = 2'b01;		//EX->ID/MEM1->EX for RS
		else if (MEM1_RFWr && (MEM1_RD == ID_RS))
			MUX4Sel = 2'b10;		//MEM1->ID/MEM2->EX for RS
		else if(MEM2_RFWr && (MEM2_RD == ID_RS))
			MUX4Sel = 2'b11;		//MEM2->ID/WB->EX for RS
		else
			MUX4Sel = 2'b00;		//NO bypass for RS

 	always@(EX_RFWr, MEM1_RFWr, MEM2_RFWr, ID_RT, MEM1_RD, MEM2_RD, EX_RD)
	 	if(EX_RFWr && (EX_RD == ID_RT))
			MUX5Sel = 2'b01;		//EX->ID/MEM1->EX for RT
		else if (MEM1_RFWr && (MEM1_RD == ID_RT))
			MUX5Sel = 2'b10;		//MEM1->ID/MEM2->EX for RT
		else if(MEM2_RFWr && (MEM2_RD == ID_RT))
			MUX5Sel = 2'b11;		//MEM2->ID/WB->EX for RT
		else
			MUX5Sel = 2'b00;		//NO bypass for RT

	always@(WB_RFWr, MEM1_RFWr, MEM2_RFWr, ID_RS, MEM1_RD, MEM2_RD, WB_RD)
		if (MEM1_RFWr && (MEM1_RD == ID_RS))
			MUX8Sel = 2'b10;		//MEM1->ID for RS
		else if(MEM2_RFWr && (MEM2_RD == ID_RS))
			MUX8Sel = 2'b11;		//MEM2->ID for RS
		else if(WB_RFWr && (WB_RD == ID_RS))
			MUX8Sel = 2'b01;		//WB->ID for RS
		else
			MUX8Sel = 2'b00;		//NO bypass for RS

 	always@(WB_RFWr, MEM1_RFWr, MEM2_RFWr, ID_RT, MEM1_RD, MEM2_RD, WB_RD)
		if (MEM1_RFWr && (MEM1_RD == ID_RT))
			MUX9Sel = 2'b10;		//MEM1->ID for RT
		else if(MEM2_RFWr && (MEM2_RD == ID_RT))
			MUX9Sel = 2'b11;		//MEM2->ID for RT
		else if(WB_RFWr && (WB_RD == ID_RT))
			MUX9Sel = 2'b01;		//WB->ID for RT
		else
			MUX9Sel = 2'b00;		//NO bypass for RT

	always@(WB_RFWr, MEM1_RFWr, MEM2_RFWr, ID_RS_forCMP, MEM1_RD, MEM2_RD, WB_RD)
		if (MEM1_RFWr && (MEM1_RD == ID_RS_forCMP))
			MUX8Sel_forCMP = 2'b10;		//MEM1->ID for RS
		else if(MEM2_RFWr && (MEM2_RD == ID_RS_forCMP))
			MUX8Sel_forCMP = 2'b11;		//MEM2->ID for RS
		else if(WB_RFWr && (WB_RD == ID_RS_forCMP))
			MUX8Sel_forCMP = 2'b01;		//WB->ID for RS
		else
			MUX8Sel_forCMP = 2'b00;		//NO bypass for RS

	always@(WB_RFWr, MEM1_RFWr, MEM2_RFWr, ID_RT_forCMP, MEM1_RD, MEM2_RD, WB_RD)
		if (MEM1_RFWr && (MEM1_RD == ID_RT_forCMP))
			MUX9Sel_forCMP = 2'b10;		//MEM1->ID for RT
		else if(MEM2_RFWr && (MEM2_RD == ID_RT_forCMP))
			MUX9Sel_forCMP = 2'b11;		//MEM2->ID for RT
		else if(WB_RFWr && (WB_RD == ID_RT_forCMP))
			MUX9Sel_forCMP = 2'b01;		//WB->ID for RT
		else
			MUX9Sel_forCMP = 2'b00;		//NO bypass for RT

	assign MUX5Sel_forALU1 = MUX5Sel & {2{~ID_MUX3Sel}};
	assign MUX4Sel_forALU1 = MUX4Sel & {2{~ALU1Sel}};
endmodule

module stall(
	input 			clk,
	input 			rst,
	input [4:0] 	EX_RT,
	input [4:0] 	MEM1_RT,
	input [4:0] 	MEM2_RT,
	input [4:0] 	ID_RS,
	input [4:0] 	ID_RT,
	input [31:0] 	ID_PC,
	input [31:0] 	EX_PC,
	input [31:0] 	MEM1_PC,
	input 			EX_DMRd,
	input 			MEM1_DMRd,
	input 			MEM2_DMRd,
	input 			BJOp,
	input 			EX_RFWr,
	input 			MEM1_RFWr,
	input 			MEM2_RFWr,
	input 			EX_CP0Rd,
	input 			MEM1_CP0Rd,
	input 			MEM2_CP0Rd,
	input 			MEM1_ee,
	input 			rst_sign,
	input 			isbusy,
	input 			RHL_visit,
	input 			iCache_data_ok,
	input 			dCache_data_ok,
	input 			MEM_dCache_en,
	input 			MEM1_cache_sel,
	input 			MEM1_dCache_en,
	input 			ID_tlb_searchen,
	input 			EX_CP0WrEn,
	input 			MUL_sign,
	input 			EX_SC_signal,
	input 			MEM1_SC_signal,
	input 			MEM1_WAIT_OP,
	input 			Interrupt,
	input			ID_isBL,

	output reg 		PCWr,
	output reg 		IF_IDWr,
	output reg 		MUX7Sel,
	output	 		icache_stall,
	output 			isStall,
	output 			dcache_stall,
	output reg 		ID_EXWr,
	output reg 		EX_MEM1Wr,
	output reg 		MEM1_MEM2Wr,
	output reg 		MEM2_WBWr,
	output reg 		PF_IFWr,
	output 			data_stall,
	output 			whole_stall
);

	wire 			addr_ok;
	wire 			stall_0;
	wire 			stall_1;
	wire 			stall_2;
	wire 			stall_3;	
	wire 			stall_4;			


	assign dcache_stall = (~dCache_data_ok |~iCache_data_ok);
	assign isStall= whole_stall | data_stall | ID_isBL;
	assign icache_stall = (~dCache_data_ok | MEM1_WAIT_OP | MUL_sign) | data_stall | ID_isBL;

	//assign stall_0 = (EX_DMRd || EX_CP0Rd || EX_SC_signal || BJOp || ALU2Op==5'b01011) && ( (EX_RT == ID_RS) || (EX_RT == ID_RT) ) && (ID_PC != EX_PC);
	//assign stall_1 = (MEM1_DMRd || MEM1_CP0Rd || MEM1_SC_signal) && ( (MEM1_RT == ID_RS) || (MEM1_RT == ID_RT) ) && (ID_PC != MEM1_PC);
	//assign stall_2 = (BJOp || ALU2Op==5'b01011) && MEM2_RFWr && (MEM2_DMRd) && ( (MEM2_RT == ID_RS) || (MEM2_RT == ID_RT)  && (MEM2_RT != 5'b0));
	//assign stall_3 = (BJOp || ALU2Op==5'b01011) && EX_RFWr && !EX_SC_signal && ( (EX_RT == ID_RS) || (EX_RT == ID_RT) ) && (EX_RT != 5'b0);

	assign stall_0 = (EX_DMRd | EX_CP0Rd | BJOp | EX_SC_signal) & ((EX_RT == ID_RS) | (EX_RT == ID_RT) ) & EX_RFWr;
	assign stall_1 = (MEM1_DMRd | MEM1_CP0Rd | BJOp&MEM1_SC_signal) & ((MEM1_RT == ID_RS) | (MEM1_RT == ID_RT) ) & MEM1_RFWr;
	assign stall_2 = (BJOp  & MEM2_DMRd ) & ((MEM2_RT == ID_RS) | (MEM2_RT == ID_RT)) & MEM2_RFWr;
	assign stall_3 = ID_tlb_searchen && EX_CP0WrEn;
	assign stall_4 = isbusy && RHL_visit;

	assign data_stall = stall_0 | stall_1 | stall_2 | stall_3 | stall_4;
	assign whole_stall = dcache_stall | MEM1_WAIT_OP | MUL_sign;

	always@( * )
		if(MEM1_ee) begin
			PF_IFWr = 1'b1;
			PCWr = 1'b1;
			IF_IDWr = 1'b1;
			ID_EXWr = 1'b1;
			EX_MEM1Wr =1'b1;
			MEM1_MEM2Wr = dCache_data_ok;
			MEM2_WBWr = dCache_data_ok;
			MUX7Sel = 1'b0;
		end
		else if(whole_stall) begin
			PCWr = 1'b0;
			PF_IFWr = 1'b0;
			IF_IDWr = 1'b0;
			ID_EXWr = 1'b0;
			EX_MEM1Wr =1'b0;
			MEM1_MEM2Wr = 1'b0;
			MEM2_WBWr = 1'b0;
			MUX7Sel = 1'b0;
		end
		else if(data_stall) begin
			PCWr = 1'b0;
			PF_IFWr = 1'b0;
			IF_IDWr = 1'b0;
			ID_EXWr = 1'b1;
			EX_MEM1Wr =1'b1;
			MEM1_MEM2Wr = 1'b1;
			MEM2_WBWr = 1'b1;
			MUX7Sel = 1'b1;
		end
		else if (ID_isBL) begin
			PCWr = 1'b0;
			PF_IFWr = 1'b0;
			IF_IDWr = 1'b0;
			ID_EXWr = 1'b1;
			EX_MEM1Wr =1'b1;
			MEM1_MEM2Wr = 1'b1;
			MEM2_WBWr = 1'b1;
			MUX7Sel = 1'b0;
		end
		else begin
			PCWr = 1'b1;
			PF_IFWr = 1'b1;
			IF_IDWr = 1'b1;
			ID_EXWr = 1'b1;
			EX_MEM1Wr =1'b1;
			MEM1_MEM2Wr = 1'b1;
			MEM2_WBWr = 1'b1;
			MUX7Sel = 1'b0;
		end

endmodule