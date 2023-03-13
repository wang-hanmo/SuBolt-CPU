module rf(
	Addr1, Addr2, Addr3, WD, RFWr, clk, rst,
	
	RD1, RD2
);
	input[4:0] Addr1, Addr2, Addr3;
	input[31:0] WD;
	input RFWr, clk, rst;
	output[31:0] RD1, RD2;
	reg[31:0] register[31:0];

	integer i;

	always@(posedge clk)
		if(!rst)
			for(i = 0; i <= 31; i = i + 1)
				register[i] <= 32'h0000_0000;
		else if(RFWr)
			register[Addr3] <= WD;

	assign RD1 = register[Addr1];
	assign RD2 = register[Addr2];


endmodule
