module AmbulanceDetector(
    input clk,
    input reset,
    input sound_in,
    output reg ambulance_detected
);

    reg [1:0] consecutive_count;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            consecutive_count <= 0;
            ambulance_detected <= 0;
        end
        else begin
            // Default outputs
            ambulance_detected <= 0;
            
            if (sound_in) begin
                if (consecutive_count < 2) begin
                    consecutive_count <= consecutive_count + 1;
                end
                else begin
                    ambulance_detected <= 1;
                    consecutive_count <= 0;  // Reset after detection
                end
            end
            else begin
                consecutive_count <= 0;  // Reset on sound_in=0
            end
        end
    end

endmodule