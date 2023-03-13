module rf(
	input [4:0] 	Addr1,
	input [4:0] 	Addr2,
	input [4:0] 	Addr3,
	input [31:0] 	WD,
	input 			RFWr,
	input 			clk,
	input 			rst,
	output[31:0] 	RD1,
	output[31:0] 	RD2,

	output[31:0]	zero,
	output[31:0]	at,
	output[31:0]	v0,
	output[31:0]	v1,
	output[31:0]	a0,
	output[31:0]	a1,
	output[31:0]	a2,
	output[31:0]	a3,
	output[31:0]	t0,
	output[31:0]	t1,
	output[31:0]	t2,
	output[31:0]	t3,
	output[31:0]	t4,
	output[31:0]	t5,
	output[31:0]	t6,
	output[31:0]	t7,
	output[31:0]	s0,
	output[31:0]	s1,
	output[31:0]	s2,
	output[31:0]	s3,
	output[31:0]	s4,
	output[31:0]	s5,
	output[31:0]	s6,
	output[31:0]	s7,
	output[31:0]	t8,
	output[31:0]	t9,
	output[31:0]	k0,
	output[31:0]	k1,
	output[31:0]	gp,
	output[31:0]	sp,
	output[31:0]	fp,
	output[31:0]	ra
);
	reg[31:0] register[31:0];

	integer i;

	always@(posedge clk)
		if(!rst)
			for(i = 0; i <= 31; i = i + 1)
				register[i] <= 32'h0000_0000;
		else if(RFWr && Addr3 != 5'b0)
			register[Addr3] <= WD;

	assign RD1 = register[Addr1];
	assign RD2 = register[Addr2];

	assign zero = register[ 0];
	assign at = register[ 1];
	assign v0 = register[ 2];
	assign v1 = register[ 3];
	assign a0 = register[ 4];
	assign a1 = register[ 5];
	assign a2 = register[ 6];
	assign a3 = register[ 7];
	assign t0 = register[ 8];
	assign t1 = register[ 9];
	assign t2 = register[10];
	assign t3 = register[11];
	assign t4 = register[12];
	assign t5 = register[13];
	assign t6 = register[14];
	assign t7 = register[15];
	assign s0 = register[16];
	assign s1 = register[17];
	assign s2 = register[18];
	assign s3 = register[19];
	assign s4 = register[20];
	assign s5 = register[21];
	assign s6 = register[22];
	assign s7 = register[23];
	assign t8 = register[24];
	assign t9 = register[25];
	assign k0 = register[26];
	assign k1 = register[27];
	assign gp = register[28];
	assign sp = register[29];
	assign fp = register[30];
	assign ra = register[31];

endmodule
