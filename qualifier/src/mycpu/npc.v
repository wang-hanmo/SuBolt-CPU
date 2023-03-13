module npc(
	ret_addr, NPCOp, NPC_op00, NPC_op01, NPC_op10, flush_condition_00, flush_condition_01,
	flush_condition_10, flush_condition_11, target_address_final, predict_final,
	ee, NPC_ee,

	flush_signal_PF, NPC, predict,
	EX_isBranch, EX_stall, EX_MUX7Sel, IF_stall, clk, rst
	);

	input[31:0] ret_addr;
	input[1:0] NPCOp;
	input[31:0] NPC_op00;
    input[31:0] NPC_op01;
    input[31:0] NPC_op10;
    input flush_condition_00;
    input flush_condition_01;
    input flush_condition_10;
    input flush_condition_11;
    input[31:0] target_address_final;
    input predict_final;
    input ee;
    input[31:0] NPC_ee;
	input EX_isBranch, EX_stall, EX_MUX7Sel, IF_stall, clk, rst;

	output reg[31:0] NPC;
	output flush_signal_PF;
	output reg predict;

	reg [31:0] NPC_temp;
	reg flush_signal_temp;

	always@(NPCOp, NPC_op00, NPC_op01, NPC_op10, ret_addr) begin
			case(NPCOp)
				2'b00:	NPC_temp = NPC_op00;								//sequential execution
				2'b01:	NPC_temp = NPC_op01;								//branch
				2'b10:	NPC_temp = NPC_op10;								//jump
				default:NPC_temp = ret_addr;								//jump return
			endcase
	end

	always@(ee, NPC_ee, flush_signal_temp, NPC_temp, target_address_final, predict_final) begin
		if (ee) begin
			NPC = NPC_ee;
			predict = 1'b0;
		end
		else if (flush_signal_temp) begin
			NPC = NPC_temp;
			predict = 1'b0;
		end
		else begin
			NPC = target_address_final;
			predict = predict_final;
		end
	end

	always@(NPCOp, flush_condition_00, flush_condition_01, flush_condition_10, flush_condition_11)
		case(NPCOp)
			2'b00:	flush_signal_temp = flush_condition_00;
			2'b01:	flush_signal_temp = flush_condition_01;
			2'b10:	flush_signal_temp = flush_condition_10;
			default:flush_signal_temp = flush_condition_11;
		endcase

	assign flush_signal_PF = flush_signal_temp| ee;

	reg [31:0] total;
	reg [31:0] fail;

	always @(posedge clk) begin
		if (!rst)
			total <= 32'd0;
		else if (EX_isBranch && ~EX_MUX7Sel && ~EX_stall)
			total <= total + 1;
	end

	always @(posedge clk) begin
		if (!rst)
			fail <= 32'd0;
		else if (flush_signal_temp && ~IF_stall)
			fail <= fail + 1;
	end	
	
endmodule

module flush(MEM_eret_flush, MEM_ex, NPCOp, PCWr, can_go,
		PC_Flush,PF_Flush,IF_Flush,ID_Flush,EX_Flush,MEM1_Flush,MEM2_Flush);
	input[1:0] NPCOp;
	input PCWr;
	input MEM_eret_flush;
	input MEM_ex;
	input can_go;

	output IF_Flush;
	output ID_Flush;
	output EX_Flush;
	output PC_Flush;
	output MEM1_Flush;
	output MEM2_Flush;
	output PF_Flush;

	assign IF_Flush =  (MEM_eret_flush | MEM_ex) ;
	assign ID_Flush = (MEM_eret_flush | MEM_ex) ;
	assign EX_Flush = (MEM_eret_flush | MEM_ex) ;
	assign MEM1_Flush = (MEM_eret_flush | MEM_ex) &can_go;
	assign PC_Flush = 1'b0 ;
	assign MEM2_Flush = 1'b0;
	assign PF_Flush = 1'b0 ;

endmodule