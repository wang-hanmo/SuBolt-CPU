module cmp(
	GPR_RS, 
	GPR_RT, 
	CMPOut1, 
	CMPOut2
);
	input[31:0] GPR_RS, GPR_RT;

	output reg CMPOut1;
	output reg[1:0] CMPOut2;

	always@(GPR_RS, GPR_RT)
		if(|(GPR_RS ^ GPR_RT))
			CMPOut1 = 1'b1;		//unequal
		else
			CMPOut1 = 1'b0;		//equal

	always@(GPR_RS)
		if(~( |GPR_RS))		//zero
			CMPOut2 = 2'b00;
		else if(GPR_RS[31])
			CMPOut2 = 2'b10;	//negative
		else
			CMPOut2 = 2'b01;	//positive

endmodule
