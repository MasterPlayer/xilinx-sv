library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;

library UNISIM;
    use UNISIM.VComponents.all;



entity axi_mm_perf_counter_vhd is
    generic (
        COUNTER_WIDTH           : integer := 32                                             ;
        COUNTER_LIMIT           : integer := 250000000                                      ;
        N_BYTES                 : integer := 32                                             ;
        ADDR_WIDTH              : integer := 32                                             ;
        ID_WIDTH                : integer := 4                                              
    );
    port(
        M_AXI_ACLK              :   in      std_logic                                      ;
        M_AXI_ARESETN           :   in      std_logic                                      ;
        -- ADDRESS READ CHANNEL
        M_AXI_ARID              :   in      std_logic_vector (      (ID_WIDTH-1) downto 0 );
        M_AXI_ARADDR            :   in      std_logic_vector (    (ADDR_WIDTH-1) downto 0 );
        M_AXI_ARLEN             :   in      std_logic_vector (                 7 downto 0 );
        M_AXI_ARSIZE            :   in      std_logic_vector (                 2 downto 0 );
        M_AXI_ARBURST           :   in      std_logic_vector (                 1 downto 0 );
        M_AXI_ARPROT            :   in      std_logic_vector (                 2 downto 0 );
        M_AXI_ARVALID           :   in      std_logic                                      ;
        M_AXI_ARLOCK            :   in      std_logic                                      ;
        M_AXI_ARCACHE           :   in      std_logic_vector (                 3 downto 0 );
        M_AXI_ARREADY           :   in      std_logic                                      ;
        -- DATA READ CHANNEL 
        M_AXI_RDATA             :   in      std_logic_vector (     (N_BYTES*8)-1 downto 0 );
        M_AXI_RID               :   in      std_logic_vector (      (ID_WIDTH-1) downto 0 );
        M_AXI_RRESP             :   in      std_logic_vector (                 1 downto 0 );
        M_AXI_RLAST             :   in      std_logic                                      ;
        M_AXI_RVALID            :   in      std_logic                                      ;
        M_AXI_RREADY            :   in      std_logic                                      ;
        -- ADDRESS WRITE CHANNEL 
        M_AXI_AWADDR            :   in      std_logic_vector (    (ADDR_WIDTH-1) downto 0 );
        M_AXI_AWLEN             :   in      std_logic_vector (                 7 downto 0 );
        M_AXI_AWSIZE            :   in      std_logic_vector (                 2 downto 0 );
        M_AXI_AWBURST           :   in      std_logic_vector (                 1 downto 0 );
        M_AXI_AWPROT            :   in      std_logic_vector (                 2 downto 0 );
        M_AXI_AWVALID           :   in      std_logic                                      ;
        M_AXI_AWLOCK            :   in      std_logic                                      ;
        M_AXI_AWCACHE           :   in      std_logic_vector (                 3 downto 0 );
        M_AXI_AWREADY           :   in      std_logic                                      ;
        -- DATA WRITE CHANNEL 
        M_AXI_WDATA             :   in      std_logic_vector (     (N_BYTES*8)-1 downto 0 );
        M_AXI_WSTRB             :   in      std_logic_vector (       (N_BYTES-1) downto 0 );
        M_AXI_WREADY            :   in      std_logic                                      ;
        M_AXI_WLAST             :   in      std_logic                                      ;
        M_AXI_WVALID            :   in      std_logic                                      ;
        -- RESPONSE CHANNEL 
        M_AXI_BID               :   in      std_logic_vector (      (ID_WIDTH-1) downto 0 );
        M_AXI_BRESP             :   in      std_logic_vector (                 1 downto 0 );
        M_AXI_BREADY            :   in      std_logic                                      ;
        M_AXI_BVALID            :   in      std_logic                                      ;

        read_packet_speed       :   out     std_logic_vector ( (COUNTER_WIDTH-1) downto 0 );
        read_data_speed         :   out     std_logic_vector ( (COUNTER_WIDTH-1) downto 0 );
        write_packet_speed      :   out     std_logic_vector ( (COUNTER_WIDTH-1) downto 0 );
        write_data_speed        :   out     std_logic_vector ( (COUNTER_WIDTH-1) downto 0 )
    );
end axi_mm_perf_counter_vhd;



architecture axi_mm_perf_counter_vhd_arch of axi_mm_perf_counter_vhd is

    --ATTRIBUTE X_INTERFACE_INFO : STRING;
    --ATTRIBUTE X_INTERFACE_INFO of S_AXI_AWADDR  : SIGNAL is "xilinx.com:interface:aximm:1.0 S_AXI AWADDR";
    --ATTRIBUTE X_INTERFACE_INFO of S_AXI_AWLEN   : SIGNAL is "xilinx.com:interface:aximm:1.0 S_AXI AWLEN";
    --ATTRIBUTE X_INTERFACE_INFO of S_AXI_AWSIZE  : SIGNAL is "xilinx.com:interface:aximm:1.0 S_AXI AWSIZE";
    --ATTRIBUTE X_INTERFACE_INFO of S_AXI_AWBURST : SIGNAL is "xilinx.com:interface:aximm:1.0 S_AXI AWBURST";
    --ATTRIBUTE X_INTERFACE_INFO of S_AXI_AWLOCK  : SIGNAL is "xilinx.com:interface:aximm:1.0 S_AXI AWLOCK";
    --ATTRIBUTE X_INTERFACE_INFO of S_AXI_AWCACHE : SIGNAL is "xilinx.com:interface:aximm:1.0 S_AXI AWCACHE";
    --ATTRIBUTE X_INTERFACE_INFO of S_AXI_AWPROT  : SIGNAL is "xilinx.com:interface:aximm:1.0 S_AXI AWPROT";
    --ATTRIBUTE X_INTERFACE_INFO of S_AXI_AWVALID : SIGNAL is "xilinx.com:interface:aximm:1.0 S_AXI AWVALID";
    --ATTRIBUTE X_INTERFACE_INFO of S_AXI_AWREADY : SIGNAL is "xilinx.com:interface:aximm:1.0 S_AXI AWREADY";
    --ATTRIBUTE X_INTERFACE_INFO of S_AXI_WDATA   : SIGNAL is "xilinx.com:interface:aximm:1.0 S_AXI WDATA";
    --ATTRIBUTE X_INTERFACE_INFO of S_AXI_WSTRB   : SIGNAL is "xilinx.com:interface:aximm:1.0 S_AXI WSTRB";
    --ATTRIBUTE X_INTERFACE_INFO of S_AXI_WLAST   : SIGNAL is "xilinx.com:interface:aximm:1.0 S_AXI WLAST";
    --ATTRIBUTE X_INTERFACE_INFO of S_AXI_WVALID  : SIGNAL is "xilinx.com:interface:aximm:1.0 S_AXI WVALID";
    --ATTRIBUTE X_INTERFACE_INFO of S_AXI_WREADY  : SIGNAL is "xilinx.com:interface:aximm:1.0 S_AXI WREADY";
    --ATTRIBUTE X_INTERFACE_INFO of S_AXI_BID     : SIGNAL is "xilinx.com:interface:aximm:1.0 S_AXI BID";
    --ATTRIBUTE X_INTERFACE_INFO of S_AXI_BRESP   : SIGNAL is "xilinx.com:interface:aximm:1.0 S_AXI BRESP";
    --ATTRIBUTE X_INTERFACE_INFO of S_AXI_BVALID  : SIGNAL is "xilinx.com:interface:aximm:1.0 S_AXI BVALID";
    --ATTRIBUTE X_INTERFACE_INFO of S_AXI_BREADY  : SIGNAL is "xilinx.com:interface:aximm:1.0 S_AXI BREADY";
    --ATTRIBUTE X_INTERFACE_INFO of S_AXI_ARID    : SIGNAL is "xilinx.com:interface:aximm:1.0 S_AXI ARID";
    --ATTRIBUTE X_INTERFACE_INFO of S_AXI_ARADDR  : SIGNAL is "xilinx.com:interface:aximm:1.0 S_AXI ARADDR";
    --ATTRIBUTE X_INTERFACE_INFO of S_AXI_ARLEN   : SIGNAL is "xilinx.com:interface:aximm:1.0 S_AXI ARLEN";
    --ATTRIBUTE X_INTERFACE_INFO of S_AXI_ARSIZE  : SIGNAL is "xilinx.com:interface:aximm:1.0 S_AXI ARSIZE";
    --ATTRIBUTE X_INTERFACE_INFO of S_AXI_ARBURST : SIGNAL is "xilinx.com:interface:aximm:1.0 S_AXI ARBURST";
    --ATTRIBUTE X_INTERFACE_INFO of S_AXI_ARLOCK  : SIGNAL is "xilinx.com:interface:aximm:1.0 S_AXI ARLOCK";
    --ATTRIBUTE X_INTERFACE_INFO of S_AXI_ARCACHE : SIGNAL is "xilinx.com:interface:aximm:1.0 S_AXI ARCACHE";
    --ATTRIBUTE X_INTERFACE_INFO of S_AXI_ARPROT  : SIGNAL is "xilinx.com:interface:aximm:1.0 S_AXI ARPROT";
    --ATTRIBUTE X_INTERFACE_INFO of S_AXI_ARVALID : SIGNAL is "xilinx.com:interface:aximm:1.0 S_AXI ARVALID";
    --ATTRIBUTE X_INTERFACE_INFO of S_AXI_ARREADY : SIGNAL is "xilinx.com:interface:aximm:1.0 S_AXI ARREADY";
    --ATTRIBUTE X_INTERFACE_INFO of S_AXI_RID     : SIGNAL is "xilinx.com:interface:aximm:1.0 S_AXI RID";
    --ATTRIBUTE X_INTERFACE_INFO of S_AXI_RDATA   : SIGNAL is "xilinx.com:interface:aximm:1.0 S_AXI RDATA";
    --ATTRIBUTE X_INTERFACE_INFO of S_AXI_RRESP   : SIGNAL is "xilinx.com:interface:aximm:1.0 S_AXI RRESP";
    --ATTRIBUTE X_INTERFACE_INFO of S_AXI_RLAST   : SIGNAL is "xilinx.com:interface:aximm:1.0 S_AXI RLAST";
    --ATTRIBUTE X_INTERFACE_INFO of S_AXI_RVALID  : SIGNAL is "xilinx.com:interface:aximm:1.0 S_AXI RVALID";
    --ATTRIBUTE X_INTERFACE_INFO of S_AXI_RREADY  : SIGNAL is "xilinx.com:interface:aximm:1.0 S_AXI RREADY";


    component axi_mm_perf_counter
        generic (
            COUNTER_WIDTH           :           integer := 32                                   ;
            COUNTER_LIMIT           :           integer := 250000000                            ;
            N_BYTES                 :           integer := 32                                   ;
            ADDR_WIDTH              :           integer := 32                                   ;
            ID_WIDTH                :           integer := 4                                    
        );
        port (
            M_AXI_ACLK              :   in      std_logic                                      ;
            M_AXI_ARESETN           :   in      std_logic                                      ;
            -- ADDRESS READ CHANNEL
            M_AXI_ARID              :   in      std_logic_vector (      (ID_WIDTH-1) downto 0 );
            M_AXI_ARADDR            :   in      std_logic_vector (    (ADDR_WIDTH-1) downto 0 );
            M_AXI_ARLEN             :   in      std_logic_vector (                 7 downto 0 );
            M_AXI_ARSIZE            :   in      std_logic_vector (                 2 downto 0 );
            M_AXI_ARBURST           :   in      std_logic_vector (                 1 downto 0 );
            M_AXI_ARPROT            :   in      std_logic_vector (                 2 downto 0 );
            M_AXI_ARVALID           :   in      std_logic                                      ;
            M_AXI_ARLOCK            :   in      std_logic                                      ;
            M_AXI_ARCACHE           :   in      std_logic_vector (                 3 downto 0 );
            M_AXI_ARREADY           :   in      std_logic                                      ;
            -- DATA READ CHANNEL 
            M_AXI_RDATA             :   in      std_logic_vector (     (N_BYTES*8)-1 downto 0 );
            M_AXI_RID               :   in      std_logic_vector (      (ID_WIDTH-1) downto 0 );
            M_AXI_RRESP             :   in      std_logic_vector (                 1 downto 0 );
            M_AXI_RLAST             :   in      std_logic                                      ;
            M_AXI_RVALID            :   in      std_logic                                      ;
            M_AXI_RREADY            :   in      std_logic                                      ;
            -- ADDRESS WRITE CHANNEL 
            M_AXI_AWADDR            :   in      std_logic_vector (    (ADDR_WIDTH-1) downto 0 );
            M_AXI_AWLEN             :   in      std_logic_vector (                 7 downto 0 );
            M_AXI_AWSIZE            :   in      std_logic_vector (                 2 downto 0 );
            M_AXI_AWBURST           :   in      std_logic_vector (                 1 downto 0 );
            M_AXI_AWPROT            :   in      std_logic_vector (                 2 downto 0 );
            M_AXI_AWVALID           :   in      std_logic                                      ;
            M_AXI_AWLOCK            :   in      std_logic                                      ;
            M_AXI_AWCACHE           :   in      std_logic_vector (                 3 downto 0 );
            M_AXI_AWREADY           :   in      std_logic                                      ;
            -- DATA WRITE CHANNEL 
            M_AXI_WDATA             :   in      std_logic_vector (     (N_BYTES*8)-1 downto 0 );
            M_AXI_WSTRB             :   in      std_logic_vector (       (N_BYTES-1) downto 0 );
            M_AXI_WREADY            :   in      std_logic                                      ;
            M_AXI_WLAST             :   in      std_logic                                      ;
            M_AXI_WVALID            :   in      std_logic                                      ;
            -- RESPONSE CHANNEL 
            M_AXI_BID               :   in      std_logic_vector (      (ID_WIDTH-1) downto 0 );
            M_AXI_BRESP             :   in      std_logic_vector (                 1 downto 0 );
            M_AXI_BREADY            :   in      std_logic                                      ;
            M_AXI_BVALID            :   in      std_logic                                      ;

            read_packet_speed       :   out     std_logic_vector ( (COUNTER_WIDTH-1) downto 0 );
            read_data_speed         :   out     std_logic_vector ( (COUNTER_WIDTH-1) downto 0 );
            write_packet_speed      :   out     std_logic_vector ( (COUNTER_WIDTH-1) downto 0 );
            write_data_speed        :   out     std_logic_vector ( (COUNTER_WIDTH-1) downto 0 )
        );
    end component;


begin


    axi_mm_perf_counter_inst : axi_mm_perf_counter
        generic map (
            COUNTER_WIDTH           =>  COUNTER_WIDTH                   ,
            COUNTER_LIMIT           =>  COUNTER_LIMIT                   ,
            N_BYTES                 =>  N_BYTES                         ,
            ADDR_WIDTH              =>  ADDR_WIDTH                      ,
            ID_WIDTH                =>  ID_WIDTH                         
        )
        port map (
            M_AXI_ACLK              =>  M_AXI_ACLK                      ,
            M_AXI_ARESETN           =>  M_AXI_ARESETN                   ,
            -- ADDRESS READ CHANNEL
            M_AXI_ARID              =>  M_AXI_ARID                      ,
            M_AXI_ARADDR            =>  M_AXI_ARADDR                    ,
            M_AXI_ARLEN             =>  M_AXI_ARLEN                     ,
            M_AXI_ARSIZE            =>  M_AXI_ARSIZE                    ,
            M_AXI_ARBURST           =>  M_AXI_ARBURST                   ,
            M_AXI_ARPROT            =>  M_AXI_ARPROT                    ,
            M_AXI_ARVALID           =>  M_AXI_ARVALID                   ,
            M_AXI_ARLOCK            =>  M_AXI_ARLOCK                    ,
            M_AXI_ARCACHE           =>  M_AXI_ARCACHE                   ,
            M_AXI_ARREADY           =>  M_AXI_ARREADY                   ,
            -- DATA READ CHANNEL 
            M_AXI_RDATA             =>  M_AXI_RDATA                     ,
            M_AXI_RID               =>  M_AXI_RID                       ,
            M_AXI_RRESP             =>  M_AXI_RRESP                     ,
            M_AXI_RLAST             =>  M_AXI_RLAST                     ,
            M_AXI_RVALID            =>  M_AXI_RVALID                    ,
            M_AXI_RREADY            =>  M_AXI_RREADY                    ,
            -- ADDRESS WRITE CHANNEL 
            M_AXI_AWADDR            =>  M_AXI_AWADDR                    ,
            M_AXI_AWLEN             =>  M_AXI_AWLEN                     ,
            M_AXI_AWSIZE            =>  M_AXI_AWSIZE                    ,
            M_AXI_AWBURST           =>  M_AXI_AWBURST                   ,
            M_AXI_AWPROT            =>  M_AXI_AWPROT                    ,
            M_AXI_AWVALID           =>  M_AXI_AWVALID                   ,
            M_AXI_AWLOCK            =>  M_AXI_AWLOCK                    ,
            M_AXI_AWCACHE           =>  M_AXI_AWCACHE                   ,
            M_AXI_AWREADY           =>  M_AXI_AWREADY                   ,
            -- DATA WRITE CHANNEL 
            M_AXI_WDATA             =>  M_AXI_WDATA                     ,
            M_AXI_WSTRB             =>  M_AXI_WSTRB                     ,
            M_AXI_WREADY            =>  M_AXI_WREADY                    ,
            M_AXI_WLAST             =>  M_AXI_WLAST                     ,
            M_AXI_WVALID            =>  M_AXI_WVALID                    ,
            -- RESPONSE CHANNEL 
            M_AXI_BID               =>  M_AXI_BID                       ,
            M_AXI_BRESP             =>  M_AXI_BRESP                     ,
            M_AXI_BREADY            =>  M_AXI_BREADY                    ,
            M_AXI_BVALID            =>  M_AXI_BVALID                    ,

            read_packet_speed       =>  read_packet_speed               ,
            read_data_speed         =>  read_data_speed                 ,
            write_packet_speed      =>  write_packet_speed              ,
            write_data_speed        =>  write_data_speed            
        );  



end axi_mm_perf_counter_vhd_arch;
