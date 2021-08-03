`timescale 1ns / 1ps

module axis_adxl_device #(
    parameter [6:0] DEVICE_ADDR      = 52,
    parameter       REQUEST_INTERVAL = 1
) (
    input               clk                ,
    input               resetn             ,

    output logic [ 7:0] READ_DEVID         , //0x00   0  R    11100101  Device ID
    output logic [ 7:0] READ_THRESH_TAP    , //0x1D  29  R/W  00000000  Tap threshold
    output logic [ 7:0] READ_OFSX          , //0x1E  30  R/W  00000000  X-axis offset
    output logic [ 7:0] READ_OFSY          , //0x1F  31  R/W  00000000  Y-axis offset
    output logic [ 7:0] READ_OFSZ          , //0x20  32  R/W  00000000  Z-axis offset
    output logic [ 7:0] READ_DUR           , //0x21  33  R/W  00000000  Tap duration
    output logic [ 7:0] READ_LATENT        , //0x22  34  R/W  00000000  Tap latency
    output logic [ 7:0] READ_WINDOW        , //0x23  35  R/W  00000000  Tap window
    output logic [ 7:0] READ_THRESH_ACT    , //0x24  36  R/W  00000000  Activity threshold
    output logic [ 7:0] READ_THRESH_INACT  , //0x25  37  R/W  00000000  Inactivity threshold
    output logic [ 7:0] READ_TIME_INACT    , //0x26  38  R/W  00000000  Inactivity time
    output logic [ 7:0] READ_ACT_INACT_CTL , //0x27  39  R/W  00000000  Axis enable control for activity and inactivity detection
    output logic [ 7:0] READ_THRESH_FF     , //0x28  40  R/W  00000000  Free-fall threshold
    output logic [ 7:0] READ_TIME_FF       , //0x29  41  R/W  00000000  Free-fall time
    output logic [ 7:0] READ_TAP_AXES      , //0x2A  42  R/W  00000000  Axis control for single tap/double tap
    output logic [ 7:0] READ_ACT_TAP_STATUS, //0x2B  43  R    00000000  Source of single tap/double tap
    output logic [ 7:0] READ_BW_RATE       , //0x2C  44  R/W  00001010  Data rate and power mode control
    output logic [ 7:0] READ_POWER_CTL     , //0x2D  45  R/W  00000000  Power-saving features control
    output logic [ 7:0] READ_INT_ENABLE    , //0x2E  46  R/W  00000000  Interrupt enable control
    output logic [ 7:0] READ_INT_MAP       , //0x2F  47  R/W  00000000  Interrupt mapping control
    output logic [ 7:0] READ_INT_SOURCE    , //0x30  48  R    00000010  Source of interrupts
    output logic [ 7:0] READ_DATA_FORMAT   , //0x31  49  R/W  00000000  Data format control
    output logic [ 7:0] READ_DATAX0        , //0x32  50  R    00000000  X-Axis Data 0
    output logic [ 7:0] READ_DATAX1        , //0x33  51  R    00000000  X-Axis Data 1
    output logic [ 7:0] READ_DATAY0        , //0x34  52  R    00000000  Y-Axis Data 0
    output logic [ 7:0] READ_DATAY1        , //0x35  53  R    00000000  Y-Axis Data 1
    output logic [ 7:0] READ_DATAZ0        , //0x36  54  R    00000000  Z-Axis Data 0
    output logic [ 7:0] READ_DATAZ1        , //0x37  55  R    00000000  Z-Axis Data 1
    output logic [ 7:0] READ_FIFO_CTL      , //0x38  56  R/W  00000000  FIFO control
    output logic [ 7:0] READ_FIFO_STATUS   , //0x39  57  R    00000000  FIFO status
    
    input        [31:0] s_axis_tdata       ,
    input        [ 3:0] s_axis_tkeep       ,
    input        [ 7:0] s_axis_tdest       ,
    input               s_axis_tvalid      ,
    input               s_axis_tlast       ,
    output logic        s_axis_tready      ,
    
    output logic [31:0] m_axis_tdata       ,
    output logic [ 3:0] m_axis_tkeep       ,
    output logic [ 7:0] m_axis_tdest       ,
    output logic        m_axis_tvalid      ,
    input               m_axis_tready      ,
    output logic        m_axis_tlast
);


    logic reset ;

    always_comb begin : reset_assign_process
        reset = !resetn;
    end 

    logic [31:0] out_din_data = '{default:0};
    logic [ 3:0] out_din_keep = '{default:0};
    logic [ 7:0] out_din_dest = '{default:0};
    logic        out_din_last = 1'b0        ;
    logic        out_wren     = 1'b0        ;
    logic        out_full                   ;
    logic        out_awfull                 ;

    logic [31:0] request_counter = '{default:0};
    logic        request_event   = 1'b0        ;

    typedef enum {
        IDLE_ST         ,
        PERFORM_READ_ST ,
        READ_DATA_ST     
    } fsm;

    fsm current_state = IDLE_ST;

    logic [7:0] reg_addr_index = '{default:0};

    logic [7:0] reg_addr_mem [0:29] = {
        8'h00, // 11100101 Device ID
        8'h1D, // 00000000 Tap threshold
        8'h1E, // 00000000 X-axis offset
        8'h1F, // 00000000 Y-axis offset
        8'h20, // 00000000 Z-axis offset
        8'h21, // 00000000 Tap duration
        8'h22, // 00000000 Tap latency
        8'h23, // 00000000 Tap window
        8'h24, // 00000000 Activity threshold
        8'h25, // 00000000 Inactivity threshold
        8'h26, // 00000000 Inactivity time
        8'h27, // 00000000 Axis enable control for activity and inactivity detection
        8'h28, // 00000000 Free-fall threshold
        8'h29, // 00000000 Free-fall time
        8'h2A, // 00000000 Axis control for single tap/double tap
        8'h2B, // 00000000 Source of single tap/double tap
        8'h2C, // 00001010 Data rate and power mode control
        8'h2D, // 00000000 Power-saving features control
        8'h2E, // 00000000 Interrupt enable control
        8'h2F, // 00000000 Interrupt mapping control
        8'h30, // 00000010 Source of interrupts
        8'h31, // 00000000 Data format control
        8'h32, // 00000000 X-Axis Data 0
        8'h33, // 00000000 X-Axis Data 1
        8'h34, // 00000000 Y-Axis Data 0
        8'h35, // 00000000 Y-Axis Data 1
        8'h36, // 00000000 Z-Axis Data 0
        8'h37, // 00000000 Z-Axis Data 1
        8'h38, // 00000000 FIFO control
        8'h39  // 00000000 FIFO status
    };


    fifo_out_sync_tuser_xpm #(
        .DATA_WIDTH(32     ),
        .USER_WIDTH(8      ),
        .MEMTYPE   ("block"),
        .DEPTH     (16     )
    ) fifo_out_sync_tuser_xpm_inst (
        .CLK          (clk          ),
        .RESET        (reset        ),
        
        .OUT_DIN_DATA (out_din_data ),
        .OUT_DIN_KEEP (out_din_keep ),
        .OUT_DIN_USER (out_din_dest ),
        .OUT_DIN_LAST (out_din_last ),
        .OUT_WREN     (out_wren     ),
        .OUT_FULL     (out_full     ),
        .OUT_AWFULL   (out_awfull   ),
        
        .M_AXIS_TDATA (m_axis_tdata ),
        .M_AXIS_TKEEP (m_axis_tkeep ),
        .M_AXIS_TUSER (m_axis_tdest ),
        .M_AXIS_TVALID(m_axis_tvalid),
        .M_AXIS_TLAST (m_axis_tlast ),
        .M_AXIS_TREADY(m_axis_tready)
    );

    always_ff @(posedge clk) begin : current_state_processing 
        if (reset)
            current_state <= IDLE_ST;
        else
            case (current_state)
                IDLE_ST : 
                    if (request_counter == REQUEST_INTERVAL) 
                        current_state <= PERFORM_READ_ST;
                    else
                        current_state <= current_state;

                PERFORM_READ_ST : 
                    if (!out_awfull)
                        current_state <= READ_DATA_ST;
                    else
                        current_state <= current_state;

                READ_DATA_ST : 
                    if (s_axis_tvalid & s_axis_tready & (s_axis_tdest[7:1] == DEVICE_ADDR))
                        current_state <= IDLE_ST;
                    else
                        current_state <= current_state;

                default : 
                    current_state <= current_state;
            end 
    end     

    always_ff @(posedge clk) begin : reg_addr_index_processing 
        if (reset)
            reg_addr_index <= '{default:0};
        else
            case (current_state)
                PERFORM_READ_ST : 
                    if (out_awfull)
                        if (reg_addr_index == 8'h1D) begin
                            reg_addr_index <= '{default:0};
                        end else begin 
                            reg_addr_index <= reg_addr_index + 1;
                    else

                default : 
                    reg_addr_index <= reg_addr_index;
            endcase // current_state
    end 

    always_ff @(posedge clk) begin : request_counter_processing 
        if (reset)
            request_counter <= '{default:0};
        else
            case (current_state) 
                IDLE_ST : 
                    request_counter <= request_counter + 1;

                default : 
                    request_counter <= '{default:0};
            endcase
    end 

endmodule : axis_adxl_requester
