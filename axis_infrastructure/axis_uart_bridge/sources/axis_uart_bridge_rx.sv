`timescale 1ns / 1ps

module axis_uart_bridge_rx #(
    parameter UART_SPEED    = 115200   ,
    parameter FREQ_HZ       = 100000000,
    parameter N_BYTES       = 32       ,
    parameter QUEUE_DEPTH   = 16       ,
    parameter QUEUE_MEMTYPE = "block"    // "distributed", "auto"
) (
    input                          clk          ,
    input                          reset        ,
    output logic [(N_BYTES*8)-1:0] M_AXIS_TDATA ,
    output logic                   M_AXIS_TVALID,
    input                          M_AXIS_TREADY,
    input                          UART_RX
);

    localparam CLOCK_DURATION      = (FREQ_HZ/UART_SPEED);
    localparam DATA_WIDTH          = (N_BYTES*8)         ;
    localparam HALF_CLOCK_DURATION = CLOCK_DURATION/2    ;

    logic [DATA_WIDTH-1:0] out_din_data = '{default:0};
    logic                  out_wren     = 1'b0        ;
    logic                  out_awfull                 ;

    logic [2:0] bit_index = '{default:0};
    logic [31:0] word_counter = '{default:0};

    logic [31:0] clock_counter      = '{default:0};
    logic        clock_event        = 1'b0        ;
    logic        d_uart_rx                        ;

    typedef enum {
        AWAIT_START_ST,
        RECEIVE_DATA_ST,
        AWAIT_STOP_ST
    } rx_fsm;

    rx_fsm current_state = AWAIT_START_ST;


    always_ff @(posedge clk) begin : d_uart_rx_proc
        d_uart_rx <= UART_RX;
    end 



    always_ff @(posedge clk) begin : half_clock_counter_proc
        if (reset) begin 
            clock_counter <= HALF_CLOCK_DURATION;
        end else begin 
            case (current_state)
                AWAIT_START_ST : 
                    if (clock_counter == HALF_CLOCK_DURATION) begin 
                        if (~UART_RX & d_uart_rx) begin 
                            clock_counter <= clock_counter + 1;
                        end else begin
                            clock_counter <= clock_counter;
                        end
                    end else begin 
                        clock_counter <= clock_counter + 1;
                    end 

                RECEIVE_DATA_ST: 
                    if (clock_counter < (CLOCK_DURATION-1)) begin 
                        clock_counter <= clock_counter + 1;
                    end else begin 
                        clock_counter <= '{default:0};
                    end 

                AWAIT_STOP_ST:
                    if (clock_counter < (CLOCK_DURATION-1)) begin 
                        clock_counter <= clock_counter + 1;
                    end else begin 
                        clock_counter <= '{default:0};
                    end 

                default: 
                    clock_counter <= '{default:0};

            endcase // current_state
        end 
    end 

    always_ff @(posedge clk) begin : clock_event_proc
        if (clock_counter == CLOCK_DURATION-1) begin  
            clock_event <= 1'b1;
        end else begin 
            clock_event <= 1'b0;
        end 
    end

    always_ff @(posedge clk) begin : current_state_proc
        if (reset) begin 
            current_state <= AWAIT_START_ST;
        end else begin 
            case (current_state) 
                AWAIT_START_ST : 
                    if (clock_event) begin 
                        if (~UART_RX) begin // is this start?
                            current_state <= RECEIVE_DATA_ST;
                        end else begin 
                            current_state <= current_state;
                        end 
                    end else begin 
                        current_state <= current_state;
                    end 

                RECEIVE_DATA_ST : 
                    if (clock_event) begin 
                        if (bit_index == 7) begin 
                            current_state <= AWAIT_STOP_ST;
                        end else begin 
                            current_state <= current_state;
                        end 
                    end else begin 
                        current_state <= current_state;
                    end 

                AWAIT_STOP_ST : 
                    if (clock_event) begin 
                        if (UART_RX) begin
                            current_state <= AWAIT_START_ST;
                        end else begin 
                            current_state <= current_state;
                        end 
                    end else begin 
                        current_state <= current_state;
                    end 

                default        : 
                    current_state <= current_state;
            endcase
        end 
    end

    always_ff @(posedge clk) begin 
        case (current_state) 
            RECEIVE_DATA_ST : 
                if (clock_event) begin 
                    bit_index <= bit_index + 1;
                end else begin 
                    bit_index <= bit_index;
                end 

            AWAIT_STOP_ST : 
                if (clock_event) begin 
                    bit_index <= '{default:0};
                end else begin 
                    bit_index <= bit_index;
                end 

            default: 
                bit_index <= '{default:0};

        endcase
    end 

    always_ff @(posedge clk) begin : out_din_data_proc
        case (current_state) 
            RECEIVE_DATA_ST : 
                if (clock_event) begin 
                    out_din_data <= {UART_RX, out_din_data[(DATA_WIDTH-1):1]};
                end 

            default : 
                out_din_data <= out_din_data;
        endcase // current_state
    end 

    // for calculation when out_wren generate
    always_ff @(posedge clk) begin : word_counter_proc
        case (current_state)
            RECEIVE_DATA_ST: 
                if (clock_event) begin 
                    if (word_counter < (DATA_WIDTH-1)) begin 
                        word_counter <= word_counter + 1;
                    end else begin 
                        word_counter <= '{default:0};
                    end 
                end else begin 
                    word_counter <= word_counter;
                end 

            default : 
                word_counter <= word_counter;

        endcase // current_state
    end 

    fifo_out_sync_xpm #(
        .DATA_WIDTH(DATA_WIDTH   ),
        .MEMTYPE   (QUEUE_MEMTYPE),
        .DEPTH     (QUEUE_DEPTH  )
    ) fifo_out_sync_xpm_inst (
        .CLK          (clk          ),
        .RESET        (reset        ),
        
        .OUT_DIN_DATA (out_din_data ),
        .OUT_DIN_KEEP ('b0          ),
        .OUT_DIN_LAST ('b0          ),
        .OUT_WREN     (out_wren     ),
        .OUT_FULL     (             ),
        .OUT_AWFULL   (out_awfull   ),
        
        .M_AXIS_TDATA (M_AXIS_TDATA ),
        .M_AXIS_TKEEP (             ),
        .M_AXIS_TVALID(M_AXIS_TVALID),
        .M_AXIS_TLAST (             ),
        .M_AXIS_TREADY(M_AXIS_TREADY)
    );

    always_ff @ (posedge clk) begin : out_wren_proc 
        if (clock_event) begin 
            if (word_counter == (DATA_WIDTH-1)) begin 
                out_wren <= 1'b1;
            end else begin 
                out_wren <= 1'b0;
            end 
        end else begin 
            out_wren <= 1'b0;
        end 
    end 




endmodule
