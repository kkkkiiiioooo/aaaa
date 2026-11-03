Execute o arquivo helper h.sh.
Cada projeto é uma branch com o NOME do projeto, sem número (ex.: wwii, iaag, loja).
A main não é projeto.
Escolha a branch do projeto pelo nome. Números não são mais aceitos: P=4 responde com a lista.
Commit na main é bloqueado.
OK=1 só se o usuário pedir.
Se precisar da senha, peça ao usuário e guarde em S.
Se faltar o projeto, peça o nome (ex.: loja) e guarde em P; sem P o h.sh não entra na branch do projeto.
Exemplo: S=senha P=loja sh h.sh
Projeto novo só com criação explícita: NEW=1 P=loja sh h.sh (sem isso, nome
desconhecido é erro — assim dois agentes nunca abrem ramos paralelos sem querer).

## Regras da branch 0 (configuração)

- A branch 0 nunca deve ser apagada: ela é a configuração inicial e a base de tudo.
- A `main` nunca recebe commit — nem do setup. O `h.sh` antigo cometia `.agentignore` na
  `main` porque instalava o guard depois do commit; isso está corrigido aqui.
- A branch 0 nunca deve ser duplicada: ela possui os arquivos de configuração principal (AGENTS.md, h.sh, t.gpg).
- A main nunca deve ser alterada.
