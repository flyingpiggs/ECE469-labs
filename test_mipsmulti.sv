// Example testbench for MIPS processor

module test_mipsmulti();

  logic        clk;
  logic        reset;

  logic [31:0] writedata, adr;
  logic        memwrite;

  // instantiate device to be tested
  top dut(clk, reset, writedata, adr, memwrite);
  
  // initialize test
  initial
    begin
      reset <= 1; # 10; reset <= 0;
    end

  // generate clock to sequence tests
  always
    begin
      clk <= 1; # 5; clk <= 0; # 5;
    end
endmodule