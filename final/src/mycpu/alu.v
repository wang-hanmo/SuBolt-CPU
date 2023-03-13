module alu1(
	input [31:0]        A,
    input [31:0]        B,
	input [4:0]         ALU1Op,

	output reg          Overflow,
	output reg [31:0]   C,
    output reg          Trap,
    output     [31:0]   add_result
);

	wire [4:0]      temp;
	wire            Less;
    wire            Trap_Equal;
    wire            Trap_Less;
    wire [31:0]     sub_result;
    wire [31:0]     or_result;
	wire [31:0]     and_result;
	wire [31:0]     nor_result;
	wire [31:0]     xor_result;
	wire [31:0]     sll_result;
	wire [31:0]     srl_result;
	wire [31:0]     sra_result;
	wire [31:0]     cmp_result;
    wire [31:0]     clo_result;
    wire [31:0]     clz_result;

    wire [2:0]      add_overflow;
    wire [2:0]      sub_overflow;

	reg [5:0]       CLO_RESULT;
	reg [5:0]       CLZ_RESULT;

    reg [31:0] simple_result;
	reg [2:0] sel1;
	reg [3:0] sel2;

	assign Less = ((ALU1Op == 5'b01001) && A[31]^B[31]) ? ~(A < B) : (A < B);
    
    /*for trap instruction*/
    assign Trap_Equal = A == B;
    assign Trap_Less =
    ( (ALU1Op == 5'b10010 || ALU1Op == 5'b10100) && A[31]^B[31]) ? ~(A < B) : (A < B);//signed/unsigned compare

    assign add_result = A + B;
	assign sub_result = A - B;
    assign or_result = A | B;
	assign and_result = A & B;
	assign nor_result = ~(A | B);
	assign xor_result = A ^ B;
	assign sll_result = B << A[4:0];
	assign srl_result = B >> A[4:0];
	assign sra_result = $signed(B) >>> A[4:0];
	assign cmp_result = {31'd0,Less};
    assign clo_result = {26'd0,CLO_RESULT};
    assign clz_result = {26'd0,CLZ_RESULT};

	always@(*)
		case(ALU1Op)
			5'b00010:			sel1 = 3'b000;		//or
			5'b00011:			sel1 = 3'b001;		//and
			5'b00100:			sel1 = 3'b010;		//nor
			5'b00101:			sel1 = 3'b011;		//xor
            default:            sel1 = 3'b100;      //movn, movz
		endcase

	always@(*)
		case(sel1)
			3'b000:			simple_result = or_result;		//or
			3'b001:			simple_result = and_result;		//and
			3'b010:			simple_result = nor_result;		//nor
            3'b011:         simple_result = xor_result;     //xor
			default:		simple_result = A;		        //movn, movz
		endcase

	always@(*)
		case(ALU1Op)
			5'b00000, 5'b01100:	sel2 = 4'b0000;		//add/addu
			5'b00001, 5'b10000:	sel2 = 4'b0001;		//sub/subu
			5'b00010, 5'b00011, 
			5'b00100, 5'b00101,
            5'b01011:	        sel2 = 4'b0010;		//or/and/nor/xor/movn/movz
			5'b00110:			sel2 = 4'b0011;		//logical left shift
			5'b00111:			sel2 = 4'b0100;		//logical right shift
			5'b01000:			sel2 = 4'b0101;		//arithmetical right shift
            5'b01101:           sel2 = 4'b0110;     //clo
            5'b01110:           sel2 = 4'b0111;     //clz
			default:			sel2 = 4'b1000;		//signed/unsigned compare
		endcase
		

	always@(*)
		case(sel2)
			4'b0000:			C = add_result;		//add/addu
			4'b0001:			C = sub_result;		//sub/subu
			4'b0010:			C = simple_result;	//or/and/nor/xor/movn/movz
			4'b0011:			C = sll_result;		//logical left shift
			4'b0100:			C = srl_result;		//logical right shift
		    4'b0101:			C = sra_result;		//arithmetical right shift
            4'b0110:            C = clo_result;     //clo
            4'b0111:            C = clz_result;     //clz
			default:			C = cmp_result;		//signed/unsigned compare
		endcase

	assign add_overflow = {A[31],B[31],add_result[31]};
	assign sub_overflow = {A[31],B[31],sub_result[31]};

	always@(ALU1Op,add_overflow, sub_overflow)
		case(ALU1Op)
		5'b00000:
			case(add_overflow)
				3'b110, 3'b001:		Overflow = 1'b1;
				default:			Overflow = 1'b0;
			endcase
		5'b00001:
			case(sub_overflow)
				3'b100, 3'b011:		Overflow = 1'b1;
				default:			Overflow = 1'b0;
			endcase
		default:	Overflow = 1'b0;
		endcase


    always @(Trap_Equal,Trap_Less,ALU1Op) begin
        case (ALU1Op)
            5'b10001://teq,teqi
                if (Trap_Equal)
                    Trap = 1'b1;
                else
                    Trap = 1'b0;
            5'b10010,5'b10011://tge,tgei,tgeu,tgeiu
                if (~Trap_Less)
                    Trap = 1'b1;
                else
                    Trap = 1'b0;
            5'b10100,5'b10101://tlt,tlti,tltu,tltiu
                if (Trap_Less)
                    Trap = 1'b1;
                else
                    Trap = 1'b0;
            5'b10110://tne,tnei
                if (~Trap_Equal)
                    Trap = 1'b1;
                else
                    Trap = 1'b0;

            default:Trap = 1'b0;
        endcase
    end

    always@(A) begin
        casez (A)
            32'b0zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz:
                CLO_RESULT = 6'd0;
            32'b10zzzzzzzzzzzzzzzzzzzzzzzzzzzzzz:
                CLO_RESULT = 6'd1;
            32'b110zzzzzzzzzzzzzzzzzzzzzzzzzzzzz:
                CLO_RESULT = 6'd2;
            32'b1110zzzzzzzzzzzzzzzzzzzzzzzzzzzz:
                CLO_RESULT = 6'd3;
            32'b11110zzzzzzzzzzzzzzzzzzzzzzzzzzz:
                CLO_RESULT = 6'd4;
            32'b111110zzzzzzzzzzzzzzzzzzzzzzzzzz:
                CLO_RESULT = 6'd5;
            32'b1111110zzzzzzzzzzzzzzzzzzzzzzzzz:
                CLO_RESULT = 6'd6;
            32'b11111110zzzzzzzzzzzzzzzzzzzzzzzz:
                CLO_RESULT = 6'd7;
            32'b111111110zzzzzzzzzzzzzzzzzzzzzzz:
                CLO_RESULT = 6'd8;
            32'b1111111110zzzzzzzzzzzzzzzzzzzzzz:
                CLO_RESULT = 6'd9;
            32'b11111111110zzzzzzzzzzzzzzzzzzzzz:
                CLO_RESULT = 6'd10;
            32'b111111111110zzzzzzzzzzzzzzzzzzzz:
                CLO_RESULT = 6'd11;
            32'b1111111111110zzzzzzzzzzzzzzzzzzz:
                CLO_RESULT = 6'd12;
            32'b11111111111110zzzzzzzzzzzzzzzzzz:
                CLO_RESULT = 6'd13;
            32'b111111111111110zzzzzzzzzzzzzzzzz:
                CLO_RESULT = 6'd14;
            32'b1111111111111110zzzzzzzzzzzzzzzz:
                CLO_RESULT = 6'd15;
            32'b11111111111111110zzzzzzzzzzzzzzz:
                CLO_RESULT = 6'd16;
            32'b111111111111111110zzzzzzzzzzzzzz:
                CLO_RESULT = 6'd17;
            32'b1111111111111111110zzzzzzzzzzzzz:
                CLO_RESULT = 6'd18;
            32'b11111111111111111110zzzzzzzzzzzz:
                CLO_RESULT = 6'd19;
            32'b111111111111111111110zzzzzzzzzzz:
                CLO_RESULT = 6'd20;
            32'b1111111111111111111110zzzzzzzzzz:
                CLO_RESULT = 6'd21;
            32'b11111111111111111111110zzzzzzzzz:
                CLO_RESULT = 6'd22;
            32'b111111111111111111111110zzzzzzzz:
                CLO_RESULT = 6'd23;
            32'b1111111111111111111111110zzzzzzz:
                CLO_RESULT = 6'd24;
            32'b11111111111111111111111110zzzzzz:
                CLO_RESULT = 6'd25;
            32'b111111111111111111111111110zzzzz:
                CLO_RESULT = 6'd26;
            32'b1111111111111111111111111110zzzz:
                CLO_RESULT = 6'd27;
            32'b11111111111111111111111111110zzz:
                CLO_RESULT = 6'd28;
            32'b111111111111111111111111111110zz:
                CLO_RESULT = 6'd29;
            32'b1111111111111111111111111111110z:
                CLO_RESULT = 6'd30;
            32'b11111111111111111111111111111110:
                CLO_RESULT = 6'd31;
            32'b11111111111111111111111111111111:
                CLO_RESULT = 6'd32;
            default:
                CLO_RESULT = 6'd0;
        endcase
    end

    always@(A) begin
        casez (A)
            32'b1zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz:
                CLZ_RESULT = 6'd0;
            32'b01zzzzzzzzzzzzzzzzzzzzzzzzzzzzzz:
                CLZ_RESULT = 6'd1;
            32'b001zzzzzzzzzzzzzzzzzzzzzzzzzzzzz:
                CLZ_RESULT = 6'd2;
            32'b0001zzzzzzzzzzzzzzzzzzzzzzzzzzzz:
                CLZ_RESULT = 6'd3;
            32'b00001zzzzzzzzzzzzzzzzzzzzzzzzzzz:
                CLZ_RESULT = 6'd4;
            32'b000001zzzzzzzzzzzzzzzzzzzzzzzzzz:
                CLZ_RESULT = 6'd5;
            32'b0000001zzzzzzzzzzzzzzzzzzzzzzzzz:
                CLZ_RESULT = 6'd6;
            32'b00000001zzzzzzzzzzzzzzzzzzzzzzzz:
                CLZ_RESULT = 6'd7;
            32'b000000001zzzzzzzzzzzzzzzzzzzzzzz:
                CLZ_RESULT = 6'd8;
            32'b0000000001zzzzzzzzzzzzzzzzzzzzzz:
                CLZ_RESULT = 6'd9;
            32'b00000000001zzzzzzzzzzzzzzzzzzzzz:
                CLZ_RESULT = 6'd10;
            32'b000000000001zzzzzzzzzzzzzzzzzzzz:
                CLZ_RESULT = 6'd11;
            32'b0000000000001zzzzzzzzzzzzzzzzzzz:
                CLZ_RESULT = 6'd12;
            32'b00000000000001zzzzzzzzzzzzzzzzzz:
                CLZ_RESULT = 6'd13;
            32'b000000000000001zzzzzzzzzzzzzzzzz:
                CLZ_RESULT = 6'd14;
            32'b0000000000000001zzzzzzzzzzzzzzzz:
                CLZ_RESULT = 6'd15;
            32'b00000000000000001zzzzzzzzzzzzzzz:
                CLZ_RESULT = 6'd16;
            32'b000000000000000001zzzzzzzzzzzzzz:
                CLZ_RESULT = 6'd17;
            32'b0000000000000000001zzzzzzzzzzzzz:
                CLZ_RESULT = 6'd18;
            32'b00000000000000000001zzzzzzzzzzzz:
                CLZ_RESULT = 6'd19;
            32'b000000000000000000001zzzzzzzzzzz:
                CLZ_RESULT = 6'd20;
            32'b0000000000000000000001zzzzzzzzzz:
                CLZ_RESULT = 6'd21;
            32'b00000000000000000000001zzzzzzzzz:
                CLZ_RESULT = 6'd22;
            32'b000000000000000000000001zzzzzzzz:
                CLZ_RESULT = 6'd23;
            32'b0000000000000000000000001zzzzzzz:
                CLZ_RESULT = 6'd24;
            32'b00000000000000000000000001zzzzzz:
                CLZ_RESULT = 6'd25;
            32'b000000000000000000000000001zzzzz:
                CLZ_RESULT = 6'd26;
            32'b0000000000000000000000000001zzzz:
                CLZ_RESULT = 6'd27;
            32'b00000000000000000000000000001zzz:
                CLZ_RESULT = 6'd28;
            32'b000000000000000000000000000001zz:
                CLZ_RESULT = 6'd29;
            32'b0000000000000000000000000000001z:
                CLZ_RESULT = 6'd30;
            32'b00000000000000000000000000000001:
                CLZ_RESULT = 6'd31;
            32'b00000000000000000000000000000000:
                CLZ_RESULT = 6'd32;
            default:
                CLZ_RESULT = 6'd0;
        endcase
    end

endmodule
