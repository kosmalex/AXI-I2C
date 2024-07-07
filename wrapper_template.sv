module wrapper_template #(
  rom_size_g         = 128,
  rom_instructions_g = 16
)(
  input  logic clk_i,
  input  logic rst_n_i,

  input  logic start_i,

  output logic scl_o,
  inout  logic sda_io
);

logic                          i2c_send_s;
logic                          i2c_done_s;
logic                          i2c_ready_s;
logic                          i2c_rcvd_byte_s;

logic [$clog2(rom_size_g)-1:0] rom_addr_s;
logic [15:0]                   rom_data_s;

i2c i2c_0 (.*, .send_i(i2c_send_s), .data_i(rom_data_s), .data_o(i2c_rcvd_byte_s), .done_o(i2c_done_s), .ready_o(i2c_ready_s));

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

typedef enum logic[1:0] { IDLE, SEND, DONE } state_t;

state_t st_s;

always_ff @(posedge clk_i) begin
  if (!rst_n_i) begin
    st_s <= IDLE;
  end else begin
    case(st_s)
      IDLE: begin
        if (start_i) begin
          st_s <= SEND;
        end
      end

      SEND: begin
        if(i2c_done_s) begin
          st_s <= DONE;
        end
      end

      DONE: begin
        if(i2c_ready_s && (rom_addr_s < rom_instructions_g)) begin
          st_s <= SEND;
        end else begin
          st_s <= IDLE;
        end
      end

      default: begin
        st_s <= IDLE;
      end
    endcase
  end
end

assign i2c_send_s = (st_s == SEND);

endmodule