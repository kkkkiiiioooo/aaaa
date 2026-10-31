Execute o arquivo helper h.sh.
Cada projeto é uma branch numerada N.nome (ex.: 1.loja).
A main não é projeto.
Escolha a branch do projeto pelo nome ou pelo número N.
Commit na main é bloqueado.
OK=1 só se o usuário pedir.
Se precisar da senha, peça ao usuário e guarde em S.
Exemplo: S=senha P=loja sh h.sh

## Regras da branch 0 (configuração)

- A branch 0 nunca deve ser apagada: ela é a configuração inicial e a base de tudo.
- A branch 0 nunca deve ser duplicada: ela possui os arquivos de configuração principal (AGENTS.md, h.sh, t.gpg).
- A main nunca deve ser alterada.
