module  bridge_dm(
	Din,
	rstrb,
	MEM2_GPR_RT,

	dout
);
	input [31:0] 		Din;
	input [4:0] 		rstrb;
	input [31:0] 		MEM2_GPR_RT;

	output reg [31:0] 	dout;


always@(*)
	case(rstrb)
		//LBU
		5'b00000: dout = {24'h0,Din[ 7: 0]};
		5'b00001: dout = {24'h0,Din[15: 8]};
		5'b00010: dout = {24'h0,Din[23:16]};
		5'b00011: dout = {24'h0,Din[31:24]};
		//LB
		5'b01000: dout = {{24{Din[ 7]}},Din[ 7: 0]};
		5'b01001: dout = {{24{Din[15]}},Din[15: 8]};
		5'b01010: dout = {{24{Din[23]}},Din[23:16]};
		5'b01011: dout = {{24{Din[31]}},Din[31:24]};
		//LHU
		5'b00100: dout = {16'h0,Din[15: 0]};
		5'b00110: dout = {16'h0,Din[31:16]};
		//LH
		5'b01100: dout = {{16{Din[15]}},Din[15: 0]};
		5'b01110: dout = {{16{Din[31]}},Din[31:16]};
		//LWL
		5'b11000: dout = {Din[ 7: 0],MEM2_GPR_RT[23: 0]};
		5'b11100: dout = {Din[15: 0],MEM2_GPR_RT[15: 0]};
		5'b11110: dout = {Din[23: 0],MEM2_GPR_RT[ 7: 0]};
		//LWR
		5'b10111: dout = {MEM2_GPR_RT[31:24],Din[31: 8]};
		5'b10011: dout = {MEM2_GPR_RT[31:16],Din[31:16]};
		5'b10001: dout = {MEM2_GPR_RT[31: 8],Din[31:24]};
		//LW LL
		default:  dout = Din;
	endcase


endmodule



// 这个模块用于当前与cpu与乘除器的交互�??
// 借助状�?�机来控�??
// * start�??1时，乘除法开始计�??
// * isBusy�??1时，表示正在运行
// * 乘法5周期运算，除法多周期�??34个）�??
// * C是运算结果，支持读保存，即如果没有新的start，结果会保持为上�??次的运算结果
module bridge_RHL(
		aclk,
		aresetn,
		A,
		B,
		ALU2Op,
		start,
		EX_RHLWr,
		EX_RHLSel_Wr,
		EX_RHLSel_Rd,
		MEM_Exception,
		MEM_eret_flush,
		dcache_stall,
		EX_Exception,
		WAIT,

		isBusy,
		RHLOut,
		MULOut,
		MUL_sign
	);
input 			aclk;
input 			aresetn;
input [31:0] 	A;
input [31:0] 	B;
input [3:0] 	ALU2Op;
input 			start;
input 			EX_RHLWr;
input [1:0] 	EX_RHLSel_Wr;
input 			EX_RHLSel_Rd;
input 			MEM_Exception;
input 			MEM_eret_flush;
input 			dcache_stall;
input			EX_Exception;
input			WAIT;

output 			isBusy;
output [31:0] 	RHLOut;
output [31:0] 	MULOut;
output	 		MUL_sign;

wire [63:0] 	divider_sign_out;
wire [63:0] 	divider_unsign_out;
wire [63:0] 	multi_sign_out;
wire [63:0] 	multi_unsign_out;
wire 			m_axis_dout_tvalid_sign;
wire 			m_axis_dout_tvalid_unsign;
wire 			multiplier_signed_valid;
wire 			multiplier_unsigned_valid;

reg  [63:0] 	RHL;
reg [3:0] 		Temp_ALU2Op;
reg 			present_state_div;
reg 			next_state_div;
reg 			present_state_mult;
reg 			next_state_mult;
reg 			present_state_multu;
reg 			next_state_multu;
reg [2:0] 		counter;
reg 			valid;

/*
	Control signals:
				MULT: 	ALU2Op <= 4'b0000;
				MULTU: 	ALU2Op <= 4'b0001;
				DIVU: 	ALU2Op <= 4'b0010;
				DIV: 	ALU2Op <= 4'b0011;

				maddu:	ALU2Op <= 4'b0100;
				madd:	ALU2Op <= 4'b0101;
				msub:	ALU2Op <= 4'b0110;
				msubu:	ALU2Op <= 4'b0111;

				mul:	ALU2Op <= 4'b1000;
*/

parameter state_free = 1'b0 ;
parameter state_busy = 1'b1 ;

assign RHLOut = EX_RHLSel_Rd ? RHL[63:32] : RHL[31:0];
assign MULOut = multi_sign_out[31:0];//mul 可能会往目标寄存器写好几�??
//assign isBusy= next_state_div | next_state_mult | next_state_multu;

assign isBusy = present_state_div&!m_axis_dout_tvalid_sign&!m_axis_dout_tvalid_unsign |
				(present_state_mult|present_state_multu)&(counter != 3'd4) |
				start&!EX_Exception&(!present_state_div& ~ALU2Op[2] & ALU2Op[1] |
				!present_state_mult&(ALU2Op==4'b0001 | ALU2Op==4'b0101 | ALU2Op==4'b0110 | ALU2Op==4'b1000) |
				!present_state_multu&(ALU2Op==4'b0000 | ALU2Op==4'b0100 | ALU2Op==4'b0111));


always@(posedge aclk)
	if(!aresetn || counter == 3'd4 )
		counter <= 3'b000;
	else if(present_state_mult == state_busy || present_state_multu == state_busy)
		counter <= counter + 1;

//store the value of RHL and ALU2Op for the madd, maddu, msub, msubu

always @(posedge aclk) begin
	if (!aresetn)
		Temp_ALU2Op <= 4'b0;
	else if (present_state_mult==state_free && next_state_mult==state_busy )
		Temp_ALU2Op <= ALU2Op;
	else if (present_state_multu==state_free && next_state_multu==state_busy )
		Temp_ALU2Op <= ALU2Op;
end

//the signal is signing the mul is working
	assign MUL_sign = (ALU2Op==4'b1000 & isBusy) ;

always@(posedge aclk)
	if(!aresetn)
		valid <= 1'b1;
	else if((!present_state_div&next_state_div | !present_state_mult&next_state_mult
			| !present_state_multu&next_state_multu)&MEM_Exception)
		valid <= 1'b0;
	else if(present_state_div&(m_axis_dout_tvalid_sign|m_axis_dout_tvalid_unsign)
			| (present_state_mult|present_state_multu)&(counter == 3'd4))
		valid <= 1'b1;



always @(posedge aclk) begin
    if(!aresetn)
        RHL <= 64'd0;
	else if((present_state_multu == state_busy) && (counter == 3'd4) && valid)
		case(Temp_ALU2Op)
			4'b0100:	RHL <= RHL + multi_unsign_out;
			4'b0111:	RHL <= RHL - multi_unsign_out;
			default:	RHL <= multi_unsign_out;
		endcase
	else if((present_state_mult == state_busy) && (counter == 3'd4) & valid)
		case(Temp_ALU2Op)
			4'b0101:	RHL <= RHL + multi_sign_out;
			4'b0110:	RHL <= RHL - multi_sign_out;
			default:	RHL <= multi_sign_out;
		endcase
	else if(m_axis_dout_tvalid_sign & valid) //sign
		RHL <= {divider_sign_out[31:0],divider_sign_out[63:32]};
	else if(m_axis_dout_tvalid_unsign & valid) //unsign
		RHL <= {divider_unsign_out[31:0],divider_unsign_out[63:32]};
	else if(EX_RHLWr && (EX_RHLSel_Wr == 2'b01) && !MEM_Exception && !MEM_eret_flush)
	    RHL <= {A,RHL[31:0]};
	else if(EX_RHLWr && (EX_RHLSel_Wr == 2'b00) && !MEM_Exception && !MEM_eret_flush)
	    RHL <= {RHL[63:32],A};
end

always @(posedge aclk ) begin
	if(!aresetn)
	begin
		present_state_div<=state_free;
	end
	else
	begin
		present_state_div<=next_state_div;
	end
end

always @(*) begin
	if(present_state_div == state_free) begin
	   if(start && ~ALU2Op[2] && ALU2Op[1] && !MEM_eret_flush && !EX_Exception)
	       next_state_div=state_busy;
	   else
	       next_state_div=state_free;
	end
	else begin
	   if (m_axis_dout_tvalid_sign|m_axis_dout_tvalid_unsign)
		   next_state_div=state_free;
	   else
	       next_state_div=state_busy;
	end

end

always @(posedge aclk ) begin
	if(!aresetn)
	begin
		present_state_mult<=state_free;
	end
	else
	begin
		present_state_mult<=next_state_mult;
	end
end

always @(present_state_mult,multiplier_signed_valid,counter) begin
	if(present_state_mult == state_free) begin
	   if(multiplier_signed_valid)
	       next_state_mult=state_busy;
	   else
	       next_state_mult=state_free;
	end
	else begin
	   if (counter == 3'd4)
		   next_state_mult=state_free;
	   else
	       next_state_mult=state_busy;
	end

end

always @(posedge aclk ) begin
	if(!aresetn)
	begin
		present_state_multu<=state_free;
	end
	else
	begin
		present_state_multu<=next_state_multu;
	end
end

always @(present_state_multu, multiplier_unsigned_valid,counter) begin
	if(present_state_multu == state_free) begin
	   if(multiplier_unsigned_valid)
	       next_state_multu=state_busy;
	   else
	       next_state_multu=state_free;
	end
	else begin
	   if (counter == 3'd4)
		   next_state_multu=state_free;
	   else
	       next_state_multu=state_busy;
	end

end

wire divider_sign_valid=(start && (ALU2Op == 4'b0011)  && !MEM_eret_flush && !EX_Exception
			&& isBusy && !present_state_div);
divider_signed divider_signed (
  .aclk(aclk),                                      // input wire aclk
  .aresetn(aresetn),                                // input wire aresetn
  .s_axis_divisor_tvalid(divider_sign_valid),    // input wire s_axis_divisor_tvalid
  .s_axis_divisor_tdata(B),      // input wire [31 : 0] s_axis_divisor_tdata
  .s_axis_dividend_tvalid(divider_sign_valid),  // input wire s_axis_dividend_tvalid
  .s_axis_dividend_tdata(A),    // input wire [31 : 0] s_axis_dividend_tdata
  .m_axis_dout_tvalid(m_axis_dout_tvalid_sign),          // output wire m_axis_dout_tvalid
  .m_axis_dout_tdata(divider_sign_out)            // output wire [63 : 0] m_axis_dout_tdata
);

wire divider_unsign_valid = (start && (ALU2Op == 4'b0010)  && !MEM_eret_flush && !EX_Exception
			&& isBusy && !present_state_div);
divider_unsigned divider_unsigned (
  .aclk(aclk),                                      // input wire aclk
  .aresetn(aresetn),                                // input wire aresetn
  .s_axis_divisor_tvalid(divider_unsign_valid),    // input wire s_axis_divisor_tvalid
  .s_axis_divisor_tdata(B),      // input wire [31 : 0] s_axis_divisor_tdata
  .s_axis_dividend_tvalid(divider_unsign_valid),  // input wire s_axis_dividend_tvalid
  .s_axis_dividend_tdata(A),    // input wire [31 : 0] s_axis_dividend_tdata
  .m_axis_dout_tvalid(m_axis_dout_tvalid_unsign),          // output wire m_axis_dout_tvalid
  .m_axis_dout_tdata(divider_unsign_out)            // output wire [63 : 0] m_axis_dout_tdata
);

assign multiplier_signed_valid = (start && (ALU2Op==4'b0001 || ALU2Op==4'b0101 || ALU2Op==4'b0110 || ALU2Op==4'b1000)
						&& !MEM_eret_flush && !EX_Exception && !dcache_stall && !WAIT);
multiplier_signed multiplier_signed(
	.CLK(aclk),
	.A(A),
	.B(B),
	.CE(next_state_mult),
	.P(multi_sign_out)
);

assign multiplier_unsigned_valid = (start &&  (ALU2Op==4'b0000 || ALU2Op==4'b0100 || ALU2Op==4'b0111)
					 && !MEM_eret_flush && !EX_Exception && !dcache_stall && !WAIT);
multiplier_unsigned multiplier_unsigned(
	.CLK(aclk),
	.A(A),
	.B(B),
	.CE(next_state_multu),
	.P(multi_unsign_out)
);

endmodule
// 因为cache的接口设计是偏向类sram接口�??
// �??以用这个模块进行 cpu和cache对axi的交�??
// 写着写着又写成转接口�?? XD
// 写的很粗糙，有巨大优化空间，目前仅仅为了实现功能
// 将来也许会对cache等做进一步优�??

//              -----------
// ***********  |�?? �?? �?? 理| ************
//              -----------
//	1.借助状�?�机实现,按照五个通道的axi设计，顺势设出两个状态机，再多添�??个空闲�?�一个完�??
//      FSM_R: 读请求，读响应，空闲�?? 完成
//		FSM_W：写请求，写数据，写响应，空闲�?�完�??
//  2.根据握手信号实现前请求状态到响应状�?�的转换
//  3.根据当前状�?�和其他�??些信号的组合逻辑生成�??些诸如data_ok,addr_ok的信�??
//  4.如果icache和dcache同时缺失，优先响应read dcache
module axi_sram_bridge(

    dcache_sel,
    icache_sel,
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
	MEM_uncache_wr_data

);
	input dcache_sel;
	input icache_sel;
// 中断信号
    input [5:0] ext_int_in      ;  //interrupt,high active;


// 时钟与复位信�??
    input clk      ;
    input rst      ;   //low active
// 读请求�?�道
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
//读相应�?�道
    input [ 3:0]    rid       ;
    input [31:0]    rdata     ;
    input [ 1:0]    rresp     ;
    input           rlast     ;
    input           rvalid    ;
    output          rready    ;
//写请求�?�道
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
// 写数据�?�道
    output [ 3:0]   wid       ;
    output [31:0]   wdata     ;
    output [ 3:0]   wstrb     ;
    output          wlast     ;
    output          wvalid    ;
    input           wready    ;
// 写相应�?�道
    input [3:0]     bid       ;
    input [1:0]     bresp     ;
    input           bvalid    ;
    output          bready    ;

// icache
	input IF_icache_rd_req;
	input [2:0]IF_icache_rd_type;
	input [31:0] IF_icache_rd_addr;
	output  IF_icache_rd_rdy;
	output  IF_icache_ret_valid;
	output IF_icache_ret_last;
	output [31:0] IF_icache_ret_data;
	input IF_icache_wr_req;
	input [2:0] IF_icache_wr_type;
	input [31:0] IF_icache_wr_addr;
	input [3:0] IF_icache_wr_wstrb;
	input [511:0] IF_icache_wr_data;
	output IF_icache_wr_rdy;
// dcache
	input MEM_dcache_rd_req;
	input [2:0]MEM_dcache_rd_type;
	input [31:0] MEM_dcache_rd_addr;
	output  MEM_dcache_rd_rdy;
	output  MEM_dcache_ret_valid;
	output MEM_dcache_ret_last;
	output [31:0] MEM_dcache_ret_data;
	input MEM_dcache_wr_req;
	input [2:0] MEM_dcache_wr_type;
	input [31:0] MEM_dcache_wr_addr;
	input [3:0] MEM_dcache_wr_wstrb;
	input [511:0] MEM_dcache_wr_data;
	output MEM_dcache_wr_rdy;
	input [31:0]MEM_uncache_wr_data;

reg [3:0] count_wr16;
//暂时用不到的信号初始�??
    assign arlock   =   0;
	assign arcache  =  	0;
    assign arprot   =   0;
    assign awid     =   1;
	assign rready   =   1;

    assign awlock   =   0;
    assign awcache  =   0;
    assign awprot   =   0;
    assign wid      =   1;

    // assign wlast    =   1;

//状�?�定�??
/*FSM_R*/
// parameter state_rd_free = 2'b00;
parameter state_rd_req = 2'b01;
parameter state_rd_res = 2'b10;
parameter state_rd_finish = 2'b11;

// parameter state_rd_free = 3'd0;
// parameter state_if_send = 3'd1;
// parameter state_if_wait = 3'd2;
// parameter state_mem_send = 3'd3;
// parameter state_mem_wait = 3'd4;
// parameter state_two_send_if = 3'd5;
// parameter state_two_send_mem = 3'd6;
parameter state_rd_free = 3'd0;
parameter state_if_send = 3'd1;
parameter state_if_wait = 3'd2;
parameter state_mem_send = 3'd3;
parameter state_mem_wait = 3'd4;
parameter state_finish = 3'd5;
/*FSM_W*/
parameter state_wr_free = 3'b000;
parameter state_wr_req = 3'b001;
parameter state_wr_data = 3'b010;
parameter state_wr_res = 3'b011;
parameter state_wr_finish = 3'b100;

//参数定义

reg [2:0] current_rd_state;
reg [2:0] next_rd_state;

reg [2:0] current_wr_state;
reg [2:0] next_wr_state;
reg [511:0] temp_data;//write buffer

reg arid_reg;// 寄存事务id
reg conf_wr;// write event argument
reg dram_wr;
reg [31:0] uncache_wr_data_reg;
reg is_writing;
reg [31:0] writing_addr;
reg [3:0] MEM_dcache_wr_wstrb_buf;
reg [2:0] MEM_dcache_wr_type_buf;
initial begin
	count_wr16 = 0;
	conf_wr=0;
	dram_wr=0;
	uncache_wr_data_reg=0;
	is_writing =0;
end

always @(posedge clk) begin
	if(!rst)
		is_writing<=0;
	else if(MEM_dcache_wr_req)
		is_writing<=1;
	else if(next_wr_state == state_wr_finish)
		is_writing<=0;

end

always @(posedge clk) begin
	if(!rst)
    begin
		writing_addr<=0;
        MEM_dcache_wr_type_buf<=0;
        MEM_dcache_wr_wstrb_buf<=0;
    end
	else if(MEM_dcache_wr_req)
    begin
		writing_addr<=MEM_dcache_wr_addr;
        MEM_dcache_wr_type_buf<=MEM_dcache_wr_type;
        MEM_dcache_wr_wstrb_buf<=MEM_dcache_wr_wstrb;
    end

end

always @(posedge clk) begin
	if(!rst)
		conf_wr<=0;
	if(MEM_dcache_wr_req & dcache_sel)
	 	conf_wr<=1;
	else if (next_wr_state==state_wr_finish)
		conf_wr<=0;

end

always @(posedge clk) begin
	if(!rst)
		dram_wr<=0;
	if(MEM_dcache_wr_req & ~dcache_sel)
	 	dram_wr<=1;
	else if (next_wr_state==state_wr_finish)
		dram_wr<=0;

end
//Write Passway
always @(posedge clk) begin
	if(!rst)
	begin
		temp_data<=0;
	end
	else if(current_wr_state==state_wr_req)
	begin
		temp_data<=MEM_dcache_wr_data;
	end
	else if((current_wr_state==state_wr_data)&&wready)
	begin
		temp_data<={32'b0,{temp_data[511:32]}};//�??要与 wdata 保持�??�??
	end
end
always @(posedge clk) begin
	if(!rst)
	begin
		uncache_wr_data_reg<=0;
	end
	else if(current_wr_state==state_wr_req)
	begin
		uncache_wr_data_reg<=MEM_uncache_wr_data;
	end
end

always @(posedge clk) begin
	if((current_wr_state==state_wr_data) && wready)
		count_wr16<=count_wr16+1;
	else if ((current_wr_state==state_wr_data) && !wready)
		count_wr16<=count_wr16;
	else
		count_wr16<=0;
end

always @(posedge clk) begin
	if(!rst)
	begin
		current_wr_state <= state_wr_free;
	end
	else
	begin
		current_wr_state <= next_wr_state;
	end
end

/*FSM_W*/
always @(*) begin
	case(current_wr_state)
		state_wr_free,state_wr_finish:
		begin
			if (MEM_dcache_wr_req)
			begin
				next_wr_state = state_wr_req;
			end
			else
				next_wr_state = current_wr_state;
		end
		state_wr_req:
		begin
			if(awvalid&awready)
				next_wr_state=state_wr_data;
			else
				next_wr_state = current_wr_state;
		end
		state_wr_data:
		begin
			if(wvalid & wready & (count_wr16==4'hf|(conf_wr)))
				next_wr_state=state_wr_res;
			else
				next_wr_state = current_wr_state;
		end
		state_wr_res:
		begin
			if(bvalid&bready)
				next_wr_state=state_wr_finish;
			else
				next_wr_state = current_wr_state;
		end
		default:
			next_wr_state = state_wr_free;
	endcase
end

//Read Passway
// 设置读id
// assign arid = MEM_dcache_rd_req ? 1:
// 			 IF_icache_rd_req  ? 0 : 0;




always @(posedge clk) begin
	if(!rst)
	begin
		current_rd_state <= state_rd_free;
	end
	else
	begin
		current_rd_state <= next_rd_state;
	end
end

/*FSM_R*/
always @(*) begin
	case(current_rd_state)
        state_rd_free:
		begin
			if ((IF_icache_rd_req) & (~is_writing | (araddr[31:6] != writing_addr[31:6])))
			begin
				next_rd_state = state_if_send;
			end
			else if ((MEM_dcache_rd_req) & (~is_writing | (araddr != writing_addr)))
				next_rd_state = state_mem_send;
			else
				next_rd_state = state_rd_free;

		end
        state_if_send:
		begin
			if(arready)
			begin
                next_rd_state=state_if_wait;
			end
			else
				next_rd_state = state_if_send;
		end
		state_if_wait:
		begin
			if(rlast& rvalid & (~rid[0]))
			begin
                if((MEM_dcache_rd_req) & (~is_writing | (araddr != writing_addr)))
                    next_rd_state=state_mem_send;
				else
					next_rd_state=state_rd_free;
			end
			else
				next_rd_state = state_if_wait;
		end
		state_mem_send:
		begin
			if(arready)
			begin
                next_rd_state=state_mem_wait;
			end
			else
				next_rd_state = state_mem_send;
		end
		state_mem_wait:
		begin
			if(rlast & rvalid & (rid[0]))
			begin
                if((IF_icache_rd_req) & (~is_writing | (araddr != writing_addr)))
                    next_rd_state=state_if_send;
				else
					next_rd_state=state_rd_free;
			end
			else
				next_rd_state = state_mem_wait;
		end
        default:
        begin
            next_rd_state = state_rd_free;
        end

	endcase
end
//
assign MEM_dcache_rd_rdy =(~is_writing)&(~IF_icache_rd_req)& arready & (current_rd_state==state_rd_free );
assign MEM_dcache_ret_valid = (rvalid & rid[0]);
assign MEM_dcache_ret_last = (rlast & rid[0]);

assign MEM_dcache_ret_data = rdata;
assign MEM_dcache_wr_rdy = (~is_writing)&awready&(current_wr_state==state_wr_free || current_wr_state==state_wr_finish );
assign IF_icache_rd_rdy = (~is_writing)&arready&(current_rd_state==state_rd_free );
assign IF_icache_ret_valid = rvalid& (~rid[0]);
assign IF_icache_ret_last = rlast & (~rid[0]);
assign IF_icache_ret_data = rdata;
assign IF_icache_wr_rdy=1;
// 0 -> instr   1 -> data
assign arid =   (current_rd_state==state_if_send)  ? 0:1;

assign arsize = (current_rd_state==state_if_send) 
				   			? IF_icache_rd_type : MEM_dcache_rd_type;
assign araddr = (current_rd_state==state_if_send) 
							? IF_icache_rd_addr : MEM_dcache_rd_addr;
assign arlen =  (current_rd_state==state_if_send) 
							?   icache_sel ? 4'b0:4'b1111 :
                                dcache_sel ? 4'b0:4'b1111;
assign arburst = (current_rd_state==state_if_send) 
							?   icache_sel ? 2'b0:2'b01 :
                                dcache_sel ? 2'b0:2'b01;

assign arvalid = (current_rd_state==state_if_send) ||
				(current_rd_state==state_mem_send);


assign awaddr =writing_addr;
assign awsize = MEM_dcache_wr_type_buf;
assign awlen = conf_wr ? 4'b0:4'b1111;
assign awvalid =   (conf_wr|dram_wr)& (current_wr_state==state_wr_req );
assign awburst = conf_wr ? 2'b0 : 2'b1;

assign wdata = conf_wr ? uncache_wr_data_reg: dram_wr ? temp_data[31:0] : 0;
assign wstrb = MEM_dcache_wr_wstrb_buf; //可能有问�??
assign wvalid =   (conf_wr|dram_wr)& (current_wr_state==state_wr_data );
assign wlast = conf_wr ? 1: dram_wr ? count_wr16==4'hf : 0;
assign bready = 1;

endmodule
