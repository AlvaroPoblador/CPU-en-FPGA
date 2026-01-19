library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.cpu_pkg.all;           -- Importamos lo siguiente:
                                -- Tipos de datos: word_t, regid_t, instr_t y state_t, 
                                -- Constantes: REG_N, REG_W y DATA_W
                                -- Códigos de operación: OP_NOP, OP_LDI, OP_ADD, OP_SUB, OP_AND, OP_OR y OP_XOR 
                                -- Funciones: sext8, mkR y mkI
entity cpu_core is
  port (
    clk     : in  std_logic;    -- Reloj
    rst     : in  std_logic;    -- Reset
    en      : in  std_logic;    -- Enable
    regs_o  : out std_logic_vector(REG_N*DATA_W-1 downto 0)    -- Salida de registros
  );
end entity;

architecture rtl of cpu_core is
  type state_t is (S_FETCH, S_EXEC);    -- Estado actual de la FSM
  signal state : state_t := S_FETCH;    

  signal pc    : unsigned(7 downto 0) := (others => '0');   -- Dirección de la próxima instrucción a leer
  signal ir    : instr_t := (others => '0');                -- Instrucción actual leida

  -- Decodificador
  signal op    : std_logic_vector(3 downto 0);
  signal rd    : regid_t;
  signal ra    : regid_t;
  signal rb    : regid_t;
  signal imm8  : std_logic_vector(7 downto 0);

  -- Regfile
  signal ra_d, rb_d : word_t;
  signal rd_we      : std_logic := '0';
  signal rd_d       : word_t := (others => '0');

  -- ALU
  signal alu_y : word_t;

  -- Definición de la ROM: Hcemos un bucle infinito en R2 que sigue los siguientes resultados => 1->8->B->C->0->F->D
  type rom_t is array(0 to 31) of instr_t;
  constant ROM : rom_t := (
    -- Inicialización (una vez tras reset)
    0  => mkI(OP_LDI, "0000", x"07"),          -- R0 = 7
    1  => mkI(OP_LDI, "0001", x"03"),          -- R1 = 3
    2  => mkI(OP_LDI, "0011", x"0F"),          -- R3 = 0x000F
    3  => mkI(OP_LDI, "0100", x"02"),          -- R4 = 2

    -- Resultado visible en los LEDs -> 1,8,B,C,0,F,D
    4  => mkI(OP_LDI, "0010", x"01"),          -- R2 = 1
    5  => mkR(OP_ADD, "0010", "0010", "0000"), -- R2 = R2 + R0 = 8 
    6  => mkR(OP_ADD, "0010", "0010", "0001"), -- R2 = R2 + R1 = 11 (B)
    7  => mkR(OP_XOR, "0010", "0010", "0000"), -- R2 = R2 xor R0 = 12 (C)
    8  => mkR(OP_AND, "0010", "0010", "0001"), -- R2 = R2 and R1 = 0 
    9  => mkR(OP_OR,  "0010", "0010", "0011"), -- R2 = R2 or  R3 = 15 (F)
    10 => mkR(OP_SUB, "0010", "0010", "0100"), -- R2 = R2 -  R4 = 13 (D)

    others => (others => '0')                  -- NOP
  );

begin
  -- Decodificación desde la instrucción leida
  op   <= ir(15 downto 12);
  rd   <= ir(11 downto 8);
  ra   <= ir(7 downto 4);
  rb   <= ir(3 downto 0);
  imm8 <= ir(7 downto 0);

  -- Regfile
  U_RF : entity work.regfile
    port map (
      clk   => clk,
      rst   => rst,
      ra_id => ra,
      rb_id => rb,
      rd_id => rd,
      rd_we => rd_we,
      rd_d  => rd_d,
      ra_d  => ra_d,
      rb_d  => rb_d,
      dump  => regs_o
    );

  -- ALU
  U_ALU : entity work.alu
    port map (
      a  => ra_d,
      b  => rb_d,
      op => op,
      y  => alu_y
    );

  -- Control simple (FETCH/EXEC)
  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then                 -- Reseteamos todas las señales y forzamos el estado FETCH (traer instrucción)
        pc    <= (others => '0');
        ir    <= (others => '0');
        state <= S_FETCH;
        rd_we <= '0';
        rd_d  <= (others => '0');
      else
        if (en = '1') then                              -- Con el switch activado
          case state is

            when S_FETCH =>                             --Se trae la instrucción y se controla que instrucción es la siguiente
              ir <= ROM(to_integer(pc));


              if pc = to_unsigned(10, pc'length) then   -- Comprobamos si va por la última instrucción y si es correcto vuelve a la primera
                pc <= to_unsigned(4, pc'length);
              else                                      -- Si no, continuamos con la siguiente instrucción 
                pc <= pc + 1;
              end if;

              state <= S_EXEC;                          -- Se pasa al estado EXEC para ejecutar la instrucción

            when S_EXEC =>                              -- Ejecutar instrucción
              rd_we <= '0';                             -- Por defecto no se escribe 
              rd_d  <= (others => '0');

              case op is
                when OP_NOP =>                          -- Si la instrucción es NOP o desconocida no se escribe
                  null;

                when OP_LDI =>                          -- Si se da esta operación hace carga inmediata
                  rd_we <= '1';
                  rd_d  <= sext8(imm8);

                when OP_ADD | OP_SUB | OP_AND | OP_OR | OP_XOR =>   -- Si se da una de estas operaciones prepara la escritura de la ALU
                  rd_we <= '1';
                  rd_d  <= alu_y;

                when others =>
                  null;
              end case;

              state <= S_FETCH;                         -- Cuando termina, vuelve al estado FETCH

          end case;
        else
          rd_we <= '0';                                 -- Sin el switch activado
        end if;
      end if;
    end if;
  end process;
end architecture;
