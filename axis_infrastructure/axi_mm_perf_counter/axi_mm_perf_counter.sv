`timescale 1ns / 1ps



module axi_mm_perf_counter #(
    parameter COUNTER_WIDTH = 32       ,
    parameter COUNTER_LIMIT = 250000000,
    parameter N_BYTES       = 32       ,
    parameter ADDR_WIDTH    = 32       ,
    parameter ID_WIDTH      = 4
) (
    (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME CLK.axi_aclk, ASSOCIATED_BUSIF M_AXI:S_AXI_B:M_AXI_LITE:S_AXI_LITE:M_AXI_BYPASS:M_AXI_B:S_AXIS_C2H_0:S_AXIS_C2H_1:S_AXIS_C2H_2:S_AXIS_C2H_3:M_AXIS_H2C_0:M_AXIS_H2C_1:M_AXIS_H2C_2:M_AXIS_H2C_3:sc0_ats_m_axis_cq:sc0_ats_m_axis_rc:sc0_ats_s_axis_cc:sc0_ats_s_axis_rq:sc1_ats_m_axis_cq:sc1_ats_m_axis_rc:sc1_ats_s_axis_cc:sc1_ats_s_axis_rq:cxs_tx:cxs_rx, ASSOCIATED_RESET axi_aresetn, FREQ_HZ 250000000, FREQ_TOLERANCE_HZ 0, PHASE 0.0, CLK_DOMAIN pciex_mm_bd_xdma_0_0_axi_aclk, INSERT_V\
    IP                                  0                     " *)
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 CLK.axi_aclk CLK" *)
    input                               M_AXI_ACLK          ,
    (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME RST.axi_aresetn, POLARITY ACTIVE_LOW, INSERT_VIP 0" *)
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 RST.axi_aresetn RST" *)
    input                               M_AXI_ARESETN       ,
    /*************************** ADDRESS READ CHANNEL **********************************/
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI ARID" *)
    input        [      (ID_WIDTH-1):0] M_AXI_ARID          ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI ARADDR" *)
    input        [      ADDR_WIDTH-1:0] M_AXI_ARADDR        ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI ARLEN" *)
    input        [                 7:0] M_AXI_ARLEN         ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI ARSIZE" *)
    input        [                 2:0] M_AXI_ARSIZE        ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI ARBURST" *)
    input        [                 1:0] M_AXI_ARBURST       ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI ARPROT" *)
    input        [                 2:0] M_AXI_ARPROT        ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI ARVALID" *)
    input                               M_AXI_ARVALID       ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI ARLOCK" *)
    input                               M_AXI_ARLOCK        ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI ARCACHE" *)
    input        [                 3:0] M_AXI_ARCACHE       ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI ARREADY" *)
    input                               M_AXI_ARREADY       ,
    /*************************** DATA READ CHANNEL **********************************/
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI RDATA" *)
    input        [     (N_BYTES*8)-1:0] M_AXI_RDATA         ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI RID" *)
    input        [      (ID_WIDTH-1):0] M_AXI_RID           ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI RRESP" *)
    input        [                 1:0] M_AXI_RRESP         ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI RLAST" *)
    input                               M_AXI_RLAST         ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI RVALID" *)
    input                               M_AXI_RVALID        ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI RREADY" *)
    input                               M_AXI_RREADY        ,
    /*************************** ADDRESS WRITE CHANNEL **********************************/
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI AWID" *)
    input        [      (ID_WIDTH-1):0] M_AXI_AWID          ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI AWADDR" *)
    input        [    (ADDR_WIDTH-1):0] M_AXI_AWADDR        ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI AWLEN" *)
    input        [                 7:0] M_AXI_AWLEN         ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI AWSIZE" *)
    input        [                 2:0] M_AXI_AWSIZE        ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI AWBURST" *)
    input        [                 1:0] M_AXI_AWBURST       ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI AWPROT" *)
    input        [                 2:0] M_AXI_AWPROT        ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI AWVALID" *)
    input                               M_AXI_AWVALID       ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI AWLOCK" *)
    input                               M_AXI_AWLOCK        ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI AWCACHE" *)
    input        [                 3:0] M_AXI_AWCACHE       ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI AWREADY" *)
    input                               M_AXI_AWREADY       ,
    /*************************** DATA WRITE CHANNEL **********************************/
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI WDATA" *)
    input        [     (N_BYTES*8)-1:0] M_AXI_WDATA         ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI WSTRB" *)
    input        [       (N_BYTES-1):0] M_AXI_WSTRB         ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI WREADY" *)
    input                               M_AXI_WREADY        ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI WLAST" *)
    input                               M_AXI_WLAST         ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI WVALID" *)
    input                               M_AXI_WVALID        ,
    /*************************** RESPONSE CHANNEL **********************************/
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI BID" *)
    input        [      (ID_WIDTH-1):0] M_AXI_BID           ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI BRESP" *)
    input        [                 1:0] M_AXI_BRESP         ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI BREADY" *)
    input                               M_AXI_BREADY        ,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI BVALID" *)
    input                               M_AXI_BVALID        ,

    output logic [(COUNTER_WIDTH-1):0] read_packet_speed   ,
    output logic [(COUNTER_WIDTH-1):0] read_data_speed     ,
    output logic [(COUNTER_WIDTH-1):0] write_packet_speed  ,
    output logic [(COUNTER_WIDTH-1):0] write_data_speed     
);

    logic [31:0] timer_counter = '{default : 0};

    logic [(COUNTER_WIDTH-1):0] read_packet_speed_cnt    = '{default:0};
    logic [(COUNTER_WIDTH-1):0] read_data_speed_cnt      = '{default:0};
    logic [(COUNTER_WIDTH-1):0] write_packet_speed_cnt   = '{default:0};
    logic [(COUNTER_WIDTH-1):0] write_data_speed_cnt    = '{default:0};

    always_ff @(posedge M_AXI_ACLK) begin 
        if (~M_AXI_ARESETN) begin 
            timer_counter <= '{default:0};
        end else begin 
            if (timer_counter < (COUNTER_LIMIT-1)) begin 
                timer_counter <= timer_counter + 1;
            end else begin  
                timer_counter <= '{default:0};
            end 
        end 
    end 

    always_ff @(posedge M_AXI_ACLK) begin : read_packet_speed_cnt_proc 
        if (~M_AXI_ARESETN) begin 
            read_packet_speed_cnt <= '{default:0};
        end else begin 
            if (timer_counter < (COUNTER_LIMIT-1)) begin 
                if (M_AXI_RVALID & M_AXI_RREADY & M_AXI_RLAST) begin 
                    read_packet_speed_cnt <= read_packet_speed_cnt + 1;
                end else begin 
                    read_packet_speed_cnt <= read_packet_speed_cnt;
                end 
            end else begin 
                read_packet_speed_cnt <= '{default:0};
            end 
        end 
    end 

    always_ff @(posedge  M_AXI_ACLK) begin : read_packet_speed_proc 
        if (~M_AXI_ARESETN) begin 
            read_packet_speed <= '{default:0};
        end else begin 
            if (timer_counter < (COUNTER_LIMIT-1)) begin 
                read_packet_speed <= read_packet_speed;
            end else begin 
                if (M_AXI_RVALID & M_AXI_RREADY & M_AXI_RLAST) begin 
                    read_packet_speed <= read_packet_speed_cnt + 1;
                end else begin 
                    read_packet_speed <= read_packet_speed_cnt;
                end
            end  
        end 
    end 




    always_ff @(posedge M_AXI_ACLK) begin : read_data_speed_cnt_proc 
        if (~M_AXI_ARESETN) begin 
            read_data_speed_cnt <= '{default:0};
        end else begin 
            if (timer_counter < (COUNTER_LIMIT-1)) begin 
                if (M_AXI_RVALID & M_AXI_RREADY) begin 
                    read_data_speed_cnt <= read_data_speed_cnt + N_BYTES;
                end else begin 
                    read_data_speed_cnt <= read_data_speed_cnt;
                end 
            end else begin 
                read_data_speed_cnt <= '{default:0};
            end 
        end 
    end 

    always_ff @(posedge  M_AXI_ACLK) begin : read_data_speed_proc 
        if (~M_AXI_ARESETN) begin 
            read_data_speed <= '{default:0};
        end else begin 
            if (timer_counter < (COUNTER_LIMIT-1)) begin 
                read_data_speed <= read_data_speed;
            end else begin 
                if (M_AXI_RVALID & M_AXI_RREADY) begin 
                    read_data_speed <= read_data_speed_cnt + N_BYTES;
                end else begin 
                    read_data_speed <= read_data_speed_cnt;
                end
            end  
        end 
    end 



    always_ff @(posedge M_AXI_ACLK) begin : write_packet_speed_cnt_proc 
        if (~M_AXI_ARESETN) begin 
            write_packet_speed_cnt <= '{default:0};
        end else begin 
            if (timer_counter < (COUNTER_LIMIT-1)) begin 
                if (M_AXI_WVALID & M_AXI_WREADY & M_AXI_WLAST) begin 
                    write_packet_speed_cnt <= write_packet_speed_cnt + 1;
                end else begin 
                    write_packet_speed_cnt <= write_packet_speed_cnt;
                end 
            end else begin 
                write_packet_speed_cnt <= '{default:0};
            end 
        end 
    end 

    always_ff @(posedge  M_AXI_ACLK) begin : write_packet_speed_proc 
        if (~M_AXI_ARESETN) begin 
            write_packet_speed <= '{default:0};
        end else begin 
            if (timer_counter < (COUNTER_LIMIT-1)) begin 
                write_packet_speed <= write_packet_speed;
            end else begin 
                if (M_AXI_WVALID & M_AXI_WREADY & M_AXI_WLAST) begin 
                    write_packet_speed <= write_packet_speed + 1;
                end else begin 
                    write_packet_speed <= write_packet_speed;
                end
            end  
        end 
    end 



    always_ff @(posedge M_AXI_ACLK) begin : write_data_speed_cnt_proc 
        if (~M_AXI_ARESETN) begin 
            write_data_speed_cnt <= '{default:0};
        end else begin 
            if (timer_counter < (COUNTER_LIMIT-1)) begin 
                if (M_AXI_WVALID & M_AXI_WREADY) begin 
                    write_data_speed_cnt <= write_data_speed_cnt + N_BYTES;
                end else begin 
                    write_data_speed_cnt <= write_data_speed_cnt;
                end 
            end else begin 
                write_data_speed_cnt <= '{default:0};
            end 
        end 
    end 

    always_ff @(posedge  M_AXI_ACLK) begin : write_data_speed_proc 
        if (~M_AXI_ARESETN) begin 
            write_data_speed <= '{default:0};
        end else begin 
            if (timer_counter < (COUNTER_LIMIT-1)) begin 
                write_data_speed <= write_data_speed;
            end else begin 
                if (M_AXI_WVALID & M_AXI_WREADY) begin 
                    write_data_speed <= write_data_speed + N_BYTES;
                end else begin 
                    write_data_speed <= write_data_speed;
                end
            end  
        end 
    end 





endmodule
