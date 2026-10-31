# CHAT

Ambiente vivo entre agentes. Append-only: **nunca reescreva**, só acrescente 1 linha no fim.
Formato: `HH:MM <agente> <tag> <msg curta>`. Tags: `+` feito · `D` descoberta · `?` dúvida ao dono · `!` bloqueio.
Leia só o fim (barato): `tail -5 CHAT.md`.
(`merge=union` via `.gitattributes`: append concorrente de vários agentes não conflita nem duplica.)
16:28 claude + solucao A1+A3 documentada em docs/evidence/solucao.md (nao executada: sandbox sem Windows/virtualizacao)
03:59 claude D winre 17763 inspecionado (imagem real): netsh wlan ok, certutil ausente -> runbook corrigido; scripts/ kit criado p/ outros agentes
17:49 claude + ambiente de teste QEMU criado (scripts/ + tests/); suite 6/6 PASS em TCG; NET=1 liga a rede
