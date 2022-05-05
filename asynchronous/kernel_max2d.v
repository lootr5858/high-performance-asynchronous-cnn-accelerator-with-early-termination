`include "./definitions.v"
`include "./handshake3.v"

module kernel_max2d
(
    input reset,

    output ack_prev,
    input  ack_nxt,

    input signed [`BIT_DATA - 1 : 0] x0_t, x0_f,
                                     x1_t, x1_f,
                                     x2_t, x2_f,
                                     x3_t, x3_f,

    output reg signed [`BIT_DATA - 1 : 0] yt, yf
);

    reg signed [`BIT_DATA - 1 : 0] p0_t, p0_f,
                                   p1_t, p1_f;

    wire signed [`BIT_DATA - 1 : 0] c0_t, c0_f,
                                    c1_t, c1_f,
                                    dy_t, dy_f;

    wire [1 : 0] ack_p_prev, inv_p;
    wire         ack_py, inv_y;

    assign ack_prev = (ack_p_prev == 2'b11) ? `ON : ((ack_p_prev == 2'b00) ? `OFF : ack_prev);

    assign c0_t = (x0_t > x1_t) ? x0_t : x1_t;
    assign c1_t = (x2_t > x3_t) ? x2_t : x3_t;
    assign dy_t = (p0_t > p1_t) ? p0_t : p1_f;
    assign c0_f = (inv_p[0]) ? ~c0_t : {`BIT_DATA{`OFF}};
    assign c1_f = (inv_p[1]) ? ~c1_t : {`BIT_DATA{`OFF}};
    assign dy_f = (inv_y)    ? ~dy_t : {`BIT_DATA{`OFF}};

    handshake3 #(.BIT0 (`BIT_DATA),
                 .BIT1 (`BIT_DATA),
                 .BIT2 (`BIT_DATA)) handshake_p0
    (
        .reset (reset),
        
        .dt_0 (x0_t),
        .df_0 (x0_f),
        .dt_1 (x1_t),
        .df_1 (x1_f),
        .dt_2 (c0_t),
        .df_2 (c0_f),

        .inv      (inv_p[0]),
        .ack_prev (ack_p_prev[0]),
        .ack_nxt  (ack_py)
    );

    always @(posedge ack_p_prev[0] or posedge (reset | ~ack_p_prev[0])) begin

        if (reset | ~ack_p_prev[0]) begin

            p0_t <= {`BIT_DATA{`OFF}};
            p0_f <= {`BIT_DATA{`OFF}};
            
        end

        else begin

            p0_t <= c0_t;
            p0_f <= c0_f;
            
        end
        
    end

    handshake3 #(.BIT0 (`BIT_DATA),
                 .BIT1 (`BIT_DATA),
                 .BIT2 (`BIT_DATA)) handshake_p1
    (
        .reset (reset),
        
        .dt_0 (x1_t),
        .df_0 (x1_f),
        .dt_1 (x2_t),
        .df_1 (x2_f),
        .dt_2 (c1_t),
        .df_2 (c1_f),

        .inv      (inv_p[1]),
        .ack_prev (ack_p_prev[1]),
        .ack_nxt  (ack_py)
    );

    always @(posedge ack_p_prev[1] or posedge (reset | ~ack_p_prev[1])) begin

        if (reset | ~ack_p_prev[1]) begin

            p1_t <= {`BIT_DATA{`OFF}};
            p1_f <= {`BIT_DATA{`OFF}};
            
        end

        else begin

            p1_t <= c1_t;
            p1_f <= c1_f;
            
        end
        
    end

    handshake3 #(.BIT0 (`BIT_DATA),
                 .BIT1 (`BIT_DATA),
                 .BIT2 (`BIT_DATA)) handshake_y
    (
        .reset (reset),
        
        .dt_0 (p0_t),
        .df_0 (p0_f),
        .dt_1 (p1_t),
        .df_1 (p1_f),
        .dt_2 (dy_t),
        .df_2 (dy_f),

        .inv      (inv_y),
        .ack_prev (ack_py),
        .ack_nxt  (ack_nxt)
    );

    always @(posedge ack_py or posedge (reset | ~ack_py)) begin

        if (reset | ~ack_py) begin

            yt <= {`BIT_DATA{`OFF}};
            yf <= {`BIT_DATA{`OFF}};
            
        end

        else begin

            yt <= dy_t;
            yf <= dy_f;
            
        end
        
    end
    
endmodule