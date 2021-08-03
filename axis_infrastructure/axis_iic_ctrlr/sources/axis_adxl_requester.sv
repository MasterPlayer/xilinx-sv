`timescale 1ns / 1ps

module axis_adxl_requester (
    input               clk          ,
    input               resetn       ,
    input               request_accel,
    output logic [15:0] x_pos        ,
    output logic [15:0] y_pos        ,
    output logic [15:0] z_pos        ,
    input        [31:0] s_axis_tdata ,
    input        [ 7:0] s_axis_tdest ,
    input               s_axis_tvalid,
    input               s_axis_tlast ,
    output logic [31:0] m_axis_tdata ,
    output logic [ 3:0] m_axis_tkeep ,
    output logic [ 7:0] m_axis_tdest ,
    output logic        m_axis_tvalid,
    input               m_axis_tready,
    output logic        m_axis_tlast
);


    localparam WORD_CNT_INIT_LIMIT = 6;
    localparam WORD_CNT_REQ_LIMIT = 2;

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

    typedef enum {
        IDLE_ST     ,
        INIT_ST     ,
        INIT_REQ_ST ,
        RX_DATA_ST   
    } fsm;

    fsm current_state = IDLE_ST;

    logic [7:0] tx_word_cnt = '{default:0};
    logic [7:0] rx_word_cnt = '{default:0};

    always_ff @(posedge clk) begin : fsm_processing
        if (reset)
            current_state <= INIT_ST;
        else
            case (current_state)
                INIT_ST:
                    if (!out_awfull)
                        if (tx_word_cnt == WORD_CNT_INIT_LIMIT-1)
                            current_state <= IDLE_ST;


                IDLE_ST : 
                    if (request_accel)
                        if (out_awfull)
                            current_state <= current_state;
                        else
                            current_state <= INIT_REQ_ST;

                INIT_REQ_ST: 
                    if (!out_awfull)
                        if (tx_word_cnt == WORD_CNT_REQ_LIMIT-1)
                            current_state <= RX_DATA_ST;

                RX_DATA_ST: 
                    if (!out_awfull)
                        current_state <= IDLE_ST;

                default:
                    current_state <= IDLE_ST; 

            endcase 
    end 

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

    always_ff @(posedge clk) begin : tx_word_cnt_processing 
        if (reset)
            tx_word_cnt <= '{default:0};
        else
            case (current_state)
                INIT_ST : 
                    if (!out_awfull)
                        tx_word_cnt <= tx_word_cnt + 1;
                    else
                        tx_word_cnt <= tx_word_cnt;

                INIT_REQ_ST : 
                    if (!out_awfull)
                        tx_word_cnt <= tx_word_cnt + 1;
                    else
                        tx_word_cnt <= tx_word_cnt;

                default :
                    tx_word_cnt <= '{default:0};
            endcase
    end 

    always_ff @(posedge clk) begin : rx_word_cnt_processing 
        if (reset)
            rx_word_cnt <= '{default:0};
        else
            if (s_axis_tvalid) begin 
                if (s_axis_tlast) begin 
                    rx_word_cnt <= '{default:0};
                end else begin 
                    rx_word_cnt <= rx_word_cnt + 1;
                end 
            end else begin 
                rx_word_cnt <= rx_word_cnt;
            end 
    end 

    always_ff @(posedge clk) begin : out_din_data_processing 
        if (reset)
            out_din_data <= '{default:0};
        else
            case (current_state)
                INIT_ST :
                    case (tx_word_cnt) 
                        0       : out_din_data <= 32'h00000002;
                        1       : out_din_data <= 32'h0000082D;
                        2       : out_din_data <= 32'h00000002;
                        3       : out_din_data <= 32'h00000031;
                        4       : out_din_data <= 32'h00000002;
                        5       : out_din_data <= 32'h00000F2C;
                        default : out_din_data <= out_din_data;
                    endcase

                INIT_REQ_ST : 
                    case (tx_word_cnt)
                        0: out_din_data <= 32'h00000001;
                        1: out_din_data <= 32'h00000032;
                    endcase

                RX_DATA_ST: 
                    out_din_data <= 32'h00000006;

                default  : 
                    out_din_data <= out_din_data;

            endcase
    end 

    always_ff @(posedge clk) begin
        case (current_state)
            INIT_ST : 
                out_din_dest <= 32'h000000A6;

            INIT_REQ_ST: 
                out_din_dest <= 32'h000000A6;

            RX_DATA_ST:
                out_din_dest <= 32'h000000A7;

            default : 
                out_din_dest <= out_din_dest; 

        endcase
    end 

    always_ff @(posedge clk) begin : out_din_keep_processing 
        if (reset) 
            out_din_keep <= '{default:0};
        else
            case (current_state)
                INIT_ST :
                    case (tx_word_cnt) 
                        0       : out_din_keep <= 4'hF;
                        1       : out_din_keep <= 4'h3;
                        2       : out_din_keep <= 4'hF;
                        3       : out_din_keep <= 4'h3;
                        4       : out_din_keep <= 4'hF;
                        5       : out_din_keep <= 4'h3;
                        default : out_din_keep <= out_din_keep;
                    endcase

                INIT_REQ_ST : 
                    case (tx_word_cnt)
                        0: out_din_keep <= 4'hF;
                        1: out_din_keep <= 4'h1;
                    endcase

                RX_DATA_ST: 
                    out_din_keep <= 4'hF;

                default  : 
                    out_din_keep <= out_din_keep;

            endcase
    end 

    always_ff @(posedge clk) begin : out_din_last_processing 
        if (reset)
            out_din_last <= 1'b0;
        else
            case (current_state)
                INIT_ST :
                    case (tx_word_cnt) 
                        0       : out_din_last <= 1'b0;
                        1       : out_din_last <= 1'b1;
                        2       : out_din_last <= 1'b0;
                        3       : out_din_last <= 1'b1;
                        4       : out_din_last <= 1'b0;
                        5       : out_din_last <= 1'b1;
                        default : out_din_last <= out_din_last;
                    endcase

                INIT_REQ_ST : 
                    case (tx_word_cnt)
                        0: out_din_last <= 1'b0;
                        1: out_din_last <= 1'b1;
                    endcase

                RX_DATA_ST: 
                    out_din_last <= 1'b1;

                default  : 
                    out_din_last <= out_din_last;

            endcase
    end 

    always_ff @(posedge clk) begin : out_wren_processing 
        if (reset)
            out_wren <= 1'b0;
        else
            case (current_state)
                INIT_ST : 
                    if (!out_awfull)
                        out_wren <= 1'b1;
                    else
                        out_wren <= 1'b0;

                INIT_REQ_ST : 
                    if (!out_awfull)
                        out_wren <= 1'b1;
                    else
                        out_wren <= 1'b0;

                RX_DATA_ST : 
                    if (~out_awfull)
                        out_wren <= 1'b1;
                    else
                        out_wren <= 1'b0;

                default :
                    out_wren <= 1'b0;
            
            endcase
    end 

    always_ff @(posedge clk) begin : x_pos_processing
        if (reset)
            x_pos <= '{default:0};
        else
            if (s_axis_tvalid & (s_axis_tdest == 8'hA7)) 
                case (rx_word_cnt)
                    0 : x_pos <= s_axis_tdata[15:0];
                    default : x_pos <= x_pos;
                endcase
    end 

    always_ff @(posedge clk) begin : y_pos_processing
        if (reset)
            y_pos <= '{default:0};
        else
            if (s_axis_tvalid & (s_axis_tdest == 8'hA7)) 
                case (rx_word_cnt)
                    0 : y_pos <= s_axis_tdata[31:16];
                    default : y_pos <= y_pos;
                endcase
    end 

    always_ff @(posedge clk) begin : z_pos_processing
        if (reset)
            z_pos <= '{default:0};
        else
            if (s_axis_tvalid & (s_axis_tdest == 8'hA7)) 
                case (rx_word_cnt)
                    1 : z_pos <= s_axis_tdata[15:0];
                    default : z_pos <= z_pos;
                endcase
            else
                z_pos <= z_pos;
    end 



endmodule : axis_adxl_requester
