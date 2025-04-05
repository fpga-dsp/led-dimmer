-- ============================================================================
--  Module: LED Dimmer Testbench
--  Author: Eric Hamdan (fpga.dsp@gmail.com)
-- ----------------------------------------------------------------------------
-- Description:
--   This is the self-checking testbench for the led_dimmer entity.
--   The TB checks the number of HIGH and LOW cycles for a given duty cycle.
--   The user can experiment with different duty cycles and clock speeds.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.textio.all;
use std.env.finish;

entity led_dimmer_tb is
end led_dimmer_tb;

architecture rtl of led_dimmer_tb is 

    -- Clock and control signals for the DUT (Device Under Test)
    signal dut_clk : std_logic := '1';
    signal dut_rst : std_logic := '0';
    signal dut_en : std_logic := '0';
    signal dut_led_out : std_logic_vector(0 to 2);

    -- Clock and PWM configuration
    constant tb_clk_freq_hz : integer := 100_000_000; -- System clock frequency (Hz)
    constant tb_clk_period : time := 1 sec / tb_clk_freq_hz; -- System clock period (sec)
    constant tb_pwm_freq_hz : integer := 20_000; -- PWM frequency (Hz)

    -- Duty cycle settings for Red, Green, and Blue channels (in %)
    constant tb_r_duty : integer := 218; -- Duty cycle for channel 0 (Red)
    constant tb_g_duty : integer := 0; -- Duty cycle for channel 1 (Green)
    constant tb_b_duty : integer := 218;  -- Duty cycle for channel 2 (Blue)

    -- Number of clock cycles per PWM period (rounded)
    constant num_clk_cycles : integer := (tb_clk_freq_hz + tb_pwm_freq_hz/2) / tb_pwm_freq_hz;

    -- Helper function to calculate expected number of clock cycles for HIGH time
    function compute_expected_high_clk_cycles(duty : integer; cycle_cnt : integer) return integer is
    begin
        return (cycle_cnt * duty + 1000 - 1) / 1000;
    end function;
    
    -- Expected number of system clock periods for HIGH and LOW of each channel
    constant exp_r_high : integer := compute_expected_high_clk_cycles(tb_r_duty, num_clk_cycles);
    constant exp_g_high : integer := compute_expected_high_clk_cycles(tb_g_duty, num_clk_cycles);
    constant exp_b_high : integer := compute_expected_high_clk_cycles(tb_b_duty, num_clk_cycles);
    constant exp_r_low : integer := num_clk_cycles - exp_r_high;
    constant exp_g_low : integer := num_clk_cycles - exp_g_high;
    constant exp_b_low : integer := num_clk_cycles - exp_b_high;

begin

    -- Clock generation: toggles every half clock period
    dut_clk <= not dut_clk after tb_clk_period/2;

    -- Instantiate the LED dimmer DUT
    DUT_LED_DIMMER : entity work.led_dimmer(rtl)
    generic map (
        r_duty_cycle => tb_r_duty,
        g_duty_cycle => tb_g_duty,
        b_duty_cycle => tb_b_duty,
        pwm_freq_hz => tb_pwm_freq_hz,
        clk_freq_hz => tb_clk_freq_hz
    )
    port map (
        clk => dut_clk,
        rst => dut_rst,
        en => dut_en,
        led_out => dut_led_out
    );

    ----------------------------------------------------------------------------
    -- Stimulus Process: Drives dut_rst and dut_en signals to exercise the design.
    ----------------------------------------------------------------------------
    stimulus : process
    begin
        -- Apply reset and keep enable low
        dut_rst <= '1';
        dut_en <= '0';
        wait for 10 * tb_clk_period;
        
        -- Check that outputs are all '0' during reset.
        assert dut_led_out = "000"
            report "Reset failed: expected dut_led_out = 000 during reset"
            severity error;

        report "LED value: " & std_logic'image(dut_led_out(0));
        
        -- Deassert reset, keep enable low.
        dut_rst <= '0';
        wait for 10 * tb_clk_period;
        
        -- Outputs should still be '0' when enable is low
        assert dut_led_out = "000"
            report "Enable low failed: expected dut_led_out = 000 when dut_en is '0'"
            severity error;
        
        -- Enable the DUT to start PWM generation
        dut_en <= '1';
        wait for 10 * tb_clk_period; -- wait for synchronizers to settle
        
        -- Run for several PWM periods to allow output validation
        wait for 7 * num_clk_cycles * tb_clk_period;
        
        -- Disable the DUT
        dut_en <= '0';
        wait for 5 * tb_clk_period;
        
        -- Check that outputs return to '0'
        assert dut_led_out = "000"
            report "Disable failed: expected dut_led_out = 000 when dut_en is '0'"
            severity error;
        
        report "Stimulus complete. Ending simulation.";
        finish;
    end process;

    ----------------------------------------------------------------------------
    -- Monitor Process: Checks PWM output for each channel
    ----------------------------------------------------------------------------        
    RBG_MONITOR_GEN : for ii in 0 to 2 generate -- Generate monitor for R, G, B channels
        monitor : process
        variable high_cycles : integer := 0;
        variable low_cycles : integer := 0;
        constant num_periods : integer := 5;  -- Check 5 full PWM periods
        begin
            -- Wait for reset deasserted and enable asserted
            wait until dut_rst = '0' and dut_en = '1';
            wait until rising_edge(dut_clk);

            for i in 1 to num_periods loop

                -- Count consecutive high cycles
                while true loop
                    wait until rising_edge(dut_clk);
                    if dut_led_out(0) = '1' then
                        high_cycles := high_cycles + 1;
                        if high_cycles = num_clk_cycles then
                            exit;
                        end if;
                    else
                        low_cycles := low_cycles + 1;
                        exit;
                    end if;
                end loop;

                -- Verify expected high pulse width
                assert high_cycles = exp_r_high
                    report "Channel 0 (r): High pulse width mismatch. Expected " & integer'image(exp_r_high) &
                            ", got " & integer'image(high_cycles)
                    severity error;

                high_cycles := 0;

                -- Count consecutive low cycles
                while true loop 
                    wait until rising_edge(dut_clk);
                    if dut_led_out(0) = '0' then
                        low_cycles := low_cycles + 1;
                        if low_cycles = num_clk_cycles then 
                            exit;
                        end if;
                    else
                        high_cycles := high_cycles + 1;
                        exit;
                    end if;
                end loop;

                -- Verify expected low pulse width
                assert low_cycles = exp_r_low
                report "Channel 0 (r): Low pulse width mismatch. Expected " & integer'image(exp_r_low) &
                        ", got " & integer'image(low_cycles)
                severity error;

                low_cycles := 0;

            end loop;
            
            report "Channel " & integer'image(ii) & " PWM timing tests ended." severity note;
            wait;
        end process;
    end generate;

end architecture;
