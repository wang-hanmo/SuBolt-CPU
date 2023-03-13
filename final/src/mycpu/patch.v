`include "MacroDef.v"

module instr_fetch_pre(
    PF_PC,PCWr,s0_found,s0_v,s0_pfn,s0_c,IF_uncache_data_ok,isStall,
    TLB_flush,EX_TLB_flush,MEM1_TLB_flush,MEM2_TLB_flush,WB_TLB_flush,
    Config_K0_out,Branch_flush,PF_Instr_Flush,
    icache_valid_CI, EX_icache_valid_CI, MEM1_icache_valid_CI,
    MEM2_icache_valid_CI, WB_icache_valid_CI,

    PF_TLB_Exc,PF_ExcCode,PF_TLBRill_Exc,PF_Exception,PPC,
    PF_invalid,Invalidate_signal,PF_icache_sel,PF_icache_valid,
    PF_uncache_valid, IF_PC_invalid, refetch
    );
    input [31:0]    PF_PC;
    input           PCWr;
    input           s0_v;
    input           s0_found;
    input [19:0]    s0_pfn;
    input           isStall;
    input           TLB_flush;
    input           EX_TLB_flush;
    input           MEM1_TLB_flush;
    input           MEM2_TLB_flush;
    input           WB_TLB_flush;
    input           IF_uncache_data_ok;
    input [2:0]     s0_c;
    input [2:0]     Config_K0_out;
    input           Branch_flush;
    input           PF_Instr_Flush;
    input           icache_valid_CI;
    input           EX_icache_valid_CI;
    input           MEM1_icache_valid_CI;
    input           MEM2_icache_valid_CI;
    input           WB_icache_valid_CI;

    output          PF_TLB_Exc;
    output          PF_TLBRill_Exc;
    output          PF_Exception;
    output [4:0]    PF_ExcCode;
    output [31:0]   PPC;
    output          PF_invalid;
    output          Invalidate_signal;
    output          PF_icache_sel;
    output          PF_icache_valid;
    output          PF_uncache_valid;
    output          IF_PC_invalid;
    output          refetch;

    wire mapped;
    wire kseg0, kseg1;
    wire PF_AdEL;
    
    /*Exception generation*/
    //the tlb exception should influence the cache and uncache valid or not
    assign mapped = ( ~PF_PC[31] || (PF_PC[31]&PF_PC[30]) ) ? 1 : 0;
    assign PPC =
		!mapped ? {3'b000,PF_PC[28:0]} : {s0_pfn,PF_PC[11:0]};

    assign PF_AdEL = PF_PC[1:0] != 2'b00 && PCWr;
    assign PF_TLBRill_Exc	= ~PF_AdEL & mapped & (!s0_found) & PCWr;
    assign PF_TLB_Exc   = mapped & (!s0_found || (s0_found&!s0_v) ) & !PF_AdEL;//tlbl
    assign PF_Exception = PF_AdEL | PF_TLB_Exc;
    assign PF_ExcCode = 	 PF_AdEL ? `AdEL :
                            PF_TLB_Exc ? `TLBL : 5'b0;

    /*icache sel*/
    assign kseg0 = (PF_PC[31:29] == 3'b100);
    assign kseg1 = (PF_PC[31:29] == 3'b101);
    assign PF_icache_sel = ~((kseg0 & (Config_K0_out==3'b011)) || (!kseg0 & !kseg1 & (s0_c==3'b011)));
    //assign PF_icache_sel = (PPC[31:16] == 16'h1faf);//used in funct test
    //assign PF_icache_sel = 1'b1;
    /* dcache control signal*/
    assign PF_invalid = PF_Exception | refetch;
    assign PF_icache_valid = !isStall & ~PF_icache_sel;
    assign PF_uncache_valid = !isStall & PF_icache_sel;
    assign Invalidate_signal = Branch_flush ? 1 : (PF_Instr_Flush | refetch);
    assign refetch =  TLB_flush | EX_TLB_flush | MEM1_TLB_flush | MEM2_TLB_flush | WB_TLB_flush |
    icache_valid_CI | EX_icache_valid_CI | MEM1_icache_valid_CI | MEM2_icache_valid_CI | WB_icache_valid_CI;

    assign IF_PC_invalid = Branch_flush | PF_Instr_Flush;

endmodule

module branch_predict_prep(
    input [31:0]    IF_PC,
    input [31:0]    PF_PC,
    input [25:0]    Imm,
    input           PF_Instr_Flush,
    input [31:0]    ret_addr,
    input           branch,
    input [31:0]    target_addr,
    input           MEM1_Exception,
    input           MEM1_eret_flush,
    input           MEM1_ee,
    input [31:0]    EPC,
    input           Interrupt,
    input           Status_BEV,
    input           Status_EXL,
    input           Cause_IV,
    input           MEM1_TLBRill_Exc,
    input           WB_TLB_flush,
    input           WB_icache_valid_CI,
    input [31:0]    MEM2_PC,
    input [31:0]    Ebase_out,
    input [31:0]    MEM1_ExcCode,

    output [31:0]   NPC_op00,
    output [31:0]   NPC_op01,
    output [31:0]   NPC_op10,
    output          flush_condition_00,
    output          flush_condition_01,
    output          flush_condition_10,
    output          flush_condition_11,
    output [31:0]   target_addr_final,
    output          ee,
    output reg[31:0]NPC_ee
);
    wire[31:0] IF_PC_add4;
    wire[31:0] PF_PC_add4;
    wire branch_signal;
    reg [11:0] offset;
    //wire npc_condition;

    assign IF_PC_add4 = IF_PC + 4;
    assign PF_PC_add4 = PF_PC + 4;
    assign NPC_op00 =  IF_PC_add4;
    assign NPC_op01 = IF_PC + {{14{Imm[15]}},Imm[15:0],2'b00} ;
    assign NPC_op10 = {IF_PC[31:28],Imm[25:0],2'b00} ;

    //assign npc_condition = (PF_predict && PF_PC != IF_PC_add4);

    assign flush_condition_00 = (NPC_op00 != PF_PC) && !PF_Instr_Flush;
    assign flush_condition_01 = (NPC_op01 != PF_PC) && !PF_Instr_Flush;
    assign flush_condition_10 = (NPC_op10 != PF_PC) && !PF_Instr_Flush;
    assign flush_condition_11 = (ret_addr != PF_PC) && !PF_Instr_Flush;

    assign branch_signal = (branch && !PF_Instr_Flush);

    assign target_addr_final = branch_signal ? target_addr : PF_PC_add4;

    assign ee = MEM1_ee |(WB_TLB_flush | WB_icache_valid_CI);

    always @( * ) begin
        if ( ~Status_EXL )
            if ( MEM1_TLBRill_Exc )
                offset = 12'h00;
            else if ( Interrupt && Cause_IV )
                offset = 12'h200;
            else
                offset = 12'h180;
        else
                offset = 12'h180;
    end
    // always @( * ) begin
    //     if ( MEM1_TLBRill_Exc )
    //         offset = 12'h000;
    //     else if ( Interrupt && Cause_IV )
    //         offset = 12'h200;
    //     else
    //         offset = 12'h180;
    // end

    always @( * ) begin
        if ( MEM1_eret_flush | WB_TLB_flush | WB_icache_valid_CI)//具有优先级
            NPC_ee = MEM1_eret_flush ? EPC : MEM2_PC;
        else if ( Status_BEV )
            NPC_ee = 32'hbfc00200 + offset;
        else
            NPC_ee = {Ebase_out[31:12],offset};
    end

endmodule

module pre_decode (
    input [5:0] IF_OP,
    input [5:0] IF_Funct,

    output reg IF_BJOp
);

    always @(IF_OP or IF_Funct) begin		
		 case (IF_OP)
			6'b000100: IF_BJOp = 1;		/* BEQ */
			6'b000101: IF_BJOp = 1;		/* BNE */
			6'b000001: IF_BJOp = 1;		/* BGEZ, BLTZ, BGEZAL, BLTZAL */
			6'b000111: IF_BJOp = 1;		/* BGTZ */
			6'b000110: IF_BJOp = 1;		/* BLEZ */
            6'b010100: IF_BJOp = 1;     /* BEQL */
            6'b010101: IF_BJOp = 1;		/* BNEl */
            6'b010111: IF_BJOp = 1;     /* BGTZL */
            6'b010110: IF_BJOp = 1;     /* BLEZL*/
			6'b000000:
			if (IF_Funct == 6'b001000 || IF_Funct == 6'b001001)	/* JR, JALR */
				IF_BJOp = 1;
			else
				IF_BJOp = 0;
			default:   IF_BJOp = 0;
		endcase
	end

endmodule

module ex_prep(
    input [1:0]     EX_NPCOp,
    input [25:0]    EX_Imm26,
    input [31:0]    ID_PC,
    input [31:0]    return_addr,
    input [2:0]     EX_MUX2Sel,

    output reg [31:0]   EX_address,
    output              EX_MUX6Sel,
    output              EX_MUX10Sel
);

    always @(EX_NPCOp, EX_Imm26, ID_PC, return_addr) begin
        case(EX_NPCOp)
				2'b01:	if(EX_Imm26[15])
							EX_address = ID_PC + {14'h3fff,EX_Imm26[15:0],2'b00};
						else
							EX_address = ID_PC + {14'h0000,EX_Imm26[15:0],2'b00};
				2'b10:	EX_address = { ID_PC[31:28],EX_Imm26[25:0],2'b00};
                2'b11: EX_address = return_addr;
				default:EX_address = ID_PC + 4;
			endcase
    end

    assign EX_MUX6Sel = (EX_MUX2Sel == 3'b010);
    assign EX_MUX10Sel = (EX_MUX2Sel == 3'b100);
endmodule


module mem1_cache_prep(
    clk,rst,MEM1_dcache_en,MEM1_eret_flush,MEM1_ALU1Out,MEM1_DMWr,
    MEM1_DMSel, MEM1_RFWr,MEM1_Overflow, Temp_M1_Exception,
    MEM1_DMRd, Temp_M1_ExcCode,MEM1_PC,s1_found,s1_v,s1_d,
    s1_pfn,s1_c,Temp_MEM1_TLB_Exc,IF_data_ok,
    Temp_MEM1_TLBRill_Exc, MEM_unCache_data_ok,
    MEM1_GPR_RT,Interrupt,Config_K0_out,MEM1_Trap,
    MEM1_LL_signal,MEM1_SC_signal,MEM1_icache_valid_CI, MEM1_icache_op_CI,
    MEM1_dcache_valid_CI, MEM1_dcache_op_CI,

    MEM1_Paddr, MEM1_cache_sel, MEM1_dcache_valid,DMWen_dcache,
    MEM1_dCache_wstrb,MEM1_ExcCode,MEM1_Exception,MEM1_badvaddr,
    MEM1_TLBRill_Exc,MEM1_TLB_Exc,MEM1_uncache_valid,MEM1_DMen,
    MEM1_wdata,MEM1_SCOut,Cause_CE_Wr, MEM1_invalid, MEM1_ee, MEM1_rstrb, MEM1_type
    );
    input           clk;
    input           rst;
    input           MEM1_dcache_en;//MEM1_dcache_en = 1 => load or store
    input           MEM1_eret_flush;
    input [31:0]    MEM1_ALU1Out;
    input           MEM1_DMWr;
    input [3:0]     MEM1_DMSel;
    input           MEM1_Overflow;
    input           Temp_M1_Exception;
    input           MEM1_DMRd;
    input[4:0]      Temp_M1_ExcCode;
    input[31:0]     MEM1_PC;
    input           s1_found;
    input           s1_v;
    input           s1_d;
    input           Temp_MEM1_TLB_Exc;
    input           IF_data_ok;
    input           Temp_MEM1_TLBRill_Exc;
    input [19:0]    s1_pfn;
    input           MEM_unCache_data_ok;
    input           MEM1_RFWr;
    input [31:0]    MEM1_GPR_RT;
    input           Interrupt;
    input [2:0]     Config_K0_out;
    input [2:0]     s1_c;
    input           MEM1_Trap;
    input           MEM1_LL_signal;
    input           MEM1_SC_signal;
    input 			MEM1_icache_valid_CI;
	input 			MEM1_icache_op_CI;
	input 			MEM1_dcache_valid_CI;
	input [1:0] 	MEM1_dcache_op_CI;

    output [31:0]   MEM1_Paddr;
    output          MEM1_cache_sel;
    output          MEM1_dcache_valid;
    output          DMWen_dcache;
    output reg[3:0] MEM1_dCache_wstrb;
    output reg[4:0] MEM1_ExcCode;
    output reg      MEM1_Exception;
    output reg[31:0] MEM1_badvaddr;
    output          MEM1_TLBRill_Exc;
    output          MEM1_TLB_Exc;
    output          MEM1_uncache_valid;
    output          MEM1_DMen;
    output reg [31:0] MEM1_wdata;
    output [31:0]   MEM1_SCOut;
    output          Cause_CE_Wr;
    output          MEM1_invalid;
    output reg      MEM1_ee;
    output reg[4:0] MEM1_rstrb;
    output reg[2:0] MEM1_type;

    wire data_mapped;
    wire valid;
    wire [4:0] MEM1_TLB_ExCode;
    wire kseg0, kseg1;
    reg tlbs, tlbl, tlbmod;
    wire AdES_sel, AdEL_sel;
    wire SC_OK;
    reg  LLbit;
    reg [31:0] LL_addr;
    wire MEM1_TLB_Exc_temp;

    assign data_mapped = (~MEM1_ALU1Out[31] || (MEM1_ALU1Out[31]&&MEM1_ALU1Out[30]))
                        & (MEM1_dcache_en | MEM1_icache_valid_CI&~MEM1_icache_op_CI
                        | MEM1_dcache_valid_CI&MEM1_dcache_op_CI[0]);//load or store or CACHE
    assign MEM1_Paddr =
		        !data_mapped ? {3'b000,MEM1_ALU1Out[28:0]} :
                {s1_pfn,MEM1_ALU1Out[11:0]} ;

    //dcache sel
    assign kseg0 = (MEM1_ALU1Out[31:29] == 3'b100);
    assign kseg1 = (MEM1_ALU1Out[31:29] == 3'b101);
    assign MEM1_cache_sel = ~((kseg0& (Config_K0_out==3'b011)) || (!kseg0 & !kseg1 & (s1_c==3'b011))) 
                        & ~MEM1_dcache_valid_CI;
    //assign MEM1_cache_sel = (MEM1_Paddr[31:16] == 16'h1faf);
    //assign MEM1_cache_sel = 1'b1;
	// 1 表示uncache, 0表示cache

    /*Exception generation*/
    /*
    Explain:
        valid --> need to use dcache
        DMWen_dcache --> need to write dcache
        !s1_found --> TLB Rill
        s1_found&!s1_v --> TLB Invalid
        s1_found&s1_v&!s1_d --> TLB Mod
    */
    assign valid = MEM1_dcache_en &IF_data_ok;
	assign 	MEM1_TLBRill_Exc	= (!Temp_M1_Exception & data_mapped & (!s1_found) & valid) | Temp_MEM1_TLBRill_Exc;

    always @(*) begin  
        if (s1_found && s1_v)
            tlbl = 1'b0;
        else if (data_mapped & !DMWen_dcache)
            tlbl = 1'b1;
        else
            tlbl = 1'b0;
    end

    always @(*) begin  
        if (s1_found && s1_v)
            tlbs = 1'b0;
        else if (data_mapped & DMWen_dcache)
            tlbs = 1'b1;
        else
            tlbs = 1'b0;
    end

    always @(*) begin  
        if (!s1_found)
            tlbmod = 1'b0;
        else if (data_mapped & DMWen_dcache & s1_v & !s1_d)
            tlbmod = 1'b1;
        else
            tlbmod = 1'b0;
    end

    assign MEM1_TLB_Exc = (MEM1_TLB_Exc_temp&!Temp_M1_Exception) | Temp_MEM1_TLB_Exc;//include tlb rill,tlb invaild
    assign MEM1_TLB_Exc_temp = tlbl | tlbs | tlbmod;
    assign MEM1_TLB_ExCode =
                              tlbl      ? `TLBL      :
                              tlbs      ? `TLBS      :
                                          `TLBMod    ;


    //Exception Sel
    assign AdES_sel =
        MEM1_DMWr && ( MEM1_DMSel == 4'b0010 && MEM1_ALU1Out[1:0] != 2'b00 ||
         MEM1_DMSel == 4'b0001 && MEM1_ALU1Out[0] != 1'b0);
    assign AdEL_sel =
        MEM1_RFWr && MEM1_DMRd &&( (MEM1_DMSel == 4'b1011 && MEM1_ALU1Out[1:0] != 2'b00) ||
        ( (MEM1_DMSel == 4'b0111 || MEM1_DMSel == 4'b1000) && MEM1_ALU1Out[0] != 1'b0 ) );

    always @(*) begin
        if (MEM1_TLB_Exc_temp)
            MEM1_Exception = 1'b1;
        else if (Interrupt | MEM1_Overflow | MEM1_Trap | AdES_sel | AdEL_sel  | Temp_M1_Exception)
            MEM1_Exception = 1'b1;
        else
            MEM1_Exception = 1'b0;
    end

    always @(*) begin
        if (MEM1_TLB_Exc_temp)
            MEM1_ee = 1'b1;
        else if (Interrupt | MEM1_Overflow | MEM1_Trap | AdES_sel | AdEL_sel  | Temp_M1_Exception | MEM1_eret_flush)
            MEM1_ee = 1'b1;
        else
            MEM1_ee = 1'b0;
    end

    always@(*)
        if (Interrupt) begin
			MEM1_ExcCode = `Int;
            MEM1_badvaddr = 32'd0;
		end
        else if(Temp_M1_Exception) begin
		    MEM1_ExcCode = Temp_M1_ExcCode;
		    MEM1_badvaddr = MEM1_PC;//在此流水级之前产生的与地�??有关的例外其出错地址�??定为其PC
		end
		else if (MEM1_Overflow) begin
		    MEM1_ExcCode = `Ov;
		    MEM1_badvaddr = 32'd0;
		end
        else if (MEM1_Trap) begin
		    MEM1_ExcCode = `Trap;
		    MEM1_badvaddr = 32'd0;
		end
		else if (AdES_sel)begin
		    MEM1_ExcCode = `AdES;
		    MEM1_badvaddr = MEM1_ALU1Out;
		end
		else if (AdEL_sel) begin
		    MEM1_ExcCode = `AdEL;
		    MEM1_badvaddr = MEM1_ALU1Out;
		end
        else begin
            MEM1_ExcCode = MEM1_TLB_ExCode;
		    MEM1_badvaddr = MEM1_ALU1Out;
        end

    assign Cause_CE_Wr = MEM1_ExcCode==`Cpu;

    /* dcache control signal*/
    assign DMWen_dcache = MEM1_DMWr & (!MEM1_SC_signal | (MEM1_SC_signal&SC_OK));//0->load,1->store
    assign MEM1_dcache_valid = (MEM1_dcache_en & IF_data_ok & MEM_unCache_data_ok
                &(!MEM1_SC_signal | (MEM1_SC_signal&SC_OK))) & ~MEM1_cache_sel;
    assign MEM1_uncache_valid =MEM1_dcache_en & MEM1_cache_sel & &(!MEM1_SC_signal | (MEM1_SC_signal&SC_OK));
    assign MEM1_DMen = (MEM1_dcache_en | MEM1_dcache_valid_CI)&!MEM1_ee
                        &(!MEM1_SC_signal | (MEM1_SC_signal&SC_OK));
    assign MEM1_invalid = MEM1_ee;

    /* LL SC Instr */
    always @(posedge clk) begin
        if ( !rst | MEM1_ee )
            LLbit <= 1'b0;
        else if ( MEM1_LL_signal )
            LLbit <= 1'b1;
    end
    always @(posedge clk) begin
        if ( !rst | MEM1_ee )
            LL_addr <= 32'b0;
        else if ( MEM1_LL_signal )
            LL_addr <= MEM1_ALU1Out;
    end
    assign SC_OK = LLbit & (LL_addr == MEM1_ALU1Out) & MEM1_SC_signal;
    assign MEM1_SCOut = {31'b0,(MEM1_dcache_valid|MEM1_uncache_valid)};

/* set writeen signal and store data */

    always@(*)
        case(MEM1_DMSel)
            4'b0000://SB 
                case(MEM1_Paddr[1:0])
                    2'b00:      MEM1_dCache_wstrb = 4'b0001;
                    2'b01:      MEM1_dCache_wstrb = 4'b0010;  
                    2'b10:      MEM1_dCache_wstrb = 4'b0100;
                    default:    MEM1_dCache_wstrb = 4'b1000;
                endcase
            4'b0001://SH
                case(MEM1_Paddr[1])
                    1'b0:       MEM1_dCache_wstrb = 4'b0011;
                    default:    MEM1_dCache_wstrb = 4'b1100;
                endcase
            4'b0011://SWL
                case(MEM1_Paddr[1:0])
                    2'b00:      MEM1_dCache_wstrb = 4'b0001;
                    2'b01:      MEM1_dCache_wstrb = 4'b0011;  
                    2'b10:      MEM1_dCache_wstrb = 4'b0111;
                    default:    MEM1_dCache_wstrb = 4'b1111;
                endcase
            4'b0100://SWR
                case(MEM1_Paddr[1:0])
                    2'b00:      MEM1_dCache_wstrb = 4'b1111;
                    2'b01:      MEM1_dCache_wstrb = 4'b1110;  
                    2'b10:      MEM1_dCache_wstrb = 4'b1100;
                    default:    MEM1_dCache_wstrb = 4'b1000;
                endcase
            default://SW SC
                                MEM1_dCache_wstrb = 4'b1111;
        endcase

    always@(*)
        case(MEM1_DMSel)
            4'b0000://SB 
                                MEM1_wdata = {4{MEM1_GPR_RT[7:0]}};
            4'b0001://SH
                                MEM1_wdata = {2{MEM1_GPR_RT[15:0]}};
            4'b0011://SWL
                case(MEM1_Paddr[1:0])
                    2'b00:      MEM1_wdata = {4{MEM1_GPR_RT[31:24]}};
                    2'b01:      MEM1_wdata = {2{MEM1_GPR_RT[31:16]}};
                    2'b10:      MEM1_wdata = {8'b0,MEM1_GPR_RT[31:8]};
                    default:    MEM1_wdata = MEM1_GPR_RT[31:0];
                endcase
            4'b0100://SWR
                case(MEM1_Paddr[1:0])
                    2'b00:      MEM1_wdata = MEM1_GPR_RT[31:0];
                    2'b01:      MEM1_wdata = {MEM1_GPR_RT[23:0],8'b0};
                    2'b10:      MEM1_wdata = {2{MEM1_GPR_RT[15:0]}};
                    default:    MEM1_wdata = {4{MEM1_GPR_RT[7:0]}};
                endcase
            default://SW SC
                                MEM1_wdata = MEM1_GPR_RT[31:0];
        endcase

            
    always@(*)
        case(MEM1_DMSel)
            4'b0101://LBU 
                case(MEM1_Paddr[1:0])
                    2'b00:      MEM1_rstrb = 5'b00000;
                    2'b01:      MEM1_rstrb = 5'b00001;  
                    2'b10:      MEM1_rstrb = 5'b00010;
                    default:    MEM1_rstrb = 5'b00011;
                endcase
            4'b0110://LB 
                case(MEM1_Paddr[1:0])
                    2'b00:      MEM1_rstrb = 5'b01000;
                    2'b01:      MEM1_rstrb = 5'b01001;  
                    2'b10:      MEM1_rstrb = 5'b01010;
                    default:    MEM1_rstrb = 5'b01011;
                endcase
            4'b0111://LHU
                case(MEM1_Paddr[1])
                    1'b0:       MEM1_rstrb = 5'b00100;
                    default:    MEM1_rstrb = 5'b00110;
                endcase
            4'b1000://LH
                case(MEM1_Paddr[1])
                    1'b0:       MEM1_rstrb = 5'b01100;
                    default:    MEM1_rstrb = 5'b01110;
                endcase
            4'b1001://LWL
                case(MEM1_Paddr[1:0])
                    2'b00:      MEM1_rstrb = 5'b11000;
                    2'b01:      MEM1_rstrb = 5'b11100;  
                    2'b10:      MEM1_rstrb = 5'b11110;
                    default:    MEM1_rstrb = 5'b11111;
                endcase
            4'b1010://LWR
                case(MEM1_Paddr[1:0])
                    2'b00:      MEM1_rstrb = 5'b11111;
                    2'b01:      MEM1_rstrb = 5'b10111;  
                    2'b10:      MEM1_rstrb = 5'b10011;
                    default:    MEM1_rstrb = 5'b10001;
                endcase
            default://LW LL
                                MEM1_rstrb = 5'b11111;
        endcase

        always@(*)
        case(MEM1_DMSel)
            4'b0000,4'b0101,4'b0110://SB LBU LB 
                                MEM1_type = 3'b000;
            4'b0001,4'b0111,4'b1000://SH LHU LH
                                MEM1_type = 3'b001;
            default://SW SC SWL SWR LW LL LWL LWR
                                MEM1_type = 3'b010;
        endcase



endmodule

module cache_select_dm(
    MEM_cache_sel, uncache_Out, dcache_Out, MEM_unCache_data_ok, MEM_dCache_data_ok,
    MEM_uncache_rd_req, MEM_dcache_rd_req, MEM_uncache_wr_req, MEM_dcache_wr_req,
    MEM_uncache_rd_type, MEM_dcache_rd_type, MEM_uncache_wr_type, MEM_dcache_wr_type,
    MEM_uncache_rd_addr, MEM_dcache_rd_addr, MEM_uncache_wr_addr, MEM_dcache_wr_addr,
    MEM_uncache_wr_wstrb, MEM_dcache_wr_wstrb,

    cache_Out, MEM_data_ok, MEM_rd_req, MEM_wr_req, MEM_rd_type, MEM_wr_type, MEM_rd_addr,
    MEM_wr_addr, MEM_wr_wstrb
                );
    input           MEM_cache_sel;
    input[31:0]     uncache_Out;
    input[31:0]     dcache_Out;
    input           MEM_unCache_data_ok;
    input           MEM_dCache_data_ok;
    input           MEM_uncache_rd_req;
    input           MEM_dcache_rd_req;
    input           MEM_uncache_wr_req;
    input           MEM_dcache_wr_req;
    input [2:0]     MEM_uncache_rd_type;
    input [2:0]     MEM_dcache_rd_type;
    input [2:0]     MEM_uncache_wr_type;
    input [2:0]     MEM_dcache_wr_type;
    input [31:0]    MEM_uncache_rd_addr;
    input [31:0]    MEM_dcache_rd_addr;
    input [31:0]    MEM_uncache_wr_addr;
    input [31:0]    MEM_dcache_wr_addr;
    input [3:0]     MEM_uncache_wr_wstrb;
    input [3:0]     MEM_dcache_wr_wstrb;

    output [31:0]   cache_Out;
    output          MEM_data_ok;
    output          MEM_rd_req;
    output          MEM_wr_req;
    output [2:0]    MEM_rd_type;
    output [2:0]    MEM_wr_type;
    output [31:0]   MEM_rd_addr;
    output [31:0]   MEM_wr_addr;
    output [3:0]    MEM_wr_wstrb;

	assign cache_Out = MEM_cache_sel ? uncache_Out : dcache_Out;
	assign MEM_data_ok = MEM_cache_sel ? MEM_unCache_data_ok : MEM_dCache_data_ok;
	assign MEM_rd_req = MEM_cache_sel ? MEM_uncache_rd_req : MEM_dcache_rd_req;
	assign MEM_wr_req = MEM_cache_sel ? MEM_uncache_wr_req : MEM_dcache_wr_req;
	assign MEM_rd_type = MEM_cache_sel ? MEM_uncache_rd_type : MEM_dcache_rd_type;
	assign MEM_wr_type = MEM_cache_sel ? MEM_uncache_wr_type : MEM_dcache_wr_type;
	assign MEM_rd_addr = MEM_cache_sel ? MEM_uncache_rd_addr : MEM_dcache_rd_addr;
	assign MEM_wr_addr = MEM_cache_sel ? MEM_uncache_wr_addr : MEM_dcache_wr_addr;
	assign MEM_wr_wstrb = MEM_cache_sel ? MEM_uncache_wr_wstrb : MEM_dcache_wr_wstrb;

endmodule

module cache_select_im(
    IF_cache_sel, uncache_Out, icache_Out, IF_uncache_data_ok, IF_icache_data_ok,
    IF_uncache_rd_req, IF_icache_rd_req, IF_uncache_wr_req, IF_icache_wr_req,
    IF_uncache_rd_type, IF_icache_rd_type, IF_uncache_wr_type, IF_icache_wr_type,
    IF_uncache_rd_addr, IF_icache_rd_addr, IF_uncache_wr_addr, IF_icache_wr_addr,
    IF_uncache_wr_wstrb, IF_icache_wr_wstrb,

    cache_Out, IF_data_ok, IF_rd_req, IF_wr_req, IF_rd_type, IF_wr_type, IF_rd_addr,
    IF_wr_addr, IF_wr_wstrb
                );
    input           IF_cache_sel;
    input [31:0]    uncache_Out;
    input [31:0]    icache_Out;
    input           IF_uncache_data_ok;
    input           IF_icache_data_ok;
    input           IF_uncache_rd_req;
    input           IF_icache_rd_req;
    input           IF_uncache_wr_req;
    input           IF_icache_wr_req;
    input [2:0]     IF_uncache_rd_type;
    input [2:0]     IF_icache_rd_type;
    input [2:0]     IF_uncache_wr_type;
    input [2:0]     IF_icache_wr_type;
    input [31:0]    IF_uncache_rd_addr;
    input [31:0]    IF_icache_rd_addr;
    input [31:0]    IF_uncache_wr_addr;
    input [31:0]    IF_icache_wr_addr;
    input [3:0]     IF_uncache_wr_wstrb;
    input [3:0]     IF_icache_wr_wstrb;

    output [31:0]   cache_Out;
    output          IF_data_ok;
    output          IF_rd_req;
    output          IF_wr_req;
    output [2:0]    IF_rd_type;
    output [2:0]    IF_wr_type;
    output [31:0]   IF_rd_addr;
    output [31:0]   IF_wr_addr;
    output [3:0]    IF_wr_wstrb;

	assign cache_Out = IF_cache_sel ? uncache_Out : icache_Out;
	assign IF_data_ok = IF_cache_sel ? IF_uncache_data_ok : IF_icache_data_ok;
	assign IF_rd_req = IF_cache_sel ? IF_uncache_rd_req : IF_icache_rd_req;
	assign IF_wr_req = IF_cache_sel ? IF_uncache_wr_req : IF_icache_wr_req;
	assign IF_rd_type = IF_cache_sel ? IF_uncache_rd_type : IF_icache_rd_type;
	assign IF_wr_type = IF_cache_sel ? IF_uncache_wr_type : IF_icache_wr_type;
	assign IF_rd_addr = IF_cache_sel ? IF_uncache_rd_addr : IF_icache_rd_addr;
	assign IF_wr_addr = IF_cache_sel ? IF_uncache_wr_addr : IF_icache_wr_addr;
	assign IF_wr_wstrb = IF_cache_sel ? IF_uncache_wr_wstrb : IF_icache_wr_wstrb;

endmodule


module debug(
    MUX10Out, WB_PC, WB_RFWr, MEM2_WBWr,WB_RD,

    debug_wb_rf_wdata, debug_wb_pc, debug_wb_rf_wen,
    debug_wb_rf_wnum
    );
    input[31:0] MUX10Out;
    input[31:0] WB_PC;
    input WB_RFWr;
    input MEM2_WBWr;
    input[4:0] WB_RD;

    output[31:0] debug_wb_rf_wdata;
    output[31:0] debug_wb_pc;
    output[3:0] debug_wb_rf_wen;
    output[4:0] debug_wb_rf_wnum;

assign
	debug_wb_rf_wdata = MUX10Out;
assign
	debug_wb_pc  = WB_PC;
assign
	debug_wb_rf_wen  = {4{WB_RFWr&MEM2_WBWr&(WB_RD!=5'd0)}};
assign
	debug_wb_rf_wnum  = WB_RD;

endmodule