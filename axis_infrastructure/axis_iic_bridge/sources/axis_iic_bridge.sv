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

    
    localparam TEMP_DURATION = (CLK_PERIOD/CLK_I2C_PERIOD);

    logic [$clog2(TEMP_DURATION)-1:0] temp_duration_cnt = '{default:0};
    logic [$clog2(TEMP_DURATION)-1:0] temp_duration_cnt_shifted = '{default:0};

    always_ff @(posedge clk) begin 
        if (temp_duration_cnt < TEMP_DURATION-1) 
            temp_duration_cnt <= temp_duration_cnt + 1;
        else 
            temp_duration_cnt <= '{default:0};
    end 

    logic allow_counting = 1'b0;

    always_ff @(posedge clk) begin 
        if (temp_duration_cnt == (TEMP_DURATION-1)/4)
            allow_counting <= 1'b1;
    end 

    always_ff @(posedge clk) begin 
        if (allow_counting) 
            if (temp_duration_cnt_shifted < TEMP_DURATION-1) begin 
                temp_duration_cnt_shifted <= temp_duration_cnt_shifted + 1;
            end else begin 
                temp_duration_cnt_shifted <= '{default:0};
            end 
    end 


    /*Limit for counter for I2C CLK counter*/
    localparam DURATION = (CLK_PERIOD/CLK_I2C_PERIOD/2);
    /*Width of AXI4S data buses*/
    localparam DATA_WIDTH = (N_BYTES*8); 

    /*Clock counter for create i2C CLK*/
    logic [$clog2(DURATION):0] clock_counter         = '{default:0};
    logic [$clog2(DURATION):0] clock_counter_shifted = '{default:0};
    logic clock_counter_allow_flaq = 1'b0;


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

    /*Read Enable signal for input fifo*/
    always_ff @(posedge clk) begin : in_rden_processing
        case (current_state) 
            STUB_ST : in_rden <= 1'b1;
            default : in_rden <= 1'b0;
        endcase
    end 







endmodule