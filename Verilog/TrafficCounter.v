module TrafficCounter (
    input wire clk, reset,
    input wire PirAStart, PirAEnd,
    input wire PirBStart, PirBEnd,
    input wire PirCStart, PirCEnd,
    input wire PirDStart, PirDEnd,
    output reg [7:0] CountA,
    output reg [7:0] CountB,
    output reg [7:0] CountC,
    output reg [7:0] CountD
);

    // Next state counters
    reg [7:0] next_countA, next_countB, next_countC, next_countD;

    // Sequential logic for updating counters
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            CountA <= 8'b0;
            CountB <= 8'b0;
            CountC <= 8'b0;
            CountD <= 8'b0;
        end else begin
            CountA <= next_countA;
            CountB <= next_countB;
            CountC <= next_countC;
            CountD <= next_countD;
        end
    end

    // Combinational logic for counter updates
    always @(*) begin
        // Default: maintain current counts
        next_countA = CountA;
        next_countB = CountB;
        next_countC = CountC;
        next_countD = CountD;

        // Road A counter logic
        if (PirAStart && !PirAEnd) begin
            next_countA = (CountA < 255) ? CountA + 1 : CountA; // Increment, prevent overflow
        end else if (PirAEnd && !PirAStart && CountA > 0) begin
            next_countA = CountA - 1; // Decrement, prevent underflow
        end

        // Road B counter logic
        if (PirBStart && !PirBEnd) begin
            next_countB = (CountB < 255) ? CountB + 1 : CountB;
        end else if (PirBEnd && !PirBStart && CountB > 0) begin
            next_countB = CountB - 1;
        end

        // Road C counter logic
        if (PirCStart && !PirCEnd) begin
            next_countC = (CountC < 255) ? CountC + 1 : CountC;
        end else if (PirCEnd && !PirCStart && CountC > 0) begin
            next_countC = CountC - 1;
        end

        // Road D counter logic
        if (PirDStart && !PirDEnd) begin
            next_countD = (CountD < 255) ? CountD + 1 : CountD;
        end else if (PirDEnd && !PirDStart && CountD > 0) begin
            next_countD = CountD - 1;
        end
    end

endmodule