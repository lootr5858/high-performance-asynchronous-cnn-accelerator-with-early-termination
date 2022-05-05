`include "./definitions.v"

module kernel_scale
#(
    parameter BIT_IN = 16,
    parameter BIT_SH = $clog2(BIT_IN - `BIT_DATA)
 )
(
    input clock, reset,

    input signed [BIT_IN - 1 : 0] x,
    input signed [BIT_SH - 1 : 0] scale,

    output reg signed [`BIT_DATA - 1 : 0] y
);

    always @(posedge clock or posedge reset) begin

        if (reset) y <= {`BIT_DATA{`OFF}};

        else y <= x >>> scale;

    end
    
endmodule