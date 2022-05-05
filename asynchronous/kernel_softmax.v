`include "./definitions.v"
`include "./handshake2.v"
`include "./handshake3.v"

module kernel_softmax
(
    input reset,

    output ack_prev,
    input  ack_nxt,

    input signed [`BIT_DATA * `DENSE_KSIZE - 1 : 0] xt, xf,

    output reg signed [`BIT_SOFTMAX * `DENSE_KSIZE - 1 : 0] yt, yf
);

    wire [`BIT_DATA    - 1 : 0] dxt  [0 : `DENSE_KSIZE - 1],
                                dxf  [0 : `DENSE_KSIZE - 1];
    wire [`BIT_SOFTMAX - 1 : 0] cxt  [0 : `DENSE_KSIZE - 1],
                                cxf  [0 : `DENSE_KSIZE - 1],
                                cst  [0 : `DENSE_KSIZE - 2],
                                csf  [0 : `DENSE_KSIZE - 2],
                                cyt  [0 : `DENSE_KSIZE - 1],
                                cyf  [0 : `DENSE_KSIZE - 1];

    wire [`DENSE_KSIZE - 1 : 0] ack_px_prev;
    wire                        ack_px_nxt;
    wire [`DENSE_KSIZE - 1 : 0] ack_dy_prev, ack_dy_nxt,
                                inv_px, inv_dy;
    wire [`DENSE_KSIZE - 2 : 0] ack_sum_prev, ack_sum_nxt,
                                inv_sum;

    reg  [`BIT_SOFTMAX - 1 : 0] pxt  [0 : `DENSE_KSIZE - 1],
                                pxf  [0 : `DENSE_KSIZE - 1],
                                sumt [0 : `DENSE_KSIZE - 2],
                                sumf [0 : `DENSE_KSIZE - 2];

    assign ack_prev = (ack_dy_prev == {`DENSE_KSIZE{`ON}}) ? `ON
                                                           : ((ack_dy_prev == {`DENSE_KSIZE{`OFF}}) ? `OFF
                                                                                                    : ack_prev);

    genvar i, j;

    assign ack_px_nxt = (ack_sum_prev == {(`DENSE_KSIZE - 1){`ON}}) ? `ON
                        : ((ack_sum_prev == {(`DENSE_KSIZE - 1){`OFF}}) ? `OFF
                        : ack_px_nxt);

    generate

        for (i = 0; i < `DENSE_KSIZE; i = i + 1) begin

            assign dxt [i] = xt [`BIT_DATA * (i + 1) - 1 : `BIT_DATA * i];
            assign dxf [i] = xf [`BIT_DATA * (i + 1) - 1 : `BIT_DATA * i];

            assign cxt [i] = 2 ** dxt [i];
            assign cxf [i] = inv_px[i] ? ~pxt[i] : {`BIT_SOFTMAX{`OFF}};

            handshake2 #(.BIT0 (`BIT_DATA),
                        .BIT1 (`BIT_SOFTMAX)) handshake_power
            (
                .reset (reset),

                .dt_0 (dxt [i]),
                .df_0 (dxf [i]),
                .dt_1 (cxt [i]),
                .df_1 (cxf [i]),

                .inv      (inv_px [i]),
                .ack_prev (ack_px_prev [i]),
                .ack_nxt  (ack_px_nxt)
            );

            always @(posedge ack_px_prev [i] or posedge (reset | ~ack_px_prev [i])) begin

                if (reset | ~ack_px_prev [i]) begin

                    pxt [i] <= {`BIT_SOFTMAX{`OFF}};
                    pxf [i] <= {`BIT_SOFTMAX{`OFF}};
                    
                end

                else begin

                    pxt [i] <= cxt [i];
                    pxf [i] <= cxf [i];
                    
                end
                
            end

            assign cyt [i] = pxt [i] / sumt [`DENSE_KSIZE - 2];
            assign cyf [i] = inv_dy [i] ? ~cyt [i] : {`BIT_SOFTMAX{`OFF}};

            handshake3 #(.BIT0 (`BIT_SOFTMAX),
                         .BIT1 (`BIT_SOFTMAX),
                         .BIT2 (`BIT_SOFTMAX)) handshake_y
            (
                .reset (reset),

                .dt_0 (pxt [i]),
                .df_0 (pxf [i]),
                .dt_1 (sumt [`DENSE_KSIZE - 2]),
                .df_1 (sumt [`DENSE_KSIZE - 2]),
                .dt_2 (cyt [i]),
                .df_2 (cyf [i]),

                .inv      (inv_dy [i]),
                .ack_prev (ack_dy_prev [i]),
                .ack_nxt  (ack_dy_nxt [i])
            );

            always @(posedge ack_px_prev [i] or posedge (reset | ~ack_dy_prev[i])) begin

                if (reset | ~ack_dy_prev[i]) begin

                    yt [i] <= {`BIT_SOFTMAX{`OFF}};
                    yf [i] <= {`BIT_SOFTMAX{`OFF}};
                    
                end

                else begin

                    yt [i] <= cyt [i];
                    yf [i] <= cyf [i];
                    
                end
                
            end
            
        end
        
    endgenerate

    generate

        for (j = 0; j < `DENSE_KSIZE - 1; j = j + 1) begin

            assign csf [j] = inv_sum [j] ? ~cst [j] : {`BIT_SOFTMAX{`OFF}};

            always @(posedge ack_sum_prev [j] or posedge (reset | ~ack_sum_prev [j])) begin
                
                if (reset | ~ack_sum_prev [j]) begin

                    sumt [j] <= {`BIT_SOFTMAX{`OFF}};
                    sumf [j] <= {`BIT_SOFTMAX{`OFF}};
                    
                end

                else begin

                    sumt [j] <= cst [j];
                    sumf [j] <= csf [j];
                    
                end

            end

            if (j < (`DENSE_KSIZE / 2)) begin

                assign cst [j] = pxt [j * 2] + pxt [j * 2 + 1];

                handshake3 #(.BIT0 (`BIT_SOFTMAX),
                             .BIT1 (`BIT_SOFTMAX),
                             .BIT2 (`BIT_SOFTMAX)) handshake_sm
                (
                    .reset (reset),
                    
                    .dt_0 (pxt [j * 2]),
                    .df_0 (pxf [j * 2]),
                    .dt_1 (pxt [j * 2 + 1]),
                    .df_1 (pxf [j * 2 + 1]),
                    .dt_2 (cst [j]),
                    .df_2 (csf [j]),

                    .inv      (inv_sum [j]),
                    .ack_prev (ack_sum_prev [j]),
                    .ack_nxt  (ack_sum_nxt  [j])
                );
                
            end

            else if (j < `DENSE_KSIZE - 2) begin

                assign cst [j] = cst [(j - (`DENSE_KSIZE / 2)) * 2] + cst [(j - (`DENSE_KSIZE / 2)) * 2 + 1];

                handshake3 #(.BIT0 (`BIT_SOFTMAX),
                             .BIT1 (`BIT_SOFTMAX),
                             .BIT2 (`BIT_SOFTMAX)) handshake_ss
                (
                    .reset (reset),
                    
                    .dt_0 (cst [(j - (`DENSE_KSIZE / 2)) * 2]),
                    .df_0 (csf [(j - (`DENSE_KSIZE / 2)) * 2]),
                    .dt_1 (cst [(j - (`DENSE_KSIZE / 2)) * 2 + 1]),
                    .df_1 (csf [(j - (`DENSE_KSIZE / 2)) * 2 + 1]),
                    .dt_2 (cst [j]),
                    .df_2 (csf [j]),

                    .inv      (inv_sum [j]),
                    .ack_prev (ack_sum_prev [j]),
                    .ack_nxt  (ack_sum_nxt  [j])
                );
                
            end

            else begin

                assign cst [j] = cst [j - 1] + cst [j - 2];

                handshake3 #(.BIT0 (`BIT_SOFTMAX),
                             .BIT1 (`BIT_SOFTMAX),
                             .BIT2 (`BIT_SOFTMAX)) handshake_ss
                (
                    .reset (reset),
                    
                    .dt_0 (cst [j - 1]),
                    .df_0 (csf [j - 1]),
                    .dt_1 (cst [j - 2]),
                    .df_1 (csf [j - 2]),
                    .dt_2 (cst [j]),
                    .df_2 (csf [j]),

                    .inv      (inv_sum [j]),
                    .ack_prev (ack_sum_prev [j]),
                    .ack_nxt  (ack_sum_nxt  [j])
                );
                
            end
            
        end
        
    endgenerate   
    
endmodule