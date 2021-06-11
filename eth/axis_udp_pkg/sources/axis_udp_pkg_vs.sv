`timescale 1ns / 1ps


module axis_udp_pkg_vs #(
    parameter MAX_SIZE        = 1024  ,
    parameter N_BYTES         = 8     ,
    parameter HEAD_PART       = 6     ,
    parameter HEAD_WORD_LIMIT = 4     ,
    parameter ASYNC_MODE      = "FULL"  // "S_SIDE P_SIDE SYNC"
) (
    input                          CLK          ,
    input                          RESET        ,
    input        [           31:0] HOST_IP      ,
    input        [           47:0] HOST_MAC     ,
    input        [           15:0] HOST_PORT    ,
    input        [           31:0] DEST_IP      ,
    input        [           47:0] DEST_MAC     ,
    input        [           15:0] DEST_PORT    ,
    // packet size for insertion to head for ip/udp
    input                          S_AXIS_CLK   ,
    input        [(N_BYTES*8)-1:0] S_AXIS_TDATA ,
    input        [    N_BYTES-1:0] S_AXIS_TKEEP ,
    input                          S_AXIS_TVALID,
    input                          S_AXIS_TLAST ,
    output                         S_AXIS_TREADY,
    input                          M_AXIS_CLK   ,
    output logic [(N_BYTES*8)-1:0] M_AXIS_TDATA ,
    output logic [    N_BYTES-1:0] M_AXIS_TKEEP ,
    output logic                   M_AXIS_TVALID,
    input  logic                   M_AXIS_TREADY,
    output logic                   M_AXIS_TLAST
);

    parameter C_ADDITION_HEADER = 0                                         ;
    parameter C_IPV4_HEADER     = 20                                        ;
    parameter C_UDP_HEADER      = 8                                         ;
    parameter C_HEADER_SIZE     = C_ADDITION_HEADER + C_IPV4_HEADER + C_UDP_HEADER;

    parameter DATA_WIDTH     = (N_BYTES*8);
    parameter HEAD_WIDTH     = (HEAD_PART*8);
    parameter DELAYREG_WIDTH = (DATA_WIDTH - HEAD_WIDTH);

    parameter [15:0] C_ETH_TYPE        = 16'h0800;
    parameter [15:0] C_IPV4_IP_VER_LEN = 16'h4500;
    parameter [15:0] C_IPV4_ID         = 16'h0000;
    parameter [15:0] C_IPV4_FLAGS      = 16'h0000;
    parameter [ 7:0] C_IPV4_TTL        = 8'hFF   ;
    parameter [ 7:0] C_IPV4_PROTO      = 8'h11   ;

    logic s_axis_tlast_latch;

    logic s_side_clk;
    logic s_side_reset;

    logic [15:0] cmd_din         ;
    logic        cmd_wren  = 1'b0;
    logic        cmd_full        ;
    logic [15:0] cmd_dout        ;
    logic        cmd_rden  = 1'b0;
    logic        cmd_empty       ;
    logic [15:0] pkt_size_reg_udp;

    logic [DELAYREG_WIDTH-1:0] d_in_dout_data                   ;
    logic [   (N_BYTES*8)-1:0] in_dout_data                     ;
    logic [       N_BYTES-1:0] in_dout_keep                     ;
    logic [       N_BYTES-1:0] saved_in_dout_keep = '{default:0};
    logic                      in_dout_last                     ;
    logic                      in_rden            = 1'b0        ;
    logic                      in_empty                         ;

    logic [(N_BYTES*8)-1:0] out_din_data       ;
    logic [    N_BYTES-1:0] out_din_keep       ;
    logic                   out_din_last       ;
    logic                   out_wren     = 1'b0;
    logic                   out_full           ;
    logic                   out_awfull         ;


    logic [15:0] ipv4_chksum_reg;
    logic        ipv4_done      ;

    logic [$clog2(HEAD_WORD_LIMIT)-1:0] head_cnt     = '{default:0};
    logic [                       15:0] word_counter = '{default:0};
    logic [                       15:0] byte_counter = '{default:0};

    typedef enum {
        IDLE_ST,
        WRITE_HEADER_ST ,
        READ_FIRST_ST,
        WRITE_DATA_ST,
        WRITE_LAST_ST
    } fsm;

    fsm current_state = IDLE_ST;

    logic s_axis_reset;

    always_ff @(posedge CLK) begin : current_state_processing
        if (RESET) 
            current_state <= IDLE_ST;
        else
            case (current_state) 

                IDLE_ST : 
                    if (!cmd_empty) begin 
                        if (ipv4_done) begin 
                            if (!out_awfull) begin 
                                current_state <= WRITE_HEADER_ST;
                            end 
                        end 
                    end 

                WRITE_HEADER_ST : 
                    if (head_cnt == HEAD_WORD_LIMIT) begin 
                        current_state <= READ_FIRST_ST;
                    end 

                READ_FIRST_ST : 
                    if (!out_awfull) begin 
                        if (in_dout_last) begin 
                            case (in_dout_keep)
                                8'hFF : 
                                    current_state <= WRITE_LAST_ST;

                                8'h7F : 
                                    current_state <= WRITE_LAST_ST;

                                default : 
                                    current_state <= IDLE_ST;

                            endcase

                        end else begin  
                            current_state <= WRITE_DATA_ST;
                        end 
                    end 

                WRITE_DATA_ST : 
                    if (in_rden) begin 
                        if (in_dout_last) begin 
                            case (in_dout_keep) 
                                
                                8'hFF : 
                                    current_state <= WRITE_LAST_ST;

                                8'h7F : 
                                    current_state <= WRITE_LAST_ST;

                                default : 
                                    current_state <= IDLE_ST;

                            endcase
                        end 
                    end 

                WRITE_LAST_ST :  
                    if (!out_awfull)
                        current_state <= IDLE_ST;

                default : 
                    current_state <= IDLE_ST;

            endcase // current_state
    end 

    always_ff @(posedge CLK) begin : head_cnt_processing 
        if (RESET)
            head_cnt <= '{default:0};
        else
            case (current_state)
                WRITE_HEADER_ST : 
                    if (!out_awfull) begin 
                        head_cnt <= head_cnt + 1;
                    end 

                default : 
                    head_cnt <= '{default:0};

            endcase
    end 


    ipv4_chksum_calc_sync #(.SWAP_BYTES(1'b0)) ipv4_chksum_calc_sync_inst (
        .CLK            (CLK            ),
        .RESET          (RESET          ),
        .IPV4_CALC_START(~cmd_empty     ),
        .IPV4_IP_VER_LEN(16'h4500       ),
        .IPV4_IP_ID     (16'h0000       ),
        .IPV4_TOTAL_SIZE(cmd_dout       ),
        .IPV4_TTL       (8'hFF          ),
        .IPV4_PROTO     (8'h11          ),
        .IPV4_SRC_ADDR  (HOST_IP        ),
        .IPV4_DST_ADDR  (DEST_IP        ),
        .IPV4_CHKSUM    (ipv4_chksum_reg),
        .IPV4_DONE      (ipv4_done      )
    );


    generate
        if ((ASYNC_MODE == "FULL") || (ASYNC_MODE == "S_SIDE")) begin 

            always_comb begin 
                s_side_clk = S_AXIS_CLK;
                s_side_reset = s_axis_reset;
            end 

            rst_syncer #(.INIT_VALUE(1'b1)) rst_syncer_inst_s_axis (
                .CLK      (s_side_clk  ),
                .RESET    (RESET       ),
                .RESET_OUT(s_axis_reset)
            );
            
            fifo_in_async_xpm #(
                .DATA_WIDTH(DATA_WIDTH),
                .CDC_SYNC  (4        ),
                .MEMTYPE   ("block"  ),
                .DEPTH     (2048     )
            ) fifo_in_async_xpm_inst (
                .S_AXIS_CLK   (s_side_clk        ),
                .S_AXIS_RESET (s_side_reset      ),
                .M_AXIS_CLK   (CLK               ),
                
                .S_AXIS_TDATA (S_AXIS_TDATA      ),
                .S_AXIS_TKEEP (S_AXIS_TKEEP      ),
                .S_AXIS_TVALID(S_AXIS_TVALID     ),
                .S_AXIS_TLAST (s_axis_tlast_latch),
                .S_AXIS_TREADY(S_AXIS_TREADY     ),
                
                .IN_DOUT_DATA (in_dout_data      ),
                .IN_DOUT_KEEP (in_dout_keep      ),
                .IN_DOUT_LAST (in_dout_last      ),
                .IN_RDEN      (in_rden           ),
                .IN_EMPTY     (in_empty          )
            );

            fifo_cmd_async_xpm #(
                .DATA_WIDTH(16     ),
                .CDC_SYNC  (4      ),
                .MEMTYPE   ("block"),
                .DEPTH     (2048   )
            ) fifo_cmd_async_xpm_inst (
                .CLK_WR  (s_side_clk  ),
                .RESET_WR(s_side_reset),
                .CLK_RD  (CLK         ),
                .DIN     (cmd_din     ),
                .WREN    (cmd_wren    ),
                .FULL    (cmd_full    ),
                .DOUT    (cmd_dout    ),
                .RDEN    (cmd_rden    ),
                .EMPTY   (cmd_empty   )
            );

        end else begin 

            always_comb begin
                s_side_clk   = CLK;
                s_side_reset = RESET;
            end 

            fifo_in_sync_xpm #(
                .DATA_WIDTH(DATA_WIDTH),
                .MEMTYPE   ("block"  ),
                .DEPTH     (2048     )
            ) fifo_in_sync_xpm_inst (
                .CLK          (CLK               ),
                .RESET        (RESET             ),
                
                .S_AXIS_TDATA (S_AXIS_TDATA      ),
                .S_AXIS_TKEEP (S_AXIS_TKEEP      ),
                .S_AXIS_TVALID(S_AXIS_TVALID     ),
                .S_AXIS_TLAST (s_axis_tlast_latch),
                .S_AXIS_TREADY(S_AXIS_TREADY     ),
                
                .IN_DOUT_DATA (in_dout_data      ),
                .IN_DOUT_KEEP (in_dout_keep      ),
                .IN_DOUT_LAST (in_dout_last      ),
                .IN_RDEN      (in_rden           ),
                .IN_EMPTY     (in_empty          )
            );
            fifo_cmd_sync_xpm #(
                .DATA_WIDTH(16           ),
                .MEMTYPE   ("distributed"),
                .DEPTH     (2048         )
            ) fifo_cmd_sync_xpm_inst (
                .CLK  (CLK      ),
                .RESET(RESET    ),
                .DIN  (cmd_din  ),
                .WREN (cmd_wren ),
                .FULL (cmd_full ),
                .DOUT (cmd_dout ),
                .RDEN (cmd_rden ),
                .EMPTY(cmd_empty)
            );
        end 
    endgenerate

    always_ff @(posedge CLK) begin 
        if (RESET) 
            cmd_rden <= 1'b0;
        else 
            case (current_state) 
                WRITE_HEADER_ST : 
                    if (head_cnt == HEAD_WORD_LIMIT) begin 
                        cmd_rden <= 1'b1;
                    end else begin  
                        cmd_rden <= 1'b0;
                    end 

                default : 
                    cmd_rden <= 1'b0;
            endcase
    end 

    always_comb begin 
        if ((current_state == WRITE_DATA_ST | current_state == READ_FIRST_ST) & !out_awfull)
            in_rden = 1'b1;
        else 
            in_rden = 1'b0;
    end 

    always_ff @(posedge CLK) begin : d_in_dout_data_processing
        if (in_rden)
            d_in_dout_data <= in_dout_data[DATA_WIDTH-1:(DATA_WIDTH-DELAYREG_WIDTH)];
    end  

    // for assertion tlast of packet if size exceeds MAX_SIZE values in words
    always_ff @(posedge s_side_clk) begin 
        if (s_side_reset) begin 
            word_counter <= '{default:0};
        end else begin 
            if (S_AXIS_TVALID & S_AXIS_TREADY) begin 
                if (s_axis_tlast_latch) begin 
                    word_counter <= '{default:0};
                end else begin  
                    if (word_counter < MAX_SIZE-1) begin 
                        word_counter <= word_counter + 1;
                    end else begin 
                        word_counter <= word_counter;
                    end 
                end 
            end 
        end 
    end 

    // for insertion to headers and calculation ipv4 checksum. 
    // start value calculated as UDP_PAYLOAD + UDP_HEAD + IP_HEAD
    always_ff @(posedge s_side_clk) begin : byte_counter_proc
        if (s_side_reset) begin
            byte_counter <= C_HEADER_SIZE;
        end else begin
            if (S_AXIS_TVALID & S_AXIS_TREADY) begin 
                if (s_axis_tlast_latch) begin 
                    byte_counter <= C_HEADER_SIZE;
                end else begin  
                    byte_counter <= byte_counter + 8;
                end 
            end 
        end
    end 

    // Command queue receives ipv4 total size parameter
    always_ff @(posedge s_side_clk) begin 
        if (S_AXIS_TVALID & S_AXIS_TREADY & s_axis_tlast_latch)
            case (S_AXIS_TKEEP)
                'h7F    : cmd_din <= byte_counter + 7;
                'h3F    : cmd_din <= byte_counter + 6;
                'h1F    : cmd_din <= byte_counter + 5;
                'h0F    : cmd_din <= byte_counter + 4;
                'h07    : cmd_din <= byte_counter + 3;
                'h03    : cmd_din <= byte_counter + 2;
                'h01    : cmd_din <= byte_counter + 1;
                default : cmd_din <= byte_counter + 8;
            endcase // S_AXIS_TKEEP
    end 

    always_ff @(posedge s_side_clk) begin 
        if (S_AXIS_TVALID & S_AXIS_TREADY & s_axis_tlast_latch)
            cmd_wren <= 1'b1;
        else 
            cmd_wren <= 1'b0;
    end 

    always_comb begin 
        if (word_counter < MAX_SIZE-1)
            s_axis_tlast_latch <= S_AXIS_TLAST;
        else 
            s_axis_tlast_latch <= 1'b1;
    end 

    generate
        if ((ASYNC_MODE == "FULL") || (ASYNC_MODE == "M_SIDE")) begin 
            fifo_out_async_xpm #(
                .DATA_WIDTH(N_BYTES*8),
                .CDC_SYNC  (4        ),
                .MEMTYPE   ("block"  ),
                .DEPTH     (128      )
            ) fifo_out_async_xpm_inst (
                .CLK          (CLK          ),
                .RESET        (RESET        ),
                .OUT_DIN_DATA (out_din_data ),
                .OUT_DIN_KEEP (out_din_keep ),
                .OUT_DIN_LAST (out_din_last ),
                .OUT_WREN     (out_wren     ),
                .OUT_FULL     (out_full     ),
                .OUT_AWFULL   (out_awfull   ),
                
                .M_AXIS_CLK   (M_AXIS_CLK   ),
                .M_AXIS_TDATA (M_AXIS_TDATA ),
                .M_AXIS_TKEEP (M_AXIS_TKEEP ),
                .M_AXIS_TVALID(M_AXIS_TVALID),
                .M_AXIS_TLAST (M_AXIS_TLAST ),
                .M_AXIS_TREADY(M_AXIS_TREADY)
            );
        end else begin  
            fifo_out_sync_xpm #(
                .DATA_WIDTH(N_BYTES*8),
                .MEMTYPE   ("block"  ),
                .DEPTH     (128      )
            ) fifo_out_sync_xpm_inst (
                .CLK          (CLK          ),
                .RESET        (RESET        ),
                
                .OUT_DIN_DATA (out_din_data ),
                .OUT_DIN_KEEP (out_din_keep ),
                .OUT_DIN_LAST (out_din_last ),
                .OUT_WREN     (out_wren     ),
                .OUT_FULL     (out_full     ),
                .OUT_AWFULL   (out_awfull   ),
                
                .M_AXIS_TDATA (M_AXIS_TDATA ),
                .M_AXIS_TKEEP (M_AXIS_TKEEP ),
                .M_AXIS_TVALID(M_AXIS_TVALID),
                .M_AXIS_TLAST (M_AXIS_TLAST ),
                .M_AXIS_TREADY(M_AXIS_TREADY)
            );
        end 
    endgenerate

    always_ff @(posedge CLK) begin : pkt_size_reg_udp_processing
        pkt_size_reg_udp <= cmd_dout - C_IPV4_HEADER;
    end

    always_ff @(posedge CLK) begin : out_din_data_processing
        case (current_state)
            WRITE_HEADER_ST :
                case (head_cnt)
                    'h00 : out_din_data <= {HOST_MAC[15:0] , DEST_MAC};
                    'h01 : out_din_data <= {C_IPV4_IP_VER_LEN[7:0], C_IPV4_IP_VER_LEN[15:8], C_ETH_TYPE[7:0], C_ETH_TYPE[15:8], HOST_MAC[47:16]};
                    'h02 : out_din_data <= {C_IPV4_PROTO, C_IPV4_TTL, C_IPV4_FLAGS, C_IPV4_ID, cmd_dout[7:0], cmd_dout[15:8]};
                    'h03 : out_din_data <= {DEST_IP[15:0], HOST_IP, ipv4_chksum_reg[7:0],  ipv4_chksum_reg[15:8]};
                    'h04 : out_din_data <= {pkt_size_reg_udp[7:0], pkt_size_reg_udp[15:8], DEST_PORT, HOST_PORT, DEST_IP[31:16]};
                    'h05 : out_din_data <= {in_dout_data[47:0], 16'h0000};
                    default : out_din_data <= out_din_data;
                endcase

            WRITE_DATA_ST : 
                if (in_rden)
                    out_din_data <= {in_dout_data[HEAD_WIDTH-1:0], d_in_dout_data[15:0]};

            WRITE_LAST_ST : 
                if (!out_awfull)
                    out_din_data <= {out_din_data[(DATA_WIDTH-1):(DATA_WIDTH-HEAD_WIDTH)], d_in_dout_data[15:0]};

            default :
                out_din_data <= out_din_data;
        endcase // S_AXIS_TKEEP
    end 

    always_ff @(posedge CLK) begin : saved_in_dout_keep_processing 
        if (in_rden)
            if (in_dout_last)
                saved_in_dout_keep <= in_dout_keep;
    end 

    always_ff @(posedge CLK) begin : out_din_keep_processing 
        case (current_state)

            WRITE_HEADER_ST : 
                if (head_cnt == HEAD_WORD_LIMIT) begin 
                    out_din_keep <= {in_dout_keep[HEAD_PART-1:0], 2'b11};
                end else begin  
                    out_din_keep <= '{default:1};
                end 

            WRITE_DATA_ST : 
                if (in_rden) begin 
                    if (in_dout_last) begin 
                        out_din_keep <= {in_dout_keep[HEAD_PART-1:0], 2'b11};
                    end else begin 
                        out_din_keep <= '{default:1};
                    end  
                end 

            WRITE_LAST_ST : 
                case (saved_in_dout_keep)
                    8'h7F : 
                        out_din_keep <= 8'h1;

                    default : 
                        out_din_keep <= 8'h3;

                endcase

            default : 
                out_din_keep <= '{default:1};

        endcase // S_AXIS_TKEEP
    end 

            // WRITE_HEADER_ST : 
            //     if (head_cnt == HEAD_WORD_LIMIT) begin 
            //         out_din_keep <= {in_dout_keep[HEAD_PART-1:0], 2'b11};
            //     end else begin  
            //         out_din_keep <= '{default:1};
            //     end 


    always_ff @(posedge CLK) begin : out_din_last_processing 
        case (current_state)
            
            WRITE_HEADER_ST : 
                if (head_cnt == HEAD_WORD_LIMIT) begin 
                    if (in_dout_last) begin 
                        out_din_last <= 1'b1;
                    end else begin 
                        out_din_last <= 1'b0;
                    end 
                end else begin 
                    out_din_last <= 1'b0;
                end 

            WRITE_DATA_ST : 
                if (in_rden) begin 
                    if (in_dout_last) begin 
                        case (in_dout_keep) 
                            
                            8'hFF : 
                                out_din_last <= 1'b0;

                            8'h7F : 
                                out_din_last <= 1'b0;

                            default : 
                                out_din_last <= 1'b1;

                        endcase
                    end 
                end 

            WRITE_LAST_ST : 
                if (~out_awfull) 
                    out_din_last <= 1'b1;
            
            default : 
                out_din_last <= 1'b0;

        endcase 
    end 

    always_ff @(posedge CLK) begin 
        case (current_state) 
            WRITE_HEADER_ST : 
                if (!out_awfull)
                    out_wren <= 1'b1;
                else 
                    out_wren <= 1'b0;

            WRITE_DATA_ST :
                if (~out_awfull)
                    out_wren <= 1'b1;
                else 
                    out_wren <= 1'b0;

            WRITE_LAST_ST : 
                if (~out_awfull)
                    out_wren <= 1'b1;
                else 
                    out_wren <= 1'b0;

            default : 
                out_wren <= 1'b0;

        endcase
    end 



endmodule
