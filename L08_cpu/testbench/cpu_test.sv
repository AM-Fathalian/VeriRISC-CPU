module cpu_test;

//==============================================================
// A practical testbench top typically contains: 
// (1) declarations of TB signals, 
// (2) DUT instantiation, 
// (3) clock/reset processes, 
// (4) stimulus (tasks or sequences), 
// (5) monitoring/checking (assertions/scoreboard), 
// (6) an end condition + timeout so a hung test doesn’t run forever.
//==============================================================

  //============================================================
  // (1) TB SHELL: time setup + imports + TB-owned declarations
  //============================================================
  timeunit 1ns;                 // TB time unit (delays like #5 mean 5ns in this module).
  timeprecision 100ps;          // Rounding precision for time delays/events in this module.

  import typedefs::*;           // Pull in shared types (ex: opcode_t enum/typedef).

  logic          rst_;           // Active-low reset (note the underscore naming convention).
  logic [12*8:1] testfile;      // Holds an ASCII filename (string packed into bits).
  opcode_t       topcode;        // For printing decoded instruction name().
  logic [31:0]   test_number;    // User-selected test ID.

  logic clk, alu_clk, cntrl_clk, clk2, fetch, halt;
  logic load_ir;

  //============================================================
  // (2) DUT INSTANTIATION: connect TB signals to the DUT ports
  //============================================================
  cpu cpu1 (
    .halt      (halt),
    .load_ir   (load_ir),
    .clk       (clk),
    .alu_clk   (alu_clk),
    .cntrl_clk (cntrl_clk),
    .fetch     (fetch),
    .rst_      (rst_)
  );

  //============================================================
  // (3) CLOCK/RESET GENERATION: create clocks/phases + apply reset
  //     (Reset sequencing itself is done later in the stimulus.)
  //============================================================

  // clock generator
  `define PERIOD 10
  logic master_clk = 1'b1;      // The only "real" oscillator. Everything else is derived.

  logic [3:0] count;            // Counter used to derive different phase clocks.

  // (3a) Master clock: toggles forever every PERIOD/2.
  always
    #(`PERIOD/2) master_clk = ~master_clk;

  // (3b) Phase counter: increments on master clock edges (resets when rst_ asserted).
  always @(posedge master_clk or negedge rst_)
    if (~rst_)
      count <= 3'b0;
    else
      count <= count + 1;

  // (3c) Derived clocks/phases: these are DUT-specific phase relationships.
  assign cntrl_clk = ~count[0];
  assign clk       =  count[1];
  assign fetch     = ~count[3];
  assign alu_clk   = ~(count == 4'hc);
  // end of clock generator


  //============================================================
  // (5) MONITOR SETUP (formatting, logging helpers)
  //     (This is “monitor infrastructure”; actual checking is later.)
  //============================================================
  initial
    $timeformat(-9, 1, " ns", 12); // Print %t in ns with 1 decimal.


  //============================================================
  // (4) TEST SELECTION + (5) STIMULUS/DRIVE: choose test, load program,
  //     pulse reset, then run the DUT
  //============================================================
  initial
    forever begin
      //---- (4) Interactive test selection menu ----
      $display("");
      $display("****************************************");
      $display("THE FOLLOWING DEBUG TASKS ARE AVAILABLE:");
      $display("1- The basic CPU diagnostic.            ");
      $display("2- The advanced CPU diagnostic.         ");
      $display("3- The Fibonacci program.               ");
      $display("****************************************");
      $display("");
      $display("Enter ' deposit test_number # ; run' \n");

      test_number = 1;          // Default if user doesn’t change it.
      // $stop;                    // Pause sim here: user edits test_number, then continues.

      test_number = 1; // default
      if (!$value$plusargs("test_number=%d", test_number)) begin
      // no plusarg provided, keep default
      end



      if (test_number > 3) begin
        $display("Test number %d is not between 1 and 3", test_number);
      end
      else begin
        //---- (4) Print which test was chosen ----
        case (test_number)
          1: begin
               $display("CPUtest1 - BASIC CPU DIAGNOSTIC PROGRAM \n");
               $display("THIS TEST SHOULD HALT WITH THE PC AT 17 hex\n");
             end
          2: begin
               $display("CPUtest2 - ADVANCED CPU DIAGNOSTIC PROGRAM\n");
               $display("THIS TEST SHOULD HALT WITH THE PC AT 10 hex\n");
             end
          3: begin
               $display("CPUtest3 - FIBONACCI NUMBERS to 144\n");
               $display("THIS TEST SHOULD HALT WITH THE PC AT 0C hex\n");
             end
        endcase

        //---- (5) Stimulus step: build file name and preload DUT memory ----
        // Creates "CPUtest1.dat", "CPUtest2.dat", etc. using ASCII math.
        testfile = { "CPUtest", 8'h30 + test_number[7:0], ".dat" };

        // Loads program bits into the DUT’s internal memory array (hierarchical reference).
        $readmemb(testfile, cpu1.mem1.memory);

        //---- (3) Reset sequencing: drive reset around clock edges ----
        // NOTE: This is “reset generation” in practice, but kept inside stimulus.
        rst_ = 1;                                // Deassert reset first (depending on design).
        repeat (2) @(negedge master_clk);
        rst_ = 0;                                // Assert active-low reset.
        repeat (2) @(negedge master_clk);
        rst_ = 1;                                // Release reset -> CPU starts executing.

        //---- (5) Monitor header ----
        $display("     TIME       PC    INSTR    OP   ADR   DATA\n");
        $display("  ----------     --    -----    --   ---   ----\n");

        //============================================================
        // (5) RUN LOOP (stimulus + monitoring): step until halt
        //============================================================
        while (!halt) begin
          @(posedge clk);                        // Advance at the CPU “main” clock boundary.

          // Hierarchical observation + conditional logging at instruction-load time.
          if (load_ir) begin
            #(`PERIOD/2);                        // Wait half period to sample stable values.
            topcode = cpu1.opcode;               // Capture opcode for name() printing.

            $display("%t    %h    %s      %h    %h     %h     %h",
                     $time, cpu1.pc_addr, topcode.name(), cpu1.opcode,
                     cpu1.addr, cpu1.alu_out, cpu1.data_out);

            // Special-case extra print for Fibonacci program.
            if ((test_number == 3) && (topcode == JMP))
              $display("Next Fibonacci number is %d", cpu1.mem1.memory[5'h1B]);
          end
        end

        //============================================================
        // (6) CHECKS / SCOREBOARD: decide pass/fail from end state
        //============================================================
        // Here the “golden expectation” is: final PC must match the known halt address.
        if ( test_number == 1 && cpu1.pc_addr !== 5'h17
          || test_number == 2 && cpu1.pc_addr !== 5'h10
          || test_number == 3 && cpu1.pc_addr !== 5'h0C
          || cpu1.pc_addr === 5'hXX ) begin
          $display("CPU TEST FAILED");
          $finish;
        end

        $display("\nCPU TEST %0d PASSED", test_number);
      end
    end

endmodule
