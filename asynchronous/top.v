`include "./definitions.v"
`include "./layer0.v"
`include "./layer_convolution.v"
`include "./layer_max2d.v"
`include "./layer_dense.v"
`include "./buffer.v"
`include "./handshake1.v"
`include "./handshake3.v"

module top
(
    input clock, reset, load,

    output ack_prev,
    input  ack_nxt,

    input        [`ADDRT - 1 : 0] addr,
    input signed [`BIT_W - 1 : 0] data_w,
    input signed [`BIT_I - 1 : 0] din_t, din_f,

    output reg [`BIT_O - 1 : 0] dout_t, dout_f
);

    wire signed [`BIT_L0B0   - 1 : 0] link_00t, link_00f;
    wire signed [`BIT_B0L1   - 1 : 0] link_01t, link_01f;
    wire signed [`BIT_L1B1   - 1 : 0] link_02t, link_02f;
    wire signed [`BIT_B1L2   - 1 : 0] link_03t, link_03f;
    wire signed [`BIT_L2B2   - 1 : 0] link_04t, link_04f;
    wire signed [`BIT_B2L3F  - 1 : 0] link_05t, link_05f;
    wire signed [`BIT_L3FB3F - 1 : 0] link_06t, link_06f;
    wire signed [`BIT_B3FL4F - 1 : 0] link_07t, link_07f;
    wire signed [`BIT_L4FB4F - 1 : 0] link_08t, link_08f;
    wire signed [`BIT_B4FL5F - 1 : 0] link_09t, link_09f;
    wire signed [`BIT_L5FB5F - 1 : 0] link_10t, link_10f;
    wire signed [`BIT_B5FL6F - 1 : 0] link_11t, link_11f;
    wire signed [`BIT_B2L3E  - 1 : 0] link_12t, link_12f;
    wire signed [`BIT_RLRE   - 1 : 0] results_full_t, results_full_f, results_early_t, results_early_f;

    wire [`BIT_O - 1 : 0] index_full_t, index_full_f, index_early_t, index_early_f;
    wire                  ack_l0_b0,   ack_b0_l1,
                          ack_l1_b1,   ack_b1_l2,
                          ack_l2_b2,   ack_b2, ack_b2_l3e, ack_b2_l3f, ack_b2_l3e_1,
                          ack_l3f_b3f, ack_b3f_l4f,
                          ack_l4f_b4f, ack_b4f_l5f,
                          ack_l5f_b5f, ack_b5f_l6f, ack_b5f_l6f_1,
                          ack_l6f_b6f,
                          ack_l3e_b3e, lock;

    reg signed [`BIT_B5FL6F - 1 : 0] link_11t1, link_11f1;
    reg signed [`BIT_B2L3E  - 1 : 0] link_05t1, link_05f1;
    reg signed [`BIT_RLRE   - 1 : 0] res_full_t, res_full_f, res_early_t, res_early_f;

    reg [$clog2(`FILTER_L5F) - 1 : 0] cnt_full;
    reg [$clog2(`IN_B2L3F)   - 1 : 0] cnt_early;

    reg [`BIT_S0    - 1 : 0] scale_0;
    reg [`BIT_S1    - 1 : 0] scale_1;
    reg [`BIT_S3F   - 1 : 0] scale_3f;
    reg [`BIT_S3E   - 1 : 0] scale_3e;
    reg [`BIT_S4F   - 1 : 0] scale_4f;
    reg [`BIT_S6F   - 1 : 0] scale_6f;
    reg [`BIT_LW    - 1 : 0] load_weights;

    assign link_12 = link_05[cnt_early];

    always @(posedge clock or posedge reset) begin

        if (reset) begin

            load_weights <= {`BIT_LW{`OFF}};
            
        end

        else if (load) begin

            casex (addr[3:0])

                // layer 0, weights
                {1'b0, 3'd0} :  load_weights <= {`BIT_LW{`OFF}} + (2 ** 0);

                // layer 0, scale
                {1'b1, 3'd0} : begin

                    load_weights <= {`BIT_LW{`OFF}};
                    scale_0      <= data_w[`BIT_S0 + 3 : 4];
                    
                end

                // layer 1, weights
                {1'b0, 3'd1} :  load_weights <= {`BIT_LW{`OFF}} + (2 ** 1);

                // layer 1, scale
                {1'b1, 3'd1} : begin

                    load_weights <= {`BIT_LW{`OFF}};
                    scale_1      <= data_w[`BIT_S1 + 3 : 4];
                    
                end

                // layer 3F, weights
                {1'b0, 3'd3} :  load_weights <= {`BIT_LW{`OFF}} + (2 ** 2);

                // layer 3F, scale
                {1'b1, 3'd3} : begin

                    load_weights <= {`BIT_LW{`OFF}};
                    scale_3f     <= data_w[`BIT_S3F + 3 : 4];
                    
                end

                // layer 4F, weights
                {1'b0, 3'd4} :  load_weights <= {`BIT_LW{`OFF}} + (2 ** 3);

                // layer 1, scale
                {1'b1, 3'd4} : begin

                    load_weights <= {`BIT_LW{`OFF}};
                    scale_4f      <= data_w[`BIT_S4F + 3 : 4];
                    
                end

                // layer 6F, weights
                {1'b0, 3'd6} :  load_weights <= {`BIT_LW{`OFF}} + (2 ** 4);

                // layer 6F, scale
                {1'b1, 3'd6} : begin

                    load_weights <= {`BIT_LW{`OFF}};
                    scale_6f     <= data_w[`BIT_S6F + 3 : 4];
                    
                end

                // layer 3E, weights
                {1'b0, 3'd7} :  load_weights <= {`BIT_LW{`OFF}} + (2 ** 5);

                // layer 1, scale
                {1'b1, 3'd7} : begin

                    load_weights <= {`BIT_LW{`OFF}};
                    scale_3e     <= data_w[`BIT_S3E + 3 : 4];
                    
                end

                default : load_weights <= load_weights;

            endcase
            
        end

        else load_weights <= load_weights;
        
    end

    layer0 layer0
    (
        .clock (clock),
        .reset (reset),
        .load  (load_weights[0]),

        .ack_prev (ack_prev),
        .ack_nxt  (ack_l0_b0),

        .w (data_w [`BIT_INL0 - 1 : 0]),

        .xt (din_t),
        .xf (din_f),
        .zt (link_00t),
        .zf (link_00f)
    );

    buffer #(.SIZE  (`CONV2D_KSIZE),
             .CYCLE ($clog2(`CONV2D_KSIZE - 1) + 1),
             .BITi  (`BIT_L0B0),
             .BITo  (`BIT_B0L1)) buffer0
    (
        .reset (reset),

        .ack_prev (ack_l0_b0),
        .ack_nxt  (ack_b0_l1),

        .dt (link_00t),
        .df (link_00f),
        .qt (link_01t),
        .qf (link_01f)
    );

    layer_convolution #(.FILTER_IN  (`FILTER_L0),
                        .FILTER_OUT (`FILTER_L1),
                        .BIT_IN     (`BIT_B0L1),
                        .BIT_OUT    (`BIT_L1B1),
                        .BIT_SCALE  (`BIT_S1)) layer1
    (
        .clock (clock),
        .reset (reset),

        .load  (load_weights[1]),
        .addr  (addr[$clog2(`FILTER_L1) + 3 : 4]),
        .w     (data_w[`BIT_B0L1 - 1 : 0]),
        .scale (scale_1),

        .ack_prev (ack_b0_l1),
        .ack_nxt  (ack_l1_b1),

        .xt (link_01t),
        .xf (link_01f),
        .zt (link_02t),
        .zf (link_02f)
    );

    buffer #(.SIZE  (`MAX2D_KSIZE),
             .CYCLE ($clog2(`CONV2D_KSIZE - 1) + 1),
             .BITi  (`BIT_L1B1),
             .BITo  (`BIT_B1L2)) buffer1
    (
        .reset (reset),

        .ack_prev (ack_l1_b1),
        .ack_nxt  (ack_b1_l2),

        .dt (link_02t),
        .df (link_02f),
        .qt (link_03t),
        .qf (link_03f)
    );

    layer_max2d #(.FILTER_IN (`FILTER_L2)) layer2 
    (
        .reset (reset),

        .ack_prev (ack_b1_l2),
        .ack_nxt  (ack_l2_b2),

        .xt (link_03t),
        .xf (link_03f),
        .zt (link_04t),
        .zf (link_04f)
    );

    assign ack_b2_l3 = ((ack_b2_l3e == `ON) & (ack_b2_l3f == `ON)) ? `ON :
                       (((ack_b2_l3e == `OFF) & (ack_b2_l3f == `OFF)) ? `OFF :
                       ack_b2_l3);

    buffer #(.SIZE  (`CONV2D_KSIZE),
             .CYCLE ($clog2(`MAX2D_KSIZE)),
             .BITi  (`BIT_L2B2),
             .BITo  (`BIT_B2L3E)) buffer2
    (
        .reset (reset),

        .ack_prev (ack_l2_b2),
        .ack_nxt  (ack_b2_l3),

        .dt (link_04t),
        .df (link_04f),
        .qt (link_05t),
        .qf (link_05f)
    );

    layer_convolution #(.FILTER_IN  (`FILTER_L2),
                        .FILTER_OUT (`FILTER_L3F),
                        .BIT_IN     (`BIT_B2L3F),
                        .BIT_OUT    (`BIT_L3FB3F),
                        .BIT_SCALE  (`BIT_S3F)) layer3F
    (
        .clock (clock),
        .reset (reset | lock),

        .load  (load_weights[2]),
        .addr  (addr[$clog2(`FILTER_L3F) + 3 : 4]),
        .w     (data_w[`BIT_B2L3F - 1 : 0]),
        .scale (scale_3f),

        .ack_prev (ack_b2_l3f),
        .ack_nxt  (ack_l3f_b3f),

        .xt (link_05t),
        .xf (link_05f),
        .zt (link_06t),
        .zf (link_06f)
    );

    buffer #(.SIZE  (`CONV2D_KSIZE),
             .CYCLE ($clog2(`CONV2D_KSIZE - 1) + 1),
             .BITi  (`BIT_L3FB3F),
             .BITo  (`BIT_B3FL4F)) buffer3F
    (
        .reset (reset | lock),

        .ack_prev (ack_l3f_b3f),
        .ack_nxt  (ack_b3f_l4f),

        .dt (link_06t),
        .df (link_06f),
        .qt (link_07t),
        .qf (link_07f)
    );

    layer_convolution #(.FILTER_IN  (`FILTER_L3F),
                        .FILTER_OUT (`FILTER_L4F),
                        .BIT_IN     (`BIT_B3FL4F),
                        .BIT_OUT    (`BIT_L4FB4F),
                        .BIT_SCALE  (`BIT_S4F)) layer4F
    (
        .clock (clock),
        .reset (reset | lock),

        .load  (load_weights[3]),
        .addr  (addr[$clog2(`FILTER_L3F) + 3 : 4]),
        .w     (data_w[`BIT_B2L3F - 1 : 0]),
        .scale (scale_4f),

        .ack_prev (ack_b3f_l4f),
        .ack_nxt  (ack_l4f_b4f),

        .xt (link_07t),
        .xf (link_07f),
        .zt (link_08t),
        .zf (link_08f)
    );

    buffer #(.SIZE  (`MAX2D_KSIZE),
             .CYCLE ($clog2(`CONV2D_KSIZE - 1) + 1),
             .BITi  (`BIT_L4FB4F),
             .BITo  (`BIT_B4FL5F)) buffer4F
    (
        .reset (reset | lock),

        .ack_prev (ack_l4f_b4f),
        .ack_nxt  (ack_b4f_l5f),

        .dt (link_08t),
        .df (link_08f),
        .qt (link_09t),
        .qf (link_09f)
    );

    layer_max2d #(.FILTER_IN (`FILTER_L5F)) layer5F 
    (
        .clock (clock),
        .reset (reset | lock),

        .ack_prev (ack_b4f_l5f),
        .ack_nxt  (ack_l5f_b5f),

        .xt (link_09t),
        .xf (link_09f),
        .zt (link_10t),
        .zf (link_10f)
    );

    buffer #(.SIZE  (1),
             .CYCLE ($clog2(`MAX2D_KSIZE)),
             .BITi  (`BIT_L5FB5F),
             .BITo  (`BIT_L5FB5F)) buffer5F
    (
        .reset (reset | lock),

        .ack_prev (ack_l5f_b5f),
        .ack_nxt  (ack_b5f_l6f),

        .dt (link_10t),
        .df (link_10f),
        .qt (link_11t),
        .qf (link_11f)
    );

    assign ack_b5f_l6f = (ack_b5f_l6f_1 & (cnt_full == `IN_B5FL6F) == `ON) ? `ON :
                         ((ack_b5f_l6f_1 == `OFF & (cnt_full == 0)) ? `OFF :
                         ack_b5f_l6f_1);

    always @(posedge ack_b5f_l6f_1 or posedge (reset | ~ack_b5f_l6f_1 | lock)) begin

        if (reset | lock) begin

            cnt_full  <= {($clog2(`FILTER_L5F)){`OFF}};
            link_11t1 <= {`BIT_B5FL6F{`OFF}};
            link_11f1 <= {`BIT_B5FL6F{`OFF}};
            
        end

        else if (~ack_b5f_l6f_1) begin

            link_11t1 <= {`BIT_B5FL6F{`OFF}};
            link_11f1 <= {`BIT_B5FL6F{`OFF}};
            
        end

        else begin

            cnt_full <= cnt_full + 1;
            
            link_11t1 <= link_11t[`BIT_DATA * (cnt_full + 1) - 1 : `BIT_DATA * cnt_full];
            link_11f1 <= link_11f[`BIT_DATA * (cnt_full + 1) - 1 : `BIT_DATA * cnt_full];
            
        end
        
    end

    layer_dense #(.BIT_IN (`BIT_DATA),
                  .BIT_MA (`BIT_B5FL6F),
                  .SIZE   (`IN_B5FL6F)) layer6F
    (
        .clock (clock),
        .reset (reset | lock),
        
        .load  (load_weights[4]),
        .addr0 (addr[7:4]),
        .addr1 (addr[21:8]),
        .w     (data_w[`BIT_DATA * `IN_B5FL6F - 1 : 0]),
        .scale (scale_6f),

        .ack_prev (ack_b5f_l6f_1),
        .ack_nxt  (ack_l6f_b6f),

        .xt (link_11t1),
        .xf (link_11f1),
        .zt (link_12t),
        .zf (link_12f)
    );

    assign ack_b2_l3e = (ack_b2_l3e_1 & (cnt_early == `IN_B2L3E) == `ON) ? `ON :
                         ((ack_b2_l3e_1 == `OFF & (cnt_early == 0)) ? `OFF :
                        ack_b2_l3e_1);

    always @(posedge ack_b2_l3e_1 or posedge (reset | ~ack_b2_l3e_1)) begin

        if (reset) begin

            cnt_early  <= {($clog2(`IN_B2L3E)){`OFF}};
            link_05t1 <= {`BIT_B2L3E{`OFF}};
            link_05f1 <= {`BIT_B2L3E{`OFF}};
            
        end

        else if (~ack_b2_l3e_1) begin

            link_05t1 <= {`BIT_B5FL6F{`OFF}};
            link_05f1 <= {`BIT_B5FL6F{`OFF}};
            
        end

        else begin

            cnt_early <= cnt_early + 1;
            
            link_05t1 <= link_11t[`BIT_DATA * (cnt_early + 1) - 1 : `BIT_DATA * cnt_early];
            link_05f1 <= link_11f[`BIT_DATA * (cnt_early + 1) - 1 : `BIT_DATA * cnt_early];
            
        end
        
    end

    layer_dense #(.BIT_IN (`BIT_DATA),
                  .BIT_MA (`BIT_B2L3E),
                  .SIZE   (`IN_B2L3E)) layer3E
    (
        .clock (clock),
        .reset (reset),

        .ack_prev (ack_b2_l3e_1),
        .ack_nxt  (ack_l3e_b3e),
        
        .load  (load_weights[5]),
        .addr0 (addr[7:4]),
        .addr1 (addr[21:8]),
        .w     (data_w[`BIT_DATA * `IN_B2L3E - 1 : 0]),
        .scale (scale_3e),

        .xt (link_05t1),
        .xf (link_05f1),
        .zf (results_early_t),
        .zf (results_early_f)
    );

    handshake1 #(.BIT0 (`BIT_RLRE)) handshake_early
    (
        .reset (reset),

        .ack_prev (ack_l3e_b3e),
        .ack_nxt  (ack_nxt),

        .d0_t (results_early_t),
        .d0_t (results_early_f)
    );

    always @(posedge ack_l3e_b3e or posedge (reset | ~ack_l3e_b3e)) begin

        if (reset | ~ack_l3e_b3e) begin

            res_early_t <= {`BIT_RLRE{`OFF}};
            res_early_f <= {`BIT_RLRE{`OFF}};
            
        end

        else begin

            res_early_t <= results_early_t;
            res_early_f <= results_early_f;
            
        end
        
    end

    handshake1 #(.BIT0 (`BIT_RLRE)) handshake_full
    (
        .reset (reset),

        .ack_prev (ack_l6f_b6f),
        .ack_nxt  (ack_nxt),

        .d0_t (results_full_t),
        .d0_t (results_full_f)
    );

    always @(posedge ack_l6f_b6f or posedge (reset | ~ack_l6f_b6f)) begin

        if (reset | ~ack_l6f_b6f) begin

            res_full_t <= {`BIT_RLRE{`OFF}};
            res_full_f <= {`BIT_RLRE{`OFF}};
            
        end

        else begin

            res_full_t <= results_full_t;
            res_full_f <= results_full_f;
            
        end
        
    end

    assign lock = ack_nxt ? `OFF : 
                  ((res_early_t > 70) ? `ON : `OFF);

    assign dout_t = lock ? res_early_t : res_full_t;
    assign dout_f = lock ? res_early_f : res_full_f;
    
endmodule
