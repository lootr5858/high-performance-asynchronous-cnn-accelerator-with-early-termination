`include "./definitions.v"

module kernel_softmax
(
    input clock, reset,

    input signed [`BIT_DATA * `DENSE_KSIZE - 1 : 0] x,

    output signed [`BIT_SOFTMAX * `DENSE_KSIZE - 1 : 0] y
);

    wire [`BIT_DATA    - 1 : 0] dx  [0 : `DENSE_KSIZE - 1];
    reg  [`BIT_SOFTMAX - 1 : 0] dy  [0 : `DENSE_KSIZE - 1],
                                px  [0 : `DENSE_KSIZE - 1],
                                sum [0 : `DENSE_KSIZE - 2];

    genvar i;
    
    integer ri, rj, ci, cj;

    generate

        for (i = 0; i < `DENSE_KSIZE; i = i + 1) begin

            assign dx [i] = x [`BIT_DATA * (i + 1) - 1 : `BIT_DATA * i];
            
            assign y [`BIT_SOFTMAX * (i + 1) - 1 : `BIT_SOFTMAX * i] = dy [i];
            
        end
        
    endgenerate

    always @(posedge clock or posedge reset) begin

        if (reset) begin
            
            for (ri = 0; ri < `DENSE_KSIZE; ri = ri + 1) begin

                dy [ri] <= {`BIT_SOFTMAX{`OFF}};
                px [ri] <= {`BIT_SOFTMAX{`OFF}};
                
            end

            for (rj = 0; rj < `DENSE_KSIZE - 1; rj = rj + 1) sum [rj] <= {`BIT_SOFTMAX{`OFF}};

        end

        else begin

            for (ci = 0; ci < `DENSE_KSIZE; ci = ci + 1) begin

                dy [ci] <= px [ci] / sum [`DENSE_KSIZE - 2];
                px [ci] <= 2 ** dx[ci];
                
            end

            for (cj = 0; cj < `DENSE_KSIZE - 2; cj = cj + 1) begin

                if (cj < (`DENSE_KSIZE / 2)) sum [cj] <= px [cj * 2] + px [cj * 2 + 1];

                else sum [cj] <= sum [(cj - (`DENSE_KSIZE/2)) * 2] + sum [(cj - (`DENSE_KSIZE/2)) * 2 + 1];
                
            end

            sum [`DENSE_KSIZE - 2] <= sum [`DENSE_KSIZE - 3] + sum [`DENSE_KSIZE - 4];
            
        end
        
    end
    
endmodule