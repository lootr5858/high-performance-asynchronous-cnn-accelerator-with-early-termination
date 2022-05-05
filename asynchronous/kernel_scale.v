`include "./definitions.v"
`include "./handshake2.v"

module kernel_scale
#(
    parameter BIT_IN = 16,
    parameter BIT_SH = $clog2(BIT_IN - `BIT_DATA)
 )
(
    input reset,

    output ack_prev,
    input  ack_nxt,

    input signed [BIT_IN - 1 : 0] xt, xf,
    input signed [BIT_SH - 1 : 0] scale,

    output reg signed [`BIT_DATA - 1 : 0] yt, yf
);

    wire signed [`BIT_DATA - 1 : 0] cyt, cyf;
    wire                            inv_y;

    assign cyt = (xt[`BIT_DATA - 1] == `ON) ? {`BIT_DATA{`OFF}} : xt;
    assign cyf = inv_y ? ~cyt : {`BIT_DATA{`OFF}};

    handshake2 #(.BIT0 (BIT_IN),
                 .BIT1 (`BIT_DATA)) handshake_y
    (
        .reset (reset),
        
        .dt_0 (xt),
        .df_0 (xf),
        .dt_1 (cyt),
        .df_1 (cyf),

        .inv      (inv_y),
        .ack_prev (ack_prev),
        .ack_nxt  (ack_nxt)
    );

    always @(posedge ack_prev or posedge (reset | ~ack_prev)) begin

        if (reset | ~ ack_prev) begin

            yt <= {`BIT_DATA{`OFF}};
            yf <= {`BIT_DATA{`OFF}};
            
        end

        else begin

            yt <= cyt;
            yf <= cyf;
            
        end
        
    end
    
endmodule