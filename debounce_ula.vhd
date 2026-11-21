----------------------------------------------------------------------------------
-- Projeto: Unidade Lógica e Aritmética (ULA) de 4 bits com FSM
-- Arquivo: debounce_ula.vhd (Filtro de Debounce e Detector de Borda)
-- Autor: Yure
-- Instituição: UFRJ - Sistemas Digitais
-- Placa/FPGA: Xilinx Spartan-3AN Starter Kit (Clock: 50 MHz)
--
-- Descrição:
--   Filtra a trepidação mecânica do botão de confirmação (janela de 20 ms,
--   equivalente a 1.000.000 ciclos @ 50 MHz) e gera um pulso síncrono de
--   1 ciclo de clock na borda de subida para transição segura da FSM.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity debounce_ula is
    port(
        clk        : in  std_logic;
        confirm    : in  std_logic;
        confirm_db : out std_logic;
        pulso      : out std_logic
    );
end debounce_ula;

architecture comportamento of debounce_ula is
    signal confirm_ant      : std_logic := '0';
    signal contagem         : integer range 0 to 1000000 := 0;
    signal confirm_db_ant   : std_logic := '0';
    signal confirm_db_sinal : std_logic := '0';
begin
    process (clk)
    begin
        if rising_edge(clk) then
            case confirm is
                when '0' =>
                    if confirm_ant = confirm then
                        if contagem < 1000000 then
                            confirm_ant <= confirm;
                            contagem    <= contagem + 1;
                        else
                            confirm_db_sinal <= '0';
                        end if;
                    else
                        contagem    <= 1;
                        confirm_ant <= confirm;
                    end if;

                when '1' =>
                    if confirm_ant = confirm then
                        if contagem < 1000000 then
                            confirm_ant <= confirm;
                            contagem    <= contagem + 1;
                        else
                            confirm_db_sinal <= '1';
                        end if;
                    else
                        contagem    <= 1;
                        confirm_ant <= confirm;
                    end if;
                
                when others =>
                    null;
            end case;
            confirm_db_ant <= confirm_db_sinal;
        end if;
    end process;

    confirm_db <= confirm_db_sinal;
    pulso      <= confirm_db_sinal and (not confirm_db_ant);
end comportamento;