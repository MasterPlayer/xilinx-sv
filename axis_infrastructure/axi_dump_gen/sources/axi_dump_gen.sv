`timescale 1 ns / 1 ps

module axi_dump_gen #(
    parameter FREQ_HZ              = 250000000,
    parameter N_BYTES              = 2        ,
    parameter ASYNC                = 1'b0     ,
    parameter MODE                 = "SINGLE" , // "SINGLE", "ZEROS", "BYTE"
    parameter SWAP_BYTES           = 1'b0     ,
    parameter DEFAULT_PACKET_SIZE  = 4096     ,
    parameter DEFAULT_PACKET_LIMIT = 0        ,
    parameter DEFAULT_PAUSE        = 0
) (
    input                          aclk         ,
    input                          aresetn      ,
    input        [            4:0] awaddr       ,
    input        [            2:0] awprot       ,
    input                          awvalid      ,
    output logic                   awready      ,
    input        [           31:0] wdata        ,
    input        [            3:0] wstrb        ,
    input                          wvalid       ,
    output logic                   wready       ,
    output logic [            1:0] bresp        ,
    output logic                   bvalid       ,
    input                          bready       ,
    input        [            4:0] araddr       ,
    input        [            2:0] arprot       ,
    input                          arvalid      ,
    output logic                   arready      ,
    output logic [           31:0] rdata        ,
    output logic [            1:0] rresp        ,
    output logic                   rvalid       ,
    input                          rready       ,
    input                          M_AXIS_CLK   ,
    output logic [(N_BYTES*8)-1:0] M_AXIS_TDATA ,
    output logic [    N_BYTES-1:0] M_AXIS_TKEEP ,
    output logic                   M_AXIS_TVALID,
    input                          M_AXIS_TREADY,
    output logic                   M_AXIS_TLAST
);

    localparam integer ADDR_LSB = 2;
    localparam integer ADDR_OPT = 2;

    logic [7:0][31:0] register;

    logic        reset            ;
    logic        run_stop         ;
    logic        d_run_stop       ;
    logic        event_start      ;
    logic        event_stop       ;
    logic        ignore_ready     ;
    logic        status           ;
    logic [31:0] packet_size      ;
    logic [31:0] packet_limit     ;
    logic [31:0] pause            ;
    logic [31:0] valid_count      ;
    logic        m_axis_tready_cdc;

    logic device_not_ready_flaq ; 

    logic aw_en = 1'b1;

    if (ASYNC) begin 
        bit_syncer_fdre #(
            .DATA_WIDTH(1   ),
            .INIT_VALUE(1'b0)
        ) bit_syncer_fdre_inst (
            .CLK_SRC (M_AXIS_CLK       ),
            .CLK_DST (aclk             ),
            .DATA_IN (M_AXIS_TREADY    ),
            .DATA_OUT(m_axis_tready_cdc)
        );
    end 

    if (!ASYNC) begin 
        always_comb begin 
            m_axis_tready_cdc = M_AXIS_TREADY;
        end 
    end 


    always_ff @(posedge aclk) begin : d_run_stop_proc
        d_run_stop <= run_stop;
    end 

    always_comb begin 
        if (run_stop & !d_run_stop)
            event_start = 1'b1;
        else 
            event_start = 1'b0;
    end 

    always_comb begin 
        if (!run_stop & d_run_stop)
            event_stop = 1'b1;
        else 
            event_stop = 1'b0;
    end 



    always_comb begin : to_user_logic_assignment_group
        reset        = register[0][0];
        run_stop     = register[1][0];
        ignore_ready = register[1][1];
        packet_size  = register[2];
        packet_limit = register[3];
        pause        = register[4];
    end 

    always_comb begin : from_usr_logic_assignment_group
        register[1][16] = status;
        register[1][17] = device_not_ready_flaq;
        register[5]     = FREQ_HZ;
        register[6]     = valid_count;
        register[7]     = N_BYTES*8;
    end 

    always_ff @(posedge aclk) begin : device_not_ready_flaq_processing 
        if (!aresetn | !run_stop) begin 
            device_not_ready_flaq <= 1'b0;
        end else begin 
            if (ignore_ready) begin 

                if (!device_not_ready_flaq) begin 
                    if (!m_axis_tready_cdc) begin 
                        device_not_ready_flaq <= 1'b1;
                    end else begin 
                        device_not_ready_flaq <= device_not_ready_flaq;
                    end 
                end else begin 
                    if (arvalid & arready & ~rvalid) begin 
                        case (araddr[(ADDR_OPT + ADDR_LSB) : ADDR_LSB]) 
                            'h1 : device_not_ready_flaq <= 1'b0;
                            default : device_not_ready_flaq <= device_not_ready_flaq;
                        endcase // araddr
                    end else begin 
                        device_not_ready_flaq <= device_not_ready_flaq;
                    end                     
                end 
            end else begin 
                device_not_ready_flaq <= 1'b0;
            end 
        end 
    end 

    /**/
    always_ff @(posedge aclk) begin : aw_en_processing 
        if (!aresetn) 
            aw_en <= 1'b1;
        else
            if (!awready & awvalid & wvalid & aw_en)
                aw_en <= 1'b0;
            else
                if (bready & bvalid)
                    aw_en <= 1'b1;
    end 

    /**/
    always_ff @(posedge aclk) begin : awready_processing 
        if (!aresetn)
            awready <= 1'b0;
        else
            if (!awready & awvalid & wvalid & aw_en)
                awready <= 1'b1;
            else 
                awready <= 1'b0;
    end 



    always_ff @(posedge aclk) begin : wready_processing 
        if (!aresetn)
            wready <= 1'b0;
        else
            if (!wready & wvalid & awvalid & aw_en)
                wready <= 1'b1;
            else
                wready <= 1'b0;

    end 



    always_ff @(posedge aclk) begin : bvalid_processing
        if (!aresetn)
            bvalid <= 1'b0;
        else
            // if (awvalid & awready & wvalid & wready & ~bvalid)
            if (wvalid & wready & awvalid & awready & ~bvalid)
                bvalid <= 1'b1;
            else
                if (bvalid & bready)
                    bvalid <= 1'b0;

    end 



    always_ff @(posedge aclk) begin : arready_processing 
        if (!aresetn)
            arready <= 1'b0;
        else
            if (!arready & arvalid)
                arready <= 1'b1;
            else
                arready <= 1'b0;
            
    end



    always_ff @(posedge aclk) begin : rvalid_processing
        if (!aresetn)
            rvalid <= 1'b0;
        else
            if (arvalid & arready & ~rvalid)
                rvalid <= 1'b1;
            else 
                if (rvalid & rready)
                    rvalid <= 1'b0;

    end 


    always_ff @(posedge aclk) begin : rdata_processing 
        if (!aresetn)
            rdata <= '{default:0};
        else
            if (arvalid & arready & ~rvalid)
                case (araddr[(ADDR_OPT + ADDR_LSB) : ADDR_LSB]) 
                    'h0 : rdata <= register[0];
                    'h1 : rdata <= register[1];
                    'h2 : rdata <= register[2];
                    'h3 : rdata <= register[3];
                    'h4 : rdata <= register[4];
                    'h5 : rdata <= register[5];
                    'h6 : rdata <= register[6];
                    'h7 : rdata <= register[7];
                    default : rdata <= rdata;
                endcase // araddr
    end 



    always_ff @(posedge aclk) begin : rresp_processing 
        if (!aresetn) 
            rresp <= '{default:0};
        else
            if (arvalid & arready & ~rvalid)
                case (araddr[(ADDR_OPT + ADDR_LSB) : ADDR_LSB])
                    'h0 : rresp <= '{default:0};
                    'h1 : rresp <= '{default:0};
                    'h2 : rresp <= '{default:0};
                    'h3 : rresp <= '{default:0};
                    'h4 : rresp <= '{default:0};
                    'h5 : rresp <= '{default:0};
                    'h6 : rresp <= '{default:0};
                    'h7 : rresp <= '{default:0};
                    default : rresp <= 'b10;
                endcase; // araddr
    end                     



    always_ff @(posedge aclk) begin : bresp_processing
        if (!aresetn)
            bresp <= '{default:0};
        else
            if (awvalid & awready & wvalid & wready & ~bvalid)
                if (awaddr >= 0 | awaddr <= 7 )
                    bresp <= '{default:0};
                else
                    bresp <= 'b10;
    end


    always_ff @(posedge aclk) begin : reg_0_processing
        if (!aresetn) 
            register[0] <= 'b0;
        else
            if (awvalid & awready & wvalid & wready)
                if (awaddr[(ADDR_OPT + ADDR_LSB) : ADDR_LSB] == 'h00)
                    register[0] <= wdata;
    end 

    /*done*/
    always_ff @(posedge aclk) begin : reg_1_processing 
        if (!aresetn) begin  
            register[1][15:0] <= 'b0;
            register[1][31:18] <= 'b0;
        end else 
            if (awvalid & awready & wvalid & wready)
                if (awaddr[(ADDR_OPT + ADDR_LSB) : ADDR_LSB] == 'h01) begin
                    register[1][15:0] <= wdata[15:0];
                    register[1][31:18] <= wdata[31:18];
                end 
    end 

    /*done*/
    always_ff @(posedge aclk) begin : reg_2_processing 
        if (!aresetn)
            register[2] <= DEFAULT_PACKET_SIZE;
        else
            if (awvalid & awready & wvalid & wready)
                if (awaddr[(ADDR_OPT + ADDR_LSB) : ADDR_LSB] == 'h02)
                    register[2] <= wdata;
    end 

    always_ff @(posedge aclk) begin : reg_3_processing 
        if (!aresetn)
            register[3] <= DEFAULT_PACKET_LIMIT;
        else
            if (awvalid & awready & wvalid & wready)
                if (awaddr[(ADDR_OPT + ADDR_LSB) : ADDR_LSB] == 'h03)
                    register[3] <= wdata;
    end 

    always_ff @(posedge aclk) begin : reg_4_processing 
        if (!aresetn)
            register[4] <= DEFAULT_PAUSE;
        else
            if (awvalid & awready & wvalid & wready)
                if (awaddr[(ADDR_OPT + ADDR_LSB) : ADDR_LSB] == 'h04)
                    register[4] <= wdata;
    end 



    axis_dump_gen #(
        .FREQ_HZ   (FREQ_HZ   ),
        .N_BYTES   (N_BYTES   ),
        .ASYNC     (ASYNC     ),
        .MODE      (MODE      ),
        .SWAP_BYTES(SWAP_BYTES)
    ) axis_dump_gen (
        .CLK          (aclk         ),
        .RESET        (reset        ),
        
        .EVENT_START  (event_start  ),
        .EVENT_STOP   (event_stop   ),
        .IGNORE_READY (ignore_ready ),
        .STATUS       (status       ),
        
        .PAUSE        (pause        ),
        .PACKET_SIZE  (packet_size  ),
        .PACKET_LIMIT (packet_limit ),
        
        .VALID_COUNT  (valid_count  ),
        
        .M_AXIS_CLK   (M_AXIS_CLK   ),
        .M_AXIS_TDATA (M_AXIS_TDATA ),
        .M_AXIS_TKEEP (M_AXIS_TKEEP ),
        .M_AXIS_TVALID(M_AXIS_TVALID),
        .M_AXIS_TREADY(M_AXIS_TREADY),
        .M_AXIS_TLAST (M_AXIS_TLAST )
    );




endmodule
