-- ============================================================================
--  Module: LED Dimmer Arty A7 Top
--  Author: Eric Hamdan (fpga.dsp@gmail.com)
-- ----------------------------------------------------------------------------
--         +-----------------------------+
-- clk --->|                             |
-- rst --->|                             |
-- sw0 --->|    led_dimmer_arty_a7_top   |---> led0(0) -- Red PWM
--         |                             |---> led0(1) -- Green PWM
--         |                             |---> led0(2) -- Blue PWM
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
--   This is the Arty A7 top level wrapper for the led_dimmer module.
--   It incorporates an external reset and enable switch synchronizer.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity led_dimmer_arty_a7_top is
    generic (
        r_duty_cycle : integer range 0 to 1000 := 218;
        g_duty_cycle : integer range 0 to 1000 := 0;
        b_duty_cycle : integer range 0 to 1000 := 218;
        pwm_freq_hz : integer range 10_000 to 20_000 := 20_000;
        clk_freq_hz : integer range 50_000 to 200_000_000 := 100_000_000
    );
    port (
        clk : in std_logic; -- System clock
        rst : in std_logic; -- External reset
        sw0 : in std_logic; -- External enable switch
        led0 : out std_logic_vector(0 to 2) -- Led outputs
    );
end led_dimmer_arty_a7_top;

architecture rtl of led_dimmer_arty_a7_top is

    signal sw0_sync : std_logic_vector(1 downto 0) := (others => '0'); -- Synchronized switch input
    signal rst_sync : std_logic_vector(1 downto 0) := (others => '0'); -- Synchronized reset input

begin

    -- Synchronize external enable switch
    SYNC_EN : process(clk)
    begin
        if rising_edge(clk) then
            sw0_sync(0) <= sw0;
            sw0_sync(1) <= sw0_sync(0);
        end if;
    end process;

    -- Synchronize external reset
    SYNC_RST : process(clk)
    begin
        if rising_edge(clk) then
            rst_sync(0) <= rst;
            rst_sync(1) <= rst_sync(0);
        end if;
    end process;

    -- LED Dimmer entity
    LED_DIMMER : entity work.led_dimmer(rtl)
    generic map (
        r_duty_cycle => r_duty_cycle, 
        g_duty_cycle => g_duty_cycle,
        b_duty_cycle => b_duty_cycle,
        pwm_freq_hz => pwm_freq_hz,
        clk_freq_hz => clk_freq_hz
    )
    port map (
        clk => clk, 
        rst => rst_sync(1),
        en => sw0_sync(1),
        led_out => led0
    );

end architecture;
