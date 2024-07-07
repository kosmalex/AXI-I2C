module clk_divider #(
  divider_g = 10
)(
  input  logic clk_i,
  input  logic rst_n_i,
  input  logic hold_i,
  input  logic reset_i,
  output logic clk_o
);

localparam max_count_lp = divider_g / 2;

logic [$clog2(max_count_lp)-1:0] counter_s;

assign last_cnt_s = ( counter_s == (max_count_lp-1) );

always_ff @(posedge clk_i) begin
  if (!rst_n_i || hold_i) begin
    counter_s <= 0;
  end else begin
    if (last_cnt_s) begin
      counter_s <= 'd0;
    end else begin
      counter_s <= counter_s + 'd1;
    end
  end
end

always_ff @(posedge clk_i) begin
  if (!rst_n_i || reset_i) begin
    clk_o <= 1'b0;
  end else if (last_cnt_s) begin
    clk_o <= ~clk_o;
  end
end

endmodule