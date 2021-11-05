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


    localparam DURATION_     = (CLK_PERIOD/CLK_I2C_PERIOD);
    localparam DURATION_DIV2 = ((DURATION_)/2)-1          ;
    localparam DURATION_DIV4 = ((DURATION_)/4)            ;

    logic [$clog2(DURATION_)-1:0] duration_cnt_         = '{default:0};
    logic [$clog2(DURATION_)-1:0] duration_cnt_shifted_ = '{default:0};
    logic                         event_                = 1'b0        ;
    logic                         allow_counting_       = 1'b0        ;
    logic                         clk_assert_           = 1'b0        ;
    logic                         clk_deassert_         = 1'b0        ;
    logic [                  7:0] i2c_address_          = '{default:0};
    logic [2:0] bit_cnt_ = '{default:0};


    logic scl_ = 1'b1;
    logic sda_ = 1'b1;

    always_ff @(posedge clk) begin 
        if (duration_cnt_ < (DURATION_-1)) 
            duration_cnt_ <= duration_cnt_ + 1;
        else 
            duration_cnt_ <= '{default:0};
    end 

    always_ff @(posedge clk) begin 
        if (duration_cnt_ == (DURATION_DIV4))
            allow_counting_ <= 1'b1;
    end 

    always_ff @(posedge clk) begin 
        if (allow_counting_) 
            if (duration_cnt_shifted_ < (DURATION_-1)) begin 
                duration_cnt_shifted_ <= duration_cnt_shifted_ + 1;
            end else begin 
                duration_cnt_shifted_ <= '{default:0};
            end 
    end 

    always_ff @(posedge clk) begin 
        if (duration_cnt_ == (DURATION_-1)) 
            event_ <= 1'b1;
        else 
            event_ <= 1'b0;
    end 

    always_ff @(posedge clk) begin 
        if (duration_cnt_shifted_ == (DURATION_DIV2)) 
            clk_deassert_ <= 1'b1;
        else 
            clk_deassert_ <= 1'b0;
    end 

    always_ff @(posedge clk) begin 
        if (duration_cnt_shifted_ == (DURATION_-1)) 
            clk_assert_ <= 1'b1;
        else 
            clk_assert_ <= 1'b0;
    end 

    always_ff @(posedge clk) begin 
        // if (duration_cnt_shifted_ == (DURATION_-1))
        //     scl_ <= 1'b1;
        // else if (duration_cnt_shifted_ == DURATION_DIV2) 
        //     scl_ <= 1'b0;

        case (current_state_) 
            IDLE_ST_ : 
                scl_ <= 1'b1;

            START_ST_ : 
                if (clk_assert_) 
                    scl_ <= 1'b0;

                // if (duration_cnt_shifted_ == (DURATION_-1))
                //     scl_ <= 1'b1;
                // else if (duration_cnt_shifted_ == DURATION_DIV2) 
                //     scl_ <= 1'b0;

            TX_ADDR_ST_: 
                if (duration_cnt_shifted_ == (DURATION_-1))
                    scl_ <= 1'b1;
                else if (duration_cnt_shifted_ == DURATION_DIV2) 
                    scl_ <= 1'b0;

            STOP_ST_ : 
                if (clk_assert_)
                    scl_ <= 1'b1;
                // if (duration_cnt_shifted_ == (DURATION_-1))
                //     scl_ <= 1'b1;
                // else if (duration_cnt_shifted_ == DURATION_DIV2) 
                //     scl_ <= 1'b0;


            default : 
                scl_ <= 1'b1;
        endcase // current_state_

    end 

    always_ff @(posedge clk) begin 
        if (event_) begin 
            case (current_state_)
                IDLE_ST_ : 
                    if (!in_empty) 
                        sda_ <= 1'b0;
                    else 
                        sda_ <= 1'b1;

                START_ST_ : 
                    sda_ <= i2c_address_[7];

                TX_ADDR_ST_ : 
                    sda_ <= i2c_address_[7];

                default : 
                    sda_ <= 1'b1;

            endcase
        end 
    end 

    typedef enum {
        IDLE_ST_,
        START_ST_,
        TX_ADDR_ST_,
        STOP_ST_,
        STUB_ST_
    } fsm_;

    fsm_ current_state_ = IDLE_ST_;

    always_ff @(posedge clk) begin 
        if (reset) begin 
            current_state_ <= IDLE_ST_;
        end else begin 

            if (event_) begin 
                case (current_state_)
                    IDLE_ST_ : 
                        if (!in_empty) 
                            current_state_ <= START_ST_;

                    START_ST_ : 
                        current_state_ <= TX_ADDR_ST_;

                    TX_ADDR_ST_ : 
                        if (!bit_cnt_) 
                            current_state_ <= STOP_ST_;

                    STOP_ST_ :
                        current_state_ <= STUB_ST_;

                    default: 
                        current_state_ <= current_state_;
                endcase 
            end else begin 
                current_state_ <= current_state_;
            end 
        end 
    end 

    always_ff @(posedge clk) begin
        if (event_)
            case (current_state_) 
                IDLE_ST_ : 
                    i2c_address_ <= in_dout_user;

                START_ST_ : 
                    i2c_address_ <= {i2c_address_[6:0], 1'b0};
                
                TX_ADDR_ST_ : 
                    i2c_address_ <= {i2c_address_[6:0], 1'b0};

                default: 
                    i2c_address_ <= i2c_address_;
            endcase
    end

    always_ff @(posedge clk) begin 
        if (event_) begin 
            case (current_state_) 

                TX_ADDR_ST_ : 
                    bit_cnt_ <= bit_cnt_ - 1;

                default : 
                    bit_cnt_ <= 7;
            endcase // current_state
        end 
    end 













    /*Limit for counter for I2C CLK counter*/
    localparam DURATION = (CLK_PERIOD/CLK_I2C_PERIOD/2);
    /*Width of AXI4S data buses*/
    localparam DATA_WIDTH = (N_BYTES*8); 

    /*Clock counter for create i2C CLK*/
    logic [$clog2(DURATION):0] clock_counter            = '{default:0};
    logic [$clog2(DURATION):0] clock_counter_shifted    = '{default:0};
    logic                      clock_counter_allow_flaq = 1'b0        ;


    logic internal_i2c_clk   = 1'b0;
    logic d_internal_i2c_clk = 1'b0;

    logic clk_assert   = 1'b0;
    logic clk_deassert = 1'b0;

    logic sda = 1'b1;
    logic scl = 1'b1;

    /*Input FIFO signal group for sending data to I2C devices*/
    logic [(DATA_WIDTH-1):0] in_dout_data       ;
    logic [   (N_BYTES-1):0] in_dout_keep       ;
    logic [             7:0] in_dout_user       ;
    logic                    in_dout_last       ;
    logic                    in_rden      = 1'b0;
    logic                    in_empty           ;
    /*address for i2c device and operation*/
    logic [7:0] i2c_address = '{default:0};

    /**/
    typedef enum {
        IDLE_ST ,
        START_ST,
        TX_ADDR_ST,
        STOP_ST ,
        STUB_ST
    } fsm;

    fsm current_state = IDLE_ST;

    logic [2:0] bit_cnt = '{default:0};

    /*Dont forget about DRCs for this component*/

    /*clock counter for i2c clk generation and event flaqs generation*/
    always_ff @(posedge clk) begin 
        if (clock_counter < DURATION-1) 
            clock_counter <= clock_counter + 1;
        else 
            clock_counter <= '{default:0};
    end 

    always_ff @(posedge clk) begin 
        if (clock_counter_allow_flaq) 
            if (clock_counter_shifted < DURATION-1) 
                clock_counter_shifted <= clock_counter_shifted + 1;
            else 
                clock_counter_shifted <= '{default:0};
    end 


    always_ff @(posedge clk) begin 
        if (reset)
            clock_counter_allow_flaq <= 1'b0;
        else 
            if (clock_counter == (DURATION-1)/2)
                clock_counter_allow_flaq <= 1'b1;
    end     

    /*internal clock i2c generation*/
    always_ff @(posedge clk) begin 
        if (clock_counter < (DURATION-1))
            internal_i2c_clk <= internal_i2c_clk;
        else 
            internal_i2c_clk <= ~internal_i2c_clk;
    end 

    /*latenced for 1 clk period signal for event rising/falling generation*/
    always_ff @(posedge clk) begin 
        d_internal_i2c_clk <= internal_i2c_clk;
    end 

    /*event when internal i2c clk asserted*/
    always_ff @(posedge clk) begin 
        if (!d_internal_i2c_clk & internal_i2c_clk)
            clk_assert <= 1'b1;
        else 
            clk_assert <= 1'b0;
    end 

    /*event when internal i2c clk asserted*/
    always_ff @(posedge clk) begin 
        if (d_internal_i2c_clk & !internal_i2c_clk)
            clk_deassert <= 1'b1;
        else 
            clk_deassert <= 1'b0;
    end 

    always_ff @(posedge clk) begin : current_state_proc
        if (reset) begin 
            current_state <= IDLE_ST;
        end else begin 
            if (clk_assert) 
                case (current_state)
                    IDLE_ST :
                        if (~in_empty) 
                            current_state <= START_ST;

                    START_ST : 
                        current_state <= TX_ADDR_ST;

                    TX_ADDR_ST:
                        if (!bit_cnt)
                            current_state <= STOP_ST;

                    STOP_ST : 
                        current_state <= STUB_ST;

                    STUB_ST : 
                        current_state <= current_state;

                    default : 
                        current_state <= STUB_ST;
                endcase // current_state
        end 
    end 



    always_ff @(posedge clk) begin : sda_proc
        if (clk_assert) begin 
            case (current_state) 
                IDLE_ST : 
                    if (~in_empty)
                        sda <= 1'b0;

                START_ST : 
                    sda <= i2c_address[7];

                TX_ADDR_ST : 
                    sda <= i2c_address[7];

                STOP_ST : 
                    sda <= 1'b1;

                default : 
                    sda <= sda;
            endcase // current_state
        end 
    end 

    always_ff @(posedge clk) begin : scl_proc 
        case (current_state) 
            
            START_ST: 
                if (clk_deassert)
                    scl <= 1'b0;

            TX_ADDR_ST : 
                if (clock_counter_shifted == (DURATION-1))
                    scl <= ~scl;

            STOP_ST:
                if (clk_deassert)
                    scl <= 1'b1;

            default : 
                scl <= scl;
        endcase // current_state
    end 


    always_ff @(posedge clk) begin 
        if (clk_assert) begin 
            case (current_state) 

                TX_ADDR_ST : 
                    bit_cnt <= bit_cnt - 1;

                default : 
                    bit_cnt <= 7;
            endcase // current_state
        end 
    end 

    /*save this address for transmission to I2C bus
    *   and return this address to master device on AXI-Stream bus
    */
    always_ff @(posedge clk) begin
        if (clk_assert)
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

    // /*Read Enable signal for input fifo*/
    // always_ff @(posedge clk) begin : in_rden_processing
    //     case (current_state) 
    //         STUB_ST : in_rden <= 1'b1;
    //         default : in_rden <= 1'b0;
    //     endcase
    // end 







endmodule