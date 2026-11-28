# INDEX — mapa do repositório (leia primeiro, depois `STATE.md`)

Projeto: recuperar o Wi-Fi (BCM4356, erro 10) de um Xiaomi Mi Pad 2 só com WinRE + `cmd` + texto digitado. Prova em QEMU antes de hardware.
Branch única: `desafio`. Um agente por vez. Detalhes ficam nos arquivos abaixo: leia só o que a tarefa pedir.

## Ordem de leitura

1. `INDEX.md` (este) e `STATE.md` (estado atual, feito/próximo/bloqueios).
2. Só se for mudar algo: `AGENTS.md` (regras), `GOAL.md` (objetivo e restrições).
3. Só se a tarefa tocar o tema: o arquivo da tabela abaixo.

## Raiz

| Arquivo | O que é |
|---|---|
| `AGENTS.md` | Regras de agente: sincronização, evidência, restrições (193 linhas) |
| `GOAL.md` | Missão e restrições rígidas |
| `README.md` | Visão geral do desafio e organização |
| `TODO.md` | Plano amplo e ideias do dono (139 linhas) |
| `ANOTACOES-IMPORTANTES.md` | Notas canônicas (dispositivo, canais) |
| `hypotheses.md` | Hipóteses (não são fatos) |
| `setup.sh`, `qoder-setup.sh` | Preparação do ambiente efêmero |
| `projeto.gpg` | Arquivo cifrado (não ler) |
| `.opencode/` | Configuração de agente |

## Pastas

| Pasta | Conteúdo | Quando abrir |
|---|---|---|
| `docs/` | `00` visão, `01` restrições, `02` estado do dispositivo, `03` driver Wi-Fi erro 10, `04` fidelidade, `05` offline servicing, `06` auditoria 1809, `07` inventário. `DOCS-BUNDLE.md` junta tudo (grande, evitar) | Para entender um tema |
| `experiments/` | `README.md` = quadro de experimentos (E0.1–E7); `E1-…`, `E3b-…`, `E7-…`; `templates/` | Antes de rodar ou registrar experimento |
| `qemu/` | Scripts de boot do WinRE (`run-winre*.sh`, `build-*.sh`, `mon.py`, `audit.sh`) e `README.md` | Para E1/E1b |
| `scripts/` | `salvar.sh` (commit+push), `verify-*.sh`, `prepare-ascii-transfer.py`, `winre-*.js`, `advisor-request.py` | Para tarefas de automação |
| `drivers/` | `estado-dispositivo/`, `mipad2-oficial/`, `nvram-delta/` (67 arquivos) | Para trabalho de driver/nvram |
| `inventory/` | `names-only/` (nomes por tipo) + `README.md` | Para consultar o que existe nas imagens |
| `prompts/` | `advisor.md` (briefing), `advisor-resposta.md` (orientação recente), histórico e anexos | Só para estratégia de recuperação |
| `winre-1809-oficial-intacta/` | WIM 1809 oficial em partes + SHA256SUMS | Nunca editar; trabalhar em cópias |
| `winre-fabrica-10586-424MB/` | WIM de fábrica 10586 em partes + SHA256SUMS | Nunca editar; trabalhar em cópias |

## Comandos curtos

- Sincronizar: `git fetch origin desafio && git merge --ff-only origin/desafio`
- Salvar: `scripts/salvar.sh "msg" caminho...` (sempre caminhos explícitos)
- Buscar sem ler tudo: `grep -rl termo .` e `sed -n 1,30p arq`
- Histórico recente: `git log -5 --oneline`

## Armadilhas de contexto

- Não use `cat` em `TODO.md`, `AGENTS.md` ou `DOCS-BUNDLE.md` inteiros; a célula E1b em `TODO.md` é muito longa (linhas 19–82).
- Resultado de QEMU/mock nunca é prova (regra de evidência em `AGENTS.md`).
- Não commitar imagens geradas, logs ou segredos.
