#!/bin/sh
# setup/common/deps.sh - dependencias comuns a todos os agentes (delega ao detector de gerenciador).
cd "$(dirname "$0")/../.." || exit 1
mkdir -p .work/logs .work/downloads .work/vm .work/uup .work/iso .work/mnt
grep -qx '.work/' .gitignore 2>/dev/null || printf '.work/\n' >> .gitignore
sh scripts/ambiente.sh
