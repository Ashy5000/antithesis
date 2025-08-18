`include "uart.sv"

module gpu (
    input clk,
    input uart_rx,
    output uart_tx,
    output reg [5:0] led,
    input btn1
);

reg [1:0] state;
reg [1:0] send;
reg [23:0] counter;

always @(posedge clk) begin
    counter <= counter + 1;
    if (send == 1)
        send <= 0;
    if (counter == 0)
        send <= 1;
end

uart mod_uart (
    .clk,
    .uart_rx,
    .uart_tx,
    .led,
    .send,
);

endmodule
