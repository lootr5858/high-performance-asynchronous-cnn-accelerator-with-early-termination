`include "./definitions.v"

module kernel_relu
(
    input clock, reset,

    input signed [`BIT_DATA - 1 : 0] x,

    output reg signed [`BIT_DATA - 1 : 0] y
);

    always @(posedge clock or posedge reset) begin

        if (reset) y <= {`BIT_DATA{`OFF}};

        else begin

            if (x[`BIT_DATA - 1] == `ON) y <= {`BIT_DATA{`OFF}};

            else y <= x;
            
        end
        
    end
    
endmodule