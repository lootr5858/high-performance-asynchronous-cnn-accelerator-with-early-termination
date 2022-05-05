`include "./definitions.v"
`include "./handshake3.v"

module kernel_dense
#(
    parameter BIT_OUT    = `BIT_DATA * `DENSE_KSIZE
 )
(
    input reset,

    input signed [`BIT_DATA - 1 : 0] xt, xf,
    input signed [BIT_OUT   - 1 : 0] wt, wf,

    output reg signed [BIT_OUT * 2 - 1 : 0] yt, yf,

    output ack_prev,
    input  ack_nxt
);

    localparam BITm = `BIT_DATA * 2;

    wire signed [`BIT_DATA - 1 : 0] dwt [0 : `DENSE_KSIZE - 1],
                                    dwf [0 : `DENSE_KSIZE - 1];

    wire [`DENSE_KSIZE - 1 : 0] ack_mul_prev, inv_mul;

    wire signed [BITm - 1 : 0] dyt [0 : `DENSE_KSIZE - 1],
                               dyf [0 : `DENSE_KSIZE - 1];

    assign ack_prev = (ack_mul_prev == {`DENSE_KSIZE{`ON}}) ? `ON
                                                            : ((ack_mul_prev == {`DENSE_KSIZE{`OFF}}) ? `OFF : ack_prev);

    genvar i;

    generate

        for (i = 0; i < `DENSE_KSIZE; i = i + 1) begin
            
            assign dwt [i] = wt [`BIT_DATA * (i + 1) - 1 : `BIT_DATA * i];
            assign dwf [i] = wf [`BIT_DATA * (i + 1) - 1 : `BIT_DATA * i];

            assign dyt [i] = xt * dwt [i];
            assign dyf [i] = inv_mul[i] ? ~dyt[i] : {BITm{`OFF}};

            handshake3 #(.BIT0 (`BIT_DATA),
                         .BIT1 (`BIT_DATA),
                         .BIT2 (BITm))      mul
            (
                .reset (reset),

                .dt_0 (xt),
                .df_0 (xf),
                .dt_1 (dwt[i]),
                .df_1 (dwf[i]),
                .dt_2 (dyt[i]),
                .df_2 (dyf[i]),

                .ack_prev (ack_mul_prev[i]),
                .inv      (inv_mul[i]),
                .ack_nxt  (ack_nxt)
            );

            always @(posedge ack_mul_prev[i] or posedge (reset | ~ack_mul_prev[i])) begin

                if (reset | ~ack_mul_prev[i]) begin

                    yt [BITm * (i + 1) - 1 : BITm * i] <= {BITm{`OFF}};
                    yf [BITm * (i + 1) - 1 : BITm * i] <= {BITm{`OFF}};
                    
                end

                else begin

                    yt [BITm * (i + 1) - 1 : BITm * i] <= dyt[i];
                    yf [BITm * (i + 1) - 1 : BITm * i] <= dyf[i];
                    
                end
                
            end

        end
        
    endgenerate
    
endmodule