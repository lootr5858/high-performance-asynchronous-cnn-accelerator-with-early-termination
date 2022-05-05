`include "./definitions.v"

module handshake3
#(
    parameter BIT0 = 8,
    parameter BIT1 = 16,
    parameter BIT2 = 32
 )
(
    input reset,

    input [BIT0 - 1 : 0] dt_0, df_0,
    input [BIT1 - 1 : 0] dt_1, df_1,
    input [BIT2 - 1 : 0] dt_2, df_2,

    output ack_prev, inv,
    input  ack_nxt 
);

    wire [2:0] req;
    wire       verify, fire;
    reg        busy;

    assign req[0] = (dt_0 ^ df_0 == {BIT0{`ON}})  ? `ON :
                    (dt_0 ^ df_0 == {BIT0{`OFF}}) ? `OFF  : req[0];
    assign req[1] = (dt_1 ^ df_1 == {BIT1{`ON}})  ? `ON :
                    (dt_1 ^ df_1 == {BIT1{`OFF}}) ? `OFF  : req[1];
    assign req[2] = (dt_2 ^ df_2 == {BIT2{`ON}})  ? `ON :
                    (dt_2 ^ df_2 == {BIT2{`OFF}}) ? `OFF  : req[2];
    assign verify = (req == 3'b000) ? `OFF :
                    (req == 3'b111) ? `ON  : verify;

    assign fire = (verify ^ busy) & ~ack_nxt;

    assign inv = req[0] & req[1];

    assign ack_prev = busy;

    always @(fire or reset) begin

        if (reset) busy <= `OFF;

        else busy <= ~busy;
        
    end
    
endmodule