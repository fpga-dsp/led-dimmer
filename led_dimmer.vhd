-- ============================================================================
--  Module: LED Dimmer
--  Author: Eric Hamdan (fpga.dsp@gmail.com)
-- ----------------------------------------------------------------------------
--         +-----------------------------+
-- clk --->|                             |
-- rst --->|                             |
-- en  --->|        led_dimmer           |---> led_out(0) -- Red PWM
--         |                             |---> led_out(1) -- Green PWM
--         |                             |---> led_out(2) -- Blue PWM
--         +-----------------------------+
--
-- Generics:
--   - r_duty_cycle  : integer (0 to 1000)   -- Red LED duty cycle (0.1% steps)
--   - g_duty_cycle  : integer (0 to 1000)   -- Green LED duty cycle (0.1% steps)
--   - b_duty_cycle  : integer (0 to 1000)   -- Blue LED duty cycle (0.1% steps)
--   - pwm_freq_hz   : integer (10_000 to 20_000 Hz)
--   - clk_freq_hz   : integer (50_000 to 200_000_000 Hz)
--
-- Description:
--   This module generates PWM signals for RGB LEDs based on configured
--   duty cycles and frequency settings.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity led_dimmer is
    generic (
        r_duty_cycle : integer range 0 to 1000;                    -- Red LED duty cycle (0.1% steps)
        g_duty_cycle : integer range 0 to 1000;                    -- Green LED duty cycle (0.1% steps)
        b_duty_cycle : integer range 0 to 1000;                    -- Blue LED duty cycle (0.1% steps)
        pwm_freq_hz  : integer range 10_000 to 20_000;             -- Desired PWM frequency in Hz
        clk_freq_hz  : integer range 50_000_000 to 200_000_000     -- Input clock frequency in Hz
    );
    port (
        clk     : in  std_logic;                                   -- Input clock input
        rst     : in  std_logic;                                   -- Active-high synchronous reset
        en      : in  std_logic;                                   -- Enable signal (PWM on/off)
        led_out : out std_logic_vector(0 to 2)                     -- RGB PWM output (0: Red, 1: Green, 2: Blue)
    );
end led_dimmer;

architecture rtl of led_dimmer is

    -- Calculates the number of input clock cycles during HIGH time
    -- Ceiling rounding guarantees at least one HIGH cycle for any non-zero duty
    function compute_clk_cycles_high(duty : integer range 0 to 1000; cycle_cnt : integer range 2_500 to 20_000) return integer is
    begin
        return ((cycle_cnt * duty) + 999) / 1000;
    end function;

    type container is array(0 to 2) of unsigned(14 downto 0); -- Container for per-channel counters

    -- Calculates number of input clock cycles in one PWM period
    -- Nearest integer rounding
    constant num_clk_cycles_total : integer := (clk_freq_hz + (pwm_freq_hz / 2)) / pwm_freq_hz;

    -- Number of input clock cycles the output stays HIGH per channel based on duty cycle
    constant num_clk_cycles_high : container := (
        to_unsigned(compute_clk_cycles_high(r_duty_cycle, num_clk_cycles_total), 15),
        to_unsigned(compute_clk_cycles_high(g_duty_cycle, num_clk_cycles_total), 15),
        to_unsigned(compute_clk_cycles_high(b_duty_cycle, num_clk_cycles_total), 15)
    );

    signal clk_cnt : container := (others => (others => '0')); -- PWM counters per channel
    signal led_out_i : std_logic_vector(0 to 2) := (others => '0'); -- Internal RGB output

begin   

    -- Drive output
    led_out <= led_out_i;
    
    -- PWM logic process
    PWM_PROC : process(clk)
    begin
        if rising_edge(clk) then

            led_out_i <= (others => '0'); -- Clear outputs, overidden if PWM is active
            
            if rst = '1' then -- Active-high synchronous reset
                clk_cnt   <= (others => (others => '0')); -- Reset counters

            elsif en = '0' then -- Disable PWM output, counters are latched
                -- Do nothing

            else
                for ii in 0 to 2 loop -- Iterate over RGB channels
                    if clk_cnt(ii) < num_clk_cycles_high(ii) then
                        led_out_i(ii) <= '1'; -- Drive high for active duty portion
                    else
                        led_out_i(ii) <= '0'; -- Drive low for remainder
                    end if;

                    if clk_cnt(ii) = num_clk_cycles_total - 1 then
                        clk_cnt(ii) <= (others => '0'); -- Reset counter at end of PWM period
                    else
                        clk_cnt(ii) <= clk_cnt(ii) + 1; -- Increment counter
                    end if;
                end loop;
            end if;

        end if;
    end process;

end architecture;
