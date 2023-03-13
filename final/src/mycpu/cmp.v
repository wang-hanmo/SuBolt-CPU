module cmp(
	GPR_RS,
	GPR_RT,
	
	CMPOut1,
	CMPOut2,
	CMPOut3
);
	input[31:0] GPR_RS, GPR_RT;

	output CMPOut1;
	output[3:0] CMPOut2;
	output CMPOut3;

	// always@(GPR_RS, GPR_RT)
	// 	if(|(GPR_RS ^ GPR_RT))
	// 		CMPOut1 = 1'b1;		//unequal
	// 	else
	// 		CMPOut1 = 1'b0;		//equal

	// always@(GPR_RS)
	// 	if(~( |GPR_RS))		//zero
	// 		CMPOut2 = 2'b00;
	// 	else if(GPR_RS[31])
	// 		CMPOut2 = 2'b10;	//negative
	// 	else
	// 		CMPOut2 = 2'b01;	//positive

	assign CMPOut1 = |(GPR_RS ^ GPR_RT);

	assign CMPOut2[3] = ~GPR_RS[31]; 				// >=0
	assign CMPOut2[2] = GPR_RS[31];  				// <0
	assign CMPOut2[1] = (|GPR_RS) & ~GPR_RS[31];	// >0
	assign CMPOut2[0] = ~(|GPR_RS) | GPR_RS[31];	// <=0

	assign CMPOut3 = ~( |GPR_RT);

endmodule
