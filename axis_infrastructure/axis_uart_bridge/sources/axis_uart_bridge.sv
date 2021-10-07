`timescale 1ns / 1ps


module axis_uart_bridge #(
    parameter UART_SPEED    = 115200   ,
    parameter FREQ_HZ       = 100000000,
    parameter N_BYTES       = 32       ,
    parameter QUEUE_DEPTH   = 16       ,
    parameter QUEUE_MEMTYPE = "block"    // "distributed", "auto"
) (
    input                          clk          ,
    input                          reset        ,
    input        [(N_BYTES*8)-1:0] S_AXIS_TDATA ,
    input                          S_AXIS_TVALID,
    output logic                   S_AXIS_TREADY,
    output logic [(N_BYTES*8)-1:0] M_AXIS_TDATA ,
    output logic                   M_AXIS_TVALID,
    input                          M_AXIS_TREADY,
    input                          UART_RX      ,
    output logic                   UART_TX
);



    axis_uart_bridge_rx #(
        .UART_SPEED   (UART_SPEED   ),
        .FREQ_HZ      (FREQ_HZ      ),
        .N_BYTES      (N_BYTES      ),
        .QUEUE_DEPTH  (QUEUE_DEPTH  ),
        .QUEUE_MEMTYPE(QUEUE_MEMTYPE)
    ) axis_uart_bridge_rx_inst (
        .clk          (clk          ),
        .reset        (reset        ),
        .M_AXIS_TDATA (M_AXIS_TDATA ),
        .M_AXIS_TVALID(M_AXIS_TVALID),
        .M_AXIS_TREADY(M_AXIS_TREADY),
        .UART_RX      (UART_RX      )
    );

    axis_uart_bridge_tx #(
        .UART_SPEED   (UART_SPEED   ),
        .FREQ_HZ      (FREQ_HZ      ),
        .N_BYTES      (N_BYTES      ),
        .QUEUE_DEPTH  (QUEUE_DEPTH  ),
        .QUEUE_MEMTYPE(QUEUE_MEMTYPE)
    ) axis_uart_bridge_tx_inst (
        .clk          (clk          ),
        .reset        (reset        ),
        .S_AXIS_TDATA (S_AXIS_TDATA ),
        .S_AXIS_TVALID(S_AXIS_TVALID),
        .S_AXIS_TREADY(S_AXIS_TREADY),
        .UART_TX      (UART_TX      )
    );


endmodule
