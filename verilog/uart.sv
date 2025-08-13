module uart
#(
    parameter DELAY_FRAMES = 234 // 27,000,000 (27Mhz) / 115200 Baud rate
)
(
    input clk,
    input uart_rx,
    output uart_tx,
    output reg [5:0] led,
    input send,
);

localparam HALF_DELAY_WAIT = (DELAY_FRAMES / 2);

reg [3:0] rxState = 0;
reg [12:0] rxCounter = 0;
reg [7:0] dataIn = 0;
reg [2:0] rxBitNumber = 0;
reg byteReady = 0;

localparam RX_STATE_IDLE = 0;
localparam RX_STATE_START_BIT = 1;
localparam RX_STATE_READ_WAIT = 2;
localparam RX_STATE_READ = 3;
localparam RX_STATE_STOP_BIT = 5;

always @(posedge clk) begin
    case (rxState)
        RX_STATE_IDLE: begin
            // Idle state
            if (uart_rx == 0) begin
                // If receives zero bit
                // Moves to start bit state
                rxState <= RX_STATE_START_BIT;
                rxCounter <= 1;
                rxBitNumber <= 0;
                byteReady <= 0;
            end
        end 
        RX_STATE_START_BIT: begin
            // Waits for start bit
            // Then moves to read wait state
            if (rxCounter == HALF_DELAY_WAIT) begin
                rxState <= RX_STATE_READ_WAIT;
                rxCounter <= 1;
            end else 
                rxCounter <= rxCounter + 1;
        end
        RX_STATE_READ_WAIT: begin
            // Waits to receive byte
            // Then read bits from the byte
            rxCounter <= rxCounter + 1;
            if ((rxCounter + 1) == DELAY_FRAMES) begin
                rxState <= RX_STATE_READ;
            end
        end
        RX_STATE_READ: begin
            // Reset the counter
            rxCounter <= 1;
            // Read a single bit
            dataIn <= {uart_rx, dataIn[7:1]};
            // Increment the index
            rxBitNumber <= rxBitNumber + 1;
            // If the byte is done being read
            if (rxBitNumber == 3'b111)
                // Stop
                rxState <= RX_STATE_STOP_BIT;
            else
                // Otherwise, keep reading bits
                rxState <= RX_STATE_READ_WAIT;
        end
        RX_STATE_STOP_BIT: begin
            // Waits for stop bit
            // Then moves to idle state
            rxCounter <= rxCounter + 1;
            if ((rxCounter + 1) == DELAY_FRAMES) begin
                rxState <= RX_STATE_IDLE;
                rxCounter <= 0;
                byteReady <= 1;
            end
        end
    endcase
end

always @(posedge clk) begin
    if (byteReady) begin
        led <= ~dataIn[5:0];
    end
end

reg [3:0] txState = 0;
reg [24:0] txCounter = 0;
reg [7:0] dataOut = 0;
reg txPinRegister = 1;
reg [2:0] txBitNumber = 0;
reg [3:0] txByteCounter = 0;

assign uart_tx = txPinRegister;

localparam MEMORY_LENGTH = 12;
reg [7:0] testMemory [MEMORY_LENGTH-1:0];

initial begin
    testMemory[0] = "B";
    testMemory[1] = "O";
    testMemory[2] = "O";
    testMemory[3] = " ";
    testMemory[4] = "N";
    testMemory[5] = "V";
    testMemory[6] = "I";
    testMemory[7] = "D";
    testMemory[8] = "I";
    testMemory[9] = "A";
    testMemory[10] = "!";
    testMemory[11] = "!";
end

localparam TX_STATE_IDLE = 0;
localparam TX_STATE_START_BIT = 1;
localparam TX_STATE_WRITE = 2;
localparam TX_STATE_STOP_BIT = 3;

always @(posedge clk) begin
    case (txState)
        TX_STATE_IDLE: begin
            if (send) begin
                // If send flag is set, start sending data
                txState <= TX_STATE_START_BIT;
                txCounter <= 0;
                txByteCounter <= 0;
            end
            else begin
                // Hold pin at 1.
                txPinRegister <= 1;
            end
        end 
        TX_STATE_START_BIT: begin
            // Set to 0 for start bit.
            txPinRegister <= 0;
            // Delay
            if ((txCounter + 1) == DELAY_FRAMES) begin
                txState <= TX_STATE_WRITE;
                dataOut <= testMemory[txByteCounter];
                txBitNumber <= 0;
                txCounter <= 0;
            end else 
                txCounter <= txCounter + 1;
        end
        TX_STATE_WRITE: begin
            // Write 1 bit
            txPinRegister <= dataOut[txBitNumber];
            if ((txCounter + 1) == DELAY_FRAMES) begin
                if (txBitNumber == 3'b111) begin
                    // End packet
                    txState <= TX_STATE_STOP_BIT;
                end else begin
                    // Keep writing
                    txState <= TX_STATE_WRITE;
                    txBitNumber <= txBitNumber + 1;
                end
                // Reset counter
                txCounter <= 0;
            end else 
                txCounter <= txCounter + 1;
        end
        TX_STATE_STOP_BIT: begin
            // Set to 1 for stop bit
            txPinRegister <= 1;
            if ((txCounter + 1) == DELAY_FRAMES) begin
                if (txByteCounter == MEMORY_LENGTH - 1) begin
                    // End transmission
                    txState <= TX_STATE_IDLE;
                end else begin
                    // Start next packet
                    txByteCounter <= txByteCounter + 1;
                    txState <= TX_STATE_START_BIT;
                end
                // Reset counter
                txCounter <= 0;
            end else 
                txCounter <= txCounter + 1;
        end
    endcase      
end
endmodule
