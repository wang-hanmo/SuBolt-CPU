 `include "MacroDef.v"
module mips(
    ext_int_in   ,   //high active

    clk      ,
    rst      ,   //low active

    arid      ,
    araddr    ,
    arlen     ,
    arsize    ,
    arburst   ,
    arlock    ,
    arcache   ,
    arprot    ,
    arvalid   ,
    arready   ,

    rid       ,
    rdata     ,
    rresp     ,
    rlast     ,
    rvalid    ,
    rready    ,

    awid      ,
    awaddr    ,
    awlen     ,
    awsize    ,
    awburst   ,
    awlock    ,
    awcache   ,
    awprot    ,
    awvalid   ,
    awready   ,

    wid       ,
    wdata     ,
    wstrb     ,
    wlast     ,
    wvalid    ,
    wready    ,

    bid       ,
    bresp     ,
    bvalid    ,
    bready    ,

    //debug interface
    debug_wb_pc      ,
    debug_wb_rf_wen  ,
    debug_wb_rf_wnum ,
    debug_wb_rf_wdata
);
// 中断信号
    input [5:0]     ext_int_in      ;  //interrupt,high active;
// 时钟与复位信�????
    input           clk      ;
    input           rst      ;   //low active
// 读请求信号�?�道
    output [ 3:0]   arid      ;
    output [31:0]   araddr    ;
    output [ 3:0]   arlen     ;
    output [ 2:0]   arsize    ;
    output [ 1:0]   arburst   ;
    output [ 1:0]   arlock    ;
    output [ 3:0]   arcache   ;
    output [ 2:0]   arprot    ;
    output          arvalid   ;
    input           arready   ;
//读相应信号�?�道
    input [ 3:0]    rid       ;
    input [31:0]    rdata     ;
    input [ 1:0]    rresp     ;
    input           rlast     ;
    input           rvalid    ;
    output          rready    ;
//写请求信号�?�道
    output [ 3:0]   awid      ;
    output [31:0]   awaddr    ;
    output [ 3:0]   awlen     ;
    output [ 2:0]   awsize    ;
    output [ 1:0]   awburst   ;
    output [ 1:0]   awlock    ;
    output [ 3:0]   awcache   ;
    output [ 2:0]   awprot    ;
    output          awvalid   ;
    input           awready   ;
// 写数据信号�?�道
    output [ 3:0]   wid       ;
    output [31:0]   wdata     ;
    output [ 3:0]   wstrb     ;
    output          wlast     ;
    output          wvalid    ;
    input           wready    ;
// 写相应信号�?�道
    input  [3:0]    bid       ;
    input  [1:0]    bresp     ;
    input           bvalid    ;
    output          bready    ;
//debug
    output [31:0]   debug_wb_pc      ;
    output [3:0]    debug_wb_rf_wen  ;
    output [4:0]    debug_wb_rf_wnum ;
    output [31:0]   debug_wb_rf_wdata;


	/*signals defination*/
    //--------------Pre_F---------------//
	wire            PF_Exception;
	wire [4:0]      PF_ExcCode;
	wire            PF_TLBRill_Exc;//imply the TLB Rill Exception,which has a special exception entry
	wire            PF_TLB_Exc;//include TLB Rill�? TLB Invalid, TLB Modified exception
	wire            PF_invalid;
    wire            PF_icache_sel;
    wire            PF_icache_valid;
    wire            PF_uncache_valid;
    wire [ 1:0]      s0_index;
    wire [18:0]     s0_vpn2;
    wire            s0_odd_page;
    wire [ 7:0]     s0_asid;
    wire            s0_found;
    wire [19:0]     s0_pfn;
    wire [ 2:0]     s0_c;
    wire            s0_d;
    wire            s0_v;
    wire [31:0]     PF_PC;
    wire            PF_IFWr;
    wire            PF_Flush;
    wire            PF_Instr_Flush;

    wire [31:0]     NPC_op00;
    wire [31:0]     NPC_op01;
    wire [31:0]     NPC_op10;
    wire            flush_condition_00;
    wire            flush_condition_01;
    wire            flush_condition_10;
    wire            flush_condition_11;
    wire [31:0]     target_addr_final;
    wire            ee;
    wire [31:0]     NPC_ee;

    wire [31:0]     NPC_op00_reg;
    wire [31:0]     NPC_op01_reg;
    wire [31:0]     NPC_op10_reg;
    wire            flush_condition_00_reg;
    wire            flush_condition_01_reg;
    wire            flush_condition_10_reg;
    wire            flush_condition_11_reg;
    wire [31:0]     target_addr_final_reg;
    wire            ee_reg;
    wire [31:0]     NPC_ee_reg;

    wire[31:0]      ret_addr_reg;
    wire[1:0]       NPCOp_reg;
	//--------------IF----------------//
    wire[31:0]      IF_PC;
    wire[31:0]      PPC;
    //i_cache
    wire            IF_iCache_addr_ok;
	wire            IF_iCache_data_ok;
	wire [31:0]     IF_iCache_rdata;
    wire            IF_icache_rd_req;
	wire [2:0]      IF_icache_rd_type;
	wire [31:0]     IF_icache_rd_addr;
	wire            IF_icache_rd_rdy;
	wire            IF_icache_ret_valid;
	wire            IF_icache_ret_last;
	wire [31:0]     IF_icache_ret_data;
	wire            IF_icache_wr_req;
	wire [2:0]      IF_icache_wr_type;
	wire [31:0]     IF_icache_wr_addr;
	wire [3:0]      IF_icache_wr_wstrb;
	wire [511:0]    IF_icache_wr_data;
	wire            IF_icache_wr_rdy;
    
    wire            icache_stall;
	wire            IF_Exception;
    wire            Temp_IF_Exception;
	wire [4:0]      Temp_IF_ExcCode;
    wire [4:0]      IF_ExcCode;
	wire            IF_TLBRill_Exc;
	wire            IF_TLB_Exc;
	wire            IF_invalid;
    wire            IF_icache_sel;
    wire            IF_uncache_valid;
    wire [31:0]     IF_PPC;
    wire [31:0]     Instr;
    //i_uncache
    wire            IF_uncache_data_ok;
    wire [31:0]     IF_uncache_rdata;
    wire            IF_uncache_rd_req;
    wire            IF_uncache_wr_req;
    wire [2:0]      IF_uncache_rd_type;
    wire [2:0]      IF_uncache_wr_type;
    wire [31:0]     IF_uncache_rd_addr;
    wire [31:0]     IF_uncache_wr_addr;
    wire [31:0]     IF_uncache_wr_data;
    wire [3:0]      IF_uncache_wr_wstrb;
	wire            IF_uncache_rd_rdy;
	wire            IF_uncache_ret_valid;
	wire            IF_uncache_ret_last;
	wire [31:0]     IF_uncache_ret_data;
	wire            IF_uncache_wr_rdy;


    wire            IF_data_ok;
    wire            IF_rd_req;
    wire            IF_wr_req;
    wire [2:0]      IF_rd_type;
    wire [2:0]      IF_wr_type;
    wire [31:0]     IF_rd_addr;
    wire [31:0]     IF_wr_addr;
    wire [3:0]      IF_wr_wstrb;

    wire            branch;
    wire [31:0]     target_addr;
    wire            IF_PC_invalid;
    wire            IF_BJOp;       
    wire            refetch;
    //--------------ID----------------//
    wire [31:0]     ID_PC;
    wire [31:0]     ID_Instr;
    wire [31:0]     GPR_RS;
    wire [31:0]     GPR_RT;
    wire [1:0]      EXTOp;
    wire [31:0]     Imm32;
    wire            CMPOut1;
    wire [3:0]      CMPOut2;
    wire [31:0]     MUX8Out;
    wire [31:0]     MUX9Out;
    wire [22:0]      MUX7Out;
    wire            ID_dcache_en;
    wire            DMWr;
    wire            RFWr;
    wire            RHLWr;
    wire [1:0]      MUX1Sel;
    wire [2:0]      MUX2_6Sel;
    wire            MUX3Sel;
    wire            DMRd;
    wire [1:0]      NPCOp;
    wire [4:0]      ALU1Op;
    wire            ALU1Sel;
    wire [3:0]      ALU2Op;
    wire            RHLSel_Rd;
	wire [1:0]      RHLSel_Wr;
    wire [3:0]      DMSel;
    wire            ID_BJOp;
    wire            eret_flush;
    wire            CP0WrEn;
	wire            Exception;
    wire [4:0]      ExcCode;
    wire            isBD;
    wire            isBranch;
    wire            CP0Rd;
    wire            start;
	wire            RHL_visit;

    wire            Temp_ID_Excetion;
    wire            ID_Exception;
	wire [4:0]      ID_ExcCode;
    wire [4:0]      Temp_ID_ExcCode;
	wire            ID_TLBRill_Exc;
	wire            ID_tlb_searchen;
	wire            ID_MUX12Sel;
    wire            ID_MUX11Sel;
	wire            ID_TLB_Exc;
	wire            TLB_flush;
	wire            TLB_writeen;
	wire            TLB_readen;
    wire            CMPOut3;
    wire            Branch_flush;
    wire            LL_signal;
    wire            SC_signal;
    wire            movz_movn;
    wire            ID_WAIT_OP;
    wire            icache_valid_CI;
	wire            icache_op_CI;
	wire            dcache_valid_CI;
	wire [1:0]      dcache_op_CI;

    wire [1:0]      ID_BrType;
    wire [1:0]      ID_JType;
    wire [4:0]      ID_MUX1Out;
    wire [31:0]     ID_MUX3Out;
    wire            ID_isBL;
	//--------------EX----------------//
    wire            EX_isBranch;
    wire            EX_isBusy;
    wire            EX_eret_flush;
    wire            EX_CP0WrEn;
    wire            EX_Exception;
    wire [4:0]      EX_ExcCode;
    wire            EX_isBD;
    wire            EX_RHLSel_Rd;
	wire            EX_DMWr;
    wire            EX_DMRd;
    wire            EX_MUX3Sel;
    wire            EX_ALU1Sel;
	wire            EX_RFWr;
    wire            EX_RHLWr;
    wire [3:0]      EX_ALU2Op;
    wire [1:0]      EX_MUX1Sel;
	wire [1:0]      EX_RHLSel_Wr;
    wire [3:0]      EX_DMSel;
    wire [2:0]      EX_MUX2Sel;
    wire [4:0]      EX_ALU1Op;
    wire [4:0]      EX_RS;
    wire [4:0]      EX_RT;
    wire [4:0]      EX_RD;
    wire [4:0]      EX_shamt;
    wire [31:0]     EX_PC;
	wire [31:0]     EX_GPR_RS;
    wire [31:0]     EX_GPR_RT;
    wire [31:0]     EX_Imm32;
    wire [7:0]      EX_CP0Addr;
	wire            EX_CP0Rd;
    wire            EX_start;
    wire            EX_dcache_en;
    wire [1:0]      EX_MUX4Sel;
    wire [1:0]      EX_MUX5Sel;

    wire [4:0]      EX_MUX1Out;
    wire [31:0]     EX_MUX3Out;
    wire [31:0]     MUX4Out;
    wire [31:0]     MUX5Out;
    wire [31:0]     RHLOut;
    wire [31:0]     ALU1Out;
    wire            Overflow;
	wire [4:0]      Temp_EX_ExcCode;
	wire            EX_TLBRill_Exc;
	wire            EX_tlb_searchen;
	wire            EX_MUX12Sel;
    wire            EX_MUX11Sel;
	wire            EX_TLB_Exc;
	wire            EX_TLB_writeen;
	wire            EX_TLB_readen;
    wire            EX_TLB_flush;
    wire [31:0]     MULOut;
    wire            MUL_sign;
    wire            Trap;
    wire            EX_LL_signal;
    wire            EX_SC_signal;
    wire            EX_icache_valid_CI;
	wire            EX_icache_op_CI;
	wire            EX_dcache_valid_CI;
	wire [1:0]      EX_dcache_op_CI;
    wire            EX_WAIT_OP;
    wire [31:0]     MUX13Out;
    wire [1:0]      EX_NPCOp;
    wire            EX_stall;
    wire            EX_MUX7Sel;
    wire [1:0]      EX_BrType;
    wire [1:0]      EX_JType;
    wire [25:0]     EX_Imm26;
    wire [31:0]     EX_address;
    wire [18:0]     EX_s1_vpn2;
    wire [31:0]     add_result;
    wire [31:0]     MUX4Out_forALU1;
    wire [31:0]     MUX5Out_forALU1;
    wire [31:0]     MUX14Out;

    wire [3:0]      EX_match1;
    wire [31:0]     Ebase_out;  
    wire            EX_Branch_flush;
    wire            EX_isBL;
    wire            EX_MUX6Sel; 
    wire            EX_MUX10Sel;     
	//-------------MEM1---------------//
    wire            MEM1_eret_flush;
    wire            MEM1_Exception;
    wire [31:0]     MUX6Out;
    wire            Interrupt;
    wire [31:0]     EPCOut;
    wire [31:0]     CP0Out;
    wire            MEM1_DMWr;
    wire            MEM1_DMRd;
    wire            MEM1_RFWr;
    wire            MEM1_CP0WrEn;
    wire            Temp_M1_Exception;
    wire [4:0]      Temp_M1_ExcCode;
    wire            MEM1_isBD;
    wire [3:0]      MEM1_DMSel;
    wire [2:0]      MEM1_MUX2Sel;
    wire [4:0]      MEM1_RD;
    wire [31:0]     MEM1_PC;
    wire [31:0]     MEM1_MUX13Out;
    wire [31:0]     MEM1_ALU1Out;
    wire [31:0]     MEM1_GPR_RT;
    wire [7:0]      MEM1_CP0Addr;
    wire            MEM1_CP0Rd;
    wire            MEM1_dcache_en;
    wire            MEM1_Overflow;
    wire [4:0]      MEM1_ExcCode;
    wire [31:0]     MEM1_badvaddr;
    wire [31:0]     MEM1_Paddr;
    wire            MEM1_cache_sel;
    wire            MEM1_dcache_valid;
    wire            DMWen_dcache;
    wire [3:0]      MEM1_dCache_wstrb;
    wire [18:0]     s1_vpn2;
    wire            s1_odd_page;
    wire [ 7:0]     s1_asid;
    wire            s1_found;
    wire [ 1:0]     s1_index;
    wire [19:0]     s1_pfn;
    wire [ 2:0]     s1_c;
    wire            s1_d;
    wire            s1_v;
	wire            MEM1_TLB_Exc;
    wire            MEM1_TLBRill_Exc;
	wire            MEM1_MUX12Sel;
    wire            MEM1_tlb_searchen;
    wire            MEM1_MUX11Sel;
	wire            MEM1_TLB_flush;
	wire            MEM1_TLB_writeen;
	wire            MEM1_TLB_readen;
	wire [31:0]     Index_out;
    wire [31:0]     EntryLo0_out;
    wire [31:0]     EntryLo1_out;
    wire [31:0]     EntryHi_out;
    wire [31:0]     Random_out;
    wire            Temp_MEM1_TLB_Exc;
    wire            Temp_MEM1_TLBRill_Exc;
    wire            MEM1_uncache_valid;
    wire            MEM1_DMen;
    wire [31:0]     MEM1_wdata;
    wire [2:0]      Config_K0_out;
    wire [31:0]     MEM1_MULOut;
    wire            MEM1_Trap;
    wire            MEM1_LL_signal;
    wire            MEM1_SC_signal;
    wire [31:0]     MEM1_SCOut;
    wire            MEM1_icache_valid_CI;
	wire            MEM1_icache_op_CI;
	wire            MEM1_dcache_valid_CI;
	wire [1:0]      MEM1_dcache_op_CI;
    wire            Status_BEV;
    wire            Status_EXL;
    wire            Cause_IV;
    wire            MEM1_WAIT_OP;
    wire            Cause_CE_Wr;
    wire            MEM1_invalid;      
    wire            MEM1_ee;   
    wire [4:0]      MEM1_rstrb;
    wire [2:0]      MEM1_type;   

    wire [3:0]      match1;
    wire            MEM1_MUX6Sel;
    wire            MEM1_MUX10Sel;
	//-------------MEM2---------------//
    wire            MEM2_RFWr;
    wire [4:0]      MEM2_RD;
    wire [31:0]     MUX2Out;
    wire [2:0]      MEM2_MUX2Sel;
    wire [31:0]     MEM2_PC;
    wire [31:0]     MEM2_ALU1Out;
    wire [31:0]     MEM2_MUX6Out;
    wire [31:0]     MEM2_CP0Out;
    wire [4:0]      MEM2_rstrb;
    wire [2:0]      MEM2_type;
    wire            MEM2_cache_sel;
    wire            MEM2_Exception;
    wire            MEM2_eret_flush;
    wire            MEM2_dcache_en;
    wire [31:0]     MEM2_Paddr;
    wire [3:0]      MEM2_unCache_wstrb;
    wire [31:0]     MEM2_GPR_RT;
    wire            MEM2_DMen;
    wire            DMWen_uncache;
    wire            MEM2_uncache_valid;
    wire [31:0]     DMOut;
    wire            MEM2_DMRd;
    wire            MEM2_CP0Rd;
    wire            MEM2_TLB_writeen;
	wire            MEM2_TLB_readen;
	wire            MEM2_TLB_flush;
    wire [1:0]      MEM2_LoadOp;
    wire [31:0]     MEM2_wdata;
    wire [31:0]     MEM2_SCOut;
    wire            MEM2_icache_valid_CI;
    wire            MEM2_invalid;  
    wire            MEM2_MUX10Sel;
    //--------------WB----------------//
    wire [31:0]     WB_PC;
	wire [31:0]     WB_MUX2Out;
	wire [2:0]      WB_MUX2Sel;
	wire [4:0]      WB_RD;
	wire            WB_RFWr;
    wire [31:0]     WB_DMOut;
    wire [31:0]     MUX10Out;
	wire            we;//write enable
    wire [ 1:0]     w_index;
    wire [18:0]     w_vpn2;
    wire [ 7:0]     w_asid;
    wire            w_g;
    wire [19:0]     w_pfn0;
    wire [ 2:0]     w_c0;
    wire            w_d0;
    wire            w_v0;
    wire [19:0]     w_pfn1;
    wire [ 2:0]     w_c1;
    wire            w_d1;
    wire            w_v1;

	wire [ 3:0]     r_index;
    wire [18:0]     r_vpn2;
    wire [ 7:0]     r_asid;
    wire            r_g;
    wire [19:0]     r_pfn0;
    wire [ 2:0]     r_c0;
    wire            r_d0;
    wire            r_v0;
    wire [19:0]     r_pfn1;
    wire [ 2:0]     r_c1;
    wire            r_d1;
    wire            r_v1;
	wire            WB_TLB_flush;
	wire            WB_TLB_writeen;
	wire            WB_TLB_readen;
    wire            WB_icache_valid_CI;
    wire            WB_MUX10Sel;
    //-------------ELSE---------------//
    wire            isStall;
    wire            dcache_stall;
    wire            MUX7Sel;
    wire [1:0]      MUX8Sel;
    wire [1:0]      MUX9Sel;
    wire [1:0]      MUX4Sel;
    wire [1:0]      MUX5Sel;
    wire            PCWr;
    wire            IF_IDWr;
    wire            ID_EXWr;
    wire            EX_MEM1Wr;
    wire            MEM1_MEM2Wr;
    wire            MEM2_WBWr;
    wire            PC_Flush;
    wire            IF_Flush;
    wire            ID_Flush;
    wire            EX_Flush;
    wire            MEM1_Flush;
    wire            MEM2_Flush;
    wire            insert_nop_toID;      
    wire            Invalidate_signal;
    //d_cache
    wire            MEM_dCache_addr_ok;
    wire            MEM_dCache_data_ok;
    wire [31:0]     dcache_Out;
  	wire            MEM_dcache_rd_req;
    wire [2:0]      MEM_dcache_rd_type;
    wire [31:0]     MEM_dcache_rd_addr;
    wire            MEM_dcache_rd_rdy;
	wire            MEM_dcache_ret_valid;
    wire            MEM_dcache_ret_last;
    wire [31:0]     MEM_dcache_ret_data;
    wire            MEM_dcache_wr_req;
    wire [2:0]      MEM_dcache_wr_type;
    wire [31:0]     MEM_dcache_wr_addr;
	wire [3:0]      MEM_dcache_wr_wstrb;
    wire [511:0]    MEM_dcache_wr_data;
    wire            MEM_dcache_wr_rdy;
    //d_uncache
    wire            MEM_unCache_data_ok;
    wire [31:0]     uncache_Out;
    wire            MEM_uncache_rd_req;
    wire            MEM_uncache_wr_req;
    wire [2:0]      MEM_uncache_rd_type;
    wire [2:0]      MEM_uncache_wr_type;
    wire [31:0]     MEM_uncache_rd_addr;
    wire [31:0]     MEM_uncache_wr_addr;
    wire [3:0]      MEM_uncache_wr_wstrb;
    wire [31:0]     MEM_uncache_wr_data;
    wire            MEM_uncache_rd_rdy;
	wire            MEM_uncache_ret_valid;
    wire            MEM_uncache_ret_last;
    wire [31:0]     MEM_uncache_ret_data;
    wire            MEM_uncache_wr_rdy;

    wire [31:0]     cache_Out;
    wire            MEM_data_ok;
    wire            MEM_rd_req;
    wire            MEM_wr_req;
    wire [2:0]      MEM_rd_type;
    wire [2:0]      MEM_wr_type;
    wire [31:0]     MEM_rd_addr;
    wire [31:0]     MEM_wr_addr;
    wire [3:0]      MEM_wr_wstrb;

    wire            Instr_Flush;
    wire            data_stall;
    wire            whole_stall;

    //to introduce fanout
    wire [31:0]     MEM1_ALU1Out_forExPa;
    wire [25:0]     Imm26_forBP;
	wire [15:0]     Imm16_forEXT;
	wire [25:0]     Imm26_forDFF;
	wire [5:0]      op;
	wire [5:0]      func;
	wire [4:0]      shamt;
	wire [7:0]      CP0Addr;
	wire [4:0]      rs_forRF;
	wire [4:0]      rs_forCtrl;
	wire [4:0]      rs_forDFF;
	wire [4:0]      rs_forBypass;
	wire [4:0]      rs_forStall;
	wire [4:0]      rt_forRF;
	wire [4:0]      rt_forCtrl;
	wire [4:0]      rt_forDFF;
	wire [4:0]      rt_forBypass;
	wire [4:0]      rt_forStall;
	wire [4:0]      rt_forMUX1;
	wire [4:0]      rd_forMUX1;
    wire [31:0]     EX_GPR_RS_forALU1;
    wire [31:0]     EX_GPR_RT_forALU1;
    wire [1:0]      MUX4Sel_forALU1;
    wire [1:0]      MUX5Sel_forALU1;
    wire [1:0]      EX_MUX4Sel_forALU1;
    wire [1:0]      EX_MUX5Sel_forALU1;
    wire [4:0]      rs_forBypass_forCMP;
    wire [1:0]      MUX8Sel_forCMP;
    wire [31:0]     MUX8Out_forCMP;
    wire [4:0]      rt_forBypass_forCMP;
    wire [1:0]      MUX9Sel_forCMP;
    wire [31:0]     MUX9Out_forCMP;


/************** ILA DEBUG ***************/
    wire[31:0] EX_Instr;
    wire[31:0] MEM1_Instr;
    wire[31:0]	zero;
	wire[31:0]	at;
	wire[31:0]	v0;
	wire[31:0]	v1;
	wire[31:0]	a0;
	wire[31:0]	a1;
	wire[31:0]	a2;
	wire[31:0]	a3;
	wire[31:0]	t0;
	wire[31:0]	t1;
	wire[31:0]	t2;
	wire[31:0]	t3;
	wire[31:0]	t4;
	wire[31:0]	t5;
	wire[31:0]	t6;
	wire[31:0]	t7;
	wire[31:0]	s0;
	wire[31:0]	s1;
	wire[31:0]	s2;
	wire[31:0]	s3;
	wire[31:0]	s4;
	wire[31:0]	s5;
	wire[31:0]	s6;
	wire[31:0]	s7;
	wire[31:0]	t8;
	wire[31:0]	t9;
	wire[31:0]	k0;
	wire[31:0]	k1;
	wire[31:0]	gp;
	wire[31:0]	sp;
	wire[31:0]	fp;
	wire[31:0]	ra;
    wire[31:0]  Status_out;
    wire[31:0]  Cause_out;
    wire[3:0]   state_i_uncache_0;
    wire[3:0]   state_i_cache_1  ;
    wire[3:0]   state_d_uncache_2;
    wire[3:0]   state_d_cache_3  ;
    wire        i_uncache_state;
    wire[2:0]   i_cache_state  ;
    wire        d_uncache_state;
    wire[2:0]   d_cache_state  ;


// ILA_0 U_ILA_0(
//         .clk(clk),
//         //register
//         .probe0(MEM2_PC), .probe1(at), .probe2(v0), .probe3(v1),
//         .probe4(a0), .probe5(a1), .probe6(a2), .probe7(a3),
//         .probe8(t0), .probe9(t1), .probe10(t2), .probe11(t3),
//         .probe12(t4), .probe13(t5), .probe14(t6), .probe15(t7),
//         .probe16(s0), .probe17(s1), .probe18(s2), .probe19(s3),
//         .probe20(s4), .probe21(s5), .probe22(s6), .probe23(s7),
// 	    .probe24(t8), .probe25(t9), .probe26(k0), .probe27(k1),
//         .probe28(gp), .probe29(sp), .probe30(fp), .probe31(ra),
//         //PC Instr
//         .probe32(MEM1_PC), .probe33(MEM1_Instr),
//         //exception
//         .probe34(MEM1_Exception), .probe35(MEM1_ExcCode), .probe36(EPCOut),
//         .probe37(Status_out), .probe38(Cause_out),
//         //axi
//         .probe39(arvalid), .probe40(arready), .probe41(araddr),
//         .probe42(arburst), .probe43(arlen), .probe44(arsize),
//         .probe45(rvalid), .probe46(rready), .probe47(rdata), .probe48(rlast),
//         .probe49(awvalid), .probe50(awready), .probe51(awaddr),
//         .probe52(awburst), .probe53(awlen), .probe54(awsize),
//         .probe55(wvalid), .probe56(wready), .probe57(wdata), .probe58(wstrb),
//         .probe59(bvalid), .probe60(bready)
//     );

// ILA_1 U_ILA_1(
//         .clk(clk),
//         //synchronic
//         .probe0(MEM1_PC), .probe1(MEM1_Instr),
//         //new bridge
//         .probe2(state_i_uncache_0), .probe3(state_i_cache_1),
//         .probe4(state_d_uncache_2), .probe5(state_d_cache_3),
//         //cache
//         .probe6(i_uncache_state), .probe7(i_cache_state),
//         .probe8(d_uncache_state), .probe9(d_cache_state),
//         .probe10(IF_uncache_data_ok), .probe11(IF_iCache_data_ok),
//         .probe12(MEM_unCache_data_ok), .probe13(MEM_dCache_data_ok),
//         //IF MEM2
//         .probe14(IF_PC), .probe15(IF_PPC), .probe16(IF_icache_sel),
//         .probe17(MEM2_PC), .probe18(MEM2_Paddr), .probe19(MEM2_cache_sel),
//         //stall flush
//         .probe20(refetch), .probe21(IF_PC_invalid),
//         .probe22(data_stall), .probe23(whole_stall),
//         .probe24(Cause_out), .probe25(MEM1_Exception), .probe26(MEM1_eret_flush),
//         .probe27(MEM1_ALU1Out)
//     );


/**************DATA PATH***************/
    //--------------PF----------------//
PC U_PC (
        .clk(clk), .rst(rst), .wr(PCWr), .flush(PC_Flush),
		.ret_addr(MUX8Out),.NPCOp(NPCOp), .NPC_op00(NPC_op00), .NPC_op01(NPC_op01), .NPC_op10(NPC_op10),
        .flush_condition_00(flush_condition_00), .flush_condition_01(flush_condition_01),
        .flush_condition_10(flush_condition_10), .flush_condition_11(flush_condition_11),
        .target_addr_final(target_addr_final), .ee(ee), .NPC_ee(NPC_ee),

		.ret_addr_reg(ret_addr_reg),.NPCOp_reg(NPCOp_reg), .NPC_op00_reg(NPC_op00_reg),
        .NPC_op01_reg(NPC_op01_reg), .NPC_op10_reg(NPC_op10_reg),
        .flush_condition_00_reg(flush_condition_00_reg), .flush_condition_01_reg(flush_condition_01_reg),
        .flush_condition_10_reg(flush_condition_10_reg), .flush_condition_11_reg(flush_condition_11_reg),
        .target_addr_final_reg(target_addr_final_reg),
        .ee_reg(ee_reg), .NPC_ee_reg(NPC_ee_reg)
);

pre_decode U_PRE_DECODE(
    .IF_OP(Instr[31:26]),
    .IF_Funct(Instr[5:0]),

    .IF_BJOp(IF_BJOp)
);

instr_fetch_pre U_INSTR_FETCH(
    PF_PC,PCWr,s0_found,s0_v,s0_pfn,s0_c,IF_uncache_data_ok,
    isStall,TLB_flush,EX_TLB_flush,MEM1_TLB_flush,MEM2_TLB_flush,
    WB_TLB_flush,Config_K0_out,Branch_flush,PF_Instr_Flush,
    icache_valid_CI, EX_icache_valid_CI, MEM1_icache_valid_CI,
    MEM2_icache_valid_CI, WB_icache_valid_CI,

    PF_TLB_Exc,PF_ExcCode,PF_TLBRill_Exc,PF_Exception,PPC,
    PF_invalid,Invalidate_signal,PF_icache_sel,PF_icache_valid,
    PF_uncache_valid, IF_PC_invalid, refetch
    );

branch_predict_prep U_BRANCH_PREDICT_PREP(
    .IF_PC(IF_PC),
    .PF_PC(PF_PC),
    .Imm(Imm26_forBP),
    .PF_Instr_Flush(PF_Instr_Flush),
    .ret_addr(MUX8Out),
    .branch(branch),
    .target_addr(target_addr),
    .MEM1_Exception(MEM1_Exception),
    .MEM1_eret_flush(MEM1_eret_flush),
    .MEM1_ee(MEM1_ee),
    .EPC(EPCOut),
    .Interrupt(Interrupt),
    .Status_BEV(Status_BEV),
    .Status_EXL(Status_EXL),
    .Cause_IV(Cause_IV),
    .MEM1_TLBRill_Exc(MEM1_TLBRill_Exc),
    .WB_TLB_flush(WB_TLB_flush),
    .WB_icache_valid_CI(WB_icache_valid_CI),
    .MEM2_PC(MEM2_PC),
    .Ebase_out(Ebase_out),
    .MEM1_ExcCode(MEM1_ExcCode),

    .NPC_op00(NPC_op00),
    .NPC_op01(NPC_op01),
    .NPC_op10(NPC_op10),
    .flush_condition_00(flush_condition_00),
    .flush_condition_01(flush_condition_01),
    .flush_condition_10(flush_condition_10),
    .flush_condition_11(flush_condition_11),
    .target_addr_final(target_addr_final),
    .ee(ee),
    .NPC_ee(NPC_ee)
);

icache U_ICACHE(
	.clk(clk), .resetn(rst), .exception(MEM1_ee | IF_invalid), .stall(icache_stall),
	// cpu && cache
	/*input*/
  	.valid(PF_icache_valid), .index(PF_PC[11:6]), .tag(IF_PPC[31:12]), .offset(PF_PC[5:0]),
	/*output*/
	.addr_ok(IF_iCache_addr_ok), .data_ok(IF_iCache_data_ok), .rdata(Instr),
	//cache && axi
	/*input*/
  	.rd_rdy(1'b1),
	.ret_valid(IF_icache_ret_valid),.ret_last(IF_icache_ret_last),
	.ret_data(IF_icache_ret_data),.wr_rdy(IF_icache_wr_rdy),
	/*output*/
	.rd_req(IF_icache_rd_req),.wr_req(IF_icache_wr_req),.rd_type(IF_icache_rd_type),
	.wr_type(IF_icache_wr_type),.rd_addr(IF_icache_rd_addr),.wr_addr(IF_icache_wr_addr),
	.wr_wstrb(IF_icache_wr_wstrb), .wr_data(IF_icache_wr_data),
    .valid_CI(MEM1_icache_valid_CI), .op_CI(MEM1_icache_op_CI), .index_CI(MEM1_ALU1Out[11:6]),
    .way_CI(MEM1_ALU1Out[12]), .tag_CI(MEM2_Paddr[31:12]),
    .cache_sel(IF_icache_sel), .uncache_out(IF_uncache_rdata), 
    .uncache_data_ok(IF_uncache_data_ok), .IF_data_ok(IF_data_ok),
    .C_STATE(i_cache_state)
	);
	//--------------IF----------------//
PF_IF U_PF_IF(
		//input
		.clk(clk),.rst(rst),.wr(PF_IFWr),.PF_PC(PF_PC),.PF_Exception(PF_Exception),
        .PF_ExcCode(PF_ExcCode),.PF_TLBRill_Exc(PF_TLBRill_Exc),.PF_TLB_Exc(PF_TLB_Exc),
        .invalid(PF_invalid),.icache_sel(PF_icache_sel),.uncache_valid(PF_uncache_valid),
        .PPC(PPC),.PF_Flush(PF_Flush),

		//output
		.IF_PC(IF_PC),.IF_Exception(IF_Exception),.IF_ExcCode(IF_ExcCode),.IF_TLBRill_Exc(IF_TLBRill_Exc),
		.IF_TLB_Exc(IF_TLB_Exc), .IF_invalid(IF_invalid), .IF_icache_sel(IF_icache_sel),
        .IF_uncache_valid(IF_uncache_valid), .IF_PPC(IF_PPC)
	);
uncache_im U_UNCACHE_IM(
        .clk(clk), .resetn(rst), .wr(PF_IFWr), .exception(MEM1_ee | IF_invalid),
        //CPU_Pipeline side
        /*input*/   .valid(IF_uncache_valid & ~IF_invalid), .addr(IF_PPC),
        /*output*/  .data_ok(IF_uncache_data_ok), .rdata(IF_uncache_rdata),
        //AXI-Bus side
        /*input*/   .rd_rdy(1'b1), .wr_rdy(IF_uncache_wr_rdy),
        .ret_valid(IF_uncache_ret_valid), .ret_last(IF_uncache_ret_valid), .ret_data(IF_uncache_ret_data),
        /*output*/  .rd_req(IF_uncache_rd_req), .wr_req(IF_uncache_wr_req),
        .rd_type(IF_uncache_rd_type), .wr_type(IF_uncache_wr_type), .rd_addr(IF_uncache_rd_addr),
        .wr_addr(IF_uncache_wr_addr), .wr_wstrb(IF_uncache_wr_wstrb), .wr_data(IF_uncache_wr_data),
        .C_STATE(i_uncache_state)
);

// cache_select_im U_CACHE_SELECT_IM(
//     IF_icache_sel, IF_uncache_rdata, IF_iCache_rdata, IF_uncache_data_ok,
//     IF_iCache_data_ok,IF_uncache_rd_req, IF_icache_rd_req, IF_uncache_wr_req,
//     IF_icache_wr_req,IF_uncache_rd_type, IF_icache_rd_type, IF_uncache_wr_type,
//     IF_icache_wr_type,IF_uncache_rd_addr, IF_icache_rd_addr, IF_uncache_wr_addr,
//     IF_icache_wr_addr,IF_uncache_wr_wstrb, IF_icache_wr_wstrb,

//     Instr, IF_data_ok, IF_rd_req, IF_wr_req, IF_rd_type, IF_wr_type, IF_rd_addr,
//     IF_wr_addr, IF_wr_wstrb
//     );

branch_predictor U_BRANCH_PREDICTOR(
    .clk(clk),
    .resetn(rst),
    .index(IF_PC[9:2]),
    .EX_index(EX_PC[9:2]),
    .EX_taken(|EX_NPCOp),
    .EX_valid(~EX_MUX7Sel && ~EX_stall),
    .EX_JType(EX_JType),

    .branch(branch)
);

branch_target_predictor U_BRANCH_TARGET_PREDICTOR(
    .clk(clk),
    .resetn(rst),
    .PF_PC(PF_PC),
    .index(IF_PC[8:2]),
    .tag(IF_PC[31:9]),
    .EX_index(EX_PC[8:2]),
    .EX_tag(EX_PC[31:9]),
    .EX_BrType(EX_BrType),
    .EX_address(EX_address),
    .EX_taken(|EX_NPCOp && ~EX_stall && ~EX_MUX7Sel),

    .target_address(target_addr)
);
    //--------------ID----------------//
IF_ID U_IF_ID(
		.clk(clk), .rst(rst),.IF_IDWr(IF_IDWr),.IF_Flush(IF_Flush),
        .IF_PC(EX_Branch_flush ? PF_PC: PF_Instr_Flush ? PF_PC: IF_PC),
        .Instr(EX_Branch_flush ? 32'd0: Instr & {32{!(PF_Instr_Flush | refetch)}}), 
        .IF_Exception(EX_Branch_flush ? 1'b0: IF_Exception & !(PF_Instr_Flush | refetch)),
		.IF_ExcCode(IF_ExcCode),
        .IF_TLBRill_Exc(EX_Branch_flush ? 1'b0: IF_TLBRill_Exc & !(PF_Instr_Flush | refetch)),
        .IF_TLB_Exc(EX_Branch_flush ? 1'b0: IF_TLB_Exc & !(PF_Instr_Flush | refetch)), 
        .IF_BJOp(EX_Branch_flush ? 1'b0: IF_BJOp & !(PF_Instr_Flush | refetch)),
        .EPC(EPCOut),

		.ID_PC(ID_PC), .ID_Instr(ID_Instr),.Temp_ID_Excetion(Temp_ID_Excetion),
		.Temp_ID_ExcCode(Temp_ID_ExcCode),.ID_TLBRill_Exc(ID_TLBRill_Exc),.ID_TLB_Exc(ID_TLB_Exc),

        .Imm26_forBP(Imm26_forBP), .Imm16_forEXT(Imm16_forEXT), .Imm26_forDFF(Imm26_forDFF),
        .op(op), .func(func), .shamt(shamt), .CP0Addr(CP0Addr), .rs_forRF(rs_forRF), .rs_forCtrl(rs_forCtrl),
        .rs_forDFF(rs_forDFF), .rs_forBypass(rs_forBypass), .rs_forStall(rs_forStall), .rt_forRF(rt_forRF),
        .rt_forCtrl(rt_forCtrl), .rt_forDFF(rt_forDFF), .rt_forBypass(rt_forBypass), .rt_forStall(rt_forStall),
        .rt_forMUX1(rt_forMUX1), .rd_forMUX1(rd_forMUX1),.ID_BJOp(ID_BJOp), 
        .rs_forBypass_forCMP(rs_forBypass_forCMP), .rt_forBypass_forCMP(rt_forBypass_forCMP)
	);

rf U_RF(
		.Addr1(rs_forRF), .Addr2(rt_forRF), .Addr3(WB_RD),
		.WD(MUX10Out), .RFWr(WB_RFWr), .clk(clk),

		.rst(rst), .RD1(GPR_RS), .RD2(GPR_RT),
    .zero(zero),
	.at(at),
	.v0(v0),
	.v1(v1),
	.a0(a0),
	.a1(a1),
	.a2(a2),
	.a3(a3),
	.t0(t0),
	.t1(t1),
	.t2(t2),
	.t3(t3),
	.t4(t4),
	.t5(t5),
	.t6(t6),
	.t7(t7),
	.s0(s0),
	.s1(s1),
	.s2(s2),
	.s3(s3),
	.s4(s4),
	.s5(s5),
	.s6(s6),
	.s7(s7),
	.t8(t8),
	.t9(t9),
	.k0(k0),
	.k1(k1),
	.gp(gp),
	.sp(sp),
	.fp(fp),
	.ra(ra)
	);

ext U_EXT(
		.Imm16(Imm16_forEXT), .EXTOp(EXTOp),

		.Imm32(Imm32)
    );

mux3 U_MUX3(
		.RD2(MUX9Out), .Imm32(Imm32), .MUX3Sel(MUX3Sel),

		.B(ID_MUX3Out)
	);
    
cmp U_CMP(
		.GPR_RS(MUX8Out_forCMP), .GPR_RT(MUX9Out_forCMP),

		.CMPOut1(CMPOut1), .CMPOut2(CMPOut2),.CMPOut3(CMPOut3)
	);

mux7 U_MUX7(
		.WRSign({
            ID_isBL,            //22
            Branch_flush,       //21
            eret_flush,         //20
            LL_signal,          //19
            SC_signal,          //18
            icache_valid_CI,    //17
            dcache_valid_CI,    //16
            ID_WAIT_OP,         //15
            DMRd,               //14
            CP0WrEn,            //13
            ID_Exception,       //12
            isBD,               //11
            isBranch,           //10
            CP0Rd,              // 9
            start,              // 8
            ID_TLB_Exc,         // 7
            TLB_writeen,        // 6
            TLB_readen,         // 5
            ID_tlb_searchen,    // 4
            ID_dcache_en,       // 3
            DMWr,               // 2
            RFWr,               // 1
            RHLWr               // 0
            }), .MUX7Sel(MUX7Sel),

		.MUX7Out(MUX7Out)
	);

mux8 U_MUX8(
		.GPR_RS(GPR_RS), .data_MEM1(MUX6Out), .data_MEM2(MUX2Out), .MUX8Sel(MUX8Sel),
        .WD(MUX10Out),

		.out(MUX8Out)
	);

mux8 U_MUX8_forCMP(
		.GPR_RS(GPR_RS), .data_MEM1(MUX6Out), .data_MEM2(MUX2Out), 
        .MUX8Sel(MUX8Sel_forCMP), .WD(MUX10Out),

		.out(MUX8Out_forCMP)
	);

mux9 U_MUX9(
		.GPR_RT(GPR_RT), .data_MEM1(MUX6Out), .data_MEM2(MUX2Out), .MUX9Sel(MUX9Sel),
        .WD(MUX10Out),

		.out(MUX9Out)
	);

mux9 U_MUX9_forCMP(
		.GPR_RT(GPR_RT), .data_MEM1(MUX6Out), .data_MEM2(MUX2Out), 
        .MUX9Sel(MUX9Sel_forCMP), .WD(MUX10Out),

		.out(MUX9Out_forCMP)
	);

ctrl U_CTRL(
		.clk(clk),.rst(rst),.OP(op),.Funct(func),.rt(rt_forCtrl),.CMPOut1(CMPOut1),
		.CMPOut2(CMPOut2),.rs(rs_forCtrl),.EXE_isBranch(EX_isBranch),.Temp_ID_Excetion(Temp_ID_Excetion),
        .IF_Flush(IF_Flush),.Temp_ID_ExcCode(Temp_ID_ExcCode),.ID_TLB_Exc(ID_TLB_Exc),.rd(ID_Instr[15:11]),
        .CMPOut3(CMPOut3),.shamt(ID_Instr[10:6]), .ID_BJOp(ID_BJOp), .EX_isBL(EX_isBL),

		.MUX1Sel(MUX1Sel),.MUX2Sel(MUX2_6Sel),.MUX3Sel(MUX3Sel),.RFWr(RFWr),.RHLWr(RHLWr),.DMWr(DMWr),.DMRd(DMRd),
		.NPCOp(NPCOp),.EXTOp(EXTOp),.ALU1Op(ALU1Op),.ALU1Sel(ALU1Sel),.ALU2Op(ALU2Op),.RHLSel_Rd(RHLSel_Rd),
		.RHLSel_Wr(RHLSel_Wr),.DMSel(DMSel), .eret_flush(eret_flush),.CP0WrEn(CP0WrEn),
		.ID_Exception(ID_Exception),.ID_ExcCode(ID_ExcCode),.isBD(isBD),.isBranch(isBranch),.CP0Rd(CP0Rd),.start(start),
		.RHL_visit(RHL_visit),.dcache_en(ID_dcache_en),.ID_tlb_searchen(ID_tlb_searchen),.ID_MUX11Sel(ID_MUX11Sel),
        .ID_MUX12Sel(ID_MUX12Sel),.TLB_flush(TLB_flush),.TLB_writeen(TLB_writeen),.TLB_readen(TLB_readen),
        .movz_movn(movz_movn),.Branch_flush(Branch_flush), .LL_signal(LL_signal),
        .SC_signal(SC_signal), .icache_valid_CI(icache_valid_CI), .icache_op_CI(icache_op_CI),
        .dcache_valid_CI(dcache_valid_CI), .dcache_op_CI(dcache_op_CI),.ID_WAIT_OP(ID_WAIT_OP),
        .ID_BrType(ID_BrType), .ID_JType(ID_JType), .isBL(ID_isBL)
	);
    //DMRd,CP0WrEn,ID_Exception,isBD,isBranch,CP0Rd,start,ID_TLB_Exc,TLB_writeen,TLB_readen,ID_tlb_searchen
    //LL_signal,SC_signal,icache_valid_CI,dcache_valid_CI,ID_WAIT_OP
	//--------------EX----------------//
ID_EX U_ID_EX(
		.clk(clk), .rst(rst), .ID_EXWr(ID_EXWr),.RHLSel_Rd(RHLSel_Rd), .PC(ID_PC), .ALU1Op(ALU1Op), .ALU2Op(ALU2Op),
		.MUX1Sel(MUX1Sel), .MUX3Sel(MUX3Sel),.ALU1Sel(ALU1Sel), .DMWr(MUX7Out[2]), .DMSel(DMSel), .DMRd(MUX7Out[14]),
		.RFWr(MUX7Out[1]&movz_movn&!EX_isBL), .RHLWr(MUX7Out[0]),.RHLSel_Wr(RHLSel_Wr), .MUX2Sel(MUX2_6Sel),
		.GPR_RS(MUX8Out), .GPR_RT(MUX9Out), .RS(rs_forDFF),.RT(rt_forDFF), .RD(ID_Instr[15:11]),
		.Imm32(Imm32), .shamt(shamt), .eret_flush(MUX7Out[20]), .ID_Flush(ID_Flush), .CP0WrEn(MUX7Out[13]),
		.Exception(MUX7Out[12]), .ExcCode(ID_ExcCode), .isBD(MUX7Out[11]), .isBranch(MUX7Out[10]),
		.CP0Addr(CP0Addr), .CP0Rd(MUX7Out[9]), .start(MUX7Out[8] & ~EX_isBusy),.ID_dcache_en(MUX7Out[3]),
		.ID_TLBRill_Exc(ID_TLBRill_Exc),.ID_tlb_searchen(MUX7Out[4]),.ID_MUX11Sel(ID_MUX11Sel), .ID_MUX12Sel(ID_MUX12Sel),
		.ID_TLB_Exc(MUX7Out[7]),.TLB_flush(TLB_flush),.TLB_writeen(MUX7Out[6]),.TLB_readen(MUX7Out[5]),
        .LL_signal(MUX7Out[19]),.SC_signal(MUX7Out[18]), .icache_valid_CI(MUX7Out[17]),
        .icache_op_CI(icache_op_CI),.dcache_valid_CI(MUX7Out[16]), .dcache_op_CI(dcache_op_CI),
        .ID_WAIT_OP(MUX7Out[15]), .ID_BrType(ID_BrType), .ID_JType(ID_JType), .MUX7Sel(MUX7Sel), .ID_Imm26(Imm26_forDFF),
        .ID_NPCOp(NPCOp), .MUX4Sel(MUX4Sel), .MUX5Sel(MUX5Sel), 
        .MUX4Sel_forALU1(MUX4Sel_forALU1), .MUX5Sel_forALU1(MUX5Sel_forALU1),
        .ID_MUX1Out(ID_MUX1Out), .ID_MUX3Out(ID_MUX3Out), .Branch_flush(MUX7Out[21]), .ID_isBL(MUX7Out[22]),
        .EPC(EPCOut), .ID_Instr(ID_Instr),

		.EX_eret_flush(EX_eret_flush), .EX_CP0WrEn(EX_CP0WrEn), .EX_Exception(EX_Exception),
		.EX_ExcCode(EX_ExcCode), .EX_isBD(EX_isBD), .EX_isBranch(EX_isBranch), .EX_RHLSel_Rd(EX_RHLSel_Rd),
	 	.EX_DMWr(EX_DMWr), .EX_DMRd(EX_DMRd), .EX_MUX3Sel(EX_MUX3Sel), .EX_ALU1Sel(EX_ALU1Sel),
		.EX_RFWr(EX_RFWr), .EX_RHLWr(EX_RHLWr), .EX_ALU2Op(EX_ALU2Op), .EX_MUX1Sel(EX_MUX1Sel),
		.EX_RHLSel_Wr(EX_RHLSel_Wr), .EX_DMSel(EX_DMSel), .EX_MUX2Sel(EX_MUX2Sel), .EX_ALU1Op(EX_ALU1Op),
		.EX_RS(EX_RS), .EX_RT(EX_RT), .EX_RD(EX_RD), .EX_shamt(EX_shamt), .EX_PC(EX_PC),
		.EX_GPR_RS(EX_GPR_RS), .EX_GPR_RT(EX_GPR_RT), .EX_Imm32(EX_Imm32), .EX_CP0Addr(EX_CP0Addr),
		.EX_CP0Rd(EX_CP0Rd), .EX_start(EX_start),.EX_dcache_en(EX_dcache_en),.EX_TLBRill_Exc(EX_TLBRill_Exc),
		.EX_tlb_searchen(EX_tlb_searchen),.EX_MUX11Sel(EX_MUX11Sel),.EX_MUX12Sel(EX_MUX12Sel),
		.EX_TLB_Exc(EX_TLB_Exc),.EX_TLB_flush(EX_TLB_flush),.EX_TLB_writeen(EX_TLB_writeen),.EX_TLB_readen(EX_TLB_readen),
        .EX_LL_signal(EX_LL_signal),.EX_SC_signal(EX_SC_signal),
        .EX_icache_valid_CI(EX_icache_valid_CI), .EX_icache_op_CI(EX_icache_op_CI),
        .EX_dcache_valid_CI(EX_dcache_valid_CI), .EX_dcache_op_CI(EX_dcache_op_CI),.EX_WAIT_OP(EX_WAIT_OP),
        .EX_BrType(EX_BrType), .EX_JType(EX_JType), .EX_MUX7Sel(EX_MUX7Sel), .EX_Imm26(EX_Imm26), .EX_NPCOp(EX_NPCOp),
        .EX_stall(EX_stall), .EX_MUX4Sel(EX_MUX4Sel), .EX_MUX5Sel(EX_MUX5Sel),
        .EX_MUX4Sel_forALU1(EX_MUX4Sel_forALU1), .EX_MUX5Sel_forALU1(EX_MUX5Sel_forALU1),
        .EX_GPR_RS_forALU1(EX_GPR_RS_forALU1), .EX_GPR_RT_forALU1(EX_GPR_RT_forALU1),
        .EX_MUX1Out(EX_MUX1Out), .EX_MUX3Out(EX_MUX3Out), .EX_Branch_flush(EX_Branch_flush), .EX_isBL(EX_isBL),
        .EX_Instr(EX_Instr)
	);

mux1 U_MUX1(
		.RT(rt_forMUX1), .RD(rd_forMUX1), .MUX1Sel(MUX1Sel),

		 .Addr3(ID_MUX1Out)
	);


mux4 U_MUX4(
		.GPR_RS(EX_GPR_RS), .data_EX(MUX6Out), .data_MEM1(MUX2Out),
        .data_MEM2(MUX10Out), .MUX4Sel(EX_MUX4Sel),

		.out(MUX4Out)
	);

mux5 U_MUX5(
		.GPR_RT(EX_GPR_RT), .data_EX(MUX6Out), .data_MEM1(MUX2Out),
        .data_MEM2(MUX10Out), .MUX5Sel(EX_MUX5Sel),

		.out(MUX5Out)
	);

mux4 U_MUX4_forALU1(
		.GPR_RS(MUX14Out), .data_EX(MUX6Out), .data_MEM1(MUX2Out), 
        .data_MEM2(MUX10Out), .MUX4Sel(EX_MUX4Sel_forALU1),

		.out(MUX4Out_forALU1)
	);

mux5 U_MUX5_forALU1(
        .GPR_RT(EX_MUX3Out), .data_EX(MUX6Out), .data_MEM1(MUX2Out),
        .data_MEM2(MUX10Out), .MUX5Sel(EX_MUX5Sel_forALU1),

		.out(MUX5Out_forALU1)
);

bridge_RHL U_ALU2(
		.aclk(clk),.aresetn(rst),.A(MUX4Out),.B(MUX5Out),.ALU2Op(EX_ALU2Op),.start(EX_start),
		.EX_RHLWr(EX_RHLWr), .EX_RHLSel_Wr(EX_RHLSel_Wr), .EX_RHLSel_Rd(EX_RHLSel_Rd),
		.MEM_Exception(MEM1_Exception), .MEM_eret_flush(MEM1_eret_flush),
        .dcache_stall(dcache_stall), .EX_Exception(EX_Exception), .WAIT(MEM1_WAIT_OP),

		.isBusy(EX_isBusy),.RHLOut(RHLOut),.MULOut(MULOut),.MUL_sign(MUL_sign)
	);

alu1 U_ALU1(
		.A(MUX4Out_forALU1), .B(MUX5Out_forALU1),.ALU1Op(EX_ALU1Op),

		.C(ALU1Out),.Overflow(Overflow),.Trap(Trap), .add_result(add_result)
	);

ex_prep U_EX_PREP(
    .EX_NPCOp(EX_NPCOp),
    .EX_Imm26(EX_Imm26),
    .ID_PC(ID_PC),
    .return_addr(EX_GPR_RS),
    .EX_MUX2Sel(EX_MUX2Sel),

    .EX_address(EX_address),
    .EX_MUX6Sel(EX_MUX6Sel),
    .EX_MUX10Sel(EX_MUX10Sel)
);

mux11 U_MUX11(
	.vpn2(EntryHi_out[31:13]),.alu1out(add_result[31:13]),.MUX11_Sel(EX_MUX11Sel),

	.out(EX_s1_vpn2)
);

mux13 U_MUX13(
    .Imm32(EX_Imm32), .PC(EX_PC), .RHLOut(RHLOut), .EX_MUX2Sel(EX_MUX2Sel),
    .MULOut(MULOut),

	.MUX13Out(MUX13Out)
);

mux14 U_MUX14(
	    .RD1(EX_GPR_RS_forALU1), .shamt(EX_shamt), .ALU1Sel(EX_ALU1Sel), 
	
	    .A(MUX14Out)
	);

	//-------------MEM1---------------//
EX_MEM1 U_EX_MEM1(
		.clk(clk), .rst(rst), .EX_MEM1Wr(EX_MEM1Wr), .EX_PC(EX_PC), .DMWr(EX_DMWr),
        .DMSel(EX_DMSel), .DMRd(EX_DMRd), .RFWr(EX_RFWr), .MUX2Sel(EX_MUX2Sel),.MUX13Out(MUX13Out),
        .ALU1Out(ALU1Out), .GPR_RT(MUX5Out), .RD(EX_MUX1Out), .EX_Flush(EX_Flush), .eret_flush(EX_eret_flush),
        .CP0WrEn(EX_CP0WrEn), .Exception(EX_Exception), .ExcCode(EX_ExcCode), .isBD(EX_isBD),
        .CP0Addr(EX_CP0Addr), .CP0Rd(EX_CP0Rd), .EX_dcache_en(EX_dcache_en),.Overflow(Overflow),
        .EX_TLBRill_Exc(EX_TLBRill_Exc),.EX_tlb_searchen(EX_tlb_searchen),.EX_MUX11Sel(EX_MUX11Sel),
        .EX_MUX12Sel(EX_MUX12Sel),.EX_TLB_Exc(EX_TLB_Exc),.EX_TLB_flush(EX_TLB_flush),.EX_TLB_writeen(EX_TLB_writeen),
        .EX_TLB_readen(EX_TLB_readen),.MULOut(MULOut),
        .Trap(Trap),.EX_LL_signal(EX_LL_signal),.EX_SC_signal(EX_SC_signal),
        .EX_icache_valid_CI(EX_icache_valid_CI), .EX_icache_op_CI(EX_icache_op_CI),
        .EX_dcache_valid_CI(EX_dcache_valid_CI), .EX_dcache_op_CI(EX_dcache_op_CI),.EX_WAIT_OP(EX_WAIT_OP),
        .EX_s1_vpn2(EX_s1_vpn2), .EX_match1(EX_match1), .EPC(EPCOut), .EX_MUX6Sel(EX_MUX6Sel), .EX_MUX10Sel(EX_MUX10Sel),
        .EX_Instr(EX_Instr),

		.MEM1_DMWr(MEM1_DMWr), .MEM1_DMRd(MEM1_DMRd), .MEM1_RFWr(MEM1_RFWr),.MEM1_eret_flush(MEM1_eret_flush),
        .MEM1_CP0WrEn(MEM1_CP0WrEn), .MEM1_Exception(Temp_M1_Exception), .MEM1_ExcCode(Temp_M1_ExcCode),
        .MEM1_isBD(MEM1_isBD),.MEM1_DMSel(MEM1_DMSel), .MEM1_MUX2Sel(MEM1_MUX2Sel), .MEM1_RD(MEM1_RD),
        .MEM1_PC(MEM1_PC), .MEM1_MUX13Out(MEM1_MUX13Out), .MEM1_ALU1Out(MEM1_ALU1Out), .MEM1_GPR_RT(MEM1_GPR_RT),
        .MEM1_CP0Addr(MEM1_CP0Addr), .MEM1_CP0Rd(MEM1_CP0Rd), .MEM1_dcache_en(MEM1_dcache_en),
        .MEM1_Overflow(MEM1_Overflow),.MEM1_TLBRill_Exc(Temp_MEM1_TLBRill_Exc), 
        .MEM1_tlb_searchen(MEM1_tlb_searchen),.MEM1_MUX11Sel(MEM1_MUX11Sel),.MEM1_MUX12Sel(MEM1_MUX12Sel),
        .MEM1_TLB_Exc(Temp_MEM1_TLB_Exc),.MEM1_TLB_flush(MEM1_TLB_flush),.MEM1_TLB_writeen(MEM1_TLB_writeen),
        .MEM1_TLB_readen(MEM1_TLB_readen),.MEM1_MULOut(MEM1_MULOut),
        .MEM1_Trap(MEM1_Trap),.MEM1_LL_signal(MEM1_LL_signal),.MEM1_SC_signal(MEM1_SC_signal),
        .MEM1_icache_valid_CI(MEM1_icache_valid_CI), .MEM1_icache_op_CI(MEM1_icache_op_CI),
        .MEM1_dcache_valid_CI(MEM1_dcache_valid_CI), .MEM1_dcache_op_CI(MEM1_dcache_op_CI),.MEM1_WAIT_OP(MEM1_WAIT_OP),
        .s1_vpn2(s1_vpn2), .MEM1_ALU1Out_forExPa(MEM1_ALU1Out_forExPa), .match1(match1), .MEM1_MUX6Sel(MEM1_MUX6Sel), 
        .MEM1_MUX10Sel(MEM1_MUX10Sel), .MEM1_Instr(MEM1_Instr)
    );

CP0 U_CP0(
		.clk(clk),.rst(rst),.CP0WrEn(MEM1_CP0WrEn&~whole_stall),.addr(MEM1_CP0Addr),.data_in(MEM1_GPR_RT),
		.MEM1_Exception(MEM1_Exception),.MEM1_eret_flush(MEM1_eret_flush),.MEM1_isBD(MEM1_isBD),
        .ext_int_in(ext_int_in),.MEM1_ExcCode(MEM1_ExcCode),.MEM1_badvaddr(MEM1_badvaddr),
		.MEM1_PC(MEM1_PC),.EntryHi_Wren(MEM1_TLB_readen),.EntryLo0_Wren(MEM1_TLB_readen),
		.EntryLo1_Wren(MEM1_TLB_readen),.Index_Wren(MEM1_tlb_searchen),.s1_found(s1_found),
    	.EntryHi_in({r_vpn2,5'b0,r_asid}),.EntryLo0_in({6'b0,r_pfn0,r_c0,r_d0,r_v0,r_g}),
        .MEM1_TLB_Exc(MEM1_TLB_Exc),.EntryLo1_in({6'b0,r_pfn1,r_c1,r_d1,r_v1,r_g}),
        .Index_in({!s1_found,29'b0,s1_index}),.Cause_CE_Wr(Cause_CE_Wr), .dcache_stall(dcache_stall),

		.data_out(CP0Out), .EPC_out(EPCOut), .Interrupt(Interrupt),.EntryHi_out(EntryHi_out),
		.Index_out(Index_out),.EntryLo0_out(EntryLo0_out),.EntryLo1_out(EntryLo1_out),
        .Random_out(Random_out),.Config_K0_out(Config_K0_out),.Status_BEV(Status_BEV),
        .Status_EXL(Status_EXL), .Cause_IV(Cause_IV), .Ebase_out(Ebase_out),
        .Status_out(Status_out), .Cause_out(Cause_out)
	);


mux12 U_MUX12(
    .index(Index_out[1:0]), .random(Random_out[1:0]), .MUX12_Sel(MEM1_MUX12Sel),

    .out(w_index)
);

mux6 U_MUX6(
		.ALU1Out(MEM1_ALU1Out), .MUX13Out(MEM1_MUX13Out),
        .MUX6Sel(MEM1_MUX6Sel),

		.out(MUX6Out)
	);

mem1_cache_prep U_MEM1_CACHE_PREP(
        clk,rst,MEM1_dcache_en,MEM1_eret_flush,MEM1_ALU1Out_forExPa, MEM1_DMWr,
        MEM1_DMSel, MEM1_RFWr,MEM1_Overflow, Temp_M1_Exception,MEM1_DMRd,
        Temp_M1_ExcCode,MEM1_PC,s1_found,s1_v,s1_d,s1_pfn,s1_c,
        Temp_MEM1_TLB_Exc,IF_data_ok,Temp_MEM1_TLBRill_Exc, MEM_unCache_data_ok,
        MEM1_GPR_RT,Interrupt,Config_K0_out,MEM1_Trap,
        MEM1_LL_signal,MEM1_SC_signal, MEM1_icache_valid_CI, MEM1_icache_op_CI,
        MEM1_dcache_valid_CI, MEM1_dcache_op_CI,

        MEM1_Paddr, MEM1_cache_sel, MEM1_dcache_valid,DMWen_dcache,
        MEM1_dCache_wstrb,MEM1_ExcCode,MEM1_Exception,MEM1_badvaddr,
        MEM1_TLBRill_Exc,MEM1_TLB_Exc,MEM1_uncache_valid, MEM1_DMen,
        MEM1_wdata,MEM1_SCOut,Cause_CE_Wr, MEM1_invalid, MEM1_ee, MEM1_rstrb, MEM1_type
	);

dcache U_DCACHE(
    .clk(clk), .resetn(rst), .DMen(MEM2_dcache_en), 
    .stall(~(IF_data_ok&MEM_unCache_data_ok)), .exception(MEM2_invalid),
	// cpu && cache
  	.valid(MEM1_dcache_valid), .op(DMWen_dcache), .index(MEM1_ALU1Out[11:6]),
    .tag(MEM2_Paddr[31:12]), .offset(MEM1_ALU1Out[5:0]),.wstrb(MEM1_dCache_wstrb), .wdata(MEM1_wdata),
    .addr_ok(MEM_dCache_addr_ok), .data_ok(MEM_dCache_data_ok), .rdata(cache_Out),
	//cache && axi
  	.rd_req(MEM_dcache_rd_req), .rd_type(MEM_dcache_rd_type), .rd_addr(MEM_dcache_rd_addr),
    .rd_rdy(MEM_dcache_rd_rdy), .ret_valid(MEM_dcache_ret_valid & ~MEM2_cache_sel), .ret_last(MEM_dcache_ret_last),
    .ret_data(MEM_dcache_ret_data), .wr_valid(bvalid), .wr_req(MEM_dcache_wr_req),
    .wr_type(MEM_dcache_wr_type), .wr_addr(MEM_dcache_wr_addr), .wr_wstrb(MEM_dcache_wr_wstrb),
    .wr_data(MEM_dcache_wr_data), .wr_rdy(MEM_dcache_wr_rdy),
    .valid_CI(MEM1_dcache_valid_CI), .op_CI(MEM1_dcache_op_CI), .index_CI(MEM1_ALU1Out[11:6]),
    .way_CI(MEM1_ALU1Out[12]), .tag_CI(MEM2_Paddr[31:12]),
    .cache_sel(MEM2_cache_sel), .uncache_out(uncache_Out),
    .uncache_data_ok(MEM_unCache_data_ok), .MEM_data_ok(MEM_data_ok),
    .C_STATE(d_cache_state)
	);
	//-------------MEM2---------------//
MEM1_MEM2 U_MEM1_MEM2(
		.clk(clk),.rst(rst),.PC(MEM1_PC),.RFWr(MEM1_RFWr),.MUX2Sel(MEM1_MUX2Sel),
		.MUX6Out(MUX6Out),.ALU1Out(MEM1_ALU1Out),.RD(MEM1_RD),.MEM1_Flush(MEM1_Flush),
        .CP0Out(CP0Out),.MEM1_MEM2Wr(MEM1_MEM2Wr),
        .cache_sel(MEM1_cache_sel),.DMWen(DMWen_dcache),.Exception(MEM1_Exception),
        .eret_flush(MEM1_eret_flush),.uncache_valid(MEM1_uncache_valid),.DMen(MEM1_DMen),
        .Paddr(MEM1_Paddr),.MEM1_dCache_wstrb(MEM1_dCache_wstrb),.GPR_RT(MEM1_GPR_RT),
        .DMRd(MEM1_DMRd),.CP0Rd(MEM1_CP0Rd),.MEM1_TLB_flush(MEM1_TLB_flush),
        .MEM1_TLB_writeen(MEM1_TLB_writeen),.MEM1_TLB_readen(MEM1_TLB_readen),
        .MEM1_LoadOp(MEM1_LoadOp),.MEM1_wdata(MEM1_wdata),.MEM1_SCOut(MEM1_SCOut),
        .MEM1_icache_valid_CI(MEM1_icache_valid_CI), .MEM1_dcache_en(MEM1_dcache_en),
        .MEM1_invalid(MEM1_invalid), .MEM1_rstrb(MEM1_rstrb), .MEM1_type(MEM1_type),
        .EPC(EPCOut), .MEM1_MUX10Sel(MEM1_MUX10Sel),

		.MEM2_RFWr(MEM2_RFWr),.MEM2_MUX2Sel(MEM2_MUX2Sel),.MEM2_RD(MEM2_RD),
        .MEM2_PC(MEM2_PC), .MEM2_ALU1Out(MEM2_ALU1Out),.MEM2_MUX6Out(MEM2_MUX6Out),
        .MEM2_CP0Out(MEM2_CP0Out), .MEM2_cache_sel(MEM2_cache_sel),
        .MEM2_DMWen(DMWen_uncache),.MEM2_Exception(MEM2_Exception),.MEM2_eret_flush(MEM2_eret_flush),
        .MEM2_uncache_valid(MEM2_uncache_valid),.MEM2_DMen(MEM2_DMen),.MEM2_Paddr(MEM2_Paddr),
        .MEM2_unCache_wstrb(MEM2_unCache_wstrb),.MEM2_GPR_RT(MEM2_GPR_RT),.MEM2_DMRd(MEM2_DMRd),
        .MEM2_CP0Rd(MEM2_CP0Rd),.MEM2_TLB_flush(MEM2_TLB_flush),.MEM2_TLB_writeen(MEM2_TLB_writeen),
        .MEM2_TLB_readen(MEM2_TLB_readen),.MEM2_LoadOp(MEM2_LoadOp),.MEM2_wdata(MEM2_wdata),
        .MEM2_SCOut(MEM2_SCOut), .MEM2_icache_valid_CI(MEM2_icache_valid_CI),
        .MEM2_dcache_en(MEM2_dcache_en), .MEM2_invalid(MEM2_invalid),
        .MEM2_rstrb(MEM2_rstrb), .MEM2_type(MEM2_type), .MEM2_MUX10Sel(MEM2_MUX10Sel)
	);

mux2 U_MUX2(
		.MUX6Out(MEM2_MUX6Out), .MUX2Sel(MEM2_MUX2Sel),
        .CP0Out(MEM2_CP0Out),.MEM2_SCOut(MEM2_SCOut),

		.WD(MUX2Out)
	);

uncache_dm U_UNCACHE_DM(
        .clk(clk),.resetn(rst), .MEM2_type(MEM2_type), .wr(MEM1_MEM2Wr), .exception(MEM2_invalid),
        .valid(MEM2_uncache_valid &~MEM2_invalid),.op(DMWen_uncache),.addr(MEM2_Paddr),
        .wstrb(MEM2_unCache_wstrb),.wdata(MEM2_wdata),.data_ok(MEM_unCache_data_ok),.rdata(uncache_Out),
        .rd_rdy(MEM_uncache_rd_rdy),.wr_rdy(MEM_uncache_wr_rdy),
        .ret_valid(MEM_uncache_ret_valid),.ret_last(MEM_uncache_ret_last),.ret_data(MEM_uncache_ret_data),.wr_valid(bvalid),
        .rd_req(MEM_uncache_rd_req),.wr_req(MEM_uncache_wr_req), .rd_type(MEM_uncache_rd_type),
		.wr_type(MEM_uncache_wr_type), .rd_addr(MEM_uncache_rd_addr), .wr_addr(MEM_uncache_wr_addr),
		.wr_wstrb(MEM_uncache_wr_wstrb), .wr_data(MEM_uncache_wr_data),
        .C_STATE(d_uncache_state)
);

bridge_dm U_BRIDGE_DM(
		.rstrb(MEM2_rstrb),
		.Din(cache_Out),
        .MEM2_GPR_RT(MEM2_GPR_RT),

		.dout(DMOut)
	);

// cache_select_dm U_CACHE_SELECT_DM(
// 	    MEM2_cache_sel, uncache_Out, dcache_Out, MEM_unCache_data_ok, MEM_dCache_data_ok,
//         MEM_uncache_rd_req, MEM_dcache_rd_req, MEM_uncache_wr_req, MEM_dcache_wr_req,
//         MEM_uncache_rd_type, MEM_dcache_rd_type, MEM_uncache_wr_type, MEM_dcache_wr_type,
//         MEM_uncache_rd_addr, MEM_dcache_rd_addr, MEM_uncache_wr_addr, MEM_dcache_wr_addr,
//         MEM_uncache_wr_wstrb, MEM_dcache_wr_wstrb,

//         cache_Out,MEM_data_ok,MEM_rd_req,MEM_wr_req,MEM_rd_type,MEM_wr_type,MEM_rd_addr,
//         MEM_wr_addr,MEM_wr_wstrb
//     );

    //--------------WB----------------//
MEM2_WB U_MEM2_WB(
        .clk(clk),.rst(rst),.MEM2_WBWr(MEM2_WBWr),.MEM2_Flush(MEM2_Flush),.PC(MEM2_PC),
        .MUX2Out(MUX2Out),.MUX2Sel(MEM2_MUX2Sel),.RD(MEM2_RD),.RFWr(MEM2_RFWr),.DMOut(DMOut),
        .MEM2_TLB_flush(MEM2_TLB_flush),.MEM2_TLB_writeen(MEM2_TLB_writeen),
        .MEM2_TLB_readen(MEM2_TLB_readen), .MEM2_icache_valid_CI(MEM2_icache_valid_CI),
        .MEM2_MUX10Sel(MEM2_MUX10Sel),

		.WB_PC(WB_PC),.WB_MUX2Out(WB_MUX2Out),.WB_MUX2Sel(WB_MUX2Sel),
        .WB_RD(WB_RD),.WB_RFWr(WB_RFWr),.WB_DMOut(WB_DMOut),.WB_TLB_flush(WB_TLB_flush),
        .WB_TLB_writeen(WB_TLB_writeen),.WB_TLB_readen(WB_TLB_readen),
        .WB_icache_valid_CI(WB_icache_valid_CI), .WB_MUX10Sel(WB_MUX10Sel)
        );

mux10 U_MUX10(
        .WB_MUX2Out(WB_MUX2Out), .WB_DMOut(WB_DMOut), .WB_MUX2Sel(WB_MUX10Sel),

        .MUX10Out(MUX10Out)
        );
    //-------------ELSE---------------//
//physical address tranfer
tlb_4 U_TLB(
    clk,
    rst,

    //search port 0
    PF_PC[31:13],	//s0_vpn2
    PF_PC[12],	//s0_odd_page
    EntryHi_out[7:0],	//s0_asid

    s0_found,
    s0_index,
    s0_pfn,
    s0_c,
    s0_d,
    s0_v,

    //search port 1
    EX_s1_vpn2,
    MEM1_ALU1Out[12],//s1_odd_page,no use for tlbp
    EntryHi_out[7:0],//s1_asid

    s1_found,
    s1_index,
    s1_pfn,
    s1_c,
    s1_d,
    s1_v,

    //write port
    MEM1_TLB_writeen,//we, write enable
    w_index,//w_index,
    EntryHi_out[31:13],		//w_vpn2,
    EntryHi_out[7:0],		//w_asid,
    EntryLo0_out[0]&EntryLo1_out[0],//w_g,
    EntryLo0_out[25:6],		//w_pfn0,
    EntryLo0_out[5:3],		//w_c0,
    EntryLo0_out[2],		//w_d0,
    EntryLo0_out[1],		//w_v0,
    EntryLo1_out[25:6],		//w_pfn1,
    EntryLo1_out[5:3],		//w_c1,
    EntryLo1_out[2],		//w_d1,
    EntryLo1_out[1],		//w_v1,

    //read port
    Index_out[1:0],//r_index

    r_vpn2,
    r_asid,
    r_g,
    r_pfn0,
    r_c0,
    r_d0,
    r_v0,
    r_pfn1,
    r_c1,
    r_d1,
    r_v1,

    match1,
    EX_match1
);

npc U_NPC(
		.ret_addr(ret_addr_reg), .NPCOp(NPCOp_reg), .NPC_op00(NPC_op00_reg), .NPC_op01(NPC_op01_reg),
        .NPC_op10(NPC_op10_reg), .flush_condition_00(flush_condition_00_reg),
        .flush_condition_01(flush_condition_01_reg), .flush_condition_10(flush_condition_10_reg),
        .flush_condition_11(flush_condition_11_reg),.target_addr_final(target_addr_final_reg),
        .ee(ee_reg), .NPC_ee(NPC_ee_reg),

		.NPC(PF_PC), .Instr_Flush(PF_Instr_Flush)
	);

flush U_FLUSH(
        .MEM1_ee(MEM1_ee),
        .can_go(MEM_data_ok), 

        .PC_Flush(PC_Flush),.PF_Flush(PF_Flush),.IF_Flush(IF_Flush),
        .ID_Flush(ID_Flush),.EX_Flush(EX_Flush),.MEM1_Flush(MEM1_Flush),
        .MEM2_Flush(MEM2_Flush)
    );

bypass U_BYPASS(
		.EX_RD(EX_MUX1Out), .ID_RS(rs_forBypass), .ID_RT(rt_forBypass),
        .MEM1_RD(MEM1_RD), .MEM2_RD(MEM2_RD), .WB_RD(WB_RD),.MEM1_RFWr(MEM1_RFWr),
        .MEM2_RFWr(MEM2_RFWr), .WB_RFWr(WB_RFWr), .EX_RFWr(EX_RFWr),
        .ID_RS_forCMP(rs_forBypass_forCMP), .ID_RT_forCMP(rt_forBypass_forCMP),
        .ID_MUX3Sel(MUX3Sel), .ALU1Sel(ALU1Sel),

		.MUX4Sel(MUX4Sel), .MUX5Sel(MUX5Sel),
		.MUX8Sel(MUX8Sel), .MUX9Sel(MUX9Sel),
        .MUX8Sel_forCMP(MUX8Sel_forCMP), .MUX9Sel_forCMP(MUX9Sel_forCMP), 
        .MUX5Sel_forALU1(MUX5Sel_forALU1), .MUX4Sel_forALU1(MUX4Sel_forALU1)
	);

stall U_STALL(
		.clk(clk),.rst(rst) ,
		.EX_RT(EX_MUX1Out), .MEM1_RT(MEM1_RD), .MEM2_RT(MEM2_RD), .ID_RS(rs_forStall), .ID_RT(rt_forStall),
		.EX_DMRd(EX_DMRd),.ID_PC(ID_PC),.EX_PC(EX_PC), .MEM1_PC(MEM1_PC), .MEM1_DMRd(MEM1_DMRd), .MEM2_DMRd(MEM2_DMRd),
		.BJOp(ID_BJOp),.EX_RFWr(EX_RFWr), .EX_CP0Rd(EX_CP0Rd), .MEM1_CP0Rd(MEM1_CP0Rd), .MEM2_CP0Rd(MEM2_CP0Rd),
		.rst_sign(!rst), .MEM1_ee(MEM1_ee), .MEM1_RFWr(MEM1_RFWr), .MEM2_RFWr(MEM2_RFWr),
        .isbusy(EX_isBusy), .RHL_visit(RHL_visit),.iCache_data_ok(IF_data_ok),
        .dCache_data_ok(MEM_data_ok),
        .MEM_dCache_en(MEM2_DMen),.MEM1_cache_sel(MEM1_cache_sel),
        .MEM1_dCache_en(MEM1_dcache_valid | MEM1_dcache_valid_CI),.ID_tlb_searchen(ID_tlb_searchen),
        .EX_CP0WrEn(EX_CP0WrEn), .MUL_sign(MUL_sign), .EX_SC_signal(EX_SC_signal),
        .MEM1_SC_signal(MEM1_SC_signal), .MEM1_WAIT_OP(MEM1_WAIT_OP), .Interrupt(Interrupt), .ID_isBL(ID_isBL),

		.PCWr(PCWr), .IF_IDWr(IF_IDWr), .MUX7Sel(MUX7Sel),.icache_stall(icache_stall),.isStall(isStall),
		.dcache_stall(dcache_stall), .ID_EXWr(ID_EXWr), .EX_MEM1Wr(EX_MEM1Wr), .MEM1_MEM2Wr(MEM1_MEM2Wr),
        .MEM2_WBWr(MEM2_WBWr),.PF_IFWr(PF_IFWr),
        .data_stall(data_stall), .whole_stall(whole_stall)
);
/*
axi_sram_bridge U_AXI_SRAM_BRIDGE(
	MEM2_cache_sel,
    IF_icache_sel,
    ext_int_in   ,   //high active

    clk      ,
    rst      ,   //low active

    arid      ,
    araddr    ,
    arlen     ,
    arsize    ,
    arburst   ,
    arlock    ,
    arcache   ,
    arprot    ,
    arvalid   ,
    arready   ,

    rid       ,
    rdata     ,
    rresp     ,
    rlast     ,
    rvalid    ,
    rready    ,

    awid      ,
    awaddr    ,
    awlen     ,
    awsize    ,
    awburst   ,
    awlock    ,
    awcache   ,
    awprot    ,
    awvalid   ,
    awready   ,

    wid       ,
    wdata     ,
    wstrb     ,
    wlast     ,
    wvalid    ,
    wready    ,

    bid       ,
    bresp     ,
    bvalid    ,
    bready    ,
// icache
	IF_rd_req,// icache �???? dcache 同时缺失怎么�????
	IF_rd_type,
	IF_rd_addr,
	IF_icache_rd_rdy,
	IF_icache_ret_valid,
	IF_icache_ret_last,
	IF_icache_ret_data,
	IF_wr_req,
	IF_wr_type,
	IF_wr_addr,
	IF_wr_wstrb,
	IF_icache_wr_data,
	IF_icache_wr_rdy,
//	dcache
	MEM_rd_req,
	MEM_rd_type,
	MEM_rd_addr,
	MEM_dcache_rd_rdy,
	MEM_dcache_ret_valid,
	MEM_dcache_ret_last,
	MEM_dcache_ret_data,
	MEM_wr_req,
	MEM_wr_type,
	MEM_wr_addr,
	MEM_wr_wstrb,
	MEM_dcache_wr_data,
	MEM_dcache_wr_rdy,
	MEM_uncache_wr_data

);
*/
new_bridge U_AXI_SRAM_BRIDGE(
	MEM2_cache_sel,
    IF_icache_sel,
    ext_int_in   ,   //high active

    clk      ,
    rst      ,   //low active

    arid      ,
    araddr    ,
    arlen     ,
    arsize    ,
    arburst   ,
    arlock    ,
    arcache   ,
    arprot    ,
    arvalid   ,
    arready   ,

    rid       ,
    rdata     ,
    rresp     ,
    rlast     ,
    rvalid    ,
    rready    ,

    awid      ,
    awaddr    ,
    awlen     ,
    awsize    ,
    awburst   ,
    awlock    ,
    awcache   ,
    awprot    ,
    awvalid   ,
    awready   ,

    wid       ,
    wdata     ,
    wstrb     ,
    wlast     ,
    wvalid    ,
    wready    ,

    bid       ,
    bresp     ,
    bvalid    ,
    bready    ,

	IF_icache_rd_req,
	IF_icache_rd_type,
	IF_icache_rd_addr,
	IF_icache_rd_rdy,
	IF_icache_ret_valid,
	IF_icache_ret_last,
	IF_icache_ret_data,
	IF_icache_wr_req,
	IF_icache_wr_type,
	IF_icache_wr_addr,
	IF_icache_wr_wstrb,
	IF_icache_wr_data,
	IF_icache_wr_rdy,
// iuncache
	IF_uncache_rd_req,
	IF_uncache_rd_type,
	IF_uncache_rd_addr,
	IF_uncache_rd_rdy,
	IF_uncache_ret_valid,
	IF_uncache_ret_last,
	IF_uncache_ret_data,
	IF_uncache_wr_req,
	IF_uncache_wr_type,
	IF_uncache_wr_addr,
	IF_uncache_wr_wstrb,
    IF_uncache_wr_data,
	IF_uncache_wr_rdy,
//	dcache
	MEM_dcache_rd_req,
	MEM_dcache_rd_type,
	MEM_dcache_rd_addr,
	MEM_dcache_rd_rdy,
	MEM_dcache_ret_valid,
	MEM_dcache_ret_last,
	MEM_dcache_ret_data,
	MEM_dcache_wr_req,
	MEM_dcache_wr_type,
	MEM_dcache_wr_addr,
	MEM_dcache_wr_wstrb,
	MEM_dcache_wr_data,
	MEM_dcache_wr_rdy,
//  d uncache
	MEM_uncache_rd_req,
	MEM_uncache_rd_type,
	MEM_uncache_rd_addr,
	MEM_uncache_rd_rdy,
	MEM_uncache_ret_valid,
	MEM_uncache_ret_last,
	MEM_uncache_ret_data,
	MEM_uncache_wr_req,
	MEM_uncache_wr_type,
	MEM_uncache_wr_addr,
	MEM_uncache_wr_wstrb,
	MEM_uncache_wr_data,
	MEM_uncache_wr_rdy,

    state_i_uncache_0,
    state_i_cache_1,
    state_d_uncache_2,
    state_d_cache_3

);

debug U_DEBUG(
    MUX10Out, WB_PC, WB_RFWr, MEM2_WBWr,WB_RD,

    debug_wb_rf_wdata, debug_wb_pc,
    debug_wb_rf_wen, debug_wb_rf_wnum
    );

endmodule