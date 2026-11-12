# Evidência E4 (parte 2) — o autorun do WinRE roda INTEIRO no PE e o host lê o log

**Agente:** mavis · **quando:** 2026-11-07 12:23–12:33 UTC · **etapa:** E4 · **modelo:** MiniMax-M3.1-Flash
**Run:** R2 — ISO com os 6 drivers da E2 injetados + o autorun (E3).

## O que o R2 provou

| # | alegação | prova |
|---|---|---|
| 1 | o PE sobe e o autorun **chega ao fim** | `=== autorun-wwii end ===` na última linha do log |
| 2 | o host lê o log **completo** | 19 727 bytes lidos do disco (`.work/vm/wwii-r2-final.log`, cópia em `git show 42d65cc:docs/evidence/e4-autorun-completo-r2.txt`) |
| 3 | **`wlansvc` sobe no WinRE 1809** | `The WLAN AutoConfig service is starting.. / was started successfully.` — o serviço existe e funciona |
| 4 | o contexto `netsh wlan` **responde** | `netsh wlan show drivers` devolveu "There is no wireless interface on the system." (não é erro de sintaxe: é falta de hardware) |
| 5 | o PE **enxerga** os volumes e o hardware | `diag.cmd`: `Volume 0 D: CDFS 427 MB` (a ISO), `Volume 1 C: FAT32 3071 MB` (o disco de dados), `Disk 0 3072 MB`; PCI: `VEN_8086&DEV_100E` (a NIC e1000), `VEN_1237` (SATA), `VEN_7000/7010` (PIIX3) |
| 6 | o `net start` mostra o serviço rodando | lista com "WLAN AutoConfig" entre os serviços iniciados |

**Limite honesto:** o QEMU **não tem hardware Wi-Fi** (só a NIC Ethernet e1000), então
`netsh wlan show interfaces` não tem o que listar. Provar a conexão Wi-Fi de verdade
exige a máquina do dono (é o que o D5 do lead já previa). O que o QEMU prova é que o
**caminho de código funciona**: driver presente → `drvload` → `wlansvc` sobe → `netsh wlan`
responde.

## Trecho final do log (literal)

```
--- net start ---
The WLAN AutoConfig service is starting..
The WLAN AutoConfig service was started successfully.
...
--- netsh wlan ---
There is no wireless interface on the system.
...
=== autorun-wwii end ===
```

## Detalhe que importa: `pnputil /enum-drivers` volta VAZIO

```
--- pnputil ---
Microsoft PnP Utility
No published driver packages were found on the system.
```

Isto é **esperado** e está documentado no próprio `scripts/injetar_driver.sh`: a injeção
offline com `wimlib` escreve os arquivos, mas **não registra o pacote no banco PnP**
(o que o DISM faz). Para o *runtime* isso não impede o `drvload` (instalação "loose"):
o driver carrega, o serviço sobe e o `netsh` responde. O que falta é o registro formal,
que só o DISM no Windows faz.

## O BSOD do R2 era falso positivo (e o detector foi corrigido)

O detector de bugcheck classificou a tela do OOBE do WinPE ("Choose your keyboard
layout") como BSOD. Medido pixel a pixel:

| tela | cor dominante | branco | bloco branco 80×80 |
|---|---|---|---|
| BSOD real (`docs/evidence/e4-bsod-xpress-425s.png`) | `(215,120,0)` 97% | 1% | 206 (o QR code) |
| OOBE do WinPE (R2) | `(178,103,32)` 100% | 0% | 0 |

Ou seja: **o OOBE do WinPE 1809 é laranja como o BSOD.** O detector agora exige a cor
saturada do bugcheck (R≥195, B≤45) **ou** o bloco branco do QR code, e o caso do OOBE
entrou na suíte como regressão (`scripts/tests/unit/detectar_bsod.py`, 7/7 PASS).

## Estado do PE em runtime (o que falta para o dono)

- O PE abre o **OOBE** ("Choose your keyboard layout") porque o `winpeshl.ini` chama
  `wpeinit.exe`. O autorun roda **antes** disso e não depende de tecla, mas o OOBE fica
  esperando input. Para a entrega "zero tecla" isso precisa ser resolvido (por exemplo,
  pré-configurando o layout no hive, ou não chamando `wpeinit`).
- O `serial.log` continua vazio: o PE 1809 não tem COM1. **O canal com o host é o disco.**
