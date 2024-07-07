module pmod_color #(
  rom_size_g         = 128,
  rom_instructions_g = 16
)(
  input  logic       clk_i,
  input  logic       rst_n_i,

  input  logic       start_i,

  input  logic       led_en_i,

  output logic       dummy_o,
  output logic       led_en_o,
  output logic       scl_o,
  inout  logic       sda_io,

  output logic       hsync_o,
  output logic       vsync_o,
  output logic [3:0] red_o  ,
  output logic [3:0] green_o,
  output logic [3:0] blue_o,

  output logic [15:0] LED
);

typedef enum logic[3:0] { IDLE, SEND[3], WAIT[3], DONE[4], READ[1], STALL_2p4_ms} state_t;

state_t st_s;

logic                          i2c_send_s;
logic                          i2c_done_s;
logic                          i2c_ready_s;
logic [72:0]                   i2c_rcvd_byte_s;
logic [3:0]                    i2c_nbytes_s;

logic [3:0]                    r_s;
logic [3:0]                    g_s;
logic [3:0]                    b_s;

logic                          stall_2p4_ms_done_s;

logic [$clog2(rom_size_g)-1:0] rom_addr_s;
logic [31:0]                   rom_data_s;

i2c #(
  .divider_g    (300),
  .start_hold_g (100),
  .stop_hold_g  (100),
  .free_hold_g  (130),
  .data_hold_g  (10),
  .nbytes_g     (9)
)
i2c_0 (
  .*, 
  .send_i   (i2c_send_s),
  .nbytes_i (i2c_nbytes_s),
  .data_i   ({40'd0, rom_data_s}),
  .data_o   (i2c_rcvd_byte_s),
  .done_o   (i2c_done_s),
  .ready_o  (i2c_ready_s)
);

timer #(20'h3A980) timer_2p4_ms (.*, .count_i(st_s == STALL_2p4_ms) , .done_o(stall_2p4_ms_done_s));
// timer #(32'H249F00) free_hold  (.*, .count_i(free_hold_count_s) , .done_o(free_hold_done_s));

vga_controller vga_controller_0(.*, .red_i({i2c_rcvd_byte_s[47:32]}), .green_i({i2c_rcvd_byte_s[31:16]}), .blue_i({i2c_rcvd_byte_s[15:0]}));

// ROM used to init a I2C peripheral
blk_mem_gen_0 rom (
  .clka  (clk_i),
  .addra (rom_addr_s),
  .douta (rom_data_s) 
);

// Address ff
always_ff @(posedge clk_i) begin
  if (!rst_n_i) begin
    rom_addr_s <= 'd0;
  end else begin
    if (i2c_done_s) begin
      rom_addr_s <= rom_addr_s + 'd1;
    end
  end
end

always_ff @(posedge clk_i) begin
  if (!rst_n_i) begin
    st_s <= IDLE;
  end else begin
    case(st_s)
      IDLE: begin
        if (start_i) begin
          st_s <= SEND0;
        end
      end

      SEND0: begin
        st_s <= WAIT0;
      end

      WAIT0: begin
        if(i2c_done_s) begin
          st_s <= DONE0;
        end
      end

      DONE0: begin
        if(i2c_ready_s && (rom_addr_s < 1)) begin
          st_s <= SEND0;
        end else begin
          st_s <= STALL_2p4_ms;
        end
      end

      STALL_2p4_ms: begin
        if (stall_2p4_ms_done_s) begin
          st_s <= SEND1;
        end
      end

      SEND1: begin
        st_s <= WAIT1;
      end

      WAIT1: begin
        if(i2c_done_s) begin
          st_s <= DONE1;
        end
      end

      DONE1: begin
        if (i2c_ready_s)
          st_s <= READ0;
      end

      READ0: begin
        st_s <= WAIT2;
      end

      WAIT2: begin
        if(i2c_done_s) begin
          st_s <= DONE2;
        end
      end

      DONE2: begin
        if(i2c_ready_s) begin
          st_s <= DONE3;
        end
      end

      DONE3: begin
        if (!start_i) begin
          st_s <= IDLE;
        end
      end

      default: begin
        st_s <= IDLE;
      end
    endcase
  end
end

assign LED[0] = (st_s == IDLE);
assign LED[1] = (st_s == DONE3);

assign LED[15-:4] = red_o;

assign LED[11:2] = 0;

assign i2c_send_s = (st_s == SEND0) || (st_s == SEND1) || (st_s == SEND2) || (st_s == READ0);
assign dummy_o    = 1'b0;
assign led_en_o   = led_en_i;

always_comb begin
  case(st_s)
    SEND0: begin
      i2c_nbytes_s = 'd4;
    end

    SEND1: begin
      i2c_nbytes_s = 'd2;
    end

    READ0: begin
      i2c_nbytes_s = 'd8;
    end

    default: begin
      i2c_nbytes_s = 'd0;
    end
  endcase
end
endmodule