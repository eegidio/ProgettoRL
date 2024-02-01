library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity project_reti_logiche is
    port(
        i_clk   : in std_logic;
        i_rst   : in std_logic;
        i_start : in std_logic;
        i_w     : in std_logic;
        
        o_z0    : out std_logic_vector(7 downto 0);
        o_z1    : out std_logic_vector(7 downto 0);
        o_z2    : out std_logic_vector(7 downto 0);
        o_z3    : out std_logic_vector(7 downto 0);
        o_done  : out std_logic;
        
        o_mem_addr  : out std_logic_vector(15 downto 0);
        i_mem_data  : in std_logic_vector(7 downto 0);
        o_mem_we    : out std_logic;
        o_mem_en    : out std_logic
    );
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is

type state_type is (    IDLE,
                        ASK_CHN_1,
                        ASK_CHN_0,
                        ASK_ADDR,
                        REQUEST_DATA,
                        WAIT_DATA,
                        SHOW_OUT
                        );

constant gnd : std_logic_vector(7 downto 0) := "00000000";
signal curr_state, next_state : state_type;
signal out_buffer_0, out_buffer_1, out_buffer_2, out_buffer_3 : std_logic_vector(7 downto 0);
signal chn : std_logic_vector(1 downto 0);
signal shift_reg : std_logic_vector (15 downto 0);

signal input_sel : std_logic;
signal buffer_reg_en : std_logic;
signal reg_rst : std_logic;

begin
------------------------------------------------
-- channel register
process (i_clk, i_rst, reg_rst, i_start)
begin
    if reg_rst = '1' or i_rst = '1' then
        chn <= "00";
    elsif rising_edge(i_clk) and input_sel = '0' and i_start = '1' then
        chn <= chn(0) & i_w;
    end if;
end process;

-- shift register for address
process (i_clk, i_rst, reg_rst, i_start)
begin
    if reg_rst = '1' or i_rst = '1' then
            shift_reg <= "0000000000000000";
    elsif rising_edge(i_clk) and input_sel = '1' and i_start =  '1' then
          shift_reg <= shift_reg(14 downto 0) & i_w;
    end if;
end process;

-- buffer registers
process (i_clk, i_rst, buffer_reg_en)
begin
    if i_rst = '1' then
        out_buffer_0 <= "00000000";
        out_buffer_1 <= "00000000";
        out_buffer_2 <= "00000000";
        out_buffer_3 <= "00000000";
    elsif rising_edge(i_clk) and buffer_reg_en = '1' then
        case chn is
            when "00" =>
                out_buffer_0 <= i_mem_data;
                
            when "01" =>
                out_buffer_1 <= i_mem_data;
                
            when "10" =>
                out_buffer_2 <= i_mem_data;
                
            when others =>
                out_buffer_3 <= i_mem_data;
        end case;
    end if;
end process;

------------------------------------------------ 
o_mem_we <= '0';
o_mem_addr <= shift_reg;

-- FSM
process(i_rst, i_clk)
begin
    if i_rst = '1' then
        curr_state <= IDLE;
    elsif rising_edge(i_clk) then
        curr_state <= next_state;
        if  i_start = '1' and curr_state = IDLE then
            curr_state <= ASK_CHN_1;
        end if;
    end if;
end process;


process (i_start, curr_state)
begin
    input_sel <= '0';
    buffer_reg_en <= '0';
    reg_rst <= '0';
    next_state <=  curr_state;
    
    o_z0 <= gnd;
    o_z1 <= gnd;
    o_z2 <= gnd;
    o_z3 <= gnd;
    o_mem_en <= '0';
    o_done <= '0';
    
    case curr_state is
    
    when IDLE =>
        if i_start = '1'  then
            input_sel <= '0';
            next_state <= ASK_CHN_1;
        else
            next_state <= IDLE;
        end if;
        
    when ASK_CHN_1 =>  
        input_sel <= '0';
        next_state <= ASK_CHN_0;    
    
    when ASK_CHN_0 =>
        if i_start = '1' then
            input_sel <= '1';
            next_state <= ASK_ADDR;
        elsif i_start = '0' then
            next_state <= REQUEST_DATA;
        end if;
    
    when ASK_ADDR =>
        if i_start = '1' then
            input_sel <= '1';
            next_state <= ASK_ADDR;
        elsif i_start = '0' then
            next_state <= REQUEST_DATA;
        end if;
    
    when REQUEST_DATA =>
        o_mem_en <= '1';
        next_state <= WAIT_DATA;
    
    when WAIT_DATA =>
        buffer_reg_en <= '1';
        next_state <= SHOW_OUT;
    
    when SHOW_OUT =>
        o_done <= '1';
        o_z0 <= out_buffer_0;
        o_z1 <= out_buffer_1;
        o_z2 <= out_buffer_2;
        o_z3 <= out_buffer_3;
        reg_rst <= '1';
        next_state <= IDLE;
                
    end case;
end process;

end Behavioral;