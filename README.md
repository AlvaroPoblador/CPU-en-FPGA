# CPU 16-bit en VHDL (PYNQ-Z2)

Implementación en VHDL de una CPU sencilla de 16 bits para FPGA.

## Archivos
- cpu_pkg.vhd: tipos, constantes y opcodes.
- alu.vhd: ALU (ADD, SUB, AND, OR, XOR).
- regfile.vhd: banco de registros 16×16 (lectura asíncrona, escritura síncrona).
- cpu_core.vhd: núcleo de la CPU (PC, IR, ROM y control FETCH/EXEC).
- top_pynqz2.vhd: top para PYNQ-Z2 (reloj, switches/botón y LEDs).

## Qué hace
La CPU ejecuta un programa en ROM que actualiza el registro **R2** en bucle.
En la placa se muestran los **4 bits bajos de R2** en `LED(3 downto 0)`.

Secuencia esperada en LEDs:
1 → 8 → B → C → 0 → F → D → (repite)

## Controles (PYNQ-Z2)
- btn(0): Reset
- sw(0): Enable / pausa (0 = parada, 1 = ejecuta)
- sw(1): Velocidad (0 = lento, 1 = rápido)

## Cómo usar (Vivado)
1. Crear proyecto RTL y añadir los .vhd.
2. Poner top_pynqz2 como Top Module.
3. Añadir el .xdc de la PYNQ-Z2.
4. Sintetizar, implementar y generar bitstream.
5. Programar la FPGA.

## Autor
Alejandro Casanova Valero
Álvaro Poblador Márquez
