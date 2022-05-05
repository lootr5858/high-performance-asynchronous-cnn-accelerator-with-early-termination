`include "./definitions.v"
`include "./kernel_conv2d.v"
`include "./kernel_scale.v"
`include "./kernel_relu.v"

module layer_convolution
#(
    parameter FILTER_IN  = 8,
    parameter FILTER_OUT = 16,
    parameter BIT_IN     = 1024,
    parameter BIT_OUT    = 256,
    parameter BIT_SCALE  = 4
)
(
    input clock, reset, load,

    input [$clog2(FILTER_OUT) - 1 : 0] addr,

    input signed [BIT_IN - 1 : 0] x, w,
    input signed [BIT_SCALE - 1 : 0] scale,

    output signed [BIT_OUT - 1 : 0] z
);

    localparam BIT0 = (`BIT_DATA * 2) + $clog2(`CONV2D_KSIZE - 1); // bit width of conv2d kernel
    localparam BIT1 = BIT0 + $clog2(FILTER_IN - 1); // bit width of conv2d filter
    localparam BIT_KERNEL = `BIT_DATA * `CONV2D_KSIZE;

    wire signed [BIT_KERNEL      - 1 : 0] dx [0 : FILTER_IN - 1];
    wire signed [BIT_KERNEL      - 1 : 0] dw [0 : FILTER_OUT - 1][0 : FILTER_IN - 1];
    wire signed [BIT0   - 1 : 0] y0 [0 : FILTER_OUT - 1][0 : FILTER_IN - 1];
    wire signed [`BIT_DATA - 1 : 0] y2 [0 : FILTER_OUT - 1];

    reg signed [BIT_IN - 1 : 0] ww [0 : FILTER_OUT - 1];
    reg signed [BIT1 - 1 : 0] y1 [0 : FILTER_OUT - 1][0 : FILTER_IN - 2];

    genvar  i, j, k, l;
    integer rw, ryi, ryj, cyi, cyj;

    always @(posedge clock or posedge reset) begin

        if (reset) begin

            for (rw = 0; rw < FILTER_OUT; rw = rw + 1) ww[rw] <= {BIT_IN{`OFF}};
                
            for (ryi = 0; ryi < FILTER_OUT - 1; ryi = ryi + 1) begin

                for (ryj = 0; ryj < FILTER_IN - 1; ryj = ryi + 1) y1[ryi][ryj] <= {BIT1{`OFF}};

            end
            
        end

        else if (load) ww[addr] <= w;

        else begin

            for (cyi = 0; cyi < FILTER_OUT - 1; cyi = cyi + 1) begin
    
                for (cyj = 0; cyj < FILTER_IN - 1; cyj = cyj + 1) begin

                    if (cyj < (FILTER_IN / 2)) y1 [cyi][cyj] <= y0 [cyi][cyj * 2] + y0 [cyi][cyj * 2 + 1];
                    else                       y1 [cyi][cyj] <= y1 [cyi][(cyj - (FILTER_IN / 2)) * 2] + y1 [cyi][(cyj - (FILTER_IN / 2)) * 2 + 1];
                    
                end

            end
            
        end
        
    end

    generate

        for (k = 0; k < FILTER_IN; k = k + 1) begin
            
            assign dx[k] =  x[BIT_KERNEL * (k + 1) - 1 : BIT_KERNEL * k];
            
            for (l = 0; l < FILTER_OUT; l = l + 1 ) assign dw[l][k] = ww[l][BIT_KERNEL * (k + 1) - 1 : BIT_KERNEL * k];

        end
        
    endgenerate

    generate

        for (i = 0; i < FILTER_OUT; i = i + 1) begin

            for (j = 0; j < FILTER_IN; j = j + 1) begin

                kernel_conv2d conv2d
                (
                    .clock (clock),
                    .reset (reset),

                    .x (dx[j]),
                    .w (dw[i][j]),
                    .y (y0[i][j])
                );
                
            end

            kernel_scale #(.BIT_IN (BIT1),
                           .BIT_SH (BIT_SCALE)) scale 
            (
                .clock (clock),
                .reset (reset),

                .x (y1[i][FILTER_IN - 2]),
                .y (y2[i])
            );

            kernel_relu relu 
            (
                .clock (clock),
                .reset (reset),
                
                .x (y2[i]),
                .y (z[`BIT_DATA * (i + 1) - 1 : `BIT_DATA * i])
            );
            
        end
        
    endgenerate
    
endmodule
