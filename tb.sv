module tb;

logic       clk_i, rst_n_i;
logic       scl_o;
wire        sda_io;
logic       start_i;
logic       sda_io_i_dbg;

initial begin
  clk_i = 0;
  forever #5ns clk_i = ~clk_i;
end

wrapper_template dut (.*);

initial begin
  rst_n_i <= 1;
  repeat(4) @(posedge clk_i);
  rst_n_i <= 0;
  repeat(10) @(posedge clk_i);
  rst_n_i <= 1;
  repeat(2) @(posedge clk_i);

  start_i <= 1'b1;
  repeat(2) @(posedge clk_i);
  start_i <= 1'b0;
  repeat(1) @(posedge clk_i);

  $stop();
end

task SLV_SEND(logic [7:0] data2send);
  @(negedge sda_io);
  @(negedge scl_o);

  @(posedge scl_o);
  @(posedge scl_o);
  @(posedge scl_o);
  @(posedge scl_o);
  @(posedge scl_o);
  @(posedge scl_o);
  @(posedge scl_o);
  @(posedge scl_o) begin
    sda_io_i_dbg = 1'b1;
  end

  for (int i = 0; i < 8; i++) begin
    @(posedge scl_o) begin
      sda_io_i_dbg = data2send[7-i];
    end
  end

  @(posedge scl_o);
  @(posedge sda_io);

endtask

endmodule
