`include "./definitions.v"
`include "./kernel_dense.v"
`include "./kernel_scale.v"
`include "./kernel_softmax.v"

module layer_dense
#(
    parameter BIT_IN  = `BIT_DATA * `DENSE_KSIZE,
    parameter BIT_MA  = 32,
    parameter SIZE    = 128,
    parameter BIT_SH  = $clog2(BIT_MA - `BIT_DATA)
 )
(
    input clock, reset, load,

    output ack_prev,
    input  ack_nxt,

    input        [$clog2(`DENSE_KSIZE) - 1 : 0] addr0,
    input        [$clog2(SIZE)         - 1 : 0] addr1,
    input signed [BIT_IN               - 1 : 0] wt, wf,

    input signed [`BIT_DATA - 1 : 0] xt, xf,
    input        [BIT_SH    - 1 : 0] scale,

    output reg signed [`BIT_SOFTMAX - 1 : 0] zt, zf,
    output reg        [`BIT_O       - 1 : 0] index_t, index_f
);

    localparam BITc = $clog2(SIZE);
    localparam BIT0 = `BIT_DATA * 2;
    localparam BIT1 = BIT0 * `DENSE_KSIZE;
    localparam BIT2 = `BIT_DATA * `DENSE_KSIZE;
    localparam BIT3 = `BIT_SOFTMAX * `DENSE_KSIZE;

    wire signed [BIT1      - 1 : 0] yt0, yf0;
    wire signed [BIT0      - 1 : 0] dyt0 [0 : `DENSE_KSIZE - 1],
                                    dyf0 [0 : `DENSE_KSIZE - 1],
                                    cyt1 [0 : `DENSE_KSIZE - 1],
                                    cyf1 [0 : `DENSE_KSIZE - 1];
    wire signed [`BIT_DATA - 1 : 0] dyt2 [0 : `DENSE_KSIZE - 1],
                                    dyf2 [0 : `DENSE_KSIZE - 1];
    wire signed [BIT2      - 1 : 0] dyt3, dyf3;
    wire signed [BIT3      - 1 : 0] dyt4, dyf4;

    wire signed [`BIT_SOFTMAX - 1 : 0] wyt4 [0 : `DENSE_KSIZE - 1];

    wire [`DENSE_KSIZE - 1 : 0] inv_acc,
                                ack_acc_prev, ack_acc_scale;
    wire                        ack_dense_nxt, ack_scale_softmax, ack_softmax_nxt,
                                verify;

    reg signed [BIT_IN - 1 : 0] dwt [0 : SIZE - 1],
                                dwf [0 : SIZE - 1];
    reg signed [BIT_MA - 1 : 0] dyt1 [0 : `DENSE_KSIZE - 1],
                                dyf1 [0 : `DENSE_KSIZE - 1];
    
    reg [BITc         - 1 : 0] cnt;
    reg [`DENSE_KSIZE - 1 : 0] cnt1;
    reg                        inv_y4;

    integer ri, rj, lw, c0, c1, c2, cp;
    genvar  i;

    always @(posedge clock or posedge reset) begin

        if (reset) begin

            for (rj = 0; rj < SIZE; rj = rj + 1) begin
                
                dwt [rj] <= {BIT_IN{`OFF}};
                dwf [rj] <= {BIT_IN{`OFF}};

            end
            
        end

        else if (load) begin
            
            dwt [addr0][addr1] <= wt;
            dwf [addr0][addr1] <= wf;

        end

        else dwt [0][0] <= dwt [0][0];
        
    end

    always @(posedge (clock & verify) or posedge (reset | ~ack_nxt)) begin

        if (reset | ~ack_nxt) begin

            zt              <= {`BIT_SOFTMAX{`OFF}};
            index           <= {`BIT_O{`OFF}};
            ack_softmax_nxt <= `OFF;
            cnt             <= {BITc{`OFF}};
            inv_y4          <= `OFF;
            
        end

        else if (cnt1 == `DENSE_KSIZE - 2) begin

            ack_softmax_nxt <= `ON;
            cnt             <= cnt;
            inv_y4          <= `ON;

            if (wyt4 [cnt1] > wyt4 [cnt1 + 1]) begin

                zt    <= wyt4 [cnt1];
                index <= cnt;
                
            end

            else begin

                zt    <= wyt4 [cnt1 + 1];
                index <= cnt + 1;
                
            end
            
        end

        else begin

            ack_softmax_nxt <= `OFF;
            cnt             <= cnt + 1;
            inv_y4          <= `OFF;

            if (wyt4 [cnt1] > wyt4 [cnt1 + 1]) begin

                zt    <= wyt4 [cnt1];
                index <= cnt;
                
            end

            else begin

                zt    <= wyt4 [cnt1 + 1];
                index <= cnt + 1;
                
            end
            
        end
        
    end

    assign ack_dense_nxt = (ack_acc_prev == {`DENSE_KSIZE{`ON}}) ? `ON
                            : ((ack_acc_prev == {`DENSE_KSIZE{`OFF}}) ? `OFF
                            : ack_dense_nxt);

    assign verify = ((dyt4 ^ dyf4) == {BIT3{`ON}}) ? `ON :
                    (((dyt4 ^ dyf4) == {BIT3{`OFF}})) ? `OFF : verify;

    generate

        for (i = 0; i < `DENSE_KSIZE; i = i + 1) begin

            assign dyt0 [i] = yt0 [BIT0 * (i + 1) - 1 : BIT0 * i];
            assign dyf0 [i] = yf0 [BIT0 * (i + 1) - 1 : BIT0 * i];

            assign cyt1 [i] = (cnt == {BITc{`OFF}}) ? dyt0 [i] : cyt1 [i] + dyt0 [i];
            assign cyf1 [i] = inv_acc [i] ? ~cyt1 [i] : {BIT_MA{`OFF}};

            always @(posedge ack_acc_prev [i] or posedge (reset | ~ack_acc_prev [i])) begin

                if (reset | ~ack_acc_prev [i]) begin

                    dyt1 [i] <= {BIT_MA{`OFF}};
                    dyf1 [i] <= {BIT_MA{`OFF}};
                    
                end

                else begin

                    dyt1 [i] <= cyt1 [i];
                    dyf1 [i] <= cyf1 [i];
                    
                end
                
            end

            always @(posedge ack_acc_prev [i] or posedge reset) begin

                if (reset) cnt <= {BITc{`OFF}};

                else if (cnt == SIZE - 1) cnt <= {BITc{`OFF}};

                else cnt <= cnt + 1;
                
            end

            kernel_scale #(.BIT_IN (BIT_MA)) kernel_scale 
            (
                .reset (reset),

                .ack_prev (ack_acc_scale [i]),
                .ack_nxt  (ack_scale_softmax),

                .xt (dyt1 [i]),
                .xf (dyf1 [i]),
                .yt (dyt2 [i]),
                .yf (dyf2 [i]),

                .scale (scale)
            );

            assign dyt3 [`BIT_DATA * (i + 1) - 1 : `BIT_DATA * i] = dyt2 [i];
            assign dyf3 [`BIT_DATA * (i + 1) - 1 : `BIT_DATA * i] = dyf2 [i];
            assign wyt4 [i] = dyt4 [`BIT_SOFTMAX * (i + 1) - 1 : `BIT_SOFTMAX * i];

        end
        
    endgenerate

    kernel_dense dense
    (
        .reset (reset),

        .ack_prev (ack_prev),
        .ack_nxt  (ack_dense_nxt),

        .xt (xt),
        .xf (xf),
        .wt (dwt [cnt]),
        .wf (dwf [cnt]),
        .yt (yt0),
        .yf (yf0)
    );

    kernel_softmax softmax 
    (
        .reset (reset),
        
        .ack_prev (ack_scale_softmax),
        .ack_nxt  (ack_softmax_nxt),

        .xt (dyt3),
        .xf (dyf3),
        .yt (dyt4),
        .yf (dyf4)
    );
    
endmodule