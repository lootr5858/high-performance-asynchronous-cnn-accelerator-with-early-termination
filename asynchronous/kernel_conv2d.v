`include "./definitions.v"
`include "./handshake2.v"
`include "./handshake3.v"

module kernel_conv2d
(
    input reset,

    output ack_prev,
    input  ack_nxt,

    input signed [`BIT_DATA * `CONV2D_KSIZE - 1 : 0] xt, xf, w,

    output reg signed [BIT2 - 1 : 0] yt, yf
);

    localparam BIT1 = `BIT_DATA * 2;
    localparam BIT2 = BIT1 + $clog2(`CONV2D_KSIZE - 1);
    localparam SADD = `CONV2D_KSIZE - 2;

    wire signed [`BIT_DATA - 1 : 0] dxt    [0 : `CONV2D_KSIZE - 1],
                                    dxf    [0 : `CONV2D_KSIZE - 1],
                                    dw     [0 : `CONV2D_KSIZE - 1];
    wire signed [BIT1      - 1 : 0] cmul_t [0 : `CONV2D_KSIZE - 1],
                                    cmul_f [0 : `CONV2D_KSIZE - 1];
    wire signed [BIT2      - 1 : 0] cadd_t [0 : SADD - 1],
                                    cadd_f [0 : SADD - 1],
                                    cyt, cyf;

    wire [0 : `CONV2D_KSIZE - 1] ack_mul_prev, ack_mul_nxt, inv_mul;
    wire [0 : `CONV2D_KSIZE - 3] ack_add_prev , ack_add_nxt, inv_add;
    wire                         ack_mul_add,
                                 ack_y_prev, ack_y_nxt, inv_y;

    reg signed [BIT1 - 1 : 0] mul_t [0 : `CONV2D_KSIZE - 1],
                              mul_f [0 : `CONV2D_KSIZE - 1];
    reg signed [BIT2 - 1 : 0] add_t [0 : `CONV2D_KSIZE - 3],
                              add_f [0 : `CONV2D_KSIZE - 3];

    assign ack_prev = (ack_mul_prev == {`CONV2D_KSIZE{`ON}}) ? `ON
                                                             : ((ack_mul_prev == {`CONV2D_KSIZE{`OFF}}) ? `OFF
                                                                                                        : ack_prev);
    
    assign ack_mul_add = (ack_add_prev == {SADD{`ON}}) ? `ON
                                                       : ((ack_add_prev == {SADD{`OFF}}) ? `OFF
                                                                                         : ack_prev);

    handshake3 #(.BIT0 (BIT2),
                 .BIT1 (BIT2),
                 .BIT2 (BIT2)) handshake_y
    (
        .reset (reset),

        .dt_0 (cadd_t [SADD - 2]),
        .df_0 (cadd_f [SADD - 2]),
        .dt_1 (cadd_t [SADD - 1]),
        .df_1 (cadd_f [SADD - 1]),
        .dt_2 (cyt),
        .df_2 (cyf),

        .inv (inv_y),
        .ack_prev (ack_y_prev),
        .ack_nxt  (ack_y_nxt)
    );

    always @(posedge ack_y_prev or posedge (reset | ~ack_y_prev)) begin

        if (reset | ~ack_y_prev) begin

            yt <= {BIT2{`OFF}};
            yf <= {BIT2{`OFF}};
            
        end

        else begin

            yt <= cyt;
            yf <= cyf;
            
        end
        
    end

    genvar i, j;

    generate

        for (i = 0; i < `CONV2D_KSIZE; i = i + 1) begin

            assign dxt [i] = xt [`BIT_DATA * (i + 1) - 1 : `BIT_DATA * i];
            assign dxf [i] = xf [`BIT_DATA * (i + 1) - 1 : `BIT_DATA * i];
            assign dw  [i] = w  [`BIT_DATA * (i + 1) - 1 : `BIT_DATA * i];

            assign cmul_t [i] = dxt [i] * dw [i];
            assign cmul_f [i] = inv_mul[i] ? ~cmul_t [i] : {BIT1{`OFF}};

            assign ack_mul_nxt[i] = ack_mul_add;

            handshake2 #(.BIT0 (`BIT_DATA),
                         .BIT1 (BIT1))      handsahke_mul
            (
                .reset (reset),

                .dt_0 (dxt[i]),
                .df_0 (dxf[i]),
                .dt_1 (cmul_t[i]),
                .df_1 (cmul_f[i]),

                .inv      (inv_mul[i]),
                .ack_prev (ack_mul_prev[i]),
                .ack_nxt  (ack_mul_nxt[i])
            );

            always @(posedge ack_mul_prev[i] or posedge (reset | ~ack_mul_prev[i])) begin

                if (reset | ~ack_mul_prev[i]) begin

                    mul_t [i] <= {BIT1{`OFF}};
                    mul_f [i] <= {BIT1{`OFF}};
                    
                end

                else begin

                    mul_t [i] <= cmul_t [i];
                    mul_f [i] <= cmul_f [i];
                    
                end
                
            end
            
        end
        
    endgenerate

    generate

        for (j = 0; j < SADD; j = j + 1) begin

            assign cadd_f [j] = inv_add[j] ? ~cadd_t[j] : {BIT2{`OFF}};

            assign ack_add_nxt [j] = ack_y_prev;

            always @(posedge ack_add_prev[j] or posedge (reset | ack_add_prev[j])) begin

                if (reset | ack_add_prev[j]) begin

                    add_t [j] <= {BIT2{`OFF}};
                    add_f [j] <= {BIT2{`OFF}};
                    
                end

                else begin

                    add_t [j] <= cadd_t [j];
                    add_f [j] <= cadd_f [j];
                    
                end

            end

            if (j < (`CONV2D_KSIZE / 2)) begin

                assign cadd_t [j] = mul_t [j * 2] + mul_t [j * 2 + 1];

                handshake3 #(.BIT0 (BIT1),
                             .BIT1 (BIT1),
                             .BIT2 (BIT2))  handshake_add_mul
                (
                    .reset (reset),

                    .dt_0 (mul_t [j * 2]),
                    .df_0 (mul_f [j * 2]),
                    .dt_1 (mul_t [j * 2 + 1]),
                    .df_1 (mul_f [j * 2 + 1]),
                    .dt_2 (cadd_t [j]),
                    .df_2 (cadd_f [j]),

                    .inv      (inv_add[j]),
                    .ack_prev (ack_add_prev [j]),
                    .ack_nxt  (ack_add_nxt  [j])
                );
                
            end

            else if (j == (`CONV2D_KSIZE / 2)) begin

                assign cadd_t [j] = mul_t [`CONV2D_KSIZE - 1] + cadd_t [0];

                handshake3 #(.BIT0 (BIT1),
                             .BIT1 (BIT2),
                             .BIT2 (BIT2))  handshake_add_mul
                (
                    .reset (reset),

                    .dt_0 (mul_t [`CONV2D_KSIZE - 1]),
                    .df_0 (mul_f [`CONV2D_KSIZE - 1]),
                    .dt_1 (cadd_t [0]),
                    .df_1 (cadd_f [0]),
                    .dt_2 (cadd_t [j]),
                    .df_2 (cadd_f [j]),

                    .inv      (inv_add[j]),
                    .ack_prev (ack_add_prev [j]),
                    .ack_nxt  (ack_add_nxt  [j])
                );
                
            end

            else begin

                assign cadd_t [j] = cadd_t [j - (`CONV2D_KSIZE / 2)] + cadd_t [j - (`CONV2D_KSIZE / 2) + 1];

                handshake3 #(.BIT0 (BIT1),
                             .BIT1 (BIT2),
                             .BIT2 (BIT2))  handshake_add_mul
                (
                    .reset (reset),

                    .dt_0 (mul_t [`CONV2D_KSIZE - 1]),
                    .df_0 (mul_f [`CONV2D_KSIZE - 1]),
                    .dt_1 (cadd_t [0]),
                    .df_1 (cadd_f [0]),
                    .dt_2 (cadd_t [j]),
                    .df_2 (cadd_f [j]),

                    .inv      (inv_add[j]),
                    .ack_prev (ack_add_prev [j]),
                    .ack_nxt  (ack_add_nxt  [j])
                );
                
            end
            
        end
        
    endgenerate
    
endmodule