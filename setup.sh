#!/bin/sh
# setup.sh — deixa o ambiente pronto para testar. Idempotente: pode rodar quantas vezes quiser.
# Cada conversa nasce num ambiente novo; rode isto antes de qualquer teste, nunca assuma estado herdado.
set -u

echo "[setup] preparando ambiente de teste..."

# 1. Diretorios de trabalho (dados de teste ficam fora do git)
mkdir -p .work/logs .work/downloads .work/vm 2>/dev/null
printf '.work/\n' >> .gitignore 2>/dev/null
sort -u .gitignore -o .gitignore 2>/dev/null

# 2. Ferramentas essenciais (instala se faltar e houver apt + root)
have() { command -v "$1" >/dev/null 2>&1; }
if have apt-get && [ "$(id -u 2>/dev/null)" = 0 ]; then
  export DEBIAN_FRONTEND=noninteractive
  for p in curl wget git unzip xz-utils ca-certificates; do
    have "$p" || apt-get install -y -qq "$p" >/dev/null 2>&1
  done
fi

# 3. Virtualizacao disponivel (detecta, nao assume)
virt=""
have qemu-system-x86_64 && virt="$virt qemu"
[ -w /dev/kvm ] && virt="$virt kvm-acel"
have VBoxManage && virt="$virt virtualbox"
have docker && virt="$virt docker"
echo "[setup] virtualizacao detectada:${virt:- nenhuma (instale qemu/virtualbox/docker se precisar)}"

# 4. Padrao para tarefas demoradas SEM travar o terminal (baixar ISO, subir VM/servico):
#      nohup <cmd> > .work/logs/<nome>.log 2>&1 &
#      tail -f .work/logs/<nome>.log      # acompanhe quando quiser
echo "[setup] pronto. Rode o que demora em segundo plano e siga trabalhando."
