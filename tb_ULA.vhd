library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_ULA_SD is
-- Entidade de testbench não possui portas
end tb_ULA_SD;

architecture sim of tb_ULA_SD is

    -- Declaração do componente a ser testado (UUT)
    component ULA_SD is
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
    end component;

    -- Sinais internos para conectar na UUT
    signal clk_tb          : std_logic := '0';
    signal sel_tb          : std_logic_vector(3 downto 0) := (others => '0');
    signal reset_tb        : std_logic := '0';
    signal confirm_tb      : std_logic := '0';
    
    -- Sinais de saída
    signal resul_tb        : std_logic_vector(3 downto 0);
    signal led_zero_tb     : std_logic;
    signal led_negative_tb : std_logic;
    signal led_overflow_tb : std_logic;
    signal led_carry_tb    : std_logic;

    -- Período do Clock (50 MHz = 20 ns)
    constant CLK_PERIOD : time := 20 ns;

begin

    -- Instanciação da ULA_SD
    uut: ULA_SD port map (
        clk          => clk_tb,
        sel          => sel_tb,
        reset        => reset_tb,
        confirm      => confirm_tb,
        resul        => resul_tb,
        led_zero     => led_zero_tb,
        led_negative => led_negative_tb,
        led_overflow => led_overflow_tb,
        led_carry    => led_carry_tb
    );

    -- Processo de geração do Clock
    clk_process : process
    begin
        clk_tb <= '0';
        wait for CLK_PERIOD / 2;
        clk_tb <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    -- Processo de estímulos
    stim_proc: process
        -- Procedimento auxiliar para simular um aperto de botão real (vencendo o debounce)
        procedure apertar_confirm is
        begin
            confirm_tb <= '1';
            wait for 25 ms; -- Tempo mantido pressionado para passar pelo debouncer
            confirm_tb <= '0';
            wait for 5 ms;  -- Tempo de soltura antes do próximo comando
        end procedure;
    begin
        -- 1. Reset inicial do sistema
        reset_tb <= '1';
        wait for 100 ns;
        reset_tb <= '0';
        wait for 100 ns;

        -- =================================================================
        -- TESTE 1: SOMA (5 + 4 = 9)
        -- =================================================================
        -- Seleciona operação 001 (Soma)
        sel_tb <= "0001";
        apertar_confirm;

        -- Insere Operando A = 5 ("0101")
        sel_tb <= "0101";
        apertar_confirm;

        -- Insere Operando B = 4 ("0100")
        sel_tb <= "0100";
        apertar_confirm;

        -- Aguarda um tempo no estado exe_operacao para observar o resultado ("1001")
        wait for 10 ms;

        -- Aperta confirm novamente para voltar ao estado espera_sel
        apertar_confirm;

        -- =================================================================
        -- TESTE 2: SUBTRAÇÃO (7 - 7 = 0) -> Deve acender led_zero
        -- =================================================================
        -- Seleciona operação 010 (Subtração)
        sel_tb <= "0010";
        apertar_confirm;

        -- Insere Operando A = 7 ("0111")
        sel_tb <= "0111";
        apertar_confirm;

        -- Insere Operando B = 7 ("0111")
        sel_tb <= "0111";
        apertar_confirm;

        -- Aguarda no estado exe_operacao para observar resultado ("0000") e led_zero = '1'
        wait for 10 ms;

        -- Volta ao início
        apertar_confirm;

        -- =================================================================
        -- TESTE 3: OPERAÇÃO AND ("1100" AND "1010" = "1000")
        -- =================================================================
        sel_tb <= "0111"; -- Operação 111 (AND)
        apertar_confirm;

        sel_tb <= "1100"; -- Operando A
        apertar_confirm;

        sel_tb <= "1010"; -- Operando B
        apertar_confirm;

        wait for 10 ms;

        -- Fim da simulação
        assert false report "Simulacao concluida com sucesso!" severity failure;
        wait;
    end process;

end sim;
