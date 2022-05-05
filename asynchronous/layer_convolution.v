`include "./definitions.v"
`include "./kernel_conv2d.v"
`include "./kernel_scale.v"
`include "./kernel_relu.v"
`include "./handshake3.v"

module layer_convolution
#(
    parameter FILTER_IN  = 8,
    parameter FILTER_OUT = 16,
    parameter BIT_IN     = 1024,
    parameter BIT_OUT    = 256,
    parameter BIT_SCALE  = 4
)
(
    input clock,           // for initialisation
          reset, load,

    output ack_prev,
    input  ack_nxt,

    input [$clog2(FILTER_OUT) - 1 : 0] addr,

    input signed [BIT_IN - 1 : 0] xt, xf, w,
    input signed [BIT_SCALE - 1 : 0] scale,

    output signed [BIT_OUT - 1 : 0] zt, zf
);

    localparam BIT0 = (`BIT_DATA * 2) + $clog2(`CONV2D_KSIZE - 1); // bit width of conv2d kernel
    localparam BIT1 = BIT0 + $clog2(FILTER_IN - 1); // bit width of conv2d filter
    localparam BIT_KERNEL = `BIT_DATA * `CONV2D_KSIZE;

    wire signed [BIT_KERNEL - 1 : 0] dxt [0 : FILTER_IN - 1],
                                    dxf [0 : FILTER_IN - 1],
                                    dw [0 : FILTER_OUT - 1][0 : FILTER_IN - 1];
    wire signed [BIT0       - 1 : 0] yt0 [0 : FILTER_OUT - 1][0 : FILTER_IN - 1],
                                     yf0 [0 : FILTER_OUT - 1][0 : FILTER_IN - 1];
    wire signed [BIT1       - 1 : 0] ct1 [0 : FILTER_OUT - 1][0 : FILTER_IN - 2],
                                     cf1 [0 : FILTER_OUT - 1][0 : FILTER_IN - 2];
    wire signed [`BIT_DATA - 1 : 0]  yt2 [0 : FILTER_OUT - 1],
                                     yf2 [0 : FILTER_OUT - 1];

    wire [FILTER_IN * FILTER_OUT - 1 : 0] ack_conv_prev,
                                          ack_y1_prev;
    wire [FILTER_OUT             - 1 : 0] ack_y1_y2, ack_y2_z, ack_z_nxt;
    wire                                  ack_conv_nxt;

    reg signed [BIT_IN - 1 : 0] ww [0 : FILTER_OUT - 1];
    reg signed [BIT1 - 1 : 0] yt1 [0 : FILTER_OUT - 1][0 : FILTER_IN - 2],
                              yf1 [0 : FILTER_OUT - 1][0 : FILTER_IN - 2];

    genvar  i, j, k, l;
    integer rw, ryi, ryj, cyi, cyj;

    assign ack_prev = (ack_conv_prev ==  {(FILTER_IN * FILTER_OUT){`ON}}  ? `ON   :
                                        ({(FILTER_IN * FILTER_OUT){`OFF}}) ? `OFF : ack_prev);
    assign ack_conv_nxt = (ack_y1_prev ==  {(FILTER_IN * FILTER_OUT){`ON}}  ? `ON   :
                                        ({(FILTER_IN * FILTER_OUT){`OFF}}) ? `OFF : ack_conv_prev);

    always @(posedge clock or posedge reset) begin

        if (reset) begin

            for (rw = 0; rw < FILTER_OUT; rw = rw + 1) ww[rw] <= {BIT_IN{`OFF}};
            
        end

        else if (load) ww[addr] <= w;

        else ww[0] <= ww[0];
        
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
                    .reset (reset),

                    .ack_prev (ack_conv_prev [i * FILTER_IN + j]),
                    .ack_nxt  (ack_conv_nxt),

                    .xt (dxt[j]),
                    .xf (dxf[j]),
                    .w  (dw[i][j]),
                    .yt (yt0[i][j]),
                    .yf (yf0[i][j])
                );   

                always @(posedge ack_y1_prev [i * FILTER_IN + j] or posedge (reset | ~ack_y1_prev [i * FILTER_IN + j])) begin

                    if (reset | ~ack_y1_prev [i * FILTER_IN + j]) begin

                        yt1 [i][j] <= {BIT1{`OFF}};
                        yf1 [i][j] <= {BIT1{`OFF}};
                        
                    end

                    else begin

                        yt1 [i][j] <= ct1 [i][j];
                        yf1 [i][j] <= cf1 [i][j];
                        
                    end
                    
                end             

                if (i < (FILTER_IN / 2)) begin
                    
                    assign ct1 [i][j] = yt0 [i][j * 2] + yt0 [i][j * 2 + 1];

                    handshake3 #(.BIT0 (BIT0),
                                 .BIT1 (BIT0),
                                 .BIT2 (BIT1)) handshake_sum
                    (
                        .reset (reset),

                        .dt_0 (yt0[i][j * 2]),
                        .df_0 (yf0[i][j * 2]),
                        .dt_1 (yt0[i][j * 2 + 1]),
                        .df_1 (yf0[i][j * 2 + 1]),
                        .dt_2 (ct1[i][j]),
                        .df_2 (cf1[i][j]),

                        .ack_prev (ack_y1_prev [i * FILTER_IN + j]),
                        .ack_nxt  (ack_y1_prev [i * FILTER_IN + j + FILTER_OUT] & 
                                   ack_y1_prev [i * FILTER_IN + j + FILTER_OUT + 1])
                    );                  

                end

                else begin
                
                    assign ct1 [i][j] = ct1 [i][j - (FILTER_IN / 2)] + ct1 [i][j - (FILTER_IN / 2) + 1];

                    handshake3 #(.BIT0 (BIT1),
                                 .BIT1 (BIT1),
                                 .BIT2 (BIT1)) handshake_sum
                    (
                        .reset (reset),

                        .dt_0 (ct1 [i][j - (FILTER_IN / 2)]),
                        .df_0 (cf1 [i][j - (FILTER_IN / 2)]),
                        .dt_1 (ct1 [i][j - (FILTER_IN / 2) + 1]),
                        .df_1 (cf1 [i][j - (FILTER_IN / 2) + 1]),
                        .dt_2 (ct1[i][j]),
                        .df_2 (cf1[i][j]),

                        .ack_prev (ack_y1_prev [i * FILTER_IN + j]),
                        .ack_nxt  (ack_y1_y2 [i])
                    );
                
                end
            
            end            

            kernel_scale #(.BIT_IN (BIT1),
                           .BIT_SH (BIT_SCALE)) scale 
            (
                .reset (reset),

                .ack_prev (ack_y1_y2 [i]),
                .ack_nxt  (ack_y2_z [i]),

                .xt (yt1 [i][0 : FILTER_IN - 2]),
                .xf (yf1 [i][0 : FILTER_IN - 2]),
                .yt (yt2 [i]),
                .yf (yf2 [i])
            );

            kernel_relu relu 
            (
                .reset (reset),

                .ack_prev (ack_y2_z  [i]),
                .ack_nxt  (ack_z_nxt [i]),
                
                .xt (yt2 [i]),
                .xf (yf2 [i]),
                .yt (zt[`BIT_DATA * (i + 1) - 1 : `BIT_DATA * i]),
                .yf (zf[`BIT_DATA * (i + 1) - 1 : `BIT_DATA * i])
            );
            
        end
        
    endgenerate
    
endmodule
