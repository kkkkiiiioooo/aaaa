# Execute o arquivo helper h.
# Não leia os arquivos h nem t.gpg.
# Cada projeto é uma branch numerada N.nome (ex.: 1.loja).
# A main não é projeto.
# Escolha a branch do projeto pelo nome ou pelo número N.
# Commit na main é bloqueado.
# OK=1 só se o usuário pedir.
S=${1:-$S};P=${2:-$P}
S=$(printf %s "$S"|tr A-Z a-z|tr -cd a-z)
t=$(curl -sL raw.githubusercontent.com/kkkkiiiioooo/aaaa/0/t.gpg|gpg -dq --batch --passphrase "$S");[ -n "$t" ]||{ echo erro: senha ou rede;exit 1;}
git config --global credential.helper store
printf 'protocol=https\nhost=github.com\nusername=x\npassword=%s\n\n' "$t"|git credential approve;chmod 600 ~/.git-credentials
cd ~;[ -d aaaa ]||git clone -q https://github.com/kkkkiiiioooo/aaaa aaaa;cd aaaa||exit 1
git config user.name claude;git config user.email c@c;git config push.autoSetupRemote true
echo t.gpg>.agentignore;git ls-files --error-unmatch .agentignore >/dev/null 2>&1||{ git add .agentignore;git commit -qm agentignore;}
printf '#!/bin/sh\n[ -n "$G" ]&&exit 0;export G=1;b=$(git rev-parse --abbrev-ref HEAD);git pull -q --rebase origin $b||{ git rebase --abort 2>/dev/null;echo CONFLITO: resolva antes de enviar;exit 1;};git push -q origin $b\n' >.git/hooks/post-commit;chmod +x .git/hooks/post-commit
if [ -n "$P" ];then
 git fetch -q origin
 case $P in *[!0-9]*) pat="^([0-9]+\.)?$P$";; *) pat="^$P\.";; esac
 b=$(git branch -r|sed 's#.*origin/##'|grep -E "$pat"|head -1)
 if [ -z "$b" ];then
  case $P in *[!0-9]*) n=$(git branch -r|sed 's#.*origin/##'|grep -oE '^[0-9]+'|sort -n|tail -1);b=$((${n:-0}+1)).$P;; *) echo "branch $P.* nao existe";exit 1;; esac
 fi
 git switch -q $b 2>/dev/null||git switch -qc $b --no-track origin/main
fi
printf '#!/bin/sh\n[ "$(git branch --show-current)" = main ]&&[ -z "$OK" ]&&{ echo "main: use git switch -c PROJETO (ou OK=1)";exit 1;};exit 0\n' >.git/hooks/pre-commit;chmod +x .git/hooks/pre-commit
echo ok $PWD $(git branch --show-current);git branch -r|sed 's#.*origin/##'|grep -E '^[0-9]'|sort -uV|tr '\n' ' '
