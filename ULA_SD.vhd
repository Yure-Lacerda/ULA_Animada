----------------------------------------------------------------------------------
-- Projeto: Unidade Lógica e Aritmética (ULA) de 4 bits com FSM
-- Arquivo: ULA_SD.vhd (Módulo Top-Level)
-- Autor: Yure
-- Instituição: UFRJ - Sistemas Digitais
-- Placa/FPGA: Xilinx Spartan-3AN Starter Kit (Clock: 50 MHz)
--
-- Descrição:
--   ULA de 4 bits controlada por Máquina de Estados Finitos (FSM) com entrada
--   sequencial (Seleção -> Operando A -> Operando B -> Execução). Executa 8
--   operações lógico-aritméticas, sinaliza flags (Zero, Negative, Overflow,
--   Carry) e exibe animação de espera nos 8 LEDs (250 ms por passo @ 50 MHz).
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ULA_SD is
    port (
        clk          : in  std_logic;
        sel          : in  std_logic_vector(3 downto 0);
        reset        : in  std_logic;
        confirm      : in  std_logic;
        resul        : out std_logic_vector(3 downto 0);
        led_zero     : out std_logic;
        led_negative : out std_logic;
        led_overflow : out std_logic;
        led_carry    : out std_logic
    );
end ULA_SD;

architecture comportamento of ULA_SD is
    component debounce_ula is
        port(
            clk        : in  std_logic;
            confirm    : in  std_logic;
            confirm_db : out std_logic;
            pulso      : out std_logic
        );
    end component;

    -- Variáveis da animacao de espera ---------------------------------------------------------- 
    type tipo_estado_led is (animacao_1, animacao_2, animacao_3, animacao_4, animacao_5, animacao_6, animacao_7, animacao_8);
    signal estado_led_at : tipo_estado_led := animacao_1;
    signal balde_load    : integer range 0 to 12500000 := 0;
    ---------------------------------------------------------------------------------------------

    type tipo_estado is (espera_sel, espera_a, espera_b, exe_operacao);
    signal estado_atual  : tipo_estado := espera_sel;
    signal vetor_sel     : std_logic_vector(2 downto 0);
    signal vetor_a       : std_logic_vector(3 downto 0);
    signal vetor_b       : std_logic_vector(3 downto 0);
    signal confirm_pulso : std_logic;
    signal balde_cont    : std_logic_vector(3 downto 0);
    signal ref_cont      : integer range 0 to 3 := 0;
    signal vetor_ref     : std_logic_vector(4 downto 0);
begin

    u_debounce: debounce_ula port map(
        clk        => clk,
        confirm    => confirm,
        confirm_db => open,
        pulso      => confirm_pulso
    );

    process (clk, reset)
    begin
        if reset = '1' then
            estado_atual  <= espera_sel;
            vetor_sel     <= (others => '0');
            vetor_a       <= (others => '0');
            vetor_b       <= (others => '0');
            resul         <= (others => '0');
            estado_led_at <= animacao_1;
            balde_load    <= 0;
            led_zero      <= '0';
            led_negative  <= '0';
            led_overflow  <= '0';
            led_carry     <= '0';
            balde_cont    <= (others => '0');
            ref_cont      <= 0;
            vetor_ref     <= (others => '0');
        elsif rising_edge(clk) then
            if not (estado_atual = exe_operacao) then
                led_zero     <= '0';
                led_negative <= '0';
                led_overflow <= '0';
                led_carry    <= '0';
                resul        <= (others => '0');
              
                case estado_led_at is
                    when animacao_1 =>
                        if balde_load < 12500000 then
                            balde_load   <= balde_load + 1;
                            led_zero     <= '1';
                            led_negative <= '1';
                        else
                            balde_load    <= 0;
                            estado_led_at <= animacao_2;
                        end if;
                    
                    when animacao_2 =>
                        if balde_load < 12500000 then
                            balde_load   <= balde_load + 1;
                            led_negative <= '1';
                            led_overflow <= '1';
                        else
                            balde_load    <= 0;
                            estado_led_at <= animacao_3;
                        end if;

                    when animacao_3 =>
                        if balde_load < 12500000 then
                            balde_load   <= balde_load + 1;
                            led_overflow <= '1';
                            led_carry    <= '1';
                        else
                            balde_load    <= 0;
                            estado_led_at <= animacao_4;
                        end if;

                    when animacao_4 =>
                        if balde_load < 12500000 then
                            balde_load <= balde_load + 1;
                            led_carry  <= '1';
                            resul(3)   <= '1';
                        else
                            balde_load    <= 0;
                            estado_led_at <= animacao_5;
                        end if;

                    when animacao_5 =>
                        if balde_load < 12500000 then
                            balde_load <= balde_load + 1;
                            resul(3)   <= '1';
                            resul(2)   <= '1';
                        else
                            balde_load    <= 0;
                            estado_led_at <= animacao_6;
                        end if;
                    
                    when animacao_6 =>
                        if balde_load < 12500000 then
                            balde_load <= balde_load + 1;
                            resul(2)   <= '1';
                            resul(1)   <= '1';
                        else
                            balde_load    <= 0;
                            estado_led_at <= animacao_7;
                        end if;

                    when animacao_7 =>
                        if balde_load < 12500000 then
                            balde_load <= balde_load + 1;
                            resul(1)   <= '1';
                            resul(0)   <= '1';
                        else
                            balde_load    <= 0;
                            estado_led_at <= animacao_8;
                        end if;

                    when animacao_8 =>
                        if balde_load < 12500000 then
                            balde_load <= balde_load + 1;
                            resul(0)   <= '1';
                            led_zero   <= '1';
                        else
                            balde_load    <= 0;
                            estado_led_at <= animacao_1;
                        end if;
                end case;
            end if;
            
            case estado_atual is
                when espera_sel =>
                    if confirm_pulso = '1' then
                        vetor_sel    <= sel(2 downto 0);
                        estado_atual <= espera_a;
                    end if;

                when espera_a =>
                    if confirm_pulso = '1' then
                        vetor_a      <= sel;
                        estado_atual <= espera_b;
                    end if;

                when espera_b =>
                    if confirm_pulso = '1' then
                        vetor_b      <= sel;
                        estado_atual <= exe_operacao;
                    end if;

                when exe_operacao =>
                    led_zero     <= '0';
                    led_negative <= '0';
                    led_overflow <= '0';
                    led_carry    <= '0';
                    vetor_ref    <= (others => '0');
                    
                    case vetor_sel is
                        when "000" => -- conta do vetor_a até o vetor_b, realizando uma contagem animada
                            if ref_cont < 1 then
                                balde_cont    <= vetor_a;
                                ref_cont      <= ref_cont + 1;
                                balde_load    <= 0;
                                resul         <= vetor_a;
                                estado_led_at <= animacao_1;
                            elsif (ref_cont >= 1) and (unsigned(balde_cont) < unsigned(vetor_b)) then
                                led_zero     <= '0';
                                led_negative <= '0';
                                led_overflow <= '0';
                                led_carry    <= '0';
                                resul        <= balde_cont;
                                
                                case estado_led_at is
                                    when animacao_1 =>
                                        if balde_load < 12500000 then
                                            balde_load <= balde_load + 1;
                                            led_zero   <= '1';
                                        else
                                            balde_load    <= 0;
                                            estado_led_at <= animacao_2;
                                        end if;
                            
                                    when animacao_2 =>
                                        if balde_load < 12500000 then
                                            balde_load   <= balde_load + 1;
                                            led_negative <= '1';
                                        else
                                            balde_load    <= 0;
                                            estado_led_at <= animacao_3;
                                        end if;

                                    when animacao_3 =>
                                        if balde_load < 12500000 then
                                            balde_load   <= balde_load + 1;
                                            led_overflow <= '1';
                                        else
                                            balde_load    <= 0;
                                            estado_led_at <= animacao_4;
                                        end if;

                                    when animacao_4 =>
                                        if balde_load < 12500000 then
                                            balde_load <= balde_load + 1;
                                            led_carry  <= '1';
                                        else
                                            balde_load    <= 0;
                                            estado_led_at <= animacao_5;
                                        end if;

                                    when animacao_5 =>
                                        if balde_load < 1 then
                                            balde_cont <= std_logic_vector(unsigned(balde_cont) + 1);
                                            balde_load <= balde_load + 1;
                                        elsif balde_load < 12500000 then
                                            balde_load <= balde_load + 1;
                                        else
                                            balde_load    <= 0;
                                            estado_led_at <= animacao_1;
                                        end if;

                                    when others => 
                                        estado_led_at <= animacao_1;
                                end case;
                            else
                                resul <= balde_cont;
                                if balde_cont = "0000" then
                                    led_zero <= '1'; 
                                end if;
                            end if;

                        when "001" => -- soma o vetor_a com o vetor_b
                            vetor_ref <= std_logic_vector(unsigned('0' & vetor_a) + unsigned('0' & vetor_b));
                            led_carry <= vetor_ref(4);
                            resul     <= vetor_ref(3 downto 0); 
                            
                            if (vetor_a(3) = vetor_b(3)) and (vetor_ref(4) /= vetor_a(3)) then
                                led_overflow <= '1';
                            end if;
                            
                            if vetor_ref(3 downto 0) = "0000" then
                                led_zero <= '1';
                            end if;

                            if vetor_ref(3) = '1' then
                                led_negative <= '1';
                            end if;

                        when "010" => -- Realiza a subtração do vetor_a com o vetor_b
                            vetor_ref <= std_logic_vector(unsigned('0' & vetor_a) - unsigned('0' & vetor_b));
                            led_carry <= vetor_ref(4);
                            resul     <= vetor_ref(3 downto 0); 
                            
                            if (vetor_a(3) = vetor_b(3)) and (vetor_ref(4) /= vetor_a(3)) then
                                led_overflow <= '1';
                            end if;
                            
                            if vetor_ref(3 downto 0) = "0000" then
                                led_zero <= '1';
                            end if;

                            if vetor_ref(3) = '1' then
                                led_negative <= '1';
                            end if;

                        when "011" => -- Pega o menor entre os dois vetores
                            if signed(vetor_a) <= signed(vetor_b) then
                                vetor_ref <= '0' & vetor_a;
                            else
                                vetor_ref <= '0' & vetor_b;
                            end if;

                            if vetor_ref(3 downto 0) = "0000" then
                                led_zero <= '1';
                            end if;

                            if vetor_ref(3) = '1' then
                                led_negative <= '1';
                            end if;
                            resul <= vetor_ref(3 downto 0); 

                        when "100" => -- Retorna o maior entre os dois vetores
                            if signed(vetor_a) >= signed(vetor_b) then
                                vetor_ref <= '0' & vetor_a;
                            else
                                vetor_ref <= '0' & vetor_b;
                            end if;

                            if vetor_ref(3 downto 0) = "0000" then
                                led_zero <= '1';
                            end if;

                            if vetor_ref(3) = '1' then
                                led_negative <= '1';
                            end if;
                            resul <= vetor_ref(3 downto 0);

                        when "101" => -- Retorna a média aritmética entre os dois vetores
                            vetor_ref <= std_logic_vector(to_signed(
                                (to_integer(signed(vetor_a)) + to_integer(signed(vetor_b))) / 2, 5));

                            if vetor_ref(3 downto 0) = "0000" then
                                led_zero <= '1';
                            end if;

                            if vetor_ref(3) = '1' then
                                led_negative <= '1';
                            end if;
                            resul <= vetor_ref(3 downto 0);

                        when "110" => -- Retorna o 'or' bit a bit de cada vetor
                            vetor_ref <= ('0' & vetor_a) or ('0' & vetor_b);

                            if vetor_ref(3 downto 0) = "0000" then
                                led_zero <= '1';
                            end if;
                            resul <= vetor_ref(3 downto 0);
                        
                        when "111" => -- Retorna o 'and' bit a bit de cada vetor
                            vetor_ref <= ('0' & vetor_a) and ('0' & vetor_b);
                            
                            if vetor_ref(3 downto 0) = "0000" then
                                led_zero <= '1';
                            end if;
                            resul <= vetor_ref(3 downto 0);

                        when others =>
                            resul <= (others => '0');
                    end case;

                    if confirm_pulso = '1' then
                        ref_cont     <= 0;
                        estado_atual <= espera_sel;
                    end if;

                when others =>
                    estado_atual <= espera_sel;
            end case;
        end if;
    end process;
end comportamento;