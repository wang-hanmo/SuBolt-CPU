module tlb_16(
    input clk,
    input rst,

    //search port 0
    input   [18:0]  s0_vpn2,
    input           s0_odd_page,
    input   [ 7:0]  s0_asid,

    output          s0_found,
    output  [ 3:0]  s0_index,
    output  [19:0]  s0_pfn,
    output  [ 2:0]  s0_c,
    output          s0_d,
    output          s0_v,

    //search port 1
    input   [18:0]  s1_vpn2,
    input           s1_odd_page,
    input   [ 7:0]  s1_asid,

    output          s1_found,
    output  [ 3:0]  s1_index,
    output  [19:0]  s1_pfn,
    output  [ 2:0]  s1_c,
    output          s1_d,
    output          s1_v,   
    
    //write port
    input           we,//write enable
    input   [ 3:0]  w_index,
    input   [18:0]  w_vpn2,
    input   [ 7:0]  w_asid,
    input           w_g,
    input   [19:0]  w_pfn0,
    input   [ 2:0]  w_c0,
    input           w_d0,
    input           w_v0,
    input   [19:0]  w_pfn1,
    input   [ 2:0]  w_c1,
    input           w_d1,
    input           w_v1,

    //read port
    input   [ 3:0]  r_index,
    
    output  [18:0]  r_vpn2,
    output  [ 7:0]  r_asid,
    output          r_g,
    output  [19:0]  r_pfn0,
    output  [ 2:0]  r_c0,
    output          r_d0,
    output          r_v0,  
    output  [19:0]  r_pfn1,
    output  [ 2:0]  r_c1,
    output          r_d1,
    output          r_v1

);

    //TLB
    /*
     Basic information:
        Only include 16 terms   (could change)
        the page table structure :
        VPN2    ASID    G   PFN0    C0 D0 V0    PFN1    C1 D1 V1
         19      8      1    20     3   1  1     20      3 1  1   (bit)
    */
    
    parameter TLBNUM = 16;
    reg [18:0]  tlb_vpn2    [TLBNUM-1:0];
    reg [ 7:0]  tlb_asid    [TLBNUM-1:0];
    reg         tlb_g       [TLBNUM-1:0];
    reg [19:0]  tlb_pfn0    [TLBNUM-1:0];
    reg [ 2:0]  tlb_c0      [TLBNUM-1:0];
    reg         tlb_d0      [TLBNUM-1:0];
    reg         tlb_v0      [TLBNUM-1:0];
    reg [19:0]  tlb_pfn1    [TLBNUM-1:0];
    reg [ 2:0]  tlb_c1      [TLBNUM-1:0];
    reg         tlb_d1      [TLBNUM-1:0];
    reg         tlb_v1      [TLBNUM-1:0];

    wire [15:0]     match0 ;
    wire [15:0]     match1 ;

    integer i;

    assign match0[ 0] = (s0_vpn2==tlb_vpn2[ 0]) && ((s0_asid==tlb_asid[ 0]) || tlb_g[ 0]);
    assign match0[ 1] = (s0_vpn2==tlb_vpn2[ 1]) && ((s0_asid==tlb_asid[ 1]) || tlb_g[ 1]);
    assign match0[ 2] = (s0_vpn2==tlb_vpn2[ 2]) && ((s0_asid==tlb_asid[ 2]) || tlb_g[ 2]);
    assign match0[ 3] = (s0_vpn2==tlb_vpn2[ 3]) && ((s0_asid==tlb_asid[ 3]) || tlb_g[ 3]);
    assign match0[ 4] = (s0_vpn2==tlb_vpn2[ 4]) && ((s0_asid==tlb_asid[ 4]) || tlb_g[ 4]);
    assign match0[ 5] = (s0_vpn2==tlb_vpn2[ 5]) && ((s0_asid==tlb_asid[ 5]) || tlb_g[ 5]);
    assign match0[ 6] = (s0_vpn2==tlb_vpn2[ 6]) && ((s0_asid==tlb_asid[ 6]) || tlb_g[ 6]);
    assign match0[ 7] = (s0_vpn2==tlb_vpn2[ 7]) && ((s0_asid==tlb_asid[ 7]) || tlb_g[ 7]);
    assign match0[ 8] = (s0_vpn2==tlb_vpn2[ 8]) && ((s0_asid==tlb_asid[ 8]) || tlb_g[ 8]);
    assign match0[ 9] = (s0_vpn2==tlb_vpn2[ 9]) && ((s0_asid==tlb_asid[ 9]) || tlb_g[ 9]);
    assign match0[10] = (s0_vpn2==tlb_vpn2[10]) && ((s0_asid==tlb_asid[10]) || tlb_g[10]);
    assign match0[11] = (s0_vpn2==tlb_vpn2[11]) && ((s0_asid==tlb_asid[11]) || tlb_g[11]);
    assign match0[12] = (s0_vpn2==tlb_vpn2[12]) && ((s0_asid==tlb_asid[12]) || tlb_g[12]);
    assign match0[13] = (s0_vpn2==tlb_vpn2[13]) && ((s0_asid==tlb_asid[13]) || tlb_g[13]);
    assign match0[14] = (s0_vpn2==tlb_vpn2[14]) && ((s0_asid==tlb_asid[14]) || tlb_g[14]);
    assign match0[15] = (s0_vpn2==tlb_vpn2[15]) && ((s0_asid==tlb_asid[15]) || tlb_g[15]);

    assign match1[ 0] = (s1_vpn2==tlb_vpn2[ 0]) && ((s1_asid==tlb_asid[ 0]) || tlb_g[ 0]);
    assign match1[ 1] = (s1_vpn2==tlb_vpn2[ 1]) && ((s1_asid==tlb_asid[ 1]) || tlb_g[ 1]);
    assign match1[ 2] = (s1_vpn2==tlb_vpn2[ 2]) && ((s1_asid==tlb_asid[ 2]) || tlb_g[ 2]);
    assign match1[ 3] = (s1_vpn2==tlb_vpn2[ 3]) && ((s1_asid==tlb_asid[ 3]) || tlb_g[ 3]);
    assign match1[ 4] = (s1_vpn2==tlb_vpn2[ 4]) && ((s1_asid==tlb_asid[ 4]) || tlb_g[ 4]);
    assign match1[ 5] = (s1_vpn2==tlb_vpn2[ 5]) && ((s1_asid==tlb_asid[ 5]) || tlb_g[ 5]);
    assign match1[ 6] = (s1_vpn2==tlb_vpn2[ 6]) && ((s1_asid==tlb_asid[ 6]) || tlb_g[ 6]);
    assign match1[ 7] = (s1_vpn2==tlb_vpn2[ 7]) && ((s1_asid==tlb_asid[ 7]) || tlb_g[ 7]);
    assign match1[ 8] = (s1_vpn2==tlb_vpn2[ 8]) && ((s1_asid==tlb_asid[ 8]) || tlb_g[ 8]);
    assign match1[ 9] = (s1_vpn2==tlb_vpn2[ 9]) && ((s1_asid==tlb_asid[ 9]) || tlb_g[ 9]);
    assign match1[10] = (s1_vpn2==tlb_vpn2[10]) && ((s1_asid==tlb_asid[10]) || tlb_g[10]);
    assign match1[11] = (s1_vpn2==tlb_vpn2[11]) && ((s1_asid==tlb_asid[11]) || tlb_g[11]);
    assign match1[12] = (s1_vpn2==tlb_vpn2[12]) && ((s1_asid==tlb_asid[12]) || tlb_g[12]);
    assign match1[13] = (s1_vpn2==tlb_vpn2[13]) && ((s1_asid==tlb_asid[13]) || tlb_g[13]);
    assign match1[14] = (s1_vpn2==tlb_vpn2[14]) && ((s1_asid==tlb_asid[14]) || tlb_g[14]);
    assign match1[15] = (s1_vpn2==tlb_vpn2[15]) && ((s1_asid==tlb_asid[15]) || tlb_g[15]);

    assign s0_found =   (match0[15:0] != 16'b0);

    assign s1_found =   (match1[15:0] != 16'b0);

    //----------search port----------------//
    assign s0_index = 
            ({4{match0[ 0]}} & 4'd0 ) | ({4{match0[ 1]}} & 4'd1 ) | ({4{match0[ 2]}} & 4'd2 ) |
            ({4{match0[ 3]}} & 4'd3 ) | ({4{match0[ 4]}} & 4'd4 ) | ({4{match0[ 5]}} & 4'd5 ) |
            ({4{match0[ 6]}} & 4'd6 ) | ({4{match0[ 7]}} & 4'd7 ) | ({4{match0[ 8]}} & 4'd8 ) |
            ({4{match0[ 9]}} & 4'd9 ) | ({4{match0[10]}} & 4'd10) | ({4{match0[11]}} & 4'd11) |
            ({4{match0[12]}} & 4'd12) | ({4{match0[13]}} & 4'd13) | ({4{match0[14]}} & 4'd14) |
            ({4{match0[15]}} & 4'd15);

    assign s1_index = 
            ({4{match1[ 0]}} & 4'd0 ) | ({4{match1[ 1]}} & 4'd1 ) | ({4{match1[ 2]}} & 4'd2 ) |
            ({4{match1[ 3]}} & 4'd3 ) | ({4{match1[ 4]}} & 4'd4 ) | ({4{match1[ 5]}} & 4'd5 ) |
            ({4{match1[ 6]}} & 4'd6 ) | ({4{match1[ 7]}} & 4'd7 ) | ({4{match1[ 8]}} & 4'd8 ) |
            ({4{match1[ 9]}} & 4'd9 ) | ({4{match1[10]}} & 4'd10) | ({4{match1[11]}} & 4'd11) |
            ({4{match1[12]}} & 4'd12) | ({4{match1[13]}} & 4'd13) | ({4{match1[14]}} & 4'd14) |
            ({4{match1[15]}} & 4'd15);

    assign s0_pfn = 
        !s0_odd_page ? 
        (
            ({20{match0[ 0]}} & tlb_pfn0[ 0] ) | ({20{match0[ 1]}} & tlb_pfn0[ 1] ) | ({20{match0[ 2]}} & tlb_pfn0[ 2] ) |
            ({20{match0[ 3]}} & tlb_pfn0[ 3] ) | ({20{match0[ 4]}} & tlb_pfn0[ 4] ) | ({20{match0[ 5]}} & tlb_pfn0[ 5] ) |
            ({20{match0[ 6]}} & tlb_pfn0[ 6] ) | ({20{match0[ 7]}} & tlb_pfn0[ 7] ) | ({20{match0[ 8]}} & tlb_pfn0[ 8] ) |
            ({20{match0[ 9]}} & tlb_pfn0[ 9] ) | ({20{match0[10]}} & tlb_pfn0[10] ) | ({20{match0[11]}} & tlb_pfn0[11] ) |
            ({20{match0[12]}} & tlb_pfn0[12] ) | ({20{match0[13]}} & tlb_pfn0[13] ) | ({20{match0[14]}} & tlb_pfn0[14] ) |
            ({20{match0[15]}} & tlb_pfn0[15])
        ) :
        (
            ({20{match0[ 0]}} & tlb_pfn1[ 0] ) | ({20{match0[ 1]}} & tlb_pfn1[ 1] ) | ({20{match0[ 2]}} & tlb_pfn1[ 2] ) |
            ({20{match0[ 3]}} & tlb_pfn1[ 3] ) | ({20{match0[ 4]}} & tlb_pfn1[ 4] ) | ({20{match0[ 5]}} & tlb_pfn1[ 5] ) |
            ({20{match0[ 6]}} & tlb_pfn1[ 6] ) | ({20{match0[ 7]}} & tlb_pfn1[ 7] ) | ({20{match0[ 8]}} & tlb_pfn1[ 8] ) |
            ({20{match0[ 9]}} & tlb_pfn1[ 9] ) | ({20{match0[10]}} & tlb_pfn1[10] ) | ({20{match0[11]}} & tlb_pfn1[11] ) |
            ({20{match0[12]}} & tlb_pfn1[12] ) | ({20{match0[13]}} & tlb_pfn1[13] ) | ({20{match0[14]}} & tlb_pfn1[14] ) |
            ({20{match0[15]}} & tlb_pfn1[15])
        );

    assign s1_pfn = 
        !s1_odd_page ? 
        (
            ({20{match1[ 0]}} & tlb_pfn0[ 0] ) | ({20{match1[ 1]}} & tlb_pfn0[ 1] ) | ({20{match1[ 2]}} & tlb_pfn0[ 2] ) |
            ({20{match1[ 3]}} & tlb_pfn0[ 3] ) | ({20{match1[ 4]}} & tlb_pfn0[ 4] ) | ({20{match1[ 5]}} & tlb_pfn0[ 5] ) |
            ({20{match1[ 6]}} & tlb_pfn0[ 6] ) | ({20{match1[ 7]}} & tlb_pfn0[ 7] ) | ({20{match1[ 8]}} & tlb_pfn0[ 8] ) |
            ({20{match1[ 9]}} & tlb_pfn0[ 9] ) | ({20{match1[10]}} & tlb_pfn0[10] ) | ({20{match1[11]}} & tlb_pfn0[11] ) |
            ({20{match1[12]}} & tlb_pfn0[12] ) | ({20{match1[13]}} & tlb_pfn0[13] ) | ({20{match1[14]}} & tlb_pfn0[14] ) |
            ({20{match1[15]}} & tlb_pfn0[15])
        ) :
        (
            ({20{match1[ 0]}} & tlb_pfn1[ 0] ) | ({20{match1[ 1]}} & tlb_pfn1[ 1] ) | ({20{match1[ 2]}} & tlb_pfn1[ 2] ) |
            ({20{match1[ 3]}} & tlb_pfn1[ 3] ) | ({20{match1[ 4]}} & tlb_pfn1[ 4] ) | ({20{match1[ 5]}} & tlb_pfn1[ 5] ) |
            ({20{match1[ 6]}} & tlb_pfn1[ 6] ) | ({20{match1[ 7]}} & tlb_pfn1[ 7] ) | ({20{match1[ 8]}} & tlb_pfn1[ 8] ) |
            ({20{match1[ 9]}} & tlb_pfn1[ 9] ) | ({20{match1[10]}} & tlb_pfn1[10] ) | ({20{match1[11]}} & tlb_pfn1[11] ) |
            ({20{match1[12]}} & tlb_pfn1[12] ) | ({20{match1[13]}} & tlb_pfn1[13] ) | ({20{match1[14]}} & tlb_pfn1[14] ) |
            ({20{match1[15]}} & tlb_pfn1[15])
        );


    assign s0_c = 
        !s0_odd_page ? 
        (
            ({3{match0[ 0]}} & tlb_c0[ 0] ) | ({3{match0[ 1]}} & tlb_c0[ 1] ) | ({3{match0[ 2]}} & tlb_c0[ 2] ) |
            ({3{match0[ 3]}} & tlb_c0[ 3] ) | ({3{match0[ 4]}} & tlb_c0[ 4] ) | ({3{match0[ 5]}} & tlb_c0[ 5] ) |
            ({3{match0[ 6]}} & tlb_c0[ 6] ) | ({3{match0[ 7]}} & tlb_c0[ 7] ) | ({3{match0[ 8]}} & tlb_c0[ 8] ) |
            ({3{match0[ 9]}} & tlb_c0[ 9] ) | ({3{match0[10]}} & tlb_c0[10] ) | ({3{match0[11]}} & tlb_c0[11] ) |
            ({3{match0[12]}} & tlb_c0[12] ) | ({3{match0[13]}} & tlb_c0[13] ) | ({3{match0[14]}} & tlb_c0[14] ) |
            ({3{match0[15]}} & tlb_c0[15])
        ) :
        (
            ({3{match0[ 0]}} & tlb_c1[ 0] ) | ({3{match0[ 1]}} & tlb_c1[ 1] ) | ({3{match0[ 2]}} & tlb_c1[ 2] ) |
            ({3{match0[ 3]}} & tlb_c1[ 3] ) | ({3{match0[ 4]}} & tlb_c1[ 4] ) | ({3{match0[ 5]}} & tlb_c1[ 5] ) |
            ({3{match0[ 6]}} & tlb_c1[ 6] ) | ({3{match0[ 7]}} & tlb_c1[ 7] ) | ({3{match0[ 8]}} & tlb_c1[ 8] ) |
            ({3{match0[ 9]}} & tlb_c1[ 9] ) | ({3{match0[10]}} & tlb_c1[10] ) | ({3{match0[11]}} & tlb_c1[11] ) |
            ({3{match0[12]}} & tlb_c1[12] ) | ({3{match0[13]}} & tlb_c1[13] ) | ({3{match0[14]}} & tlb_c1[14] ) |
            ({3{match0[15]}} & tlb_c1[15])
        );

    assign s1_c = 
        !s1_odd_page ? 
        (
            ({3{match1[ 0]}} & tlb_c0[ 0] ) | ({3{match1[ 1]}} & tlb_c0[ 1] ) | ({3{match1[ 2]}} & tlb_c0[ 2] ) |
            ({3{match1[ 3]}} & tlb_c0[ 3] ) | ({3{match1[ 4]}} & tlb_c0[ 4] ) | ({3{match1[ 5]}} & tlb_c0[ 5] ) |
            ({3{match1[ 6]}} & tlb_c0[ 6] ) | ({3{match1[ 7]}} & tlb_c0[ 7] ) | ({3{match1[ 8]}} & tlb_c0[ 8] ) |
            ({3{match1[ 9]}} & tlb_c0[ 9] ) | ({3{match1[10]}} & tlb_c0[10] ) | ({3{match1[11]}} & tlb_c0[11] ) |
            ({3{match1[12]}} & tlb_c0[12] ) | ({3{match1[13]}} & tlb_c0[13] ) | ({3{match1[14]}} & tlb_c0[14] ) |
            ({3{match1[15]}} & tlb_c0[15])
        ) :
        (
            ({3{match1[ 0]}} & tlb_c1[ 0] ) | ({3{match1[ 1]}} & tlb_c1[ 1] ) | ({3{match1[ 2]}} & tlb_c1[ 2] ) |
            ({3{match1[ 3]}} & tlb_c1[ 3] ) | ({3{match1[ 4]}} & tlb_c1[ 4] ) | ({3{match1[ 5]}} & tlb_c1[ 5] ) |
            ({3{match1[ 6]}} & tlb_c1[ 6] ) | ({3{match1[ 7]}} & tlb_c1[ 7] ) | ({3{match1[ 8]}} & tlb_c1[ 8] ) |
            ({3{match1[ 9]}} & tlb_c1[ 9] ) | ({3{match1[10]}} & tlb_c1[10] ) | ({3{match1[11]}} & tlb_c1[11] ) |
            ({3{match1[12]}} & tlb_c1[12] ) | ({3{match1[13]}} & tlb_c1[13] ) | ({3{match1[14]}} & tlb_c1[14] ) |
            ({3{match1[15]}} & tlb_c1[15])
        );
    
    assign s0_d = 
        !s0_odd_page ? 
        (
            ({match0[ 0]} & tlb_d0[ 0] ) | ({match0[ 1]} & tlb_d0[ 1] ) | ({match0[ 2]} & tlb_d0[ 2] ) |
            ({match0[ 3]} & tlb_d0[ 3] ) | ({match0[ 4]} & tlb_d0[ 4] ) | ({match0[ 5]} & tlb_d0[ 5] ) |
            ({match0[ 6]} & tlb_d0[ 6] ) | ({match0[ 7]} & tlb_d0[ 7] ) | ({match0[ 8]} & tlb_d0[ 8] ) |
            ({match0[ 9]} & tlb_d0[ 9] ) | ({match0[10]} & tlb_d0[10] ) | ({match0[11]} & tlb_d0[11] ) |
            ({match0[12]} & tlb_d0[12] ) | ({match0[13]} & tlb_d0[13] ) | ({match0[14]} & tlb_d0[14] ) |
            ({match0[15]} & tlb_d0[15])
        ) :
        (
            ({match0[ 0]} & tlb_d1[ 0] ) | ({match0[ 1]} & tlb_d1[ 1] ) | ({match0[ 2]} & tlb_d1[ 2] ) |
            ({match0[ 3]} & tlb_d1[ 3] ) | ({match0[ 4]} & tlb_d1[ 4] ) | ({match0[ 5]} & tlb_d1[ 5] ) |
            ({match0[ 6]} & tlb_d1[ 6] ) | ({match0[ 7]} & tlb_d1[ 7] ) | ({match0[ 8]} & tlb_d1[ 8] ) |
            ({match0[ 9]} & tlb_d1[ 9] ) | ({match0[10]} & tlb_d1[10] ) | ({match0[11]} & tlb_d1[11] ) |
            ({match0[12]} & tlb_d1[12] ) | ({match0[13]} & tlb_d1[13] ) | ({match0[14]} & tlb_d1[14] ) |
            ({match0[15]} & tlb_d1[15])
        );

    assign s1_d = 
        !s1_odd_page ? 
        (
            ({match1[ 0]} & tlb_d0[ 0] ) | ({match1[ 1]} & tlb_d0[ 1] ) | ({match1[ 2]} & tlb_d0[ 2] ) |
            ({match1[ 3]} & tlb_d0[ 3] ) | ({match1[ 4]} & tlb_d0[ 4] ) | ({match1[ 5]} & tlb_d0[ 5] ) |
            ({match1[ 6]} & tlb_d0[ 6] ) | ({match1[ 7]} & tlb_d0[ 7] ) | ({match1[ 8]} & tlb_d0[ 8] ) |
            ({match1[ 9]} & tlb_d0[ 9] ) | ({match1[10]} & tlb_d0[10] ) | ({match1[11]} & tlb_d0[11] ) |
            ({match1[12]} & tlb_d0[12] ) | ({match1[13]} & tlb_d0[13] ) | ({match1[14]} & tlb_d0[14] ) |
            ({match1[15]} & tlb_d0[15])
        ) :
        (
            ({match1[ 0]} & tlb_d1[ 0] ) | ({match1[ 1]} & tlb_d1[ 1] ) | ({match1[ 2]} & tlb_d1[ 2] ) |
            ({match1[ 3]} & tlb_d1[ 3] ) | ({match1[ 4]} & tlb_d1[ 4] ) | ({match1[ 5]} & tlb_d1[ 5] ) |
            ({match1[ 6]} & tlb_d1[ 6] ) | ({match1[ 7]} & tlb_d1[ 7] ) | ({match1[ 8]} & tlb_d1[ 8] ) |
            ({match1[ 9]} & tlb_d1[ 9] ) | ({match1[10]} & tlb_d1[10] ) | ({match1[11]} & tlb_d1[11] ) |
            ({match1[12]} & tlb_d1[12] ) | ({match1[13]} & tlb_d1[13] ) | ({match1[14]} & tlb_d1[14] ) |
            ({match1[15]} & tlb_d1[15])
        );

    assign s0_v = 
        !s0_odd_page ?
        (
            ({match0[ 0]} & tlb_v0[ 0] ) | ({match0[ 1]} & tlb_v0[ 1] ) | ({match0[ 2]} & tlb_v0[ 2] ) |
            ({match0[ 3]} & tlb_v0[ 3] ) | ({match0[ 4]} & tlb_v0[ 4] ) | ({match0[ 5]} & tlb_v0[ 5] ) |
            ({match0[ 6]} & tlb_v0[ 6] ) | ({match0[ 7]} & tlb_v0[ 7] ) | ({match0[ 8]} & tlb_v0[ 8] ) |
            ({match0[ 9]} & tlb_v0[ 9] ) | ({match0[10]} & tlb_v0[10] ) | ({match0[11]} & tlb_v0[11] ) |
            ({match0[12]} & tlb_v0[12] ) | ({match0[13]} & tlb_v0[13] ) | ({match0[14]} & tlb_v0[14] ) |
            ({match0[15]} & tlb_v0[15])
        ) :
        (
            ({match0[ 0]} & tlb_v1[ 0] ) | ({match0[ 1]} & tlb_v1[ 1] ) | ({match0[ 2]} & tlb_v1[ 2] ) |
            ({match0[ 3]} & tlb_v1[ 3] ) | ({match0[ 4]} & tlb_v1[ 4] ) | ({match0[ 5]} & tlb_v1[ 5] ) |
            ({match0[ 6]} & tlb_v1[ 6] ) | ({match0[ 7]} & tlb_v1[ 7] ) | ({match0[ 8]} & tlb_v1[ 8] ) |
            ({match0[ 9]} & tlb_v1[ 9] ) | ({match0[10]} & tlb_v1[10] ) | ({match0[11]} & tlb_v1[11] ) |
            ({match0[12]} & tlb_v1[12] ) | ({match0[13]} & tlb_v1[13] ) | ({match0[14]} & tlb_v1[14] ) |
            ({match0[15]} & tlb_v1[15])
        );

    assign s1_v = 
        !s1_odd_page ?
        (
            ({match1[ 0]} & tlb_v0[ 0] ) | ({match1[ 1]} & tlb_v0[ 1] ) | ({match1[ 2]} & tlb_v0[ 2] ) |
            ({match1[ 3]} & tlb_v0[ 3] ) | ({match1[ 4]} & tlb_v0[ 4] ) | ({match1[ 5]} & tlb_v0[ 5] ) |
            ({match1[ 6]} & tlb_v0[ 6] ) | ({match1[ 7]} & tlb_v0[ 7] ) | ({match1[ 8]} & tlb_v0[ 8] ) |
            ({match1[ 9]} & tlb_v0[ 9] ) | ({match1[10]} & tlb_v0[10] ) | ({match1[11]} & tlb_v0[11] ) |
            ({match1[12]} & tlb_v0[12] ) | ({match1[13]} & tlb_v0[13] ) | ({match1[14]} & tlb_v0[14] ) |
            ({match1[15]} & tlb_v0[15])
        ) :
        (
            ({match1[ 0]} & tlb_v1[ 0] ) | ({match1[ 1]} & tlb_v1[ 1] ) | ({match1[ 2]} & tlb_v1[ 2] ) |
            ({match1[ 3]} & tlb_v1[ 3] ) | ({match1[ 4]} & tlb_v1[ 4] ) | ({match1[ 5]} & tlb_v1[ 5] ) |
            ({match1[ 6]} & tlb_v1[ 6] ) | ({match1[ 7]} & tlb_v1[ 7] ) | ({match1[ 8]} & tlb_v1[ 8] ) |
            ({match1[ 9]} & tlb_v1[ 9] ) | ({match1[10]} & tlb_v1[10] ) | ({match1[11]} & tlb_v1[11] ) |
            ({match1[12]} & tlb_v1[12] ) | ({match1[13]} & tlb_v1[13] ) | ({match1[14]} & tlb_v1[14] ) |
            ({match1[15]} & tlb_v1[15])
        );

    //------------write port-----------//
    always @(posedge clk) begin
        if(!rst)
            for(i=0;i<TLBNUM;i=i+1) begin
            tlb_vpn2[i] = 19'd0;
            tlb_asid[i] = 8'd0;
            tlb_g[i]    = 1'b0;
            tlb_pfn0[i] = 20'd0;
            tlb_c0[i]   = 3'd0;
            tlb_d0[i]   = 1'b0;
            tlb_v0[i]   = 1'b0;
            tlb_pfn1[i] = 20'd0;
            tlb_c1[i]   = 3'd0;
            tlb_d1[i]   = 1'b0;
            tlb_v1[i]   = 1'b0;
            end
        else if ( we )
        begin
            tlb_vpn2[w_index] = w_vpn2;
            tlb_asid[w_index] = w_asid;
            tlb_g[w_index]    = w_g;
            tlb_pfn0[w_index] = w_pfn0;
            tlb_c0[w_index]   = w_c0;
            tlb_d0[w_index]   = w_d0;
            tlb_v0[w_index]   = w_v0;
            tlb_pfn1[w_index] = w_pfn1;
            tlb_c1[w_index]   = w_c1;
            tlb_d1[w_index]   = w_d1;
            tlb_v1[w_index]   = w_v1;
        end
    end

    //--------------read port---------//
    assign r_vpn2 = tlb_vpn2[r_index];
    assign r_asid = tlb_asid[r_index];
    assign r_g    = tlb_g[r_index];
    assign r_pfn0 = tlb_pfn0[r_index];
    assign r_c0   = tlb_c0[r_index];
    assign r_d0   = tlb_d0[r_index];
    assign r_v0   = tlb_v0[r_index];
    assign r_pfn1 = tlb_pfn1[r_index];
    assign r_c1   = tlb_c1[r_index];
    assign r_d1   = tlb_d1[r_index];
    assign r_v1   = tlb_v1[r_index];
    
endmodule    

module dm_tlb(
    input clk,
    input rst,

    //search port 0
    input   [18:0]  s0_vpn2,
    input           s0_odd_page,
    input   [ 7:0]  s0_asid,

    output          s0_found,
    output  [1:0]   s0_index,
    output  [19:0]  s0_pfn,
    output  [ 2:0]  s0_c,
    output          s0_d,
    output          s0_v,

    //search port 1
    input   [18:0]  s1_vpn2,
    input           s1_odd_page,
    input   [ 7:0]  s1_asid,

    output          s1_found,
    output  [ 1:0]  s1_index,
    output  [19:0]  s1_pfn,
    output  [ 2:0]  s1_c,
    output          s1_d,
    output          s1_v,

    //write port,更改配置寄存器信息,实际使用虚拟页号来索引
    input           we,//write enable
    input   [ 1:0]  w_index,
    input   [18:0]  w_vpn2,
    input   [ 7:0]  w_asid,
    input           w_g,
    input   [19:0]  w_pfn0,
    input   [ 2:0]  w_c0,
    input           w_d0,
    input           w_v0,
    input   [19:0]  w_pfn1,
    input   [ 2:0]  w_c1,
    input           w_d1,
    input           w_v1,

    //read port
    input   [ 1:0]  r_index,

    output  [18:0]  r_vpn2,
    output  [ 7:0]  r_asid,
    output          r_g,
    output  [19:0]  r_pfn0,
    output  [ 2:0]  r_c0,
    output          r_d0,
    output          r_v0,
    output  [19:0]  r_pfn1,
    output  [ 2:0]  r_c1,
    output          r_d1,
    output          r_v1
);

    //TLB
    /*
     Basic information:
        Only include 16 terms   (could change)
        the page table structure :
        VPN2    ASID    G   PFN0    C0 D0 V0    PFN1    C1 D1 V1
         19      8      1    20     3   1  1     20      3 1  1   (bit)
    */

    parameter TLBNUM = 4;
    reg [18:0]  tlb_vpn2    [TLBNUM-1:0];
    reg [ 7:0]  tlb_asid    [TLBNUM-1:0];
    reg         tlb_g       [TLBNUM-1:0];
    reg [19:0]  tlb_pfn0    [TLBNUM-1:0];
    reg [ 2:0]  tlb_c0      [TLBNUM-1:0];
    reg         tlb_d0      [TLBNUM-1:0];
    reg         tlb_v0      [TLBNUM-1:0];
    reg [19:0]  tlb_pfn1    [TLBNUM-1:0];
    reg [ 2:0]  tlb_c1      [TLBNUM-1:0];
    reg         tlb_d1      [TLBNUM-1:0];
    reg         tlb_v1      [TLBNUM-1:0];

    //search port
    assign s0_found = (s0_vpn2==tlb_vpn2[s0_vpn2[1:0]]) && ( (s0_asid==tlb_asid[s0_vpn2[1:0]]) || tlb_g[s0_vpn2[1:0]] );
    assign s0_index = s0_vpn2[1:0];
    assign s0_pfn   = !s0_odd_page ? tlb_pfn0[s0_vpn2[1:0]] : tlb_pfn1[s0_vpn2[1:0]];
    assign s0_c     = !s0_odd_page ? tlb_c0[s0_vpn2[1:0]] : tlb_c1[s0_vpn2[1:0]];
    assign s0_d     = !s0_odd_page ? tlb_d0[s0_vpn2[1:0]] : tlb_d1[s0_vpn2[1:0]];
    assign s0_v     = !s0_odd_page ? tlb_v0[s0_vpn2[1:0]] : tlb_v1[s0_vpn2[1:0]];

    assign s1_found = (s1_vpn2==tlb_vpn2[s1_vpn2[1:0]]) && ( (s1_asid==tlb_asid[s1_vpn2[1:0]]) || tlb_g[s1_vpn2[1:0]]);
    assign s1_index =  s1_vpn2[1:0];
    assign s1_pfn   = !s1_odd_page ? tlb_pfn0[s1_vpn2[1:0]] : tlb_pfn1[s1_vpn2[1:0]];
    assign s1_c     = !s1_odd_page ?   tlb_c0[s1_vpn2[1:0]] :   tlb_c1[s1_vpn2[1:0]];
    assign s1_d     = !s1_odd_page ?   tlb_d0[s1_vpn2[1:0]] :   tlb_d1[s1_vpn2[1:0]];
    assign s1_v     = !s1_odd_page ?   tlb_v0[s1_vpn2[1:0]] :   tlb_v1[s1_vpn2[1:0]];

    //------------write port-----------//
    integer i;
    always @(posedge clk) begin
        if(!rst)
            for(i=0;i<TLBNUM;i=i+1) begin
            tlb_vpn2[i] = 19'd0;
            tlb_asid[i] = 8'd0;
            tlb_g[i]    = 1'b0;
            tlb_pfn0[i] = 20'd0;
            tlb_c0[i]   = 3'd0;
            tlb_d0[i]   = 1'b0;
            tlb_v0[i]   = 1'b0;
            tlb_pfn1[i] = 20'd0;
            tlb_c1[i]   = 3'd0;
            tlb_d1[i]   = 1'b0;
            tlb_v1[i]   = 1'b0;
            end
        else if ( we )
        begin
            tlb_vpn2[w_vpn2[1:0]] = w_vpn2;
            tlb_asid[w_vpn2[1:0]] = w_asid;
            tlb_g[w_vpn2[1:0]]    = w_g;
            tlb_pfn0[w_vpn2[1:0]] = w_pfn0;
            tlb_c0[w_vpn2[1:0]]   = w_c0;
            tlb_d0[w_vpn2[1:0]]   = w_d0;
            tlb_v0[w_vpn2[1:0]]   = w_v0;
            tlb_pfn1[w_vpn2[1:0]] = w_pfn1;
            tlb_c1[w_vpn2[1:0]]   = w_c1;
            tlb_d1[w_vpn2[1:0]]   = w_d1;
            tlb_v1[w_vpn2[1:0]]   = w_v1;
        end
    end

    //--------------read port---------//
    assign r_vpn2 = tlb_vpn2[r_index];
    assign r_asid = tlb_asid[r_index];
    assign r_g    = tlb_g[r_index];
    assign r_pfn0 = tlb_pfn0[r_index];
    assign r_c0   = tlb_c0[r_index];
    assign r_d0   = tlb_d0[r_index];
    assign r_v0   = tlb_v0[r_index];
    assign r_pfn1 = tlb_pfn1[r_index];
    assign r_c1   = tlb_c1[r_index];
    assign r_d1   = tlb_d1[r_index];
    assign r_v1   = tlb_v1[r_index];

endmodule

module tlb_4(
    input clk,
    input rst,

    //search port 0
    input   [18:0]  s0_vpn2,
    input           s0_odd_page,
    input   [ 7:0]  s0_asid,

    output          s0_found,
    output  [ 1:0]  s0_index,
    output  [19:0]  s0_pfn,
    output  [ 2:0]  s0_c,
    output          s0_d,
    output          s0_v,

    //search port 1
    input   [18:0]  s1_vpn2,
    input           s1_odd_page,
    input   [ 7:0]  s1_asid,

    output          s1_found,
    output  [ 1:0]  s1_index,
    output  [19:0]  s1_pfn,
    output  [ 2:0]  s1_c,
    output          s1_d,
    output          s1_v,   
    
    //write port
    input           we,//write enable
    input   [ 1:0]  w_index,
    input   [18:0]  w_vpn2,
    input   [ 7:0]  w_asid,
    input           w_g,
    input   [19:0]  w_pfn0,
    input   [ 2:0]  w_c0,
    input           w_d0,
    input           w_v0,
    input   [19:0]  w_pfn1,
    input   [ 2:0]  w_c1,
    input           w_d1,
    input           w_v1,

    //read port
    input   [ 1:0]  r_index,
    
    output  [18:0]  r_vpn2,
    output  [ 7:0]  r_asid,
    output          r_g,
    output  [19:0]  r_pfn0,
    output  [ 2:0]  r_c0,
    output          r_d0,
    output          r_v0,  
    output  [19:0]  r_pfn1,
    output  [ 2:0]  r_c1,
    output          r_d1,
    output          r_v1,

    input [3:0]     match1,
    output[3:0]     EX_match1
);

    //TLB
    /*
     Basic information:
        Only include 16 terms   (could change)
        the page table structure :
        VPN2    ASID    G   PFN0    C0 D0 V0    PFN1    C1 D1 V1
         19      8      1    20     3   1  1     20      3 1  1   (bit)
    */
    
    parameter TLBNUM = 4;
    reg [18:0]  tlb_vpn2    [TLBNUM-1:0];
    reg [ 7:0]  tlb_asid    [TLBNUM-1:0];
    reg         tlb_g       [TLBNUM-1:0];
    reg [19:0]  tlb_pfn0    [TLBNUM-1:0];
    reg [ 2:0]  tlb_c0      [TLBNUM-1:0];
    reg         tlb_d0      [TLBNUM-1:0];
    reg         tlb_v0      [TLBNUM-1:0];
    reg [19:0]  tlb_pfn1    [TLBNUM-1:0];
    reg [ 2:0]  tlb_c1      [TLBNUM-1:0];
    reg         tlb_d1      [TLBNUM-1:0];
    reg         tlb_v1      [TLBNUM-1:0];

    wire [TLBNUM-1:0]     match0 ;
    //wire [TLBNUM-1:0]     match1 ;
    integer i;

    assign match0[ 0] = (s0_vpn2==tlb_vpn2[ 0]) && ((s0_asid==tlb_asid[ 0]) || tlb_g[ 0]);
    assign match0[ 1] = (s0_vpn2==tlb_vpn2[ 1]) && ((s0_asid==tlb_asid[ 1]) || tlb_g[ 1]);
    assign match0[ 2] = (s0_vpn2==tlb_vpn2[ 2]) && ((s0_asid==tlb_asid[ 2]) || tlb_g[ 2]);
    assign match0[ 3] = (s0_vpn2==tlb_vpn2[ 3]) && ((s0_asid==tlb_asid[ 3]) || tlb_g[ 3]);

    // assign match1[ 0] = (s1_vpn2==tlb_vpn2[ 0]) && ((s1_asid==tlb_asid[ 0]) || tlb_g[ 0]);
    // assign match1[ 1] = (s1_vpn2==tlb_vpn2[ 1]) && ((s1_asid==tlb_asid[ 1]) || tlb_g[ 1]);
    // assign match1[ 2] = (s1_vpn2==tlb_vpn2[ 2]) && ((s1_asid==tlb_asid[ 2]) || tlb_g[ 2]);
    // assign match1[ 3] = (s1_vpn2==tlb_vpn2[ 3]) && ((s1_asid==tlb_asid[ 3]) || tlb_g[ 3]);

    assign EX_match1[ 0] = (s1_vpn2==tlb_vpn2[ 0]) && ((s1_asid==tlb_asid[ 0]) || tlb_g[ 0]);
    assign EX_match1[ 1] = (s1_vpn2==tlb_vpn2[ 1]) && ((s1_asid==tlb_asid[ 1]) || tlb_g[ 1]);
    assign EX_match1[ 2] = (s1_vpn2==tlb_vpn2[ 2]) && ((s1_asid==tlb_asid[ 2]) || tlb_g[ 2]);
    assign EX_match1[ 3] = (s1_vpn2==tlb_vpn2[ 3]) && ((s1_asid==tlb_asid[ 3]) || tlb_g[ 3]);

    assign s0_found =   (match0[3:0] != 16'b0);

    assign s1_found =   (match1[3:0] != 16'b0);

    //----------search port----------------//
    assign s0_index = 
            ({2{match0[ 0]}} & 2'd0 ) | ({2{match0[ 1]}} & 2'd1 ) | ({2{match0[ 2]}} & 2'd2 ) |
            ({2{match0[ 3]}} & 2'd3 ) ;

    assign s1_index = 
            ({2{match1[ 0]}} & 2'd0 ) | ({2{match1[ 1]}} & 2'd1 ) | ({2{match1[ 2]}} & 2'd2 ) |
            ({2{match1[ 3]}} & 2'd3 ) ;

    assign s0_pfn = 
        !s0_odd_page ? 
        (
            ({20{match0[ 0]}} & tlb_pfn0[ 0] ) | ({20{match0[ 1]}} & tlb_pfn0[ 1] ) | ({20{match0[ 2]}} & tlb_pfn0[ 2] ) |
            ({20{match0[ 3]}} & tlb_pfn0[ 3] )
        ) :
        (
            ({20{match0[ 0]}} & tlb_pfn1[ 0] ) | ({20{match0[ 1]}} & tlb_pfn1[ 1] ) | ({20{match0[ 2]}} & tlb_pfn1[ 2] ) |
            ({20{match0[ 3]}} & tlb_pfn1[ 3] )
        );

    assign s1_pfn = 
        !s1_odd_page ? 
        (
            ({20{match1[ 0]}} & tlb_pfn0[ 0] ) | ({20{match1[ 1]}} & tlb_pfn0[ 1] ) | ({20{match1[ 2]}} & tlb_pfn0[ 2] ) |
            ({20{match1[ 3]}} & tlb_pfn0[ 3] )
        ) :
        (
            ({20{match1[ 0]}} & tlb_pfn1[ 0] ) | ({20{match1[ 1]}} & tlb_pfn1[ 1] ) | ({20{match1[ 2]}} & tlb_pfn1[ 2] ) |
            ({20{match1[ 3]}} & tlb_pfn1[ 3] )
        );


    assign s0_c = 
        !s0_odd_page ? 
        (
            ({3{match0[ 0]}} & tlb_c0[ 0] ) | ({3{match0[ 1]}} & tlb_c0[ 1] ) | ({3{match0[ 2]}} & tlb_c0[ 2] ) |
            ({3{match0[ 3]}} & tlb_c0[ 3] )
        ) :
        (
            ({3{match0[ 0]}} & tlb_c1[ 0] ) | ({3{match0[ 1]}} & tlb_c1[ 1] ) | ({3{match0[ 2]}} & tlb_c1[ 2] ) |
            ({3{match0[ 3]}} & tlb_c1[ 3] )
        );

    assign s1_c = 
        !s1_odd_page ? 
        (
            ({3{match1[ 0]}} & tlb_c0[ 0] ) | ({3{match1[ 1]}} & tlb_c0[ 1] ) | ({3{match1[ 2]}} & tlb_c0[ 2] ) |
            ({3{match1[ 3]}} & tlb_c0[ 3] )
        ) :
        (
            ({3{match1[ 0]}} & tlb_c1[ 0] ) | ({3{match1[ 1]}} & tlb_c1[ 1] ) | ({3{match1[ 2]}} & tlb_c1[ 2] ) |
            ({3{match1[ 3]}} & tlb_c1[ 3] )
        );
    
    assign s0_d = 
        !s0_odd_page ? 
        (
            ({match0[ 0]} & tlb_d0[ 0] ) | ({match0[ 1]} & tlb_d0[ 1] ) | ({match0[ 2]} & tlb_d0[ 2] ) |
            ({match0[ 3]} & tlb_d0[ 3] )
        ) :
        (
            ({match0[ 0]} & tlb_d1[ 0] ) | ({match0[ 1]} & tlb_d1[ 1] ) | ({match0[ 2]} & tlb_d1[ 2] ) |
            ({match0[ 3]} & tlb_d1[ 3] )
        );

    assign s1_d = 
        !s1_odd_page ? 
        (
            ({match1[ 0]} & tlb_d0[ 0] ) | ({match1[ 1]} & tlb_d0[ 1] ) | ({match1[ 2]} & tlb_d0[ 2] ) |
            ({match1[ 3]} & tlb_d0[ 3] )
        ) :
        (
            ({match1[ 0]} & tlb_d1[ 0] ) | ({match1[ 1]} & tlb_d1[ 1] ) | ({match1[ 2]} & tlb_d1[ 2] ) |
            ({match1[ 3]} & tlb_d1[ 3] ) 
        );

    assign s0_v = 
        !s0_odd_page ?
        (
            ({match0[ 0]} & tlb_v0[ 0] ) | ({match0[ 1]} & tlb_v0[ 1] ) | ({match0[ 2]} & tlb_v0[ 2] ) |
            ({match0[ 3]} & tlb_v0[ 3] ) 
        ) :
        (
            ({match0[ 0]} & tlb_v1[ 0] ) | ({match0[ 1]} & tlb_v1[ 1] ) | ({match0[ 2]} & tlb_v1[ 2] ) |
            ({match0[ 3]} & tlb_v1[ 3] )
        );

    assign s1_v = 
        !s1_odd_page ?
        (
            ({match1[ 0]} & tlb_v0[ 0] ) | ({match1[ 1]} & tlb_v0[ 1] ) | ({match1[ 2]} & tlb_v0[ 2] ) |
            ({match1[ 3]} & tlb_v0[ 3] )
        ) :
        (
            ({match1[ 0]} & tlb_v1[ 0] ) | ({match1[ 1]} & tlb_v1[ 1] ) | ({match1[ 2]} & tlb_v1[ 2] ) |
            ({match1[ 3]} & tlb_v1[ 3] ) 
        );

    //------------write port-----------//
    always @(posedge clk) begin
        if(!rst)
            for(i=0;i<TLBNUM;i=i+1) begin
            tlb_vpn2[i] = 19'd0;
            tlb_asid[i] = 8'd0;
            tlb_g[i]    = 1'b0;
            tlb_pfn0[i] = 20'd0;
            tlb_c0[i]   = 3'd0;
            tlb_d0[i]   = 1'b0;
            tlb_v0[i]   = 1'b0;
            tlb_pfn1[i] = 20'd0;
            tlb_c1[i]   = 3'd0;
            tlb_d1[i]   = 1'b0;
            tlb_v1[i]   = 1'b0;
            end
        else if ( we )
        begin
            tlb_vpn2[w_index] = w_vpn2;
            tlb_asid[w_index] = w_asid;
            tlb_g[w_index]    = w_g;
            tlb_pfn0[w_index] = w_pfn0;
            tlb_c0[w_index]   = w_c0;
            tlb_d0[w_index]   = w_d0;
            tlb_v0[w_index]   = w_v0;
            tlb_pfn1[w_index] = w_pfn1;
            tlb_c1[w_index]   = w_c1;
            tlb_d1[w_index]   = w_d1;
            tlb_v1[w_index]   = w_v1;
        end
    end

    //--------------read port---------//
    assign r_vpn2 = tlb_vpn2[r_index];
    assign r_asid = tlb_asid[r_index];
    assign r_g    = tlb_g[r_index];
    assign r_pfn0 = tlb_pfn0[r_index];
    assign r_c0   = tlb_c0[r_index];
    assign r_d0   = tlb_d0[r_index];
    assign r_v0   = tlb_v0[r_index];
    assign r_pfn1 = tlb_pfn1[r_index];
    assign r_c1   = tlb_c1[r_index];
    assign r_d1   = tlb_d1[r_index];
    assign r_v1   = tlb_v1[r_index];
    
endmodule   