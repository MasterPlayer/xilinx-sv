library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use ieee.std_logic_unsigned.all;
    use ieee.std_logic_arith.all;

entity tb_axis_iic_bridge is 
end tb_axis_iic_bridge;



architecture tb_axis_iic_bridge_arch of tb_axis_iic_bridge is 

    constant N_BYTES            :           integer     := 4                                    ;
    constant CLK_PERIOD         :           integer     := 100000000                            ;
    constant CLK_I2C_PERIOD     :           integer     := 400000                               ; -- 4
    constant CLK_I2C_PERIOD_4   :           integer     := CLK_PERIOD/4                         ; -- 4
    constant CLK_I2C_PERIOD_5   :           integer     := CLK_PERIOD/5                        ; -- 5
    constant CLK_I2C_PERIOD_6   :           integer     := CLK_PERIOD/6                        ; -- 6
    constant CLK_I2C_PERIOD_7   :           integer     := CLK_PERIOD/7                        ; -- 7
    constant CLK_I2C_PERIOD_8   :           integer     := CLK_PERIOD/8                        ; -- 8
    constant CLK_I2C_PERIOD_9   :           integer     := CLK_PERIOD/9                        ; -- 9
    constant CLK_I2C_PERIOD_10  :           integer     := CLK_PERIOD/10                        ; -- 10
    constant CLK_I2C_PERIOD_11  :           integer     := CLK_PERIOD/11                        ; -- 11
    constant CLK_I2C_PERIOD_12  :           integer     := CLK_PERIOD/12                        ; -- 12
    constant CLK_I2C_PERIOD_13  :           integer     := CLK_PERIOD/13                        ; -- 13
    constant CLK_I2C_PERIOD_14  :           integer     := CLK_PERIOD/14                        ; -- 14
    constant CLK_I2C_PERIOD_15  :           integer     := CLK_PERIOD/15                        ; -- 15
    constant CLK_I2C_PERIOD_16  :           integer     := CLK_PERIOD/16                        ; -- 16

    component axis_iic_bridge 
        generic (
            CLK_PERIOD      :           integer     := 100000000                            ;
            CLK_I2C_PERIOD  :           integer     := 25000000                             ;
            N_BYTES         :           integer     := 32                                   
        ); 
        port (
            CLK             :   in      std_Logic                                           ;
            reset           :   in      std_Logic                                           ;
            s_axis_tdata    :   in      std_logic_Vector ( ((N_BYTES*8)-1) downto 0 )       ;
            s_axis_tkeep    :   in      std_logic_Vector (       N_BYTES-1 downto 0 )       ;
            s_axis_tuser    :   in      std_logic_Vector ( 7 downto 0 )                     ;
            s_axis_tvalid   :   in      std_Logic                                           ;
            s_axis_tready   :   out     std_Logic                                           ;
            s_axis_tlast    :   in      std_Logic                                           ;
            m_axis_tdata    :   out     std_logic_Vector ( ((N_BYTES*8)-1) downto 0 )       ;
            m_axis_tkeep    :   out     std_logic_Vector (       N_BYTES-1 downto 0 )       ;
            m_axis_tuser    :   out     std_logic_Vector ( 7 downto 0 )                     ;
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
    signal  s_axis_tuser    :           std_Logic_Vector (               7 downto 0 ) := (others => '0')    ;
    signal  s_axis_tvalid   :           std_Logic                                     := '0'                ;
    signal  s_axis_tready   :           std_Logic                                                           ;
    signal  s_axis_tlast    :           std_Logic                                                           ;
    
    signal  m_axis_tdata_4  :           std_logic_Vector ( ((N_BYTES*8)-1) downto 0 )                       ;
    signal  m_axis_tkeep_4  :           std_logic_Vector (       N_BYTES-1 downto 0 )                       ;
    signal  m_axis_tuser_4  :           std_Logic_Vector (               7 downto 0 )                       ;
    signal  m_axis_tvalid_4 :           std_Logic                                                           ;
    signal  m_axis_tready_4 :           std_Logic                                     := '0'                ;
    signal  m_axis_tlast_4  :           std_Logic                                                           ;

    signal  m_axis_tdata_5  :           std_logic_Vector ( ((N_BYTES*8)-1) downto 0 )                       ;
    signal  m_axis_tkeep_5  :           std_logic_Vector (       N_BYTES-1 downto 0 )                       ;
    signal  m_axis_tuser_5  :           std_Logic_Vector (               7 downto 0 )                       ;
    signal  m_axis_tvalid_5 :           std_Logic                                                           ;
    signal  m_axis_tready_5 :           std_Logic                                     := '0'                ;
    signal  m_axis_tlast_5  :           std_Logic                                                           ;

    signal  m_axis_tdata_6  :           std_logic_Vector ( ((N_BYTES*8)-1) downto 0 )                       ;
    signal  m_axis_tkeep_6  :           std_logic_Vector (       N_BYTES-1 downto 0 )                       ;
    signal  m_axis_tuser_6  :           std_Logic_Vector (               7 downto 0 )                       ;
    signal  m_axis_tvalid_6 :           std_Logic                                                           ;
    signal  m_axis_tready_6 :           std_Logic                                     := '0'                ;
    signal  m_axis_tlast_6  :           std_Logic                                                           ;

    signal  m_axis_tdata_7  :           std_logic_Vector ( ((N_BYTES*8)-1) downto 0 )                       ;
    signal  m_axis_tkeep_7  :           std_logic_Vector (       N_BYTES-1 downto 0 )                       ;
    signal  m_axis_tuser_7  :           std_Logic_Vector (               7 downto 0 )                       ;
    signal  m_axis_tvalid_7 :           std_Logic                                                           ;
    signal  m_axis_tready_7 :           std_Logic                                     := '0'                ;
    signal  m_axis_tlast_7  :           std_Logic                                                           ;

    signal  m_axis_tdata_8  :           std_logic_Vector ( ((N_BYTES*8)-1) downto 0 )                       ;
    signal  m_axis_tkeep_8  :           std_logic_Vector (       N_BYTES-1 downto 0 )                       ;
    signal  m_axis_tuser_8  :           std_Logic_Vector (               7 downto 0 )                       ;
    signal  m_axis_tvalid_8 :           std_Logic                                                           ;
    signal  m_axis_tready_8 :           std_Logic                                     := '0'                ;
    signal  m_axis_tlast_8  :           std_Logic                                                           ;

    signal  m_axis_tdata_9  :           std_logic_Vector ( ((N_BYTES*8)-1) downto 0 )                       ;
    signal  m_axis_tkeep_9  :           std_logic_Vector (       N_BYTES-1 downto 0 )                       ;
    signal  m_axis_tuser_9  :           std_Logic_Vector (               7 downto 0 )                       ;
    signal  m_axis_tvalid_9 :           std_Logic                                                           ;
    signal  m_axis_tready_9 :           std_Logic                                     := '0'                ;
    signal  m_axis_tlast_9  :           std_Logic                                                           ;
    
    signal  m_axis_tdata_10  :           std_logic_Vector ( ((N_BYTES*8)-1) downto 0 )                       ;
    signal  m_axis_tkeep_10  :           std_logic_Vector (       N_BYTES-1 downto 0 )                       ;
    signal  m_axis_tuser_10  :           std_Logic_Vector (               7 downto 0 )                       ;
    signal  m_axis_tvalid_10 :           std_Logic                                                           ;
    signal  m_axis_tready_10 :           std_Logic                                     := '0'                ;
    signal  m_axis_tlast_10  :           std_Logic                                                           ;

    signal  m_axis_tdata_11  :           std_logic_Vector ( ((N_BYTES*8)-1) downto 0 )                       ;
    signal  m_axis_tkeep_11  :           std_logic_Vector (       N_BYTES-1 downto 0 )                       ;
    signal  m_axis_tuser_11  :           std_Logic_Vector (               7 downto 0 )                       ;
    signal  m_axis_tvalid_11 :           std_Logic                                                           ;
    signal  m_axis_tready_11 :           std_Logic                                     := '0'                ;
    signal  m_axis_tlast_11  :           std_Logic                                                           ;

    signal  m_axis_tdata_12  :           std_logic_Vector ( ((N_BYTES*8)-1) downto 0 )                       ;
    signal  m_axis_tkeep_12  :           std_logic_Vector (       N_BYTES-1 downto 0 )                       ;
    signal  m_axis_tuser_12  :           std_Logic_Vector (               7 downto 0 )                       ;
    signal  m_axis_tvalid_12 :           std_Logic                                                           ;
    signal  m_axis_tready_12 :           std_Logic                                     := '0'                ;
    signal  m_axis_tlast_12  :           std_Logic                                                           ;

    signal  m_axis_tdata_13  :           std_logic_Vector ( ((N_BYTES*8)-1) downto 0 )                       ;
    signal  m_axis_tkeep_13  :           std_logic_Vector (       N_BYTES-1 downto 0 )                       ;
    signal  m_axis_tuser_13  :           std_Logic_Vector (               7 downto 0 )                       ;
    signal  m_axis_tvalid_13 :           std_Logic                                                           ;
    signal  m_axis_tready_13 :           std_Logic                                     := '0'                ;
    signal  m_axis_tlast_13  :           std_Logic                                                           ;

    signal  m_axis_tdata_14  :           std_logic_Vector ( ((N_BYTES*8)-1) downto 0 )                       ;
    signal  m_axis_tkeep_14  :           std_logic_Vector (       N_BYTES-1 downto 0 )                       ;
    signal  m_axis_tuser_14  :           std_Logic_Vector (               7 downto 0 )                       ;
    signal  m_axis_tvalid_14 :           std_Logic                                                           ;
    signal  m_axis_tready_14 :           std_Logic                                     := '0'                ;
    signal  m_axis_tlast_14  :           std_Logic                                                           ;

    signal  m_axis_tdata_15  :           std_logic_Vector ( ((N_BYTES*8)-1) downto 0 )                       ;
    signal  m_axis_tkeep_15  :           std_logic_Vector (       N_BYTES-1 downto 0 )                       ;
    signal  m_axis_tuser_15  :           std_Logic_Vector (               7 downto 0 )                       ;
    signal  m_axis_tvalid_15 :           std_Logic                                                           ;
    signal  m_axis_tready_15 :           std_Logic                                     := '0'                ;
    signal  m_axis_tlast_15  :           std_Logic                                                           ;

    signal  m_axis_tdata_16  :           std_logic_Vector ( ((N_BYTES*8)-1) downto 0 )                       ;
    signal  m_axis_tkeep_16  :           std_logic_Vector (       N_BYTES-1 downto 0 )                       ;
    signal  m_axis_tuser_16  :           std_Logic_Vector (               7 downto 0 )                       ;
    signal  m_axis_tvalid_16 :           std_Logic                                                           ;
    signal  m_axis_tready_16 :           std_Logic                                     := '0'                ;
    signal  m_axis_tlast_16  :           std_Logic                                                           ;

    signal  m_axis_tdata     :           std_logic_Vector ( ((N_BYTES*8)-1) downto 0 )                       ;
    signal  m_axis_tkeep     :           std_logic_Vector (       N_BYTES-1 downto 0 )                       ;
    signal  m_axis_tuser     :           std_Logic_Vector (               7 downto 0 )                       ;
    signal  m_axis_tvalid    :           std_Logic                                                           ;
    signal  m_axis_tready    :           std_Logic                                     := '0'                ;
    signal  m_axis_tlast     :           std_Logic                                                           ;



    signal  scl_i_4         :           std_Logic                                     := '0'                ;
    signal  sda_i_4         :           std_Logic                                     := '0'                ;
    signal  scl_t_4         :           std_Logic                                                           ;
    signal  sda_t_4         :           std_Logic                                                           ;

    signal  scl_i_5         :           std_Logic                                     := '0'                ;
    signal  sda_i_5         :           std_Logic                                     := '0'                ;
    signal  scl_t_5         :           std_Logic                                                           ;
    signal  sda_t_5         :           std_Logic                                                           ;

    signal  scl_i_6         :           std_Logic                                     := '0'                ;
    signal  sda_i_6         :           std_Logic                                     := '0'                ;
    signal  scl_t_6         :           std_Logic                                                           ;
    signal  sda_t_6         :           std_Logic                                                           ;

    signal  scl_i_7         :           std_Logic                                     := '0'                ;
    signal  sda_i_7         :           std_Logic                                     := '0'                ;
    signal  scl_t_7         :           std_Logic                                                           ;
    signal  sda_t_7         :           std_Logic                                                           ;

    signal  scl_i_8         :           std_Logic                                     := '0'                ;
    signal  sda_i_8         :           std_Logic                                     := '0'                ;
    signal  scl_t_8         :           std_Logic                                                           ;
    signal  sda_t_8         :           std_Logic                                                           ;

    signal  scl_i_9         :           std_Logic                                     := '0'                ;
    signal  sda_i_9         :           std_Logic                                     := '0'                ;
    signal  scl_t_9         :           std_Logic                                                           ;
    signal  sda_t_9         :           std_Logic                                                           ;

    signal  scl_i_10        :           std_Logic                                     := '0'                ;
    signal  sda_i_10        :           std_Logic                                     := '0'                ;
    signal  scl_t_10        :           std_Logic                                                           ;
    signal  sda_t_10        :           std_Logic                                                           ;

    signal  scl_i_11        :           std_Logic                                     := '0'                ;
    signal  sda_i_11        :           std_Logic                                     := '0'                ;
    signal  scl_t_11        :           std_Logic                                                           ;
    signal  sda_t_11        :           std_Logic                                                           ;

    signal  scl_i_12        :           std_Logic                                     := '0'                ;
    signal  sda_i_12        :           std_Logic                                     := '0'                ;
    signal  scl_t_12        :           std_Logic                                                           ;
    signal  sda_t_12        :           std_Logic                                                           ;

    signal  scl_i_13        :           std_Logic                                     := '0'                ;
    signal  sda_i_13        :           std_Logic                                     := '0'                ;
    signal  scl_t_13        :           std_Logic                                                           ;
    signal  sda_t_13        :           std_Logic                                                           ;
    
    signal  scl_i_14        :           std_Logic                                     := '0'                ;
    signal  sda_i_14        :           std_Logic                                     := '0'                ;
    signal  scl_t_14        :           std_Logic                                                           ;
    signal  sda_t_14        :           std_Logic                                                           ;

    signal  scl_i_15        :           std_Logic                                     := '0'                ;
    signal  sda_i_15        :           std_Logic                                     := '0'                ;
    signal  scl_t_15        :           std_Logic                                                           ;
    signal  sda_t_15        :           std_Logic                                                           ;

    signal  scl_i_16        :           std_Logic                                     := '0'                ;
    signal  sda_i_16        :           std_Logic                                     := '0'                ;
    signal  scl_t_16        :           std_Logic                                                           ;
    signal  sda_t_16        :           std_Logic                                                           ;

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

    axis_iic_bridge_4_inst : axis_iic_bridge 
        generic map (
            CLK_PERIOD      =>  CLK_PERIOD                      ,
            CLK_I2C_PERIOD  =>  CLK_I2C_PERIOD_4                ,
            N_BYTES         =>  N_BYTES                          
        )
        port map  (
            CLK             =>  CLK                             ,
            reset           =>  reset                           ,
            s_axis_tdata    =>  s_axis_tdata                    ,
            s_axis_tuser    =>  s_axis_tuser                    ,
            s_axis_tkeep    =>  s_axis_tkeep                    ,
            s_axis_tvalid   =>  s_axis_tvalid                   ,
            s_axis_tready   =>  open                            ,
            s_axis_tlast    =>  s_axis_tlast                    ,
            m_axis_tdata    =>  m_axis_tdata_4                  ,
            m_axis_tkeep    =>  m_axis_tkeep_4                  ,
            m_axis_tuser    =>  m_axis_tuser_4                  ,
            m_axis_tvalid   =>  m_axis_tvalid_4                 ,
            m_axis_tready   =>  m_axis_tready_4                 ,
            m_axis_tlast    =>  m_axis_tlast_4                  ,
            scl_i           =>  scl_i_4                         ,
            sda_i           =>  sda_i_4                         ,
            scl_t           =>  scl_t_4                         ,
            sda_t           =>  sda_t_4                          
        );

    axis_iic_bridge_5_inst : axis_iic_bridge 
        generic map (
            CLK_PERIOD      =>  CLK_PERIOD                      ,
            CLK_I2C_PERIOD  =>  CLK_I2C_PERIOD_5                ,
            N_BYTES         =>  N_BYTES                          
        )
        port map  (
            CLK             =>  CLK                             ,
            reset           =>  reset                           ,
            s_axis_tdata    =>  s_axis_tdata                    ,
            s_axis_tuser    =>  s_axis_tuser                    ,
            s_axis_tkeep    =>  s_axis_tkeep                    ,
            s_axis_tvalid   =>  s_axis_tvalid                   ,
            s_axis_tready   =>  open                            ,
            s_axis_tlast    =>  s_axis_tlast                    ,
            m_axis_tdata    =>  m_axis_tdata_5                  ,
            m_axis_tkeep    =>  m_axis_tkeep_5                  ,
            m_axis_tuser    =>  m_axis_tuser_5                  ,
            m_axis_tvalid   =>  m_axis_tvalid_5                 ,
            m_axis_tready   =>  m_axis_tready_5                 ,
            m_axis_tlast    =>  m_axis_tlast_5                  ,
            scl_i           =>  scl_i_5                         ,
            sda_i           =>  sda_i_5                         ,
            scl_t           =>  scl_t_5                         ,
            sda_t           =>  sda_t_5                          
        );

    axis_iic_bridge_6_inst : axis_iic_bridge 
        generic map (
            CLK_PERIOD      =>  CLK_PERIOD                      ,
            CLK_I2C_PERIOD  =>  CLK_I2C_PERIOD_6                ,
            N_BYTES         =>  N_BYTES                          
        )
        port map  (
            CLK             =>  CLK                             ,
            reset           =>  reset                           ,
            s_axis_tdata    =>  s_axis_tdata                    ,
            s_axis_tuser    =>  s_axis_tuser                    ,
            s_axis_tkeep    =>  s_axis_tkeep                    ,
            s_axis_tvalid   =>  s_axis_tvalid                   ,
            s_axis_tready   =>  open                            ,
            s_axis_tlast    =>  s_axis_tlast                    ,
            m_axis_tdata    =>  m_axis_tdata_6                  ,
            m_axis_tkeep    =>  m_axis_tkeep_6                  ,
            m_axis_tuser    =>  m_axis_tuser_6                  ,
            m_axis_tvalid   =>  m_axis_tvalid_6                 ,
            m_axis_tready   =>  m_axis_tready_6                 ,
            m_axis_tlast    =>  m_axis_tlast_6                  ,
            scl_i           =>  scl_i_6                         ,
            sda_i           =>  sda_i_6                         ,
            scl_t           =>  scl_t_6                         ,
            sda_t           =>  sda_t_6                          
        );

    axis_iic_bridge_7_inst : axis_iic_bridge 
        generic map (
            CLK_PERIOD      =>  CLK_PERIOD                      ,
            CLK_I2C_PERIOD  =>  CLK_I2C_PERIOD_7                ,
            N_BYTES         =>  N_BYTES                          
        )
        port map  (
            CLK             =>  CLK                             ,
            reset           =>  reset                           ,
            s_axis_tdata    =>  s_axis_tdata                    ,
            s_axis_tuser    =>  s_axis_tuser                    ,
            s_axis_tkeep    =>  s_axis_tkeep                    ,
            s_axis_tvalid   =>  s_axis_tvalid                   ,
            s_axis_tready   =>  open                            ,
            s_axis_tlast    =>  s_axis_tlast                    ,
            m_axis_tdata    =>  m_axis_tdata_7                  ,
            m_axis_tkeep    =>  m_axis_tkeep_7                  ,
            m_axis_tuser    =>  m_axis_tuser_7                  ,
            m_axis_tvalid   =>  m_axis_tvalid_7                 ,
            m_axis_tready   =>  m_axis_tready_7                 ,
            m_axis_tlast    =>  m_axis_tlast_7                  ,
            scl_i           =>  scl_i_7                         ,
            sda_i           =>  sda_i_7                         ,
            scl_t           =>  scl_t_7                         ,
            sda_t           =>  sda_t_7                          
        );

    axis_iic_bridge_8_inst : axis_iic_bridge 
        generic map (
            CLK_PERIOD      =>  CLK_PERIOD                      ,
            CLK_I2C_PERIOD  =>  CLK_I2C_PERIOD_8                ,
            N_BYTES         =>  N_BYTES                          
        )
        port map  (
            CLK             =>  CLK                             ,
            reset           =>  reset                           ,
            s_axis_tdata    =>  s_axis_tdata                    ,
            s_axis_tuser    =>  s_axis_tuser                    ,
            s_axis_tkeep    =>  s_axis_tkeep                    ,
            s_axis_tvalid   =>  s_axis_tvalid                   ,
            s_axis_tready   =>  open                            ,
            s_axis_tlast    =>  s_axis_tlast                    ,
            m_axis_tdata    =>  m_axis_tdata_8                  ,
            m_axis_tkeep    =>  m_axis_tkeep_8                  ,
            m_axis_tuser    =>  m_axis_tuser_8                  ,
            m_axis_tvalid   =>  m_axis_tvalid_8                 ,
            m_axis_tready   =>  m_axis_tready_8                 ,
            m_axis_tlast    =>  m_axis_tlast_8                  ,
            scl_i           =>  scl_i_8                         ,
            sda_i           =>  sda_i_8                         ,
            scl_t           =>  scl_t_8                         ,
            sda_t           =>  sda_t_8                          
        );

    axis_iic_bridge_9_inst : axis_iic_bridge 
        generic map (
            CLK_PERIOD      =>  CLK_PERIOD                      ,
            CLK_I2C_PERIOD  =>  CLK_I2C_PERIOD_9                ,
            N_BYTES         =>  N_BYTES                          
        )
        port map  (
            CLK             =>  CLK                             ,
            reset           =>  reset                           ,
            s_axis_tdata    =>  s_axis_tdata                    ,
            s_axis_tuser    =>  s_axis_tuser                    ,
            s_axis_tkeep    =>  s_axis_tkeep                    ,
            s_axis_tvalid   =>  s_axis_tvalid                   ,
            s_axis_tready   =>  open                            ,
            s_axis_tlast    =>  s_axis_tlast                    ,
            m_axis_tdata    =>  m_axis_tdata_9                  ,
            m_axis_tkeep    =>  m_axis_tkeep_9                  ,
            m_axis_tuser    =>  m_axis_tuser_9                  ,
            m_axis_tvalid   =>  m_axis_tvalid_9                 ,
            m_axis_tready   =>  m_axis_tready_9                 ,
            m_axis_tlast    =>  m_axis_tlast_9                  ,
            scl_i           =>  scl_i_9                         ,
            sda_i           =>  sda_i_9                         ,
            scl_t           =>  scl_t_9                         ,
            sda_t           =>  sda_t_9                          
        );

    axis_iic_bridge_10_inst : axis_iic_bridge 
        generic map (
            CLK_PERIOD      =>  CLK_PERIOD                      ,
            CLK_I2C_PERIOD  =>  CLK_I2C_PERIOD_10               ,
            N_BYTES         =>  N_BYTES                          
        )
        port map  (
            CLK             =>  CLK                             ,
            reset           =>  reset                           ,
            s_axis_tdata    =>  s_axis_tdata                    ,
            s_axis_tuser    =>  s_axis_tuser                    ,
            s_axis_tkeep    =>  s_axis_tkeep                    ,
            s_axis_tvalid   =>  s_axis_tvalid                   ,
            s_axis_tready   =>  open                            ,
            s_axis_tlast    =>  s_axis_tlast                    ,
            m_axis_tdata    =>  m_axis_tdata_10                 ,
            m_axis_tkeep    =>  m_axis_tkeep_10                 ,
            m_axis_tuser    =>  m_axis_tuser_10                 ,
            m_axis_tvalid   =>  m_axis_tvalid_10                ,
            m_axis_tready   =>  m_axis_tready_10                ,
            m_axis_tlast    =>  m_axis_tlast_10                 ,
            scl_i           =>  scl_i_10                        ,
            sda_i           =>  sda_i_10                        ,
            scl_t           =>  scl_t_10                        ,
            sda_t           =>  sda_t_10                         
        );

    axis_iic_bridge_11_inst : axis_iic_bridge 
        generic map (
            CLK_PERIOD      =>  CLK_PERIOD                      ,
            CLK_I2C_PERIOD  =>  CLK_I2C_PERIOD_11               ,
            N_BYTES         =>  N_BYTES                          
        )
        port map  (
            CLK             =>  CLK                             ,
            reset           =>  reset                           ,
            s_axis_tdata    =>  s_axis_tdata                    ,
            s_axis_tuser    =>  s_axis_tuser                    ,
            s_axis_tkeep    =>  s_axis_tkeep                    ,
            s_axis_tvalid   =>  s_axis_tvalid                   ,
            s_axis_tready   =>  open                            ,
            s_axis_tlast    =>  s_axis_tlast                    ,
            m_axis_tdata    =>  m_axis_tdata_11                 ,
            m_axis_tkeep    =>  m_axis_tkeep_11                 ,
            m_axis_tuser    =>  m_axis_tuser_11                 ,
            m_axis_tvalid   =>  m_axis_tvalid_11                ,
            m_axis_tready   =>  m_axis_tready_11                ,
            m_axis_tlast    =>  m_axis_tlast_11                 ,
            scl_i           =>  scl_i_11                        ,
            sda_i           =>  sda_i_11                        ,
            scl_t           =>  scl_t_11                        ,
            sda_t           =>  sda_t_11                         
        );

    axis_iic_bridge_12_inst : axis_iic_bridge 
        generic map (
            CLK_PERIOD      =>  CLK_PERIOD                      ,
            CLK_I2C_PERIOD  =>  CLK_I2C_PERIOD_12               ,
            N_BYTES         =>  N_BYTES                          
        )
        port map  (
            CLK             =>  CLK                             ,
            reset           =>  reset                           ,
            s_axis_tdata    =>  s_axis_tdata                    ,
            s_axis_tuser    =>  s_axis_tuser                    ,
            s_axis_tkeep    =>  s_axis_tkeep                    ,
            s_axis_tvalid   =>  s_axis_tvalid                   ,
            s_axis_tready   =>  open                            ,
            s_axis_tlast    =>  s_axis_tlast                    ,
            m_axis_tdata    =>  m_axis_tdata_12                 ,
            m_axis_tkeep    =>  m_axis_tkeep_12                 ,
            m_axis_tuser    =>  m_axis_tuser_12                 ,
            m_axis_tvalid   =>  m_axis_tvalid_12                ,
            m_axis_tready   =>  m_axis_tready_12                ,
            m_axis_tlast    =>  m_axis_tlast_12                 ,
            scl_i           =>  scl_i_12                        ,
            sda_i           =>  sda_i_12                        ,
            scl_t           =>  scl_t_12                        ,
            sda_t           =>  sda_t_12                         
        );

    axis_iic_bridge_13_inst : axis_iic_bridge 
        generic map (
            CLK_PERIOD      =>  CLK_PERIOD                      ,
            CLK_I2C_PERIOD  =>  CLK_I2C_PERIOD_13               ,
            N_BYTES         =>  N_BYTES                          
        )
        port map  (
            CLK             =>  CLK                             ,
            reset           =>  reset                           ,
            s_axis_tdata    =>  s_axis_tdata                    ,
            s_axis_tuser    =>  s_axis_tuser                    ,
            s_axis_tkeep    =>  s_axis_tkeep                    ,
            s_axis_tvalid   =>  s_axis_tvalid                   ,
            s_axis_tready   =>  open                            ,
            s_axis_tlast    =>  s_axis_tlast                    ,
            m_axis_tdata    =>  m_axis_tdata_13                 ,
            m_axis_tkeep    =>  m_axis_tkeep_13                 ,
            m_axis_tuser    =>  m_axis_tuser_13                 ,
            m_axis_tvalid   =>  m_axis_tvalid_13                ,
            m_axis_tready   =>  m_axis_tready_13                ,
            m_axis_tlast    =>  m_axis_tlast_13                 ,
            scl_i           =>  scl_i_13                        ,
            sda_i           =>  sda_i_13                        ,
            scl_t           =>  scl_t_13                        ,
            sda_t           =>  sda_t_13                         
        );

    axis_iic_bridge_14_inst : axis_iic_bridge 
        generic map (
            CLK_PERIOD      =>  CLK_PERIOD                      ,
            CLK_I2C_PERIOD  =>  CLK_I2C_PERIOD_14               ,
            N_BYTES         =>  N_BYTES                          
        )
        port map  (
            CLK             =>  CLK                             ,
            reset           =>  reset                           ,
            s_axis_tdata    =>  s_axis_tdata                    ,
            s_axis_tuser    =>  s_axis_tuser                    ,
            s_axis_tkeep    =>  s_axis_tkeep                    ,
            s_axis_tvalid   =>  s_axis_tvalid                   ,
            s_axis_tready   =>  open                            ,
            s_axis_tlast    =>  s_axis_tlast                    ,
            m_axis_tdata    =>  m_axis_tdata_14                 ,
            m_axis_tkeep    =>  m_axis_tkeep_14                 ,
            m_axis_tuser    =>  m_axis_tuser_14                 ,
            m_axis_tvalid   =>  m_axis_tvalid_14                ,
            m_axis_tready   =>  m_axis_tready_14                ,
            m_axis_tlast    =>  m_axis_tlast_14                 ,
            scl_i           =>  scl_i_14                        ,
            sda_i           =>  sda_i_14                        ,
            scl_t           =>  scl_t_14                        ,
            sda_t           =>  sda_t_14                         
        );

    axis_iic_bridge_15_inst : axis_iic_bridge 
        generic map (
            CLK_PERIOD      =>  CLK_PERIOD                      ,
            CLK_I2C_PERIOD  =>  CLK_I2C_PERIOD_15               ,
            N_BYTES         =>  N_BYTES                          
        )
        port map  (
            CLK             =>  CLK                             ,
            reset           =>  reset                           ,
            s_axis_tdata    =>  s_axis_tdata                    ,
            s_axis_tuser    =>  s_axis_tuser                    ,
            s_axis_tkeep    =>  s_axis_tkeep                    ,
            s_axis_tvalid   =>  s_axis_tvalid                   ,
            s_axis_tready   =>  open                            ,
            s_axis_tlast    =>  s_axis_tlast                    ,
            m_axis_tdata    =>  m_axis_tdata_15                 ,
            m_axis_tkeep    =>  m_axis_tkeep_15                 ,
            m_axis_tuser    =>  m_axis_tuser_15                 ,
            m_axis_tvalid   =>  m_axis_tvalid_15                ,
            m_axis_tready   =>  m_axis_tready_15                ,
            m_axis_tlast    =>  m_axis_tlast_15                 ,
            scl_i           =>  scl_i_15                        ,
            sda_i           =>  sda_i_15                        ,
            scl_t           =>  scl_t_15                        ,
            sda_t           =>  sda_t_15                         
        );

    axis_iic_bridge_16_inst : axis_iic_bridge 
        generic map (
            CLK_PERIOD      =>  CLK_PERIOD                      ,
            CLK_I2C_PERIOD  =>  CLK_I2C_PERIOD_16               ,
            N_BYTES         =>  N_BYTES                          
        )
        port map  (
            CLK             =>  CLK                             ,
            reset           =>  reset                           ,
            s_axis_tdata    =>  s_axis_tdata                    ,
            s_axis_tuser    =>  s_axis_tuser                    ,
            s_axis_tkeep    =>  s_axis_tkeep                    ,
            s_axis_tvalid   =>  s_axis_tvalid                   ,
            s_axis_tready   =>  open                            ,
            s_axis_tlast    =>  s_axis_tlast                    ,
            m_axis_tdata    =>  m_axis_tdata_16                 ,
            m_axis_tkeep    =>  m_axis_tkeep_16                 ,
            m_axis_tuser    =>  m_axis_tuser_16                 ,
            m_axis_tvalid   =>  m_axis_tvalid_16                ,
            m_axis_tready   =>  m_axis_tready_16                ,
            m_axis_tlast    =>  m_axis_tlast_16                 ,
            scl_i           =>  scl_i_16                        ,
            sda_i           =>  sda_i_16                        ,
            scl_t           =>  scl_t_16                        ,
            sda_t           =>  sda_t_16                         
        );

    axis_iic_bridge_inst : axis_iic_bridge 
        generic map (
            CLK_PERIOD      =>  CLK_PERIOD                      ,
            CLK_I2C_PERIOD  =>  CLK_I2C_PERIOD                  ,
            N_BYTES         =>  N_BYTES                          
        )
        port map  (
            CLK             =>  CLK                             ,
            reset           =>  reset                           ,
            s_axis_tdata    =>  s_axis_tdata                    ,
            s_axis_tuser    =>  s_axis_tuser                    ,
            s_axis_tkeep    =>  s_axis_tkeep                    ,
            s_axis_tvalid   =>  s_axis_tvalid                   ,
            s_axis_tready   =>  open                            ,
            s_axis_tlast    =>  s_axis_tlast                    ,
            m_axis_tdata    =>  m_axis_tdata                    ,
            m_axis_tkeep    =>  m_axis_tkeep                    ,
            m_axis_tuser    =>  m_axis_tuser                    ,
            m_axis_tvalid   =>  m_axis_tvalid                   ,
            m_axis_tready   =>  m_axis_tready                   ,
            m_axis_tlast    =>  m_axis_tlast                    ,
            scl_i           =>  scl_i                           ,
            sda_i           =>  sda_i                           ,
            scl_t           =>  scl_t                           ,
            sda_t           =>  sda_t                            
        );


    s_axis_processing : process(CLK)
    begin
        if CLK'event AND CLK = '1' then 
            case i is
                when 100 => S_AXIS_TDATA <= x"03020100"; S_AXIS_TUSER <= x"A6"; S_AXIS_TKEEP <= x"F"; S_AXIS_TVALID <= '1'; S_AXIS_TLAST <= '0';
                when 101 => S_AXIS_TDATA <= x"03020100"; S_AXIS_TUSER <= x"A6"; S_AXIS_TKEEP <= x"F"; S_AXIS_TVALID <= '1'; S_AXIS_TLAST <= '0';                
                when others => S_AXIS_TDATA <= S_AXIS_TDATA; S_AXIS_TUSER <= S_AXIS_TUSER; S_AXIS_TKEEP <= S_AXIS_TKEEP; S_AXIS_TVALID <= '0'; S_AXIS_TLAST <= S_AXIS_TLAST;
            end case;
        end if;
    end process;

end architecture;