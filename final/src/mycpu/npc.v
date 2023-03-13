module npc(
	ret_addr, NPCOp, NPC_op00, NPC_op01, NPC_op10, flush_condition_00, flush_condition_01,
	flush_condition_10, flush_condition_11, target_addr_final, 
	ee, NPC_ee,

	Instr_Flush, NPC
	);

	input [31:0] 		ret_addr;
	input [1:0] 		NPCOp;
	input [31:0]		NPC_op00;
    input [31:0] 		NPC_op01;
    input [31:0] 		NPC_op10;
    input 				flush_condition_00;
    input 				flush_condition_01;
    input 				flush_condition_10;
    input 				flush_condition_11;
	input [31:0]		target_addr_final;
    input 				ee;
    input [31:0] 		NPC_ee;

	output reg [31:0] 	NPC;
	output 				Instr_Flush;

	reg [31:0] 			NPC_temp;
	reg 				branch_error;

	always@(NPCOp, NPC_op00, NPC_op01, NPC_op10, ret_addr) begin
			case(NPCOp)
				2'b00:	NPC_temp = NPC_op00;								//sequential execution
				2'b01:	NPC_temp = NPC_op01;								//branch
				2'b10:	NPC_temp = NPC_op10;								//jump
				default:NPC_temp = ret_addr;								//jump return
			endcase
	end

	always@(ee, NPC_ee, branch_error, NPC_temp, target_addr_final) begin
		if (ee) begin
			NPC = NPC_ee;
		end
		else if (branch_error) begin
			NPC = NPC_temp;
		end
		else begin
			NPC = target_addr_final;
		end
	end

	always@(NPCOp, flush_condition_00, flush_condition_01, flush_condition_10, flush_condition_11)
		case(NPCOp)
			2'b00:	branch_error = flush_condition_00;
			2'b01:	branch_error = flush_condition_01;
			2'b10:	branch_error = flush_condition_10;
			default:branch_error = flush_condition_11;
		endcase

	assign Instr_Flush = branch_error | ee;
	
endmodule


module flush(
	MEM1_ee, can_go,

	PC_Flush,PF_Flush,IF_Flush,ID_Flush,
	EX_Flush,MEM1_Flush,MEM2_Flush
	);
	input 			MEM1_ee;
	input 			can_go;

	output 			IF_Flush;
	output 			ID_Flush;
	output 			EX_Flush;
	output 			PC_Flush;
	output 			MEM1_Flush;
	output 			MEM2_Flush;
	output 			PF_Flush;

	assign IF_Flush =  MEM1_ee ;
	assign ID_Flush = MEM1_ee ;
	assign EX_Flush = MEM1_ee ;
	assign MEM1_Flush = MEM1_ee &can_go;
	assign PC_Flush = 1'b0 ;
	assign MEM2_Flush = 1'b0;
	assign PF_Flush = 1'b0 ;

endmodule