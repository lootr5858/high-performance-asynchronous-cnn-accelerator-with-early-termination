`include "./definitions.v"

module kernel_dense
#(
    parameter BIT_OUT    = `BIT_DATA * `DENSE_KSIZE
 )
(
    input clock, reset,

    input signed [`BIT_DATA - 1 : 0] x,
    input signed [BIT_OUT   - 1 : 0] w,

    output signed [BIT_OUT * 2 - 1 : 0] y
);

    localparam BITm = `BIT_DATA * 2;

    wire signed [`BIT_DATA - 1 : 0] dw [0 : `DENSE_KSIZE - 1];

    reg signed [BITm - 1 : 0] dy [0 : `DENSE_KSIZE - 1];

    genvar i;

    generate

        for (i = 0; i < `DENSE_KSIZE; i = i + 1) begin
            
            assign dw [i] = w [`BIT_DATA * (i + 1) - 1 : `BIT_DATA * i];

            assign y [BITm * (i + 1) - 1 : BITm * i] = dy [i];

        end
        
    endgenerate

    integer ry, cy;

    always @(posedge clock or posedge reset) begin
 
        if (reset) begin

            for (ry = 0; ry < `DENSE_KSIZE; ry = ry + 1) dy [ry] <= {BITm{`OFF}};
            
        end

        else begin

            for (cy = 0; cy < `DENSE_KSIZE; cy = cy + 1) dy [cy] <= x * dw [cy];
            
        end
        
    end
    
endmodule