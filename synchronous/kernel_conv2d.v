`include "./definitions.v"

module kernel_conv2d
(
    input clock, reset,

    input signed [`BIT_DATA * `CONV2D_KSIZE - 1 : 0] x, w,

    output reg signed [BIT2 - 1 : 0] y
);

    wire signed [`BIT_DATA - 1 : 0] dx [0 : `CONV2D_KSIZE - 1],
                                    dw [0 : `CONV2D_KSIZE - 1];

    genvar i;

    generate

        for (i = 0; i < `CONV2D_KSIZE; i = i + 1) begin

            assign dx [i] = x [`BIT_DATA * (i + 1) - 1 : `BIT_DATA * i];
            assign dw [i] = w [`BIT_DATA * (i + 1) - 1 : `BIT_DATA * i];
            
        end
        
    endgenerate

    localparam BIT1 = `BIT_DATA * 2;
    localparam BIT2 = BIT1 + $clog2(`CONV2D_KSIZE - 1);

    reg signed [BIT1 - 1 : 0] mul [0 : `CONV2D_KSIZE - 1];
    reg signed [BIT2 - 1 : 0] add [0 : `CONV2D_KSIZE - 3];

    integer rm, ra, cm;

    always @(posedge clock or posedge reset) begin

        if (reset) begin

            for (rm = 0; rm < `CONV2D_KSIZE; rm = rm + 1) mul[rm] <= {BIT1{`OFF}};

            for (ra = 0; ra < `CONV2D_KSIZE - 2; ra = ra + 1) add[ra] <= {BIT2{`OFF}};

            y <= {BIT2{`OFF}};
            
        end

        else begin

            for (cm = 0; cm < `CONV2D_KSIZE; cm = cm + 1) mul [cm] <= dx [cm] * dw [cm];
            
            add[0] <= mul[0] + mul[1];
            add[1] <= mul[2] + mul[3];
            add[2] <= mul[4] + mul[5];
            add[3] <= mul[6] + mul[7];
            add[4] <= mul[8] + add[0];
            add[5] <= add[1] + add[2];
            add[6] <= add[3] + add[4];

            y <= add[5] + add[6];
            
        end

        
        
    end
    
endmodule