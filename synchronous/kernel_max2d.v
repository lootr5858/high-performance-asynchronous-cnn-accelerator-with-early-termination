`include "definitions.v"

module kernel_max2d
(
    input clock, reset,

    input signed [`BIT_DATA - 1 : 0] x0, x1, x2, x3,

    output reg signed [`BIT_DATA - 1 : 0] y
);

    reg signed [`BIT_DATA - 1 : 0] temp0, temp1;

    always @(posedge clock or posedge reset) begin

        if (reset) temp0 <= {`BIT_DATA{`OFF}};

        else begin

            if (x0 > x1) temp0 <= x0;

            else temp0 <= x1;
            
        end
        
    end

    always @(posedge clock or posedge reset) begin

        if (reset) temp1 <= {`BIT_DATA{`OFF}};

        else begin

            if (x2 > x3) temp1 <= x2;

            else temp1 <= x3;
            
        end
        
    end

    always @(posedge clock or posedge reset) begin

        if (reset) y <= {`BIT_DATA{`OFF}};

        else begin

            if (temp0 > temp1) y <= temp0;

            else y <= temp1;
            
        end
        
    end
    
endmodule