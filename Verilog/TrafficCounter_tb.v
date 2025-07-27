module TrafficCounter_tb;
    // Testbench signals
    reg clk, reset;
    reg PirAStart, PirAEnd;
    reg PirBStart, PirBEnd;
    reg PirCStart, PirCEnd;
    reg PirDStart, PirDEnd;
    wire [7:0] CountA, CountB, CountC, CountD;

    // Instantiate the module
    TrafficCounter uut (
        .clk(clk),
        .reset(reset),
        .PirAStart(PirAStart), .PirAEnd(PirAEnd),
        .PirBStart(PirBStart), .PirBEnd(PirBEnd),
        .PirCStart(PirCStart), .PirCEnd(PirCEnd),
        .PirDStart(PirDStart), .PirDEnd(PirDEnd),
        .CountA(CountA),
        .CountB(CountB),
        .CountC(CountC),
        .CountD(CountD)
    );

    // Clock generation (100MHz, 10ns period)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // VCD file generation
    initial begin
        $dumpfile("traffic_counter.vcd");
        $dumpvars(0, TrafficCounter_tb);
    end

    // Test stimulus
    initial begin
        // Initialize signals
        reset = 1;
        PirAStart = 0; PirAEnd = 0;
        PirBStart = 0; PirBEnd = 0;
        PirCStart = 0; PirCEnd = 0;
        PirDStart = 0; PirDEnd = 0;

        // Test Case 1: Reset
        #20 reset = 0;
        #10 $display("Test 1: Reset -> CountA=%d, CountB=%d, CountC=%d, CountD=%d", CountA, CountB, CountC, CountD);

        // Test Case 2: Road A increment by 2
        #10 PirAStart = 1; #10 PirAStart = 0;
        #10 PirAStart = 1; #10 PirAStart = 0;
        #10 $display("Test 2: Road A +2 -> CountA=%d, CountB=%d, CountC=%d, CountD=%d", CountA, CountB, CountC, CountD);

        // Test Case 3: Road B increment by 3
        #10 PirBStart = 1; #10 PirBStart = 0;
        #10 PirBStart = 1; #10 PirBStart = 0;
        #10 PirBStart = 1; #10 PirBStart = 0;
        #10 $display("Test 3: Road B +3 -> CountA=%d, CountB=%d, CountC=%d, CountD=%d", CountA, CountB, CountC, CountD);

        // Test Case 4: Road A decrement by 1
        #10 PirAEnd = 1; #10 PirAEnd = 0;
        #10 $display("Test 4: Road A -1 -> CountA=%d, CountB=%d, CountC=%d, CountD=%d", CountA, CountB, CountC, CountD);

        // Test Case 7: Road D decrement below zero
        #10 PirDStart = 1; #10 PirDStart = 0; // Ensure count > 0
        #10 PirDEnd = 1; #10 PirDEnd = 0;
        #10 PirDEnd = 1; #10 PirDEnd = 0;
        #10 $display("Test 7: Road D -1 (below 0) -> CountA=%d, CountB=%d, CountC=%d, CountD=%d", CountA, CountB, CountC, CountD);

        // Test Case 8: Simultaneous Start and End on Road A
        #10 PirAStart = 1; PirAEnd = 1; #10 PirAStart = 0; PirAEnd = 0;
        #10 $display("Test 8: Road A Start+End -> CountA=%d, CountB=%d, CountC=%d, CountD=%d", CountA, CountB, CountC, CountD);

        // Test Case 9: All roads increment by 1
        #10 PirAStart = 1; PirBStart = 1; PirCStart = 1; PirDStart = 1;
        #10 PirAStart = 0; PirBStart = 0; PirCStart = 0; PirDStart = 0;
        #10 $display("Test 9: All +1 -> CountA=%d, CountB=%d, CountC=%d, CountD=%d", CountA, CountB, CountC, CountD);

        // End simulation
        #50 $finish;
    end
endmodule