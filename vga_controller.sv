module vga_controller #(parameter int COLOR_WIDTH=16
                    )(input logic clk_i,
                      input logic rst_n_i,
                      input logic [COLOR_WIDTH-1:0] red_i,
                      input logic [COLOR_WIDTH-1:0] green_i,
                      input logic [COLOR_WIDTH-1:0] blue_i,
                      output logic hsync_o,
                      output logic vsync_o,
                      output logic [3:0] red_o,
                      output logic [3:0] green_o,
                      output logic [3:0] blue_o);
  
  
  localparam H_PIXELS = 800;//640;
  localparam H_FRONT= 40;//16;
  localparam H_SYNC = 128;//96;
  localparam H_BACK= 88;//48;
  localparam H_SUM = H_PIXELS + H_FRONT + H_SYNC + H_BACK;
  
  localparam V_LINES = 600;//480;
  localparam V_FRONT= 1;//11;
  localparam V_SYNC = 4;//2;
  localparam V_BACK= 23;//31;
  localparam V_SUM = V_LINES + V_FRONT + V_SYNC + V_BACK;
  
  logic [10:0] cntRow;
  logic [10:0] cntColumn;
  logic enable;

  logic [3:0] r_s;
  logic [3:0] g_s;
  logic [3:0] b_s;
	
  //toggle ff for frequency division by 2
  always_ff @(posedge clk_i) begin
    if (!rst_n_i)
      enable <= 1'b0;
    else
      enable <=~enable;
  end

  //assign enable=1;
  
  //counter for every collumn
  always_ff @(posedge clk_i) begin
    if (!rst_n_i) 
      cntColumn <= 0;
    else begin
      if (!enable) begin
        cntColumn <= cntColumn + 1;
        if (cntColumn == H_SUM-1)
          cntColumn <= 0;
      end
	end	
  end
  
  //counter for every row
  always_ff @(posedge clk_i) begin
    if (!rst_n_i) 
      cntRow <= 0;
    else begin
      if (!enable) begin
        if (cntColumn == H_SUM-1) begin
          cntRow <= cntRow + 1;
          if (cntRow == V_SUM-1)
            cntRow <= 0;
        end
      end
    end
  end
  
  always_ff @(posedge clk_i) begin
    if(!rst_n_i)
      hsync_o<=1;
    else 
      hsync_o<=(cntColumn >= H_PIXELS + H_FRONT-1 && cntColumn <H_PIXELS+H_FRONT+H_SYNC-1);
  end

  always_ff @(posedge clk_i) begin
    if(!rst_n_i)
      vsync_o<=1;
    else 
      vsync_o<=(cntRow >= V_LINES + V_FRONT-1 && cntRow <V_LINES+V_FRONT+V_SYNC-1);
  end

  assign read_address=((cntColumn>=H_PIXELS/2-64 && cntColumn < H_PIXELS/2+64) && (cntRow>=V_LINES/2-64 && cntRow < V_LINES/2+64))?((cntRow-V_LINES/2+64)*128+(cntColumn-H_PIXELS/2+64)):0;

  always_comb begin
    r_s = 4'h0;
    b_s = 4'h0;
    g_s = 4'h0;
    
    if ((red_i > blue_i) && (red_i > green_i)) begin
      r_s = 4'hf;
    end else if ((green_i > blue_i) && (green_i > red_i)) begin
      g_s = 4'hf;
    end else if ((blue_i > red_i) && (blue_i > green_i)) begin
      b_s = 4'hf;
    end
  end

  always_ff @(posedge clk_i) begin
    if(!rst_n_i) begin
      red_o <= 4'b0000;
      green_o <= 4'b0000;
      blue_o <= 4'b0000;
    end
    else begin
      if ((cntColumn>=H_PIXELS/2-64 && cntColumn <H_PIXELS/2+64) && (cntRow>=V_LINES/2-64 && cntRow <V_LINES/2+64)) begin
        red_o   <= r_s;
        green_o <= g_s;
        blue_o  <= b_s;
      end
      else begin
        red_o <= 4'b0000;
        green_o <= 4'b0000;
        blue_o <= 4'b0000;
      end
    end
  end
  
endmodule