`include "./definitions.v"

module handshake2
#(
    parameter BIT0 = 8,
    parameter BIT1 = 16
 )
(
    input reset,

    input [BIT0 - 1 : 0] dt_0, df_0,
    input [BIT1 - 1 : 0] dt_1, df_1,

    output ack_prev, inv,
    input  ack_nxt
);

    wire [1:0] req;
    wire       verify, fire;
    reg        busy;

    assign req[0] = (dt_0 ^ df_0 == {BIT0{`ON}})  ? `ON :
                    (dt_0 ^ df_0 == {BIT0{`OFF}}) ? `OFF  : req[0];
    assign req[1] = (dt_1 ^ df_1 == {BIT0{`ON}})  ? `ON :
                    (dt_1 ^ df_1 == {BIT0{`OFF}}) ? `OFF  : req[1];
    assign verify = (req == 2'b00) ? `OFF :
                    (req == 2'b11) ? `ON  : verify;

    assign fire = (verify ^ busy) & ~ack_nxt;

    assign inv = req[0];

    assign ack_prev = busy;

     always @(posedge fire or posedge reset) begin

         if (reset) busy <= `OFF;

         else #1 busy <= ~busy;
        
     end
    
endmodule