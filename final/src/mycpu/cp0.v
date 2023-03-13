`include "MacroDef.v"

//THE ADDR[2:0] IS SELECT BITS
`define Index_index         8'b00000_000
`define Random_index        8'b00001_000
`define EntryLo0_index      8'b00010_000
`define EntryLo1_index      8'b00011_000
`define Context_index       8'b00100_000
`define PageMask_index      8'b00101_000
`define Wired_index         8'b00110_000
`define BadVAddr_index      8'b01000_000
`define Count_index         8'b01001_000
`define EntryHi_index       8'b01010_000
`define Compare_index       8'b01011_000
`define Status_index        8'b01100_000
`define Cause_index         8'b01101_000
`define EPC_index           8'b01110_000
`define PRID_index          8'b01111_000
`define Ebase_index         8'b01111_001
`define Config_index        8'b10000_000
`define Config1_index       8'b10000_001
`define TagLo_index         8'b11100_010
`define TagHi_index         8'b11101_010


`define status_cu0          Status[28]
`define status_bev          Status[22]
`define status_im           Status[15:8]
`define status_um           Status[4]
`define status_exl          Status[1]      //例外级
`define status_ie           Status[0]      //全局中断使能位

`define cause_bd            Cause[31]      //是否处于分支延迟槽
`define cause_ti            Cause[30]      //计时器中断提示
`define cause_ce            Cause[29:28]
`define cause_iv            Cause[23]
`define cause_ip1           Cause[15:10]    //待处理硬件中断，每一位对应一个中断线
`define cause_ip2           Cause[9:8]      //待处理软件中断标识
`define cause_excode        Cause[6:2]     //例外编码


module CP0(
    clk, rst, CP0WrEn, addr, data_in, MEM1_Exception, MEM1_eret_flush,
    MEM1_isBD,ext_int_in, MEM1_ExcCode, MEM1_PC,EntryLo0_Wren,
    EntryLo1_Wren,Index_Wren,MEM1_TLB_Exc,MEM1_badvaddr,EntryLo0_in,
    EntryLo1_in,Index_in,s1_found,EntryHi_Wren,EntryHi_in,Cause_CE_Wr,
    dcache_stall,

    data_out, EPC_out, Interrupt,EntryHi_out,Index_out,EntryLo0_out,
    EntryLo1_out, Random_out, Config_K0_out, Status_BEV,Status_EXL,
    Cause_IV,Ebase_out, Status_out, Cause_out
);
    input           clk;
    input           rst;
    input           CP0WrEn;
    input [7:0]     addr;
    input [31:0]    data_in;
    input           MEM1_Exception;         //M级中断标识
    input           MEM1_eret_flush;  //M级eret指令清空信号
    input           MEM1_isBD;          //延迟槽标识
    input [5:0]     ext_int_in;      //外部硬件中断标识
    input [4:0]     MEM1_ExcCode;     //M级例外编码
    input [31:0]    MEM1_badvaddr;    //bad virtual address
    input [31:0]    MEM1_PC;
    input           EntryLo0_Wren;
    input           EntryLo1_Wren;
    input           Index_Wren;
    input           MEM1_TLB_Exc;
    input           EntryHi_Wren;
    input           s1_found;
    input [31:0]    EntryHi_in;
    input [31:0]    EntryLo0_in;
    input [31:0]    EntryLo1_in;
    input [31:0]    Index_in;
    input           Cause_CE_Wr;
    input           dcache_stall;

    output [31:0]   data_out;
    output [31:0]   EPC_out;
    output          Interrupt;         //中断
    output [31:0]   EntryLo0_out;
    output [31:0]   EntryLo1_out;
    output [31:0]   Index_out;
    output [31:0]   EntryHi_out;
    output [31:0]   Random_out;
    output [2:0]    Config_K0_out;
    output          Status_BEV;
    output          Status_EXL;
    output          Cause_IV;
    output [31:0]   Ebase_out;
    output [31:0]   Status_out;
    output [31:0]   Cause_out;

    reg [31:0]      Index;
    reg [31:0]      Random;
    reg [31:0]      EntryLo0;
    reg [31:0]      EntryLo1;
    reg [31:0]      Context;
    reg [31:0]      PageMask;
    reg [31:0]      Wired;
    reg [31:0]      BadVAddr;
    reg [31:0]      Count;
    reg [31:0]      EntryHi;
    reg [31:0]      Compare;
    reg [31:0]      Status;
    reg [31:0]      Cause;
    reg [31:0]      EPC;
    reg [31:0]      PRID;
    reg [31:0]      Ebase;
    reg [31:0]      Config;
    reg [31:0]      Config1;
    reg [31:0]      TagLo;
    reg [31:0]      TagHi;
    reg             tick;
    wire    count_eq_compare;       //Count == Compare
    wire    Interrupt_temp;
    reg     Interrupt_reg;


assign count_eq_compare = (Compare == Count);
assign EPC_out = EPC;
assign EntryLo1_out = EntryLo1;
assign EntryLo0_out = EntryLo0;
assign Index_out = Index;
assign EntryHi_out = EntryHi;
assign Random_out = Random;
assign Config_K0_out = Config[2:0];
assign Status_BEV = `status_bev;
assign Status_EXL = `status_exl;
assign Cause_IV   = `cause_iv;
assign Ebase_out  = Ebase;
assign Status_out = Status;
assign Cause_out = Cause;

assign Interrupt_temp =
        ((Cause[15:8] & `status_im) != 8'h00) && `status_ie == 1'b1 && `status_exl == 1'b0;

assign Interrupt = (Interrupt_temp | Interrupt_reg) & ~dcache_stall;

always@(posedge clk) begin
    if(!rst)
        Interrupt_reg <= 1'b0;
    else if(Interrupt_temp & dcache_stall)
        Interrupt_reg <= 1'b1;
    else if(~dcache_stall)
        Interrupt_reg <= 1'b0;
end

/*
reg [31:0] count_exc;

always @(posedge clk) begin
    if ( !rst )
        count_exc <= 32'b0;
    else if (MEM1_Exception)
        count_exc <= count_exc + 32'b1;
end
*/

    //MFC0 read CP0
assign data_out =
                (addr == `Index_index   )     ?     Index               :
                (addr == `Random_index  )     ?     Random              :
                (addr == `EntryLo0_index)     ?     EntryLo0            :
                (addr == `EntryLo1_index)     ?     EntryLo1            :
                (addr == `Context_index )     ?     Context             :
                (addr == `PageMask_index)     ?     PageMask            :
                (addr == `Wired_index   )     ?     Wired               :
                (addr == `BadVAddr_index)     ?     BadVAddr            :
                (addr == `Count_index   )     ?     Count               :
                (addr == `EntryHi_index )     ?     EntryHi             :
                (addr == `Compare_index )     ?     Compare             :
                (addr == `Status_index  )     ?     Status              :
                (addr == `Cause_index   )     ?     Cause               :
                (addr == `EPC_index     )     ?     EPC                 :
                (addr == `PRID_index    )     ?     PRID                :
                (addr == `Ebase_index   )     ?     Ebase               :
                (addr == `Config_index  )     ?     Config              :
                (addr == `Config1_index )     ?     Config1             :
                (addr == `TagLo_index   )     ?     TagLo               :
                (addr == `TagHi_index   )     ?     TagHi               :
                                                        32'b0;

    /*
    CP0 generation by mtc0 and tlb instr;
    The first principle to use the cp0 register is :
            the basic company of a cp0 register is the reg field,
            not the whole reg
    */

    //EntryHi generation,consider the priority
    always @(posedge clk) begin
        if ( !rst )
            EntryHi[12:8] <= 0;
        else if (CP0WrEn && addr == `EntryHi_index)
        begin
            EntryHi[31:13] <= data_in[31:13];
            EntryHi[7:0] <= data_in[7:0];
        end
        else if ( EntryHi_Wren )
            EntryHi <= EntryHi_in;
        else if ( MEM1_TLB_Exc )
            EntryHi[31:13] <= MEM1_badvaddr[31:13];
    end

    //EntryLo0 generation
    always @(posedge clk) begin
        if ( !rst )
            EntryLo0[31:26] <= 6'b0;
        else if (CP0WrEn && addr == `EntryLo0_index)
            EntryLo0[25:0] <= data_in[25:0];
        else if ( EntryLo0_Wren )
            EntryLo0 <= EntryLo0_in;
    end

    //EntryLo1 generation
    always @(posedge clk) begin
        if ( !rst )
            EntryLo1[31:26] <= 6'b0;
        else if (CP0WrEn && addr == `EntryLo1_index)
            EntryLo1[25:0] <= data_in[25:0];
        else if ( EntryLo1_Wren )
            EntryLo1 <= EntryLo1_in;
    end

    //BadVAddr generation
    always @(posedge clk) begin
        if ( (MEM1_Exception && (MEM1_ExcCode == `AdEL || MEM1_ExcCode == `AdES)) || MEM1_TLB_Exc)
            BadVAddr <= MEM1_badvaddr;
    end

    //Index generation
    always @(posedge clk) begin
        if ( !rst )
            Index[31:2] <= 0;
        else if (CP0WrEn && addr == `Index_index)
            Index[1:0] <= data_in[1:0];
        else if ( Index_Wren & s1_found)
            Index <= Index_in;
        else if (Index_Wren & !s1_found)
            Index[31] <= 1'b1;
    end

    //Wired generation
    always @(posedge clk) begin
        if ( !rst )
            Wired <= 32'b0;
        else if (CP0WrEn && addr == `Wired_index && data_in[1:0] != 2'b11)//wired's value must be less than 4'b1111
            Wired[1:0] <= data_in[1:0];
    end

    //Random generarion
    always @(posedge clk) begin
        if ( !rst || Random[1:0] <= Wired[1:0])
            Random <= {30'b0,2'b11};
        else if (CP0WrEn && addr == `Wired_index)
            Random[1:0] <= 2'b11;
        else if( Random[1:0] > Wired[1:0] )//进行的是无符号的比较，这样写对吗
            Random[1:0] <= Random[1:0] - 1'b1;
    end

    //Config generation, 地址映射相关
    //这些配置寄存器的信息可能需要修改
    always @(posedge clk) begin
        if ( !rst )
        begin
            Config[31]      <= 1'b1;
            Config[30:16]   <= 0;
            Config[15]      <= 1'b0;
            Config[14:13]   <= 2'b0;
            Config[12:10]   <= 3'b0;
            Config[9:7]     <= 3'h1;//表示MMU采用标准的TLB(直接映射)
            Config[6:3]     <= 4'b0;
            Config[2:0]     <= 3'h3;//K0,3 --> cache
        end
        else if (CP0WrEn && addr == `Config_index)
            Config[2:0] <= data_in[2:0];
    end

    //Config1 generation,缓存属性相关
    always @(posedge clk) begin
        if ( !rst )
        begin
            Config1[31]     <= 1'b0;//indicate that don't implement the Config2 reg
            Config1[30:25]  <= 6'h3;
            Config1[24:22]  <= 3'h0;
            Config1[21:19]  <= 3'h5;//5-->icache
            Config1[18:16]  <= 3'h1;
            Config1[15:13]  <= 3'h0;
            Config1[12:10]  <= 3'h5;//5-->dcache
            Config1[9:7]    <= 3'h1;
            Config1[6:0]    <= 7'b0;//the Config1[3] = 0 indicates that don't implement the Watch reg
        end
    end

    //Context generation
    always @(posedge clk) begin
        if ( !rst )
            Context[3:0] <= 4'b0;
        else if (MEM1_TLB_Exc)//tlb exception
            Context[22:4] <= MEM1_badvaddr[31:13];
        else if (CP0WrEn && addr == `Context_index)
            Context[31:23] <= data_in[31:23];
            //a pointer into current PTE(page table entry) array in memory
    end

    //Pagemask generation,
    always @(posedge clk) begin
        if ( !rst )//fixed page, 4 kb
            PageMask <= 32'b0;  //{19'b0,2'b11,11'b0};not sure
    end

    //TagLo generarion,虽然实现了,但是似乎cache指令用不到
    always @(posedge clk) begin
        if (CP0WrEn && addr == `TagLo_index)
            TagLo <= data_in;
    end

    //PRID generation
    always @(posedge clk) begin
        if ( !rst )
            PRID <= 32'h4220;
    end

    //Ebase generation
    always @(posedge clk) begin
        if ( !rst )
            Ebase <= 32'h80000000;
        else if (CP0WrEn && addr == `Ebase_index)
            Ebase[29:12] <= data_in[29:12];
    end

    //Count generation
    /*A way to build Frequency divider(分频器)*/
    always @(posedge clk) begin
        if (!rst)
            tick <= 1'b0;
        else
            tick <= ~tick;

        if (CP0WrEn && addr == `Count_index)
            Count <= data_in;
        else if (tick)
            Count <= Count + 1'b1;
    end

    //Compare generation
    always @(posedge clk) begin
        if (CP0WrEn && addr == `Compare_index)
            Compare <= data_in;
    end

    //Status
    always @(posedge clk) begin
        if (!rst)
            `status_cu0 <= 1'b0;
        else if (CP0WrEn && addr == `Status_index)
            `status_cu0 <= data_in[28];
    end

    //Status,implement the bev but don't implement the cause_iv
    always @(posedge clk) begin
        if (!rst)
            `status_bev <= 1'b1;
        else if (CP0WrEn && addr == `Status_index)
            `status_bev <= data_in[22];
    end

    //Status
    always @(posedge clk) begin
        if (CP0WrEn && addr == `Status_index)
            `status_im <= data_in[15:8];
    end

    //Status
    always @(posedge clk) begin
        if (!rst)
            `status_um <= 1'b0;
        else if (CP0WrEn && addr == `Status_index)
            `status_um <= data_in[4];
    end

    //Status
    always @(posedge clk) begin
        if (!rst)
            `status_exl <= 1'b0;
        else if (MEM1_Exception)
            `status_exl <= 1'b1;
        else if (MEM1_eret_flush)
            `status_exl <= 1'b0;
        else if (CP0WrEn && addr == `Status_index)
            `status_exl <= data_in[1];
    end

    //Status
    always @(posedge clk) begin
        if (!rst)
            `status_ie <= 1'b0;
        else if (CP0WrEn && addr == `Status_index)
            `status_ie <= data_in[0];
    end

    //Status
    always @(posedge clk) begin
        if (!rst) begin
            Status[31:29] <= 3'b0;
            Status[27:23] <= 5'b0;
            Status[21:16] <= 6'b0;
            Status[7:5] <= 3'b0;
            Status[3:2] <= 2'b0;
        end
    end

    //Cause------> 31
    always @(posedge clk) begin
        if (!rst)
            `cause_bd <= 1'b0;
        else if (MEM1_Exception && !`status_exl)
            `cause_bd <= MEM1_isBD;
    end

    //Cause-------> 30
    always @(posedge clk) begin
        if (!rst)
            `cause_ti <= 1'b0;
        else if (CP0WrEn && addr == `Compare_index)
            `cause_ti <= 1'b0;
        else if (count_eq_compare)
            `cause_ti <= 1'b1;
    end

    //Cause
    always @(posedge clk) begin
        if (!rst)
            `cause_ce <= 2'b0;
        else if (MEM1_ExcCode == `Cpu)
             `cause_ce <= 2'b01;
        else if (MEM1_Exception)
            `cause_ce <= 2'b0;
    end

    //Cause-------> 23
    always @(posedge clk) begin
        if (!rst)
            `cause_iv <= 1'b0;
        else if (CP0WrEn && addr == `Cause_index)
            `cause_iv <= data_in[23];
    end

    //Cause-------> 15:10
    always @(posedge clk) begin
        if (!rst)
            `cause_ip1 <= 6'b0;
        else begin
            Cause[15] <= ext_int_in[5] | `cause_ti;
            Cause[14:10] <= ext_int_in[4:0];
        end
    end

    //Cause--------> 9:8
    always @(posedge clk) begin
        if (!rst)
            `cause_ip2 <= 2'b0;
        else if (CP0WrEn && addr == `Cause_index)
            `cause_ip2 <= data_in[9:8];
    end

    //Cause--------> 6:2
    always @(posedge clk) begin
        if (!rst)
            `cause_excode <= 5'b0;
        else if (MEM1_Exception)
            `cause_excode <= MEM1_ExcCode;
    end

    //Cause
    always @(posedge clk) begin
        if (!rst) begin
            Cause[27:24] <= 4'b0;
            Cause[22:16] <= 7'b0;
            Cause[7] <= 1'b0;
            Cause[1:0] <= 2'b0;
        end
    end

    //EPC
    always @(posedge clk) begin
        if (MEM1_Exception && !`status_exl) begin
            EPC <= MEM1_isBD ? MEM1_PC - 32'd4 : MEM1_PC;//excrption to modify the EPC，EPC_OUT = EPC
        end
        else if (CP0WrEn && addr == `EPC_index) begin
            EPC <= data_in;//mtc0 to modify the EPC，EPC_OUT = EPC + 4
         end
    end

endmodule
