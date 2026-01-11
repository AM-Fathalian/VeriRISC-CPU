
module counter #(
parameter int WIDTH = 5
)(
input logic [WIDTH-1:0] data,
input logic load,
input logic enable,
input logic clk,
input logic rst_,
output logic [WIDTH-1:0] count
);

timeunit 1ns;
timeprecision 100ps;


	always_ff @(posedge clk or negedge rst_)
	begin
		if (!rst_)
			count <= '0;
		else begin
			if (load)
				count <= data;
			else if (enable)
				count++;
			//else :: the counter remains unchanged.
		end	
	end
	
endmodule