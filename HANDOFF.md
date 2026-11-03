# HANDOFF

Estado atual (snapshot; reescreva ao fim de cada rodada — não append).

## Fase
Rodada de **autonomia do repositório** (2026-11-04), além do desafio em si:
n- **PLANO.md agora e template do lead**: entrada minima (RELATORIO inteiro + tails), reescrito inteiro (<=4 KB) com passos exatos, armadilha, aceite e plano B por frente; instrucoes p/ agentes embutidas (executar passos exatos, seguir plano B, nunca esperar o lead).

- **Ambiente de teste PROVADO executável num sandbox hostil**: sem `/dev/kvm`, sem
  docker, 2 núcleos, 4 GB. `sh scripts/ambiente.sh` + `sh scripts/tests/run-tests.sh`
  ⇒ `SUITE: PASS` (28 `[PASS]` / 0 `[FAIL]`) em **259 s** sob TCG.
- **Causa raiz das rodadas perdidas** (não era falta de Windows, eram 3 defeitos de setup):
  1. `setup.sh` instalava só curl/wget/git/unzip/xz — nenhum qemu/wimlib — e dizia "pronto";
  2. `docs/evidence/ambiente-teste.md` mandava rodar `scripts/env-setup.sh`, **que não
     existe** (renomeado para `ambiente.sh`): quem obedecia levava "no such file";
  3. `run-tests.sh` escondia a saída do install (`>/dev/null || true`) e devolvia
     `SKIP: qemu ausente` (exit 2), que se lê como "aqui não dá".
- **Falso positivo corrigido**: `ambiente.sh` reportava `virtualizacao: kvm` porque o
  pacote qemu instala `/usr/bin/kvm`; o módulo não existia (`Could not access KVM kernel
  module`). Agora mede `[ -w /dev/kvm ]` e diz TCG. Detector otimista faz agente tentar
  o impossível e gastar a rodada.
- **Novos**: `scripts/doctor.sh` (níveis T0–T4, exit ≠ 0 se nada for executável),
  `scripts/agente.sh` (identidade `A=<nome>` → `git config` + `PRESENCA.md`),
  `hooks/` versionados via `core.hooksPath` (antes: `.git/hooks` não é clonado, então
  todo clone novo nascia sem trava de `main` nem push), `setup.sh` reescrito.
- **Procedência**: `h.sh` fixa `user.name=claude` para todos os agentes, então
  `git log` não distinguia ninguém. Com `A=<nome>` os commits passam a trazer o nome
  real e `PRESENCA.md` registra so `nome data` por linha (minimo, p/ tokens).

## Próximo passo
1. **T3 (em andamento nesta rodada)**: baixar os UUP do 1809 (3,61 GB, `uup_links.sh`
   gerou links válidos) → `converter_iso.sh` → ISO bootável. Faltava `xorriso`/`mkisofs`
   para o conversor: **instalado** (`ambiente.sh` não cuida disso — adicionar).
2. Com a ISO: trocar `sources/boot.wim` pelo WIM modificado e usar **`winpeshl.ini`**
   para o PE iniciar o script sozinho (fecha o "autorun" do plano antigo). Validar em
   TCG com timeout alto, 2º plano. `HIPÓTESE` — nunca tentado aqui; pode falhar por
   tempo/timeout, e falha também é evidência.
3. Itens 1–3 do HANDOFF anterior continuam válidos (drivers em lote por `VEN_`, injeção,
   autorun), agora com harness que de fato roda.

## Premissas (assumidas, sem dono)
- Hardware desconhecido: cobrir chips comuns em lote, como antes.
- A validação de **runtime** de driver Wi-Fi (erro 10) segue fora de alcance de qualquer
  sandbox: exige o adaptador real. Isso é limite do método, não do esforço.

## Riscos abertos
- T3 sem KVM: cada boot de PE do Windows sob TCG pode levar dezenas de minutos; 4 GB de
  RAM é o mínimo apertado para PE. Discos: 3,61 GB UUP + ~5 GB ISO.
- `HANDOFF.md` cresce (PRESENCA.md agora e minima: `nome data`); `HANDOFF` é reescrito e **não** tem `merge=union`
  → dois agentes simultâneos conflitam e o rebase do `post-commit` aborta.

## Bloqueios
- Nenhum bloqueio depende do dono.
- **Nada foi enviado** nesta rodada: os commits estão locais (hook de push desativado de
  propósito com `MM_GUARDA=1`), porque enviar é ação externa e o dono não autorizou
  explicitamente este conteúdo. `HEAD` local = `origin/4.4mmii1` no momento do setup.
