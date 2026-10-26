
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity IC74194 is

    port(
        -- DI[3 .. 0] correspond to chip inputs A, B, C, D respectively
        DI   :  in      std_logic_vector(3 downto 0);
        LSI  :  in      std_logic;
        RSI  :  in      std_logic;
        -- S1 and S0 control signals 
        S    :  in      std_logic_vector(1 downto 0);
        CLR  :  in      std_logic;
        CLK  :  in      std_logic;
        -- DO[3 .. 0] correspond to chip outputs QA, QB, QC, QD respectively
        DO   :  buffer  std_logic_vector(3 downto 0)
    );

end entity IC74194;

architecture DataFlow of IC74194 is
    signal dff_inputs : std_logic_vector(3 downto 0);

begin
        dff_inputs(3) <=  
            (RSI and not S(1) and S(0)) or
            (S(0) and S(1) and DI(3)) or
            (not S(0) and S(1) and DO(2)) or
            (not S(0) and not S(1) and DO(3));
        
        dff_inputs(2) <=
            (DO(3) and not S(1) and S(0)) or
            (S(0) and S(1) and DI(2)) or
            (not S(0) and S(1) and DO(1)) or
            (not S(0) and not S(1) and DO(2));

        dff_inputs(1) <=
            (DO(2) and not S(1) and S(0)) or
            (S(0) and S(1) and DI(1)) or
            (not S(0) and S(1) and DO(0)) or
            (not S(0) and not S(1) and DO(1));

        dff_inputs(0) <=
            (DO(1) and not S(1) and S(0)) or
            (S(0) and S(1) and DI(0)) or
            (not S(0) and S(1) and LSI) or
            (not S(0) and not S(1) and DO(0));

        dffs: for i in 0 to 3 generate
            dff_x: entity work.dff_reset(async) 
                port map (
                    clk => CLK,
                    -- active LOW clear 
                    reset => not CLR,
                    d => dff_inputs(i),
                    q => DO(i),
                    qn => open
                );
        end generate dffs;

end architecture DataFlow;