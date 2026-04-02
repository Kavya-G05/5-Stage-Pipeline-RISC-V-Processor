`timescale 1ns/1ps

module Processor_top_tb;

    // Testbench signals
    reg clk;
    reg rst;
   
    


    // Instantiate DUT (Design Under Test)
    Processor_top dut (
        .clk(clk),
        .rst(rst)
        
        // Connect outputs as needed if you have them as ports
    );

    // Clock generation (10 ns period)
    always #5 clk = ~clk;

    initial begin
        // Initialize signals
        clk = 0;
        rst = 0;
       
        // Reset pulse
        #20 rst = 1;

        

       

        // Let it run for a while
        #100;

        $finish;
    end

    // Monitor outputs

endmodule
