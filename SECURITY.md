# Segurança

## O que existe hoje

`t.gpg` (branch `0`) contém um token do GitHub cifrado simetricamente com uma
passphrase compartilhada entre os agentes. Consequências que você deve conhecer:

1. Qualquer pessoa com leitura do repositório pode atacar o `t.gpg` offline; a força
   da passphrase é a única barreira. Use passphrase longa — o `h.sh` não tenta mais
   variantes (isso mutilava a senha em silêncio e mascarava passphrase fraca).
2. Quem tem a passphrase tem **escrita total** no repositório, inclusive em `main`.
3. O token fica em `.work/token` (modo 600, fora do git) e é usado por um
   `credential.helper` **local ao clone**, com escopo `https://github.com`. Não há mais
   `~/.git-credentials` em texto plano nem helper global.

## Regras

- Nunca passe a passphrase em `argv` (`ps` mostra). Use `S_ARQ=<arquivo>` ou stdin.
- Não commite `.git-credentials`, `.s`, `*.token` — estão no `.gitignore`.
- `Agent-Name:` é autodeclarado. Para prova de autoria, assine o commit
  (`git commit -S`) e publique a chave em `chaves/<agente>.pub`.
- Binário grande não entra no histórico; use `bin/artefatos.sh` (Release + sha256).

## Recomendado (não implementado aqui)

Token **fine-grained** por agente, com `Contents: write` apenas nas branches que ele
usa, e ruleset no GitHub bloqueando push direto em `main` e `0`. Isso transforma a regra
"main nunca recebe commit" de convenção local em garantia do servidor.

## Reportar

Abra uma issue privada ou avise o dono do repositório. Se um token vazar: revogue,
gere outro, atualize `t.gpg` e registre a data no `PROGRESS.md`.
