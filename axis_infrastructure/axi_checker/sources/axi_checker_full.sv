`timescale 1 ns / 1 ps

module axi_checker_full #(
    parameter integer AXI_ID_WIDTH   = 1 ,
    parameter integer AXI_DATA_WIDTH = 32,
    parameter integer AXI_ADDR_WIDTH = 6
) (
    input                                 S_AXI_ACLK    ,
    input                                 S_AXI_ARESETN ,
    input        [  C_S_AXI_ID_WIDTH-1:0] S_AXI_AWID    ,
    input        [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_AWADDR  ,
    input        [                   7:0] S_AXI_AWLEN   ,
    input        [                   2:0] S_AXI_AWSIZE  ,
    input        [                   1:0] S_AXI_AWBURST ,
    input                                 S_AXI_AWLOCK  ,
    input        [                   3:0] S_AXI_AWCACHE ,
    input        [                   2:0] S_AXI_AWPROT  ,
    input        [                   3:0] S_AXI_AWQOS   ,
    input        [                   3:0] S_AXI_AWREGION,
    input                                 S_AXI_AWVALID ,
    output logic                          S_AXI_AWREADY ,
    input        [    AXI_DATA_WIDTH-1:0] S_AXI_WDATA   ,
    input        [(AXI_DATA_WIDTH/8)-1:0] S_AXI_WSTRB   ,
    input                                 S_AXI_WLAST   ,
    input                                 S_AXI_WVALID  ,
    output logic                          S_AXI_WREADY  ,
    output logic [  C_S_AXI_ID_WIDTH-1:0] S_AXI_BID     ,
    output logic [                   1:0] S_AXI_BRESP   ,
    output logic                          S_AXI_BVALID  ,
    input                                 S_AXI_BREADY
);


    logic axi_full_awready     ;
    logic axi_full_wready      ;
    logic axi_full_bvalid      ;
    logic axi_full_awv_awr_flag;

    always_comb begin
        S_AXI_AWREADY = axi_full_awready;
        S_AXI_WREADY  = axi_full_wready;
        S_AXI_BRESP   = 'b0;
        S_AXI_BVALID  = axi_full_bvalid;
        S_AXI_BID     = S_AXI_AWID;
    end 

    always_ff @(posedge S_AXI_ACLK) begin : awready_processing  
        if (~S_AXI_ARESETN) begin 
            axi_full_awready <= 1'b0;
        end else begin 
            if (axi_full_awready && S_AXI_AWVALID & ~axi_full_awv_awr_flag && ~axi_arv_arr_flag) begin 
                axi_full_awready <= 1'b1;
            end else begin                 
                axi_full_awready <= 1'b0;
            end 
        end 
    end 

    always_ff @(posedge S_AXI_ACLK) begin : axi_full_awv_awr_flag_processing 
        if (~S_AXI_ARESETN) begin 
            axi_full_awv_awr_flag <= 1'b0;
        end else begin 
            if (axi_full_awready && S_AXI_AWVALID & ~axi_full_awv_awr_flag && ~axi_arv_arr_flag) begin 
                axi_full_awv_awr_flag <= 1'b1;
            end else begin 
                if (S_AXI_WLAST & axi_full_wready) begin 
                    axi_full_awv_awr_flag <= 1'b0;
                end 
            end 
        end
    end 

    always_ff @( posedge S_AXI_ACLK ) begin : wready_processing
        if ( ~S_AXI_ARESETN ) begin
            axi_full_wready <= 1'b0;
        end else begin
            if ( ~axi_full_wready && S_AXI_WVALID && axi_full_awv_awr_flag) begin
                axi_full_wready <= 1'b1;
            end else begin 
                if (S_AXI_WLAST && axi_full_wready) begin
                    axi_full_wready <= 1'b0;
                end
            end 
        end
    end

    always @( posedge S_AXI_ACLK ) begin
        if ( S_AXI_ARESETN == 1'b0 ) begin
            axi_full_bvalid <= 0;
        end else begin
            if (axi_full_awv_awr_flag && axi_full_wready && S_AXI_WVALID && ~axi_full_bvalid && S_AXI_WLAST ) begin
                axi_full_bvalid <= 1'b1;
            end else begin
                if (S_AXI_BREADY && axi_full_bvalid) begin
                    axi_full_bvalid <= 1'b0;
                end
            end
        end
    end   



    endmodule
