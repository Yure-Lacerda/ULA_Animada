# ULA de 4 bits com FSM e Animações em LED (FPGA Spartan-3AN)

Implementação em VHDL de uma Unidade Lógica e Aritmética (ULA) de 4 bits projetada para a placa **Xilinx Spartan-3AN Starter Kit** (clock de 50 MHz). O projeto combina operações lógico-aritméticas completas, sinalização de flags de status, tratamento de debounce em hardware e animações visuais temporizadas nos 8 LEDs da placa.

---

https://github.com/user-attachments/assets/00fcf061-e313-4667-b25f-e2609cc4e80b

---

## Destaques de Arquitetura

* **Entrada Sequencial via Máquina de Estados (FSM):** Como a placa Spartan-3AN Starter Kit dispõe de 4 chaves deslizantes (*slide switches*), a arquitetura utiliza uma FSM de 4 estados para reaproveitar o mesmo barramento `sel(3 downto 0)` e o botão `confirm` para configurar a operação e os dois operandos em sequência, sem necessidade de hardware externo.
* **Filtro de Debounce e Detector de Borda (`debounce_ula.vhd`):** Módulo dedicado que elimina a trepidação mecânica do botão físico por meio de uma janela de estabilização de **20 ms** ($1.000.000$ de ciclos @ $50\text{ MHz}$) e gera um pulso síncrono de exatamente **1 ciclo de clock** (`pulso`) para evitar saltos acidentais entre os estados.
* **Feedback Visual nos LEDs:** Enquanto aguarda a entrada dos dados, os 8 LEDs da placa (`led_zero`, `led_negative`, `led_overflow`, `led_carry` e `resul[3:0]`) executam uma varredura luminosa contínua com passo de **250 ms** ($12.500.000$ ciclos @ $50\text{ MHz}$).

---

## Operações Suportadas

A seleção da operação é feita nos 3 bits menos significativos das chaves (`sel[2:0]`) durante o primeiro estado da FSM:

| Código (`sel[2:0]`) | Operação | Descrição | Flags Atualizadas |
| :---: | :--- | :--- | :--- |
| `000` | **Contador Animado** | Conta progressivamente de `A` até `B` com varredura nos LEDs de status | `Zero` |
| `001` | **Soma** | Calcula a adição `A + B` em 4 bits | `Carry`, `Overflow`, `Zero`, `Negative` |
| `010` | **Subtração** | Calcula a subtração `A - B` em 4 bits | `Carry`, `Overflow`, `Zero`, `Negative` |
| `011` | **Mínimo** | Retorna o menor valor (com sinal) entre `A` e `B` | `Zero`, `Negative` |
| `100` | **Máximo** | Retorna o maior valor (com sinal) entre `A` e `B` | `Zero`, `Negative` |
| `101` | **Média Aritmética** | Calcula `(A + B) / 2` considerando operandos com sinal | `Zero`, `Negative` |
| `110` | **OR Lógico** | Operação bit a bit `A OR B` | `Zero` |
| `111` | **AND Lógico** | Operação bit a bit `A AND B` | `Zero` |

---

## Fluxo de Operação na Placa (FSM)

1. **`espera_sel` (Estado Inicial):** Os LEDs exibem a animação de espera. Ajuste o código da operação nas chaves `sel[2:0]` e pressione `confirm`.
2. **`espera_a`:** Ajuste o valor binário do **Operando A** nas 4 chaves `sel[3:0]` e pressione `confirm`.
3. **`espera_b`:** Ajuste o valor binário do **Operando B** nas 4 chaves `sel[3:0]` e pressione `confirm`.
4. **`exe_operacao`:** A animação de espera é interrompida e os LEDs exibem o resultado em `resul[3:0]` juntamente com as flags ativas (`Zero`, `Negative`, `Overflow` e `Carry`).
5. **Nova Operação:** Pressione `confirm` novamente para retornar ao estado `espera_sel` (ou acione `reset` a qualquer momento para reiniciar o sistema).

---

## Mapeamento de Pinos (`ULA_SD.ucf`)

O arquivo de restrições físicas (`ULA_SD.ucf`) mapeia os sinais da entidade top-level para os periféricos da placa **Spartan-3AN Starter Kit** operando no padrão lógico `LVCMOS33`:

| Sinal VHDL | Direção | Periférico na Placa | Pino FPGA (`LOC`) | Configuração Extra |
| :--- | :---: | :--- | :---: | :--- |
| `clk` | `IN` | Oscilador On-board (50 MHz) | `E12` | `LVCMOS33` |
| `reset` | `IN` | Botão `BTN_EAST` | `T16` | `LVCMOS33 \| PULLDOWN` |
| `confirm` | `IN` | Botão `BTN_SOUTH` | `T15` | `LVCMOS33 \| PULLDOWN` |
| `sel[3:0]` | `IN` | Chaves `SW3`, `SW2`, `SW1`, `SW0` | `U2`, `U3`, `T4`, `V8` | `LVCMOS33` |
| `resul[3:0]` | `OUT` | LEDs `LED3`, `LED2`, `LED1`, `LED0` | `W21`, `Y22`, `V20`, `R20` | `SLEW = SLOW \| DRIVE = 8` |
| `led_zero` | `OUT` | `LED7` (Flag Zero) | `W22` | `SLEW = SLOW \| DRIVE = 8` |
| `led_negative` | `OUT` | `LED6` (Flag Negative) | `W20` | `SLEW = SLOW \| DRIVE = 8` |
| `led_overflow` | `OUT` | `LED5` (Flag Overflow) | `Y21` | `SLEW = SLOW \| DRIVE = 8` |
| `led_carry` | `OUT` | `LED4` (Flag Carry) | `U20` | `SLEW = SLOW \| DRIVE = 8` |

---

## Simulação e Verificação (Testbench)

O arquivo `tb_ULA_SD.vhd` valida o comportamento temporal e lógico do sistema completo (ULA + Debouncer) com clock simulado de **50 MHz** (período de $20\text{ ns}$):

* **Simulação Realista de Botão (`apertar_confirm`):** Procedimento dedicado que mantém o sinal `confirm` em nível alto por **25 ms** (ultrapassando a janela de 20 ms do filtro de debounce) seguido de **5 ms** em nível baixo, garantindo a verificação fiel das transições de estado da FSM.
* **Casos de Teste Automatizados:**
  1. **Reset Assíncrono:** Inicialização do sistema em `espera_sel` com limpeza dos registradores.
  2. **Soma (`001`):** `5 + 4 = 9` (`"0101" + "0100" = "1001"`), validando o cálculo e o retorno ao estado inicial após nova confirmação.
  3. **Subtração com Flag Zero (`010`):** `7 - 7 = 0` (`"0111" - "0111" = "0000"`), validando o acionamento simultâneo de `led_zero = '1'`.
  4. **AND Lógico (`111`):** `"1100" AND "1010" = "1000"`, validando a operação bit a bit.

---

## Estrutura do Repositório

```text
ULA_Animada/
├── ULA_SD.vhd          # Módulo Top-Level (FSM, datapath da ULA, flags e controle dos LEDs)
├── debounce_ula.vhd    # Filtro de debounce síncrono e gerador de pulso de borda de subida
├── tb_ULA_SD.vhd       # Testbench para verificação funcional e temporal da ULA e do debounce
├── ULA_SD.ucf          # Arquivo de restrições físicas e mapeamento de pinos (Spartan-3AN)
└── README.md           # Documentação do projeto
