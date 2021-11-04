library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use ieee.std_logic_unsigned.all;
    use ieee.std_logic_arith.all;

entity tb_axis_iic_bridge is 
end tb_axis_iic_bridge;



architecture tb_axis_iic_bridge_arch of tb_axis_iic_bridge is 

    constant N_BYTES        :           integer     := 4                                    ;
    constant CLK_PERIOD     :           integer     := 100000000                            ;
    constant CLK_I2C_PERIOD :           integer     := 100000000                            ;


    component axis_iic_bridge 
        generic (
            CLK_PERIOD      :           integer     := 100000000                            ;
            CLK_I2C_PERIOD  :           integer     := 25000000                             ;
            N_BYTES         :           integer     := 32                                   
        ); 
        port (
            CLK             :   in      std_Logic                                           ;
            resetn          :   in      std_Logic                                           ;
            s_axis_tdata    :   in      std_logic_Vector ( ((N_BYTES*8)-1) downto 0 )       ;
            s_axis_tkeep    :   in      std_logic_Vector (       N_BYTES-1 downto 0 )       ;
            s_axis_tvalid   :   in      std_Logic                                           ;
            s_axis_tready   :   out     std_Logic                                           ;
            s_axis_tlast    :   in      std_Logic                                           ;
            m_axis_tdata    :   out     std_logic_Vector ( ((N_BYTES*8)-1) downto 0 )       ;
            m_axis_tkeep    :   out     std_logic_Vector (       N_BYTES-1 downto 0 )       ;
            m_axis_tvalid   :   out     std_Logic                                           ;
            m_axis_tready   :   in      std_Logic                                           ;
            m_axis_tlast    :   out     std_Logic                                           ;
            scl_i           :   in      std_Logic                                           ;
            sda_i           :   in      std_Logic                                           ;
            scl_t           :   out     std_Logic                                           ;
            sda_t           :   out     std_Logic                                            
        );
    end component;


    signal  CLK             :           std_Logic                                     := '0'                ;
    signal  reset           :           std_Logic                                     := '0'                ;
    signal  s_axis_tdata    :           std_logic_Vector ( ((N_BYTES*8)-1) downto 0 ) := (others => '0')    ;
    signal  s_axis_tkeep    :           std_logic_Vector (       N_BYTES-1 downto 0 ) := (others => '0')    ;
    signal  s_axis_tvalid   :           std_Logic                                     := '0'                ;
    signal  s_axis_tready   :           std_Logic                                                           ;
    signal  s_axis_tlast    :           std_Logic                                                           ;
    signal  m_axis_tdata    :           std_logic_Vector ( ((N_BYTES*8)-1) downto 0 )                       ;
    signal  m_axis_tkeep    :           std_logic_Vector (       N_BYTES-1 downto 0 )                       ;
    signal  m_axis_tvalid   :           std_Logic                                                           ;
    signal  m_axis_tready   :           std_Logic                                     := '0'                ;
    signal  m_axis_tlast    :           std_Logic                                                           ;
    signal  scl_i           :           std_Logic                                     := '0'                ;
    signal  sda_i           :           std_Logic                                     := '0'                ;
    signal  scl_t           :           std_Logic                                                           ;
    signal  sda_t           :           std_Logic                                                           ;

    constant clock_period   :           time                                          := 10 ns              ;

    signal i                :           integer                                       := 0                  ;

begin 

    CLK <= not CLK after clock_period/2;

    i_processing : process(CLK)
    begin
        if CLK'event AND CLK = '1' then 
            i <= i + 1;
        end if;
    end process;

    reset <= '1' when i < 5 else '0';

    axis_iic_bridge_inst : axis_iic_bridge 
        generic map (
            CLK_PERIOD      =>  CLK_PERIOD                      ,
            CLK_I2C_PERIOD  =>  CLK_I2C_PERIOD                  ,
            N_BYTES         =>  N_BYTES                          
        )
        port map  (
            CLK             =>  CLK                             ,
            resetn          =>  not(reset)                      ,
            s_axis_tdata    =>  s_axis_tdata                    ,
            s_axis_tkeep    =>  s_axis_tkeep                    ,
            s_axis_tvalid   =>  s_axis_tvalid                   ,
            s_axis_tready   =>  s_axis_tready                   ,
            s_axis_tlast    =>  s_axis_tlast                    ,
            m_axis_tdata    =>  m_axis_tdata                    ,
            m_axis_tkeep    =>  m_axis_tkeep                    ,
            m_axis_tvalid   =>  m_axis_tvalid                   ,
            m_axis_tready   =>  m_axis_tready                   ,
            m_axis_tlast    =>  m_axis_tlast                    ,
            scl_i           =>  scl_i                           ,
            sda_i           =>  sda_i                           ,
            scl_t           =>  scl_t                           ,
            sda_t           =>  sda_t                            
        );


end architecture;