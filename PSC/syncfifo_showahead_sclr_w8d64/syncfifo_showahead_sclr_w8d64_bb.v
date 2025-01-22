
module syncfifo_showahead_sclr_w8d64 (
	data,
	wrreq,
	rdreq,
	clock,
	sclr,
	q,
	usedw,
	full,
	empty,
	almost_empty);	

	input	[7:0]	data;
	input		wrreq;
	input		rdreq;
	input		clock;
	input		sclr;
	output	[7:0]	q;
	output	[5:0]	usedw;
	output		full;
	output		empty;
	output		almost_empty;
endmodule
