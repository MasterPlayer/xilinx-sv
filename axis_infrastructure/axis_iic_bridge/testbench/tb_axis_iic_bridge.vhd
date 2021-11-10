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


    component axis_iic_ctrlr 
        generic (
            CLK_PERIOD      :           integer := 100000000                            ;
            CLK_I2C_PERIOD  :           integer := 400000                               ;
            N_BYTES         :           integer := 32                                   ;
            DEPTH           :           integer := 16                                    
        );  
        port (
            clk             :   in      std_logic                                       ;
            resetn          :   in      std_logic                                       ;
            s_axis_tdata    :   in      std_logic_vector ( ((N_BYTES*8)-1) downto 0 )   ;
            s_axis_tkeep    :   in      std_logic_vector (       N_BYTES-1 downto 0 )   ;
            s_axis_tdest    :   in      std_logic_vector (               7 downto 0 )   ;
            s_axis_tvalid   :   in      std_logic                                       ;
            s_axis_tready   :   out     std_logic                                       ;
            s_axis_tlast    :   in      std_logic                                       ;
            m_axis_tdata    :   out     std_logic_vector ( ((N_BYTES*8)-1) downto 0 )   ;
            m_axis_tkeep    :   out     std_logic_vector (       N_BYTES-1 downto 0 )   ;
            m_axis_tdest    :   out     std_logic_vector (               7 downto 0 )   ;
            m_axis_tvalid   :   out     std_logic                                       ;
            m_axis_tready   :   in      std_logic                                       ;
            m_axis_tlast    :   out     std_logic                                       ;
            scl_i           :   in      std_logic                                       ;
            sda_i           :   in      std_logic                                       ;
            scl_t           :   out     std_logic                                       ;
            sda_t           :   out     std_logic                                        
        );
    end component;

    component axis_iic_bridge 
        generic (
            CLK_PERIOD      :           integer     := 100000000                            ;
            CLK_I2C_PERIOD  :           integer     := 25000000                             ;
            N_BYTES         :           integer     := 32                                   ;
            WRITE_CONTROL   :           string      := "STREAM" -- or "COUNTER"
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
    signal  s_axis_tlast    :           std_Logic                                     := '0'                ;
    
    signal  m_axis_tdata_4  :           std_logic_Vector ( ((N_BYTES*8)-1) downto 0 )                       ;
    signal  m_axis_tkeep_4  :           std_logic_Vector (       N_BYTES-1 downto 0 )                       ;
    signal  m_axis_tuser_4  :           std_Logic_Vector (               7 downto 0 )                       ;
    signal  m_axis_tvalid_4 :           std_Logic                                                           ;
    signal  m_axis_tready_4 :           std_Logic                                     := '0'                ;
    signal  m_axis_tlast_4  :           std_Logic                                                           ;

    --signal  m_axis_tdata_5  :           std_logic_Vector ( ((N_BYTES*8)-1) downto 0 )                       ;
    --signal  m_axis_tkeep_5  :           std_logic_Vector (       N_BYTES-1 downto 0 )                       ;
    --signal  m_axis_tuser_5  :           std_Logic_Vector (               7 downto 0 )                       ;
    --signal  m_axis_tvalid_5 :           std_Logic                                                           ;
    --signal  m_axis_tready_5 :           std_Logic                                     := '0'                ;
    --signal  m_axis_tlast_5  :           std_Logic                                                           ;

    --signal  m_axis_tdata_6  :           std_logic_Vector ( ((N_BYTES*8)-1) downto 0 )                       ;
    --signal  m_axis_tkeep_6  :           std_logic_Vector (       N_BYTES-1 downto 0 )                       ;
    --signal  m_axis_tuser_6  :           std_Logic_Vector (               7 downto 0 )                       ;
    --signal  m_axis_tvalid_6 :           std_Logic                                                           ;
    --signal  m_axis_tready_6 :           std_Logic                                     := '0'                ;
    --signal  m_axis_tlast_6  :           std_Logic                                                           ;

    --signal  m_axis_tdata_7  :           std_logic_Vector ( ((N_BYTES*8)-1) downto 0 )                       ;
    --signal  m_axis_tkeep_7  :           std_logic_Vector (       N_BYTES-1 downto 0 )                       ;
    --signal  m_axis_tuser_7  :           std_Logic_Vector (               7 downto 0 )                       ;
    --signal  m_axis_tvalid_7 :           std_Logic                                                           ;
    --signal  m_axis_tready_7 :           std_Logic                                     := '0'                ;
    --signal  m_axis_tlast_7  :           std_Logic                                                           ;

    --signal  m_axis_tdata_8  :           std_logic_Vector ( ((N_BYTES*8)-1) downto 0 )                       ;
    --signal  m_axis_tkeep_8  :           std_logic_Vector (       N_BYTES-1 downto 0 )                       ;
    --signal  m_axis_tuser_8  :           std_Logic_Vector (               7 downto 0 )                       ;
    --signal  m_axis_tvalid_8 :           std_Logic                                                           ;
    --signal  m_axis_tready_8 :           std_Logic                                     := '0'                ;
    --signal  m_axis_tlast_8  :           std_Logic                                                           ;

    --signal  m_axis_tdata_9  :           std_logic_Vector ( ((N_BYTES*8)-1) downto 0 )                       ;
    --signal  m_axis_tkeep_9  :           std_logic_Vector (       N_BYTES-1 downto 0 )                       ;
    --signal  m_axis_tuser_9  :           std_Logic_Vector (               7 downto 0 )                       ;
    --signal  m_axis_tvalid_9 :           std_Logic                                                           ;
    --signal  m_axis_tready_9 :           std_Logic                                     := '0'                ;
    --signal  m_axis_tlast_9  :           std_Logic                                                           ;
    
    --signal  m_axis_tdata_10  :           std_logic_Vector ( ((N_BYTES*8)-1) downto 0 )                       ;
    --signal  m_axis_tkeep_10  :           std_logic_Vector (       N_BYTES-1 downto 0 )                       ;
    --signal  m_axis_tuser_10  :           std_Logic_Vector (               7 downto 0 )                       ;
    --signal  m_axis_tvalid_10 :           std_Logic                                                           ;
    --signal  m_axis_tready_10 :           std_Logic                                     := '0'                ;
    --signal  m_axis_tlast_10  :           std_Logic                                                           ;

    --signal  m_axis_tdata_11  :           std_logic_Vector ( ((N_BYTES*8)-1) downto 0 )                       ;
    --signal  m_axis_tkeep_11  :           std_logic_Vector (       N_BYTES-1 downto 0 )                       ;
    --signal  m_axis_tuser_11  :           std_Logic_Vector (               7 downto 0 )                       ;
    --signal  m_axis_tvalid_11 :           std_Logic                                                           ;
    --signal  m_axis_tready_11 :           std_Logic                                     := '0'                ;
    --signal  m_axis_tlast_11  :           std_Logic                                                           ;

    --signal  m_axis_tdata_12  :           std_logic_Vector ( ((N_BYTES*8)-1) downto 0 )                       ;
    --signal  m_axis_tkeep_12  :           std_logic_Vector (       N_BYTES-1 downto 0 )                       ;
    --signal  m_axis_tuser_12  :           std_Logic_Vector (               7 downto 0 )                       ;
    --signal  m_axis_tvalid_12 :           std_Logic                                                           ;
    --signal  m_axis_tready_12 :           std_Logic                                     := '0'                ;
    --signal  m_axis_tlast_12  :           std_Logic                                                           ;

    --signal  m_axis_tdata_13  :           std_logic_Vector ( ((N_BYTES*8)-1) downto 0 )                       ;
    --signal  m_axis_tkeep_13  :           std_logic_Vector (       N_BYTES-1 downto 0 )                       ;
    --signal  m_axis_tuser_13  :           std_Logic_Vector (               7 downto 0 )                       ;
    --signal  m_axis_tvalid_13 :           std_Logic                                                           ;
    --signal  m_axis_tready_13 :           std_Logic                                     := '0'                ;
    --signal  m_axis_tlast_13  :           std_Logic                                                           ;

    --signal  m_axis_tdata_14  :           std_logic_Vector ( ((N_BYTES*8)-1) downto 0 )                       ;
    --signal  m_axis_tkeep_14  :           std_logic_Vector (       N_BYTES-1 downto 0 )                       ;
    --signal  m_axis_tuser_14  :           std_Logic_Vector (               7 downto 0 )                       ;
    --signal  m_axis_tvalid_14 :           std_Logic                                                           ;
    --signal  m_axis_tready_14 :           std_Logic                                     := '0'                ;
    --signal  m_axis_tlast_14  :           std_Logic                                                           ;

    --signal  m_axis_tdata_15  :           std_logic_Vector ( ((N_BYTES*8)-1) downto 0 )                       ;
    --signal  m_axis_tkeep_15  :           std_logic_Vector (       N_BYTES-1 downto 0 )                       ;
    --signal  m_axis_tuser_15  :           std_Logic_Vector (               7 downto 0 )                       ;
    --signal  m_axis_tvalid_15 :           std_Logic                                                           ;
    --signal  m_axis_tready_15 :           std_Logic                                     := '0'                ;
    --signal  m_axis_tlast_15  :           std_Logic                                                           ;

    --signal  m_axis_tdata_16  :           std_logic_Vector ( ((N_BYTES*8)-1) downto 0 )                       ;
    --signal  m_axis_tkeep_16  :           std_logic_Vector (       N_BYTES-1 downto 0 )                       ;
    --signal  m_axis_tuser_16  :           std_Logic_Vector (               7 downto 0 )                       ;
    --signal  m_axis_tvalid_16 :           std_Logic                                                           ;
    --signal  m_axis_tready_16 :           std_Logic                                     := '0'                ;
    --signal  m_axis_tlast_16  :           std_Logic                                                           ;

    signal  m_axis_tdata     :           std_logic_Vector ( ((N_BYTES*8)-1) downto 0 )                       ;
    signal  m_axis_tkeep     :           std_logic_Vector (       N_BYTES-1 downto 0 )                       ;
    signal  m_axis_tuser     :           std_Logic_Vector (               7 downto 0 )                       ;
    signal  m_axis_tvalid    :           std_Logic                                                           ;
    signal  m_axis_tready    :           std_Logic                                     := '0'                ;
    signal  m_axis_tlast     :           std_Logic                                                           ;

    signal  m_axis_tdata_ctrl     :           std_logic_Vector ( ((N_BYTES*8)-1) downto 0 )                       ;
    signal  m_axis_tkeep_ctrl     :           std_logic_Vector (       N_BYTES-1 downto 0 )                       ;
    signal  m_axis_tuser_ctrl     :           std_Logic_Vector (               7 downto 0 )                       ;
    signal  m_axis_tvalid_ctrl    :           std_Logic                                                           ;
    signal  m_axis_tready_ctrl    :           std_Logic                                     := '0'                ;
    signal  m_axis_tlast_ctrl     :           std_Logic                                                           ;

    signal  scl_i_4         :           std_Logic                                     := '1'                ;
    signal  sda_i_4         :           std_Logic                                     := '1'                ;
    signal  scl_t_4         :           std_Logic                                                           ;
    signal  sda_t_4         :           std_Logic                                                           ;

    --signal  scl_i_5         :           std_Logic                                     := '0'                ;
    --signal  sda_i_5         :           std_Logic                                     := '0'                ;
    --signal  scl_t_5         :           std_Logic                                                           ;
    --signal  sda_t_5         :           std_Logic                                                           ;

    --signal  scl_i_6         :           std_Logic                                     := '0'                ;
    --signal  sda_i_6         :           std_Logic                                     := '0'                ;
    --signal  scl_t_6         :           std_Logic                                                           ;
    --signal  sda_t_6         :           std_Logic                                                           ;

    --signal  scl_i_7         :           std_Logic                                     := '0'                ;
    --signal  sda_i_7         :           std_Logic                                     := '0'                ;
    --signal  scl_t_7         :           std_Logic                                                           ;
    --signal  sda_t_7         :           std_Logic                                                           ;

    --signal  scl_i_8         :           std_Logic                                     := '0'                ;
    --signal  sda_i_8         :           std_Logic                                     := '0'                ;
    --signal  scl_t_8         :           std_Logic                                                           ;
    --signal  sda_t_8         :           std_Logic                                                           ;

    --signal  scl_i_9         :           std_Logic                                     := '0'                ;
    --signal  sda_i_9         :           std_Logic                                     := '0'                ;
    --signal  scl_t_9         :           std_Logic                                                           ;
    --signal  sda_t_9         :           std_Logic                                                           ;

    --signal  scl_i_10        :           std_Logic                                     := '0'                ;
    --signal  sda_i_10        :           std_Logic                                     := '0'                ;
    --signal  scl_t_10        :           std_Logic                                                           ;
    --signal  sda_t_10        :           std_Logic                                                           ;

    --signal  scl_i_11        :           std_Logic                                     := '0'                ;
    --signal  sda_i_11        :           std_Logic                                     := '0'                ;
    --signal  scl_t_11        :           std_Logic                                                           ;
    --signal  sda_t_11        :           std_Logic                                                           ;

    --signal  scl_i_12        :           std_Logic                                     := '0'                ;
    --signal  sda_i_12        :           std_Logic                                     := '0'                ;
    --signal  scl_t_12        :           std_Logic                                                           ;
    --signal  sda_t_12        :           std_Logic                                                           ;

    --signal  scl_i_13        :           std_Logic                                     := '0'                ;
    --signal  sda_i_13        :           std_Logic                                     := '0'                ;
    --signal  scl_t_13        :           std_Logic                                                           ;
    --signal  sda_t_13        :           std_Logic                                                           ;
    
    --signal  scl_i_14        :           std_Logic                                     := '0'                ;
    --signal  sda_i_14        :           std_Logic                                     := '0'                ;
    --signal  scl_t_14        :           std_Logic                                                           ;
    --signal  sda_t_14        :           std_Logic                                                           ;

    --signal  scl_i_15        :           std_Logic                                     := '0'                ;
    --signal  sda_i_15        :           std_Logic                                     := '0'                ;
    --signal  scl_t_15        :           std_Logic                                                           ;
    --signal  sda_t_15        :           std_Logic                                                           ;

    --signal  scl_i_16        :           std_Logic                                     := '0'                ;
    --signal  sda_i_16        :           std_Logic                                     := '0'                ;
    --signal  scl_t_16        :           std_Logic                                                           ;
    --signal  sda_t_16        :           std_Logic                                                           ;

    signal  scl_i           :           std_Logic                                     := '0'                ;
    signal  sda_i           :           std_Logic                                     := '0'                ;
    signal  scl_t           :           std_Logic                                                           ;
    signal  sda_t           :           std_Logic                                                           ;

    signal  scl_i_ctrl      :           std_Logic                                     := '0'                ;
    signal  sda_i_ctrl      :           std_Logic                                     := '0'                ;
    signal  scl_t_ctrl      :           std_Logic                                                           ;
    signal  sda_t_ctrl      :           std_Logic                                                           ;

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
            N_BYTES         =>  N_BYTES                         ,
            WRITE_CONTROL   =>  "STREAM" -- or "COUNTER"
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

    --scl_i_4 <= scl_t_4;

    m_axis_tready_4 <= '1';

    scl_i_4_processing : process(CLK)
    begin
        if CLK'event AND CLK = '1' then 
            case i is 
                when (2*53)    => scl_i_4 <= '0';
                when (2*54)+1  => scl_i_4 <= '1';
                when (2*55)+1  => scl_i_4 <= '0';
                when (2*56)+1  => scl_i_4 <= '1';
                when (2*57)+1  => scl_i_4 <= '0';
                when (2*58)+1  => scl_i_4 <= '1';
                when (2*59)+1  => scl_i_4 <= '0';
                when (2*60)+1  => scl_i_4 <= '1';
                when (2*61)+1  => scl_i_4 <= '0';
                when (2*62)+1  => scl_i_4 <= '1';
                when (2*63)+1  => scl_i_4 <= '0';
                when (2*64)+1  => scl_i_4 <= '1';
                when (2*65)+1  => scl_i_4 <= '0';
                when (2*66)+1  => scl_i_4 <= '1';
                when (2*67)+1  => scl_i_4 <= '0';
                when (2*68)+1  => scl_i_4 <= '1';
                when (2*69)+1  => scl_i_4 <= '0';
                when (2*70)+1  => scl_i_4 <= '1';
                when (2*71)+1  => scl_i_4 <= '0';
                when (2*72)+1  => scl_i_4 <= '1';
                when (2*73)+1  => scl_i_4 <= '0';
                when (2*74)+1  => scl_i_4 <= '1';
                when (2*75)+1  => scl_i_4 <= '0';
                when (2*76)+1  => scl_i_4 <= '1';
                when (2*77)+1  => scl_i_4 <= '0';
                when (2*78)+1  => scl_i_4 <= '1';
                when (2*79)+1  => scl_i_4 <= '0';
                when (2*80)+1  => scl_i_4 <= '1';
                when (2*81)+1  => scl_i_4 <= '0';
                when (2*82)+1  => scl_i_4 <= '1';
                when (2*83)+1  => scl_i_4 <= '0';
                when (2*84)+1  => scl_i_4 <= '1';
                when (2*85)+1  => scl_i_4 <= '0';
                when (2*86)+1  => scl_i_4 <= '1';
                when (2*87)+1  => scl_i_4 <= '0';
                when (2*88)+1  => scl_i_4 <= '1';
                when (2*89)+1  => scl_i_4 <= '0';
                when (2*90)+1  => scl_i_4 <= '1';
                when (2*91)+1  => scl_i_4 <= '0';
                when (2*92)+1  => scl_i_4 <= '1';
                when (2*93)+1  => scl_i_4 <= '0';
                when (2*94)+1  => scl_i_4 <= '1';
                when (2*95)+1  => scl_i_4 <= '0';
                when (2*96)+1  => scl_i_4 <= '1';
                when (2*97)+1  => scl_i_4 <= '0';
                when (2*98)+1  => scl_i_4 <= '1';
                when (2*99)+1  => scl_i_4 <= '0';
                when (2*100)+1 => scl_i_4 <= '1';
                when (2*101)+1 => scl_i_4 <= '0';
                when (2*102)+1 => scl_i_4 <= '1';
                when (2*103)+1 => scl_i_4 <= '0';
                when (2*104)+1 => scl_i_4 <= '1';
                when (2*105)+1 => scl_i_4 <= '0';
                when (2*106)+1 => scl_i_4 <= '1';
                when (2*107)+1 => scl_i_4 <= '0';
                when (2*108)+1 => scl_i_4 <= '1';
                when (2*109)+1 => scl_i_4 <= '0';
                when (2*110)+1 => scl_i_4 <= '1';
                when (2*111)+1 => scl_i_4 <= '0';
                when (2*112)+1 => scl_i_4 <= '1';
                when (2*113)+1 => scl_i_4 <= '0';
                when (2*114)+1 => scl_i_4 <= '1';
                when (2*115)+1 => scl_i_4 <= '0';
                when (2*116)+1 => scl_i_4 <= '1';
                when (2*117)+1 => scl_i_4 <= '0';
                when (2*118)+1 => scl_i_4 <= '1';
                when (2*119)+1 => scl_i_4 <= '0';
                when (2*120)+1 => scl_i_4 <= '1';
                when (2*121)+1 => scl_i_4 <= '0';
                when (2*122)+1 => scl_i_4 <= '1';
                when (2*123)+1 => scl_i_4 <= '0';
                when (2*124)+1 => scl_i_4 <= '1';
                when (2*125)+1 => scl_i_4 <= '0';
                when (2*126)+1 => scl_i_4 <= '1';
                when (2*127)+1 => scl_i_4 <= '0';
                when (2*128)+1 => scl_i_4 <= '1';
                when (2*129)+1 => scl_i_4 <= '0';
                when (2*130)+1 => scl_i_4 <= '1';
                when (2*131)+1 => scl_i_4 <= '0';
                when (2*132)+1 => scl_i_4 <= '1';
                when (2*133)+1 => scl_i_4 <= '0';
                when (2*134)+1 => scl_i_4 <= '1';
                when (2*135)+1 => scl_i_4 <= '0';
                when (2*136)+1 => scl_i_4 <= '1';
                when (2*137)+1 => scl_i_4 <= '0';
                when (2*138)+1 => scl_i_4 <= '1';
                when (2*139)+1 => scl_i_4 <= '0';
                when (2*140)+1 => scl_i_4 <= '1';
                when (2*141)+1 => scl_i_4 <= '0';
                when (2*142)+1 => scl_i_4 <= '1';
                when (2*143)+1 => scl_i_4 <= '0';
                when (2*144)+1 => scl_i_4 <= '1';
                when (2*145)+1 => scl_i_4 <= '0';
                when (2*146)+1 => scl_i_4 <= '1';
                when (2*147)+1 => scl_i_4 <= '0';
                when (2*148)+1 => scl_i_4 <= '1';
                when (2*149)+1 => scl_i_4 <= '0';
                when (2*150)+1 => scl_i_4 <= '1';
                when (2*151)+1 => scl_i_4 <= '0';
                when (2*152)+1 => scl_i_4 <= '1';
                when (2*153)+1 => scl_i_4 <= '0';
                when (2*154)+1 => scl_i_4 <= '1';
                when (2*155)+1 => scl_i_4 <= '0';
                when (2*156)+1 => scl_i_4 <= '1';
                when (2*157)+1 => scl_i_4 <= '0';
                when (2*158)+1 => scl_i_4 <= '1';
                when (2*159)+1 => scl_i_4 <= '0';
                when (2*160)+1 => scl_i_4 <= '1';
                when (2*161)+1 => scl_i_4 <= '0';
                when (2*163)   => scl_i_4 <= '1';

                when others => scl_i_4 <= scl_i_4;
            end case;
        end if;
    end process;

    sda_i_4_processing : process(CLK)
    begin
        if CLK'event AND CLK = '1' then 
            case i is 
                when 4*26    => sda_i_4 <= '0'; -- START
                when 4*27    => sda_i_4 <= '1'; -- ADDR[7]
                when 4*28    => sda_i_4 <= '0'; -- ADDR[6]
                when 4*29    => sda_i_4 <= '1'; -- ADDR[5]
                when 4*30    => sda_i_4 <= '0'; -- ADDR[4]
                when 4*31    => sda_i_4 <= '0'; -- ADDR[3]
                when 4*32    => sda_i_4 <= '1'; -- ADDR[2]
                when 4*33    => sda_i_4 <= '1'; -- ADDR[1]
                when 4*34    => sda_i_4 <= '1'; -- ADDR[0]
                when 4*35    => sda_i_4 <= '0'; -- ACK
                when 4*36    => sda_i_4 <= '0'; -- DATA[7]
                when 4*37    => sda_i_4 <= '0'; -- DATA[6]
                when 4*38    => sda_i_4 <= '0'; -- DATA[5]
                when 4*39    => sda_i_4 <= '0'; -- DATA[4]
                when 4*40    => sda_i_4 <= '0'; -- DATA[3]
                when 4*41    => sda_i_4 <= '0'; -- DATA[2]
                when 4*42    => sda_i_4 <= '0'; -- DATA[1]
                when 4*43    => sda_i_4 <= '0'; -- DATA[0]
                when 4*44    => sda_i_4 <= '0'; -- ACK
                when 4*45    => sda_i_4 <= '0'; -- DATA[7]
                when 4*46    => sda_i_4 <= '0'; -- DATA[6]
                when 4*47    => sda_i_4 <= '0'; -- DATA[5]
                when 4*48    => sda_i_4 <= '0'; -- DATA[4]
                when 4*49    => sda_i_4 <= '0'; -- DATA[3]
                when 4*50    => sda_i_4 <= '0'; -- DATA[2]
                when 4*51    => sda_i_4 <= '0'; -- DATA[1]
                when 4*52    => sda_i_4 <= '1'; -- DATA[0]
                when 4*53    => sda_i_4 <= '0'; -- ACK
                when 4*54    => sda_i_4 <= '0'; -- DATA[7]
                when 4*55    => sda_i_4 <= '0'; -- DATA[6]
                when 4*56    => sda_i_4 <= '0'; -- DATA[5]
                when 4*57    => sda_i_4 <= '0'; -- DATA[4]
                when 4*58    => sda_i_4 <= '0'; -- DATA[3]
                when 4*59    => sda_i_4 <= '0'; -- DATA[2]
                when 4*60    => sda_i_4 <= '1'; -- DATA[1]
                when 4*61    => sda_i_4 <= '0'; -- DATA[0]
                when 4*62    => sda_i_4 <= '0'; -- ACK
                when 4*63    => sda_i_4 <= '0'; -- DATA[7]
                when 4*64    => sda_i_4 <= '0'; -- DATA[6]
                when 4*65    => sda_i_4 <= '0'; -- DATA[5]
                when 4*66    => sda_i_4 <= '0'; -- DATA[4]
                when 4*67    => sda_i_4 <= '0'; -- DATA[3]
                when 4*68    => sda_i_4 <= '0'; -- DATA[2]
                when 4*69    => sda_i_4 <= '1'; -- DATA[1]
                when 4*70    => sda_i_4 <= '1'; -- DATA[0]
                when 4*71    => sda_i_4 <= '0'; -- ACK
                when 4*72    => sda_i_4 <= '0'; -- DATA[7]
                when 4*73    => sda_i_4 <= '0'; -- DATA[6]
                when 4*74    => sda_i_4 <= '0'; -- DATA[5]
                when 4*75    => sda_i_4 <= '0'; -- DATA[4]
                when 4*76    => sda_i_4 <= '0'; -- DATA[3]
                when 4*77    => sda_i_4 <= '1'; -- DATA[2]
                when 4*78    => sda_i_4 <= '0'; -- DATA[1]
                when 4*79    => sda_i_4 <= '0'; -- DATA[0]
                when 4*80    => sda_i_4 <= '1'; -- NACK
                when 4*81    => sda_i_4 <= '0'; -- STOP              
                when 4*82    => sda_i_4 <= '1'; 

                --when 4*83    => sda_i_4 <= '0'; -- START
                --when 4*84    => sda_i_4 <= '1'; -- ADDR[7]
                --when 4*85    => sda_i_4 <= '1'; -- ADDR[6]
                --when 4*86    => sda_i_4 <= '1'; -- ADDR[5]
                --when 4*87    => sda_i_4 <= '1'; -- ADDR[4]
                --when 4*88    => sda_i_4 <= '0'; -- ADDR[3]
                --when 4*89    => sda_i_4 <= '1'; -- ADDR[2]
                --when 4*90    => sda_i_4 <= '1'; -- ADDR[1]
                --when 4*91    => sda_i_4 <= '1'; -- ADDR[0]
                --when 4*92    => sda_i_4 <= '0'; -- ACK
                --when 4*93    => sda_i_4 <= '1'; -- DATA[7]
                --when 4*94    => sda_i_4 <= '0'; -- DATA[6]
                --when 4*95    => sda_i_4 <= '0'; -- DATA[5]
                --when 4*96    => sda_i_4 <= '0'; -- DATA[4]
                --when 4*97    => sda_i_4 <= '0'; -- DATA[3]
                --when 4*98    => sda_i_4 <= '0'; -- DATA[2]
                --when 4*99    => sda_i_4 <= '0'; -- DATA[1]
                --when 4*100   => sda_i_4 <= '0'; -- DATA[0]
                --when 4*101   => sda_i_4 <= '0'; -- ACK
                --when 4*102   => sda_i_4 <= '1'; -- DATA[7]
                --when 4*103   => sda_i_4 <= '0'; -- DATA[6]
                --when 4*104   => sda_i_4 <= '0'; -- DATA[5]
                --when 4*105   => sda_i_4 <= '0'; -- DATA[4]
                --when 4*106   => sda_i_4 <= '0'; -- DATA[3]
                --when 4*107   => sda_i_4 <= '0'; -- DATA[2]
                --when 4*108   => sda_i_4 <= '0'; -- DATA[1]
                --when 4*109   => sda_i_4 <= '1'; -- DATA[0]
                --when 4*110   => sda_i_4 <= '0'; -- ACK
                --when 4*111   => sda_i_4 <= '1'; -- DATA[7]
                --when 4*112   => sda_i_4 <= '0'; -- DATA[6]
                --when 4*113   => sda_i_4 <= '0'; -- DATA[5]
                --when 4*114   => sda_i_4 <= '0'; -- DATA[4]
                --when 4*115   => sda_i_4 <= '0'; -- DATA[3]
                --when 4*116   => sda_i_4 <= '0'; -- DATA[2]
                --when 4*117   => sda_i_4 <= '1'; -- DATA[1]
                --when 4*118   => sda_i_4 <= '0'; -- DATA[0]
                --when 4*119   => sda_i_4 <= '0'; -- ACK
                --when 4*120   => sda_i_4 <= '1'; -- DATA[7]
                --when 4*121   => sda_i_4 <= '0'; -- DATA[6]
                --when 4*122   => sda_i_4 <= '0'; -- DATA[5]
                --when 4*123   => sda_i_4 <= '0'; -- DATA[4]
                --when 4*124   => sda_i_4 <= '0'; -- DATA[3]
                --when 4*125   => sda_i_4 <= '0'; -- DATA[2]
                --when 4*126   => sda_i_4 <= '1'; -- DATA[1]
                --when 4*127   => sda_i_4 <= '1'; -- DATA[0]
                --when 4*128   => sda_i_4 <= '1'; -- NACK
                --when 4*129   => sda_i_4 <= '0'; -- STOP     
                --when 4*130   => sda_i_4 <= '1'; 

                when others => sda_i_4 <= sda_i_4;
            end case;
        end if;
    end process;


    s_axis_processing : process(CLK)
    begin
        if CLK'event AND CLK = '1' then 
            case i is
                when 99 => S_AXIS_TDATA <= x"00000005"; S_AXIS_TUSER <= x"A7"; S_AXIS_TKEEP <= "1111"; S_AXIS_TVALID <= '1'; S_AXIS_TLAST <= '1';
                --when 101 => S_AXIS_TDATA <= x"00000001"; S_AXIS_TUSER <= x"A9"; S_AXIS_TKEEP <= "1111"; S_AXIS_TVALID <= '1'; S_AXIS_TLAST <= '1';
                --when 100 => S_AXIS_TDATA <= x"00000008"; S_AXIS_TUSER <= x"A6"; S_AXIS_TKEEP <= x"F"; S_AXIS_TVALID <= '1'; S_AXIS_TLAST <= '0';
                --when 101 => S_AXIS_TDATA <= x"03020100"; S_AXIS_TUSER <= x"A6"; S_AXIS_TKEEP <= x"F"; S_AXIS_TVALID <= '1'; S_AXIS_TLAST <= '1';
                --when 102 => S_AXIS_TDATA <= x"07060504"; S_AXIS_TUSER <= x"A6"; S_AXIS_TKEEP <= x"F"; S_AXIS_TVALID <= '1'; S_AXIS_TLAST <= '0';                
                --when 103 => S_AXIS_TDATA <= x"0B0A0908"; S_AXIS_TUSER <= x"A6"; S_AXIS_TKEEP <= x"F"; S_AXIS_TVALID <= '1'; S_AXIS_TLAST <= '0';
                --when 104 => S_AXIS_TDATA <= x"0F0E0D0C"; S_AXIS_TUSER <= x"A6"; S_AXIS_TKEEP <= x"F"; S_AXIS_TVALID <= '1'; S_AXIS_TLAST <= '1';

                when 105 => S_AXIS_TDATA <= x"00000008"; S_AXIS_TUSER <= x"A6"; S_AXIS_TKEEP <= x"F"; S_AXIS_TVALID <= '1'; S_AXIS_TLAST <= '0';
                when 106 => S_AXIS_TDATA <= x"03020100"; S_AXIS_TUSER <= x"A6"; S_AXIS_TKEEP <= x"F"; S_AXIS_TVALID <= '1'; S_AXIS_TLAST <= '0';
                when 107 => S_AXIS_TDATA <= x"07060504"; S_AXIS_TUSER <= x"A6"; S_AXIS_TKEEP <= x"F"; S_AXIS_TVALID <= '1'; S_AXIS_TLAST <= '1';                


                when others => S_AXIS_TDATA <= S_AXIS_TDATA; S_AXIS_TUSER <= S_AXIS_TUSER; S_AXIS_TKEEP <= S_AXIS_TKEEP; S_AXIS_TVALID <= '0'; S_AXIS_TLAST <= S_AXIS_TLAST;
            end case;
        end if;
    end process;


    --axis_iic_ctrlr_inst : axis_iic_ctrlr 
    --    generic map (
    --        CLK_PERIOD      =>  100000000       ,
    --        CLK_I2C_PERIOD  =>  400000          ,
    --        N_BYTES         =>  4               ,
    --        DEPTH           =>  16               
    --    )
    --    port map  (
    --        clk             =>  clk                     ,
    --        resetn          =>  not(reset)              ,
    --        s_axis_tdata    =>  s_axis_tdata            ,
    --        s_axis_tkeep    =>  s_axis_tkeep            ,
    --        s_axis_tdest    =>  s_axis_tuser            ,
    --        s_axis_tvalid   =>  s_axis_tvalid           ,
    --        s_axis_tready   =>  open                    ,
    --        s_axis_tlast    =>  s_axis_tlast            ,
    --        m_axis_tdata    =>  m_axis_tdata_ctrl       ,
    --        m_axis_tkeep    =>  m_axis_tkeep_ctrl       ,
    --        m_axis_tdest    =>  m_axis_tuser_ctrl       ,
    --        m_axis_tvalid   =>  m_axis_tvalid_ctrl      ,
    --        m_axis_tready   =>  m_axis_tready_ctrl      ,
    --        m_axis_tlast    =>  m_axis_tlast_ctrl       ,
    --        scl_i           =>  scl_i_ctrl              ,
    --        sda_i           =>  sda_i_ctrl              ,
    --        scl_t           =>  scl_t_ctrl              ,
    --        sda_t           =>  sda_t_ctrl               
    --    );

    --sda_i_ctrl <= '0';
    --scl_i_ctrl <= scl_t_ctrl;

    --axis_iic_bridge_5_inst : axis_iic_bridge 
    --    generic map (
    --        CLK_PERIOD      =>  CLK_PERIOD                      ,
    --        CLK_I2C_PERIOD  =>  CLK_I2C_PERIOD_5                ,
    --        N_BYTES         =>  N_BYTES                          
    --    )
    --    port map  (
    --        CLK             =>  CLK                             ,
    --        reset           =>  reset                           ,
    --        s_axis_tdata    =>  s_axis_tdata                    ,
    --        s_axis_tuser    =>  s_axis_tuser                    ,
    --        s_axis_tkeep    =>  s_axis_tkeep                    ,
    --        s_axis_tvalid   =>  s_axis_tvalid                   ,
    --        s_axis_tready   =>  open                            ,
    --        s_axis_tlast    =>  s_axis_tlast                    ,
    --        m_axis_tdata    =>  m_axis_tdata_5                  ,
    --        m_axis_tkeep    =>  m_axis_tkeep_5                  ,
    --        m_axis_tuser    =>  m_axis_tuser_5                  ,
    --        m_axis_tvalid   =>  m_axis_tvalid_5                 ,
    --        m_axis_tready   =>  m_axis_tready_5                 ,
    --        m_axis_tlast    =>  m_axis_tlast_5                  ,
    --        scl_i           =>  scl_i_5                         ,
    --        sda_i           =>  sda_i_5                         ,
    --        scl_t           =>  scl_t_5                         ,
    --        sda_t           =>  sda_t_5                          
    --    );

    --axis_iic_bridge_6_inst : axis_iic_bridge 
    --    generic map (
    --        CLK_PERIOD      =>  CLK_PERIOD                      ,
    --        CLK_I2C_PERIOD  =>  CLK_I2C_PERIOD_6                ,
    --        N_BYTES         =>  N_BYTES                          
    --    )
    --    port map  (
    --        CLK             =>  CLK                             ,
    --        reset           =>  reset                           ,
    --        s_axis_tdata    =>  s_axis_tdata                    ,
    --        s_axis_tuser    =>  s_axis_tuser                    ,
    --        s_axis_tkeep    =>  s_axis_tkeep                    ,
    --        s_axis_tvalid   =>  s_axis_tvalid                   ,
    --        s_axis_tready   =>  open                            ,
    --        s_axis_tlast    =>  s_axis_tlast                    ,
    --        m_axis_tdata    =>  m_axis_tdata_6                  ,
    --        m_axis_tkeep    =>  m_axis_tkeep_6                  ,
    --        m_axis_tuser    =>  m_axis_tuser_6                  ,
    --        m_axis_tvalid   =>  m_axis_tvalid_6                 ,
    --        m_axis_tready   =>  m_axis_tready_6                 ,
    --        m_axis_tlast    =>  m_axis_tlast_6                  ,
    --        scl_i           =>  scl_i_6                         ,
    --        sda_i           =>  sda_i_6                         ,
    --        scl_t           =>  scl_t_6                         ,
    --        sda_t           =>  sda_t_6                          
    --    );

    --axis_iic_bridge_7_inst : axis_iic_bridge 
    --    generic map (
    --        CLK_PERIOD      =>  CLK_PERIOD                      ,
    --        CLK_I2C_PERIOD  =>  CLK_I2C_PERIOD_7                ,
    --        N_BYTES         =>  N_BYTES                          
    --    )
    --    port map  (
    --        CLK             =>  CLK                             ,
    --        reset           =>  reset                           ,
    --        s_axis_tdata    =>  s_axis_tdata                    ,
    --        s_axis_tuser    =>  s_axis_tuser                    ,
    --        s_axis_tkeep    =>  s_axis_tkeep                    ,
    --        s_axis_tvalid   =>  s_axis_tvalid                   ,
    --        s_axis_tready   =>  open                            ,
    --        s_axis_tlast    =>  s_axis_tlast                    ,
    --        m_axis_tdata    =>  m_axis_tdata_7                  ,
    --        m_axis_tkeep    =>  m_axis_tkeep_7                  ,
    --        m_axis_tuser    =>  m_axis_tuser_7                  ,
    --        m_axis_tvalid   =>  m_axis_tvalid_7                 ,
    --        m_axis_tready   =>  m_axis_tready_7                 ,
    --        m_axis_tlast    =>  m_axis_tlast_7                  ,
    --        scl_i           =>  scl_i_7                         ,
    --        sda_i           =>  sda_i_7                         ,
    --        scl_t           =>  scl_t_7                         ,
    --        sda_t           =>  sda_t_7                          
    --    );

    --axis_iic_bridge_8_inst : axis_iic_bridge 
    --    generic map (
    --        CLK_PERIOD      =>  CLK_PERIOD                      ,
    --        CLK_I2C_PERIOD  =>  CLK_I2C_PERIOD_8                ,
    --        N_BYTES         =>  N_BYTES                          
    --    )
    --    port map  (
    --        CLK             =>  CLK                             ,
    --        reset           =>  reset                           ,
    --        s_axis_tdata    =>  s_axis_tdata                    ,
    --        s_axis_tuser    =>  s_axis_tuser                    ,
    --        s_axis_tkeep    =>  s_axis_tkeep                    ,
    --        s_axis_tvalid   =>  s_axis_tvalid                   ,
    --        s_axis_tready   =>  open                            ,
    --        s_axis_tlast    =>  s_axis_tlast                    ,
    --        m_axis_tdata    =>  m_axis_tdata_8                  ,
    --        m_axis_tkeep    =>  m_axis_tkeep_8                  ,
    --        m_axis_tuser    =>  m_axis_tuser_8                  ,
    --        m_axis_tvalid   =>  m_axis_tvalid_8                 ,
    --        m_axis_tready   =>  m_axis_tready_8                 ,
    --        m_axis_tlast    =>  m_axis_tlast_8                  ,
    --        scl_i           =>  scl_i_8                         ,
    --        sda_i           =>  sda_i_8                         ,
    --        scl_t           =>  scl_t_8                         ,
    --        sda_t           =>  sda_t_8                          
    --    );

    --axis_iic_bridge_9_inst : axis_iic_bridge 
    --    generic map (
    --        CLK_PERIOD      =>  CLK_PERIOD                      ,
    --        CLK_I2C_PERIOD  =>  CLK_I2C_PERIOD_9                ,
    --        N_BYTES         =>  N_BYTES                          
    --    )
    --    port map  (
    --        CLK             =>  CLK                             ,
    --        reset           =>  reset                           ,
    --        s_axis_tdata    =>  s_axis_tdata                    ,
    --        s_axis_tuser    =>  s_axis_tuser                    ,
    --        s_axis_tkeep    =>  s_axis_tkeep                    ,
    --        s_axis_tvalid   =>  s_axis_tvalid                   ,
    --        s_axis_tready   =>  open                            ,
    --        s_axis_tlast    =>  s_axis_tlast                    ,
    --        m_axis_tdata    =>  m_axis_tdata_9                  ,
    --        m_axis_tkeep    =>  m_axis_tkeep_9                  ,
    --        m_axis_tuser    =>  m_axis_tuser_9                  ,
    --        m_axis_tvalid   =>  m_axis_tvalid_9                 ,
    --        m_axis_tready   =>  m_axis_tready_9                 ,
    --        m_axis_tlast    =>  m_axis_tlast_9                  ,
    --        scl_i           =>  scl_i_9                         ,
    --        sda_i           =>  sda_i_9                         ,
    --        scl_t           =>  scl_t_9                         ,
    --        sda_t           =>  sda_t_9                          
    --    );

    --axis_iic_bridge_10_inst : axis_iic_bridge 
    --    generic map (
    --        CLK_PERIOD      =>  CLK_PERIOD                      ,
    --        CLK_I2C_PERIOD  =>  CLK_I2C_PERIOD_10               ,
    --        N_BYTES         =>  N_BYTES                          
    --    )
    --    port map  (
    --        CLK             =>  CLK                             ,
    --        reset           =>  reset                           ,
    --        s_axis_tdata    =>  s_axis_tdata                    ,
    --        s_axis_tuser    =>  s_axis_tuser                    ,
    --        s_axis_tkeep    =>  s_axis_tkeep                    ,
    --        s_axis_tvalid   =>  s_axis_tvalid                   ,
    --        s_axis_tready   =>  open                            ,
    --        s_axis_tlast    =>  s_axis_tlast                    ,
    --        m_axis_tdata    =>  m_axis_tdata_10                 ,
    --        m_axis_tkeep    =>  m_axis_tkeep_10                 ,
    --        m_axis_tuser    =>  m_axis_tuser_10                 ,
    --        m_axis_tvalid   =>  m_axis_tvalid_10                ,
    --        m_axis_tready   =>  m_axis_tready_10                ,
    --        m_axis_tlast    =>  m_axis_tlast_10                 ,
    --        scl_i           =>  scl_i_10                        ,
    --        sda_i           =>  sda_i_10                        ,
    --        scl_t           =>  scl_t_10                        ,
    --        sda_t           =>  sda_t_10                         
    --    );

    --axis_iic_bridge_11_inst : axis_iic_bridge 
    --    generic map (
    --        CLK_PERIOD      =>  CLK_PERIOD                      ,
    --        CLK_I2C_PERIOD  =>  CLK_I2C_PERIOD_11               ,
    --        N_BYTES         =>  N_BYTES                          
    --    )
    --    port map  (
    --        CLK             =>  CLK                             ,
    --        reset           =>  reset                           ,
    --        s_axis_tdata    =>  s_axis_tdata                    ,
    --        s_axis_tuser    =>  s_axis_tuser                    ,
    --        s_axis_tkeep    =>  s_axis_tkeep                    ,
    --        s_axis_tvalid   =>  s_axis_tvalid                   ,
    --        s_axis_tready   =>  open                            ,
    --        s_axis_tlast    =>  s_axis_tlast                    ,
    --        m_axis_tdata    =>  m_axis_tdata_11                 ,
    --        m_axis_tkeep    =>  m_axis_tkeep_11                 ,
    --        m_axis_tuser    =>  m_axis_tuser_11                 ,
    --        m_axis_tvalid   =>  m_axis_tvalid_11                ,
    --        m_axis_tready   =>  m_axis_tready_11                ,
    --        m_axis_tlast    =>  m_axis_tlast_11                 ,
    --        scl_i           =>  scl_i_11                        ,
    --        sda_i           =>  sda_i_11                        ,
    --        scl_t           =>  scl_t_11                        ,
    --        sda_t           =>  sda_t_11                         
    --    );

    --axis_iic_bridge_12_inst : axis_iic_bridge 
    --    generic map (
    --        CLK_PERIOD      =>  CLK_PERIOD                      ,
    --        CLK_I2C_PERIOD  =>  CLK_I2C_PERIOD_12               ,
    --        N_BYTES         =>  N_BYTES                          
    --    )
    --    port map  (
    --        CLK             =>  CLK                             ,
    --        reset           =>  reset                           ,
    --        s_axis_tdata    =>  s_axis_tdata                    ,
    --        s_axis_tuser    =>  s_axis_tuser                    ,
    --        s_axis_tkeep    =>  s_axis_tkeep                    ,
    --        s_axis_tvalid   =>  s_axis_tvalid                   ,
    --        s_axis_tready   =>  open                            ,
    --        s_axis_tlast    =>  s_axis_tlast                    ,
    --        m_axis_tdata    =>  m_axis_tdata_12                 ,
    --        m_axis_tkeep    =>  m_axis_tkeep_12                 ,
    --        m_axis_tuser    =>  m_axis_tuser_12                 ,
    --        m_axis_tvalid   =>  m_axis_tvalid_12                ,
    --        m_axis_tready   =>  m_axis_tready_12                ,
    --        m_axis_tlast    =>  m_axis_tlast_12                 ,
    --        scl_i           =>  scl_i_12                        ,
    --        sda_i           =>  sda_i_12                        ,
    --        scl_t           =>  scl_t_12                        ,
    --        sda_t           =>  sda_t_12                         
    --    );

    --axis_iic_bridge_13_inst : axis_iic_bridge 
    --    generic map (
    --        CLK_PERIOD      =>  CLK_PERIOD                      ,
    --        CLK_I2C_PERIOD  =>  CLK_I2C_PERIOD_13               ,
    --        N_BYTES         =>  N_BYTES                          
    --    )
    --    port map  (
    --        CLK             =>  CLK                             ,
    --        reset           =>  reset                           ,
    --        s_axis_tdata    =>  s_axis_tdata                    ,
    --        s_axis_tuser    =>  s_axis_tuser                    ,
    --        s_axis_tkeep    =>  s_axis_tkeep                    ,
    --        s_axis_tvalid   =>  s_axis_tvalid                   ,
    --        s_axis_tready   =>  open                            ,
    --        s_axis_tlast    =>  s_axis_tlast                    ,
    --        m_axis_tdata    =>  m_axis_tdata_13                 ,
    --        m_axis_tkeep    =>  m_axis_tkeep_13                 ,
    --        m_axis_tuser    =>  m_axis_tuser_13                 ,
    --        m_axis_tvalid   =>  m_axis_tvalid_13                ,
    --        m_axis_tready   =>  m_axis_tready_13                ,
    --        m_axis_tlast    =>  m_axis_tlast_13                 ,
    --        scl_i           =>  scl_i_13                        ,
    --        sda_i           =>  sda_i_13                        ,
    --        scl_t           =>  scl_t_13                        ,
    --        sda_t           =>  sda_t_13                         
    --    );

    --axis_iic_bridge_14_inst : axis_iic_bridge 
    --    generic map (
    --        CLK_PERIOD      =>  CLK_PERIOD                      ,
    --        CLK_I2C_PERIOD  =>  CLK_I2C_PERIOD_14               ,
    --        N_BYTES         =>  N_BYTES                          
    --    )
    --    port map  (
    --        CLK             =>  CLK                             ,
    --        reset           =>  reset                           ,
    --        s_axis_tdata    =>  s_axis_tdata                    ,
    --        s_axis_tuser    =>  s_axis_tuser                    ,
    --        s_axis_tkeep    =>  s_axis_tkeep                    ,
    --        s_axis_tvalid   =>  s_axis_tvalid                   ,
    --        s_axis_tready   =>  open                            ,
    --        s_axis_tlast    =>  s_axis_tlast                    ,
    --        m_axis_tdata    =>  m_axis_tdata_14                 ,
    --        m_axis_tkeep    =>  m_axis_tkeep_14                 ,
    --        m_axis_tuser    =>  m_axis_tuser_14                 ,
    --        m_axis_tvalid   =>  m_axis_tvalid_14                ,
    --        m_axis_tready   =>  m_axis_tready_14                ,
    --        m_axis_tlast    =>  m_axis_tlast_14                 ,
    --        scl_i           =>  scl_i_14                        ,
    --        sda_i           =>  sda_i_14                        ,
    --        scl_t           =>  scl_t_14                        ,
    --        sda_t           =>  sda_t_14                         
    --    );

    --axis_iic_bridge_15_inst : axis_iic_bridge 
    --    generic map (
    --        CLK_PERIOD      =>  CLK_PERIOD                      ,
    --        CLK_I2C_PERIOD  =>  CLK_I2C_PERIOD_15               ,
    --        N_BYTES         =>  N_BYTES                          
    --    )
    --    port map  (
    --        CLK             =>  CLK                             ,
    --        reset           =>  reset                           ,
    --        s_axis_tdata    =>  s_axis_tdata                    ,
    --        s_axis_tuser    =>  s_axis_tuser                    ,
    --        s_axis_tkeep    =>  s_axis_tkeep                    ,
    --        s_axis_tvalid   =>  s_axis_tvalid                   ,
    --        s_axis_tready   =>  open                            ,
    --        s_axis_tlast    =>  s_axis_tlast                    ,
    --        m_axis_tdata    =>  m_axis_tdata_15                 ,
    --        m_axis_tkeep    =>  m_axis_tkeep_15                 ,
    --        m_axis_tuser    =>  m_axis_tuser_15                 ,
    --        m_axis_tvalid   =>  m_axis_tvalid_15                ,
    --        m_axis_tready   =>  m_axis_tready_15                ,
    --        m_axis_tlast    =>  m_axis_tlast_15                 ,
    --        scl_i           =>  scl_i_15                        ,
    --        sda_i           =>  sda_i_15                        ,
    --        scl_t           =>  scl_t_15                        ,
    --        sda_t           =>  sda_t_15                         
    --    );

    --axis_iic_bridge_16_inst : axis_iic_bridge 
    --    generic map (
    --        CLK_PERIOD      =>  CLK_PERIOD                      ,
    --        CLK_I2C_PERIOD  =>  CLK_I2C_PERIOD_16               ,
    --        N_BYTES         =>  N_BYTES                          
    --    )
    --    port map  (
    --        CLK             =>  CLK                             ,
    --        reset           =>  reset                           ,
    --        s_axis_tdata    =>  s_axis_tdata                    ,
    --        s_axis_tuser    =>  s_axis_tuser                    ,
    --        s_axis_tkeep    =>  s_axis_tkeep                    ,
    --        s_axis_tvalid   =>  s_axis_tvalid                   ,
    --        s_axis_tready   =>  open                            ,
    --        s_axis_tlast    =>  s_axis_tlast                    ,
    --        m_axis_tdata    =>  m_axis_tdata_16                 ,
    --        m_axis_tkeep    =>  m_axis_tkeep_16                 ,
    --        m_axis_tuser    =>  m_axis_tuser_16                 ,
    --        m_axis_tvalid   =>  m_axis_tvalid_16                ,
    --        m_axis_tready   =>  m_axis_tready_16                ,
    --        m_axis_tlast    =>  m_axis_tlast_16                 ,
    --        scl_i           =>  scl_i_16                        ,
    --        sda_i           =>  sda_i_16                        ,
    --        scl_t           =>  scl_t_16                        ,
    --        sda_t           =>  sda_t_16                         
    --    );

    axis_iic_bridge_inst : axis_iic_bridge 
        generic map (
            CLK_PERIOD      =>  CLK_PERIOD                      ,
            CLK_I2C_PERIOD  =>  CLK_I2C_PERIOD                  ,
            N_BYTES         =>  N_BYTES                         ,
            WRITE_CONTROL   =>  "STREAM" -- or "COUNTER"
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

    scl_i <= scl_t;

    m_axis_tready <= '1';

    sda_i_processing : process(CLK)
    begin
        if CLK'event AND CLK = '1' then 
            case i is 
                when 250*1    => sda_i <= '0'; -- START
                when 250*2    => sda_i <= '1'; -- ADDR[7]
                when 250*3    => sda_i <= '0'; -- ADDR[6]
                when 250*4    => sda_i <= '1'; -- ADDR[5]
                when 250*5    => sda_i <= '0'; -- ADDR[4]
                when 250*6    => sda_i <= '0'; -- ADDR[3]
                when 250*7    => sda_i <= '1'; -- ADDR[2]
                when 250*8    => sda_i <= '1'; -- ADDR[1]
                when 250*9    => sda_i <= '1'; -- ADDR[0]
                when 250*10   => sda_i <= '0'; -- ACK
                when 250*11   => sda_i <= '0'; -- DATA[7]
                when 250*12   => sda_i <= '0'; -- DATA[6]
                when 250*13   => sda_i <= '0'; -- DATA[5]
                when 250*14   => sda_i <= '0'; -- DATA[4]
                when 250*15   => sda_i <= '0'; -- DATA[3]
                when 250*16   => sda_i <= '0'; -- DATA[2]
                when 250*17   => sda_i <= '0'; -- DATA[1]
                when 250*18   => sda_i <= '0'; -- DATA[0]
                when 250*19   => sda_i <= '0'; -- ACK
                when 250*20   => sda_i <= '0'; -- DATA[7]
                when 250*21   => sda_i <= '0'; -- DATA[6]
                when 250*22   => sda_i <= '0'; -- DATA[5]
                when 250*23   => sda_i <= '0'; -- DATA[4]
                when 250*24   => sda_i <= '0'; -- DATA[3]
                when 250*25   => sda_i <= '0'; -- DATA[2]
                when 250*26   => sda_i <= '0'; -- DATA[1]
                when 250*27   => sda_i <= '1'; -- DATA[0]
                when 250*28   => sda_i <= '0'; -- ACK
                when 250*29   => sda_i <= '0'; -- DATA[7]
                when 250*30   => sda_i <= '0'; -- DATA[6]
                when 250*31   => sda_i <= '0'; -- DATA[5]
                when 250*32   => sda_i <= '0'; -- DATA[4]
                when 250*33   => sda_i <= '0'; -- DATA[3]
                when 250*34   => sda_i <= '0'; -- DATA[2]
                when 250*35   => sda_i <= '1'; -- DATA[1]
                when 250*36   => sda_i <= '0'; -- DATA[0]
                when 250*37   => sda_i <= '0'; -- ACK
                when 250*38   => sda_i <= '0'; -- DATA[7]
                when 250*39   => sda_i <= '0'; -- DATA[6]
                when 250*40   => sda_i <= '0'; -- DATA[5]
                when 250*41   => sda_i <= '0'; -- DATA[4]
                when 250*42   => sda_i <= '0'; -- DATA[3]
                when 250*43   => sda_i <= '0'; -- DATA[2]
                when 250*44   => sda_i <= '1'; -- DATA[1]
                when 250*45   => sda_i <= '1'; -- DATA[0]
                when 250*46   => sda_i <= '0'; -- ACK
                when 250*47   => sda_i <= '0'; -- DATA[7]
                when 250*48   => sda_i <= '0'; -- DATA[6]
                when 250*49   => sda_i <= '0'; -- DATA[5]
                when 250*50   => sda_i <= '0'; -- DATA[4]
                when 250*51   => sda_i <= '0'; -- DATA[3]
                when 250*52   => sda_i <= '1'; -- DATA[2]
                when 250*53   => sda_i <= '0'; -- DATA[1]
                when 250*54   => sda_i <= '0'; -- DATA[0]
                when 250*55   => sda_i <= '1'; -- NACK
                when 250*56   => sda_i <= '0'; -- STOP              
                when 250*57   => sda_i <= '1'; 
                when others => sda_i <= sda_i;
            end case;
        end if;
    end process;



end architecture;