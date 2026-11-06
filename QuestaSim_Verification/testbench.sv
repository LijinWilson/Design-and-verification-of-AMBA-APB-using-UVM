/* `include "uvm_macros.svh"
`include "package.sv"
`include "apb_slave_design.sv"

module tb;
  import uvm_pkg::*;
  import pkg::*;
  bit PCLK;
  always #5 PCLK=~PCLK;
  intf inf(PCLK);
  
  apb_slave dut
  (
    .PCLK(inf.PCLK),
    .PRESETn(inf.PRESETn),
    .PSEL(inf.PSEL),
    .PENABLE(inf.PENABLE),
    .PWRITE(inf.PWRITE),
    .PADDR(inf.PADDR),
    .PWDATA(inf.PWDATA),
    .PRDATA(inf.PRDATA),
    .PREADY(inf.PREADY),
    .PSLVERR(inf.PSLVERR)
  );
  
  initial begin
    uvm_config_db #(virtual intf)::set(null,"*","inf",inf);
  end

  initial begin
    run_test("apb_test");
  end
  
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
  end
  
endmodule


 */
`timescale 1ns/1ps
`include "uvm_macros.svh"
`include "package.sv"
`include "apb_slave_design.sv"

module tb;
  import uvm_pkg::*;
  import pkg::*;
  
  bit PCLK;
  always #5 PCLK = ~PCLK;
  
  intf inf(PCLK);
  
  apb_slave dut (
    .PCLK(inf.PCLK),
    .PRESETn(inf.PRESETn),
    .PSEL(inf.PSEL),
    .PENABLE(inf.PENABLE),
    .PWRITE(inf.PWRITE),
    .PADDR(inf.PADDR),
    .PWDATA(inf.PWDATA),
    .PRDATA(inf.PRDATA),
    .PREADY(inf.PREADY),
    .PSLVERR(inf.PSLVERR)
  );
  
  // FIX: Merged initial blocks to guarantee execution order
  initial begin
    uvm_config_db #(virtual intf)::set(null, "*", "inf", inf);
    run_test("apb_test");
  end
  
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
  end
  
endmodule