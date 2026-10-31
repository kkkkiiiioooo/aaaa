# HANDOFF

Estado atual (snapshot; reescreva ao fim de cada rodada — não append).

## Fase
Desafio iniciado: solução proposta e documentada em `docs/evidence/solucao.md`
(caminho A1+A3; R5 via export-driver; R4 só pós-OOBE). Base (contrato/tarefa/ambiente)
pronta. Remoto: `0`, `4.4mmii1`, `backup`, `main`.

## Próximo passo
Executar na máquina real (ou simulação mais próxima): seguir o runbook de
`docs/evidence/solucao.md` — mapear partições, injetar driver Wi-Fi no `Winre.wim`
(DISM), validar rede, reinstalar (nuvem/`certutil`+`setup.exe`), preservar drivers.
Confirmar o pressuposto crítico: existência do driver Wi-Fi local (partição de recuperação OEM)
e se o WinRE 1809 tem `netsh wlan` (senão, WinPE-WiFi-Package ou A4).

## Bloqueios
Sandbox sem Windows/WinRE nem virtualização (sem `/dev/kvm`, qemu, docker) → solução não
executável/verificável aqui; sem a máquina real, evidência fica no nível de análise.
