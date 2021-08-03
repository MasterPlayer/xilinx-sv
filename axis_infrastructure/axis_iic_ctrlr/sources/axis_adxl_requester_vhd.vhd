
library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use ieee.std_logic_unsigned.all;
    use ieee.std_logic_arith.all;

library UNISIM;
    use UNISIM.VComponents.all;

entity axis_adxl_requester_vhd is
    port (
        CLK             :   in      std_logic                           ;
        RESETN          :   in      std_logic                           ;
        REQUEST_ACCEL   :   in      std_logic                           ;
        X_POS           :   out     std_logic_vector ( 15 downto 0 )    ;
        Y_POS           :   out     std_logic_vector ( 15 downto 0 )    ;
        Z_POS           :   out     std_logic_vector ( 15 downto 0 )    ;
        S_AXIS_TDATA    :   in      std_logic_vector ( 31 downto 0 )    ;
        S_AXIS_TDEST    :   in      std_logic_vector (  7 downto 0 )    ;
        S_AXIS_TVALID   :   in      std_logic                           ;
        S_AXIS_TLAST    :   in      std_logic                           ;
        M_AXIS_TDATA    :   out     std_logic_vector ( 31 downto 0 )    ;
        M_AXIS_TKEEP    :   out     std_logic_vector (  3 downto 0 )    ;
        M_AXIS_TDEST    :   out     std_logic_vector (  7 downto 0 )    ;
        M_AXIS_TVALID   :   out     std_logic                           ;
        M_AXIS_TREADY   :   in      std_logic                           ;
        M_AXIS_TLAST    :   out     std_logic                           
    );
end axis_adxl_requester_vhd;



architecture axis_adxl_requester_vhd_arch of axis_adxl_requester_vhd is

    component axis_adxl_requester
        port(
            clk             :   in      std_logic                           ;
            resetn          :   in      std_logic                           ;
            request_accel   :   in      std_logic                           ;
            x_pos           :   out     std_logic_vector ( 15 downto 0 )    ;
            y_pos           :   out     std_logic_vector ( 15 downto 0 )    ;
            z_pos           :   out     std_logic_vector ( 15 downto 0 )    ;
            s_axis_tdata    :   in      std_logic_vector ( 31 downto 0 )    ;
            s_axis_tdest    :   in      std_logic_vector (  7 downto 0 )    ;
            s_axis_tvalid   :   in      std_logic                           ;
            s_axis_tlast    :   in      std_logic                           ;
            m_axis_tdata    :   out     std_logic_vector ( 31 downto 0 )    ;
            m_axis_tkeep    :   out     std_logic_vector (  3 downto 0 )    ;
            m_axis_tdest    :   out     std_logic_vector (  7 downto 0 )    ;
            m_axis_tvalid   :   out     std_logic                           ;
            m_axis_tready   :   in      std_logic                           ;
            m_axis_tlast    :   out     std_logic                           
        );
    end component;

begin

    axis_adxl_requester_inst : axis_adxl_requester
        port map (
            clk             =>  CLK                 ,
            resetn          =>  RESETN              ,
            request_accel   =>  REQUEST_ACCEL       ,
            x_pos           =>  X_POS               ,
            y_pos           =>  Y_POS               ,
            z_pos           =>  Z_POS               ,
            s_axis_tdata    =>  S_AXIS_TDATA        ,
            s_axis_tdest    =>  S_AXIS_TDEST        ,
            s_axis_tvalid   =>  S_AXIS_TVALID       ,
            s_axis_tlast    =>  S_AXIS_TLAST        ,
            m_axis_tdata    =>  M_AXIS_TDATA        ,
            m_axis_tkeep    =>  M_AXIS_TKEEP        ,
            m_axis_tdest    =>  M_AXIS_TDEST        ,
            m_axis_tvalid   =>  M_AXIS_TVALID       ,
            m_axis_tready   =>  M_AXIS_TREADY       ,
            m_axis_tlast    =>  M_AXIS_TLAST         
        );

end axis_adxl_requester_vhd_arch;



