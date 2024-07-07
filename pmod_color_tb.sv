module tb;

logic       clk_i;
logic       rst_n_i;

logic       start_i;

logic       led_en_i;

logic       dummy_o;
logic       led_en_o;
logic       scl_o;
wire        sda_io;

logic       hsync_o;
logic       vsync_o;
logic [3:0] red_o  ;
logic [3:0] green_o;
logic [3:0] blue_o;

logic [1:0] nbytes_i;

logic [15:0] LED;

initial begin
  clk_i = 0;
  forever #5ns clk_i = ~clk_i;
end

pmod_color dut (.*);

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

endmodule
