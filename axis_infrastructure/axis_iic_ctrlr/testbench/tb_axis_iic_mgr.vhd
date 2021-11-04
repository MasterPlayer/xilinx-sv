
library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use ieee.std_logic_unsigned.all;
    use ieee.std_logic_arith.all;

    use ieee.std_logic_textio.all;
    use std.textio.all;


library UNISIM;
    use UNISIM.VComponents.all;

entity tb_axis_iic_mgr is
end tb_axis_iic_mgr;



architecture Behavioral of tb_axis_iic_mgr is

    constant N_BYTES : integer := 4     ;


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
    
    signal  resetn          :       std_logic                                       := '0'               ;

    signal  s_axis_tdata    :       std_logic_vector ( ((N_BYTES*8)-1) downto 0 )   := (others => '0')   ;
    signal  s_axis_tkeep    :       std_logic_vector (         N_BYTES-1 downto 0 ) := (others => '0')   ;
    signal  s_axis_tdest    :       std_logic_vector (                 7 downto 0 ) := (others => '0')   ;
    signal  s_axis_tvalid   :       std_logic                                       := '0'               ;
    signal  s_axis_tready   :       std_logic                                                            ;
    signal  s_axis_tlast    :       std_logic                                       := '0'               ;

    signal  m_axis_tdata    :       std_logic_vector ( ((N_BYTES*8)-1) downto 0 )                        ;
    signal  m_axis_tkeep    :       std_logic_vector (         N_BYTES-1 downto 0 )                      ;
    signal  m_axis_tdest    :       std_logic_vector (                 7 downto 0 )                      ;
    signal  m_axis_tvalid   :       std_logic                                                            ;
    signal  m_axis_tready   :       std_logic                                       := '0'               ;
    signal  m_axis_tlast    :       std_logic                                                            ;

    signal  SCL_I           :       std_logic                                       := '0'                  ;
    signal  SDA_I           :       std_logic                                       := '0'                  ;
    signal  SCL_T           :       std_logic                                                               ;
    signal  SDA_T           :       std_logic                                                               ;

    signal  clk             :       std_logic                                       := '0'                  ;

    constant clk_period : time := 10 ns;
    constant clk_i2c_period : time := 2500 ns;

    signal  i : integer := 0;

begin

    CLK <= not CLK after clk_period/2;

    i_processing : process(CLK)
    begin
        if CLK'event AND CLK = '1' then 
            i <= i + 1;
        end if;
    end process;

    resetn <= '0' when i < 800 else '1';


    axis_iic_ctrlr_inst : axis_iic_ctrlr 
        generic map (
            CLK_PERIOD      =>  100000000       ,
            CLK_I2C_PERIOD  =>  400000          ,
            N_BYTES         =>  4               ,
            DEPTH           =>  16               
        )
        port map  (
            clk             =>  clk             ,
            resetn          =>  resetn          ,
            s_axis_tdata    =>  s_axis_tdata    ,
            s_axis_tkeep    =>  s_axis_tkeep    ,
            s_axis_tdest    =>  s_axis_tdest    ,
            s_axis_tvalid   =>  s_axis_tvalid   ,
            s_axis_tready   =>  s_axis_tready   ,
            s_axis_tlast    =>  s_axis_tlast    ,
            m_axis_tdata    =>  m_axis_tdata    ,
            m_axis_tkeep    =>  m_axis_tkeep    ,
            m_axis_tdest    =>  m_axis_tdest    ,
            m_axis_tvalid   =>  m_axis_tvalid   ,
            m_axis_tready   =>  '1'             ,
            m_axis_tlast    =>  m_axis_tlast    ,
            scl_i           =>  scl_i           ,
            sda_i           =>  sda_i           ,
            scl_t           =>  scl_t           ,
            sda_t           =>  sda_t            
        );
    
    --SCL_I <= SCL_T;

    m_axis_tready <= '1';

    sda_i_processing : process(CLK)
    begin
        if CLK'event AND CLK = '1' then 
            case i is 
                when 0 => SDA_I <= '1';
                
                when (1062 + (250* 0)) => SDA_I <= '0';

                when (1062 + (250* 1)) => SDA_I <= '1';
                when (1062 + (250* 2)) => SDA_I <= '0';
                when (1062 + (250* 3)) => SDA_I <= '1';
                when (1062 + (250* 4)) => SDA_I <= '0';
                when (1062 + (250* 5)) => SDA_I <= '0';
                when (1062 + (250* 6)) => SDA_I <= '1';
                when (1062 + (250* 7)) => SDA_I <= '1';
                when (1062 + (250* 8)) => SDA_I <= '1';
                
                when (1062 + (250* 9)) => SDA_I <= '0';

                when (1062 + (250*10)) => SDA_I <= '1';
                when (1062 + (250*11)) => SDA_I <= '1';
                when (1062 + (250*12)) => SDA_I <= '1';
                when (1062 + (250*13)) => SDA_I <= '1';
                when (1062 + (250*14)) => SDA_I <= '1';
                when (1062 + (250*15)) => SDA_I <= '0';
                when (1062 + (250*16)) => SDA_I <= '0';
                when (1062 + (250*17)) => SDA_I <= '0';

                when (1062 + (250*18)) => SDA_I <= '0';

                when (1062 + (250*19)) => SDA_I <= '1';
                when (1062 + (250*20)) => SDA_I <= '1';
                when (1062 + (250*21)) => SDA_I <= '1';
                when (1062 + (250*22)) => SDA_I <= '1';
                when (1062 + (250*23)) => SDA_I <= '1';
                when (1062 + (250*24)) => SDA_I <= '1';
                when (1062 + (250*25)) => SDA_I <= '1';

                when (1062 + (250*26)) => SDA_I <= '0';

                when (1062 + (250*27)) => SDA_I <= '0';
                when (1062 + (250*28)) => SDA_I <= '0';
                when (1062 + (250*29)) => SDA_I <= '0';
                when (1062 + (250*30)) => SDA_I <= '0';
                when (1062 + (250*31)) => SDA_I <= '0';
                when (1062 + (250*32)) => SDA_I <= '0';
                when (1062 + (250*33)) => SDA_I <= '1';
                when (1062 + (250*34)) => SDA_I <= '0';
                
                when (1062 + (250*35)) => SDA_I <= '0';

                when (1062 + (250*36)) => SDA_I <= '0';
                when (1062 + (250*37)) => SDA_I <= '1';
                when (1062 + (250*38)) => SDA_I <= '0';
                when (1062 + (250*39)) => SDA_I <= '0';
                when (1062 + (250*40)) => SDA_I <= '0';
                when (1062 + (250*41)) => SDA_I <= '0';
                when (1062 + (250*42)) => SDA_I <= '0';
                when (1062 + (250*43)) => SDA_I <= '0';
                
                when (1062 + (250*44)) => SDA_I <= '0';

                when (1062 + (250*45)) => SDA_I <= '1';
                when (1062 + (250*46)) => SDA_I <= '1';
                when (1062 + (250*47)) => SDA_I <= '1';
                when (1062 + (250*48)) => SDA_I <= '0';
                when (1062 + (250*49)) => SDA_I <= '1';
                when (1062 + (250*50)) => SDA_I <= '0';
                when (1062 + (250*51)) => SDA_I <= '1';
                when (1062 + (250*52)) => SDA_I <= '0';
                
                when (1062 + (250*53)) => SDA_I <= '0';

                when (1062 + (250*54)) => SDA_I <= '0';
                when (1062 + (250*55)) => SDA_I <= '0';
                when (1062 + (250*56)) => SDA_I <= '0';
                when (1062 + (250*57)) => SDA_I <= '0';
                when (1062 + (250*58)) => SDA_I <= '0';
                when (1062 + (250*59)) => SDA_I <= '0';
                when (1062 + (250*60)) => SDA_I <= '0';
                when (1062 + (250*61)) => SDA_I <= '0';
                
                when (1062 + (250*62)) => SDA_I <= '1';

                when (1062 + (250*63)) => SDA_I <= '0';
                when (1062 + (250*64)) => SDA_I <= '1';
                when (1062 + (250*65)) => SDA_I <= '1';
                
                when others =>
                    SDA_I <= SDA_I;
            end case;
        end if;
    end process;

    SCL_I <= SCL_T;



end Behavioral;



