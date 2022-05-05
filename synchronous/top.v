`include "./definitions.v"
`include "./layer0.v"
`include "./layer_convolution.v"
`include "./layer_max2d.v"
`include "./layer_dense.v"
`include "./buffer.v"

module top
(
    input clock, reset, load,

    input        [`ADDRT - 1 : 0] addr,
    input signed [`BIT_W - 1 : 0] data_w,
    input signed [`BIT_I - 1 : 0] data_in,

    output reg [`BIT_O - 1 : 0] data_out
);

    wire signed [`BIT_L0B0   - 1 : 0] link_00;
    wire signed [`BIT_B0L1   - 1 : 0] link_01;
    wire signed [`BIT_L1B1   - 1 : 0] link_02;
    wire signed [`BIT_B1L2   - 1 : 0] link_03;
    wire signed [`BIT_L2B2   - 1 : 0] link_04;
    wire signed [`BIT_B2L3F  - 1 : 0] link_05;
    wire signed [`BIT_L3FB3F - 1 : 0] link_06;
    wire signed [`BIT_B3FL4F - 1 : 0] link_07;
    wire signed [`BIT_L4FB4F - 1 : 0] link_08;
    wire signed [`BIT_B4FL5F - 1 : 0] link_09;
    wire signed [`BIT_L5FB5F - 1 : 0] link_10;
    wire signed [`BIT_B5FL6F - 1 : 0] link_11;
    wire signed [`BIT_B2L3E  - 1 : 0] link_12;
    wire signed [`BIT_RLRE   - 1 : 0] results_full, results_early;
    wire        [`BIT_O      - 1 : 0] index_full, index_early;

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

            cnt_full     <=  {`IN_B5FL6F{`OFF}};
            cnt_early    <= {`IN_B2L3E {`OFF}};
            load_weights <= {`BIT_LW{`OFF}};
            data_out     <= {`BIT_O{`OFF}};
            
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

            if (results_early > 70) z <= index_early;
            else                    z <= index_full;
            
        end

        else load_weights <= load_weights;
        
    end

    layer0 layer0
    (
        .clock (clock),
        .reset (reset),
        .load  (load_weights[0]),

        .x (data_in),
        .w (data_w [`BIT_INL0 - 1 : 0]),
        .z (link_00)
    );

    buffer #(.SIZE  (`CONV2D_KSIZE),
             .CYCLE ($clog2(`CONV2D_KSIZE - 1) + 1),
             .BITi  (`BIT_L0B0),
             .BITo  (`BIT_B0L1)) buffer0
    (
        .clock (clock),
        .reset (reset),

        .d (link_00),
        .q (link_01)
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

        .x     (link_01),
        .scale (scale_1),
        .z     (link_02)
    );

    buffer #(.SIZE  (`MAX2D_KSIZE),
             .CYCLE ($clog2(`CONV2D_KSIZE - 1) + 1),
             .BITi  (`BIT_L1B1),
             .BITo  (`BIT_B1L2)) buffer1
    (
        .clock (clock),
        .reset (reset),

        .d (link_02),
        .q (link_03)
    );

    layer_max2d #(.FILTER_IN (`FILTER_L2)) layer2 
    (
        .clock (clock),
        .reset (reset),

        .x (link_03),
        .z (link_04)
    );

    buffer #(.SIZE  (`CONV2D_KSIZE),
             .CYCLE ($clog2(`MAX2D_KSIZE)),
             .BITi  (`BIT_L2B2),
             .BITo  (`BIT_B2L3E)) buffer2
    (
        .clock (clock),
        .reset (reset),

        .d (link_04),
        .q (link_05)
    );

    layer_convolution #(.FILTER_IN  (`FILTER_L2),
                        .FILTER_OUT (`FILTER_L3F),
                        .BIT_IN     (`BIT_B2L3F),
                        .BIT_OUT    (`BIT_L3FB3F),
                        .BIT_SCALE  (`BIT_S3F)) layer3F
    (
        .clock (clock),
        .reset (reset),

        .load  (load_weights[2]),
        .addr  (addr[$clog2(`FILTER_L3F) + 3 : 4]),
        .w     (data_w[`BIT_B2L3F - 1 : 0]),

        .x     (link_05),
        .scale (scale_3f),
        .z     (link_06)
    );

    buffer #(.SIZE  (`CONV2D_KSIZE),
             .CYCLE ($clog2(`CONV2D_KSIZE - 1) + 1),
             .BITi  (`BIT_L3FB3F),
             .BITo  (`BIT_B3FL4F)) buffer3F
    (
        .clock (clock),
        .reset (reset),

        .d (link_06),
        .q (link_07)
    );

    layer_convolution #(.FILTER_IN  (`FILTER_L3F),
                        .FILTER_OUT (`FILTER_L4F),
                        .BIT_IN     (`BIT_B3FL4F),
                        .BIT_OUT    (`BIT_L4FB4F),
                        .BIT_SCALE  (`BIT_S4F)) layer4F
    (
        .clock (clock),
        .reset (reset),

        .load  (load_weights[3]),
        .addr  (addr[$clog2(`FILTER_L3F) + 3 : 4]),
        .w     (data_w[`BIT_B2L3F - 1 : 0]),

        .x     (link_07),
        .scale (scale_4f),
        .z     (link_08)
    );

    buffer #(.SIZE  (`MAX2D_KSIZE),
             .CYCLE ($clog2(`CONV2D_KSIZE - 1) + 1),
             .BITi  (`BIT_L4FB4F),
             .BITo  (`BIT_B4FL5F)) buffer4F
    (
        .clock (clock),
        .reset (reset),

        .d (link_08),
        .q (link_09)
    );

    layer_max2d #(.FILTER_IN (`FILTER_L5F)) layer5F 
    (
        .clock (clock),
        .reset (reset),

        .x (link_09),
        .z (link_10)
    );

    buffer #(.SIZE  (1),
             .CYCLE ($clog2(`MAX2D_KSIZE)),
             .BITi  (`BIT_L5FB5F),
             .BITo  (`BIT_L5FB5F)) buffer5F
    (
        .clock (clock),
        .reset (reset),

        .d (link_10),
        .q (link_11)
    );

    layer_dense #(.BIT_IN (`BIT_DATA),
                  .BIT_MA (`BIT_B5FL6F),
                  .SIZE   (`IN_B5FL6F)) layer6F
    (
        .clock (clock),
        .reset (reset),
        
        .load  (load_weights[4]),
        .addr0 (addr[7:4]),
        .addr1 (addr[21:8]),
        .w     (data_w[`BIT_DATA * `IN_B5FL6F - 1 : 0]),

        .x     (link_11[cnt_full]),
        .scale (scale_6f),
        .z     (results_full)
    );

    layer_dense #(.BIT_IN (`BIT_DATA),
                  .BIT_MA (`BIT_B2L3E),
                  .SIZE   (`IN_B2L3E)) layer3E
    (
        .clock (clock),
        .reset (reset),
        
        .load  (load_weights[5]),
        .addr0 (addr[7:4]),
        .addr1 (addr[21:8]),
        .w     (data_w[`BIT_DATA * `IN_B2L3E - 1 : 0]),

        .x     (link_12[cnt_early]),
        .scale (scale_3e),
        .z     (results_early)
    );
    
endmodule
