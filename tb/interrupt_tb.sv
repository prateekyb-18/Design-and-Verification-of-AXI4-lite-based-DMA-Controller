module interrupt_tb;

    logic clk;
    logic rst_n;

    logic dma_done;
    logic irq_enable;
    logic irq_clear;

    logic irq;

    integer pass_count;
    integer fail_count;

    // DUT

    interrupt dut(
        .clk(clk),
        .rst_n(rst_n),
        .dma_done(dma_done),
        .irq_enable(irq_enable),
        .irq_clear(irq_clear),
        .irq(irq)
    );

    // Clock Generation

    always #5 clk = ~clk;

    // Reset Task

    task reset_dut();
    begin
        rst_n = 0;

        dma_done   = 0;
        irq_enable = 0;
        irq_clear  = 0;

        repeat(2) @(posedge clk);

        rst_n = 1;

        @(posedge clk);
    end
    endtask

    // Check Task

    task check_irq(
        input logic expected,
        input string test_name
    );
    begin

        if(irq == expected)
        begin
            pass_count++;
            $display("[PASS] %s", test_name);
        end
        else
        begin
            fail_count++;
            $error("[FAIL] %s Expected=%0b Actual=%0b",
                    test_name,expected,irq);
        end

    end
    endtask

    // Test Sequence

    initial begin

        clk = 0;

        pass_count = 0;
        fail_count = 0;

       
        // RESET TEST
        

        reset_dut();

        check_irq(1'b0,"RESET_TEST");

       
        // IRQ GENERATION TEST
      

        irq_enable = 1;
        dma_done   = 1;

        @(posedge clk);

        dma_done = 0;

        check_irq(1'b1,"IRQ_GENERATION");

        
        // IRQ LATCH TEST
        
        repeat(2) @(posedge clk);

        check_irq(1'b1,"IRQ_LATCH");

        //---------------------------------
        // IRQ CLEAR TEST
       

        irq_clear = 1;

        @(posedge clk);

        irq_clear = 0;

        check_irq(1'b0,"IRQ_CLEAR");

        //---------------------------------
        // IRQ DISABLED TEST
    

        irq_enable = 0;
        dma_done   = 1;

        @(posedge clk);

        dma_done = 0;

        check_irq(1'b0,"IRQ_DISABLED");

        //---------------------------------
        // PRIORITY TEST
        // dma_done and irq_clear together
        //---------------------------------

        irq_enable = 1;

        dma_done  = 1;
        irq_clear = 1;

        @(posedge clk);

        dma_done  = 0;
        irq_clear = 0;

        check_irq(1'b1,"PRIORITY_TEST");

        
        // SUMMARY
     
        $display("=================================");
        $display("PASS COUNT = %0d", pass_count);
        $display("FAIL COUNT = %0d", fail_count);
        $display("=================================");

        $finish;

    end

    // waveform Dump

    initial begin
        $dumpfile("interrupt.vcd");
        $dumpvars(0, interrupt_tb);
    end

endmodule
