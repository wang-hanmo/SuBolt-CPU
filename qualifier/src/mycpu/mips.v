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
    input [5:0] ext_int_in      ;  //interrupt,high active;
// 时钟与复位信�????????
    input clk      ;
    input rst      ;   //low active
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
    input [3:0]     bid       ;
    input [1:0]     bresp     ;
    input           bvalid    ;
    output          bready    ;
//debug
    output  [31:0] debug_wb_pc      ;
    output  [3:0] debug_wb_rf_wen  ;
    output  [4:0] debug_wb_rf_wnum ;
    output  [31:0] debug_wb_rf_wdata;


	/*signals defination*/
    //--------------Pre_F---------------//
	wire PF_Exception;
	wire [4:0] PF_ExcCode;
    wire PF_icache_valid;
    wire[31:0] PF_PC;

    wire[31:0] ret_addr_reg;
    wire[1:0] NPCOp_reg;
    wire PF_predict;
	//--------------IF----------------//
    wire[31:0] PC;
    wire[31:0] PPC;

    wire IF_iCache_addr_ok;
	wire IF_iCache_data_ok;
	wire [31:0] IF_iCache_rdata;
    wire IF_icache_rd_req;
	wire [2:0]IF_icache_rd_type;
	wire [31:0] IF_icache_rd_addr;
	wire  IF_icache_rd_rdy;
	wire  IF_icache_ret_valid;
	wire IF_icache_ret_last;
	wire [31:0] IF_icache_ret_data;
	wire IF_icache_wr_req;
	wire [2:0] IF_icache_wr_type;
	wire [31:0] IF_icache_wr_addr;
	wire [3:0] IF_icache_wr_wstrb;
	wire [511:0] IF_icache_wr_data;
	wire IF_icache_wr_rdy;

	wire IF_Exception;
	wire [4:0] IF_ExcCode;
    wire IF_icache_valid;
    wire branch;
    wire [31:0] target_addr;
    wire flush_signal_IF;
    wire IF_stall;
    wire IF_BJOp;
    //--------------ID----------------//
    wire[31:0] ID_PC;
    wire[31:0] ID_Instr;
    wire[31:0] GPR_RS;
    wire[31:0] GPR_RT;
    wire[1:0] EXTOp;
    wire[31:0] Imm32;
    wire CMPOut1;
    wire[1:0] CMPOut2;
    wire[31:0] MUX8Out;
    wire[31:0] MUX9Out;
    wire[3:0] MUX7Out;
    wire ID_dcache_en;
    wire DMWr;
    wire RFWr;
    wire RHLWr;
    wire[1:0] MUX1Sel;
    wire[2:0] MUX11Sel;
    wire MUX3Sel;
    wire DMRd;
    wire[1:0] NPCOp;
    wire[3:0] ALU1Op;
    wire ALU1Sel;
    wire[1:0] ALU2Op;
    wire RHLSel_Rd;
	wire[1:0] RHLSel_Wr;
    wire[2:0] DMSel;
    wire eret_flush;
    wire CP0WrEn;
	wire Exception;
    wire[4:0] ExcCode;
    wire isBD;
    wire isBranch;
    wire CP0Rd;
    wire start;
	wire RHL_visit;

    wire Temp_ID_Excetion;
	wire[4:0] Temp_ID_ExcCode,ID_ExcCode;
    wire ID_Exception;
    wire[4:0] MUX1Out;
    wire [1:0] ID_BrType;
    wire [1:0] ID_JType;
    wire ID_BJOp;
	//--------------EX----------------//
    wire EX_isBranch;
    wire EX_isBusy;
    wire EX_eret_flush;
    wire EX_CP0WrEn;
    wire EX_Exception;
    wire[4:0] EX_ExcCode;
    wire EX_isBD;
    wire EX_RHLSel_Rd;
	wire EX_DMWr;
    wire EX_DMRd;
    wire EX_MUX3Sel;
    wire EX_ALU1Sel;
	wire EX_RFWr;
    wire EX_RHLWr;
    wire[1:0] EX_ALU2Op;
    wire[4:0] EX_RD;
	wire[1:0] EX_RHLSel_Wr;
    wire[2:0] EX_DMSel;
    wire[2:0] EX_MUX11Sel;
    wire[3:0] EX_ALU1Op;
    wire[4:0] EX_RS;
    wire[4:0] EX_RT;
    wire[4:0] EX_shamt;
    wire[31:0] EX_PC;
	wire[31:0] EX_GPR_RS;
    wire[31:0] EX_GPR_RT;
    wire[31:0] EX_Imm32;
    wire[7:0] EX_CP0Addr;
	wire EX_CP0Rd;
    wire EX_start;
    wire EX_dcache_en;

    wire[31:0] MUX3Out;
    wire[31:0] MUX4Out;
    wire[31:0] MUX5Out;
    wire[31:0] RHLOut;
    wire[31:0] ALU1Out;
    wire[31:0] MUX11Out;
    wire Overflow;
    wire[31:0] MUX12Out;

    wire Temp_EX_Excetion;
	wire[4:0] Temp_EX_ExcCode;
    wire [1:0] EX_BrType;
    wire [31:0] EX_address;
    wire [25:0] EX_Imm26;
    wire [1:0] EX_NPCOp;
    wire EX_MUX6Sel;
    wire EX_MUX2Sel;
    wire EX_MUX10Sel;
    wire [1:0] EX_JType;
    wire EX_MUX7Sel;
    wire EX_stall;
	//-------------MEM1---------------//
    wire MEM1_eret_flush;
    wire MEM1_Exception;
    wire[31:0] MUX6Out;
    wire Interrupt;
    wire[31:0] EPCOut;
    wire[31:0] CP0Out;
    wire MEM1_DMWr;
    wire MEM1_DMRd;
    wire MEM1_RFWr;
    wire MEM1_CP0WrEn;
    wire Temp_M1_Exception;
    wire[4:0] Temp_M1_ExcCode;
    wire MEM1_isBD;
    wire[2:0] MEM1_DMSel;
    wire[4:0] MEM1_RD;
    wire[31:0] MEM1_PC;
    wire[31:0] MEM1_ALU1Out;
    wire[31:0] MEM1_GPR_RT;
    wire[7:0] MEM1_CP0Addr;
    wire MEM1_CP0Rd;
    wire MEM1_dcache_en;
    wire MEM1_Overflow;
    wire[4:0] MEM1_ExcCode;
    wire[31:0] MEM1_badvaddr;
    wire[31:0] MEM1_Paddr;
    wire MEM1_cache_sel;
    wire MEM1_dcache_valid;
    wire DMWen_dcache;
    wire[3:0] MEM1_dCache_wstrb;
    wire[31:0] MEM1_MUX11Out;

	wire [31:0] M1_badvaddr;
    wire MEM1_uncache_valid;
    wire MEM1_DMen;
    wire MEM1_dcache_valid_except_icache;
    wire[3:0] MEM1_rstrb;
    wire MEM1_MUX6Sel;
    wire MEM1_MUX2Sel;
    wire MEM1_MUX10Sel;
	//-------------MEM2---------------//
    wire MEM2_RFWr;
    wire[4:0] MEM2_RD;
    wire[31:0] MUX2Out;
    wire[31:0] MEM2_PC;
    wire[31:0] MEM2_MUX6Out;
    wire[31:0] MEM2_CP0Out;
    wire[2:0] MEM2_DMSel;
    wire MEM2_cache_sel;
    wire MEM2_Exception;
    wire MEM2_eret_flush;
    wire MEM2_dcache_en;
    wire[31:0] MEM2_Paddr;
    wire[3:0] MEM2_unCache_wstrb;
    wire[31:0] MEM2_GPR_RT;
    wire MEM2_DMen;
    wire DMWen_uncache;
    wire MEM2_uncache_valid;
    wire[31:0] DMOut;
    wire MEM2_DMRd;
    wire MEM2_can_go;
    wire[3:0] MEM2_rstrb;
    wire MEM2_MUX2Sel;
    wire MEM2_MUX10Sel;
    //--------------WB----------------//
    wire[31:0] WB_PC;
	wire[31:0] WB_MUX2Out;
	wire[4:0] WB_RD;
	wire WB_RFWr;
    wire[31:0] WB_DMOut;
    wire[31:0] MUX10Out;
    wire WB_MUX10Sel;
    //-------------ELSE---------------//
    wire isStall;
    wire dcache_stall;
    wire icache_stall_1;

    wire MUX7Sel;
    wire[1:0] MUX8Sel;
    wire[1:0] MUX9Sel;
    wire[1:0] MUX4Sel;
    wire[1:0] MUX5Sel;
    wire[1:0] EX_MUX4Sel;
    wire[1:0] EX_MUX5Sel;

    wire PCWr;
    wire PF_IFWr;
    wire IF_IDWr;
    wire ID_EXWr;
    wire EX_MEM1Wr;
    wire MEM1_MEM2Wr;
    wire MEM2_WBWr;
    wire PC_Flush;
    wire PF_Flush;
    wire IF_Flush;
    wire ID_Flush;
    wire EX_Flush;
    wire MEM1_Flush;
    wire MEM2_Flush;


    wire MEM_dCache_addr_ok;
    wire MEM_dCache_data_ok;
    wire[31:0] dcache_Out;
  	wire MEM_dcache_rd_req;
    wire[2:0] MEM_dcache_rd_type;
    wire[31:0] MEM_dcache_rd_addr;
    wire MEM_dcache_rd_rdy;
	wire MEM_dcache_ret_valid;
    wire MEM_dcache_ret_last;
    wire[31:0] MEM_dcache_ret_data;
    wire MEM_dcache_wr_req;
    wire[2:0] MEM_dcache_wr_type;
    wire[31:0] MEM_dcache_wr_addr;
	wire[3:0] MEM_dcache_wr_wstrb;
    wire[511:0] MEM_dcache_wr_data;
    wire MEM_dcache_wr_rdy;

    wire MEM_unCache_data_ok;
    wire[31:0] uncache_Out;
    wire MEM_uncache_rd_req;
    wire MEM_uncache_wr_req;
    wire[2:0] MEM_uncache_rd_type;
    wire[2:0] MEM_uncache_wr_type;
    wire[31:0] MEM_uncache_rd_addr;
    wire[31:0] MEM_uncache_wr_addr;
    wire[3:0] MEM_uncache_wr_wstrb;
    wire[31:0] MEM_uncache_wr_data;

    wire[31:0] cache_Out;
    wire MEM_data_ok;
    wire MEM_rd_req;
    wire MEM_wr_req;
    wire[2:0] MEM_rd_type;
    wire[2:0] MEM_wr_type;
    wire[31:0] MEM_rd_addr;
    wire[31:0] MEM_wr_addr;
    wire[3:0] MEM_wr_wstrb;

    wire predict;

    wire[31:0] NPC_op00;
    wire[31:0] NPC_op01;
    wire[31:0] NPC_op10;
    wire flush_condition_00;
    wire flush_condition_01;
    wire flush_condition_10;
    wire flush_condition_11;
    wire[31:0] target_address_final;
    wire predict_final;
    wire ee;
    wire[31:0] NPC_ee;

    wire[31:0] NPC_op00_reg;
    wire[31:0] NPC_op01_reg;
    wire[31:0] NPC_op10_reg;
    wire flush_condition_00_reg;
    wire flush_condition_01_reg;
    wire flush_condition_10_reg;
    wire flush_condition_11_reg;
    wire[31:0] target_address_final_reg;
    wire predict_final_reg;
    wire ee_reg;
    wire[31:0] NPC_ee_reg;

    //fanout
    wire[31:0] MEM1_ALU1Out_forExPa;
    wire[25:0] Imm26_forBP;
	wire[15:0] Imm16_forEXT;
	wire[25:0] Imm26_forDFF;
	wire[5:0] op;
	wire[5:0] func;
	wire[4:0] shamt;
	wire[7:0] CP0Addr;
	wire[4:0] rs_forRF;
	wire[4:0] rs_forCtrl;
	wire[4:0] rs_forDFF;
	wire[4:0] rs_forBypass;
	wire[4:0] rs_forStall;
	wire[4:0] rt_forRF;
	wire[4:0] rt_forCtrl;
	wire[4:0] rt_forDFF;
	wire[4:0] rt_forBypass;
	wire[4:0] rt_forStall;
	wire[4:0] rt_forMUX1;
	wire[4:0] rd_forMUX1;
    wire[31:0] EX_GPR_RS_forALU1;
    wire[31:0] EX_GPR_RT_forALU1;
    wire[31:0] MUX4Out_forALU1;
    wire[31:0] MUX5Out_forALU1;
    wire[31:0] MUX10Out_forEX;
    wire WB_MUX10Sel_forEX;
    wire[31:0] MUX2Out_forEX;
    wire MEM2_MUX2Sel_forEX;
    wire[31:0] MUX6Out_forEX;
    wire MEM1_MUX6Sel_forEX;
    wire[1:0] MUX4Sel_forALU1;
    wire[1:0] MUX5Sel_forALU1;
    wire[1:0] EX_MUX4Sel_forALU1;
    wire[1:0] EX_MUX5Sel_forALU1;
    wire[4:0] rs_forBypass_forCMP;
    wire[1:0] MUX8Sel_forCMP;
    wire[31:0] MUX8Out_forCMP;
    wire[4:0] rt_forBypass_forCMP;
    wire[1:0] MUX9Sel_forCMP;
    wire[31:0] MUX9Out_forCMP;
    
/**************DATA PATH***************/
    //--------------PF----------------//


PC U_PC(
        .clk(clk), .rst(rst), .wr(PCWr), .flush(PC_Flush),
		.ret_addr(MUX8Out),.NPCOp(NPCOp), .NPC_op00(NPC_op00), .NPC_op01(NPC_op01), .NPC_op10(NPC_op10),
        .flush_condition_00(flush_condition_00), .flush_condition_01(flush_condition_01),
        .flush_condition_10(flush_condition_10), .flush_condition_11(flush_condition_11),
        .target_address_final(target_address_final),.predict_final(predict_final), .ee(ee), .NPC_ee(NPC_ee),

		.ret_addr_reg(ret_addr_reg),.NPCOp_reg(NPCOp_reg), .NPC_op00_reg(NPC_op00_reg), 
        .NPC_op01_reg(NPC_op01_reg), .NPC_op10_reg(NPC_op10_reg),
        .flush_condition_00_reg(flush_condition_00_reg), .flush_condition_01_reg(flush_condition_01_reg),
        .flush_condition_10_reg(flush_condition_10_reg), .flush_condition_11_reg(flush_condition_11_reg),
        .target_address_final_reg(target_address_final_reg),.predict_final_reg(predict_final_reg), 
        .ee_reg(ee_reg), .NPC_ee_reg(NPC_ee_reg)

);

branch_predict_prep U_BRANCH_PREDICT_PREP(
    .IF_PC(PC), 
    .PF_PC(PF_PC),
    .Imm(Imm26_forBP),
    .PF_predict(PF_predict),
    .flush_signal_IF(flush_signal_IF),
    .ret_addr(MUX8Out),
    .branch(branch),
    .target_address(target_addr),
    .MEM_ex(MEM1_Exception),
    .MEM_eret_flush(MEM1_eret_flush),
    .EPC(EPCOut),

    .NPC_op00(NPC_op00),
    .NPC_op01(NPC_op01),
    .NPC_op10(NPC_op10),
    .flush_condition_00(flush_condition_00),
    .flush_condition_01(flush_condition_01),
    .flush_condition_10(flush_condition_10),
    .flush_condition_11(flush_condition_11),
    .target_address_final(target_address_final),
    .predict_final(predict_final),
    .ee(ee),
    .NPC_ee(NPC_ee)
);

instr_fetch_pre U_INSTR_FETCH(
    PF_PC, PCWr, isStall,

    PF_ExcCode,PF_Exception,PPC, PF_icache_valid
    );




	//--------------IF----------------//
PF_IF U_PF_IF(
		//input
		.clk(clk), .rst(rst), .wr(PF_IFWr), .flush(PF_Flush),
        .NPC(PF_PC),.PF_Exception(PF_Exception),.PF_ExcCode(PF_ExcCode), .PF_icache_valid(PF_icache_valid),
		//input signals and output signals are separate
		//output
		.PC(PC),.IF_Exception(IF_Exception), .IF_ExcCode(IF_ExcCode),
        .IF_icache_valid(IF_icache_valid), .IF_stall(IF_stall)
	);

icache U_ICACHE(
	.clk(clk), .resetn(rst), .exception(MEM1_Exception || MEM1_eret_flush), .stall_1(icache_stall_1),
	// cpu && cache
	/*input*/
  	.valid(PF_icache_valid), .index(PPC[11:6]), .tag(PPC[31:12]), .offset(PPC[5:0]),
	/*output*/
	.addr_ok(IF_iCache_addr_ok), .data_ok(IF_iCache_data_ok), .rdata(IF_iCache_rdata),
	//cache && axi
	/*input*/
  	.rd_rdy(IF_icache_rd_rdy),
	.ret_valid(IF_icache_ret_valid),.ret_last(IF_icache_ret_last),
	.ret_data(IF_icache_ret_data),.wr_rdy(IF_icache_wr_rdy),
	/*output*/
	.rd_req(IF_icache_rd_req),.wr_req(IF_icache_wr_req),.rd_type(IF_icache_rd_type),
	.wr_type(IF_icache_wr_type),.rd_addr(IF_icache_rd_addr),.wr_addr(IF_icache_wr_addr),
	.wr_wstrb(IF_icache_wr_wstrb), .wr_data(IF_icache_wr_data)
	);

pre_decode U_PRE_DECODE(
    .IF_OP(IF_iCache_rdata[31:26]),
    .IF_Funct(IF_iCache_rdata[5:0]),

    .IF_BJOp(IF_BJOp)
);

branch_predictor U_BRANCH_PREDICTOR(
    .clk(clk),
    .resetn(rst),
    .index(PC[9:2]),
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
    .index(PC[8:2]),
    .tag(PC[31:9]),
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
		.PC(flush_signal_IF ? PF_PC : PC), .Instr(IF_iCache_rdata &{32{~flush_signal_IF & IF_icache_valid}}),
        .IF_Exception(IF_Exception& ~flush_signal_IF), .IF_ExcCode(IF_ExcCode&{5{~flush_signal_IF}}),
        .IF_BJOp(IF_BJOp& ~flush_signal_IF),

		.ID_PC(ID_PC), .ID_Instr(ID_Instr),.Temp_ID_Excetion(Temp_ID_Excetion),
		.Temp_ID_ExcCode(Temp_ID_ExcCode),

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

		.rst(rst), .RD1(GPR_RS), .RD2(GPR_RT)
	);

ext U_EXT(
		.Imm16(Imm16_forEXT), .EXTOp(EXTOp),

		.Imm32(Imm32)
    );

cmp U_CMP(
		.GPR_RS(MUX8Out_forCMP), .GPR_RT(MUX9Out_forCMP),

		.CMPOut1(CMPOut1), .CMPOut2(CMPOut2)
	);

mux7 U_MUX7(
		.WRSign({ID_dcache_en, DMWr, RFWr, RHLWr}), .MUX7Sel(MUX7Sel),

		.MUX7Out(MUX7Out)
	);

mux8 U_MUX8(
		.GPR_RS(GPR_RS), .data_MEM1(MUX6Out), .data_MEM2(MUX2Out), 
        .MUX8Sel(MUX8Sel), .WD(MUX10Out),

		.out(MUX8Out)
	);

mux8 U_MUX8_forCMP(
		.GPR_RS(GPR_RS), .data_MEM1(MUX6Out), .data_MEM2(MUX2Out), 
        .MUX8Sel(MUX8Sel_forCMP), .WD(MUX10Out),

		.out(MUX8Out_forCMP)
	);

mux9 U_MUX9(
		.GPR_RT(GPR_RT), .data_MEM1(MUX6Out), .data_MEM2(MUX2Out), 
        .MUX9Sel(MUX9Sel), .WD(MUX10Out),

		.out(MUX9Out)
	);

mux9 U_MUX9_forCMP(
		.GPR_RT(GPR_RT), .data_MEM1(MUX6Out), .data_MEM2(MUX2Out), 
        .MUX9Sel(MUX9Sel_forCMP), .WD(MUX10Out),

		.out(MUX9Out_forCMP)
	);

ctrl U_CTRL(
		.clk(clk), .rst(rst), .OP(op), .Funct(func), .rt(rt_forCtrl), .CMPOut1(CMPOut1),
		.CMPOut2(CMPOut2), .rs(rs_forCtrl), .EXE_isBranch(EX_isBranch),
		.Temp_ID_Excetion(Temp_ID_Excetion), .IF_Flush(IF_Flush),.Temp_ID_ExcCode(Temp_ID_ExcCode),

		.MUX1Sel(MUX1Sel), .MUX11Sel(MUX11Sel), .MUX3Sel(MUX3Sel), .RFWr(RFWr), .RHLWr(RHLWr), .DMWr(DMWr), .DMRd(DMRd),
		.NPCOp(NPCOp), .EXTOp(EXTOp), .ALU1Op(ALU1Op), .ALU1Sel(ALU1Sel), .ALU2Op(ALU2Op), .RHLSel_Rd(RHLSel_Rd),
		.RHLSel_Wr(RHLSel_Wr), .DMSel(DMSel), .eret_flush(eret_flush), .CP0WrEn(CP0WrEn),
		.ID_Exception(ID_Exception), .ID_ExcCode(ID_ExcCode), .isBD(isBD), .isBranch(isBranch), .CP0Rd(CP0Rd), .start(start),
		.RHL_visit(RHL_visit),.dcache_en(ID_dcache_en), .BrType(ID_BrType), .J_Type(ID_JType)
	);

mux1 U_MUX1(
		.RT(rt_forMUX1), .RD(rd_forMUX1), .MUX1Sel(MUX1Sel),

		 .Addr3(MUX1Out)
	);
	//--------------EX----------------//
ID_EX U_ID_EX(
		.clk(clk), .rst(rst), .ID_EXWr(ID_EXWr),.RHLSel_Rd(RHLSel_Rd), .PC(ID_PC), .ALU1Op(ALU1Op), .ALU2Op(ALU2Op),
		.MUX1Out(MUX1Out), .MUX3Sel(MUX3Sel),.ALU1Sel(ALU1Sel), .DMWr(MUX7Out[2]), .DMSel(DMSel), .DMRd(DMRd),
		.RFWr(MUX7Out[1]), .RHLWr(MUX7Out[0]),.RHLSel_Wr(RHLSel_Wr), .MUX11Sel(MUX11Sel),
		.GPR_RS(MUX8Out), .GPR_RT(MUX9Out), .RS(rs_forDFF),.RT(rt_forDFF),
		.Imm32(Imm32), .shamt(shamt), .eret_flush(eret_flush), .ID_Flush(ID_Flush), .CP0WrEn(CP0WrEn),
		.Exception(ID_Exception), .ExcCode(ID_ExcCode), .isBD(isBD), .isBranch(isBranch),
		.CP0Addr(CP0Addr), .CP0Rd(CP0Rd), .start(start & ~EX_isBusy),.ID_dcache_en(MUX7Out[3]),
        .MUX4Sel(MUX4Sel), .MUX5Sel(MUX5Sel),
        .ID_BrType(ID_BrType), .ID_Imm26(Imm26_forDFF), .ID_NPCOp(NPCOp),
        .ID_JType(ID_JType), .MUX7Sel(MUX7Sel),
        .MUX4Sel_forALU1(MUX4Sel_forALU1), .MUX5Sel_forALU1(MUX5Sel_forALU1),

		.EX_eret_flush(EX_eret_flush), .EX_CP0WrEn(EX_CP0WrEn), .EX_Exception(EX_Exception),
		.EX_ExcCode(EX_ExcCode), .EX_isBD(EX_isBD), .EX_isBranch(EX_isBranch), .EX_RHLSel_Rd(EX_RHLSel_Rd),
	 	.EX_DMWr(EX_DMWr), .EX_DMRd(EX_DMRd), .EX_MUX3Sel(EX_MUX3Sel), .EX_ALU1Sel(EX_ALU1Sel),
		.EX_RFWr(EX_RFWr), .EX_RHLWr(EX_RHLWr), .EX_ALU2Op(EX_ALU2Op), .EX_RD(EX_RD),
		.EX_RHLSel_Wr(EX_RHLSel_Wr), .EX_DMSel(EX_DMSel), .EX_MUX11Sel(EX_MUX11Sel), .EX_ALU1Op(EX_ALU1Op),
		.EX_RS(EX_RS), .EX_RT(EX_RT), .EX_shamt(EX_shamt), .EX_PC(EX_PC),
		.EX_GPR_RS(EX_GPR_RS), .EX_GPR_RT(EX_GPR_RT), .EX_Imm32(EX_Imm32), .EX_CP0Addr(EX_CP0Addr),
		.EX_CP0Rd(EX_CP0Rd), .EX_start(EX_start),.EX_dcache_en(EX_dcache_en),
        .EX_MUX4Sel(EX_MUX4Sel), .EX_MUX5Sel(EX_MUX5Sel),
        .EX_BrType(EX_BrType), .EX_Imm26(EX_Imm26), .EX_NPCOp(EX_NPCOp),
        .EX_GPR_RS_forALU1(EX_GPR_RS_forALU1), .EX_GPR_RT_forALU1(EX_GPR_RT_forALU1),
        .EX_JType(EX_JType), .EX_MUX7Sel(EX_MUX7Sel), .EX_stall(EX_stall),
        .EX_MUX4Sel_forALU1(EX_MUX4Sel_forALU1), .EX_MUX5Sel_forALU1(EX_MUX5Sel_forALU1)
	);


mux3 U_MUX3(
		.RD2(EX_GPR_RT_forALU1), .Imm32(EX_Imm32), .MUX3Sel(EX_MUX3Sel),

		.B(MUX3Out)
	);

mux12 U_MUX12(
	    .RD1(EX_GPR_RS_forALU1), .shamt(EX_shamt), .ALU1Sel(EX_ALU1Sel), 
	
	    .A(MUX12Out)
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
		.GPR_RS(MUX12Out), .data_EX(MUX6Out_forEX), .data_MEM1(MUX2Out_forEX), 
        .data_MEM2(MUX10Out_forEX), .MUX4Sel(EX_MUX4Sel_forALU1),

		.out(MUX4Out_forALU1)
	);

mux5 U_MUX5_forALU1(
		.GPR_RT(MUX3Out), .data_EX(MUX6Out_forEX), .data_MEM1(MUX2Out_forEX), 
        .data_MEM2(MUX10Out_forEX), .MUX5Sel(EX_MUX5Sel_forALU1),

		.out(MUX5Out_forALU1)
	);


mux11 U_MUX11(
        .Imm32(EX_Imm32), .PC(EX_PC), .RHLOut(RHLOut), .EX_MUX11Sel(EX_MUX11Sel), 
        .MUX11Out(MUX11Out)
        );

bridge_RHL U_ALU2(
		.aclk(clk),.aresetn(rst),.A(MUX4Out), .B(MUX5Out), .ALU2Op(EX_ALU2Op) ,.start(EX_start),
		.EX_RHLWr(EX_RHLWr), .EX_RHLSel_Wr(EX_RHLSel_Wr), .EX_RHLSel_Rd(EX_RHLSel_Rd),
		.MEM_Exception(MEM1_Exception), .MEM_eret_flush(MEM1_eret_flush),

		.isBusy(EX_isBusy),
		.RHLOut(RHLOut)
	);

alu1 U_ALU1(
		.A(MUX4Out_forALU1), .B(MUX5Out_forALU1),.ALU1Op(EX_ALU1Op),

		.C(ALU1Out),.Overflow(Overflow)
	);

ex_prep U_EX_PREP(
    .EX_NPCOp(EX_NPCOp),
    .EX_Imm26(EX_Imm26),
    .ID_PC(ID_PC),
    .EX_MUX11Sel(EX_MUX11Sel),
    .return_addr(EX_GPR_RS),

    .EX_address(EX_address),
    .EX_MUX6Sel(EX_MUX6Sel),
    .EX_MUX2Sel(EX_MUX2Sel),
    .EX_MUX10Sel(EX_MUX10Sel)
);
	//-------------MEM1---------------//
EX_MEM1 U_EX_MEM1(
		.clk(clk), .rst(rst), .EX_MEM1Wr(EX_MEM1Wr), .EX_PC(EX_PC), .DMWr(EX_DMWr),
        .DMSel(EX_DMSel), .DMRd(EX_DMRd), .RFWr(EX_RFWr), .MUX11Out(MUX11Out),
        .ALU1Out(ALU1Out), .GPR_RT(MUX5Out), .RD(EX_RD), .EX_Flush(EX_Flush), .eret_flush(EX_eret_flush),
        .CP0WrEn(EX_CP0WrEn), .Exception(EX_Exception), .ExcCode(EX_ExcCode), .isBD(EX_isBD),
        .CP0Addr(EX_CP0Addr), .CP0Rd(EX_CP0Rd), .EX_dcache_en(EX_dcache_en),.Overflow(Overflow),
        .MUX6Sel(EX_MUX6Sel), .MUX2Sel(EX_MUX2Sel), .MUX10Sel(EX_MUX10Sel),

		.MEM1_DMWr(MEM1_DMWr), .MEM1_DMRd(MEM1_DMRd), .MEM1_RFWr(MEM1_RFWr),.MEM1_eret_flush(MEM1_eret_flush),
        .MEM1_CP0WrEn(MEM1_CP0WrEn), .MEM1_Exception(Temp_M1_Exception), .MEM1_ExcCode(Temp_M1_ExcCode),
        .MEM1_isBD(MEM1_isBD),.MEM1_DMSel(MEM1_DMSel), .MEM1_RD(MEM1_RD),
        .MEM1_PC(MEM1_PC), .MEM1_MUX11Out(MEM1_MUX11Out), .MEM1_ALU1Out(MEM1_ALU1Out), 
        .MEM1_GPR_RT(MEM1_GPR_RT), .MEM1_CP0Addr(MEM1_CP0Addr), .MEM1_CP0Rd(MEM1_CP0Rd),
        .MEM1_dcache_en(MEM1_dcache_en),.MEM1_Overflow(MEM1_Overflow),
        .MEM1_ALU1Out_forExPa(MEM1_ALU1Out_forExPa), .MEM1_MUX6Sel(MEM1_MUX6Sel), 
        .MEM1_MUX2Sel(MEM1_MUX2Sel), .MEM1_MUX10Sel(MEM1_MUX10Sel), .MEM1_MUX6Sel_forEX(MEM1_MUX6Sel_forEX)
	);



CP0 U_CP0(
		.clk(clk), .rst(rst), .CP0WrEn(MEM1_CP0WrEn), .addr(MEM1_CP0Addr), .data_in(MEM1_GPR_RT),
		.MEM_Exc(MEM1_Exception), .MEM_eret_flush(MEM1_eret_flush), .MEM_bd(MEM1_isBD),
        .ext_int_in(ext_int_in), .MEM_ExcCode(MEM1_ExcCode),.MEM_badvaddr(MEM1_badvaddr),
		.MEM_PC(MEM1_PC), .dcache_stall(dcache_stall),

		.data_out(CP0Out), .EPC_out(EPCOut), .Interrupt(Interrupt)
	);

mux6 U_MUX6(
		.MUX11Out(MEM1_MUX11Out), .ALU1Out(MEM1_ALU1Out), .MUX6Sel(MEM1_MUX6Sel),

		.out(MUX6Out)
	);

mux6 U_MUX6_forEX(
		.MUX11Out(MEM1_MUX11Out), .ALU1Out(MEM1_ALU1Out), .MUX6Sel(MEM1_MUX6Sel_forEX),

		.out(MUX6Out_forEX)
	);

exception U_EXCEPTION(
    MEM1_Overflow, Temp_M1_Exception, MEM1_DMWr, MEM1_DMSel, MEM1_ALU1Out_forExPa,
    MEM1_DMRd, Temp_M1_ExcCode, MEM1_PC, MEM1_RFWr,Interrupt,

    MEM1_Exception, MEM1_ExcCode, MEM1_badvaddr
    );

mem1_cache_prep U_MEM1_CACHE_PREP(
    MEM1_dcache_en,MEM1_eret_flush, MEM1_Exception,
    MEM1_ALU1Out_forExPa, MEM1_DMWr, MEM1_DMSel,
    IF_iCache_data_ok, MEM_unCache_data_ok,

    MEM1_Paddr, MEM1_cache_sel, MEM1_dcache_valid,
    DMWen_dcache, MEM1_dCache_wstrb,
    MEM1_uncache_valid, MEM1_DMen,
    MEM1_dcache_valid_except_icache, MEM1_rstrb
	);

dcache U_DCACHE(.clk(clk), .resetn(rst), .DMen(MEM1_dcache_en), 
    .stall_1(~(IF_iCache_data_ok&MEM_unCache_data_ok)),
	// cpu && cache
  	.valid(MEM1_dcache_valid), .op(DMWen_dcache), .index(MEM1_Paddr[11:6]),
    .tag(MEM1_Paddr[31:12]), .offset(MEM1_Paddr[5:0]),.wstrb(MEM1_dCache_wstrb), .wdata(MEM1_GPR_RT),
    .addr_ok(MEM_dCache_addr_ok), .data_ok(MEM_dCache_data_ok), .rdata(dcache_Out),
	//cache && axi
  	.rd_req(MEM_dcache_rd_req), .rd_type(MEM_dcache_rd_type), .rd_addr(MEM_dcache_rd_addr),
    .rd_rdy(MEM_dcache_rd_rdy), .ret_valid(MEM_dcache_ret_valid), .ret_last(MEM_dcache_ret_last),
    .ret_data(MEM_dcache_ret_data), .wr_valid(bvalid), .wr_req(MEM_dcache_wr_req),
    .wr_type(MEM_dcache_wr_type), .wr_addr(MEM_dcache_wr_addr), .wr_wstrb(MEM_dcache_wr_wstrb),
    .wr_data(MEM_dcache_wr_data), .wr_rdy(MEM_dcache_wr_rdy),
    .uncache_out(uncache_Out), .cache_sel(MEM2_cache_sel)
	);
	//-------------MEM2---------------//
MEM1_MEM2 U_MEM1_MEM2(
		.clk(clk), .rst(rst), .PC(MEM1_PC), .RFWr(MEM1_RFWr), .MUX2Sel(MEM1_MUX2Sel),
		.MUX6Out(MUX6Out), .RD(MEM1_RD), .MEM1_Flush(MEM1_Flush), . MUX10Sel(MEM1_MUX10Sel),
        .CP0Out(CP0Out), .MEM1_MEM2Wr(MEM1_MEM2Wr), .DMSel(MEM1_DMSel),
        .cache_sel(MEM1_cache_sel), .DMWen(DMWen_dcache), .Exception(MEM1_Exception),
        .eret_flush(MEM1_eret_flush), .uncache_valid(MEM1_uncache_valid), .DMen(MEM1_DMen),
        .Paddr(MEM1_Paddr), .MEM1_dCache_wstrb(MEM1_dCache_wstrb), .GPR_RT(MEM1_GPR_RT),
        .DMRd(MEM1_DMRd), .MEM1_rstrb(MEM1_rstrb),

		.MEM2_RFWr(MEM2_RFWr), .MEM2_MUX2Sel(MEM2_MUX2Sel),
		.MEM2_RD(MEM2_RD), .MEM2_PC(MEM2_PC), .MEM2_MUX10Sel(MEM2_MUX10Sel),
		.MEM2_MUX6Out(MEM2_MUX6Out), .MEM2_CP0Out(MEM2_CP0Out),
        .MEM2_DMSel(MEM2_DMSel), .MEM2_cache_sel(MEM2_cache_sel), .MEM2_DMWen(DMWen_uncache),
        .MEM2_Exception(MEM2_Exception), .MEM2_eret_flush(MEM2_eret_flush),
        .MEM2_uncache_valid(MEM2_uncache_valid), .MEM2_DMen(MEM2_DMen),
        .MEM2_Paddr(MEM2_Paddr), .MEM2_unCache_wstrb(MEM2_unCache_wstrb), .MEM2_GPR_RT(MEM2_GPR_RT),
        .MEM2_DMRd(MEM2_DMRd), .MEM2_rstrb(MEM2_rstrb), .MEM2_MUX2Sel_forEX(MEM2_MUX2Sel_forEX)
	);

mux2 U_MUX2(
		.MUX6Out(MEM2_MUX6Out), .MUX2Sel(MEM2_MUX2Sel), .CP0Out(MEM2_CP0Out),

		.WD(MUX2Out)
	);

mux2 U_MUX2_forEX(
		.MUX6Out(MEM2_MUX6Out), .MUX2Sel(MEM2_MUX2Sel_forEX), .CP0Out(MEM2_CP0Out),

		.WD(MUX2Out_forEX)
	);



uncache_dm U_UNCACHE_DM(
        .clk(clk), .resetn(rst), .DMSel(MEM2_DMSel),
        .valid(MEM2_uncache_valid), .op(DMWen_uncache), .addr(MEM2_Paddr), .wstrb(MEM2_unCache_wstrb),
        .wdata(MEM2_GPR_RT), .data_ok(MEM_unCache_data_ok), .rdata(uncache_Out),
        .rd_rdy(MEM_dcache_rd_rdy), .wr_rdy(MEM_dcache_wr_rdy), .ret_valid(MEM_dcache_ret_valid),
        .ret_last(MEM_dcache_ret_last),.ret_data(MEM_dcache_ret_data),.wr_valid(bvalid),
        .rd_req(MEM_uncache_rd_req), .wr_req(MEM_uncache_wr_req), .rd_type(MEM_uncache_rd_type),
		.wr_type(MEM_uncache_wr_type), .rd_addr(MEM_uncache_rd_addr), .wr_addr(MEM_uncache_wr_addr),
		.wr_wstrb(MEM_uncache_wr_wstrb), .wr_data(MEM_uncache_wr_data)
);

bridge_dm U_BRIDGE_DM(
		 .Din(dcache_Out),
         .rstrb(MEM2_rstrb),

		 .dout(DMOut)
	);

cache_select_dm U_CACHE_SELECT_DM(
				MEM2_cache_sel, MEM_unCache_data_ok, MEM_dCache_data_ok,
                MEM_uncache_rd_req, MEM_dcache_rd_req, MEM_uncache_wr_req, MEM_dcache_wr_req,
                MEM_uncache_rd_type, MEM_dcache_rd_type, MEM_uncache_wr_type, MEM_dcache_wr_type,
                MEM_uncache_rd_addr, MEM_dcache_rd_addr, MEM_uncache_wr_addr, MEM_dcache_wr_addr,
                MEM_uncache_wr_wstrb, MEM_dcache_wr_wstrb,

                MEM_data_ok, MEM_rd_req, MEM_wr_req, MEM_rd_type, MEM_wr_type, MEM_rd_addr,
                MEM_wr_addr, MEM_wr_wstrb
                );

    //--------------WB----------------//
MEM2_WB U_MEM2_WB(
            .clk(clk), .rst(rst), .MEM2_WBWr(MEM2_WBWr), .MEM2_Flush(MEM2_Flush),
			.PC(MEM2_PC), .MUX2Out(MUX2Out), .MUX10Sel(MEM2_MUX10Sel), .RD(MEM2_RD), .RFWr(MEM2_RFWr),
            .DMOut(DMOut), 

			.WB_PC(WB_PC), .WB_MUX2Out(WB_MUX2Out), .WB_MUX10Sel(WB_MUX10Sel),
            .WB_RD(WB_RD), .WB_RFWr(WB_RFWr), .WB_DMOut(WB_DMOut), .WB_MUX10Sel_forEX(WB_MUX10Sel_forEX)
            );

mux10 U_MUX10(
            .WB_MUX2Out(WB_MUX2Out), .WB_DMOut(WB_DMOut), .WB_MUX10Sel(WB_MUX10Sel),
            .MUX10Out(MUX10Out)
        );

mux10 U_MUX10_forEX(
            .WB_MUX2Out(WB_MUX2Out), .WB_DMOut(WB_DMOut), .WB_MUX10Sel(WB_MUX10Sel_forEX),
            .MUX10Out(MUX10Out_forEX)
        );


    //-------------ELSE---------------//
//physical address tranfer

npc U_NPC(
		.ret_addr(ret_addr_reg), .NPCOp(NPCOp_reg), .NPC_op00(NPC_op00_reg), .NPC_op01(NPC_op01_reg),
        .NPC_op10(NPC_op10_reg), .flush_condition_00(flush_condition_00_reg), 
        .flush_condition_01(flush_condition_01_reg), .flush_condition_10(flush_condition_10_reg),
        .flush_condition_11(flush_condition_11_reg),.target_address_final(target_address_final_reg),
        .predict_final(predict_final_reg), .ee(ee_reg), .NPC_ee(NPC_ee_reg),
        .EX_isBranch(EX_isBranch), .EX_stall(EX_stall), .EX_MUX7Sel(EX_MUX7Sel), 
        .IF_stall(IF_stall), .clk(clk), .rst(rst),

		.NPC(PF_PC), .flush_signal_PF(flush_signal_IF), .predict(PF_predict)
	);

flush U_FLUSH(
        .MEM_eret_flush(MEM1_eret_flush), .MEM_ex(MEM1_Exception), .NPCOp(NPCOp), 
        .PCWr(PCWr), .can_go(MEM2_can_go),
	
        .PC_Flush(PC_Flush), .PF_Flush(PF_Flush), .IF_Flush(IF_Flush), .ID_Flush(ID_Flush),
        .EX_Flush(EX_Flush), .MEM1_Flush(MEM1_Flush), .MEM2_Flush(MEM2_Flush)
    );

bypass U_BYPASS(
		.EX_RS(EX_RS), .EX_RT(EX_RT), .ID_RS(rs_forBypass), .ID_RT(rt_forBypass),
        .MEM1_RD(MEM1_RD), .MEM2_RD(MEM2_RD), .EX_RD(EX_RD), .WB_RD(WB_RD),
		.MEM1_RFWr(MEM1_RFWr), .MEM2_RFWr(MEM2_RFWr), .EX_RFWr(EX_RFWr), .WB_RFWr(WB_RFWr),
        .ALU1Sel(ALU1Sel), .MUX3Sel(MUX3Sel), 
        .ID_RS_forCMP(rs_forBypass_forCMP), .ID_RT_forCMP(rt_forBypass_forCMP),

        .MUX4Sel(MUX4Sel), .MUX5Sel(MUX5Sel), 
        .MUX4Sel_forALU1(MUX4Sel_forALU1), .MUX5Sel_forALU1(MUX5Sel_forALU1),
		.MUX8Sel(MUX8Sel), .MUX9Sel(MUX9Sel),
        .MUX8Sel_forCMP(MUX8Sel_forCMP), .MUX9Sel_forCMP(MUX9Sel_forCMP)
	);

stall U_STALL(
		.EX_RT(EX_RD), .MEM1_RT(MEM1_RD), .MEM2_RT(MEM2_RD), .ID_RS(rs_forStall), .ID_RT(rt_forStall),
		.EX_DMRd(EX_DMRd), .MEM1_DMRd(MEM1_DMRd), .MEM2_DMRd(MEM2_DMRd),
		.BJOp(ID_BJOp),.EX_RFWr(EX_RFWr), .EX_CP0Rd(EX_CP0Rd), .MEM1_CP0Rd(MEM1_CP0Rd),
		.MEM1_ex(MEM1_Exception), .MEM1_RFWr(MEM1_RFWr), .MEM2_RFWr(MEM2_RFWr),
		.MEM1_eret_flush(MEM1_eret_flush),.isbusy(EX_isBusy), .RHL_visit(RHL_visit),
		.iCache_data_ok(IF_iCache_data_ok),.dCache_data_ok(MEM_data_ok),.MEM2_dCache_en(MEM2_DMen),
		.MEM1_cache_sel(MEM1_cache_sel), .MEM_dCache_addr_ok(MEM_dCache_addr_ok),
		.MEM1_dCache_en(MEM1_dcache_valid), .MEM1_dcache_valid_except_icache(MEM1_dcache_valid_except_icache),

		.PCWr(PCWr), .IF_IDWr(IF_IDWr), .MUX7Sel(MUX7Sel),.isStall(isStall), .data_ok(MEM2_can_go),
		.dcache_stall(dcache_stall), .icache_stall_1(icache_stall_1),
        .ID_EXWr(ID_EXWr), .EX_MEM1Wr(EX_MEM1Wr), .MEM1_MEM2Wr(MEM1_MEM2Wr),
        .MEM2_WBWr(MEM2_WBWr), .PF_IFWr(PF_IFWr)
	);

axi_sram_bridge U_AXI_SRAM_BRIDGE(
	MEM2_cache_sel,
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
	IF_icache_rd_req,// icache �???????? dcache 同时缺失怎么�????????
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

debug U_DEBUG(MUX10Out, WB_PC, WB_RFWr, MEM2_WBWr,WB_RD,
        debug_wb_rf_wdata, debug_wb_pc, debug_wb_rf_wen, debug_wb_rf_wnum );

endmodule