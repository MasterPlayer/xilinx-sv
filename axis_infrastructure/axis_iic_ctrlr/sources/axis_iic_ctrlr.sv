`timescale 1ns / 1ps

module axis_iic_ctrlr #(
    parameter CLK_PERIOD     = 100000000,
    parameter CLK_I2C_PERIOD = 400000   ,
    parameter N_BYTES        = 32       ,
    parameter DEPTH          = 16       
) (
    input                            clk          ,
    input                            resetn       ,
    // data to iic device AXI-Stream port
    input        [((N_BYTES*8)-1):0] s_axis_tdata ,
    input        [      N_BYTES-1:0] s_axis_tkeep ,
    input        [              7:0] s_axis_tdest ,
    input                            s_axis_tvalid,
    output logic                     s_axis_tready,
    input                            s_axis_tlast ,
    // data from iic device AXI-Stream port
    output logic [((N_BYTES*8)-1):0] m_axis_tdata ,
    output logic [      N_BYTES-1:0] m_axis_tkeep ,
    output logic [              7:0] m_axis_tdest ,
    output logic                     m_axis_tvalid,
    input                            m_axis_tready,
    output logic                     m_axis_tlast ,
    // i2c interface : input and tristate output
    input                            scl_i        ,
    input                            sda_i        ,
    output logic                     scl_t        ,
    output logic                     sda_t
);

    localparam DIVIDER = (CLK_PERIOD/CLK_I2C_PERIOD); 
    localparam EVENT_PERIOD = (DIVIDER/4);

    logic reset ;

    always_comb begin : reset_assign_process
        reset = !resetn;
    end 


 // 1) Положняк такой, что надо на любой команде закидывать размер 
 // количества данных, которое надо будет считать. 
 // Это будет первое слово которое надо запомнить и не передавать на устройства. 
 // При записи оно использоваться не будет. 
 // При чтении оно будет обозначать сколько данных надо считать. Возможно надо будет отнять -1
 // При этом, переход в рабочее состояние конечного автомата производится 
 // только тогда, когда cmd_fifo не пуста. 
 // заканчивать ее чтение надо только тогда, когда транзакция выполнится до конца 
 // или не выполнится вовсе. 
 


    logic [(N_BYTES*8)-1:0] in_dout_data                       ;
    logic [(N_BYTES*8)-1:0] in_dout_data_shift   = '{default:0};
    logic [    N_BYTES-1:0] in_dout_keep                       ;
    logic [    N_BYTES-1:0] in_dout_keep_shift   = '{default:0};
    logic [            7:0] in_dout_dest                       ;
    logic [            7:0] in_dout_dest_shift   = '{default:0};
    logic                   in_dout_last                       ;
    logic                   in_dout_last_latched = 1'b0        ;
    logic                   in_rden                            ;
    logic                   d_in_rden            = 1'b0        ;
    logic                   in_empty                           ;

    logic [  N_BYTES-1:0][7:0] out_din_data = '{default:0};
    logic [(N_BYTES)-1:0]      out_din_keep = '{default:0};
    logic [          7:0]      out_din_dest = '{default:0};
    logic                      out_din_last = 1'b0        ;
    logic                      out_wren     = 1'b0        ;
    logic                      out_full                   ;
    logic                      out_awfull                 ;

    typedef enum {
        IDLE_ST                 ,
        START_TRANSMISSION_ST   ,
        STOP_TRANSMISSION_ST    ,
        TX_ADDR_ST              ,

        WAIT_ACK_ST             ,
        READ_ST                 ,
        WAIT_RD_ACK_ST          ,
        WRITE_ST                ,
        WAIT_WR_ACK_ST          
    } fsm;

    fsm current_state = IDLE_ST;

    logic [$clog2(N_BYTES*8)-1:0] bit_cnt       = '{default : 0};
    logic [  $clog2(N_BYTES)-1:0] word_byte_cnt = '{default:0}  ;

    logic [(N_BYTES*8)-1:0] rd_byte_reg = '{default:0};

    (* dont_touch = "true" *)logic i2c_clk = 1'b0          ;
    (* dont_touch = "true" *)logic bus_i2c_clk = 1'b0;

    logic                     i2c_clk_assertion   = 1'b0        ;
    logic                     i2c_clk_deassertion = 1'b0        ;
    logic [($clog2(DIVIDER))-1:0] divider_counter     = '{default:0};

    logic has_slave_ack = 1'b0;

    logic [(N_BYTES*8)-1:0] cmd_din   = '{default:0};
    logic                   cmd_wren  = 1'b0        ;
    logic                   cmd_full                ;
    logic [(N_BYTES*8)-1:0] cmd_dout                ;
    logic                   cmd_rden  = 1'b0        ;
    logic                   cmd_empty               ;

    logic [($clog2(N_BYTES))-1:0] byte_address = '{default:0};

    fifo_cmd_sync_xpm #(
        .DATA_WIDTH(N_BYTES*8    ),
        .MEMTYPE   ("distributed"),
        .DEPTH     (DEPTH        )
    ) fifo_cmd_sync_xpm_inst (
        .CLK  (clk      ),
        .RESET(reset    ),
        .DIN  (cmd_din  ),
        .WREN (cmd_wren ),
        .FULL (cmd_full ),
        .DOUT (cmd_dout ),
        .RDEN (cmd_rden ),
        .EMPTY(cmd_empty)
    );

    always_ff @(posedge clk) begin 
        if (reset)
            cmd_wren <= 1'b0;
        else
            if (s_axis_tvalid & s_axis_tready & s_axis_tlast)
                cmd_wren <= 1'b1;
            else
                cmd_wren <= 1'b0;
    end 

    always_ff @(posedge clk) begin 
        if (reset)
            cmd_rden <= 1'b0;
        else
            if (i2c_clk_assertion)
                case (current_state)
                    STOP_TRANSMISSION_ST:
                        cmd_rden <= 1'b1;

                    default : 
                        cmd_rden <= 1'b0;

                endcase
            else
                cmd_rden <= 1'b0;


    end 

    fifo_in_sync_user_xpm #(
        .DATA_WIDTH(N_BYTES*8    ),
        .USER_WIDTH(8            ),
        .MEMTYPE   ("distributed"),
        .DEPTH     (DEPTH        )
    ) fifo_in_sync_user_xpm_inst (
        .CLK          (clk          ),
        .RESET        (reset        ),
        
        .S_AXIS_TDATA (s_axis_tdata ),
        .S_AXIS_TKEEP (s_axis_tkeep ),
        .S_AXIS_TUSER (s_axis_tdest ),
        .S_AXIS_TVALID(s_axis_tvalid),
        .S_AXIS_TLAST (s_axis_tlast ),
        .S_AXIS_TREADY(s_axis_tready),
        
        .IN_DOUT_DATA (in_dout_data ),
        .IN_DOUT_KEEP (in_dout_keep ),
        .IN_DOUT_USER (in_dout_dest ),
        .IN_DOUT_LAST (in_dout_last ),
        .IN_RDEN      (in_rden      ),
        .IN_EMPTY     (in_empty     )
    );

    always_ff @(posedge clk) begin
        case (current_state)
            IDLE_ST : 
                if (~cmd_empty)
                    out_din_dest <= in_dout_dest;

        endcase // current_state
    end 

    /* clock divider counter for division input clock*/
    always_ff @(posedge clk) begin : divider_counter_processing 
        if (divider_counter < (DIVIDER-1))
            divider_counter <= divider_counter + 1;
        else
            divider_counter <= '{default:0};
    end 

    /*clock for i2c logic for data on bus*/
    always_ff @(posedge clk) begin : i2c_clk_processing 
        if (divider_counter == (EVENT_PERIOD-1))
            i2c_clk <= 1'b1;
        else if (divider_counter == (EVENT_PERIOD*3))
            i2c_clk <= 1'b0;
    end 

    /*assertion event flaq for i2c_clk*/
    always_ff @(posedge clk) begin : i2c_clk_assertion_processing 
        if (divider_counter == EVENT_PERIOD-1)
            i2c_clk_assertion <= 1'b1;
        else
            i2c_clk_assertion <= 1'b0;
    end 

    /*deassertion event flaq for i2c_clk*/
    always_ff @(posedge clk) begin : i2c_clk_deassertion_processing 
        if (divider_counter == (EVENT_PERIOD*3)-1)
            i2c_clk_deassertion <= 1'b1;
        else
            i2c_clk_deassertion <= 1'b0;
    end 

    /*for i2c bus signal*/
    always_ff @(posedge clk) begin : bus_i2c_clk_processing 
        if (divider_counter == (EVENT_PERIOD * 2))
            bus_i2c_clk <= 1'b1;
        else if (divider_counter == DIVIDER-1)
            bus_i2c_clk <= 1'b0;
    end 

    /*fsm
    * All transmissions over states must be sets according with i2c_clk_assertion 
    * in other case fsm must wait asserion this signal
    */
    always_ff @(posedge clk) begin : fsm_processing
        if (reset)
            current_state <= IDLE_ST;
        else
            if (i2c_clk_assertion)
                case (current_state)
                    IDLE_ST : 
                        if (!cmd_empty)
                            if (in_dout_dest[0]) begin // if reading 
                                if (!out_awfull) begin 
                                    current_state <= START_TRANSMISSION_ST;
                                end 
                            end else begin 
                                current_state <= START_TRANSMISSION_ST;
                            end 

                    /*establish START for I2C transaction*/
                    START_TRANSMISSION_ST : 
                        current_state <= TX_ADDR_ST;

                    /*Transmission address + command operation*/
                    TX_ADDR_ST : 
                        if (bit_cnt == 0)
                            current_state <= WAIT_ACK_ST;

                    WAIT_ACK_ST :
                        if (has_slave_ack) 
                            if (in_dout_dest[0])
                                current_state <= READ_ST; // go to reading data from slave device
                            else
                                current_state <= WRITE_ST; // go to write data to slave
                        else
                            current_state <= STOP_TRANSMISSION_ST; // abort transaction, maybe i must signalize about this event and release input fifo for 1 packet, if i sending data to slave

                    /*transmit STOP flaq on i2c bus*/
                    STOP_TRANSMISSION_ST : 
                        current_state <= IDLE_ST;

                    /*WAIT ACK signal from slave after WRITE ADDRESS operation*/
                    /*ACK = '0' from slave on SDA bus */
                    /*if no ACK then exit*/
                    /*NO_ACK = line SDA is '1' state*/

                    READ_ST : 
                        if (bit_cnt == 0)
                            current_state <= WAIT_RD_ACK_ST;

                    WAIT_RD_ACK_ST :
                        if (!rd_byte_reg)
                            current_state <= STOP_TRANSMISSION_ST;
                        else
                            current_state <= READ_ST;

                    WRITE_ST :
                        if (bit_cnt == 0)
                            current_state <= WAIT_WR_ACK_ST;

                    WAIT_WR_ACK_ST : 
                        if (has_slave_ack)
                            if (!in_dout_keep_shift[0])
                                if (in_dout_last_latched)
                                    current_state <= STOP_TRANSMISSION_ST;
                                else
                                    current_state <= WRITE_ST;
                            else
                                current_state <= WRITE_ST;
                        else
                            current_state <= STOP_TRANSMISSION_ST;

                    default:
                        current_state <= IDLE_ST; 

                endcase

    end 

    always_ff @(posedge clk) begin : sda_t_processing 
        if (reset) 
            sda_t <= 1'b1;
        else
            if (i2c_clk_assertion)
                case (current_state)
                    IDLE_ST : 
                        if (!cmd_empty)
                            sda_t <= 1'b0;

                    START_TRANSMISSION_ST :
                        sda_t <= in_dout_dest[bit_cnt];

                    STOP_TRANSMISSION_ST : 
                        sda_t <= 1'b1;

                    TX_ADDR_ST : 
                        if (bit_cnt)
                            sda_t <= in_dout_dest[bit_cnt-1];
                        else
                            sda_t <= 1'b1;

                    WAIT_ACK_ST :
                        if (has_slave_ack) // if device presented
                            if (!in_dout_dest[0]) // if op = WRITE
                                sda_t <= in_dout_data[bit_cnt];    
                            else
                                sda_t <= 1'b1; // for write operation

                    WRITE_ST : 
                        if (bit_cnt != 0)
                            sda_t <= in_dout_data_shift[bit_cnt-1];
                        else
                            sda_t <= 1'b1;

                    WAIT_WR_ACK_ST : 
                        if (has_slave_ack)
                            if (!in_dout_keep_shift[0])
                                if (in_dout_last_latched)
                                    sda_t <= 1'b0;
                                else
                                    sda_t <= in_dout_data_shift[bit_cnt];
                            else
                                sda_t <= in_dout_data_shift[bit_cnt];
                        else
                            sda_t <= 1'b0;

                    READ_ST : 
                        if (bit_cnt)
                            sda_t <= 1'b1;
                        else
                            if (rd_byte_reg == 1)
                                sda_t <= 1'b1;
                            else
                                sda_t <= 1'b0;

                    WAIT_RD_ACK_ST:
                        if (rd_byte_reg == 0)
                            sda_t <= 1'b0;
                        else
                            sda_t <= 1'b1;

                    default : 
                        sda_t <= 1'b1;

                endcase
    end 

    always_ff @(posedge clk) begin : scl_t_processing 
        case (current_state)
            START_TRANSMISSION_ST : 
                /*START transaction on I2C bus must be started if i2c clk deasserted*/
                if (i2c_clk_deassertion) 
                    scl_t <= 1'b0;

            /*Transmit STOP state : SCL must be asserted if deassert i2c clk*/
            STOP_TRANSMISSION_ST : 
                if (i2c_clk_deassertion)
                    scl_t <= 1'b1;


            TX_ADDR_ST : 
                scl_t <= bus_i2c_clk;

            WAIT_ACK_ST : 
                scl_t <= bus_i2c_clk;

            WRITE_ST : 
                scl_t <= bus_i2c_clk;

            WAIT_WR_ACK_ST :
                scl_t <= bus_i2c_clk;

            READ_ST :
                scl_t <= bus_i2c_clk;


            WAIT_RD_ACK_ST :
                scl_t <= bus_i2c_clk;

            default : 
                scl_t <= 1'b1;

            endcase 
    end  



    always_ff @(posedge clk) begin : has_slave_ack_processing 
        if (reset)
            has_slave_ack <= 1'b0;
        else
            case (current_state)
                WAIT_ACK_ST : 
                    if (scl_i)
                        if (!sda_i)
                            has_slave_ack <= 1'b1;
                        else
                            has_slave_ack <= 1'b0;
                
                WAIT_WR_ACK_ST :
                    if (scl_i) 
                        if (!sda_i) 
                            has_slave_ack <= 1'b1;
                        else
                            has_slave_ack <= 1'b0;


                default : 
                    has_slave_ack <= 1'b0;

            endcase // current_state
    end



    always_ff @(posedge clk) begin : bit_cnt_processing 
        if (reset) 
            bit_cnt <= 'h7;
        else
            if (i2c_clk_assertion)
                case (current_state)

                    IDLE_ST : 
                        bit_cnt <= 7;
                    
                    TX_ADDR_ST :
                        if (bit_cnt != 0)
                            bit_cnt <= bit_cnt - 1;
                        else
                            bit_cnt <= 7;

                    WRITE_ST : 
                        if (bit_cnt != 0)
                            bit_cnt <= bit_cnt - 1;
                        else
                            bit_cnt <= 7;

                    READ_ST : 
                        if (bit_cnt != 0)
                            bit_cnt <= bit_cnt - 1;
                        else
                            bit_cnt <= 7;

                    default : 
                        bit_cnt <= bit_cnt;

                endcase
    end 



    always_ff @(posedge clk) begin : in_dout_data_shift_processing 
        case (current_state)
            WAIT_ACK_ST : 
                in_dout_data_shift <= in_dout_data; // assertion shifting register

            WRITE_ST : 
                if (bit_cnt == 0) 
                    if (i2c_clk_assertion)
                        in_dout_data_shift[((N_BYTES-1)*8)-1:0] <= in_dout_data_shift[(N_BYTES*8)-1:8];

            WAIT_WR_ACK_ST : 
                if (d_in_rden)
                    in_dout_data_shift <= in_dout_data;

            default : 
                in_dout_data_shift <= in_dout_data_shift;

        endcase // current_state
    end 



    always_ff @(posedge clk) begin : in_dout_keep_shift_processing 
        case (current_state) 
            WAIT_ACK_ST : 
                in_dout_keep_shift <= in_dout_keep; // assertion shifting register

            WRITE_ST : 
                if (bit_cnt == 0) 
                    if (i2c_clk_assertion)
                        in_dout_keep_shift[N_BYTES-1 : 0] <= {1'b0 , in_dout_keep_shift[N_BYTES-1:1]};


            WAIT_WR_ACK_ST : 
                if (d_in_rden)
                    if (!in_dout_last_latched)
                        in_dout_keep_shift <= in_dout_keep;

            default : 
                in_dout_keep_shift <= in_dout_keep_shift;

            endcase
    end 

    /*Переделать, надо брать команды откуда-то извне, а не с шины данных*/
    always_ff @(posedge clk) begin : rd_byte_reg_processing 
        if (i2c_clk_assertion)
            case (current_state)
                IDLE_ST : 
                    if (in_dout_data > DEPTH) begin 
                        rd_byte_reg <= DEPTH;
                    end else begin
                        rd_byte_reg <= in_dout_data;
                    end 

                READ_ST : 
                    if (bit_cnt == 0)
                        rd_byte_reg <= rd_byte_reg - 1;

                default : 
                    rd_byte_reg <= rd_byte_reg;

            endcase 
    end 

    /*WRITE OP operation*/
    always_ff @(posedge clk) begin : in_dout_last_latched_processing 
        if (i2c_clk_assertion)
            case (current_state) 

                WAIT_ACK_ST : 
                    in_dout_last_latched <= in_dout_last;

                WAIT_WR_ACK_ST : 
                    if (has_slave_ack)
                        in_dout_last_latched <= in_dout_last;

                default : 
                    in_dout_last_latched <= in_dout_last_latched;

            endcase
    end 

    always_comb begin : in_rden_assertion 
        case (current_state) 

            IDLE_ST: 
                if (i2c_clk_assertion & ~cmd_empty)
                    in_rden = 1'b1;
                else
                    in_rden = 1'b0;
            
            WAIT_WR_ACK_ST : 
                    in_rden = ((!in_dout_keep_shift[0]) & i2c_clk_deassertion);
            
            default : 
                in_rden = 1'b0;
        endcase
    end 

    /*for correct reading from input fifo we must delay in_rden signal for assign in_dout_data_shift, in_dout_keep_shift*/
    always_ff @(posedge clk) begin : d_in_rden_processing 
        d_in_rden <= in_rden;
    end 

    fifo_out_sync_tuser_xpm #(
        .DATA_WIDTH(N_BYTES*8),
        .USER_WIDTH(8        ),
        .MEMTYPE   ("block"  ),
        .DEPTH     (DEPTH    )
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

    always_ff @(posedge clk) begin : word_byte_cnt_processing
        if (reset)
            word_byte_cnt <= '{default:0};
        else
            if (i2c_clk_assertion)
                case (current_state)

                    IDLE_ST : 
                        word_byte_cnt <= '{default:0};

                    WAIT_RD_ACK_ST : 
                        if (word_byte_cnt < N_BYTES-1)
                            word_byte_cnt <= word_byte_cnt + 1;
                        else
                            word_byte_cnt <= '{default:0};
                    
                    default : 
                        word_byte_cnt <= word_byte_cnt;
                
                endcase
    end  

    always_ff @(posedge clk) begin : byte_address_processing 
        if (reset)
            byte_address <= '{default:0};
        else
            if (i2c_clk_assertion)
                case (current_state)
                    IDLE_ST : 
                        byte_address <= '{default:0};

                    READ_ST:
                        if (bit_cnt == 0)
                            if (byte_address == N_BYTES-1) 
                                byte_address <= '{default:0};
                            else
                                byte_address <= byte_address + 1;
                    
                    default:
                        byte_address <= byte_address;
                endcase // current_state
    end 

    always_ff @(posedge clk) begin : out_din_data_processing 
        if (reset)
            out_din_data <= '{default:'{default:0}};
        else
            if (i2c_clk_deassertion) 
                case (current_state)
                    READ_ST :
                        out_din_data[byte_address] <= {out_din_data[byte_address][6:0], sda_i};
                        // out_din_data <= {out_din_data[(N_BYTES*8)-2:0], sda_i};

                    default  : 
                        out_din_data <= out_din_data;

                endcase
    end 

    always_ff @(posedge clk) begin : out_din_keep_processing 
        if (reset) 
            out_din_keep <= '{default:0};
        else
            if (i2c_clk_assertion)
                case (current_state)

                    IDLE_ST : 
                        out_din_keep <= '{default:0};

                    READ_ST : 
                        if (bit_cnt == 0) begin 
                            if (&out_din_keep)
                                out_din_keep[N_BYTES-1:1] <= '{default:0};                        
                        
                            out_din_keep[byte_address] <= 1'b1;
                        end 
                            

                    default : 
                        out_din_keep <= out_din_keep;

                endcase 
    end 

    always_ff @(posedge clk) begin : out_din_last_processing 
        if (reset)
            out_din_last <= 1'b0;
        else
            if (i2c_clk_assertion) 
                case (current_state)
                    WAIT_RD_ACK_ST : 
                        if (!rd_byte_reg)
                            out_din_last <= 1'b1;
                        else
                            out_din_last <= 1'b0;

                    default : 
                        out_din_last <= out_din_last;

                endcase
    end 

    always_ff @(posedge clk) begin : out_wren_processing 
        if (reset)
            out_wren <= 1'b0;
        else
            if (i2c_clk_assertion)
                case (current_state)
                    WAIT_RD_ACK_ST : 
                        if (!rd_byte_reg)
                            out_wren <= 1'b1;
                        else    
                            if (word_byte_cnt == N_BYTES-1)
                                out_wren <= 1'b1;
                            else
                                out_wren <= 1'b0;
                    
                    default :
                        out_wren <= 1'b0;
                
                endcase

            else
                out_wren <= 1'b0;
    end 




endmodule : axis_iic_ctrlr
