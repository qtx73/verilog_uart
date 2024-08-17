module uart_transceiver (
    input clk,
    input rstn,
    input wire tx_start,
    input wire rx,
    input wire [7:0] tx_data,
    output wire tx,
    output wire [7:0] rx_data,
    output wire tx_done,
    output wire rx_done,
    output wire tx_busy,
    output wire rx_busy,
    output wire rx_error
);

// Clock Rate: 50 MHz
// BAUD Rate: 9600 bps
// BAUD divider: 50000000/9600 -> 5208
localparam BAUD_DIV = 5208 - 1;
reg [12:0] baud_counter;
wire baud_tick;

// Baud rate generator
assign baud_tick = baud_counter == BAUD_DIV;
always @ (posedge clk or negedge rstn) begin
    if (!rstn) begin
        baud_counter <= 13'b0;
    end
    else begin
        if (baud_counter == BAUD_DIV) begin
            baud_counter <= 13'b0;
        end
        else begin
            baud_counter <= baud_counter + 13'b1;
        end
    end
end

// Mesatability handling for rx
reg [1:0] rx_sync;
wire rx_in;
always @ (posedge clk or negedge rstn) begin
    if (!rstn) begin
        rx_sync <= 2'b11;
    end
    else begin
        rx_sync <= {rx_sync[1:0], rx};
    end
end
assign rx_in = rx_sync[1];

// Transmitter
reg [9:0] tx_shift_reg;
reg [3:0] tx_bit_count;
reg tx_active;
reg tx_done_reg;

assign tx = tx_active ? tx_shift_reg[0] : 1'b1;
assign tx_busy = tx_active;
assign tx_done = tx_done_reg;
always @ (posedge clk or negedge rstn) begin
    if (!rstn) begin
        tx_shift_reg <= 10'h0;
        tx_bit_count <= 4'b0;
        tx_active <= 1'b0;
        tx_done_reg <= 1'b0;
    end
    else begin
        if (tx_start && !tx_active) begin
            tx_shift_reg <= {1'b1, tx_data, 1'b0};
            tx_bit_count <= 4'b1;
            tx_active <= 1'b1;
            tx_done_reg <= 1'b0;
        end
        else if (tx_active && baud_tick) begin
            tx_shift_reg <= {1'b1, tx_shift_reg[9:1]};
            tx_bit_count <= tx_bit_count + 4'b1;
            if (tx_bit_count == 4'd10) begin
                tx_active <= 1'b0;
                tx_done_reg <= 1'b1;
            end
            else begin
                tx_active <= 1'b1;
                tx_done_reg <= 1'b0;
            end
        end
        else begin
            tx_shift_reg <= tx_shift_reg;
            tx_bit_count <= tx_bit_count;
            tx_active <= tx_active;
            tx_done_reg <= tx_done_reg;
        end
    end
end

// Receiver
reg [7:0] rx_data_reg;
reg [3:0] rx_bit_count;
reg [3:0] rx_sample_count;
reg rx_active;
reg rx_done_reg;
reg rx_error_reg;

assign rx_busy = rx_active;
assign rx_done = rx_done_reg;
assign rx_data = rx_data_reg;
assign rx_error = rx_error_reg;

always @ (posedge clk or negedge rstn) begin
    if (!rstn) begin
        rx_data_reg <= 8'b0;
        rx_bit_count <= 4'd0;
        rx_sample_count <= 4'd0;
        rx_active <= 1'b0;
        rx_done_reg <= 1'b0;
        rx_error_reg <= 1'b0;
    end
    else begin
        if (!rx_active && !rx_in) begin
            rx_data_reg <= rx_data_reg;
            rx_bit_count <= 4'd1;
            rx_sample_count <= 4'd0;
            rx_active <= 1'b1;
            rx_done_reg <= 1'b0;
            rx_error_reg <= 1'b0;
        end
        else if (rx_active && baud_tick) begin
            if ((4'd9 >= rx_bit_count) && (rx_bit_count >= 4'd1)) begin
                rx_data_reg[rx_bit_count - 4'd2] <= rx_in;
                rx_sample_count <= rx_sample_count + 4'd1;
            end
            if ((rx_bit_count == 4'd10) && (!rx_in)) begin
                rx_error_reg <= 1'b1;
            end
            if (rx_bit_count == 4'd10) begin
                rx_bit_count <= 4'd0;
                rx_active <= 1'b0;
                rx_done_reg <= 1'b1;
            end
            else begin
                rx_bit_count <= rx_bit_count + 4'd1;
                rx_active <= 1'b1;
                rx_done_reg <= 1'b0;
            end
        end
    end
end

endmodule

