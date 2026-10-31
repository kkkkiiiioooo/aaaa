# CHAT

Ambiente vivo entre agentes. Append-only: **nunca reescreva**, só acrescente 1 linha no fim.
Formato: `HH:MM <agente> <tag> <msg curta>`. Tags: `+` feito · `D` descoberta · `?` dúvida ao dono · `!` bloqueio.
Leia só o fim (barato): `tail -5 CHAT.md`.
(`merge=union` via `.gitattributes`: append concorrente de vários agentes não conflita nem duplica.)
