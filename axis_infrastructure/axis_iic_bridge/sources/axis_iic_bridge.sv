`timescale 1ns / 1ps


module axis_iic_bridge #(
    parameter CLK_PERIOD     = 100000000,
    parameter CLK_I2C_PERIOD = 25000000 ,
    parameter N_BYTES        = 32
) (
    input  logic                     clk          ,
    input  logic                     reset        ,
    input  logic [((N_BYTES*8)-1):0] s_axis_tdata ,
    input  logic [              7:0] s_axis_tuser , // tuser or tdest for addressation data
    input  logic [      N_BYTES-1:0] s_axis_tkeep ,
    input  logic                     s_axis_tvalid,
    output logic                     s_axis_tready,
    input  logic                     s_axis_tlast ,
    output logic [((N_BYTES*8)-1):0] m_axis_tdata ,
    output logic [      N_BYTES-1:0] m_axis_tkeep ,
    output logic [              7:0] m_axis_tuser ,
    output logic                     m_axis_tvalid,
    input  logic                     m_axis_tready,
    output logic                     m_axis_tlast ,
    input  logic                     scl_i        ,
    input  logic                     sda_i        ,
    output logic                     scl_t        ,
    output logic                     sda_t
);


    localparam DURATION      = (CLK_PERIOD/CLK_I2C_PERIOD);
    localparam DURATION_DIV2 = ((DURATION)/2)-1           ;
    localparam DURATION_DIV4 = ((DURATION)/4)             ;
    localparam DATA_WIDTH    = (N_BYTES*8)                ;

    logic [$clog2(DURATION)-1:0] duration_cnt         = '{default:0};
    logic [$clog2(DURATION)-1:0] duration_cnt_shifted = '{default:0};
    logic                        has_event            = 1'b0        ;
    logic                        allow_counting       = 1'b0        ;
    logic                        clk_assert           = 1'b0        ;
    logic                        clk_deassert         = 1'b0        ;
    logic [                 2:0] bit_cnt              = '{default:0};
    logic                        has_ack              = 1'b0        ;

    logic scl = 1'b1;
    logic sda = 1'b1;

    logic [             7:0] i2c_address       = '{default:0};
    logic [(DATA_WIDTH-1):0] transmission_size = '{default:0};



    logic                        bad_transmission_flaq = 1'b0        ;

    logic [(DATA_WIDTH-1):0] in_dout_data                  ;
    logic [(DATA_WIDTH-1):0] in_dout_data_shift            ;
    logic [(DATA_WIDTH-1):0] in_dout_data_shift_swap       ;
    logic [   (N_BYTES-1):0] in_dout_keep                  ;
    logic [             7:0] in_dout_user                  ;
    logic                    in_dout_last                  ;
    logic                    in_rden                 = 1'b0;
    logic                    in_empty                      ;

    typedef enum {
        IDLE_ST,
        START_ST,
        TX_ADDR_ST,
        WAIT_ACK_ST,
        WRITE_ST,
        WAIT_WRITE_ACK_ST,
        READ_ST,
        STOP_ST,
        STUB_ST
    } fsm;

    fsm current_state = IDLE_ST;

    
    for (genvar index = 0; index < N_BYTES; index++) begin : adc_data_trans
        // high = (((n_bytes)-index)*8)-1;
        // low = (((n_bytes-1)-index)*8);
        // high_ = ((index+1)*8)-1;
        // low_ = (index*8);
        always_comb begin
            in_dout_data_shift_swap[((N_BYTES-index)*8)-1:(((N_BYTES-1)-index)*8)] = in_dout_data_shift[(((index+1)*8)-1):(index*8)];
        end

    end 

    always_ff @(posedge clk) begin 
        case (current_state)
            WAIT_ACK_ST : 
                if (clk_assert) begin 
                    if (scl_i) begin 
                        bad_transmission_flaq <= 1'b1;
                    end else begin 
                        bad_transmission_flaq <= 1'b0;
                    end 
                end else begin 
                    bad_transmission_flaq <= 1'b0;
                end 

            default : 
                bad_transmission_flaq <= 1'b0;

        endcase
    end 

    always_ff @(posedge clk) begin 
        if (duration_cnt < (DURATION-1)) 
            duration_cnt <= duration_cnt + 1;
        else 
            duration_cnt <= '{default:0};
    end 

    always_ff @(posedge clk) begin 
        if (duration_cnt == (DURATION_DIV4))
            allow_counting <= 1'b1;
    end 

    always_ff @(posedge clk) begin 
        if (allow_counting) 
            if (duration_cnt_shifted < (DURATION-1)) begin 
                duration_cnt_shifted <= duration_cnt_shifted + 1;
            end else begin 
                duration_cnt_shifted <= '{default:0};
            end 
    end 

    always_ff @(posedge clk) begin 
        if (duration_cnt == (DURATION-1)) 
            has_event <= 1'b1;
        else 
            has_event <= 1'b0;
    end 

    always_ff @(posedge clk) begin 
        if (duration_cnt_shifted == (DURATION_DIV2)) 
            clk_deassert <= 1'b1;
        else 
            clk_deassert <= 1'b0;
    end 

    always_ff @(posedge clk) begin 
        if (duration_cnt_shifted == (DURATION-1)) 
            clk_assert <= 1'b1;
        else 
            clk_assert <= 1'b0;
    end 

    always_ff @(posedge clk) begin 
        case (current_state) 
            IDLE_ST : 
                scl <= 1'b1;

            START_ST : 
                if (clk_assert) 
                    scl <= 1'b0;

            TX_ADDR_ST: 
                if (duration_cnt_shifted == (DURATION-1))
                    scl <= 1'b1;
                else if (duration_cnt_shifted == DURATION_DIV2) 
                    scl <= 1'b0;

            WAIT_ACK_ST: 
                if (duration_cnt_shifted == (DURATION-1))
                    scl <= 1'b1;
                else if (duration_cnt_shifted == DURATION_DIV2) 
                    scl <= 1'b0;

            WRITE_ST : 
                if (duration_cnt_shifted == (DURATION-1))
                    scl <= 1'b1;
                else if (duration_cnt_shifted == DURATION_DIV2) 
                    scl <= 1'b0;

            WAIT_WRITE_ACK_ST : 
                if (duration_cnt_shifted == (DURATION-1))
                    scl <= 1'b1;
                else if (duration_cnt_shifted == DURATION_DIV2) 
                    scl <= 1'b0;

            STOP_ST : 
                if (clk_assert)
                    scl <= 1'b1;

            default : 
                scl <= 1'b1;
        endcase // current_state_

    end 

    always_ff @(posedge clk) begin 
        if (has_event) begin 
            case (current_state)
                IDLE_ST : 
                    if (!in_empty) begin 
                        if (in_dout_data) begin 
                            sda <= 1'b0;
                        end else begin 
                            sda <= 1'b1;
                        end 
                    end else begin  
                        sda <= 1'b1;
                    end 

                START_ST : 
                    sda <= i2c_address[7];

                TX_ADDR_ST : 
                    if (bit_cnt) begin 
                        sda <= i2c_address[7];
                    end else begin 
                        sda <= 1'b1;
                    end 

                WAIT_ACK_ST : 
                    if (in_dout_user[0]) begin 
                        // if read operation
                        sda <= 1'b1;
                    end else begin 
                        sda <= in_dout_data_shift_swap[(DATA_WIDTH-1)];
                    end 

                WRITE_ST :
                    if (bit_cnt) 
                        sda <= in_dout_data_shift_swap[(DATA_WIDTH-1)]; //TO DO : Here is data
                    else
                        sda <= 1'b1;

                default : 
                    sda <= 1'b1;

            endcase
        end 
    end 

    always_ff @(posedge clk) begin 
        if (reset) begin 
            current_state <= IDLE_ST;
        end else begin 

            if (has_event) begin 
                case (current_state)
                    IDLE_ST : 
                        if (!in_empty) 
                            if (in_dout_data) 
                                current_state <= START_ST;

                    START_ST : 
                        current_state <= TX_ADDR_ST;

                    TX_ADDR_ST : 
                        if (!bit_cnt) 
                            current_state <= WAIT_ACK_ST;

                    WAIT_ACK_ST : 
                        if (has_ack) begin 
                            if (in_dout_user[0]) begin 
                                current_state <= READ_ST;
                            end else begin 
                                current_state <= WRITE_ST;
                            end 
                        end 

                    WRITE_ST : 
                        if (!bit_cnt) 
                            current_state <= WAIT_WRITE_ACK_ST;

                    WAIT_WRITE_ACK_ST : 
                        if (has_ack)
                            current_state <= STUB_ST;
                    
                    READ_ST : 
                        current_state <= STUB_ST;

                    STOP_ST :
                        current_state <= STUB_ST;

                    default: 
                        current_state <= current_state;
                endcase 
            end else begin 
                current_state <= current_state;
            end 
        end 
    end 

    always_ff @(posedge clk) begin
        if (has_event)
            case (current_state) 
                IDLE_ST : 
                    i2c_address <= in_dout_user;

                START_ST : 
                    i2c_address <= {i2c_address[6:0], 1'b0};
                
                TX_ADDR_ST : 
                    i2c_address <= {i2c_address[6:0], 1'b0};

                default: 
                    i2c_address <= i2c_address;
            endcase
    end

    always_ff @(posedge clk) begin 
        if (has_event) begin 
            case (current_state) 

                TX_ADDR_ST : 
                    bit_cnt <= bit_cnt - 1;

                WRITE_ST : 
                    bit_cnt <= bit_cnt - 1;

                default : 
                    bit_cnt <= 7;
            endcase // current_state
        end 
    end 

    always_ff @(posedge clk) begin 
        case (current_state)
            WAIT_ACK_ST : 
                if (clk_assert) begin 
                    if (!sda_i) begin 
                        has_ack <= 1'b1;
                    end else begin   
                        has_ack <= 1'b0;
                    end 
                end 

            WAIT_WRITE_ACK_ST : 
                if (clk_assert) begin 
                    if (!sda_i) begin 
                        has_ack <= 1'b1;
                    end else begin   
                        has_ack <= 1'b0;
                    end 
                end 


            default: 
                has_ack <= 1'b0;

        endcase // current_state
    end 

    fifo_in_sync_user_xpm #(
        .DATA_WIDTH(DATA_WIDTH),
        .USER_WIDTH(8         ),
        .MEMTYPE   ("block"   ),
        .DEPTH     (16        )
    ) fifo_in_sync_user_xpm_inst (
        .CLK          (clk          ),
        .RESET        (reset        ),
        .S_AXIS_TDATA (s_axis_tdata ),
        .S_AXIS_TKEEP (s_axis_tkeep ),
        .S_AXIS_TUSER (s_axis_tuser ),
        .S_AXIS_TVALID(s_axis_tvalid),
        .S_AXIS_TREADY(s_axis_tready),
        .S_AXIS_TLAST (s_axis_tlast ),
        .IN_DOUT_DATA (in_dout_data ),
        .IN_DOUT_KEEP (in_dout_keep ),
        .IN_DOUT_USER (in_dout_user ),
        .IN_DOUT_LAST (in_dout_last ),
        .IN_RDEN      (in_rden      ),
        .IN_EMPTY     (in_empty     )
    );

    always_ff @(posedge clk) begin 
        if (has_event) begin 
            case (current_state)
                TX_ADDR_ST : 
                    if (!bit_cnt) 
                        in_dout_data_shift <= in_dout_data;
                
                WAIT_ACK_ST : 
                    in_dout_data_shift <= {1'b0, in_dout_data_shift[DATA_WIDTH-1:1]};

                WRITE_ST : 
                    in_dout_data_shift <= {1'b0, in_dout_data_shift[DATA_WIDTH-1:1]};

                default: 
                    in_dout_data_shift <= in_dout_data_shift;
            endcase // current_state
        end 
    end 

    /*Read Enable signal for input fifo*/
    always_ff @(posedge clk) begin : in_rden_processing
        if (has_event) begin  
            case (current_state) 
                IDLE_ST : 
                    if (!in_empty)
                        in_rden <= 1'b1;
                    else 
                        in_rden <= 1'b0;

                default : in_rden <= 1'b0;
            endcase
        end else begin 
            in_rden <= 1'b0;
        end 
    end 

    always_ff @(posedge clk) begin
        if (has_event) begin 
            case (current_state) 
                IDLE_ST: 
                    if (!in_empty)  
                        transmission_size <= in_dout_data;

                default: 
                    transmission_size <= transmission_size;
            endcase // current_state
        end 
    end 






endmodule