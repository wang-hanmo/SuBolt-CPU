// 0 -> instr uncacache
// 1 -> instr cacache
// 2 -> data  uncacache
// 3 -> data  cacache
module new_bridge(
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
	input dcache_sel;
	input icache_sel;
// 中断信号
    input [5:0] ext_int_in      ;  //interrupt,high active;


// 时钟与复位信�?
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

	input IF_uncache_rd_req;
	input [2:0]IF_uncache_rd_type;
	input [31:0] IF_uncache_rd_addr;
	output  IF_uncache_rd_rdy;
	output  IF_uncache_ret_valid;
	output IF_uncache_ret_last;
	output [31:0] IF_uncache_ret_data;
	input IF_uncache_wr_req;
	input [2:0] IF_uncache_wr_type;
	input [31:0] IF_uncache_wr_addr;
	input [3:0] IF_uncache_wr_wstrb;
	input [31:0] IF_uncache_wr_data;
	output IF_uncache_wr_rdy;
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

	input MEM_uncache_rd_req;
	input [2:0]MEM_uncache_rd_type;
	input [31:0] MEM_uncache_rd_addr;
	output  MEM_uncache_rd_rdy;
	output  MEM_uncache_ret_valid;
	output MEM_uncache_ret_last;
	output [31:0] MEM_uncache_ret_data;
	input MEM_uncache_wr_req;
	input [2:0] MEM_uncache_wr_type;
	input [31:0] MEM_uncache_wr_addr;
	input [3:0] MEM_uncache_wr_wstrb;
	input [31:0] MEM_uncache_wr_data;
	output MEM_uncache_wr_rdy;

parameter state_free    = 4'd0;
parameter state_rd_req  = 4'd1;
parameter state_rd_res  = 4'd2;
parameter state_wr_req  = 4'd3;
parameter state_wr_data = 4'd4;
parameter state_wr_res  = 4'd5;
parameter state_number  = 4;

output reg [state_number-1:0] state_i_uncache_0;
output reg [state_number-1:0] state_i_cache_1  ;
output reg [state_number-1:0] state_d_uncache_2;
output reg [state_number-1:0] state_d_cache_3  ;

reg [state_number-1:0] next_state_i_uncache_0;
reg [state_number-1:0] next_state_i_cache_1  ;
reg [state_number-1:0] next_state_d_uncache_2;
reg [state_number-1:0] next_state_d_cache_3  ;

reg [3:0] count_wr16_i;
reg [3:0] count_wr16_d;
reg dcache_sel_buf;
always@(posedge clk) begin
    if(MEM_uncache_wr_req||MEM_dcache_wr_req)
        dcache_sel_buf <= dcache_sel;
end

reg [31:0] MEM_uncache_wr_addr_buf;
reg [31:0] MEM_dcache_wr_addr_buf;
reg [31:0] MEM_uncache_wr_data_buf;
reg [511:0] tempdata;
reg [3:0] MEM_dcache_wr_wstrb_buf;
reg [3:0] MEM_uncache_wr_wstrb_buf;
reg [2:0] MEM_dcache_wr_type_buf;
reg [2:0] MEM_uncache_wr_type_buf;
always @(posedge clk) begin
    if(!rst)
    begin
        MEM_uncache_wr_addr_buf <= 0;
        MEM_uncache_wr_data_buf <= 0;
        MEM_uncache_wr_wstrb_buf<= 0;
        MEM_uncache_wr_type_buf <= 0;
    end
	else if(state_d_uncache_2==state_free && MEM_uncache_wr_req)
	begin
        MEM_uncache_wr_addr_buf <= MEM_uncache_wr_addr;
        MEM_uncache_wr_data_buf <= MEM_uncache_wr_data;
        MEM_uncache_wr_wstrb_buf<= MEM_uncache_wr_wstrb;
        MEM_uncache_wr_type_buf <= MEM_uncache_wr_type;
	end

end
always @(posedge clk) begin
	if(!rst)
	begin
		tempdata<=0;
        MEM_dcache_wr_addr_buf <= 0;
        MEM_dcache_wr_wstrb_buf<= 0;
        MEM_dcache_wr_type_buf <= 0;

	end
	else if(state_d_cache_3==state_free && MEM_dcache_wr_req)
	begin
		tempdata<=MEM_dcache_wr_data;
        MEM_dcache_wr_addr_buf<=MEM_dcache_wr_addr;
        MEM_dcache_wr_wstrb_buf<= MEM_dcache_wr_wstrb;
        MEM_dcache_wr_type_buf <= MEM_dcache_wr_type;
	end
	else if((state_d_cache_3==state_wr_data)&&wready)
	begin
		tempdata<={32'b0,{tempdata[511:32]}};//�?要与 wdata 保持�?�?
	end
end

always @(posedge clk) begin
    if(next_state_i_cache_1==state_wr_data && wready_1)
        count_wr16_i <= count_wr16_i+1;
    else if(next_state_i_cache_1==state_wr_data && ~wready_1)
        count_wr16_i <= count_wr16_i;
    else
        count_wr16_i <= 0;

end
always @(posedge clk) begin
    if(next_state_d_cache_3==state_wr_data && wready_3)
        count_wr16_d <= count_wr16_d+1;
    else if(next_state_d_cache_3==state_wr_data && ~wready_3)
        count_wr16_d <= count_wr16_d;
    else
        count_wr16_d <= 0;
end

wire [15 : 0] s_axi_awid;
wire [127 : 0] s_axi_awaddr;
wire [15 : 0] s_axi_awlen;
wire [11 : 0] s_axi_awsize;
wire [7 : 0] s_axi_awburst;
wire [7 : 0] s_axi_awlock;
wire [15 : 0] s_axi_awcache;
wire [11 : 0] s_axi_awprot;
wire [15 : 0] s_axi_awqos;
wire [3 : 0] s_axi_awvalid;
wire [3 : 0] s_axi_awready;
wire [15 : 0] s_axi_wid;
wire [127 : 0] s_axi_wdata;
wire [15 : 0] s_axi_wstrb;
wire [3 : 0] s_axi_wlast;
wire [3 : 0] s_axi_wvalid;
wire [3 : 0] s_axi_wready;
wire [15 : 0] s_axi_bid;
wire [7 : 0] s_axi_bresp;
wire [3 : 0] s_axi_bvalid;
wire [3 : 0] s_axi_bready;
wire [15 : 0] s_axi_arid;
wire [127 : 0] s_axi_araddr;
wire [15 : 0] s_axi_arlen;
wire [11 : 0] s_axi_arsize;
wire [7 : 0] s_axi_arburst;
wire [7 : 0] s_axi_arlock;
wire [15 : 0] s_axi_arcache;
wire [11 : 0] s_axi_arprot;
wire [15 : 0] s_axi_arqos;
wire [3 : 0] s_axi_arvalid;
wire [3 : 0] s_axi_arready;
wire [15 : 0] s_axi_rid;
wire [127 : 0] s_axi_rdata;
wire [7 : 0] s_axi_rresp;
wire [3 : 0] s_axi_rlast;
wire [3 : 0] s_axi_rvalid;
wire [3 : 0] s_axi_rready;
wire [3 : 0] m_axi_awid;
wire [31 : 0] m_axi_awaddr;
wire [3 : 0] m_axi_awlen;
wire [2 : 0] m_axi_awsize;
wire [1 : 0] m_axi_awburst;
wire [1 : 0] m_axi_awlock;
wire [3 : 0] m_axi_awcache;
wire [2 : 0] m_axi_awprot;
wire [3 : 0] m_axi_awqos;
wire [0 : 0] m_axi_awvalid;
wire [0 : 0] m_axi_awready;
wire [3 : 0] m_axi_wid;
wire [31 : 0] m_axi_wdata;
wire [3 : 0] m_axi_wstrb;
wire [0 : 0] m_axi_wlast;
wire [0 : 0] m_axi_wvalid;
wire [0 : 0] m_axi_wready;
wire [3 : 0] m_axi_bid;
wire [1 : 0] m_axi_bresp;
wire [0 : 0] m_axi_bvalid;
wire [0 : 0] m_axi_bready;
wire [3 : 0] m_axi_arid;
wire [31 : 0] m_axi_araddr;
wire [3 : 0] m_axi_arlen;
wire [2 : 0] m_axi_arsize;
wire [1 : 0] m_axi_arburst;
wire [1 : 0] m_axi_arlock;
wire [3 : 0] m_axi_arcache;
wire [2 : 0] m_axi_arprot;
wire [3 : 0] m_axi_arqos;
wire [0 : 0] m_axi_arvalid;
wire [0 : 0] m_axi_arready;
wire [3 : 0] m_axi_rid;
wire [31 : 0] m_axi_rdata;
wire [1 : 0] m_axi_rresp;
wire [0 : 0] m_axi_rlast;
wire [0 : 0] m_axi_rvalid;
wire [0 : 0] m_axi_rready;
wire [ 3:0]   arid_0      ;
wire [31:0]   araddr_0    ;
wire [ 3:0]   arlen_0     ;
wire [ 2:0]   arsize_0    ;
wire [ 1:0]   arburst_0   ;
wire [ 1:0]   arlock_0    ;
wire [ 3:0]   arcache_0   ;
wire [ 2:0]   arprot_0    ;
wire          arvalid_0   ;
wire          arready_0   ;
wire [3:0]    arqos_0     ;

wire [ 3:0]   rid_0       ;
wire [31:0]   rdata_0     ;
wire [ 1:0]   rresp_0     ;
wire          rlast_0     ;
wire          rvalid_0    ;
wire          rready_0    ;

wire [ 3:0]   awid_0      ;
wire [31:0]   awaddr_0    ;
wire [ 3:0]   awlen_0     ;
wire [ 2:0]   awsize_0    ;
wire [ 1:0]   awburst_0   ;
wire [ 1:0]   awlock_0    ;
wire [ 3:0]   awcache_0   ;
wire [ 2:0]   awprot_0    ;
wire          awvalid_0   ;
wire          awready_0   ;
wire [ 3:0]   awqos_0     ;

wire [ 3:0]   wid_0       ;
wire [31:0]   wdata_0     ;
wire [ 3:0]   wstrb_0     ;
wire          wlast_0     ;
wire          wvalid_0    ;
wire          wready_0    ;

wire [3:0]    bid_0       ;
wire [1:0]    bresp_0     ;
wire          bvalid_0    ;
wire          bready_0    ;

// ----------------------
wire [ 3:0]   arid_1      ;
wire [31:0]   araddr_1    ;
wire [ 3:0]   arlen_1     ;
wire [ 2:0]   arsize_1    ;
wire [ 1:0]   arburst_1   ;
wire [ 1:0]   arlock_1    ;
wire [ 3:0]   arcache_1   ;
wire [ 2:0]   arprot_1    ;
wire          arvalid_1   ;
wire          arready_1   ;
wire [3:0]    arqos_1     ;

wire [ 3:0]   rid_1       ;
wire [31:0]   rdata_1     ;
wire [ 1:0]   rresp_1     ;
wire          rlast_1     ;
wire          rvalid_1    ;
wire          rready_1    ;

wire [ 3:0]   awid_1      ;
wire [31:0]   awaddr_1    ;
wire [ 3:0]   awlen_1     ;
wire [ 2:0]   awsize_1    ;
wire [ 1:0]   awburst_1   ;
wire [ 1:0]   awlock_1    ;
wire [ 3:0]   awcache_1   ;
wire [ 2:0]   awprot_1    ;
wire          awvalid_1   ;
wire          awready_1   ;
wire [ 3:0]   awqos_1     ;

wire [ 3:0]   wid_1       ;
wire [31:0]   wdata_1     ;
wire [ 3:0]   wstrb_1     ;
wire          wlast_1     ;
wire          wvalid_1    ;
wire          wready_1    ;

wire [3:0]    bid_1       ;
wire [1:0]    bresp_1     ;
wire          bvalid_1    ;
wire          bready_1    ;
// -----------------------
wire [ 3:0]   arid_2      ;
wire [31:0]   araddr_2    ;
wire [ 3:0]   arlen_2     ;
wire [ 2:0]   arsize_2    ;
wire [ 1:0]   arburst_2   ;
wire [ 1:0]   arlock_2    ;
wire [ 3:0]   arcache_2   ;
wire [ 2:0]   arprot_2    ;
wire          arvalid_2   ;
wire          arready_2   ;
wire [3:0]    arqos_2     ;

wire [ 3:0]   rid_2       ;
wire [31:0]   rdata_2     ;
wire [ 1:0]   rresp_2     ;
wire          rlast_2     ;
wire          rvalid_2    ;
wire          rready_2    ;

wire [ 3:0]   awid_2      ;
wire [31:0]   awaddr_2    ;
wire [ 3:0]   awlen_2     ;
wire [ 2:0]   awsize_2    ;
wire [ 1:0]   awburst_2   ;
wire [ 1:0]   awlock_2    ;
wire [ 3:0]   awcache_2   ;
wire [ 2:0]   awprot_2    ;
wire          awvalid_2   ;
wire          awready_2   ;
wire [ 3:0]   awqos_2     ;

wire [ 3:0]   wid_2       ;
wire [31:0]   wdata_2     ;
wire [ 3:0]   wstrb_2     ;
wire          wlast_2     ;
wire          wvalid_2    ;
wire          wready_2    ;

wire [3:0]    bid_2       ;
wire [1:0]    bresp_2     ;
wire          bvalid_2    ;
wire          bready_2    ;

// --------------
wire [ 3:0]   arid_3      ;
wire [31:0]   araddr_3    ;
wire [ 3:0]   arlen_3     ;
wire [ 2:0]   arsize_3    ;
wire [ 1:0]   arburst_3   ;
wire [ 1:0]   arlock_3    ;
wire [ 3:0]   arcache_3   ;
wire [ 2:0]   arprot_3    ;
wire          arvalid_3   ;
wire          arready_3   ;
wire [3:0]    arqos_3     ;

wire [ 3:0]   rid_3       ;
wire [31:0]   rdata_3     ;
wire [ 1:0]   rresp_3     ;
wire          rlast_3     ;
wire          rvalid_3    ;
wire          rready_3    ;

wire [ 3:0]   awid_3      ;
wire [31:0]   awaddr_3    ;
wire [ 3:0]   awlen_3     ;
wire [ 2:0]   awsize_3    ;
wire [ 1:0]   awburst_3   ;
wire [ 1:0]   awlock_3    ;
wire [ 3:0]   awcache_3   ;
wire [ 2:0]   awprot_3    ;
wire          awvalid_3   ;
wire          awready_3   ;
wire [ 3:0]   awqos_3     ;
wire [ 3:0]   wid_3       ;
wire [31:0]   wdata_3     ;
wire [ 3:0]   wstrb_3     ;
wire          wlast_3     ;
wire          wvalid_3    ;
wire          wready_3    ;

wire [3:0]    bid_3       ;
wire [1:0]    bresp_3     ;
wire          bvalid_3    ;
wire          bready_3    ;

always@(posedge clk)begin
    if(!rst)
    begin
        state_i_uncache_0 <= state_free;
        state_i_cache_1   <= state_free;
        state_d_uncache_2 <= state_free;
        state_d_cache_3   <= state_free;

    end
    else
    begin
        state_i_uncache_0 <= next_state_i_uncache_0;
        state_i_cache_1   <= next_state_i_cache_1;
        state_d_uncache_2 <= next_state_d_uncache_2;
        state_d_cache_3   <= next_state_d_cache_3;
    end
end

always@(*)
begin
    case(state_i_uncache_0)
        state_free:
        begin
            if(IF_uncache_rd_req & icache_sel)
                next_state_i_uncache_0 = state_rd_req;
            else if(IF_uncache_wr_req & icache_sel)
                next_state_i_uncache_0 = state_wr_req;
            else
                next_state_i_uncache_0 = state_free;
        end
        state_rd_req:
        begin
            if(arvalid_0 & arready_0)
                next_state_i_uncache_0 = state_rd_res;
            else
                next_state_i_uncache_0 = state_rd_req;
        end
        state_rd_res:
        begin
            if(rvalid_0 & rready_0 & rlast_0)
                next_state_i_uncache_0 = state_free;
            else
                next_state_i_uncache_0 = state_rd_res;
        end
        state_wr_req:
        begin
            if(awvalid_0 & awready_0)
                next_state_i_uncache_0 = state_wr_data;
            else
                next_state_i_uncache_0 = state_wr_req;
        end
        state_wr_data:
        begin
            if(wvalid_0 & wready_0 & wlast_0 )
                next_state_i_uncache_0 = state_wr_res;
            else
                next_state_i_uncache_0 = state_wr_data;
        end
        state_wr_res:
        begin
            if(bvalid_0 & bready_0)
                next_state_i_uncache_0 = state_free;
            else
                next_state_i_uncache_0 = state_wr_res;
        end
        default:
            next_state_i_uncache_0 = state_free;
    endcase
end

always@(*)
begin
    case(state_i_cache_1)
        state_free:
        begin
            if(IF_icache_rd_req & ~icache_sel)
                next_state_i_cache_1 = state_rd_req;
            else if(IF_icache_wr_req & ~icache_sel)
                next_state_i_cache_1 = state_wr_req;
            else
                next_state_i_cache_1 = state_free;
        end
        state_rd_req:
        begin
            if(arvalid_1 & arready_1)
                next_state_i_cache_1 = state_rd_res;
            else
                next_state_i_cache_1 = state_rd_req;
        end
        state_rd_res:
        begin
            if(rvalid_1 & rready_1 & rlast_1)
                next_state_i_cache_1 = state_free;
            else
                next_state_i_cache_1 = state_rd_res;
        end
        state_wr_req:
        begin
            if(awvalid_1 & awready_1)
                next_state_i_cache_1 = state_wr_data;
            else
                next_state_i_cache_1 = state_wr_req;
        end
        state_wr_data:
        begin
            if(wvalid_1 & wready_1 & wlast_1 )
                next_state_i_cache_1 = state_wr_res;
            else
                next_state_i_cache_1 = state_wr_data;
        end
        state_wr_res:
        begin
            if(bvalid_1 & bready_1)
                next_state_i_cache_1 = state_free;
            else
                next_state_i_cache_1 = state_wr_res;
        end
        default:
            next_state_i_cache_1 = state_free;
    endcase
end

always@(*)
begin
    case(state_d_uncache_2)
        state_free:
        begin
            if(MEM_uncache_rd_req & dcache_sel)
                next_state_d_uncache_2 = state_rd_req;
            else if(MEM_uncache_wr_req & dcache_sel)
                next_state_d_uncache_2 = state_wr_req;
            else
                next_state_d_uncache_2 = state_free;
        end
        state_rd_req:
        begin
            if(arvalid_2 & arready_2)
                next_state_d_uncache_2 = state_rd_res;
            else
                next_state_d_uncache_2 = state_rd_req;
        end
        state_rd_res:
        begin
            if(rvalid_2 & rready_2 & rlast_2)
                next_state_d_uncache_2 = state_free;
            else
                next_state_d_uncache_2 = state_rd_res;
        end
        state_wr_req:
        begin
            if(awvalid_2 & awready_2)
                next_state_d_uncache_2 = state_wr_data;
            else
                next_state_d_uncache_2 = state_wr_req;
        end
        state_wr_data:
        begin
            if(wvalid_2 & wready_2 & wlast_2 )
                next_state_d_uncache_2 = state_wr_res;
            else
                next_state_d_uncache_2 = state_wr_data;
        end
        state_wr_res:
        begin
            if(bvalid_2 & bready_2)
                next_state_d_uncache_2 = state_free;
            else
                next_state_d_uncache_2 = state_wr_res;
        end
        default:
            next_state_d_uncache_2 = state_free;
    endcase
end

always@(*)
begin
    case(state_d_cache_3)
        state_free:
        begin
            if(MEM_dcache_rd_req & ~dcache_sel)
                next_state_d_cache_3 = state_rd_req;
            else if(MEM_dcache_wr_req & ~dcache_sel)
                next_state_d_cache_3 = state_wr_req;
            else
                next_state_d_cache_3 = state_free;
        end
        state_rd_req:
        begin
            if(arvalid_3 & arready_3)
                next_state_d_cache_3 = state_rd_res;
            else
                next_state_d_cache_3 = state_rd_req;
        end
        state_rd_res:
        begin
            if(rvalid_3 & rready_3 & rlast_3)
                next_state_d_cache_3 = state_free;
            else
                next_state_d_cache_3 = state_rd_res;
        end
        state_wr_req:
        begin
            if(awvalid_3 & awready_3)
                next_state_d_cache_3 = state_wr_data;
            else
                next_state_d_cache_3 = state_wr_req;
        end
        state_wr_data:
        begin
            if(wvalid_3 & wready_3 & wlast_3 )
                next_state_d_cache_3 = state_wr_res;
            else
                next_state_d_cache_3 = state_wr_data;
        end
        state_wr_res:
        begin
            if(bvalid_3 & bready_3)
                next_state_d_cache_3 = state_free;
            else
                next_state_d_cache_3 = state_wr_res;
        end
        default:
            next_state_d_cache_3 = state_free;
    endcase
end

assign  arid_0    = 4'b0 ;
assign  araddr_0  = IF_uncache_rd_addr ;
assign  arlen_0   = 4'b0  ;
assign  arsize_0  = IF_uncache_rd_type ;
assign  arburst_0 = 2'b1 ;
assign  arlock_0  = 2'b0 ;
assign  arcache_0 = 4'b0 ;
assign  arprot_0  = 3'b0 ;
assign  arvalid_0 = state_i_uncache_0==state_rd_req ;
assign  arready_0 = s_axi_arready[0] ;
assign  arqos_0   = 4'b0;

assign  rid_0     = s_axi_rid[3:0] ;
assign  rdata_0   = s_axi_rdata[31:0] ;
assign  rresp_0   = s_axi_rresp[1:0] ;
assign  rlast_0   = s_axi_rlast[0] ;
assign  rvalid_0  = s_axi_rvalid[0] && (rid_0 == 4'b0) ;
assign  rready_0  = 1'b1 ;

assign  awid_0    = 4'b0 ;
assign  awaddr_0  = IF_uncache_wr_addr ;
assign  awlen_0   = 4'b0 ;
assign  awsize_0  = IF_uncache_wr_type ;
assign  awburst_0 = 2'b1 ;
assign  awlock_0  = 2'b0 ;
assign  awcache_0 = 4'b0 ;
assign  awprot_0  = 3'b0 ;
assign  awvalid_0 = state_i_uncache_0==state_wr_req ;
assign  awready_0 = s_axi_awready[0] ;
assign  awqos_0   = 4'b0 ;

assign  wid_0     = 4'b0 ;
assign  wdata_0   = tempdata[31:0] ;
assign  wstrb_0   = IF_uncache_wr_wstrb ;
assign  wlast_0   = 1 ;
assign  wvalid_0  = state_i_uncache_0==state_wr_data;
assign  wready_0  = s_axi_wready[0] ;

assign  bid_0     = s_axi_bid[3:0] ;
assign  bresp_0   = s_axi_bresp[1:0] ;
assign  bvalid_0  = s_axi_bvalid[0] &&(bid_0==4'b0) ;
assign  bready_0  = 1'b1;

assign  arid_1    = 4'b1 ;
assign  araddr_1  = IF_icache_rd_addr ;
assign  arlen_1   = 4'b1111  ;
assign  arsize_1  = IF_icache_rd_type ;
assign  arburst_1 = 2'b1 ;
assign  arlock_1  = 2'b0 ;
assign  arcache_1 = 4'b0 ;
assign  arprot_1  = 3'b0 ;
assign  arvalid_1 = state_i_cache_1==state_rd_req ;
assign  arready_1 = s_axi_arready[1] ;
assign  arqos_1   = 4'b0;

assign  rid_1     = s_axi_rid[7:4] ;
assign  rdata_1   = s_axi_rdata[63:32] ;
assign  rresp_1   = s_axi_rresp[3:2] ;
assign  rlast_1   = s_axi_rlast[1] ;
assign  rvalid_1  = s_axi_rvalid[1] && (rid_1 == 4'b1) ;
assign  rready_1  = 1'b1 ;

assign  awid_1    = 4'b1 ;
assign  awaddr_1  = IF_icache_wr_addr ;
assign  awlen_1   = 4'b1111 ;
assign  awsize_1  = IF_icache_wr_type ;
assign  awburst_1 = 2'b1 ;
assign  awlock_1  = 2'b0 ;
assign  awcache_1 = 4'b0 ;
assign  awprot_1  = 3'b0 ;
assign  awvalid_1 = state_i_cache_1==state_wr_req ;
assign  awready_1 = s_axi_awready[1] ;
assign  awqos_1   = 4'b0 ;

assign  wid_1     = 4'b1 ;
assign  wdata_1   = tempdata[31:0] ;
assign  wstrb_1   = IF_icache_wr_wstrb ;
assign  wlast_1   = count_wr16_i==4'hf ;
assign  wvalid_1  = state_i_cache_1==state_wr_data;
assign  wready_1  = s_axi_wready[1] ;

assign  bid_1     = s_axi_bid[7:4] ;
assign  bresp_1   = s_axi_bresp[3:2] ;
assign  bvalid_1  = s_axi_bvalid[1] &&(bid_1==4'b1) ;
assign  bready_1  = 1'b1;

assign  arid_2    = 4'b10 ;
assign  araddr_2  = MEM_uncache_rd_addr ;
assign  arlen_2   = 4'b0  ;
assign  arsize_2  = MEM_uncache_rd_type ;
assign  arburst_2 = 2'b1 ;
assign  arlock_2  = 2'b0 ;
assign  arcache_2 = 4'b0 ;
assign  arprot_2  = 3'b0 ;
assign  arvalid_2 = state_d_uncache_2==state_rd_req ;
assign  arready_2 = s_axi_arready[2] ;
assign  arqos_2   = 4'b0;

assign  rid_2     = s_axi_rid[11:8] ;
assign  rdata_2   = s_axi_rdata[95:64] ;
assign  rresp_2   = s_axi_rresp[5:4] ;
assign  rlast_2   = s_axi_rlast[2] ;
assign  rvalid_2  = s_axi_rvalid[2] && (rid_2 == 4'b10) ;
assign  rready_2  = 1'b1 ;

assign  awid_2    = 4'b10 ;
assign  awaddr_2  = MEM_uncache_wr_addr_buf ;
assign  awlen_2   = 4'b0 ;
assign  awsize_2  = MEM_uncache_wr_type_buf ;
assign  awburst_2 = 2'b1 ;
assign  awlock_2  = 2'b0 ;
assign  awcache_2 = 4'b0 ;
assign  awprot_2  = 3'b0 ;
assign  awvalid_2 = state_d_uncache_2==state_wr_req ;
assign  awready_2 = s_axi_awready[2] ;
assign  awqos_2   = 4'b0 ;

assign  wid_2     = 4'b10 ;
assign  wdata_2   = MEM_uncache_wr_data_buf ;
assign  wstrb_2   = MEM_uncache_wr_wstrb_buf ;
assign  wlast_2   = 1 ;
assign  wvalid_2  = state_d_uncache_2==state_wr_data;
assign  wready_2  = s_axi_wready[2] ;

assign  bid_2     = s_axi_bid[7:4] ;
assign  bresp_2   = s_axi_bresp[3:2] ;
assign  bvalid_2  = s_axi_bvalid[2] &&(bid_2==4'b10) ;
assign  bready_2  = 1'b1;

assign  arid_3    = 4'b11 ;
assign  araddr_3  = MEM_dcache_rd_addr ;
assign  arlen_3   = 4'b1111  ;
assign  arsize_3  = MEM_dcache_rd_type ;
assign  arburst_3 = 2'b1 ;
assign  arlock_3  = 2'b0 ;
assign  arcache_3 = 4'b0 ;
assign  arprot_3  = 3'b0 ;
assign  arvalid_3 = state_d_cache_3==state_rd_req ;
assign  arready_3 = s_axi_arready[3] ;
assign  arqos_3   = 4'b0;

assign  rid_3     = s_axi_rid[15:12] ;
assign  rdata_3   = s_axi_rdata[127:96] ;
assign  rresp_3   = s_axi_rresp[7:6] ;
assign  rlast_3   = s_axi_rlast[3] ;
assign  rvalid_3  = s_axi_rvalid[3] && (rid_3 == 4'b11) ;
assign  rready_3  = 1'b1 ;

assign  awid_3    = 4'b11 ;
assign  awaddr_3  = MEM_dcache_wr_addr_buf ;
assign  awlen_3   = 4'b1111 ;
assign  awsize_3  = MEM_dcache_wr_type_buf ;
assign  awburst_3 = 2'b1 ;
assign  awlock_3  = 2'b0 ;
assign  awcache_3 = 4'b0 ;
assign  awprot_3  = 3'b0 ;
assign  awvalid_3 = state_d_cache_3==state_wr_req ;
assign  awready_3 = s_axi_awready[3] ;
assign  awqos_3   = 4'b0 ;

assign  wid_3     = 4'b11 ;
assign  wdata_3   = tempdata[31:0] ;
assign  wstrb_3   = MEM_dcache_wr_wstrb_buf ;
assign  wlast_3   = count_wr16_d==4'hf ;
assign  wvalid_3  = state_d_cache_3==state_wr_data;
assign  wready_3  = s_axi_wready[3] ;

assign  bid_3     = s_axi_bid[15:12] ;
assign  bresp_3   = s_axi_bresp[7:6] ;
assign  bvalid_3  = s_axi_bvalid[3] &&(bid_3==4'b11) ;
assign  bready_3  = 1'b1;



assign s_axi_awid={awid_3,awid_2,awid_1,awid_0};
assign s_axi_awaddr={awaddr_3,awaddr_2,awaddr_1,awaddr_0};
assign s_axi_awlen={awlen_3,awlen_2,awlen_1,awlen_0};
assign s_axi_awsize={awsize_3,awsize_2,awsize_1,awsize_0};
assign s_axi_awburst={awburst_3,awburst_2,awburst_1,awburst_0};
assign s_axi_awlock={awlock_3,awlock_2,awlock_1,awlock_0};
assign s_axi_awcache={awcache_3,awcache_2,awcache_1,awcache_0};
assign s_axi_awprot={awprot_3,awprot_2,awprot_1,awprot_0};
assign s_axi_awqos={awqos_3,awqos_2,awqos_1,awqos_0};
assign s_axi_awvalid={awvalid_3,awvalid_2,awvalid_1,awvalid_0};
assign s_axi_wid={wid_3,wid_2,wid_1,wid_0};
assign s_axi_wdata={wdata_3,wdata_2,wdata_1,wdata_0};
assign s_axi_wstrb={wstrb_3,wstrb_2,wstrb_1,wstrb_0};
assign s_axi_wlast={wlast_3,wlast_2,wlast_1,wlast_0};
assign s_axi_wvalid={wvalid_3,wvalid_2,wvalid_1,wvalid_0};
assign s_axi_bready={bready_3,bready_2,bready_1,bready_0};
assign s_axi_araddr={araddr_3,araddr_2,araddr_1,araddr_0};
assign s_axi_arid={arid_3,arid_2,arid_1,arid_0};
assign s_axi_arlen={arlen_3,arlen_2,arlen_1,arlen_0};
assign s_axi_arsize={arsize_3,arsize_2,arsize_1,arsize_0};
assign s_axi_arburst={arburst_3,arburst_2,arburst_1,arburst_0};
assign s_axi_arlock={arlock_3,arlock_2,arlock_1,arlock_0};
assign s_axi_arcache={arcache_3,arcache_2,arcache_1,arcache_0};
assign s_axi_arprot={arprot_3,arprot_2,arprot_1,arprot_0};
assign s_axi_arqos={arqos_3,arqos_2,arqos_1,arqos_0};
assign s_axi_arvalid={arvalid_3,arvalid_2,arvalid_1,arvalid_0};
assign s_axi_rready={rready_3,rready_2,rready_1,rready_0};

cache_axi_bridge axi_cross_1_4 (
  .aclk(clk),                     // input wire aclk
  .aresetn(rst),                  // input wire aresetn
  .s_axi_awid(s_axi_awid),        // input wire [15 : 0] s_axi_awid
  .s_axi_awaddr(s_axi_awaddr),    // input wire [127 : 0] s_axi_awaddr
  .s_axi_awlen(s_axi_awlen),      // input wire [15 : 0] s_axi_awlen
  .s_axi_awsize(s_axi_awsize),    // input wire [11 : 0] s_axi_awsize
  .s_axi_awburst(s_axi_awburst),  // input wire [7 : 0] s_axi_awburst
  .s_axi_awlock(s_axi_awlock),    // input wire [7 : 0] s_axi_awlock
  .s_axi_awcache(s_axi_awcache),  // input wire [15 : 0] s_axi_awcache
  .s_axi_awprot(s_axi_awprot),    // input wire [11 : 0] s_axi_awprot
  .s_axi_awqos(s_axi_awqos),      // input wire [15 : 0] s_axi_awqos
  .s_axi_awvalid(s_axi_awvalid),  // input wire [3 : 0] s_axi_awvalid
  .s_axi_awready(s_axi_awready),  // output wire [3 : 0] s_axi_awready
  .s_axi_wid(s_axi_wid),          // input wire [15 : 0] s_axi_wid
  .s_axi_wdata(s_axi_wdata),      // input wire [127 : 0] s_axi_wdata
  .s_axi_wstrb(s_axi_wstrb),      // input wire [15 : 0] s_axi_wstrb
  .s_axi_wlast(s_axi_wlast),      // input wire [3 : 0] s_axi_wlast
  .s_axi_wvalid(s_axi_wvalid),    // input wire [3 : 0] s_axi_wvalid
  .s_axi_wready(s_axi_wready),    // output wire [3 : 0] s_axi_wready
  .s_axi_bid(s_axi_bid),          // output wire [15 : 0] s_axi_bid
  .s_axi_bresp(s_axi_bresp),      // output wire [7 : 0] s_axi_bresp
  .s_axi_bvalid(s_axi_bvalid),    // output wire [3 : 0] s_axi_bvalid
  .s_axi_bready(s_axi_bready),    // input wire [3 : 0] s_axi_bready
  .s_axi_arid(s_axi_arid),        // input wire [15 : 0] s_axi_arid
  .s_axi_araddr(s_axi_araddr),    // input wire [127 : 0] s_axi_araddr
  .s_axi_arlen(s_axi_arlen),      // input wire [15 : 0] s_axi_arlen
  .s_axi_arsize(s_axi_arsize),    // input wire [11 : 0] s_axi_arsize
  .s_axi_arburst(s_axi_arburst),  // input wire [7 : 0] s_axi_arburst
  .s_axi_arlock(s_axi_arlock),    // input wire [7 : 0] s_axi_arlock
  .s_axi_arcache(s_axi_arcache),  // input wire [15 : 0] s_axi_arcache
  .s_axi_arprot(s_axi_arprot),    // input wire [11 : 0] s_axi_arprot
  .s_axi_arqos(s_axi_arqos),      // input wire [15 : 0] s_axi_arqos
  .s_axi_arvalid(s_axi_arvalid),  // input wire [3 : 0] s_axi_arvalid
  .s_axi_arready(s_axi_arready),  // output wire [3 : 0] s_axi_arready
  .s_axi_rid(s_axi_rid),          // output wire [15 : 0] s_axi_rid
  .s_axi_rdata(s_axi_rdata),      // output wire [127 : 0] s_axi_rdata
  .s_axi_rresp(s_axi_rresp),      // output wire [7 : 0] s_axi_rresp
  .s_axi_rlast(s_axi_rlast),      // output wire [3 : 0] s_axi_rlast
  .s_axi_rvalid(s_axi_rvalid),    // output wire [3 : 0] s_axi_rvalid
  .s_axi_rready(s_axi_rready),    // input wire [3 : 0] s_axi_rready
  .m_axi_awid(awid),        // output wire [3 : 0] m_axi_awid
  .m_axi_awaddr(awaddr),    // output wire [31 : 0] m_axi_awaddr
  .m_axi_awlen(awlen),      // output wire [3 : 0] m_axi_awlen
  .m_axi_awsize(awsize),    // output wire [2 : 0] m_axi_awsize
  .m_axi_awburst(awburst),  // output wire [1 : 0] m_axi_awburst
  .m_axi_awlock(awlock),    // output wire [1 : 0] m_axi_awlock
  .m_axi_awcache(awcache),  // output wire [3 : 0] m_axi_awcache
  .m_axi_awprot(awprot),    // output wire [2 : 0] m_axi_awprot
  .m_axi_awqos(m_axi_awqos),      // output wire [3 : 0] m_axi_awqos
  .m_axi_awvalid(awvalid),  // output wire [0 : 0] m_axi_awvalid
  .m_axi_awready(awready),  // input wire [0 : 0] m_axi_awready
  .m_axi_wid(wid),          // output wire [3 : 0] m_axi_wid
  .m_axi_wdata(wdata),      // output wire [31 : 0] m_axi_wdata
  .m_axi_wstrb(wstrb),      // output wire [3 : 0] m_axi_wstrb
  .m_axi_wlast(wlast),      // output wire [0 : 0] m_axi_wlast
  .m_axi_wvalid(wvalid),    // output wire [0 : 0] m_axi_wvalid
  .m_axi_wready(wready),    // input wire [0 : 0] m_axi_wready
  .m_axi_bid(bid),          // input wire [3 : 0] m_axi_bid
  .m_axi_bresp(bresp),      // input wire [1 : 0] m_axi_bresp
  .m_axi_bvalid(bvalid),    // input wire [0 : 0] m_axi_bvalid
  .m_axi_bready(bready),    // output wire [0 : 0] m_axi_bready
  .m_axi_arid(arid),        // output wire [3 : 0] m_axi_arid
  .m_axi_araddr(araddr),    // output wire [31 : 0] m_axi_araddr
  .m_axi_arlen(arlen),      // output wire [3 : 0] m_axi_arlen
  .m_axi_arsize(arsize),    // output wire [2 : 0] m_axi_arsize
  .m_axi_arburst(arburst),  // output wire [1 : 0] m_axi_arburst
  .m_axi_arlock(arlock),    // output wire [1 : 0] m_axi_arlock
  .m_axi_arcache(arcache),  // output wire [3 : 0] m_axi_arcache
  .m_axi_arprot(arprot),    // output wire [2 : 0] m_axi_arprot
  .m_axi_arqos(m_axi_arqos),      // output wire [3 : 0] m_axi_arqos
  .m_axi_arvalid(arvalid),  // output wire [0 : 0] m_axi_arvalid
  .m_axi_arready(arready),  // input wire [0 : 0] m_axi_arready
  .m_axi_rid(rid),          // input wire [3 : 0] m_axi_rid
  .m_axi_rdata(rdata),      // input wire [31 : 0] m_axi_rdata
  .m_axi_rresp(rresp),      // input wire [1 : 0] m_axi_rresp
  .m_axi_rlast(rlast),      // input wire [0 : 0] m_axi_rlast
  .m_axi_rvalid(rvalid),    // input wire [0 : 0] m_axi_rvalid
  .m_axi_rready(rready)     // output wire [0 : 0] m_axi_rready
);
assign MEM_dcache_rd_rdy = 1'b1;
assign MEM_dcache_ret_valid = (rvalid_3) & (rid_3==4'b11) &(state_d_cache_3 == state_rd_res);
assign MEM_dcache_ret_last = (rlast_3) & (rid_3==4'b11)& (state_d_cache_3 == state_rd_res);
assign MEM_dcache_ret_data =  rdata_3 ;
assign MEM_dcache_wr_rdy = state_d_cache_3 ==state_free;
//---------------------------
assign MEM_uncache_rd_rdy = 1'b1;
assign MEM_uncache_ret_valid = (rvalid_2) & (rid_2==4'b10)&(state_d_uncache_2 == state_rd_res);
assign MEM_uncache_ret_last = (rlast_2) & (rid_2==4'b10)&(state_d_uncache_2 == state_rd_res);
assign MEM_uncache_ret_data =  rdata_2 ;
assign MEM_uncache_wr_rdy = state_d_uncache_2 ==state_free;
//-------------------------
assign IF_icache_rd_rdy = 1'b1;
assign IF_icache_ret_valid = (rvalid_1) & (rid_1==4'b01)&(state_i_cache_1 == state_rd_res);
assign IF_icache_ret_last = rlast_1 & (rid_1==4'b01)&(state_i_cache_1 == state_rd_res);
assign IF_icache_ret_data = rdata_1;
assign IF_icache_wr_rdy = state_i_cache_1 == state_free;
//--------------------------
assign IF_uncache_rd_rdy = 1'b1;
assign IF_uncache_ret_valid = (rvalid_0) & (rid_0==4'b00)&(state_i_uncache_0 == state_rd_res);
assign IF_uncache_ret_last = rlast_0 & (rid_0==4'b00)&(state_i_uncache_0 == state_rd_res);
assign IF_uncache_ret_data = rdata_0;
assign IF_uncache_wr_rdy = state_i_uncache_0 == state_free;
endmodule
