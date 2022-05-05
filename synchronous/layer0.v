`include "./definitions.v"
`include "./kernel_conv2d.v"
`include "./kernel_scale.v"
`include "./kernel_relu.v"

module layer0 (
    input clock, reset, load,

    input signed [`BIT_INL0 - 1 : 0] x, w,
    input signed [`BIT_S0 - 1 : 0] scale,

    output signed [`BIT_L0B0 - 1 : 0] z
);

    localparam BIT0 = `BIT_DATA * 2 + $clog2(`CONV2D_KSIZE - 1);

    wire signed [BIT0      - 1 : 0] y0 [0 : `FILTER_L0 - 1];
    wire signed [`BIT_DATA - 1 : 0] y1 [0 : `FILTER_L0 - 1];

    reg signed [`BIT_INL0 - 1 : 0] dw [0 : `FILTER_L0];

    genvar i;
    integer rw, sw;

    always @(posedge clock or posedge reset) begin

        if (reset) begin

            for (rw = 0; rw < `FILTER_L0; rw = rw + 1) dw [rw] <= {`BIT_INL0{`OFF}};
            
        end

        else if (load) begin

            for (sw = 0; sw < `FILTER_L0; sw = sw + 1) dw [sw] <= w;
            
        end

        else dw[0] <= dw[0];
        
    end

    generate

        for (i = 0; i < `FILTER_L0; i = i + 1) begin

            kernel_conv2d conv2d
            (
                .clock (clock),
                .reset (reset),

                .x (x),
                .w (dw[i]),

                .y (y0[i])
            );

            kernel_scale #(.BIT_IN (BIT0),
                           .BIT_SH (`BIT_S0)) scale
            (
                .clock (clock),
                .reset (reset),

                .x (y0[i]),
                .scale (scale),
                
                .y (y1[i])
            );

            kernel_relu relu
            (
                .clock (clock),
                .reset (reset),

                .x (y1[i]),
                .y (z[`BIT_DATA * (i + 1) - 1 : `BIT_DATA * i])
            );
            
        end
        
    endgenerate    
    
endmodule