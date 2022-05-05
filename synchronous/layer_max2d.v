`include "./definitions.v"
`include "./kernel_max2d.v"

module layer_max2d
#(
    parameter FILTER_IN = 32
) (
    input clock, reset,

    input signed [BIT0 - 1 : 0] x,

    output signed [BIT1 - 1 : 0] y
);

    localparam BIT0 = `BIT_DATA * `MAX2D_KSIZE * FILTER_IN;
    localparam BIT1 = `BIT_DATA * FILTER_IN;
    localparam BIT2 = `BIT_DATA * `MAX2D_KSIZE;

    wire signed [`BIT_DATA - 1 : 0] dx [0 : FILTER_IN - 1][0 : `MAX2D_KSIZE - 1];
    wire signed [`BIT_DATA - 1 : 0] dy [0 : FILTER_IN - 1];

    genvar i, j;

    generate

        for (i = 0; i < FILTER_IN; i = i + 1) begin

            assign y [`BIT_DATA * (i + 1) - 1 : `BIT_DATA * i] = dy[i];

            kernel_max2d max2d 
            (
                .clock (clock),
                .reset (reset),

                .x0 (dx[i][0]),
                .x1 (dx[i][1]),
                .x2 (dx[i][2]),
                .x3 (dx[i][3]),

                .y (dy[i])
            );

            for (j = 0; j < `MAX2D_KSIZE; j = j + 1) begin

                assign dx [i][j] = x [i * (`BIT_DATA * `MAX2D_KSIZE) + `BIT_DATA * (j + 1) - 1 : i * (`BIT_DATA * `MAX2D_KSIZE) + `BIT_DATA * j];                
            end
            
        end
        
    endgenerate
    
endmodule