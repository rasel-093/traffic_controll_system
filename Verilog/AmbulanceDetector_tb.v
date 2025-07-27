`timescale 1ns / 1ps

module AmbulanceDetector_tb;
    // Inputs
    reg clk;
    reg reset;
    reg sound_in;
    
    // Outputs
    wire ambulance_detected;
    
    // Internal signal monitoring
    wire [1:0] consecutive_count = uut.consecutive_count;
    
    // Instantiate the Unit Under Test (UUT)
    AmbulanceDetector uut (
        .clk(clk),
        .reset(reset),
        .sound_in(sound_in),
        .ambulance_detected(ambulance_detected)
    );
    
    // Clock generation (100MHz)
    always #5 clk = ~clk;

     // VCD file generation
    initial begin
        $dumpfile("ambulance_detector.vcd");
        $dumpvars(0, AmbulanceDetector_tb);
    end
    
    initial begin
        // Initialize signals
        clk = 0;
        reset = 0;
        sound_in = 0;
        
        // Setup monitoring
      $monitor("Time = %0t ns | clk = %b | sound_in = %b | count = %d | detected = %b", 
                $time,clk, sound_in, consecutive_count, ambulance_detected);
        
        // Test 1: Reset test
        $display("\n=== Test 1: Reset ===");
        reset = 1;
        #20;
        reset = 0;
        #10;
        
        // Test 2: Exactly 3 consecutive 1's
        $display("\n=== Test 2: 3 consecutive 1's ===");
        sound_in = 1; #10;  // count should be 1
        sound_in = 1; #10;  // count should be 2
        sound_in = 1; #10;  // should trigger and reset count
        sound_in = 0; #10;
        #10;
        
        // Test 3: 2 consecutive 1's (should not trigger)
        $display("\n=== Test 3: 2 consecutive 1's ===");
        sound_in = 1; #10;  // count = 1
        sound_in = 1; #10;  // count = 2
        sound_in = 0; #10;  // should reset
        #10;
        
        // Test 4: 6 consecutive 1's (should trigger once at 3rd)
        $display("\n=== Test 4: 6 consecutive 1's ===");
        sound_in = 1; #60;  // 6 cycles
        sound_in = 0; #10;
        #10;
        
        // Test 5: Interrupted pattern 1-0-1-1-0-1-1-1
        $display("\n=== Test 5: Interrupted pattern ===");
        sound_in = 1; #10;  // count = 1
        sound_in = 0; #10;  // reset
        sound_in = 1; #10;  // count = 1
        sound_in = 1; #10;  // count = 2
        sound_in = 0; #10;  // reset
        sound_in = 1; #10;  // count = 1
        sound_in = 1; #10;  // count = 2
        sound_in = 1; #10;  // trigger
        sound_in = 0; #10;
        #10;
        
        $display("\n=== All tests completed ===");
        $finish;
    end
endmodule