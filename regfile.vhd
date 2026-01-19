library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.cpu_pkg.all;               -- Importamos word_t, regid_t, REG_N y DATA_W

entity regfile is
  port (
    clk   : in  std_logic;          -- Reloj
    rst   : in  std_logic;          -- Reset

    ra_id : in  regid_t;            -- Registro a leer por el puerto a
    rb_id : in  regid_t;            -- Registro a leer por el puerto b

    rd_id : in  regid_t;            -- Registro a escribir
    rd_we : in  std_logic;          -- Enable para escribir (0 no escribe, 1 escribe)
    rd_d  : in  word_t;             -- Dato a escribir

    ra_d  : out word_t;             -- Valor almacenado en el registro seleccionado por ra_id
    rb_d  : out word_t;             -- Valor almacenado en el registro seleccionado por rb_id

    dump  : out std_logic_vector(REG_N*DATA_W-1 downto 0)   -- Salida registros
  );
end entity;

architecture rtl of regfile is
  type reg_array_t is array(0 to REG_N-1) of word_t;
  signal regs : reg_array_t := (others => (others => '0'));     -- Contenido del banco de registros
begin
-- Lectura asincrona
  ra_d <= regs(to_integer(unsigned(ra_id)));                    
  rb_d <= regs(to_integer(unsigned(rb_id)));

-- Lectura síncrona
  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        regs <= (others => (others => '0'));
      else
        if rd_we = '1' then
          regs(to_integer(unsigned(rd_id))) <= rd_d;
        end if;
      end if;
    end if;
  end process;

-- Salida del contenido de todos los registros en el bus dump
  gen_dump : for i in 0 to REG_N-1 generate
    dump((i+1)*DATA_W-1 downto i*DATA_W) <= regs(i);
  end generate;
end architecture;
