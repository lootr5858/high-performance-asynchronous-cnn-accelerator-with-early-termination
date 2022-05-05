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

    input        [$clog2(`DENSE_KSIZE) - 1 : 0] addr0,
    input        [$clog2(SIZE)         - 1 : 0] addr1,
    input signed [BIT_IN               - 1 : 0] w,

    input signed [`BIT_DATA - 1 : 0] x,
    input        [BIT_SH    - 1 : 0] scale,

    output reg signed [`BIT_SOFTMAX - 1 : 0] z,
    output reg        [`BIT_O       - 1 : 0] index

);

    localparam BITc = $clog2(SIZE);
    localparam BIT0 = `BIT_DATA * 2;
    localparam BIT1 = BIT0 * `DENSE_KSIZE;
    localparam BIT2 = `BIT_DATA * `DENSE_KSIZE;

    wire signed [BIT1 - 1 : 0] yy0;
    wire signed [BIT2 - 1 : 0] yy2;
    
    wire signed [BIT0         - 1 : 0] y0 [0 : `DENSE_KSIZE - 1];
    wire signed [`BIT_DATA    - 1 : 0] y2 [0 : `DENSE_KSIZE - 1];
    wire signed [`BIT_SOFTMAX * `DENSE_KSIZE   - 1 : 0] temp;
    wire signed [`BIT_SOFTMAX - 1 : 0] temp1 [0 : `DENSE_KSIZE - 1];

    reg signed [BIT_IN - 1 : 0] dw [0 : SIZE - 1];
    reg signed [BIT_MA - 1 : 0] y1 [0 : `DENSE_KSIZE - 1];
    reg signed [BITc   - 1 : 0] cnt;

    integer ri, rj, lw, c0, c1, c2, cp;
    genvar  i;

    always @(posedge clock or posedge reset) begin

        if (reset) begin

            for (ri = 0; ri < `DENSE_KSIZE; ri = ri + 1) y1 [ri] <= {BIT_MA{`OFF}};

            for (rj = 0; rj < SIZE; rj = rj + 1) dw [rj] <= {BIT_IN{`OFF}};

            cnt <= {BITc{`OFF}};
            
        end

        else if (load) dw [addr0][addr1] <= w;

        else begin

            if (cnt == {BITc{`OFF}}) begin

                for (c0 = 0; c0 < `DENSE_KSIZE; c0 = c0 + 1) y1 [c0] <= {BIT_MA{`OFF}} + y0 [c0];

                cnt <= cnt + `ON;
                
            end

            else if (cnt == SIZE - 1) begin

                for (c1 = 0; c1 < `DENSE_KSIZE; c1 = c1 + 1) y1 [c1] <= y1 [c1] + y0 [c1];

                cnt <= {BITc{`OFF}};
                
            end

            else begin

                for (c2 = 0; c2 < `DENSE_KSIZE; c2 = c2 + 1) y1 [c2] <= y1 [c2] + y0 [c2];

                cnt <= cnt + `ON;
                
            end
            
        end
        
    end

    always @(posedge clock or posedge reset) begin

        if (reset) z <= {`BIT_SOFTMAX{`OFF}};

        else begin

            for (cp = 1; cp < `DENSE_KSIZE; cp = cp + 1) begin

                if (temp1[cp - 1] > temp1[cp]) begin 
                    
                    z     <= temp1[cp - 1];
                    index <= cp - 1;

                end

                else begin 
                    
                    z     <= temp1[cp];
                    index <= cp;

                end
                
            end
            
        end
        
    end

    generate

        for (i = 0; i < `DENSE_KSIZE; i = i + 1) begin

            assign yy2 [`BIT_DATA * (i + 1) - 1 : `BIT_DATA * i] = y2 [i];

            assign y0 [i] = yy0 [BIT0 * (i + 1) - 1 : BIT0 * i];

            assign temp1[i] = temp [`BIT_SOFTMAX * (i + 1) - 1 : `BIT_SOFTMAX * i];

            kernel_scale #(.BIT_IN (BIT_MA)) scale 
            (
                .clock (clock),
                .reset (reset),

                .x (y1 [i]),
                .y (y2 [i])
            );

        end
        
    endgenerate

    kernel_dense dense 
    (
        .clock (clock),
        .reset (reset),

        .x (x),
        .w (dw[cnt]),

        .y (yy0)
    );

    kernel_softmax softmax 
    (
        .clock (clock),
        .reset (reset),

        .x (yy2),
        .y (temp)
    );
    
endmodule