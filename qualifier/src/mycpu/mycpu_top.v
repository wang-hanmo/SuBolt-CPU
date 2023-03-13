module mycpu_top(
    ext_int   ,   //high active

    aclk      ,
    aresetn   ,   //low active

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
    input [5:0] ext_int      ;  //interrupt,high active;


// 时钟与复位信�?
    input aclk      ;
    input aresetn   ;  //low active
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

    //debug
    output  [31:0] debug_wb_pc      ;
    output  [3:0] debug_wb_rf_wen  ;
    output  [4:0] debug_wb_rf_wnum ;
    output  [31:0] debug_wb_rf_wdata;


mips U_MIPS(
    ext_int   ,   //high active

    aclk      ,
    aresetn   ,   //low active

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

endmodule 