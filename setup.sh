#!/bin/sh
# setup.sh - unico ponto de entrada de uma conversa nova. Idempotente.
#
# Faz, nesta ordem:
#   1. instala o que falta (sem engolir erro de instalacao)
#   2. ativa os hooks versionados (core.hooksPath)  -> main protegida + push + presenca
#   3. registra o agente e o horario em PRESENCA.md (A=<nome> sh setup.sh)
#   4. roda o doctor e diz o que da para executar aqui
#
# Antes este arquivo so instalava curl/wget/git/unzip/xz e escrevia "[setup] pronto",
# sem qemu nem wimlib: o teste seguinte falhava e o agente nao tinha como saber por que.
#
# Uso: A=mavis sh setup.sh
set -u
R=$(cd "$(dirname "$0")" && pwd)
cd "$R" || exit 1
mkdir -p .work/logs .work/downloads .work/vm .work/uup .work/iso .work/mnt 2>/dev/null
grep -qx '.work/' .gitignore 2>/dev/null || printf '.work/\n' >> .gitignore

echo "[setup] 1/4 dependencias (o que os scripts REALMENTE usam)"
# ambiente.sh ja traduz ferramenta->pacote por gerenciador; nao escondemos a saida.
if [ -f scripts/ambiente.sh ]; then
  sh scripts/ambiente.sh || echo "[setup] AVISO: ambiente.sh retornou erro - veja acima, nao siga como se estivesse pronto"
else
  echo "[setup] FALTA scripts/ambiente.sh - nada instalado"; exit 1
fi

echo "[setup] 2/4 hooks versionados"
# .git/hooks nao e clonado: sem isto, cada clone novo nasce sem protecao de main
# e sem push/presenca automaticos.
if [ -d hooks ]; then
  git config --local core.hooksPath hooks && echo "[setup] core.hooksPath=hooks ok"
  # Se o blob foi commitado sem bit de execucao (100644) o git IGNORA o hook em
  # silencio. Detecta e diz como corrigir, em vez de deixar o agente sem protecao.
  for h in hooks/pre-commit hooks/post-commit; do
    [ -f "$h" ] && [ ! -x "$h" ] && echo "[setup] AVISO: $h nao esta executavel -> git update-index --chmod=+x $h"
  done
else
  echo "[setup] AVISO: sem diretoria hooks/ - main nao fica protegida neste clone"
fi

echo "[setup] 3/4 identidade + presenca"
if [ -f scripts/agente.sh ]; then
  sh scripts/agente.sh entrou
else
  echo "[setup] AVISO: sem scripts/agente.sh - este agente nao ficou identificado"
fi

echo "[setup] 4/4 o que da para rodar aqui"
if [ -f scripts/doctor.sh ]; then
  sh scripts/doctor.sh
  D=$?
  [ "$D" -ne 0 ] && echo "[setup] ambiente ainda nao consegue testar nada: instale o que o doctor marcou [FALTA] e rode de novo."
  exit "$D"
fi
echo "[setup] pronto (sem doctor.sh: nao sei dizer o que e executavel)."
