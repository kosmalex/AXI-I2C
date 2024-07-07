module timer #(
  clk_periods_g = 10
)(
  input  logic clk_i,
  input  logic rst_n_i,
  input  logic count_i,

  output logic done_o
);

logic [$clog2(clk_periods_g)-1:0] counter_s;

assign done_o = ( counter_s == 'd0 );

always_ff @(posedge clk_i) begin
  if (!rst_n_i || !count_i) begin
    counter_s <= clk_periods_g-'d1;
  end else if (count_i) begin
    counter_s <= counter_s - 'd1;
  end
end

endmodule