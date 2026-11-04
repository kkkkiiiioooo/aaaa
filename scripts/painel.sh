#!/bin/sh
# painel.sh - UMA pagina para o dono: o que esta parado, o que esta travado, quem trabalhou.
# So le (nao grava nada). Uso: sh scripts/painel.sh
R=$(cd "$(dirname "$0")/.." && pwd); cd "$R" || exit 1
git fetch -q origin 2>/dev/null
NOW=$(date -u +%s)

echo "== ETAPAS (ultimo estado; ativa ha mais de 90 min = EXPIRADA, ninguem esta nela)"
for n in 1 2 3 4 5 6; do
  nome=$(grep "^| E$n " ETAPAS.md | awk -F'|' '{gsub(/^ +| +$/,"",$3); print $3}')
  l=$(grep "^E$n | " ETAPAS.md | tail -1)
  if [ -z "$l" ]; then est="livre"; else
    ag=$(echo "$l" | awk -F' [|] ' '{print $2}'); ini=$(echo "$l" | awk -F' [|] ' '{print $3}')
    est=$(echo "$l" | awk -F' [|] ' '{print $4}'); ev=$(echo "$l" | awk -F' [|] ' '{print $5}' | cut -c1-60)
    if [ "$est" = ativa ]; then
      t=$(date -u -d "$(echo "$ini" | sed 's/T/ /; s/Z//')" +%s 2>/dev/null || echo "$NOW")
      [ $(( (NOW - t) / 60 )) -gt 90 ] && est="ativa EXPIRADA"
    fi
    est="$est ($ag) $ev"
  fi
  printf 'E%s %-34s %s\n' "$n" "$nome" "$est"
done

echo; echo "== PROBLEMAS abertos ([LEAD] = esperando o lead)"
sh scripts/problema.sh abertos | cut -c1-200
[ -z "$(sh scripts/problema.sh abertos)" ] && echo "(nenhum registrado: ninguem usou o quadro ainda)"

echo; echo "== PRESENCA (entrou / ultimo push com data UTC)"
grep -E ' (inicio|push) ' PRESENCA.md | tail -8

echo; echo "== ULTIMOS COMMITS (quem mexeu, quando)"
git log -6 --format='%cd %an: %s' --date=format:'%m-%d %H:%M' | cut -c1-110

echo; echo "== SUGESTOES dos agentes (ultimas 3)"
grep -v '^#' SUGESTOES.md 2>/dev/null | tail -3 | cut -c1-200
[ -z "$(grep -v '^#' SUGESTOES.md 2>/dev/null)" ] && echo "(nenhuma ainda)"

echo; echo "== CAPACIDADE deste ambiente"
[ -w /dev/kvm ] && echo "KVM: sim" || echo "KVM: nao (usa TCG: lento, mas funciona; rode em 2o plano com timeout alto)"
for t in qemu-system-x86_64 wimlib-imagex xorriso; do command -v $t >/dev/null 2>&1 && echo "ok $t" || echo "FALTA $t (sh scripts/ambiente.sh)"; done
