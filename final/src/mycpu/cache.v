module icache(       clk, resetn, exception, stall,
        //CPU_Pipeline side
        /*input*/   valid, tag, index, offset,
        /*output*/  addr_ok, data_ok, rdata,
        //AXI-Bus side
        /*input*/   rd_rdy, wr_rdy, ret_valid, ret_last, ret_data,
        /*output*/  rd_req, wr_req, rd_type, wr_type, rd_addr, wr_addr, wr_wstrb, wr_data,
        //CACHE Instruction
            valid_CI, op_CI, index_CI, way_CI, tag_CI,
            cache_sel, uncache_out, uncache_data_ok, IF_data_ok,
            C_STATE
        );

    //clock and reset
    input clk;
    input resetn;
    input exception;
    input stall;

    // Cache && CPU-Pipeline
    input valid;                    //CPU request signal
    input[19:0] tag;                //CPU address[31:14]
    input[5:0] index;               //CPU address[13:6]
    input[5:0] offset;              //CPU address[5:0]: [5:2] is block offset , [1:0] is byte offset
    output addr_ok;                 //to show address and data is received by Cache
    output data_ok;                 //to show load or store operation is done
    output reg[31:0] rdata;         //data to be loaded from Cache to CPU

    // Cache && AXI-Bus
    input rd_rdy;                   //AXI-Bus read-ready signal
    input wr_rdy;                   //AXI-Bus write-ready signal
    input ret_valid;                //to show the data returned from AXI-Bus is valid
    input ret_last;                 //to show the data returned from AXI-Bus is the last one
    input[31:0] ret_data;           //data to be refilled from AXI-Bus to Cache
    output rd_req;                  //Cache read-request signal
    output wr_req;                  //Cache write-request signal
    output[2:0] rd_type;            //read type, assign 3'b100
    output[2:0] wr_type;            //write type, assign 3'b100
    output[31:0] rd_addr;           //read address
    output[31:0] wr_addr;           //write address
    output[3:0] wr_wstrb;           //write code,assign 4'b1111
    output[511:0] wr_data;          //data to be replaced from Cache to AXI-Bus

    input valid_CI;     //CACHE Instruction
    input op_CI;        //1: Index Invalid, 0: Hit Invalid
    input[5:0] index_CI;
    input way_CI;
    input[19:0] tag_CI;

    input cache_sel;
    input[31:0] uncache_out;
    input uncache_data_ok;
    output IF_data_ok;

    //Cache RAM
    /*
    Basic information:
        256 groups : index 0~255
        4 ways : way 0/1/2/3
        16 words in a block : block offset 0~15
        Every block: 1 valid bit + 1 dirty bit + 18 tag bit + 16 * 32 data bit
        Total memory: 64KB
    */

    reg[5:0] VT_addr;
    wire[5:0] Data_addr_wr;
    wire[5:0] Data_addr_rd;
    wire VT_Way0_wen;
    wire VT_Way1_wen;
    wire V_in;
    wire[19:0] T_in;
    wire Way0_Valid;
    wire Way1_Valid;
    wire[19:0] Way0_Tag;
    wire[19:0] Way1_Tag;
    reg[15:0] Data_Way0_wen;
    reg[15:0] Data_Way1_wen;
    reg[31:0] Data_in;
    wire[511:0] Data_Way0_out;
    wire[511:0] Data_Way1_out;

    //FINITE STATE MACHINE
    output reg[2:0] C_STATE;
    reg[2:0] N_STATE;
    parameter IDLE = 3'b000, LOOKUP = 3'b001, MISS = 3'b010, REFILL = 3'b011, INSTR = 3'b100;

    //Request Buffer
    reg[5:0] index_RB;
    reg[5:0] offset_RB;
    reg op_CI_RB;
    reg[5:0] index_CI_RB;
    reg way_CI_RB;

    //Miss Buffer : information for MISS-REPLACE-REFILL use
    reg replace_way_MB;        //the way to be replaced and refilled
    reg[19:0] replace_tag_new_MB;   //tag requested from cpu(to be refilled)
    reg[5:0] replace_index_MB;
    reg[3:0] ret_number_MB;         //how many data returned from AXI-Bus during REFILL state

    //replace select
    reg counter;
    reg age[63:0];

    //hit
    wire way0_hit;
    wire way1_hit;
    wire cache_hit;
    wire[1:0] hit_code;
    wire way0_hit_CI;
    wire way1_hit_CI;
    wire cache_hit_CI;

    reg[31:0] rdata_way0;
    reg[31:0] rdata_way1;
    reg[15:0] byte_write;
    wire RBWr;
    wire VTen;
    wire invalid;

    integer i;

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    //LUT Ram
    validtag_block VT_Way0(
        clk, resetn, VTen, VT_Way0_wen, VT_addr, VT_addr, V_in, T_in, Way0_Valid, Way0_Tag);
    validtag_block VT_Way1(
        clk, resetn, VTen, VT_Way1_wen, VT_addr, VT_addr, V_in, T_in, Way1_Valid, Way1_Tag);
    data_block Data_Way0(
            clk, resetn, VTen, Data_Way0_wen, Data_addr_wr, Data_in, Data_addr_rd, Data_Way0_out
        );
    data_block Data_Way1(
            clk, resetn, VTen, Data_Way1_wen, Data_addr_wr, Data_in, Data_addr_rd, Data_Way1_out
        );

    //tag compare && hit judgement
    assign way0_hit = Way0_Valid && (Way0_Tag == tag);
    assign way1_hit = Way1_Valid && (Way1_Tag == tag);
    assign cache_hit = way0_hit || way1_hit ;
    assign hit_code = {way1_hit,way0_hit};
    assign way0_hit_CI = Way0_Valid && (Way0_Tag == tag_CI);
    assign way1_hit_CI = Way1_Valid && (Way1_Tag == tag_CI);
    assign cache_hit_CI = way0_hit_CI || way1_hit_CI;

    assign IF_data_ok = cache_sel ? uncache_data_ok : data_ok;

    always@(posedge clk)
        if(!resetn)
            for(i=0;i<64;i=i+1)
                age[i] <= 1'b0;
        else
            case(hit_code)
                2'b01: begin
                        age[index_RB] <= 1'b1;
                    end
                2'b10: begin
                        age[index_RB] <= 1'b0;
                    end
                default:age[index_RB] <= age[index_RB];
            endcase
    always@(*)
            if(age[index_RB])
                counter = 1'd1;
            else
                counter = 1'd0;

    //Request Buffer
    always@(posedge clk)
        if(!resetn) begin
            index_RB <= 6'd0;
            offset_RB <= 6'd0;
            op_CI_RB <= 1'b0;
            index_CI_RB <= 6'd0;
            way_CI_RB <= 1'b0;
        end
        else if(RBWr) begin
            index_RB <= index;
            offset_RB <= offset;
            op_CI_RB <= op_CI;
            index_CI_RB <= index_CI;
            way_CI_RB <= way_CI;
        end

    //Miss Buffer
    always@(posedge clk)
        if(!resetn) begin
            replace_way_MB <= 1'b0;
            replace_index_MB <= 6'd0;
            replace_tag_new_MB <= 20'd0;
        end
        else if(C_STATE == LOOKUP) begin
            replace_way_MB <= counter;
            replace_index_MB <= index_RB;
            replace_tag_new_MB <= tag;
        end
    always@(posedge clk)                //help locate the block offset during REFILL state
        if(!resetn)
            ret_number_MB <= 4'b0000;
        else if(C_STATE == MISS)
            ret_number_MB <= 4'b0000;
        else if(ret_valid)
            ret_number_MB <= ret_number_MB + 1;

    //reading from cache to cpu (load)
    always@(offset_RB,Data_Way0_out)
        case(offset_RB[5:2])
            4'd0:   rdata_way0 = Data_Way0_out[ 31:  0];
            4'd1:   rdata_way0 = Data_Way0_out[ 63: 32];
            4'd2:   rdata_way0 = Data_Way0_out[ 95: 64];
            4'd3:   rdata_way0 = Data_Way0_out[127: 96];
            4'd4:   rdata_way0 = Data_Way0_out[159:128];
            4'd5:   rdata_way0 = Data_Way0_out[191:160];
            4'd6:   rdata_way0 = Data_Way0_out[223:192];
            4'd7:   rdata_way0 = Data_Way0_out[255:224];
            4'd8:   rdata_way0 = Data_Way0_out[287:256];
            4'd9:   rdata_way0 = Data_Way0_out[319:288];
            4'd10:  rdata_way0 = Data_Way0_out[351:320];
            4'd11:  rdata_way0 = Data_Way0_out[383:352];
            4'd12:  rdata_way0 = Data_Way0_out[415:384];
            4'd13:  rdata_way0 = Data_Way0_out[447:416];
            4'd14:  rdata_way0 = Data_Way0_out[479:448];
            default:rdata_way0 = Data_Way0_out[511:480];
        endcase
    always@(offset_RB,Data_Way1_out)
        case(offset_RB[5:2])
            4'd0:   rdata_way1 = Data_Way1_out[ 31:  0];
            4'd1:   rdata_way1 = Data_Way1_out[ 63: 32];
            4'd2:   rdata_way1 = Data_Way1_out[ 95: 64];
            4'd3:   rdata_way1 = Data_Way1_out[127: 96];
            4'd4:   rdata_way1 = Data_Way1_out[159:128];
            4'd5:   rdata_way1 = Data_Way1_out[191:160];
            4'd6:   rdata_way1 = Data_Way1_out[223:192];
            4'd7:   rdata_way1 = Data_Way1_out[255:224];
            4'd8:   rdata_way1 = Data_Way1_out[287:256];
            4'd9:   rdata_way1 = Data_Way1_out[319:288];
            4'd10:  rdata_way1 = Data_Way1_out[351:320];
            4'd11:  rdata_way1 = Data_Way1_out[383:352];
            4'd12:  rdata_way1 = Data_Way1_out[415:384];
            4'd13:  rdata_way1 = Data_Way1_out[447:416];
            4'd14:  rdata_way1 = Data_Way1_out[479:448];
            default:rdata_way1 = Data_Way1_out[511:480];
        endcase
    always@(*)
        if(cache_sel)
            rdata = uncache_out;
        else begin
            case(way0_hit)
                1'b0:   rdata = rdata_way1;
                default:rdata = rdata_way0;
            endcase
        end

    //write from cpu to cache (store)
    always@(ret_data)
            Data_in = ret_data;
    always@(ret_number_MB)
        case(ret_number_MB)
            4'd0:   byte_write = {15'd0,1'b1};
            4'd1:   byte_write = {14'd0,1'b1,1'd0};
            4'd2:   byte_write = {13'd0,1'b1,2'd0};
            4'd3:   byte_write = {12'd0,1'b1,3'd0};
            4'd4:   byte_write = {11'd0,1'b1,4'd0};
            4'd5:   byte_write = {10'd0,1'b1,5'd0};
            4'd6:   byte_write = {9'd0,1'b1,6'd0};
            4'd7:   byte_write = {8'd0,1'b1,7'd0};
            4'd8:   byte_write = {7'd0,1'b1,8'd0};
            4'd9:   byte_write = {6'd0,1'b1,9'd0};
            4'd10:  byte_write = {5'd0,1'b1,10'd0};
            4'd11:  byte_write = {4'd0,1'b1,11'd0};
            4'd12:  byte_write = {3'd0,1'b1,12'd0};
            4'd13:  byte_write = {2'd0,1'b1,13'd0};
            4'd14:  byte_write = {1'd0,1'b1,14'd0};
            default:byte_write = {1'b1,15'd0};
        endcase
    always@(ret_valid, C_STATE, replace_way_MB, byte_write)
        if(ret_valid &&(C_STATE == REFILL)) begin
            case(replace_way_MB)
                1'b0:  begin
                            Data_Way0_wen = byte_write;
                            Data_Way1_wen = 16'd0;
                        end
                default:begin
                            Data_Way0_wen = 16'd0;
                            Data_Way1_wen = byte_write;
                        end
            endcase
        end
        else begin
            Data_Way0_wen = 16'd0;
            Data_Way1_wen = 16'd0;
        end

    //replace from cache to mem (write memory)
    assign wr_addr = 32'd0 ;
    assign wr_data = 512'd0;
    assign wr_type = 3'b010;
    assign wr_wstrb = 4'b1111;

    //refill from mem to cache (read memory)
    assign VT_Way0_wen = ((C_STATE == REFILL) && (replace_way_MB == 0))
                        | (invalid & (op_CI_RB & ~way_CI_RB | ~op_CI_RB & way0_hit_CI));
    assign VT_Way1_wen = ((C_STATE == REFILL) && (replace_way_MB == 1))
                        | (invalid & (op_CI_RB & way_CI_RB | ~op_CI_RB & way1_hit_CI));
    assign V_in = ~(C_STATE == INSTR);
    assign T_in = replace_tag_new_MB;
    assign rd_type = 3'b010;
    assign rd_addr = {replace_tag_new_MB, replace_index_MB, 6'b000000};

    //block address control
    always@(index, C_STATE, replace_index_MB, index_RB, valid_CI, index_CI, index_CI_RB)
        if(C_STATE == REFILL)
            VT_addr = replace_index_MB;
        else if(C_STATE == INSTR)
            VT_addr = index_CI_RB;
        else if(valid_CI)
            VT_addr = index_CI;
        else
            VT_addr = index;

    assign Data_addr_wr = replace_index_MB;
    assign Data_addr_rd = (C_STATE == REFILL) ? index_RB : index;

    //main FSM
    /*
        LOOKUP: Cache checks hit (if hit,begin read/write)
        MISS: Cache doesn't hit and wait for replace
        REPLACE: Cache replaces data (writing memory)
        REFILL: Cache refills data (reading memory)
    */
    always@(posedge clk)
        if(!resetn)
            C_STATE <= IDLE;
        else
            C_STATE <= N_STATE;
    always@(C_STATE, valid, cache_hit, valid_CI, ret_valid, ret_last, exception)
        case(C_STATE)
            IDLE:   if(valid)
                        N_STATE = LOOKUP;
                    else if(valid_CI)
                        N_STATE = INSTR;
                    else
                        N_STATE = IDLE;
            LOOKUP: if(exception)
                        N_STATE = IDLE;
                    else if(!cache_hit)
                        N_STATE = MISS;
                    else if(valid)
                        N_STATE = LOOKUP;
                    else if(valid_CI)
                        N_STATE = INSTR;
                    else
                        N_STATE = IDLE;
            MISS:       N_STATE = REFILL;
            REFILL: if(ret_valid && ret_last)
                        N_STATE = LOOKUP;
                    else
                        N_STATE = REFILL;
            INSTR:      N_STATE = IDLE;
            default: N_STATE = IDLE;
        endcase

    //output signals
    assign addr_ok = 1'b1;
    assign data_ok = (C_STATE == IDLE) || ((C_STATE == LOOKUP) && cache_hit);
    //assign rd_req = (N_STATE == REFILL) ;
    assign rd_req = (C_STATE == MISS) | ((C_STATE == REFILL) & ~(ret_valid & ret_last));
    assign wr_req = 1'b0 ;

    assign RBWr = (valid | valid_CI)& data_ok;
    assign VTen = ~stall | (C_STATE == REFILL);
    assign invalid = (C_STATE == INSTR) & (op_CI_RB | cache_hit_CI);

endmodule

module dcache(       clk, resetn, DMen, stall, exception,
        //CPU_Pipeline side
        /*input*/   valid, op, tag, index, offset, wstrb, wdata,
        /*output*/  addr_ok, data_ok, rdata,
        //AXI-Bus side
        /*input*/   rd_rdy, wr_rdy, ret_valid, ret_last, ret_data, wr_valid,
        /*output*/  rd_req, wr_req, rd_type, wr_type, rd_addr, wr_addr, wr_wstrb, wr_data,
        //CACHE Instruction
                valid_CI,op_CI, index_CI, way_CI, tag_CI,
                cache_sel, uncache_out, uncache_data_ok, MEM_data_ok,
                C_STATE
        );

    //clock and reset
    input clk;
    input resetn;
    input DMen;
    input stall;
    input exception;

    // Cache && CPU-Pipeline
    input valid;                    //CPU request signal
    input op;                       //CPU opcode: 0 = load , 1 = store
    input[19:0] tag;                //CPU address[31:14]
    input[5:0] index;               //CPU address[13:6]
    input[5:0] offset;              //CPU address[5:0]: [5:2] is block offset , [1:0] is byte offset
    input[3:0] wstrb;               //write code,including 0001 , 0010 , 0100, 1000, 0011 , 1100 , 1111
    input[31:0] wdata;              //data to be stored from CPU to Cache
    output addr_ok;                 //to show address and data is received by Cache
    output data_ok;                 //to show load or store operation is done
    output reg[31:0] rdata;         //data to be loaded from Cache to CPU

    // Cache && AXI-Bus
    input rd_rdy;                   //AXI-Bus read-ready signal
    input wr_rdy;                   //AXI-Bus write-ready signal
    input ret_valid;                //to show the data returned from AXI-Bus is valid
    input ret_last;                 //to show the data returned from AXI-Bus is the last one
    input[31:0] ret_data;           //data to be refilled from AXI-Bus to Cache
    input wr_valid;
    output rd_req;                  //Cache read-request signal
    output wr_req;                  //Cache write-request signal
    output[2:0] rd_type;            //read type, assign 3'b100
    output[2:0] wr_type;            //write type, assign 3'b100
    output[31:0] rd_addr;           //read address
    output[31:0] wr_addr;           //write address
    output[3:0] wr_wstrb;           //write code,assign 4'b1111
    output[511:0] wr_data;          //data to be replaced from Cache to AXI-Bus

    input valid_CI;
    input[1:0] op_CI;   //10:index writeback invalid, 01:hit invalid, 11:hit writeback invalid
    input[5:0] index_CI;
    input way_CI;
    input[19:0] tag_CI;

    input cache_sel;
    input[31:0] uncache_out;
    input uncache_data_ok;
    output MEM_data_ok;
    //Cache RAM
    /*
    Basic information:
        256 groups : index 0~255
        4 ways : way 0/1/2/3
        16 words in a block : block offset 0~15
        Every block: 1 valid bit + 1 dirty bit + 18 tag bit + 16 * 32 data bit
        Total memory: 64KB
    */

    reg[5:0] VT_addr_wr;
    reg[5:0] VT_addr_rd;
    reg[5:0] D_addr_wr;
    reg[5:0] D_addr_rd;
    reg[5:0] Data_addr_wr;
    reg[5:0] Data_addr_rd;
    wire VT_Way0_wen;
    wire VT_Way1_wen;
    wire V_in;
    wire[19:0] T_in;
    wire Way0_Valid;
    wire Way1_Valid;
    wire[19:0] Way0_Tag;
    wire[19:0] Way1_Tag;
    wire D_Way0_wen;
    wire D_Way1_wen;
    wire D_in;
    wire Way0_Dirty;
    wire Way1_Dirty;
    reg[15:0] Data_Way0_wen;
    reg[15:0] Data_Way1_wen;
    reg[31:0] Data_in;
    wire[511:0] Data_Way0_out;
    wire[511:0] Data_Way1_out;

    //FINITE STATE MACHINE
    output reg[2:0] C_STATE;
    reg[2:0] N_STATE;
    parameter IDLE = 3'b000, LOOKUP = 3'b001,  SELECT = 3'b010,
              MISS = 3'b011, REPLACE = 3'b100, REFILL = 3'b101, INSTR = 3'b110;

    reg C_STATE_WB;
    reg N_STATE_WB;
    parameter IDLE_WB = 1'b0, WRITE = 1'b1;


    //Request Buffer
    reg op_RB;
    reg[5:0] index_RB;
    reg[5:0] offset_RB;
    reg[3:0] wstrb_RB;
    reg[31:0] wdata_RB;
    reg valid_CI_RB;
    reg[1:0] op_CI_RB;
    reg[5:0] index_CI_RB;
    reg way_CI_RB;

    //Miss Buffer : information for MISS-REPLACE-REFILL use
    reg replace_way_MB;        //the way to be replaced and refilled
    reg replace_Valid_MB;
    reg replace_Dirty_MB;
    reg[19:0] replace_tag_old_MB;   //unmatched tag in cache(to be replaced)
    reg[19:0] replace_tag_new_MB;   //tag requested from cpu(to be refilled)
    reg[5:0] replace_index_MB;
    reg[511:0] replace_data_MB;
    reg[3:0] ret_number_MB;         //how many data returned from AXI-Bus during REFILL state

    //Write Buffer
    reg[31:0] wdata_WB;
    reg way_WB;
    reg[3:0] wstrb_WB;
    reg[5:0] offset_WB;
    reg[5:0] index_WB;
    reg[19:0] tag_WB;
    reg[31:0] rdata_WB;

    //replace select
    reg[511:0] replace_data;
    reg replace_Valid;
    reg replace_Dirty;
    reg[19:0] replace_tag_old;
    reg counter;
    reg age[63:0];

    //hit
    wire way0_hit;
    wire way1_hit;
    wire cache_hit;
    wire[1:0] hit_code;
    wire hit_write;
    wire write_bypass1;
    wire way0_hit_CI;
    wire way1_hit_CI;
    wire cache_hit_CI;

    reg[31:0] rdata_way0;
    reg[31:0] rdata_way1;
    reg[15:0] byte_write1;
    reg[15:0] byte_write2;
    wire rdata_sel;
    wire[31:0] rdata_prior;

    integer i;
    wire VTen;
    reg[31:0] wdata_final;
    reg invalid;
    reg ok_CI;
    wire way_CI_sel;
    reg already_writeback;


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    //LUT Ram
    validtag_block VT_Way0(
        clk, resetn, VTen, VT_Way0_wen, VT_addr_rd, VT_addr_wr, V_in, T_in, Way0_Valid, Way0_Tag);
    validtag_block VT_Way1(
        clk, resetn, VTen, VT_Way1_wen, VT_addr_rd, VT_addr_wr, V_in, T_in, Way1_Valid, Way1_Tag);
    dirty_block D_Way0(
        clk, resetn, D_Way0_wen, D_addr_rd, D_addr_wr, D_in, Way0_Dirty);
    dirty_block D_Way1(
        clk, resetn, D_Way1_wen, D_addr_rd, D_addr_wr, D_in, Way1_Dirty);

    data_block Data_Way0(
            clk, resetn, VTen, Data_Way0_wen, Data_addr_wr, Data_in, Data_addr_rd, Data_Way0_out
        );
    data_block Data_Way1(
            clk, resetn, VTen, Data_Way1_wen, Data_addr_wr, Data_in, Data_addr_rd, Data_Way1_out
        );

    //tag compare && hit judgement
    assign way0_hit = Way0_Valid && (Way0_Tag == tag);
    assign way1_hit = Way1_Valid && (Way1_Tag == tag);
    assign cache_hit = way0_hit || way1_hit ;
    assign hit_write = (C_STATE == LOOKUP) && op_RB && cache_hit && !exception;
    assign hit_code = {way1_hit,way0_hit};

    assign way0_hit_CI = Way0_Valid && (Way0_Tag == tag_CI);
    assign way1_hit_CI = Way1_Valid && (Way1_Tag == tag_CI);
    assign cache_hit_CI = way0_hit_CI || way1_hit_CI ;


    assign write_bypass1 = (C_STATE_WB == WRITE) && DMen
                            && ~|({tag,index_RB,offset_RB[5:2]}^{tag_WB,index_WB,offset_WB[5:2]});

    assign MEM_data_ok = cache_sel ? uncache_data_ok : data_ok;

    //assign ok = ((C_STATE == IDLE) & ~write_conflict2) | ((C_STATE == LOOKUP) & ~write_conflict2 & cache_hit);
    assign VTen = ~stall | (C_STATE == REFILL);

    always@(posedge clk)
        if(!resetn)
            for(i=0;i<64;i=i+1)
                age[i] <= 1'b0;
        else
            case(hit_code)
                2'b01: begin
                        age[index_RB] <= 1'b1;
                    end
                2'b10: begin
                        age[index_RB] <= 1'b0;
                    end
                default:age[index_RB] <= age[index_RB];
            endcase
    always@(*)
            if(age[index_RB])
                counter = 1'd1;
            else
                counter = 1'd0;

    always@(*)
        case(counter)
            1'b0:  begin   //choose way0
                    replace_Valid = Way0_Valid;
                    replace_Dirty = Way0_Dirty;
                    replace_tag_old = Way0_Tag;
                    replace_data = Data_Way0_out;
            end
            default:begin   //choose way1
                    replace_Valid = Way1_Valid;
                    replace_Dirty = Way1_Dirty;
                    replace_tag_old = Way1_Tag;
                    replace_data = Data_Way1_out;
            end
        endcase

    //Request Buffer
    always@(posedge clk)
        if(!resetn) begin
            op_RB <= 1'b0;
            index_RB <= 6'd0;
            offset_RB <= 6'd0;
            wstrb_RB <= 4'd0;
            wdata_RB <= 32'd0;
            valid_CI_RB <= 1'b0;
            op_CI_RB <= 2'b00;
            index_CI_RB <= 6'd0;
            way_CI_RB <= 1'b0;
        end
        else if((valid | valid_CI) && data_ok) begin
            op_RB <= op;
            index_RB <= index;
            offset_RB <= offset;
            wstrb_RB <= wstrb;
            wdata_RB <= wdata;
            valid_CI_RB <= valid_CI;
            op_CI_RB <= op_CI;
            index_CI_RB <= index_CI;
            way_CI_RB <= way_CI;
        end

    //Miss Buffer
    always@(posedge clk)
        if(!resetn) begin
            replace_way_MB <= 1'b0;
            replace_data_MB <= 512'd0;
            replace_Valid_MB <= 1'b0;
            replace_Dirty_MB <= 1'b0;
            replace_index_MB <= 6'd0;
            replace_tag_old_MB <= 20'd0;
            replace_tag_new_MB <= 20'd0;
        end
        else if(C_STATE == LOOKUP) begin
            replace_way_MB <= counter;
            replace_data_MB <= replace_data;
            replace_Valid_MB <= replace_Valid;
            replace_Dirty_MB <= replace_Dirty;
            replace_index_MB <= index_RB;
            replace_tag_old_MB <= replace_tag_old;
            replace_tag_new_MB <= tag;
        end
        else if(C_STATE == INSTR) begin
            replace_way_MB <= way_CI_sel;
            replace_data_MB <= way_CI_sel ? Data_Way1_out : Data_Way0_out;
            replace_Valid_MB <= way_CI_sel ? Way1_Valid : Way0_Valid;
            replace_Dirty_MB <= way_CI_sel ? Way1_Dirty : Way0_Dirty;
            replace_index_MB <= index_CI_RB;
            replace_tag_old_MB <= way_CI_sel ? Way1_Tag : Way0_Tag;
            replace_tag_new_MB <= tag_CI;
        end
    always@(posedge clk)                //help locate the block offset during REFILL state
        if(!resetn)
            ret_number_MB <= 4'b0000;
        else if(C_STATE == MISS)
            ret_number_MB <= 4'b0000;
        else if(ret_valid)
            ret_number_MB <= ret_number_MB + 1;

    //Write Buffer
    always@(posedge clk)
        if(!resetn) begin
            wdata_WB <= 32'd0;
            way_WB <= 1'b0;
            wstrb_WB <= 4'd0;
            offset_WB <= 6'd0;
            index_WB <= 6'd0;
            tag_WB <= 20'd0;
            rdata_WB <= 32'd0;
        end
        else if(hit_write) begin
            wdata_WB <= wdata_RB;
            way_WB <= way0_hit ? 1'd0 : 1'd1;
            wstrb_WB <= wstrb_RB;
            offset_WB <= offset_RB;
            index_WB <= index_RB;
            tag_WB <= tag;
            rdata_WB <= write_bypass1 ? wdata_final : (way0_hit ? rdata_way0 : rdata_way1);
        end

    //reading from cache to cpu (load)
    always@(offset_RB,Data_Way0_out)
        case(offset_RB[5:2])
            4'd0:   rdata_way0 = Data_Way0_out[ 31:  0];
            4'd1:   rdata_way0 = Data_Way0_out[ 63: 32];
            4'd2:   rdata_way0 = Data_Way0_out[ 95: 64];
            4'd3:   rdata_way0 = Data_Way0_out[127: 96];
            4'd4:   rdata_way0 = Data_Way0_out[159:128];
            4'd5:   rdata_way0 = Data_Way0_out[191:160];
            4'd6:   rdata_way0 = Data_Way0_out[223:192];
            4'd7:   rdata_way0 = Data_Way0_out[255:224];
            4'd8:   rdata_way0 = Data_Way0_out[287:256];
            4'd9:   rdata_way0 = Data_Way0_out[319:288];
            4'd10:  rdata_way0 = Data_Way0_out[351:320];
            4'd11:  rdata_way0 = Data_Way0_out[383:352];
            4'd12:  rdata_way0 = Data_Way0_out[415:384];
            4'd13:  rdata_way0 = Data_Way0_out[447:416];
            4'd14:  rdata_way0 = Data_Way0_out[479:448];
            default:rdata_way0 = Data_Way0_out[511:480];
        endcase
    always@(offset_RB,Data_Way1_out)
        case(offset_RB[5:2])
            4'd0:   rdata_way1 = Data_Way1_out[ 31:  0];
            4'd1:   rdata_way1 = Data_Way1_out[ 63: 32];
            4'd2:   rdata_way1 = Data_Way1_out[ 95: 64];
            4'd3:   rdata_way1 = Data_Way1_out[127: 96];
            4'd4:   rdata_way1 = Data_Way1_out[159:128];
            4'd5:   rdata_way1 = Data_Way1_out[191:160];
            4'd6:   rdata_way1 = Data_Way1_out[223:192];
            4'd7:   rdata_way1 = Data_Way1_out[255:224];
            4'd8:   rdata_way1 = Data_Way1_out[287:256];
            4'd9:   rdata_way1 = Data_Way1_out[319:288];
            4'd10:  rdata_way1 = Data_Way1_out[351:320];
            4'd11:  rdata_way1 = Data_Way1_out[383:352];
            4'd12:  rdata_way1 = Data_Way1_out[415:384];
            4'd13:  rdata_way1 = Data_Way1_out[447:416];
            4'd14:  rdata_way1 = Data_Way1_out[479:448];
            default:rdata_way1 = Data_Way1_out[511:480];
        endcase

    assign rdata_sel = (cache_sel | write_bypass1);
    assign rdata_prior = cache_sel ? uncache_out : wdata_final;

    always@(*)
        if(rdata_sel)
            rdata = rdata_prior;
        else
            case(way0_hit)
                1'b0:   rdata = rdata_way1;
                default:rdata = rdata_way0;
            endcase

    //write from cpu to cache (store)
    always@(wdata_final, C_STATE_WB, ret_data)
        if(C_STATE_WB == WRITE)
            Data_in = wdata_final;
        else
            Data_in = ret_data;
    always@(offset_WB, wstrb_WB)
        case(offset_WB[5:2])
            4'd0:   byte_write1 = {15'd0,1'b1};
            4'd1:   byte_write1 = {14'd0,1'b1,1'd0};
            4'd2:   byte_write1 = {13'd0,1'b1,2'd0};
            4'd3:   byte_write1 = {12'd0,1'b1,3'd0};
            4'd4:   byte_write1 = {11'd0,1'b1,4'd0};
            4'd5:   byte_write1 = {10'd0,1'b1,5'd0};
            4'd6:   byte_write1 = {9'd0,1'b1,6'd0};
            4'd7:   byte_write1 = {8'd0,1'b1,7'd0};
            4'd8:   byte_write1 = {7'd0,1'b1,8'd0};
            4'd9:   byte_write1 = {6'd0,1'b1,9'd0};
            4'd10:  byte_write1 = {5'd0,1'b1,10'd0};
            4'd11:  byte_write1 = {4'd0,1'b1,11'd0};
            4'd12:  byte_write1 = {3'd0,1'b1,12'd0};
            4'd13:  byte_write1 = {2'd0,1'b1,13'd0};
            4'd14:  byte_write1 = {1'd0,1'b1,14'd0};
            default:byte_write1 = {1'b1,15'd0};
        endcase
    always@(ret_number_MB)
        case(ret_number_MB)
            4'd0:   byte_write2 = {15'd0,1'b1};
            4'd1:   byte_write2 = {14'd0,1'b1,1'd0};
            4'd2:   byte_write2 = {13'd0,1'b1,2'd0};
            4'd3:   byte_write2 = {12'd0,1'b1,3'd0};
            4'd4:   byte_write2 = {11'd0,1'b1,4'd0};
            4'd5:   byte_write2 = {10'd0,1'b1,5'd0};
            4'd6:   byte_write2 = {9'd0,1'b1,6'd0};
            4'd7:   byte_write2 = {8'd0,1'b1,7'd0};
            4'd8:   byte_write2 = {7'd0,1'b1,8'd0};
            4'd9:   byte_write2 = {6'd0,1'b1,9'd0};
            4'd10:  byte_write2 = {5'd0,1'b1,10'd0};
            4'd11:  byte_write2 = {4'd0,1'b1,11'd0};
            4'd12:  byte_write2 = {3'd0,1'b1,12'd0};
            4'd13:  byte_write2 = {2'd0,1'b1,13'd0};
            4'd14:  byte_write2 = {1'd0,1'b1,14'd0};
            default:byte_write2 = {1'b1,15'd0};
        endcase
    always@(C_STATE_WB,C_STATE,way_WB,byte_write1,byte_write2,ret_valid,replace_way_MB)
        if(C_STATE_WB) begin
            case(way_WB)
                1'b0:   begin
                            Data_Way0_wen = byte_write1;
                            Data_Way1_wen = 16'd0;
                        end
                default:begin
                            Data_Way0_wen = 16'd0;
                            Data_Way1_wen = byte_write1;
                        end
            endcase
        end
        else if(ret_valid &&(C_STATE == REFILL)) begin
            case(replace_way_MB)
                1'b0:   begin
                            Data_Way0_wen = byte_write2;
                            Data_Way1_wen = 16'd0;
                        end
                default:begin
                            Data_Way0_wen = 16'd0;
                            Data_Way1_wen = byte_write2;
                        end
            endcase
        end
        else begin
            Data_Way0_wen = 16'd0;
            Data_Way1_wen = 16'd0;
        end
        always@(wstrb_WB, rdata_WB, wdata_WB)
        case(wstrb_WB)
            4'b0001:wdata_final = {rdata_WB[31:8],wdata_WB[7:0]};
            4'b0010:wdata_final = {rdata_WB[31:16],wdata_WB[15:8],rdata_WB[7:0]};
            4'b0100:wdata_final = {rdata_WB[31:24],wdata_WB[23:16],rdata_WB[15:0]};
            4'b1000:wdata_final = {wdata_WB[31:24],rdata_WB[23:0]};
            4'b0011:wdata_final = {rdata_WB[31:16],wdata_WB[15:0]};
            4'b1100:wdata_final = {wdata_WB[31:16],rdata_WB[15:0]};
            4'b0111:wdata_final = {rdata_WB[31:24],wdata_WB[23:0]};
            4'b1110:wdata_final = {wdata_WB[31:8], rdata_WB[7:0]};
            default:wdata_final = wdata_WB;
        endcase

    //replace from cache to mem (write memory)
    assign wr_addr = {replace_tag_old_MB, replace_index_MB, 6'b000000} ;
    assign wr_data = replace_data_MB;
    assign wr_type = 3'b010;
    assign wr_wstrb = 4'b1111;

    //refill from mem to cache (read memory)
    assign VT_Way0_wen = ((C_STATE == REFILL) && (replace_way_MB == 0)) |
                        ((C_STATE == INSTR) & invalid & ~way_CI_sel);
    assign VT_Way1_wen = ((C_STATE == REFILL) && (replace_way_MB == 1)) |
                        ((C_STATE == INSTR) & invalid & way_CI_sel);
    assign V_in = ~(C_STATE == INSTR);
    assign T_in = replace_tag_new_MB;
    assign D_Way0_wen = ((C_STATE_WB == WRITE) && (way_WB == 1'd0)) || ((C_STATE == REFILL) && (replace_way_MB == 0));
    assign D_Way1_wen = ((C_STATE_WB == WRITE) && (way_WB == 1'd1)) || ((C_STATE == REFILL) && (replace_way_MB == 1));
    assign D_in = (C_STATE_WB ==WRITE);
    assign rd_type = 3'b010;
    assign rd_addr = {replace_tag_new_MB, replace_index_MB, 6'b000000};

    //block address control
    always@(*)
        if(C_STATE == REFILL)
            Data_addr_rd = index_RB;
        else if(valid_CI)
            Data_addr_rd = index_CI;
        else
            Data_addr_rd = index;

    always@(*)
        if(C_STATE_WB == WRITE)
            Data_addr_wr = index_WB;
        else
            Data_addr_wr = replace_index_MB;

    always@(*)
        if(valid_CI)
            D_addr_rd = index_CI;
        else
            D_addr_rd = index;

    always@(*)
        if(C_STATE_WB == WRITE)
            D_addr_wr = index_WB;
        else
            D_addr_wr = index_RB;

    always@(*)
        if(C_STATE == REFILL)
            VT_addr_rd = replace_index_MB;
        else if(valid_CI)
            VT_addr_rd = index_CI;
        else
            VT_addr_rd = index;

    always@(*)
        if(C_STATE == INSTR)
            VT_addr_wr = index_CI_RB;
        else
            VT_addr_wr = index_RB;

    //main FSM
    /*
        LOOKUP: Cache checks hit (if hit,begin read/write)
        MISS: Cache doesn't hit and wait for replace
        REPLACE: Cache replaces data (writing memory)
        REFILL: Cache refills data (reading memory)
    */
    always@(posedge clk)
        if(!resetn)
            C_STATE <= IDLE;
        else
            C_STATE <= N_STATE;
    always@(*)
        case(C_STATE)
            IDLE:   if(valid_CI)
                        N_STATE = INSTR;
                    else if(valid)
                        N_STATE = LOOKUP;
                    else
                        N_STATE = IDLE;
            LOOKUP: if(exception)
                        N_STATE = IDLE;
                    else if(!cache_hit)
                        N_STATE = MISS;
                    else if(valid_CI)
                        N_STATE = INSTR;
                    else if(valid)
                        N_STATE = LOOKUP;
                    else
                        N_STATE = IDLE;
            MISS:   if(!replace_Valid_MB || !replace_Dirty_MB) begin           //data is not dirty
                        N_STATE = REFILL;
                    end
                    else if(!wr_rdy)                                    //data is dirty
                        N_STATE = MISS;
                    else
                        N_STATE = REPLACE;
            REPLACE:if(valid_CI_RB)
                        N_STATE = INSTR;
                    else
                        N_STATE = REFILL;
            REFILL: if(ret_valid && ret_last)
                        N_STATE = LOOKUP;
                    else
                        N_STATE = REFILL;
            INSTR:  if(ok_CI)
                        N_STATE = IDLE;
                    else
                        N_STATE = REPLACE;
            default: N_STATE = IDLE;
        endcase

    //Write Buffer FSM
    always@(posedge clk)
        if(!resetn)
            C_STATE_WB <= IDLE_WB;
        else
            C_STATE_WB <= N_STATE_WB;
    always@(hit_write)
        if(hit_write)
            N_STATE_WB = WRITE;
        else
            N_STATE_WB = IDLE_WB;

    //output signals
    assign addr_ok = 1'b1;
    assign data_ok = (C_STATE == IDLE) || ((C_STATE == LOOKUP) && (cache_hit | exception));
    assign rd_req = ((C_STATE == MISS) & ~(replace_Valid_MB & replace_Dirty_MB)) |
                    ((C_STATE == REPLACE) & ~valid_CI_RB) |
                    ((C_STATE == REFILL) & ~(ret_valid & ret_last));
    assign wr_req = (((C_STATE == MISS) & replace_Valid_MB & replace_Dirty_MB & wr_rdy) 
                    | ((C_STATE == REPLACE) & valid_CI_RB));

    always@(*)
        case(op_CI_RB)
            2'b10://index writeback invalid
                    if(already_writeback)
                        invalid = 1'b1;
                    else if(~(way_CI_sel ? Way1_Valid&Way1_Dirty : Way0_Valid&Way0_Dirty))
                        invalid = 1'b1;
                    else
                        invalid = 1'b0;
            2'b01://hit invalid
                    if(cache_hit_CI)
                        invalid = 1'b1;
                    else
                        invalid = 1'b0;
            2'b11://hit writeback invalid
                    if(cache_hit_CI) begin
                        if(already_writeback)
                            invalid = 1'b1;
                        else if(~(way_CI_sel ? Way1_Valid&Way1_Dirty : Way0_Valid&Way0_Dirty))
                            invalid = 1'b1;
                        else
                            invalid = 1'b0;
                    end
                    else
                        invalid = 1'b0;
            default:invalid = 1'b0;
        endcase

    always@(*)
        case(op_CI_RB)
            2'b10://index writeback invalid
                    if(already_writeback)
                        ok_CI = 1'b1;
                    else if(~(way_CI_sel ? Way1_Valid&Way1_Dirty : Way0_Valid&Way0_Dirty))
                        ok_CI = 1'b1;
                    else
                        ok_CI = 1'b0;
            2'b01://hit invalid
                    ok_CI = 1'b1;
            2'b11://hit writeback invalid
                    if(cache_hit_CI) begin
                        if(already_writeback)
                            ok_CI = 1'b1;
                        else if(~(way_CI_sel ? Way1_Valid&Way1_Dirty : Way0_Valid&Way0_Dirty))
                            ok_CI = 1'b1;
                        else
                            ok_CI = 1'b0;
                    end
                    else
                        ok_CI = 1'b1;
            default:ok_CI = 1'b1;
        endcase

    assign way_CI_sel = op_CI_RB[0] ? way1_hit_CI : way_CI_RB;


    always@(posedge clk)
        if(!resetn)
            already_writeback <= 1'b0;
        else if((C_STATE == REPLACE)&valid_CI_RB)
            already_writeback <= 1'b1;
        else
            already_writeback <= 1'b0;



endmodule

module uncache_im(
        clk, resetn, wr, exception,
        //CPU_Pipeline side
        /*input*/   valid, addr,
        /*output*/  data_ok, rdata,
        //AXI-Bus side
        /*input*/   rd_rdy, wr_rdy, ret_valid, ret_last, ret_data,
        /*output*/  rd_req, wr_req, rd_type, wr_type, rd_addr, wr_addr, wr_wstrb, wr_data,
        C_STATE
);

    input clk;
    input resetn;
    input wr;
    input exception;

    input valid;
    input[31:0] addr;

    output data_ok;
    output[31:0] rdata;

    input rd_rdy;
    input wr_rdy;
    input ret_valid;
    input ret_last;
    input[31:0] ret_data;

    output rd_req;
    output wr_req;
    output[2:0] rd_type;
    output[2:0] wr_type;
    output[31:0] rd_addr;
    output[31:0] wr_addr;
    output[3:0] wr_wstrb;
    output[31:0] wr_data;

    output reg C_STATE;
    reg N_STATE;
    reg done;
    reg[31:0] rdata_reg;

    parameter IDLE = 1'b0;
    parameter LOAD    = 1'b1;


    always@(posedge clk)
        if(!resetn)
            C_STATE <= IDLE;
        else
            C_STATE <= N_STATE;

    always@(C_STATE, ret_valid, ret_last, valid, done, exception)
        case(C_STATE)
            IDLE:   if(exception)
                            N_STATE = IDLE; 
                    else if(valid & !done)
                            N_STATE = LOAD;
                    else
                            N_STATE = IDLE;
            LOAD:   if(ret_valid & ret_last)
                            N_STATE = IDLE;
                    else
                            N_STATE = LOAD;
            default:    N_STATE = IDLE;
        endcase

    assign data_ok = ~valid | done;
    assign rdata = rdata_reg;

    always@(posedge clk)
        if(!resetn)
            done <= 1'b0;
        else if(wr)
            done <= 1'b0;
        else if((C_STATE == LOAD) && ret_valid && ret_last)
            done <= 1'b1;

    always@(posedge clk)
        if(!resetn)
            rdata_reg <= 32'd0;
        else if((C_STATE == LOAD) && ret_valid && ret_last)
            rdata_reg <= ret_data;

    assign rd_req = !exception&
            (((C_STATE == IDLE) & valid & !done) | ((C_STATE == LOAD) & !(ret_valid & ret_last)));
    assign wr_req = 1'b0;
    assign rd_type = 3'b010;
    assign wr_type = 3'b010;
    assign rd_addr = addr;
    assign wr_addr = addr;
    assign wr_wstrb = 4'd0;
    assign wr_data = 32'd0;
endmodule

module uncache_dm(
        clk, resetn, MEM2_type, wr, exception,
        //CPU_Pipeline side
        /*input*/   valid, op, addr, wstrb, wdata,
        /*output*/  data_ok, rdata,
        //AXI-Bus side
        /*input*/   rd_rdy, wr_rdy, ret_valid, ret_last, ret_data, wr_valid,
        /*output*/  rd_req, wr_req, rd_type, wr_type, rd_addr, wr_addr, wr_wstrb, wr_data,
        C_STATE
);

    input clk;
    input resetn;
    input [2:0] MEM2_type;
    input wr;
    input exception;

    input valid;
    input op;
    input[31:0] addr;
    input[3:0] wstrb;
    input[31:0] wdata;

    output data_ok;
    output[31:0] rdata;

    input rd_rdy;
    input wr_rdy;
    input ret_valid;
    input ret_last;
    input[31:0] ret_data;
    input wr_valid;

    output rd_req;
    output wr_req;
    output[2:0] rd_type;
    output[2:0] wr_type;
    output[31:0] rd_addr;
    output[31:0] wr_addr;
    output[3:0] wr_wstrb;
    output[31:0] wr_data;

    output reg C_STATE;
    reg N_STATE;
    reg done;
    reg[31:0] rdata_reg;

    parameter IDLE = 1'b0;
    parameter LOAD    = 1'b1;

    wire load;
    wire store;

    assign load = valid & ~op;
    assign store = valid & op;

    always@(posedge clk)
        if(!resetn)
            C_STATE <= IDLE;
        else
            C_STATE <= N_STATE;

    always@(C_STATE, load, store, wr_rdy, ret_valid, ret_last, done, exception)
        case(C_STATE)
            IDLE:   if(exception)
                        N_STATE = IDLE; 
                    else if(load & !done)
                            N_STATE = LOAD;
                    else
                            N_STATE = IDLE;
            LOAD:   if(ret_valid && ret_last)
                            N_STATE = IDLE;
                    else
                            N_STATE = LOAD;
            default:    N_STATE = IDLE;
        endcase

    assign data_ok = ~valid | done | exception;
    assign rdata = rdata_reg;

    always@(posedge clk)
        if(!resetn)
            done <= 1'b0;
        else if(wr)
            done <= 1'b0;
        else if((C_STATE == LOAD) & ret_valid & ret_last)
            done <= 1'b1;
        else if((C_STATE == IDLE) & store & wr_rdy)
            done <= 1'b1;

    always@(posedge clk)
        if(!resetn)
            rdata_reg <= 32'd0;
        else if((C_STATE == LOAD) && ret_valid && ret_last)
            rdata_reg <= ret_data;

    assign rd_req = !exception&
            (((C_STATE == IDLE) & load & !done) | ((C_STATE == LOAD) & !(ret_valid & ret_last)));
    assign wr_req = !exception&
            ((C_STATE == IDLE) & store & wr_rdy & !done);
    assign rd_type = MEM2_type;
    assign wr_type = MEM2_type;
    assign rd_addr = addr;
    assign wr_addr = addr;
    assign wr_wstrb = wstrb;
    assign wr_data = wdata;

endmodule

module dirty_block(clk, rst, wen, rd_addr, wr_addr, din, dout);
    input clk;
    input rst;
    input wen;
    input[5:0] rd_addr;
    input[5:0] wr_addr;
    input din;

    output reg dout;
    reg[63:0] dirty;

    always@(posedge clk)
        if(!rst)
            dirty <= 64'd0;
        else if(wen)
            dirty[wr_addr] <= din;

    always@(posedge clk)
        if(!rst)
            dout <= 1'b0;
        else if(wen & (rd_addr == wr_addr))//write first
            dout <= din;
        else
            dout <= dirty[rd_addr];

endmodule

module validtag_block(clk, rst, en, wen, rd_addr, wr_addr, vin, tin, vout, tout);
    input clk;
    input rst;
    input en;
    input wen;
    input[5:0] rd_addr;
    input[5:0] wr_addr;
    input vin;
    input[19:0] tin;

    output reg vout;
    output reg[19:0] tout;

    wire vout_temp;
    wire[19:0] tout_temp;

    reg[63:0] valid;

Tag_Distributed U_ValidTag(
        wr_addr, tin, rd_addr, clk, wen, tout_temp
    );

    always@(posedge clk)
        if(!rst)
            valid <= 64'd0;
        else if(wen)
            valid[wr_addr] <= vin;

    assign vout_temp = valid[rd_addr];

    always@(posedge clk)
        if(!rst) begin
            vout <= 1'd0;
            tout <= 20'd0;
        end
        else if(en) begin
            vout <= vout_temp;
            tout <= tout_temp;
        end


endmodule

module data_block(clk, rst, en, wen, wr_addr, din, rd_addr, dout);
    input clk;
    input rst;
    input en;
    input[15:0] wen;
    input[5:0] wr_addr;
    input[31:0] din;
    input[5:0] rd_addr;
    output reg[511:0] dout;

    wire[511:0] dram_out;
    wire[511:0] dout_temp;

Data_Distributed U_0(
        wr_addr, din, rd_addr, clk, wen[ 0], dram_out[ 31:  0]
    );
Data_Distributed U_1(
        wr_addr, din, rd_addr, clk, wen[ 1], dram_out[ 63: 32]
    );
Data_Distributed U_2(
        wr_addr, din, rd_addr, clk, wen[ 2], dram_out[ 95: 64]
    );
Data_Distributed U_3(
        wr_addr, din, rd_addr, clk, wen[ 3], dram_out[127: 96]
    );
Data_Distributed U_4(
        wr_addr, din, rd_addr, clk, wen[ 4], dram_out[159:128]
    );
Data_Distributed U_5(
        wr_addr, din, rd_addr, clk, wen[ 5], dram_out[191:160]
    );
Data_Distributed U_6(
        wr_addr, din, rd_addr, clk, wen[ 6], dram_out[223:192]
    );
Data_Distributed U_7(
        wr_addr, din, rd_addr, clk, wen[ 7], dram_out[255:224]
    );
Data_Distributed U_8(
        wr_addr, din, rd_addr, clk, wen[ 8], dram_out[287:256]
    );
Data_Distributed U_9(
        wr_addr, din, rd_addr, clk, wen[ 9], dram_out[319:288]
    );
Data_Distributed U_a(
        wr_addr, din, rd_addr, clk, wen[10], dram_out[351:320]
    );
Data_Distributed U_b(
        wr_addr, din, rd_addr, clk, wen[11], dram_out[383:352]
    );
Data_Distributed U_c(
        wr_addr, din, rd_addr, clk, wen[12], dram_out[415:384]
    );
Data_Distributed U_d(
        wr_addr, din, rd_addr, clk, wen[13], dram_out[447:416]
    );
Data_Distributed U_e(
        wr_addr, din, rd_addr, clk, wen[14], dram_out[479:448]
    );
Data_Distributed U_f(
        wr_addr, din, rd_addr, clk, wen[15], dram_out[511:480]
    );

    assign dout_temp[ 31:  0] = wen[ 0]&(rd_addr == wr_addr) ? din : dram_out[ 31:  0];
    assign dout_temp[ 63: 32] = wen[ 1]&(rd_addr == wr_addr) ? din : dram_out[ 63: 32];
    assign dout_temp[ 95: 64] = wen[ 2]&(rd_addr == wr_addr) ? din : dram_out[ 95: 64];
    assign dout_temp[127: 96] = wen[ 3]&(rd_addr == wr_addr) ? din : dram_out[127: 96];
    assign dout_temp[159:128] = wen[ 4]&(rd_addr == wr_addr) ? din : dram_out[159:128];
    assign dout_temp[191:160] = wen[ 5]&(rd_addr == wr_addr) ? din : dram_out[191:160];
    assign dout_temp[223:192] = wen[ 6]&(rd_addr == wr_addr) ? din : dram_out[223:192];
    assign dout_temp[255:224] = wen[ 7]&(rd_addr == wr_addr) ? din : dram_out[255:224];
    assign dout_temp[287:256] = wen[ 8]&(rd_addr == wr_addr) ? din : dram_out[287:256];
    assign dout_temp[319:288] = wen[ 9]&(rd_addr == wr_addr) ? din : dram_out[319:288];
    assign dout_temp[351:320] = wen[10]&(rd_addr == wr_addr) ? din : dram_out[351:320];
    assign dout_temp[383:352] = wen[11]&(rd_addr == wr_addr) ? din : dram_out[383:352];
    assign dout_temp[415:384] = wen[12]&(rd_addr == wr_addr) ? din : dram_out[415:384];
    assign dout_temp[447:416] = wen[13]&(rd_addr == wr_addr) ? din : dram_out[447:416];
    assign dout_temp[479:448] = wen[14]&(rd_addr == wr_addr) ? din : dram_out[479:448];
    assign dout_temp[511:480] = wen[15]&(rd_addr == wr_addr) ? din : dram_out[511:480];

    always@(posedge clk)
        if(!rst)
            dout <= 512'd0;
        else if(en) begin
            dout <= dout_temp;
        end

endmodule
