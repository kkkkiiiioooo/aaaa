# Experimento E2 — Mecânica de servicing offline (cirurgia de WIM no lado do host) e o caminho exato de busca da nvram

## Objetivo

Pergunta única: a carga de que H1 e H2 precisam (colocar a nvram da placa em `System32\drivers`, e/ou substituir o pacote Wi-Fi inbox 2017 pelo pacote OEM 2015) pode ser produzida offline, de forma reproduzível, com verificação a nível de bytes — e onde exatamente o driver procura esses arquivos em runtime?

Segunda pergunta respondida no caminho: qual é a menor carga que plausivelmente corrigiria o dispositivo, porque o tamanho da carga é a restrição vinculante do canal de entrada de texto digitado.

## Nível de fidelidade

`somente metadados` para a reivindicação de hardware, bytes reais no lado do host para a reivindicação de mecânica.

- Exato: o WIM real do WinRE 1809 oficial é usado, nunca modificado no lugar; cada arquivo inserido é comparado por SHA-256 com a cópia no repositório; o round-trip LZMS é verificado com `wimlib-imagex verify`.
- Aproximado: nada foi inicializado, nada rodou no Mi Pad 2, o nome da pasta do DriverStore é um placeholder, e o índice de drivers do registro não foi tocado. Portanto este experimento não diz nada sobre se a correção funciona.

## Pré-condições

- Imagem de origem: `qemu/work/winre1809.wim` (cópia do `WinRE.wim` do WinRE 1809 oficial, LZMS, chunk 131072, 21.230 caminhos, índice de imagem 1, "Microsoft Windows Recovery Environment (x64)").
- Carga: `drivers/mipad2-oficial/wifi/` (17 arquivos, OEM `oem25.inf` 1.558.14.0) e `drivers/nvram-delta/4356r2nvram.txt` (5.361 bytes).
- Estado de baseline para comparação: `drivers/estado-dispositivo/` (inbox `bcmwdidhdpcie.inf` 1.558.53.25, 4 arquivos, sem nvram).
- Ferramentas: `wimlib 1.13.5`, `coreutils`, `grep`, `strings`, `iconv`.
- Espaço livre: ~1,1 GB para duas cópias extra do WIM. `/data` tinha > 40 GB livres.
- Nada no dispositivo é tocado, então nenhum backup do dispositivo é exigido para este experimento.

## Ambiente

- Data: 16/11/2026 (UTC)
- Host: sandbox na nuvem, Linux `5.10.134-013.10.1.kangaroo.al8.x86_64` (x86-64)
- Virtualização: não usada neste experimento (só trabalho com arquivos no host)
- Versões das ferramentas: `wimlib-imagex 1.13.5 (using wimlib 1.13.5)`
- Hashes das imagens (SHA-256, 12 primeiros): WIM de origem `232199c58511`; nvram `a7a0a8fb9abf`; OEM `oem25.inf` `e09bef8b9ded`; OEM `.sys` `ddbac3436533`; inbox `.inf` `2162ce513cca`

## Comandos

Driver, roteirizado, idempotente, opera só sobre cópias: `e2-servicing.sh`.

```sh
# 0. inventário de baseline da origem intocada
wimlib-imagex dir qemu/work/winre1809.wim 1 > baseline.txt

# 1. H1 (rótulo do repositório): colocar só a nvram onde o .sys diz que procura
cp qemu/work/winre1809.wim e2/WinRE-h1.wim
wimlib-imagex update e2/WinRE-lite.wim 1 \
  --command="add drivers/nvram-delta/4356r2nvram.txt /Windows/System32/drivers/4356r2nvram.txt"

# 2. H2 (rótulo do repositório): remover o pacote inbox, inserir o pacote OEM, inserir a nvram,
#    e adicionalmente preparar o pacote OEM inteiro para um pnputil no lado do dispositivo
cp qemu/work/winre1809.wim e2/WinRE-serviced.wim
wimlib-imagex update e2/WinRE-serviced.wim 1 <<EOF
delete --recursive /Windows/System32/DriverStore/FileRepository/bcmwdidhdpcie.inf_amd64_977dcc915465b0e9
add drivers/mipad2-oficial/wifi /Windows/System32/DriverStore/FileRepository/oem25.inf_amd64_0000000000000000
add drivers/nvram-delta/4356r2nvram.txt /Windows/System32/DriverStore/FileRepository/oem25.inf_amd64_0000000000000000/4356r2nvram.txt
add drivers/nvram-delta/4356r2nvram.txt /Windows/System32/drivers/4356r2nvram.txt
add drivers/mipad2-oficial/wifi /Windows/Temp/mipad2-wifi
add drivers/nvram-delta/4356r2nvram.txt /Windows/Temp/mipad2-wifi/4356r2nvram.txt
EOF

# 3. re-leitura a nível de bytes
wimlib-imagex extract e2/WinRE-serviced.wim 1 \
  /Windows/System32/DriverStore/FileRepository/oem25.inf_amd64_0000000000000000/oem25.inf --dest=verify
wimlib-imagex verify e2/WinRE-h1.wim
wimlib-imagex verify e2/WinRE-serviced.wim

# 4. a evidência de INF/caminho que guiou o design (os arquivos INF são UTF-16LE, então iconv antes)
iconv -f UTF-16LE -t UTF-8 \
  drivers/estado-dispositivo/bcmwdidhdpcie.inf_amd64_977dcc915465b0e9/bcmwdidhdpcie.inf > inbox-inf.txt
grep -c nvram inbox-inf.txt
strings drivers/estado-dispositivo/bcmwdidhdpcie.inf_amd64_977dcc915465b0e9/bcmpciedhd63.sys | grep nvram
```

Nota sobre a sintaxe do wimlib descoberta ao executar isto: `wimlib-imagex dir` não recebe `--iter` para um WIM de arquivo único (com `--iter=1` ele não imprime nada, o que silenciosamente produziu resultados "0 caminhos" numa execução anterior); o `delete` de um diretório exige a opção `--recursive` (`delete --recursive <caminho>`); um glob (`<caminho>/*`) é rejeitado como caminho inexistente; e `--command` pode ser passado só uma vez, então scripts de várias etapas devem ir pelo stdin.

## Saída observada

```text
[22:49:36] === 0. linha de base (source nunca é modificada) ===
[22:49:36] src = /data/aaaa/qemu/work/winre1809.wim (266283224 bytes)
[22:49:36] paths na imagem: 21230
[22:49:36] pacote inbox no FileRepository: 5 paths
[22:49:36] cópias do componente no WinSxS: 6 paths
[22:49:36] INF inbox em /Windows/INF: 1
[22:49:36] nvram já presente na imagem: 0
[22:49:36] arquivos *.bin em /Windows/System32/drivers: 0

[22:49:37]   /Windows/System32/drivers/4356r2nvram.txt: IGUAL (5361 bytes, sha256 a7a0a8fb9abf)
[22:49:37]   WIM antes/depois: 266283224 / 267640004 bytes (delta 1356780)

[22:49:42] update completo: 4339 ms
[22:49:42] paths inbox no FileRepository após delete: 0
[22:49:42] paths inbox ainda no WinSxS: 6
[22:49:42] paths OEM no FileRepository: 19
[22:49:42] WIM antes/depois: 266283224 / 270616246 bytes (delta 4333022)

[22:49:43]   .../oem25.inf: IGUAL
[22:49:43]   .../bcmpciedhd63.sys: IGUAL
[22:49:43]   .../bcmpciedhd63.cat: IGUAL
[22:49:43]   .../4356a2rtecdc.bin: IGUAL
[22:49:43]   .../bcm94356wlpagbl_P3_150828M.txt: IGUAL
[22:49:44]   /Windows/System32/drivers/4356r2nvram.txt: IGUAL

[22:49:50]   WinRE-lite.wim (H1): "... was successfully verified."
[22:49:56]   WinRE-serviced.wim (H2): "... was successfully verified."

[22:49:56]   pnputil.exe: /Windows/System32/pnputil.exe
[22:49:56]   dism.exe: /Windows/System32/Dism.exe
[22:49:56]   cmd.exe: /Windows/System32/cmd.exe
[22:49:56]   drvload.exe: /Windows/System32/drvload.exe
[22:49:56]   devcon.exe: AUSENTE
[22:49:56]   setupapi.dll: /Windows/System32/setupapi.dll
[22:49:56]   newdev.dll: /Windows/System32/newdev.dll
[22:49:56]   hive SYSTEM na imagem: 1
```

A evidência de INF/binários coletada na mesma sessão:

```text
# inbox INF (UTF-16LE, v1.558.53.25), decodificado com iconv
grep -c nvram inbox-inf.txt          -> 0
[BCM43XAC_NT62_4356.files]           (linha 99)
	4356r2rtecdc.bin,4356a2rtecdc.bin,,6      <- firmware renomeado, SIM
                                                <- linha de nvram: NÃO EXISTE
[DestinationDirs]
	BCM43XAC_NT62_4356.files = 12

# OEM INF (ASCII, v1.558.14.0)
[BCM43XAC_NT62_4356.files]           (linha 239)
	4356r2rtecdc.bin,4356a2rtecdc.bin,,6
	4356r2nvram.txt,bcm94356wlpagbl_P3_150828M.txt,,6   <- a única diferença
[DestinationDirs]
	BCM43XAC_NT62_4356.files = 12

# strings idênticas nos dois bcmpciedhd63.sys (inbox 1.558.53.25 e OEM 1.558.14.0)
\SystemRoot\system32\drivers\%dr%drtecdc.bin
\SystemRoot\system32\drivers\%04Xr%drtecdc.bin
\SystemRoot\system32\drivers\%dr%dnvram.txt
\SystemRoot\system32\drivers\%04Xr%dnvram.txt
nvram path set to %s
dhdpcie_download_nvram
%s: dongle nvram file download failed

# onde o .sys e o firmware realmente ficam na imagem factory (baseline.txt)
bcmpciedhd63.sys: apenas 2 ocorrências
  /Windows/System32/DriverStore/FileRepository/bcmwdidhdpcie.inf_amd64_977dcc915465b0e9/bcmpciedhd63.sys
  /Windows/WinSxS/amd64_dual_bcmwdidhdpcie.inf_.../bcmpciedhd63.sys
4356a2rtecdc.bin: apenas as mesmas 2 regiões (FileRepository e WinSxS)
/Windows/System32/drivers/*.sys: 295 arquivos, bcmpciedhd63.sys NÃO está entre eles
```

## Artefatos e hashes

| Caminho | SHA-256 | Tamanho |
|---|---|---|
| `qemu/work/winre1809.wim` (origem, intocada) | `232199c585111bfae71ff00dbdcabe5c75195fc9b431eb4d1711b8a7e471eb6c` | 266.283.224 |
| `qemu/work/e2/WinRE-lite.wim` (H1, só nvram) | `253ad2301c592a402e9a722195694f87e002347709fb447a07ee7ab7320d59fa` | 267.640.004 |
| `qemu/work/e2/WinRE-serviced.wim` (H2, troca de pacote) | `3bf63522b45d1705d8fda0f333f26de627fafd9f889398d7273217977fa5f158` | 270.616.246 |
| `drivers/nvram-delta/4356r2nvram.txt` (carga) | `a7a0a8fb9abfa877675dc7126ae2bde54c4695088543ddbaaa0a49140d9b4667` | 5.361 |
| `drivers/mipad2-oficial/wifi/oem25.inf` | `e09bef8b9deded6637f8ac64285b8b6625a6da51a4c3693ad96848bed1ce3ba9` | 279 |
| `drivers/mipad2-oficial/wifi/bcmpciedhd63.sys` | `ddbac343653389cf1e1817f8590427fe2a610107dc8a6872d96c209183d330e2` | 1.041.320 |
| `drivers/estado-dispositivo/.../bcmwdidhdpcie.inf` (inbox) | `2162ce513ccaef946ff34e22ac43340c6afd59168bb2ae9e3d3f349acecc0731` | — |

Os WIMs são ignorados pelo `.gitignore` (`*.wim`, `qemu/work/`); eles ficam no sandbox como saídas reproduzíveis do script, não como conteúdo do repositório.

O script rodou duas vezes de ponta a ponta (22:49 e 22:53 UTC) e os digests acima são da primeira execução. Tamanhos e o digest de cada arquivo inserido se reproduziram exatamente. Os digests dos contêineres **não** se reproduziram: `wimlib-imagex update` carimba o `Last Modification Time` da imagem com o relógio do host (verificado — as imagens serviced reportam `Mon Nov 16 22:53:16 2026 UTC` enquanto a origem ainda reporta `Sat Sep 15 10:02:34 2018 UTC`), então um WIM reconstruído não é bit-idêntico a um build anterior mesmo quando o seu conteúdo é idêntico. A reprodutibilidade aqui é, portanto, a nível de conteúdo (SHA-256 por arquivo), não de contêiner; qualquer hash fixado num manifesto de transferência deve ser retirado do build final, não prometido antecipadamente.

## Interpretação

### Fatos observados

1. As duas variantes de servicing executam limpas sobre uma cópia da imagem oficial real, em segundos (4,3 s para o script completo de seis comandos), e cada arquivo inserido é relido idêntico byte a byte por SHA-256. Ambos os WIMs resultantes passam `wimlib-imagex verify`.
2. O caminho de busca da nvram não é mais uma inferência a partir dos nomes de arquivo. Ambos os binários do driver — o inbox de 2017 atualmente instalado e o OEM de 2015 — contêm os mesmos templates literais `\SystemRoot\system32\drivers\%04Xr%dnvram.txt` e `\SystemRoot\system32\drivers\%dr%dnvram.txt`, mais a string de falha `dongle nvram file download failed`. Para o chip 0x4356 rev 2 isso resolve para `C:\Windows\System32\drivers\4356r2nvram.txt`, que é exatamente como o arquivo da placa é nomeado em `drivers/nvram-delta/`.
3. A única diferença funcional entre as duas seções `[BCM43XAC_NT62_4356.files]` é a linha de cópia da nvram. O INF do inbox renomeia o firmware (`4356r2rtecdc.bin,4356a2rtecdc.bin,,6`) mas nunca copia uma nvram; o INF do OEM renomeia o txt da placa para `4356r2nvram.txt` no mesmo dirid 12 (`%SystemRoot%\System32\drivers`). Os dois INFs apontam para o mesmo diretório de busca que os binários embutem.
4. Na imagem WinRE de fábrica, nem `bcmpciedhd63.sys` nem `4356a2rtecdc.bin` existem sob `System32\drivers` — eles existem só no DriverStore FileRepository e no componente WinSxS. Então o driver está preparado, não implantado: as cópias de runtime são criadas pelo setup/PnP no momento da instalação, que é onde a linha da nvram importa.
5. `pnputil.exe`, `dism.exe`, `cmd.exe`, `drvload.exe`, `setupapi.dll` e `newdev.dll` estão todos presentes na imagem do WinRE, e o hive SYSTEM está dentro do WIM. Injeção de driver no lado do dispositivo e trabalho com o registro offline são ambos possíveis do console de recuperação; `devcon.exe` não está disponível.
6. Custo: adicionar o único arquivo de nvram cresce o WIM LZMS em 1.356.780 bytes; a troca completa do pacote o cresce em 4.333.022 bytes (os dois números são inflados pelo wimlib recomprimindo com uma thread e não são uma estimativa de transferência).

### Hipóteses (não provadas aqui)

- H1 como o repositório o define (posicionamento da nvram) é agora a opção mais barata e mais precisamente direcionada: colocar só `4356r2nvram.txt` em `System32\drivers` pode bastar para o *inbox* driver iniciar o dispositivo, porque o binário do driver embute esse caminho de busca e o INF do inbox nunca cria o arquivo.
- Nova sub-questão levantada pelo fato 4: na imagem de fábrica, o firmware renomeado `4356r2rtecdc.bin` também não está em `System32\drivers`. Se o dispositivo ainda está em estado de fábrica, a carga mínima são dois arquivos, não um — firmware (641.951 bytes OEM / 651.235 bytes inbox) mais nvram (5.361 bytes) — e possivelmente `bcmpciedhd63.sys` como terceiro. Isso deve ser medido no dispositivo, não assumido.
- H2 (o driver 2017 ser a regressão, primário no repositório) pode ser desnecessário se o H1 sozinho funcionar; se o H1 sozinho não funcionar, o H2 acrescenta o `.sys`/`.cat`/DLLs IHV do OEM. Nenhum dos dois desdobramentos é provado por este experimento.
- Se o PlugPlay de fato rodou o estágio CopyFiles no dispositivo, e se o driver trata uma nvram ausente como fatal ou recorre à calibração nVMRAM/OTP de bordo, são ambos desconhecidos. Os fatos 2 e 3 dizem que o arquivo está ausente por design; não dizem que o driver falha por causa dele.
- O índice de registro do DriverStore (`SYSTEM\DriverDatabase`) continua apontando para o pacote inbox depois da troca a nível de arquivos na variante 2, então o SO pode continuar escolhendo o driver inbox de qualquer jeito. Editar esse hive offline foi deliberadamente não tentado (sem `chntpw` no sandbox, e edições às cegas no hive são exatamente o tipo de mudança não verificada que as regras do repositório proíbem).

## Decisão

- Resultado: **`host-only / não é prova`** — re-rotulado em 17/11/2026 para seguir a regra de evidência
  adicionada ao `AGENTS.md` (commit `33d4bd4`): o que passou aqui é real (o wimlib rodou sobre a
  imagem oficial real, numa cópia, e as saídas foram re-hashadas), mas o ambiente alvo de qualquer
  reivindicação que importe é um WinRE inicializado e depois o dispositivo físico, e nenhum dos dois foi exercitado.
  Pelas regras, uma verificação no lado do host não pode carregar um `pass`, então a redação anterior
  ("pass para a reivindicação de mecânica") foi substituída em vez de mantida como caso especial.
- Motivo: a carga pode ser construída de forma reproduzível e verificada offline, e o caminho exato de inserção agora está provado a partir dos binários em vez de assumido. Nenhuma evidência de dispositivo existe ainda, e o E1 (conseguir um console WinRE) continua sendo o bloqueador de qualquer reivindicação de dispositivo.
- Próximos experimentos:
  1. E1b/E1c — conseguir um console, então rodar a verificação só-de-leitura no lado do dispositivo `dir C:\Windows\System32\drivers\4356*` e `driverquery`/`pnputil /enum-drivers` para ver quais de `.sys`, firmware e nvram estão de fato implantados. Essa única listagem decide o tamanho da carga mínima e, portanto, se o canal de texto digitado basta.
  2. E8 — construir a mídia H1 com só a nvram (e opcionalmente o firmware) inseridos: 5,4 KB mais 0,64 MB de carga contra um pacote de 13,97 MB, que é a diferença entre uma transferência de texto digitado plausível e uma impossível.
  3. Decidir com o dono se o posicionamento às cegas de `System32\drivers\4356r2nvram.txt` ou uma execução consciente do registro com `pnputil /add-driver` é o caminho autorizado no lado do dispositivo.

## Limitações

- Sem boot no QEMU dos WIMs serviced: o caminho do console WinRE continua bloqueado pelos problemas do E1 (`experiments/E1-winre-boot-tcg.md`), então "a imagem serviced ainda inicializa" não está verificado.
- Só lado do host. Nada aqui exercita o setup do Windows, o ranking do PnP, a política de assinatura de catálogo (`bcmpciedhd63.cat` é assinado pelo pacote OEM; a política de test-signing é uma restrição conhecida) nem o índice real do DriverStore.
- O nome de pasta `oem25.inf_amd64_0000000000000000` do DriverStore é um placeholder explícito; o sufixo real é um hash calculado pelo PnUtil no momento da instalação.
- Os deltas de bytes são artefatos de reescrita LZMS com 1 thread do wimlib, não custos de transferência.
- Sandbox, não a máquina do dono: `/dev/kvm` está ausente, então todos os desdobramentos do QEMU continuam TCG.

## Reversão

- O WIM de origem nunca foi aberto para escrita (o `update` rodou só sobre cópias); verificado depois: `qemu/work/winre1809.wim` ainda gera o hash `232199c58511…` e `wimlib-imagex dir` ainda reporta 21.230 caminhos.
- Arquivos de rascunho criados: `qemu/work/e2/{WinRE-lite.wim,WinRE-serviced.wim,logs/,verify/}` — todos sob o `qemu/work/` ignorado; a exclusão é opcional e não destrutiva.

## Referências

- `GOAL.md` (H1 e as restrições rígidas de canal), `docs/05-offline-servicing.md`, `docs/06-auditoria-imagem-1809.md`, `docs/04-fidelidade-mimetizacao.md`
- `drivers/README.md`, `drivers/estado-dispositivo/README.md`, `drivers/nvram-delta/`
- `experiments/E1-winre-boot-tcg.md` (por que nenhuma evidência de boot ainda), `experiments/README.md` (quadro)
- Script: `e2-servicing.sh`
