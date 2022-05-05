`include "./definitions.v"
`include "./kernel_max2d.v"

module layer_max2d
#(
    parameter FILTER_IN = 32
) (
    input reset,

    input signed [BIT0 - 1 : 0] xt, xf,

    output signed [BIT1 - 1 : 0] yt, yf
);

    localparam BIT0 = `BIT_DATA * `MAX2D_KSIZE * FILTER_IN;
    localparam BIT1 = `BIT_DATA * FILTER_IN;
    localparam BIT2 = `BIT_DATA * `MAX2D_KSIZE;

    wire signed [`BIT_DATA - 1 : 0] dxt [0 : FILTER_IN - 1][0 : `MAX2D_KSIZE - 1],
                                    dxf [0 : FILTER_IN - 1][0 : `MAX2D_KSIZE - 1];
    wire signed [`BIT_DATA - 1 : 0] dyt [0 : FILTER_IN - 1],
                                    dyf [0 : FILTER_IN - 1];

    wire [FILTER_IN - 1 : 0] ack_max;

    assign ack_prev = (ack_max == {FILTER_IN{`ON}}) ? `ON :
                      ((ack_max == {FILTER_IN{`OFF}}) ? `OFF : ack_prev);

    genvar i, j;

    generate

        for (i = 0; i < FILTER_IN; i = i + 1) begin

            assign yt [`BIT_DATA * (i + 1) - 1 : `BIT_DATA * i] = dyt[i];
            assign yf [`BIT_DATA * (i + 1) - 1 : `BIT_DATA * i] = dyf[i];

            kernel_max2d max2d 
            (
                .reset (reset),

                .ack_prev (ack_max [i]),
                .ack_nxt  (ack_nxt),

                .x0_t (dxt[i][0]),
                .x0_f (dxf[i][0]),
                .x1_t (dxt[i][1]),
                .x1_f (dxf[i][1]),
                .x2_t (dxt[i][2]),
                .x2_f (dxf[i][2]),
                .x3_t (dxt[i][3]),
                .x3_f (dxf[i][3]),

                .yt (dyt[i]),
                .yf (dyf[i])
            );

            for (j = 0; j < `MAX2D_KSIZE; j = j + 1) begin

                assign dxt [i][j] = xt [i * (`BIT_DATA * `MAX2D_KSIZE) + `BIT_DATA * (j + 1) - 1 : i * (`BIT_DATA * `MAX2D_KSIZE) + `BIT_DATA * j];
                assign dxf [i][j] = xf [i * (`BIT_DATA * `MAX2D_KSIZE) + `BIT_DATA * (j + 1) - 1 : i * (`BIT_DATA * `MAX2D_KSIZE) + `BIT_DATA * j];
                
            end
            
        end
        
    endgenerate
    
endmodule