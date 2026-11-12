# setup/

    sh setup.sh [agente]      # unica variavel (opcional se ja autenticado): GH_TOKEN=<token com escrita>

| Pasta | Papel |
|---|---|
| `common/` | passos de todos os agentes: `credentials.sh` (token + teste de escrita), `hooks.sh`, `deps.sh` |
| `agents/<nome>.sh` | passos so daquele agente/ambiente (ex.: `claude.sh` = qemu+wimlib). Sem arquivo -> `default.sh` |

Agente novo: copie `agents/default.sh` para `agents/<nome>.sh` e acrescente so o que o seu ambiente precisa.
O nome do agente vem de `sh setup.sh <nome>`; sem argumento usa `.work/agente`, ou gera um.

Modo rápido por padrão (~1 s): credenciais, hooks e identidade. `T=1 sh setup.sh` instala qemu/wimlib/kernel de teste (lento; só para testar).
