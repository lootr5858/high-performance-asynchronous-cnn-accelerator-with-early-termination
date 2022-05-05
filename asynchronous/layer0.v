`include "./definitions.v"
`include "./kernel_conv2d.v"
`include "./kernel_scale.v"
`include "./kernel_relu.v"

module layer0 (
    input clock, reset, load,

    output ack_prev,
    input  ack_nxt,

    input signed [`BIT_INL0 - 1 : 0] xt, xf, w,
    input signed [`BIT_S0 - 1 : 0] scale,

    output signed [`BIT_L0B0 - 1 : 0] z
);

    localparam BIT0 = `BIT_DATA * 2 + $clog2(`CONV2D_KSIZE - 1);

    wire signed [BIT0      - 1 : 0] yt0 [0 : `FILTER_L0 - 1],
                                    yf0 [0 : `FILTER_L0 - 1];
    wire signed [`BIT_DATA - 1 : 0] yt1 [0 : `FILTER_L0 - 1],
                                    yf1 [0 : `FILTER_L0 - 1];

    wire [`FILTER_L0 - 1 : 0] ack_conv_prev, ack_conv_scale, ack_scale_relu;

    reg signed [`BIT_INL0 - 1 : 0] dw [0 : `FILTER_L0];

    genvar i;
    integer rw, sw;

    assign ack_prev = (ack_conv_prev == {`FILTER_L0{`ON}}) ? `ON :
                      ((ack_conv_prev == {`FILTER_L0{`OFF}}) ? `OFF : 
                      ack_prev);

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
                .reset (reset),

                .ack_prev (ack_conv_prev  [i]),
                .ack_nxt  (ack_conv_scale [i]),

                .xt (xt),
                .xf (xf),
                .w  (dw[i]),

                .yt (yt0 [i]),
                .yf (yf0 [i])
            );

            kernel_scale #(.BIT_IN (BIT0),
                           .BIT_SH (`BIT_S0)) scale
            (
                .reset (reset),

                .ack_prev (ack_conv_scale [i]),
                .ack_nxt  (ack_scale_relu [i]),

                .xt (yt0 [i]),
                .xf (yf0 [i]),
                .scale (scale),
                
                .yt (yt1 [i]),
                .yf (yf1 [i])
            );

            kernel_relu relu
            (
                .reset (reset),

                .ack_prev (ack_scale_relu [i]),
                .ack_nxt  (ack_nxt),

                .xt (yt1 [i]),
                .xf (yf1 [i]),
                .yt (zt[`BIT_DATA * (i + 1) - 1 : `BIT_DATA * i]),
                .yf (zf[`BIT_DATA * (i + 1) - 1 : `BIT_DATA * i])
            );
            
        end
        
    endgenerate    
    
endmodule