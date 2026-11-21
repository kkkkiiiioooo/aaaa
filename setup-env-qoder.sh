#!/bin/sh
# qoder-setup.sh — bootstrap do ambiente do agente Qoder neste repositório.
#
# Objetivo: num chat novo, um único comando deixa o sandbox pronto para trabalhar na
# branch `desafio`, sem repetir na mão o clone, a configuração da branch `0`, a
# sincronização, a checagem de escrita e a instalação das ferramentas do harness QEMU.
#
# Uso:
#   sh qoder-setup.sh              # bootstrap completo (clona se preciso, instala deps)
#   SKIP_DEPS=1 sh qoder-setup.sh  # pula apt-get (só git + credenciais + sondas)
#   REPO_DIR=/caminho sh qoder-setup.sh
#   BRANCH=desafio REPO_DIR=/data/aaaa sh qoder-setup.sh
#
# Propriedades:
#   - Idempotente: pode rodar de novo; cada etapa detecta o que já está feito.
#   - Não destrutivo: nunca faz reset --hard, checkout --, force-push nem apaga ramo
#     (AGENTS.md, Sync rule). Se a árvore divergiu, informa e para na sincronização.
#   - Não comita nem envia nada; publica é decisão do agente/dono via scripts/salvar.sh.
#
# O que cada etapa faz:
#   1 clone do repo (https://github.com/kkkkiiiioooo/aaaa.git) se o diretório não existe
#   2 credenciais: branch `0` -> setup.sh (helper store + identidade agente) -> volta para `desafio`
#   3 sync: git fetch origin desafio + git merge --ff-only origin/desafio
#   4 dependências do harness: qemu, ovmf, wimtools, mtools, xorriso
#   5 sondas de capacidade: KVM, qemu, OVMF, wimlib, CPU, RAM, disco
#   6 escrita: git push --dry-run origin HEAD
set -u

REPO_URL="${REPO_URL:-https://github.com/kkkkiiiioooo/aaaa.git}"
REPO_DIR="${REPO_DIR:-/data/aaaa}"
BRANCH="${BRANCH:-desafio}"
DEPS="qemu-system-x86 qemu-utils ovmf wimtools mtools xorriso python3"
FAILED=0

pass() { printf 'PASS  %s\n' "$1"; }
warn() { printf 'WARN  %s\n' "$1"; }
fail() { printf 'FAIL  %s\n' "$1"; FAILED=$((FAILED + 1)); }
step() { printf '\n== %s\n' "$1"; }

echo "== qoder-setup: $(date -u '+%Y-%m-%dT%H:%M:%SZ') host=$(uname -sr) user=$(whoami)"

# ---------------------------------------------------------------- 1. repositório
step "1. repositório"
if [ -d "$REPO_DIR/.git" ]; then
  pass "repo já presente em $REPO_DIR"
else
  mkdir -p "$(dirname "$REPO_DIR")"
  if git clone -q "$REPO_URL" "$REPO_DIR"; then
    pass "clonado em $REPO_DIR"
  else
    fail "clone falhou ($REPO_URL em $REPO_DIR) — confira rede/URL"
    exit 1
  fi
fi
cd "$REPO_DIR" || exit 1

# ------------------------------------------------------- 2. credenciais (branch 0)
step "2. configuração da branch 0 (credenciais)"
CFG_HELPER=$(git config --local --get-all credential.helper 2>/dev/null || true)
CRED_FILE="$(git rev-parse --absolute-git-dir)/aaaa-gh"
if [ -f "$CRED_FILE" ] && printf '%s' "$CFG_HELPER" | grep -q 'aaaa-gh'; then
  pass "helper de credenciais já configurado (setup.sh já rodou neste clone)"
else
  git fetch -q origin 0 2>/dev/null || true
  if git rev-parse --verify -q origin/0 >/dev/null; then
    git checkout -q -B 0 origin/0 || git checkout -q 0 || true
    if sh setup.sh; then
      pass "setup.sh executado"
    else
      fail "setup.sh retornou erro — credencial pode não ter sido instalada"
    fi
  else
    fail "branch 0 não encontrada no remoto"
  fi
fi
if git config --local --get-all credential.helper | grep -q 'aaaa-gh' && [ -f "$CRED_FILE" ]; then
  pass "credential.helper = store --file=.../aaaa-gh ($(ls -l "$CRED_FILE" | awk '{print $1}'))"
else
  warn "helper ausente; pushes vão pedir credencial"
fi

# ------------------------------------------------------------- 3. branch + sync
step "3. branch de trabalho e sincronização"
git fetch -q origin "$BRANCH" 2>/dev/null || warn "fetch origin/$BRANCH falhou (rede?)"
if git rev-parse --verify -q "$BRANCH" >/dev/null; then
  git checkout -q "$BRANCH" || fail "checkout $BRANCH falhou"
elif git rev-parse --verify -q "origin/$BRANCH" >/dev/null; then
  git checkout -q -b "$BRANCH" "origin/$BRANCH" || fail "checkout -b $BRANCH falhou"
else
  fail "branch $BRANCH não existe local nem remota"
  exit 1
fi
if git merge --ff-only -q "origin/$BRANCH" 2>/dev/null; then
  pass "sincronizado com origin/$BRANCH ($(git rev-parse --short HEAD) $(git log -1 --pretty=%s | cut -c1-60))"
else
  warn "não foi possível adiantar rápido: há commits locais ou divergência. Integre com merge manual (nunca force-push)."
fi
printf 'HEAD em: %s\n' "$(git rev-parse --abbrev-ref HEAD)"

# ------------------------------------------------------------------ 4. dependências
step "4. dependências do harness"
if [ "${SKIP_DEPS:-0}" = "1" ]; then
  warn "SKIP_DEPS=1 — nenhuma instalação feita"
else
  MISSING=""
  for p in $DEPS; do
    apt-cache policy "$p" 2>/dev/null | grep -q 'Installed: (none)' && MISSING="$MISSING $p"
  done
  if [ -z "$MISSING" ]; then
    pass "todas as dependências já instaladas"
  else
    echo "instalando:$MISSING"
    export DEBIAN_FRONTEND=noninteractive
    if apt-get update -qq && apt-get install -y -qq $MISSING >/tmp/qoder-setup-apt.log 2>&1; then
      pass "apt-get install ok (log: /tmp/qoder-setup-apt.log)"
    else
      fail "apt-get install falhou — veja /tmp/qoder-setup-apt.log"
    fi
  fi
fi

# --------------------------------------------------------------------- 5. sondas
step "5. sondas de capacidade do sandbox"
probe() { printf '  %-22s %s\n' "$1" "$2"; }
[ -e /dev/kvm ] && pass "KVM disponível (/dev/kvm) — boot rápido" \
                || warn "sem KVM — QEMU roda em TCG (lento, mas o dono autorizou)"
probe "vmx/svm na CPU" "$(grep -c -E 'vmx|svm' /proc/cpuinfo) flags"
probe "qemu-system-x86_64" "$(command -v qemu-system-x86_64 || echo AUSENTE)"
probe "OVMF_CODE.fd" "$([ -f /usr/share/OVMF/OVMF_CODE.fd ] && echo presente || echo AUSENTE)"
probe "OVMF_VARS.fd" "$([ -f /usr/share/OVMF/OVMF_VARS.fd ] && echo presente || echo AUSENTE)"
probe "wimlib-imagex" "$(command -v wimlib-imagex || echo AUSENTE)"
probe "mformat/xorriso" "$(command -v mformat >/dev/null && command -v xorriso >/dev/null && echo ok || echo incompleto)"
probe "python3" "$(command -v python3 || echo AUSENTE)"
probe "CPU / RAM" "$(nproc) núcleos, $(awk '/MemTotal/{printf "%.0f GB", $2/1048576}' /proc/meminfo)"
probe "espaço livre" "$(df -h "$(git rev-parse --show-toplevel)" | awk 'NR==2{print $4}')"

# --------------------------------------------------------------------- 6. escrita
step "6. confirmação de escrita no remoto"
if git push --dry-run -q origin HEAD 2>/dev/null; then
  pass "ESCRITA_OK origin/$BRANCH (dry-run; nada foi enviado)"
else
  fail "ESCRITA_FALHOU origin/$BRANCH — revise a credencial no GitHub"
fi

# --------------------------------------------------------------------- resumo
step "resumo"
printf 'branch=%s head=%s repo=%s\n' "$(git rev-parse --abbrev-ref HEAD)" "$(git rev-parse --short HEAD)" "$REPO_DIR"
if [ "$FAILED" -eq 0 ]; then
  echo "setup completo. Próximos passos do harness:"
  echo "  sh scripts/verify-images.sh              # prova as imagens divididas"
  echo "  sh qemu/build-media.sh                   # remonta F1 e F2 em qemu/work/"
  echo "  sh qemu/build-iso.sh qemu/work/f1.wim    # ISO UEFI bootável"
  echo "  sh qemu/audit.sh <argv...>               # gate anti-impugnação"
  echo "  BUDGET=600 bash qemu/run-winre.sh        # boot do WinRE em TCG"
  echo "  sh scripts/salvar.sh \"msg\" caminho...    # commit + push em $BRANCH"
else
  echo "$FAILED etapa(s) com FAIL — resolva antes de rodar experimentos."
fi
exit $([ "$FAILED" -eq 0 ] && echo 0 || echo 1)
