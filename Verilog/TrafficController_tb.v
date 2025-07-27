module TrafficController_tb;

    // Inputs
    reg clk;
    reg reset;
    reg sound_in_A, sound_in_B, sound_in_C, sound_in_D;
    reg PirAStart, PirAEnd, PirBStart, PirBEnd, PirCStart, PirCEnd, PirDStart, PirDEnd;
    
    // Outputs
    wire [1:0] right_lane_signals;
    wire left_lane_signals_A, left_lane_signals_B, left_lane_signals_C, left_lane_signals_D;
    
    // Instantiate the Unit Under Test (UUT)
    TrafficController uut (
        .clk(clk),
        .reset(reset),
        .sound_in_A(sound_in_A),
        .sound_in_B(sound_in_B),
        .sound_in_C(sound_in_C),
        .sound_in_D(sound_in_D),
        .PirAStart(PirAStart),
        .PirAEnd(PirAEnd),
        .PirBStart(PirBStart),
        .PirBEnd(PirBEnd),
        .PirCStart(PirCStart),
        .PirCEnd(PirCEnd),
        .PirDStart(PirDStart),
        .PirDEnd(PirDEnd),
        .right_lane_signals(right_lane_signals),
        .left_lane_signals_A(left_lane_signals_A),
        .left_lane_signals_B(left_lane_signals_B),
        .left_lane_signals_C(left_lane_signals_C),
        .left_lane_signals_D(left_lane_signals_D)
    );
    
    // Clock generation (1Hz for easier time tracking)
    initial begin
        clk = 0;
        forever #500 clk = ~clk; // 1Hz clock (1 second per cycle)
    end
    
    // Initialize VCD dumping
    initial begin
        $dumpfile("traffic_controller.vcd");
        $dumpvars(0, TrafficController_tb);
    end
    
    // Vehicle control tasks
    task add_vehicles_roadA;
        input [3:0] count;
        integer i;
        begin
            for (i = 0; i < count; i = i + 1) begin
                PirAStart = 1; #1000;
                PirAEnd = 1; #1000;
                PirAStart = 0; PirAEnd = 0; #1000;
            end
        end
    endtask
    
    task remove_vehicles_roadA;
        input [3:0] count;
        integer i;
        begin
            for (i = 0; i < count; i = i + 1) begin
                PirAEnd = 1; #1000;
                PirAStart = 0; PirAEnd = 0; #1000;
            end
        end
    endtask
    
    task add_vehicles_roadB;
        input [3:0] count;
        integer i;
        begin
            for (i = 0; i < count; i = i + 1) begin
                PirBStart = 1; #1000;
                PirBEnd = 1; #1000;
                PirBStart = 0; PirBEnd = 0; #1000;
            end
        end
    endtask
    
    task add_vehicles_roadC;
        input [3:0] count;
        integer i;
        begin
            for (i = 0; i < count; i = i + 1) begin
                PirCStart = 1; #1000;
                PirCEnd = 1; #1000;
                PirCStart = 0; PirCEnd = 0; #1000;
            end
        end
    endtask
    
    task add_vehicles_roadD;
        input [3:0] count;
        integer i;
        begin
            for (i = 0; i < count; i = i + 1) begin
                PirDStart = 1; #1000;
                PirDEnd = 1; #1000;
                PirDStart = 0; PirDEnd = 0; #1000;
            end
        end
    endtask
    
    // Ambulance detection task
    task trigger_ambulance;
        input [1:0] road;
        begin
            case(road)
                2'b00: begin sound_in_A = 1; #3000; sound_in_A = 0; end
                2'b01: begin sound_in_B = 1; #3000; sound_in_B = 0; end
                2'b10: begin sound_in_C = 1; #3000; sound_in_C = 0; end
                2'b11: begin sound_in_D = 1; #3000; sound_in_D = 0; end
            endcase
        end
    endtask
    
    initial begin
        // Initialize all inputs
        reset = 1;
        sound_in_A = 0; sound_in_B = 0; sound_in_C = 0; sound_in_D = 0;
        PirAStart = 0; PirAEnd = 0;
        PirBStart = 0; PirBEnd = 0;
        PirCStart = 0; PirCEnd = 0;
        PirDStart = 0; PirDEnd = 0;
        
        // Reset the system
        #2000;
        reset = 0;
        #1000;
        
        // Test Case 1: Basic traffic pattern
        $display("=== TEST 1: Basic traffic pattern ===");
        add_vehicles_roadA(5);  // Add 5 vehicles to Road A
        add_vehicles_roadB(3);  // Add 3 vehicles to Road B
        add_vehicles_roadC(7);  // Add 7 vehicles to Road C
        add_vehicles_roadD(2);  // Add 2 vehicles to Road D
        #60000;  // Wait for 1 minute
        
        // Test Case 2: Ambulance priority
        $display("=== TEST 2: Ambulance priority ===");
        trigger_ambulance(2'b01);  // Ambulance on Road B
        #60000;  // Wait for 1 minute
        
        // Test Case 3: Starvation check
        $display("=== TEST 3: Starvation check ===");
        add_vehicles_roadC(10); // Heavy traffic on Road C
        #120000; // Wait 2 minutes to observe if other roads get turns
        
        // Test Case 4: Pedestrian interval
        $display("=== TEST 4: Pedestrian interval ===");
        // Wait until next pedestrian interval
        #(240000 - ($time % 240000));
        #60000; // Observe pedestrian interval
        
        // Test Case 5: Mixed scenario
        $display("=== TEST 5: Mixed scenario ===");
        add_vehicles_roadA(3);
        add_vehicles_roadB(5);
        trigger_ambulance(2'b11); // Ambulance on Road D
        add_vehicles_roadC(2);
        add_vehicles_roadD(4);
        #120000;
        
        // Test Case 6: Left lane signal check
        $display("=== TEST 6: Left lane signal check ===");
        #240000; // Wait full cycle to observe left lane patterns
        
        $display("=== Simulation Complete ===");
        $finish;
    end
    
    // Monitor to track important signals
    always @(posedge clk) begin
        $display("Time: %0ds | Right Lane: %b | Left Lanes: A:%b B:%b C:%b D:%b | Current Road: %d | Next Road: %d | Ped Timer: %0d",
                 $time/1000, 
                 right_lane_signals, 
                 left_lane_signals_A, left_lane_signals_B, 
                 left_lane_signals_C, left_lane_signals_D,
                 uut.current_road,
                 uut.next_road,
                 uut.pedestrian_timer);
        
        // Display vehicle counts periodically
        if($time % 30000 == 0) begin
            $display("Vehicle Counts - A:%0d B:%0d C:%0d D:%0d",
                    uut.CountA, uut.CountB, uut.CountC, uut.CountD);
        end
    end

endmodule