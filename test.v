`timescale 1ns/1ps

module test;

parameter CLK_PERIOD = 20; // 50 MHz clock
parameter BIT_PERIOD = 104166; // 9600 baud

reg  clk;
reg  rstn;
reg  tx_start;
reg  [7:0] tx_data;
wire tx;
reg  rx;
wire [7:0] rx_data;
wire tx_done;
wire rx_done;
wire tx_busy;
wire rx_busy;
wire rx_error;

uart_transceiver uut (
    .clk      (clk),
    .rstn     (rstn),
    .tx_start (tx_start),
    .rx       (rx),
    .tx_data  (tx_data),
    .tx       (tx),
    .rx_data  (rx_data),
    .rx_done  (rx_done),
    .tx_done  (tx_done),
    .rx_busy  (rx_busy),
    .tx_busy  (tx_busy),
    .rx_error (rx_error)
);

always #(CLK_PERIOD/2) clk = ~clk;

task reset;
    begin
        rstn = 1'b0;
        #(CLK_PERIOD*10);
        rstn = 1'b1;
        #(CLK_PERIOD*5);
    end
endtask

task transmit_byte;
    input [7:0] data;
    begin
        tx_data = data;
        tx_start = 1'b1;
        @(posedge clk);
        #1;
        tx_start = 1'b0;
        @(posedge tx_done);
        #(CLK_PERIOD*5);
    end
endtask

task receive_byte;
    input [7:0] data;
    integer i;
    begin
        rx = 1'b1;
        #BIT_PERIOD;
        rx = 1'b0;
        #BIT_PERIOD;
        for (i = 0; i < 8; i = i + 1) begin
            rx = data[i];
            #BIT_PERIOD;
        end
        rx = 1'b1;
        #BIT_PERIOD;
        #(CLK_PERIOD*5);
    end
endtask

initial begin
    $dumpfile("test.vcd");
    $dumpvars(0, test);
end

initial begin
    #1000_000_000;
    $finish;
end

initial begin
    clk = 1'b0;
    rstn = 1'b1;
    tx_start = 1'b0;
    tx_data = 1'b0;
    rx = 1'b1;

    $display("Start reset test");
    reset();

    $display("Start transmitter test");
    transmit_byte(8'h55);
    transmit_byte(8'hAA);
    transmit_byte(8'h00);
    transmit_byte(8'hFF);

    $display("Start receiver test");
    receive_byte(8'h55);
    if (rx_data != 8'h55) $display("Error: Received %h, expected 55", rx_data);
    else $display("Received correctly: %h", rx_data);

    #BIT_PERIOD;
    #BIT_PERIOD;
    #BIT_PERIOD;
    #(CLK_PERIOD*10);
    $display("Finish");
    $finish;
end

// Logging
initial begin
    $monitor("Time = %0t rx_data = %h rx_done=%b tx_done=%b rx_busy=%b tx_busy=%b rx_error=%b",
    $time, rx_data, rx_done, tx_done, rx_busy, tx_busy, rx_error);
end

endmodule
