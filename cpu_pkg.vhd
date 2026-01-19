library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Definimos el paquete CPU_PKG
package cpu_pkg is
  -- Constantes de configuración
  constant DATA_W  : natural := 16;         -- Ancho de palabra de datos de la CPU
  constant REG_W   : natural := 4;          -- Ancho del identificador del registro
  constant REG_N   : natural := 2**REG_W;   -- Número total de registros
  
  -- Tipos de datos
  subtype word_t  is std_logic_vector(DATA_W-1 downto 0);  
  subtype instr_t is std_logic_vector(15 downto 0);     
  subtype regid_t is std_logic_vector(REG_W-1 downto 0);

  -- Códigos de operación
  constant OP_NOP  : std_logic_vector(3 downto 0) := "0000";    -- Nula
  constant OP_LDI  : std_logic_vector(3 downto 0) := "0001";    -- Carga inmediata
  constant OP_ADD  : std_logic_vector(3 downto 0) := "0010";    -- Suma
  constant OP_SUB  : std_logic_vector(3 downto 0) := "0011";    -- Resta
  constant OP_AND  : std_logic_vector(3 downto 0) := "0100";    -- AND
  constant OP_OR   : std_logic_vector(3 downto 0) := "0101";    -- OR
  constant OP_XOR  : std_logic_vector(3 downto 0) := "0110";    -- XOR

  -- Funciones
  function sext8(x : std_logic_vector(7 downto 0)) return word_t;
  function mkR(op : std_logic_vector(3 downto 0); rd, ra, rb : regid_t) return instr_t;
  function mkI(op : std_logic_vector(3 downto 0); rd : regid_t; imm8 : std_logic_vector(7 downto 0)) return instr_t;
end package;

-- Definición de cada función
package body cpu_pkg is

  -- Función para pasar de 8 bits a 16 bits, ya que LDI son 8 bits pero los registros son de 16 bits
  function sext8(x : std_logic_vector(7 downto 0)) return word_t is
  begin
    return std_logic_vector(resize(signed(x), 16));
  end function;

  -- Función para contruir una instrucción tipo R (registro/registro) para escribir en la ROM de forma legible
  function mkR(op : std_logic_vector(3 downto 0); rd, ra, rb : regid_t) return instr_t is
    variable i : instr_t;
  begin
    i(15 downto 12) := op;
    i(11 downto 8)  := rd;
    i(7 downto 4)   := ra;
    i(3 downto 0)   := rb;
    return i;
  end function;
  
  -- Función para contruir una instrucción tipo I(inmediata) para LDI en la ROM
  function mkI(op : std_logic_vector(3 downto 0); rd : regid_t; imm8 : std_logic_vector(7 downto 0)) return instr_t is
    variable i : instr_t;
  begin
    i(15 downto 12) := op;
    i(11 downto 8)  := rd;
    i(7 downto 0)   := imm8;
    return i;
  end function;
end package body;
