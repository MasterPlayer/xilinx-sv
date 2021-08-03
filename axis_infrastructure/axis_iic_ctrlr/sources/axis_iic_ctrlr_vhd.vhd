
library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use ieee.std_logic_unsigned.all;
    use ieee.std_logic_arith.all;

library UNISIM;
    use UNISIM.VComponents.all;

entity axis_iic_ctrlr_vhd is
    generic (
        CLK_PERIOD     : integer := 100000000 ;
        CLK_I2C_PERIOD : integer := 400000    ;
        N_BYTES        : integer := 32        ;
        DEPTH          : integer := 16                 
    );
    port (
        CLK             :   in      std_logic                                       ;
        RESETN          :   in      std_logic                                       ;
        S_AXIS_TDATA    :   in      std_logic_vector (((N_BYTES*8)-1) downto 0 )    ;
        S_AXIS_TKEEP    :   in      std_logic_vector (      N_BYTES-1 downto 0 )    ;
        S_AXIS_TDEST    :   in      std_logic_vector (              7 downto 0 )    ;
        S_AXIS_TVALID   :   in      std_logic                                       ;
        S_AXIS_TREADY   :   out     std_logic                                       ;
        S_AXIS_TLAST    :   in      std_logic                                       ;
        M_AXIS_TDATA    :   out     std_logic_Vector ( ((N_BYTES*8)-1) downto 0 )   ;
        M_AXIS_TKEEP    :   out     std_logic_Vector (       N_BYTES-1 downto 0 )   ;
        M_AXIS_TDEST    :   out     std_logic_Vector (               7 downto 0 )   ;
        M_AXIS_TVALID   :   out     std_logic                                       ;
        M_AXIS_TREADY   :   in      std_logic                                       ;
        M_AXIS_TLAST    :   out     std_logic                                       ;
        SCL_I           :   in      std_logic                                       ;
        SDA_I           :   in      std_logic                                       ;
        SCL_T           :   out     std_logic                                       ;
        SDA_T           :   out     std_logic                                        
    );
    --attribute DONT_TOUCH                    :           string                                                  ;
    --attribute DONT_TOUCH of axis_iic_mgr_vhd      :   entity is "true";
end axis_iic_ctrlr_vhd;



architecture axis_iic_ctrlr_vhd_arch of axis_iic_ctrlr_vhd is

    component axis_iic_ctrlr
        generic (
            CLK_PERIOD     : integer := 100000000 ;
            CLK_I2C_PERIOD : integer := 400000    ;
            N_BYTES        : integer := 32        ;
            DEPTH          : integer := 16                 
        );
        port (
            clk             :   in      std_logic                                       ;
            resetn          :   in      std_logic                                       ;
            s_axis_tdata    :   in      std_logic_vector (((N_BYTES*8)-1) downto 0 )    ;
            s_axis_tkeep    :   in      std_logic_vector (      N_BYTES-1 downto 0 )    ;
            s_axis_tdest    :   in      std_logic_vector (              7 downto 0 )    ;
            s_axis_tvalid   :   in      std_logic                                       ;
            s_axis_tready   :   out     std_logic                                       ;
            s_axis_tlast    :   in      std_logic                                       ;
            m_axis_tdata    :   out     std_logic_Vector ( ((N_BYTES*8)-1) downto 0 )   ;
            m_axis_tkeep    :   out     std_logic_Vector (       N_BYTES-1 downto 0 )   ;
            m_axis_tdest    :   out     std_logic_Vector (               7 downto 0 )   ;
            m_axis_tvalid   :   out     std_logic                                       ;
            m_axis_tready   :   in      std_logic                                       ;
            m_axis_tlast    :   out     std_logic                                       ;
            scl_i           :   in      std_logic                                       ;
            sda_i           :   in      std_logic                                       ;
            scl_t           :   out     std_logic                                       ;
            sda_t           :   out     std_logic                                        
        );
    end component;

begin

    axis_iic_ctrlr_inst : axis_iic_ctrlr
        generic map (
            CLK_PERIOD          =>  CLK_PERIOD          ,
            CLK_I2C_PERIOD      =>  CLK_I2C_PERIOD      ,
            N_BYTES             =>  N_BYTES             ,
            DEPTH               =>  DEPTH                
        )
        port map (
            clk                 =>  CLK             ,
            resetn              =>  RESETN          ,
            s_axis_tdata        =>  S_AXIS_TDATA    ,
            s_axis_tkeep        =>  S_AXIS_TKEEP    ,
            s_axis_tdest        =>  S_AXIS_TDEST    ,
            s_axis_tvalid       =>  S_AXIS_TVALID   ,
            s_axis_tready       =>  S_AXIS_TREADY   ,
            s_axis_tlast        =>  S_AXIS_TLAST    ,
            m_axis_tdata        =>  M_AXIS_TDATA    ,
            m_axis_tkeep        =>  M_AXIS_TKEEP    ,
            m_axis_tdest        =>  M_AXIS_TDEST    ,
            m_axis_tvalid       =>  M_AXIS_TVALID   ,
            m_axis_tready       =>  M_AXIS_TREADY   ,
            m_axis_tlast        =>  M_AXIS_TLAST    ,
            scl_i               =>  SCL_I           ,
            sda_i               =>  SDA_I           ,
            scl_t               =>  SCL_T           ,
            sda_t               =>  SDA_T            
        );

end axis_iic_ctrlr_vhd_arch;



