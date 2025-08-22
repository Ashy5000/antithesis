module vram #(
	parameter size,
	parameter address_width,
) (
	input clk,
	input [address_width:0] addr,
	input [7:0] in,
	output [7:0] out,
	input write,
);

reg [address_width:0]mem[0:size - 1];

always @(posedge clk) begin
	if (write)
		mem[addr] <= in;
	else
		out <= mem[addr];
end
