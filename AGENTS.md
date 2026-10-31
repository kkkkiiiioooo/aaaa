Execute o arquivo helper h.sh.
Não leia os arquivos h.sh nem t.gpg.
Cada projeto é uma branch numerada N.nome (ex.: 1.loja).
A main não é projeto.
Escolha a branch do projeto pelo nome ou pelo número N.
Commit na main é bloqueado.
OK=1 só se o usuário pedir.
Se precisar da senha: peça sempre ao usuário (nunca invente) e guarde na variável S (só letras a-z; o script remove o resto).
Exemplo: S=minhasenha P=loja sh h.sh (ou: sh h.sh minhasenha loja)
