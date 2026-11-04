# MELHORIAS — Propostas técnicas para profissionalizar o repositório

> Gerado em: 2026-11-04 | Branch: wwii | Revisão: 1.0

---

## 1. ORQUESTRAÇÃO — Lease e bloqueio de etapas

### Problema atual
`etapa.sh` usa arquivo local (`ETAPAS.md`) como lock. Dois agentes em paralelo
podem fazer append simultâneo, corrompendo o log de reclamações.

### Solução recomendada
| # | Método | Complexidade | Impacto |
|---|--------|-------------|---------|
| A | `flock` em `.work/etapa.lock` antes de append | Baixa | Atômico no mesmo host |
| B | Git lock file: `git notes` para estado das etapas | Média | Atômico em repos distintos |
| C | Webhook GitHub Actions como árbitro central | Alta | Funciona entre máquinas |
| D | SQLite com WAL em `.work/etapas.db` | Média | ACID, sem conflito merge |
| E | `etapa.sh` via REST num micro servidor em background | Alta | Multi-host real |

**Recomendação: A (imediato) + D (médio prazo)**

```sh
# Implementação A — adicionar no etapa.sh antes de todo append:
(flock -x 9; printf '%s\n' "$LINHA" >> "$F") 9>.work/etapa.lock
```

---

## 2. HANDOFF.md — Merge conflict em paralelo

### Problema documentado no próprio HANDOFF.md
> "HANDOFF.md não tem merge=union: dois agentes simultâneos conflitam"

### Soluções
| # | Método | Complexidade |
|---|--------|-------------|
| A | `.gitattributes`: `HANDOFF.md merge=union` | Mínima |
| B | Separar em `HANDOFF-<agente>.md` + script de merge | Baixa |
| C | SQLite: tabela `handoff(agente, chave, valor, ts)` | Média |
| D | HANDOFF como JSON + `jq` para merge | Baixa |
| E | Branch separada `handoff/` por agente + rebase no plano | Média |

**Recomendação: A + B**

```sh
# .gitattributes
echo 'HANDOFF.md merge=union' >> .gitattributes
echo 'PRESENCA.md merge=union' >> .gitattributes
```

---

## 3. DOCTOR.SH — Saída legível para agentes

### Problema
`doctor.sh` produz saída narrativa. Agente precisa fazer `sed`/`grep` para saber
o nível atingível, desperdiçando tokens e aumentando risco de má interpretação.

### Solução: modo machine-readable
| # | Formato | Exemplo |
|---|---------|---------|
| A | `KEY=VALUE` por linha (parseable com `source`) | `T0=sim T1=sim T2=nao` |
| B | JSON via `jq` ou printf | `{"T0":"sim","T1":"nao"}` |
| C | Exit code semântico (bit mask) | bit0=T0, bit1=T1... |
| D | Arquivo `.work/doctor-cache.env` + TTL 5 min | Evita re-rodar toda sessão |
| E | Flag `--json` / `--env` / `--human` | Compatível com uso atual |

**Recomendação: A + D + E**

```sh
# doctor.sh --env → uma linha parseable
# doctor.sh --json → JSON
# doctor.sh (sem flag) → humano atual
```

---

## 4. SCRIPTS — Ausência de testes unitários

### Problema
Suite testa E1-E4 mas os próprios scripts auxiliares (etapa.sh, relatorio.sh,
problema.sh) não têm testes. Um bug em `etapa.sh` trava todo o pipeline.

### Soluções
| # | Framework | Instalação |
|---|-----------|-----------|
| A | [bats-core](https://github.com/bats-core/bats-core) | `apt install bats` / `npm i -g bats` |
| B | shunit2 | `apt install shunit2` |
| C | roundup | `curl https://bmizerany.github.com/roundup/roundup.sh|sh` |
| D | Funções shell puras + `assert.sh` inline | Zero deps |
| E | GitHub Actions com matrix de SH e BASH | CI automático |

**Recomendação: A (bats) em `scripts/tests/unit/`**

```sh
# Instalar bats
apt install -y bats
# Rodar
bats scripts/tests/unit/
```

---

## 5. AGENTE.SH — Ausência de timeout e watchdog

### Problema
Agente pode travar em `nohup <cmd>` sem ninguém perceber. HANDOFF pode ficar
desatualizado por horas até lease expirar (90 min).

### Soluções
| # | Método | Exemplo |
|---|--------|---------|
| A | `timeout N cmd` em todos os comandos longos | `timeout 3600 sh run-vm.sh` |
| B | Watchdog em background com `kill -0 $PID` | Mata se PID morreu |
| C | `scripts/watchdog.sh` que verifica lease e faz `liberar` | Autônomo |
| D | Systemd timer (se disponível) | `systemctl --user` |
| E | GitHub Actions `timeout-minutes` por step | No CI |

**Recomendação: A + C**

```sh
# watchdog.sh — verificar se agente ativo ainda existe
sh scripts/etapa.sh status | grep ativa | awk '{print $1}' | while read e; do
  sh scripts/etapa.sh verificar "$e" || sh scripts/etapa.sh liberar "$e"
done
```

---

## 6. PRESENÇA E LOGS — Rastreabilidade

### Problema
`PRESENCA.md` só registra início e push. Sem timestamp de fim de rodada, é
impossível medir duração real de cada agente.

### Melhoria proposta
| # | Campo extra | Valor |
|---|------------|-------|
| A | `nome fim <dataUTC> <duração>` | Mede eficiência por agente |
| B | `nome etapa <E> <acao> <ts>` | Granularidade por etapa |
| C | Métricas em `.work/metrics.json` | Mínimo no PRESENCA |
| D | `scripts/painel.sh` com colunas de duração | Visão lead |
| E | Badge no README com % etapas concluídas | Visibilidade |

**Recomendação: A + D** (painel.sh já existe, expandir)

---

## 7. INICIAR.SH — Ausência de validação de integridade

### Problema
`iniciar.sh` não verifica se o clone está íntegro antes de rodar `h.sh`.
Um clone parcial (rede caída) passa silenciosamente para o próximo passo.

### Solução
```sh
# Adicionar após clone:
git fsck --no-dangling 2>&1 | grep -q "^error:" && { echo "clone corrompido"; exit 1; }
```

| # | Verificação | Custo |
|---|------------|-------|
| A | `git fsck --no-dangling` | Baixo |
| B | SHA dos scripts críticos em `.checksums` | Médio |
| C | `git verify-commit HEAD` (GPG) | Alto, requer chave |
| D | `git status --short` vazio = limpo | Mínimo |
| E | `git diff HEAD --stat` para detectar modificações | Rápido |

---

## 8. COMUNICAÇÃO LEAD ↔ AGENTE

### Problema
O único canal é `RELATORIO.md` via branch `relatorio`. Latência alta: agente
precisa fazer push + lead precisa puxar para ver.

### Alternativas
| # | Canal | Latência | Deps |
|---|-------|----------|------|
| A | GitHub Issues via API + `gh` CLI | 1–5 min | `gh` |
| B | ntfy.sh (push notification) | <5 s | `curl` |
| C | Telegram Bot API | <1 s | `curl` |
| D | GitHub Discussions | 1–5 min | `gh` |
| E | Arquivo em branch `signal/` com webhook trigger | 1–2 min | Zero |

**Recomendação: B (ntfy.sh) como notificação de bloqueio crítico**

```sh
# Notificar lead em bloqueio
curl -d "BLOQUEIO E2: sem drivers WiFi disponíveis" ntfy.sh/aaaa-lead
```

---

## 9. BUSCAR_DRIVER.PY — Ausência de cache local

### Problema
Cada rodada que busca drivers por `VEN_` refaz requests HTTP. Se o agente
morrer no meio do download, perde tudo.

### Soluções
| # | Método | Ferramenta |
|---|--------|-----------|
| A | Cache em `.work/driver-cache/` por VEN_ | `sha256sum` para validar |
| B | SQLite: `driver_cache(ven, path, hash, ts)` | `python3 -m sqlite3` |
| C | `wget --continue` / `curl -C -` para retomar | Nativo |
| D | Hash do `.cab` antes de injetar | Evita reinjeção |
| E | `aria2c -x4` para downloads paralelos | Mais rápido |

**Recomendação: A + C + D**

```sh
pip install aria2p --break-system-packages  # alternativa E
aria2c -x4 -d .work/driver-cache/ "$URL"
```

---

## 10. AGENTS.MD — Instruções ambíguas para IAs novas

### Problema
Agente novo sem contexto lê "resolva sozinho" mas não sabe a ordem de leitura
dos arquivos nem qual ferramenta usar em cada situação.

### Melhoria
Adicionar seção `## Decisão rápida` em AGENTS.md:

```
## Decisão rápida (fluxograma de 10 s)
Preciso de rede?       → ver T0..T4 em doctor.sh
Qual etapa livre?      → sh scripts/etapa.sh status
Travar bloqueio?       → sh scripts/problema.sh buscar <termo>
Driver não acha?       → buscar_driver.py + VEN_ do DOSSIE.md
Comunicar lead?        → sh scripts/relatorio.sh estado "<msg>"
```

---

## Prioridade sugerida

| Prioridade | Item | Esforço | Impacto |
|-----------|------|---------|---------|
| P0 (imediato) | 2 — merge=union .gitattributes | 2 min | Evita corrupção |
| P0 (imediato) | 1 — flock no etapa.sh | 10 min | Evita race condition |
| P1 (curto prazo) | 3 — doctor.sh --env | 20 min | Tokens economizados |
| P1 (curto prazo) | 7 — git fsck no iniciar.sh | 5 min | Resiliência |
| P2 (médio prazo) | 4 — bats unit tests | 2 h | Confiança CI |
| P2 (médio prazo) | 5 — watchdog.sh | 1 h | Auto-recuperação |
| P3 (backlog) | 8 — ntfy.sh para lead | 30 min | UX do lead |
| P3 (backlog) | 9 — cache de drivers | 1 h | Velocidade E2 |
| P3 (backlog) | 10 — fluxograma AGENTS.md | 15 min | Onboarding |
| P3 (backlog) | 6 — métricas presença | 30 min | Visibilidade |
