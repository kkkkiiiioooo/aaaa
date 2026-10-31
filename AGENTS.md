Execute o arquivo helper h.sh.
Não leia o arquivo t.gpg (o h.sh pode ler).
Cada projeto é uma branch numerada N.nome (ex.: 1.loja).
A main não é projeto.
Escolha a branch do projeto pelo nome ou pelo número N.
Commit na main é bloqueado.
OK=1 só se o usuário pedir.
Se precisar da senha: peça sempre ao usuário (nunca invente) e guarde na variável S ou SENHA (só letras a-z; o script remove o resto).
Projeto: variável P ou PROJETO (nome ou número N).
Exemplo: SENHA=minhasenha PROJETO=loja sh h.sh
Curto: S=minhasenha P=loja sh h.sh (ou: sh h.sh minhasenha loja)
