
library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use ieee.std_logic_unsigned.all;
    use ieee.std_logic_arith.all;
    use IEEE.math_real."ceil";
    use IEEE.math_real."log2";

library UNISIM;
    use UNISIM.VComponents.all;

entity axi_memory_writer_func is
    generic (
        DATA_WIDTH          :           integer := 32                                       ;
        ADDR_WIDTH          :           integer := 32                                       ;
        BURST_LIMIT         :           integer := 16                                       ;
        FREQ_HZ             :           integer := 250000000                                 
    );
    port (
        CLK                 :   in      std_logic                                           ;
        RESET               :   in      std_logic                                           ;

        PORTION_SIZE        :   in      std_logic_Vector ( 31 downto 0 )                    ;
        MEM_STARTADDR       :   in      std_logic_Vector ( ADDR_WIDTH-1 downto 0 )          ;
        MEM_HIGHADDR        :   in      std_logic_vector ( ADDR_WIDTH-1 downto 0 )          ;
        RUN_SIGNAL          :   in      std_logic                                           ;
        STOP_SIGNAL         :   in      std_logic                                           ;
        CURRENT_BASEADDR    :   out     std_logic_Vector ( ADDR_WIDTH-1 downto 0 )          ;

        VALID_COUNTER       :   out     std_logic_vector ( 31 downto 0 )                    ;
        STATUS              :   out     std_logic                                           ;
        SUSPEND_ACTIVE      :   out     std_logic                                           ;

        -- interrupts vector
        FIFO_NOT_EMPTY      :   out     std_logic                                           ;
        FIFO_WREN           :   out     std_logic                                           ;
        FIFO_RDEN           :   in      std_logic                                           ;

        QUEUE_VOLUME        :   out     std_logic_Vector ( 31 downto 0 )                    ;
        QUEUE_OVERFLOW      :   out     std_logic                                           ;

        S_AXIS_TDATA        :   in      std_logic_vector ( DATA_WIDTH-1 downto 0 )          ;
        S_AXIS_TVALID       :   in      std_logic                                           ;
        S_AXIS_TLAST        :   in      std_Logic                                           ;
        S_AXIS_TREADY       :   out     std_logic                                           ;

        M_AXI_AWADDR        :   out     std_logic_vector ( ADDR_WIDTH-1 downto 0 )          ;
        M_AXI_AWLEN         :   out     std_logic_vector (  7 downto 0 )                    ;
        M_AXI_AWSIZE        :   out     std_logic_vector (  2 downto 0 )                    ;
        M_AXI_AWBURST       :   out     std_logic_vector (  1 downto 0 )                    ;
        M_AXI_AWLOCK        :   out     std_logic                                           ;
        M_AXI_AWCACHE       :   out     std_logic_vector (  3 downto 0 )                    ;
        M_AXI_AWPROT        :   out     std_logic_vector (  2 downto 0 )                    ;
        M_AXI_AWVALID       :   out     std_logic                                           ;
        M_AXI_AWREADY       :   in      std_logic                                           ;

        M_AXI_WDATA         :   out     std_logic_vector ( DATA_WIDTH-1 downto 0 )          ;
        M_AXI_WSTRB         :   out     std_logic_vector ( (DATA_WIDTH/8)-1 downto 0 )      ;
        M_AXI_WLAST         :   out     std_logic                                           ;
        M_AXI_WVALID        :   out     std_logic                                           ;
        M_AXI_WREADY        :   in      std_logic                                           ;

        M_AXI_BRESP         :   in      std_logic_vector (  1 downto 0 )                    ;
        M_AXI_BVALID        :   in      std_logic                                           ;
        M_AXI_BREADY        :   out     std_logic                                            
    );
end axi_memory_writer_func;



architecture axi_memory_writer_func_arch of axi_memory_writer_func is

    function clogb2 (bit_depth : integer) return integer is            
        variable depth  : integer := bit_depth;                               
        variable count  : integer := 1;                                       
    begin                                                                   
        for clogb2 in 1 to bit_depth loop  -- Works for up to 32 bit integers
            if (bit_depth <= 2) then                                           
                count := 1;                                                      
            else                                                               
                if(depth <= 1) then                                              
                    count := count;                                                
                else                                                             
                    depth := depth / 2;                                            
                    count := count + 1;                                            
                end if;                                                          
            end if;                                                            
        end loop;                                                             
        return(count);                                                         
    end;                               

    function get_fifo_size(burst_len : integer ) return integer is
        variable depth : integer := 16;
    begin
        if burst_len <= 16 then
            depth := 16 * 2;
        else
            depth := burst_len * 2;
        end if;
        return(depth);
    end;

    constant  FIFO_DEPTH                :           integer                                     := get_fifo_size(BURST_LIMIT);


    constant  C_AXSIZE_INT              :           integer                                     := clogb2((DATA_WIDTH/8)-1);

    constant  C_AXSIZE_SHIFT            :           std_logic_Vector ( C_AXSIZE_INT-1 downto 0 ):= (others => '0');
    constant  C_AXADDR_INCREMENT_VEC    :           std_logic_Vector ( ADDR_WIDTH-1 downto 0 )  := conv_std_logic_Vector ( BURST_LIMIT, (ADDR_WIDTH-C_AXSIZE_INT)) & C_AXSIZE_SHIFT;

    --constant CALC_LIMIT                 :           std_Logic_Vector ( 15 downto 0 )            := x"0003"                      ;


    component fifo_in_sync_counted_xpm
        generic(
            DATA_WIDTH                  :           integer         :=  16                                                  ;
            MEMTYPE                     :           String          :=  "block"                                             ;
            DEPTH                       :           integer         :=  16                                                   
        );
        port(
            CLK                         :   in      std_logic                                                               ;
            RESET                       :   in      std_logic                                                               ;
            
            S_AXIS_TDATA                :   in      std_logic_Vector ( DATA_WIDTH-1 downto 0 )                              ;
            S_AXIS_TVALID               :   in      std_logic                                                               ;
            S_AXIS_TLAST                :   in      std_logic                                                               ;
            S_AXIS_TREADY               :   out     std_logic                                                               ;

            IN_DOUT_DATA                :   out     std_logic_Vector ( DATA_WIDTH-1 downto 0 )                              ;
            IN_DOUT_LAST                :   out     std_logic                                                               ;
            IN_RDEN                     :   in      std_logic                                                               ;
            IN_EMPTY                    :   out     std_logic                                                               ;

            DATA_COUNT                  :   out     std_logic_Vector ( 31 downto 0 )                                         
        );
    end component;

    signal  fifo_reset                  :           std_logic                                        := '0'                 ;

    signal  write_ability               :           std_logic                                        := '0'                 ;

    signal  in_dout_data                :           std_logic_Vector ( DATA_WIDTH-1 downto 0 )                              ;
    signal  in_dout_last                :           std_logic                                                               ;
    signal  in_rden                     :           std_logic                                        := '0'                 ;
    signal  in_empty                    :           std_logic                                                               ;

    signal  fifo_data_count             :           std_logic_Vector ( 31 downto 0 )                                        ;
    signal  fifo_word_count             :           std_logic_Vector ( 31 downto 0 )                                        ;
    
    type fsm is(
        IDLE_ST                         ,
        --WAIT_FOR_CALC_ST                ,
        WAIT_FOR_DATA_ST                ,
        WRITE_ST                        ,
        WRITE_WAIT_BRESP_ST             ,
        PAUSE_ST                        
    );
    
    signal  current_state               :           fsm                                             := IDLE_ST              ;

    signal  m_axi_awaddr_reg            :           std_logic_vector ( ADDR_WIDTH-1 downto 0 )      := (others => '0')      ;
    signal  m_axi_awlen_reg             :           std_logic_vector (  7 downto 0 )                := (others => '0')      ;
    signal  m_axi_awsize_reg            :           std_logic_vector (  2 downto 0 )                := (others => '0')      ;
    signal  m_axi_awburst_reg           :           std_logic_vector (  1 downto 0 )                := (others => '0')      ;
    signal  m_axi_awvalid_reg           :           std_logic                                       := '0'                  ;

    signal  m_axi_wdata_reg             :           std_logic_vector ( DATA_WIDTH-1 downto 0 )      := (others => '0')      ;
    signal  m_axi_wstrb_reg             :           std_logic_vector ( (DATA_WIDTH/8)-1 downto 0 )  := (others => '0')      ;
    signal  m_axi_wlast_reg             :           std_logic                                                               ;
    signal  m_axi_wvalid_reg            :           std_logic                                                               ;

    signal  m_axi_bready_reg            :           std_logic                                       := '0'                  ;

    signal  awburst_counter             :           std_logic_Vector ( 7 downto 0 )                 := (others => '0')      ;
    signal  word_counter                :           std_logic_vector ( 31 downto 0 )                := (others => '0')      ;
    signal  awlen_reg                   :           std_logic_vector (  8 downto 0 )                := (others => '0')      ;

    signal  has_bresp_flaq              :           std_logic                                       := '0';

    signal  has_stop_initiated  :           std_logic                                  := '0'                   ; 

    signal  current_address : std_logic_Vector ( ADDR_WIDTH-1 downto 0 ) := (others => '0') ;

    component fifo_cmd_sync_xpm 
        generic(
            DATA_WIDTH      :           integer         :=  64                          ;
            MEMTYPE         :           String          :=  "block"                     ;
            DEPTH           :           integer         :=  16                           
        );
        port(
            CLK             :   in      std_logic                                       ;
            RESET           :   in      std_logic                                       ;
            
            DIN             :   in      std_logic_vector ( DATA_WIDTH-1 downto 0 )      ;
            WREN            :   in      std_logic                                       ;
            FULL            :   out     std_logic                                       ;
            DOUT            :   out     std_logic_Vector ( DATA_WIDTH-1 downto 0 )      ;
            RDEN            :   IN      std_logic                                       ;
            EMPTY           :   out     std_logic                                        

        );
    end component;

    signal  cmd_din         :           std_logic_vector ( ADDR_WIDTH-1 downto 0 )      ;
    signal  cmd_wren        :           std_logic                                       ;
    signal  cmd_full        :           std_logic                                       ;
    signal  cmd_dout        :           std_logic_Vector ( ADDR_WIDTH-1 downto 0 )      ;
    signal  cmd_rden        :           std_logic                                       ;
    signal  cmd_empty       :           std_logic := '0'                                ;

    --component ila_rd 
    --    port (
    --        clk             :   in      std_logic                                       ;
    --        probe0          :   in      std_logic_vector ( 29 downto 0 )                ;
    --        probe1          :   in      std_logic                                       ;
    --        probe2          :   in      std_logic                                       ;
    --        probe3          :   in      std_logic_vector ( 29 downto 0 )                ;
    --        probe4          :   in      std_logic                                       ;
    --        probe5          :   in      std_logic                                        
    --    );
    --end component;

    signal  valid_cnt       :           std_Logic_Vector ( 31 downto 0 ) := (others => '0')     ;
    signal  valid_reg       :           std_Logic_Vector ( 31 downto 0 ) := (others => '0')     ;
    signal  timer_reg       :           std_Logic_Vector ( 31 downto 0 ) := (others => '0')     ;

    signal  status_reg      :           std_logic                        := '0'                 ;

    signal  queue_volume_reg    :           std_logic_Vector ( 31 downto 0 )    := (others => '0')      ;

    signal  suspend_active_reg  :           std_logic                           := '0';

begin

    M_AXI_AWSIZE    <=  conv_std_logic_vector ( C_AXSIZE_INT, M_AXI_AWSIZE'length);
    M_AXI_AWCACHE   <= (others => '0') ;
    M_AXI_AWPROT    <= (others => '0') ;
    M_AXI_AWLOCK    <= '0';
    M_AXI_AWADDR    <=  m_axi_awaddr_reg;
    M_AXI_AWLEN     <=  m_axi_awlen_reg;
    M_AXI_AWBURST   <=  m_axi_awburst_reg;
    M_AXI_AWVALID   <=  m_axi_awvalid_reg;


    M_AXI_WDATA     <=  m_axi_wdata_reg     ;      
    M_AXI_WSTRB     <=  m_axi_wstrb_reg     ;      
    M_AXI_WLAST     <=  m_axi_wlast_reg     ;      
    M_AXI_WVALID    <=  m_axi_wvalid_reg    ;     

    M_AXI_BREADY    <=  m_axi_bready_reg    ;

    CURRENT_BASEADDR <= cmd_dout;
    --USER_EVENT       <= cmd_wren;

    FIFO_NOT_EMPTY   <= not(cmd_empty);
    FIFO_WREN        <= cmd_wren;
    
    SUSPEND_ACTIVE   <= suspend_active_reg;

    VALID_COUNTER    <= valid_reg;
    STATUS           <= status_reg;

    QUEUE_VOLUME     <= queue_volume_reg; 
    QUEUE_OVERFLOW   <= cmd_full            ;
    m_axi_awburst_reg <= "01";

    m_axi_wdata_reg <= in_dout_data;    
    m_axi_wstrb_reg <= (others => '1');

    status_reg_processing : process(CLK)
    begin 
        if CLK'event AND CLK = '1' then 
            case current_state is 
            
                when IDLE_ST => 
                    status_reg <= '0';

                when others => 
                    status_reg <= '1';
            
            end case;
        end if;
    end process;

    suspend_active_reg_processing : process(CLK)
    begin
        if CLK'event AND CLK = '1' then 
            case current_state is 
                when PAUSE_ST => 
                    suspend_active_reg <= '1';

                when others =>  
                    suspend_active_reg <= '0';
            end case;
        end if;
    end process;

    timer_reg_processing : process(CLK)
    begin
        if CLK'event AND CLK = '1' then 
            if (timer_reg < FREQ_HZ-1) then 
                timer_reg <= timer_reg + 1;
            else
                timer_reg <= (others => '0');
            end if;
        end if;
    end process;

    valid_cnt_processing : process(CLK)
    begin
        if CLK'event AND CLK = '1' then 
            if (timer_reg < FREQ_HZ-1) then 
                if (m_axi_wvalid_reg = '1' and M_AXI_WREADY = '1') then 
                    valid_cnt <= valid_cnt + 1;
                else
                    valid_cnt <= valid_cnt;
                end if;
            else
                valid_cnt <= (others => '0');
            end if;
        end if;
    end process;

    valid_reg_processing : process(CLK)
    begin
        if CLK'event AND CLK = '1' then 
            if timer_reg < (FREQ_HZ-1) then 
                valid_reg <= valid_reg;
            else
                if (m_axi_wvalid_reg = '1' and M_AXI_WREADY = '1' ) then 
                    valid_reg <= valid_cnt + 1;
                else
                    valid_reg <= valid_cnt;
                end if;
            end if;
        end if;
    end process;

    --calc_cnt_processing : process(CLK)
    --begin
    --    if CLK'event AND CLK = '1' then 
    --        case current_state is 
    --            when WAIT_FOR_CALC_ST => 
    --                calc_cnt <= calc_cnt + 1;

    --            when others => 
    --                calc_cnt <= (others => '0');

    --        end case;
    --    end if;
    --end process;

    has_stop_initiated_processing : process(CLK)
    begin
        if CLK'event AND CLK = '1' then 
            if RESET = '1' then 
                has_stop_initiated <= '0';
            else
                case current_state is 

                    when IDLE_ST => 
                        has_stop_initiated <= '0';

                    when PAUSE_ST => 
                        if RUN_SIGNAL = '1' then 
                            has_stop_initiated <= '0';
                        else
                            has_stop_initiated <= has_stop_initiated;
                        end if;

                    when others => 
                        if STOP_SIGNAL = '1' then 
                            has_stop_initiated <= '1';
                        else
                            has_stop_initiated <= has_stop_initiated;
                        end if;
     
                end case;
            end if;
        end if;
    end process;



    word_counter_processing : process(CLK)
    begin
        if CLK'event AND CLK = '1' then 
            case current_state is

                when IDLE_ST => 
                    if RUN_SIGNAL = '1' then 
                        if PORTION_SIZE( C_AXSIZE_INT-1 downto 0 ) = 0 then -- äîáèâàíèå íà êðàòíîñòü ñëîâó 
                            word_counter <= EXT(PORTION_SIZE(31 downto C_AXSIZE_INT), word_counter'length);
                        else
                            word_counter <= EXT(PORTION_SIZE(31 downto C_AXSIZE_INT), word_counter'length) + 1;
                        end if;
                    else
                        word_counter <= word_counter;
                    end if;

                when PAUSE_ST => 
                    if PORTION_SIZE( C_AXSIZE_INT-1 downto 0 ) = 0 then -- äîáèâàíèå íà êðàòíîñòü ñëîâó 
                        word_counter <= EXT(PORTION_SIZE(31 downto C_AXSIZE_INT), word_counter'length);
                    else
                        word_counter <= EXT(PORTION_SIZE(31 downto C_AXSIZE_INT), word_counter'length) + 1;
                    end if;

                when WRITE_ST => 
                    if m_axi_wvalid_reg = '1' and M_AXI_WREADY = '1' and m_axi_wlast_reg = '1' then
                        word_counter <= word_counter - awlen_reg;
                    else
                        word_counter <= word_counter;
                    end if;

                when others => 
                    word_counter <= word_counter;

            end case;
        end if;
    end process;



    m_axi_awaddr_reg_processing : process(CLK)
    begin
        if CLK'event AND CLK = '1' then 
            case current_state is
                when IDLE_ST => 
                    m_axi_awaddr_reg <= MEM_STARTADDR;

                when WRITE_WAIT_BRESP_ST => 
                    if M_AXI_BVALID = '1' and m_axi_bready_reg = '1' then 
                        m_axi_awaddr_reg <= m_axi_awaddr_reg + C_AXADDR_INCREMENT_VEC;
                    else
                        m_axi_awaddr_reg <= m_axi_awaddr_reg;    
                    end if;

                when PAUSE_ST => 
                    if (m_axi_awaddr_reg < MEM_HIGHADDR) then 
                        m_axi_awaddr_reg <= m_axi_awaddr_reg;
                    else
                        m_axi_awaddr_reg <= (others => '0');
                    end if;

                when others => 
                    m_axi_awaddr_reg <= m_axi_awaddr_reg;

            end case;
        end if;
    end process;



    current_address_processing : process(CLK)
    begin
        if CLK'event AND CLK = '1' then 
            case current_state is

                when IDLE_ST => 
                    current_address <= MEM_STARTADDR;

                when PAUSE_ST => 
                    if (m_axi_awaddr_reg < MEM_HIGHADDR) then 
                        current_address <= m_axi_awaddr_reg;
                    else
                        current_address <= (others => '0');
                    end if;

                when others => 
                    current_address <= current_address;
            end case;
        end if;
    end process;



    m_axi_awlen_reg_processing : process(CLK)
    begin
        if CLK'event AND CLK = '1' then
            case current_state is

                when WAIT_FOR_DATA_ST => 
                    if word_counter <= conv_std_logic_vector(BURST_LIMIT, word_counter'length) then 
                        m_axi_awlen_reg <= word_counter(7 downto 0) - 1;
                    else
                        m_axi_awlen_reg <= conv_std_logic_vector(BURST_LIMIT-1, 8);
                    end if;

                when WRITE_WAIT_BRESP_ST =>
                    if in_empty = '0' then 
                        if word_counter <= conv_std_logic_Vector ( BURST_LIMIT-1, word_counter'length) then 
                            if fifo_word_count < word_counter then 
                                m_axi_awlen_reg <= m_axi_awlen_reg;
                            else
                                m_axi_awlen_reg <= word_counter(7 downto 0) - 1;
                            end if;
                        else
                            if fifo_word_count < BURST_LIMIT then 
                                m_axi_awlen_reg <= m_axi_awlen_reg;
                            else
                                m_axi_awlen_reg <= conv_std_logic_vector(BURST_LIMIT-1, 8);
                            end if;
                        end if;
                    else
                        m_axi_awlen_reg <= m_axi_awlen_reg;
                    end if;

                when others => 
                    m_axi_awlen_reg <= m_axi_awlen_reg;

            end case;
        end if;
    end process;



    --íóæåí òîëüêî äëÿ äåêðåìåíòà ñ÷åò÷èêà ïðè çàïèñè. 
    awlen_reg_processing : process(CLK)
    begin
        if CLK'event AND CLK = '1' then 

            case current_state is
                when WAIT_FOR_DATA_ST => 
                    if word_counter <= conv_std_logic_vector(BURST_LIMIT, word_counter'length) then 
                        awlen_reg <= word_counter(awlen_reg'length-1 downto 0);
                    else
                        awlen_reg <= conv_std_logic_vector(BURST_LIMIT, awlen_reg'length);
                    end if;

                when WRITE_WAIT_BRESP_ST => 
                    if in_empty = '0' then 
                        if word_counter <= conv_std_logic_Vector ( BURST_LIMIT-1, word_counter'length) then 
                            if fifo_word_count < word_counter then 
                                awlen_reg <= awlen_reg;
                            else
                                awlen_reg <= word_counter(awlen_reg'length-1 downto 0);
                            end if;
                        else
                            if fifo_word_count < BURST_LIMIT then 
                                awlen_reg <= awlen_reg;
                            else
                                awlen_reg <= conv_std_logic_vector(BURST_LIMIT, awlen_reg'length);
                            end if;
                        end if;
                    else
                        awlen_reg <= awlen_reg;
                    end if;

                when others => 
                    awlen_reg <= awlen_reg;

            end case;
        end if;
    end process;



    m_axi_awvalid_reg_processing : process(CLK)
    begin
        if CLK'event AND CLK = '1' then

            case current_state is

                when WAIT_FOR_DATA_ST => 
                    if in_empty = '0' then 
                        if word_counter <= conv_std_logic_Vector ( BURST_LIMIT-1, word_counter'length) then 
                            if fifo_word_count < word_counter then 
                                m_axi_awvalid_reg <= m_axi_awvalid_reg;
                            else
                                m_axi_awvalid_reg <= '1';
                            end if;
                        else
                            if fifo_word_count < BURST_LIMIT then 
                                m_axi_awvalid_reg <= m_axi_awvalid_reg;
                            else
                                m_axi_awvalid_reg <= '1';
                            end if;
                        end if;
                    else
                        m_axi_awvalid_reg <= m_axi_awvalid_reg;
                    end if;

                when WRITE_ST => 
                    if m_axi_awvalid_reg = '1' and M_AXI_AWREADY = '1' then 
                        m_axi_awvalid_reg <= '0';
                    else
                        m_axi_awvalid_reg <= m_axi_awvalid_reg;
                    end if;

                when WRITE_WAIT_BRESP_ST =>
                    if (M_AXI_BVALID = '1' and m_axi_bready_reg = '1') or has_bresp_flaq = '1' then 
                        if word_counter = 0 then 
                            m_axi_awvalid_reg <= '0';
                        else
                            if in_empty = '0' then 
                                if word_counter <= conv_std_logic_Vector ( BURST_LIMIT-1, word_counter'length) then 
                                    if fifo_word_count < word_counter then 
                                        m_axi_awvalid_reg <= '0';
                                    else
                                        m_axi_awvalid_reg <= '1';
                                    end if;
                                else
                                    if fifo_word_count < BURST_LIMIT then 
                                        m_axi_awvalid_reg <= '0';
                                    else
                                        m_axi_awvalid_reg <= '1';
                                    end if;
                                end if;
                            else
                                m_axi_awvalid_reg <= '0';
                            end if;
                        end if;
                    else
                        m_axi_awvalid_reg <= '0';
                    end if;

                when others => 
                    m_axi_awvalid_reg <= '0';

            end case;                 
        end if;
    end process;



    m_axi_bready_reg_processing : process(CLK)
    begin
        if cLK'event AND CLK = '1' then 
            m_axi_bready_reg <= '1';
        end if;
    end process;



    m_axi_wvalid_reg_processing : process(CLK)
    begin
        if CLK'event AND CLK = '1' then 
            case current_state is

                when WAIT_FOR_DATA_ST => 
                    if in_empty = '0' then 
                        if word_counter <= conv_std_logic_Vector ( BURST_LIMIT-1, word_counter'length) then 
                            if fifo_word_count < word_counter then 
                                m_axi_wvalid_reg <= m_axi_wvalid_reg;
                            else
                                m_axi_wvalid_reg <= '1';
                            end if;
                        else
                            if fifo_word_count < BURST_LIMIT then 
                                m_axi_wvalid_reg <= m_axi_wvalid_reg;
                            else
                                m_axi_wvalid_reg <= '1';
                            end if;
                        end if;
                    else
                        m_axi_wvalid_reg <= m_axi_wvalid_reg;
                    end if;


                when WRITE_ST =>
                    if m_axi_wlast_reg = '1' and M_AXI_WREADY = '1' then 
                        m_axi_wvalid_reg <= '0';
                    else    
                        m_axi_wvalid_reg <= '1';
                    end if;

                when WRITE_WAIT_BRESP_ST =>
                    if (M_AXI_BVALID = '1' and m_axi_bready_reg = '1') or has_bresp_flaq = '1' then 
                        if word_counter = 0 then 
                            m_axi_wvalid_reg <= '0';
                        else
                            if in_empty = '0' then 
                                if word_counter <= conv_std_logic_Vector ( BURST_LIMIT-1, word_counter'length) then 
                                    if fifo_word_count < word_counter then 
                                        m_axi_wvalid_reg <= '0';
                                    else
                                        m_axi_wvalid_reg <= '1';
                                    end if;
                                else
                                    if fifo_word_count < BURST_LIMIT then 
                                        m_axi_wvalid_reg <= '0';
                                    else
                                        m_axi_wvalid_reg <= '1';
                                    end if;
                                end if;
                            else
                                m_axi_wvalid_reg <= '0';
                            end if;
                        end if;
                    else
                        m_axi_wvalid_reg <= '0';
                    end if;


                when others => 
                    m_axi_wvalid_reg <= '0';

            end case;
        end if;
    end process;   



    m_axi_wlast_reg <= '1' when awburst_counter = m_axi_awlen_reg and current_state = WRITE_ST else '0';



    awburst_counter_processing : process(CLK)
    begin
        if CLK'event AND CLK = '1' then 
            case current_state is
                when WRITE_ST => 
                    if m_axi_wvalid_reg = '1' and M_AXI_WREADY = '1' then 
                        awburst_counter <= awburst_counter + 1;
                    else
                        awburst_counter <= awburst_counter;
                    end if;

                when others => 
                    awburst_counter <= (others => '0');
            end case;
        end if;
    end process;



    fifo_in_sync_counted_xpm_inst : fifo_in_sync_counted_xpm
        generic map (
            DATA_WIDTH      =>  DATA_WIDTH                      ,
            MEMTYPE         =>  "block"                         ,
            DEPTH           =>  FIFO_DEPTH                              
        )
        port map (
            CLK             =>  CLK                             ,
            RESET           =>  fifo_reset                      ,
            
            S_AXIS_TDATA    =>  S_AXIS_TDATA                    ,
            S_AXIS_TVALID   =>  S_AXIS_TVALID and write_ability ,
            S_AXIS_TLAST    =>  S_AXIS_TLAST                    ,
            S_AXIS_TREADY   =>  S_AXIS_TREADY                   ,

            IN_DOUT_DATA    =>  IN_DOUT_DATA                    ,
            IN_DOUT_LAST    =>  IN_DOUT_LAST                    ,
            IN_RDEN         =>  IN_RDEN                         ,
            IN_EMPTY        =>  IN_EMPTY                        ,

            DATA_COUNT      =>  fifo_data_count                  
        );



    in_rden         <= '1' when m_axi_wvalid_reg = '1' and M_AXI_WREADY = '1' else '0';
    fifo_word_count <= EXT(fifo_data_count(31 downto C_AXSIZE_INT), 32);



    fifo_reset_processing : process(CLK)
    begin
        if CLK'event AND CLK = '1' then
            if RESET = '1' then 
                fifo_reset <= '1';
            else
                case current_state is

                    when IDLE_ST =>
                        fifo_reset <= '1';

                    when others => 
                        fifo_reset <= '0';

                end case;
            end if; 
        end if;
    end process;


    -- All OK
    write_ability_processing : process(CLK)
    begin
        if CLK'event AND CLK = '1' then 
            case current_state is
                when IDLE_ST => 
                    write_ability <= '0';

                when others =>
                    write_ability <= '1';

            end case;
        end if;
    end process;



    current_state_processing : process(CLK)
    begin
        if CLK'event AND CLK = '1' then 
            if RESET = '1' then 
                current_state <= IDLE_ST;
            else
                case current_state is
                    when IDLE_ST =>
                        if RUN_SIGNAL = '1' then
                            --current_state <= WAIT_FOR_CALC_ST;
                            current_state <= WAIT_FOR_DATA_ST;
                        else
                            current_state <= current_state;    
                        end if;

                    --when WAIT_FOR_CALC_ST => 
                    --    if calc_cnt = CALC_LIMIT then 
                    --        current_state <= WAIT_FOR_DATA_ST;
                    --    else
                    --        current_state <= current_state;
                    --    end if;

                    when WAIT_FOR_DATA_ST => 
                        if in_empty = '0' then 
                            if word_counter <= conv_std_logic_Vector ( BURST_LIMIT-1, word_counter'length) then 
                                if fifo_word_count < word_counter then 
                                    current_state <= current_state;
                                else
                                    current_state <= WRITE_ST;
                                end if;
                            else
                                if fifo_word_count < BURST_LIMIT then 
                                    current_state <= current_state;
                                else
                                    current_state <= WRITE_ST;
                                end if;
                            end if;
                        else
                            current_state <= current_state;
                        end if;

                    when WRITE_ST =>
                        if m_axi_wvalid_reg = '1' and M_AXI_WREADY = '1' and m_axi_wlast_reg = '1' then 
                            current_state <= WRITE_WAIT_BRESP_ST;
                        else
                            current_state <= current_state;
                        end if;

                    when WRITE_WAIT_BRESP_ST => 
                        if (M_AXI_BVALID = '1' and m_axi_bready_reg = '1') or has_bresp_flaq = '1' then 
                            if word_counter = 0 then 
                                current_state <= PAUSE_ST;
                            else
                                if in_empty = '0' then 
                                    if word_counter <= conv_std_logic_Vector ( BURST_LIMIT-1, word_counter'length) then 
                                        if fifo_word_count < word_counter then 
                                            current_state <= current_state;
                                        else
                                            current_state <= WRITE_ST;
                                        end if;
                                    else
                                        if fifo_word_count < BURST_LIMIT then 
                                            current_state <= current_state;
                                        else
                                            current_state <= WRITE_ST;
                                        end if;
                                    end if;
                                else
                                    current_state <= current_state;
                                end if;
                            end if;
                        else
                            current_state <= current_state;
                        end if;

                    when PAUSE_ST => 
                        if has_stop_initiated = '1' then 
                            if RUN_SIGNAL = '1' then 
                                current_state <= WAIT_FOR_DATA_ST;
                            else
                                current_state <= current_state;
                            end if;
                        else
                            current_state <= WAIT_FOR_DATA_ST;
                        end if;
                        --current_state <= IDLE_ST;

                    when others => 
                        current_state <= current_state;
                end case;
            end if;
        end if;
    end process;



    has_bresp_flaq_processing : process(CLK)
    begin
        if CLK'event AND CLK = '1' then 
            case current_state is
                when WRITE_WAIT_BRESP_ST =>
                    if M_AXI_BVALID = '1' and m_axi_bready_reg = '1' then 
                        has_bresp_flaq <= '1';
                    else
                        has_bresp_flaq <= has_bresp_flaq;
                    end if;

                when others => 
                    has_bresp_flaq <= '0';

            end case;
        end if;
    end process;



    fifo_cmd_sync_xpm_inst : fifo_cmd_sync_xpm 
        generic map (
            DATA_WIDTH      =>  ADDR_WIDTH              ,
            MEMTYPE         =>  "block"                 ,
            DEPTH           =>  64                       
        )
        port map (
            CLK             =>  CLK                     ,
            RESET           =>  RESET                   ,
            
            DIN             =>  cmd_din                 ,
            WREN            =>  cmd_wren                ,
            FULL            =>  cmd_full                ,
            DOUT            =>  cmd_dout                ,
            RDEN            =>  cmd_rden                ,
            EMPTY           =>  cmd_empty                
        );
 


    queue_volume_reg_processing : process(CLK)
    begin
        if CLK'event AND CLK = '1' then 
            if RESET = '1' then 
                queue_volume_reg <= (others => '0');
            else
                if cmd_wren = '1' and cmd_rden = '1' then 
                    queue_volume_reg <= queue_volume_reg;
                else
                    if cmd_wren = '1' then 
                        queue_volume_reg <= queue_volume_reg + 1;
                    else
                        if cmd_rden = '1' then 
                            queue_volume_reg <= queue_volume_reg - 1;
                        else
                            queue_volume_reg <= queue_volume_reg;
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;



    cmd_din <= current_address;



    cmd_rden <= FIFO_RDEN;



    cmd_wren_processing : process(CLK)
    begin
        if CLK'event AND CLK = '1' then 
            case current_state is 

                when WRITE_WAIT_BRESP_ST => 
                    if (M_AXI_BVALID = '1' and m_axi_bready_reg = '1') or has_bresp_flaq = '1' then 
                        if word_counter = 0 then 
                            cmd_wren <= '1';
                        else
                            cmd_wren <= '0';
                        end if;
                    else
                        cmd_wren <= '0';
                    end if;

                when others => 
                    cmd_wren <= '0';

            end case;
        end if;
    end process;




end axi_memory_writer_func_arch;