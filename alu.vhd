library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.cpu_pkg.all;                               -- Implementamos el tipo de dato word_t

entity alu is
  port (
    a      : in  word_t;                            -- Operando a
    b      : in  word_t;                            -- Operando b
    op     : in  std_logic_vector(3 downto 0);      -- Decisión de que operación hacer
    y      : out word_t                             -- Resultado de la operación
  );
end entity;

architecture rtl of alu is
begin
  process(a, b, op)
  begin
    case op is                                                          -- En función del valor de op se haran las siguientes operaciones:
      when OP_ADD => y <= std_logic_vector(signed(a) + signed(b));      
      when OP_SUB => y <= std_logic_vector(signed(a) - signed(b));      
      when OP_AND => y <= a and b;                                      
      when OP_OR  => y <= a or b;
      when OP_XOR => y <= a xor b;
      when others => y <= (others => '0');
    end case;
  end process;
end architecture;
