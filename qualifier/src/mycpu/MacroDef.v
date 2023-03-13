//------------R_Type--------------------//
`define R_type 6'b000000

//-----------calc_r---------------------//
`define add     6'b100000
`define addu    6'b100001
`define sub     6'b100010
`define subu    6'b100011

`define sll     6'b000000 //逻辑左移
`define srl     6'b000010 //逻辑右移
`define sra     6'b000011 //算数右移
`define sllv    6'b000100 //逻辑可变左移
`define srlv    6'b000110 //逻辑可变右移
`define srav    6'b000111 //算数可变右移

`define and_    6'b100100
`define or_     6'b100101
`define xor_    6'b100110 //异或
`define nor_    6'b100111 //或非

`define slt     6'b101010 //小于置 1(有符号)
`define sltu    6'b101011 //小于置 1(有符号)                  


//-----------calc_i--------------------//
`define mult  6'b011000
`define multu 6'b011001
`define div   6'b011010
`define divu  6'b011011

//--------------jump_l_r----------------//
`define jalr  6'b001001
`define jr    6'b001000


`define nop   6'b000000

`define mfhi  6'b010000
`define mflo  6'b010010
`define mthi  6'b010001
`define mtlo  6'b010011

//-------------trap----------------------------//
`define break   6'b001101
`define syscall 6'b001100

//--------------------end R_type---------------//


//-----------calc_i---------------------//
`define addi  6'b001000
`define addiu 6'b001001
`define andi  6'b001100
`define ori   6'b001101
`define xori  6'b001110
`define lui   6'b001111

`define slti  6'b001010 //小于立即数置 1(有符号)
`define sltiu 6'b001011 //小于立即数置 1(无符号)

//-----------load--------------------//
`define lb	  6'b100000
`define lbu   6'b100100
`define lh	  6'b100001
`define lhu   6'b100101
`define lw    6'b100011

//-------------store----------------//
`define sb    6'b101000
`define sh    6'b101001
`define sw    6'b101011

//--------------jump_link----------------//
`define j     6'b000010
`define jal   6'b000011

//------------jump_l_r------------------//


//--------------branch------------------//
`define beq   6'b000100
`define bne   6'b000101
`define blez  6'b000110
`define bgtz  6'b000111

`define bltz  5'b00000
`define bgez  5'b00001                             
`define bgezal  5'b10001                             
`define bltzal  5'b10000                             
`define b_special 6'b000001
//b_special include bltz bgez

//--------------super---------------------//
`define cop0    6'b010000

`define mtc0    5'b00100    //RS字段
`define mfc0    5'b00000

`define eret    6'b011000

//--------------tlb---------------------//
`define tlb     6'b010000

`define tlbp    6'b001000
`define tlbr    6'b000001
`define tlbwi   6'b000010
`define tlbwr   6'b000110
`define walt    6'b100000

//---- data memory 's opration----//
`define Byte_Zero       3'd0//用于加载无符号字节
`define Byte_Sign       3'd1 //用于加载有符号字节
`define HalfWord_Zero   3'd2 //用于加载无符号半字
`define HalfWord_Sign   3'd3 //用于加载符号半字
`define Word            3'd4 //用于加载字
//---- end data memory -------- //


// ----instruction's categories----//
//判断指令类型时，首先使用opcode字段进行判断，如果可以判断出具体指令，停止判断
//否则，继续使用funct字段进行判断
//lui   imm16，sll、sra、srl    shamt
`define calc_r      4'd0//R型指令,rs+rt
`define calc_i      4'd1//I型指令,rs+imm16
`define load        4'd2//rs+imm16
`define store       4'd3//rs+imm16
`define jump_link   4'd4//jal: PC4
`define jump_l_r    4'd5//include jr、jalr，标准是 是否需要访问寄存器堆
//jalr: PC4
`define branch      4'd6
`define mul_div     4'd7//包括乘除槽用到的几个指令

`define super       4'd8
`define trap        4'd9
// ----ALU 's optr

`define ALU_add  4'd1
`define ALU_sub  4'd2
`define ALU_sll  4'd3//逻辑左移（算数左移与之相同）
`define ALU_srl  4'd4//逻辑右移
`define ALU_sra  4'd5//算术右移
`define ALU_and  4'd6
`define ALU_or   4'd7
`define ALU_xor  4'd8
`define ALU_nor  4'd9
`define ALU_slt  4'd10//小于则置位（有符号）
`define ALU_sltu 4'd11//小于则置位（无符号）
`define ALU_A    4'd12
`define ALU_B    4'd13

//异常、中断类型
`define Int     5'd0
`define TLBMod  5'd1
`define TLBL    5'd2
`define TLBS    5'd3
`define AdEL    5'd4
`define AdES    5'd5
`define Sys     5'd8
`define Bp      5'd9
`define RI      5'd10
`define Cpu     5'd11
`define Ov      5'd12
`define Trap    5'd13