module TrafficController (
    input wire clk,            // Input clock (assumed 1 Hz for simplicity)
    input wire reset,          // Reset signal
    input wire sound_in_A,     // Sound input for Road A
    input wire sound_in_B,     // Sound input for Road B
    input wire sound_in_C,     // Sound input for Road C
    input wire sound_in_D,     // Sound input for Road D
    input wire PirAStart, PirAEnd,  // PIR sensors input for Road A
    input wire PirBStart, PirBEnd,  // PIR sensors input for Road B
    input wire PirCStart, PirCEnd,  // PIR sensors input for Road C
    input wire PirDStart, PirDEnd,  // PIR sensors input for Road D    
    output reg [1:0] right_lane_signals,  // 00=A, 01=B, 10=C, 11=D (green for right lane)
    output reg left_lane_signals_A,      // Green signal for left lane of Road A
    output reg left_lane_signals_B,      // Green signal for left lane of Road B
    output reg left_lane_signals_C,      // Green signal for left lane of Road C
    output reg left_lane_signals_D       // Green signal for left lane of Road D
);

    // Parameters
    parameter AMBULANCE_WEIGHT = 100;  // High priority weight for ambulance
    parameter GREEN_DURATION = 60;     // 60 seconds for right lane green
    parameter PEDESTRIAN_INTERVAL = 300; // 300 seconds (5 minutes) total cycle
    parameter LEFT_GREEN_DURATION = 240; // Left lane green for 4 minutes
    parameter LEFT_RED_DURATION = 60;   // Left lane red for 1 minute
    
    // Internal registers
    reg [8:0] green_timer;             // Needs to count up to 300
    reg [8:0] pedestrian_timer;        // Needs to count up to 300
    reg [5:0] age_timer;               // Counts up to 60 seconds for age increment
    reg age_increment_flag;            // Flag for age increment
    reg [1:0] current_road;            // 00=A, 01=B, 10=C, 11=D
    reg [1:0] next_road;
    reg[1:0] force_red; // Force red signal for all lanes during pedestrian interval
    
    // Traffic counts from TrafficCounter
    wire [7:0] CountA, CountB, CountC, CountD;
    
    // Ambulance detection flags
    wire ambulance_A, ambulance_B, ambulance_C, ambulance_D;
    reg pending_ambulance_A, pending_ambulance_B, pending_ambulance_C, pending_ambulance_D;
    
    // Age counters for each road (to prevent starvation)
    reg [7:0] age_A, age_B, age_C, age_D;
    
    // Priority values
    integer priority_A, priority_B, priority_C, priority_D;
    
    // Instantiate TrafficCounter module
    TrafficCounter traffic_counter (
        .clk(clk),
        .reset(reset),
        .PirAStart(PirAStart),
        .PirAEnd(PirAEnd),
        .PirBStart(PirBStart),
        .PirBEnd(PirBEnd),
        .PirCStart(PirCStart),
        .PirCEnd(PirCEnd),
        .PirDStart(PirDStart),
        .PirDEnd(PirDEnd),
        .CountA(CountA),
        .CountB(CountB),
        .CountC(CountC),
        .CountD(CountD)
    );
    
    // Instantiate AmbulanceDetector modules for each road
    AmbulanceDetector ambulance_detector_A (
        .clk(clk),
        .reset(reset),
        .sound_in(sound_in_A),
        .ambulance_detected(ambulance_A)
    );
    
    AmbulanceDetector ambulance_detector_B (
        .clk(clk),
        .reset(reset),
        .sound_in(sound_in_B),
        .ambulance_detected(ambulance_B)
    );
    
    AmbulanceDetector ambulance_detector_C (
        .clk(clk),
        .reset(reset),
        .sound_in(sound_in_C),
        .ambulance_detected(ambulance_C)
    );
    
    AmbulanceDetector ambulance_detector_D (
        .clk(clk),
        .reset(reset),
        .sound_in(sound_in_D),
        .ambulance_detected(ambulance_D)
    );
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pending_ambulance_A <= 0;
            pending_ambulance_B <= 0;
            pending_ambulance_C <= 0;
            pending_ambulance_D <= 0;
        end else begin
            // Set pending flag when ambulance is detected
            if (ambulance_A) pending_ambulance_A <= 1;
            if (ambulance_B) pending_ambulance_B <= 1;
            if (ambulance_C) pending_ambulance_C <= 1;
            if (ambulance_D) pending_ambulance_D <= 1;

            // Clear pending ambulance flag when the current road gets green signal and timer resets
            if (current_road == 2'b00 && green_timer == 0) pending_ambulance_A <= 0;
            if (current_road == 2'b01 && green_timer == 0) pending_ambulance_B <= 0;
            if (current_road == 2'b10 && green_timer == 0) pending_ambulance_C <= 0;
            if (current_road == 2'b11 && green_timer == 0) pending_ambulance_D <= 0;
        end
    end

    
    // Timer and priority calculation logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            green_timer <= 0;
            pedestrian_timer <= 0;
            age_timer <= 0;
            age_increment_flag <= 0;
            current_road <= 2'b00; // Start with Road A
            age_A <= 0;
            age_B <= 0;
            age_C <= 0;
            age_D <= 0;
        end else begin
            // Increment timers
            green_timer <= green_timer + 1;
            pedestrian_timer <= pedestrian_timer + 1;
            age_timer <= age_timer + 1;
            
            // Age increment control - set flag every 60 seconds
            if (age_timer >= GREEN_DURATION) begin
                age_increment_flag <= 1;
                age_timer <= 0;
            end else begin
                age_increment_flag <= 0;
            end
            
            // Reset timers at end of cycle
            if (pedestrian_timer >= PEDESTRIAN_INTERVAL) begin
                pedestrian_timer <= 0;
                green_timer <= 0;
                age_timer <= 0;
                // Reset ages during pedestrian interval
                age_A <= 0;
                age_B <= 0;
                age_C <= 0;
                age_D <= 0;
            end
            
            // Normal operation (not pedestrian interval)
            if (pedestrian_timer < PEDESTRIAN_INTERVAL) begin
                // Update ages (increment for non-current roads only every 60 seconds)
                if (age_increment_flag) begin
                    if (current_road != 2'b00) age_A <= age_A + 1;
                    if (current_road != 2'b01) age_B <= age_B + 1;
                    if (current_road != 2'b10) age_C <= age_C + 1;
                    if (current_road != 2'b11) age_D <= age_D + 1;
                end
                
                // Calculate priorities
                priority_A = CountA + (pending_ambulance_A ? AMBULANCE_WEIGHT : 0) + age_A;
                priority_B = CountB + (pending_ambulance_B ? AMBULANCE_WEIGHT : 0) + age_B;
                priority_C = CountC + (pending_ambulance_C ? AMBULANCE_WEIGHT : 0) + age_C;
                priority_D = CountD + (pending_ambulance_D ? AMBULANCE_WEIGHT : 0) + age_D;
                
                // Determine next road with highest priority
                next_road = 2'b00; // Default to Road A
                if (priority_B > priority_A && priority_B > priority_C && priority_B > priority_D)
                    next_road = 2'b01;
                else if (priority_C > priority_A && priority_C > priority_B && priority_C > priority_D)
                    next_road = 2'b10;
                else if (priority_D > priority_A && priority_D > priority_B && priority_D > priority_C)
                    next_road = 2'b11;
                
                // Check if right lane green duration has completed
                if (green_timer >= GREEN_DURATION) begin
                    green_timer <= 0;
                    current_road <= next_road;
                    // Reset age for the new current road
                    case (next_road)
                        2'b00: age_A <= 0;
                        2'b01: age_B <= 0;
                        2'b10: age_C <= 0;
                        2'b11: age_D <= 0;
                    endcase
                end
            end
        end
    end
    
    // Output signal generation
    always @(*) begin
        // Default all signals to red
        right_lane_signals = 2'b00;
        left_lane_signals_A = 0;
        left_lane_signals_B = 0;
        left_lane_signals_C = 0;
        left_lane_signals_D = 0;
        force_red = 2'b01; // Default to no force red
         
        // Pedestrian interval (last minute of 5-minute cycle)
        if (pedestrian_timer >= LEFT_GREEN_DURATION) begin
            // All signals remain red
        end else begin
            // Left lane signals (green for first 4 minutes)
            left_lane_signals_A = 1;
            left_lane_signals_B = 1;
            left_lane_signals_C = 1;
            left_lane_signals_D = 1;
            force_red = 2'b00; // Force red for all lanes during pedestrian interval
            
            // Right lane signals (changes every minute)
            case (current_road)
                2'b00: right_lane_signals = 2'b00; // Road A green
                2'b01: right_lane_signals = 2'b01; // Road B green
                2'b10: right_lane_signals = 2'b10; // Road C green
                2'b11: right_lane_signals = 2'b11; // Road D green
            endcase
        end
    end

endmodule