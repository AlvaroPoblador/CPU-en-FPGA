library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.cpu_pkg.all;           -- Importamos REG_N, DATA_W y word_t

entity top_pynqz2 is
  port (
    sysclk : in  std_logic;                        -- reloj 125 MHz
    btn    : in  std_logic_vector(3 downto 0);     -- botón
    sw     : in  std_logic_vector(1 downto 0);     -- switch
    led    : out std_logic_vector(3 downto 0)      -- LEDs
  );
end entity;

architecture rtl of top_pynqz2 is
  signal rst      : std_logic;                                  -- Señal de reset
  signal regs_o   : std_logic_vector(REG_N*DATA_W-1 downto 0);  -- Registros del CPU_core

  signal divcnt    : unsigned(26 downto 0) := (others => '0');  -- Contador para dividiir la frecuencia
  signal tick_slow : std_logic := '0';                          -- Pulso lento
  signal tick_fast : std_logic := '0';                          -- Pulso rápido
  signal tick_sel  : std_logic := '0';                          -- Seleccionador de pulso
  signal en_cpu    : std_logic := '0';                          -- Enable

-- Función para extraer registros de bus dump
  function get_reg(dump : std_logic_vector; idx : integer) return word_t is
    variable lo, hi : integer;
  begin
    lo := idx*DATA_W;
    hi := (idx+1)*DATA_W - 1;
    return dump(hi downto lo);
  end function;

  signal r2 : word_t;       -- Señal de R2
  
begin
  rst <= btn(0);            -- Se activa el reset cuando se pulsa el botón

  -- Divisor de frecuencia para pulso lento o rápido
  process(sysclk)
  begin
    if rising_edge(sysclk) then
      divcnt <= divcnt + 1;

      -- RÁPIDO: pulso cuando los 24 bits bajos vuelven a 0 (~0.134 s)
      if divcnt(23 downto 0) = 0 then
        tick_fast <= '1';
      else
        tick_fast <= '0';
      end if;

      -- LENTO: pulso cuando todo el contador vuelve a 0 (~2.15 s con 28 bits)
      if divcnt = 0 then
        tick_slow <= '1';
      else
        tick_slow <= '0';
      end if;
    end if;
  end process;

  -- sw1=0 lento, sw1=1 rápido
  tick_sel <= tick_fast when sw(1) = '1' else tick_slow;

  -- sw0=0 pausa, sw0=1 enable
  en_cpu <= tick_sel and sw(0);

  -- CPU core
  UCPU: entity work.cpu_core
    port map (
      clk    => sysclk,
      rst    => rst,
      en     => en_cpu,
      regs_o => regs_o
    );

  -- Mostrar R2 en LEDs
  r2  <= get_reg(regs_o, 2);
  led <= r2(3 downto 0);

end architecture;
