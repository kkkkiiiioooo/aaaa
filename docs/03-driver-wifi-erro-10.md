# Driver Wi-Fi e erro 10

> **Procedência:** verificada. Os dados da 1809 abaixo foram reconferidos contra
> `winre-1809-oficial-intacta/`, extraído do ESD oficial (`Core_en-us.esd`,
> 522.499.063 bytes, SHA-1 `8352af7661fb4808decc0253f6d516b7c2d88605`, SHA-256
> `b4d37e91…`). O WIM resultante (266.283.224 bytes, SHA-256 `232199c5…`) tem a
> mesma listagem de 21.230 caminhos do WIM derivado anterior, e os 11 arquivos
> do estado de driver são idênticos byte a byte. Veja `docs/06-auditoria-imagem-1809.md`.

## Sintoma

O adaptador BCM4356 é `PCI\VEN_14E4&DEV_43EC`. Depois que o driver inbox de 2017 entra em uso, o Windows reporta:

```text
ConfigManagerErrorCode = 10
```

O erro 10 significa que o dispositivo não consegue iniciar. O adaptador não aparece como interface Wi-Fi funcional.

## Versões

| Pacote | Versão | Data | Origem |
|---|---|---|---|
| Inbox `bcmwdidhdpcie.inf` | 1.558.53.25 | 21/04/2017 | WinRE 1809 |
| OEM `oem25.inf` | 1.558.14.0 | 23/12/2015 | Backup de fábrica do Mi Pad 2 |

Os dois pacotes usam um arquivo chamado `bcmpciedhd63.sys`, mas os binários diferem:

- Inbox: 1.037.824 bytes.
- OEM: 1.041.320 bytes.

## Por que copiar o driver mais velho não basta

O ranking de drivers do Windows prefere o driver mais novo para o mesmo dispositivo. O pacote inbox de 2017 fica acima do pacote OEM de 2015. Adicionar o pacote OEM sem remover o pacote inbox sem forçar o pacote OEM deixa o driver mais novo selecionado.

As opções funcionais são:

1. Remover o pacote inbox, depois adicionar o pacote OEM.
2. Forçar o pacote OEM com `devcon update`.
3. Usar o equivalente do Gerenciador de Dispositivos de "Escolher em uma lista" e selecionar o driver Broadcom de 2015.

A seleção manual do usuário funcionou no dispositivo físico. Isso é consistente com uma regressão de versão de driver.

## Evidência externa conhecida

O Microsoft Q&A documenta o mesmo sintoma no Mi Pad 2 e a solução de contorno com o driver mais velho:

https://learn.microsoft.com/en-us/answers/questions/2779164/broadcom-802-11ac-wireless-pcie-cant-be-started-af

O Microsoft Update Catalog lista os pacotes Broadcom BCM4356:

https://www.catalog.update.microsoft.com/Search.aspx?q=Broadcom%20BCM4356

Essas fontes sustentam o H2. Elas não substituem um teste no dispositivo físico.

## O fator nvram

O driver constrói estes caminhos:

```text
\SystemRoot\system32\drivers\4356r2rtecdc.bin
\SystemRoot\system32\drivers\4356r2nvram.txt
```

O DriverStore alvo contém `4356a2rtecdc.bin`, que o INF renomeia para `4356r2rtecdc.bin` durante a instalação. O DriverStore alvo não contém a nvram.

O INF do OEM contém:

```text
4356r2nvram.txt,bcm94356wlpagbl_P3_150828M.txt,,6
```

O INF do inbox não. Este é o delta de nvram.

O H2 é primário: o driver de 2017 é a regressão. O H1 é secundário: se a instalação do pacote OEM não copiar a nvram, a nvram precisa ser colocada separadamente em `System32\drivers`.

## Confirmado offline (E2, 16/11/2026)

`experiments/E2-offline-servicing.md` transformou três pontos acima de inferência em medição. Nenhum deles é evidência de hardware.

1. Os caminhos de busca estão embutidos nos binários, não só implícitos pelo INF. `strings` sobre **ambos** os builds de `bcmpciedhd63.sys` (inbox 1.558.53.25 e OEM 1.558.14.0) devolve os mesmos templates e o mesmo caminho de falha:

   ```text
   \SystemRoot\system32\drivers\%dr%drtecdc.bin
   \SystemRoot\system32\drivers\%04Xr%drtecdc.bin
   \SystemRoot\system32\drivers\%dr%dnvram.txt
   \SystemRoot\system32\drivers\%04Xr%dnvram.txt
   nvram path set to %s
   dhdpcie_download_nvram
   %s: dongle nvram file download failed
   ```

   Para o chip 0x4356 rev 2 isso resolve para `4356r2rtecdc.bin` e `4356r2nvram.txt`, que é exatamente a nomenclatura que `drivers/nvram-delta/` usa. Se o driver trata uma nvram ausente como fatal ou recorre à calibração de bordo ainda não está provado.
2. Na imagem WinRE da fábrica o driver está **preparado, não implantado**. `System32\drivers` contém 295 arquivos `.sys` e este não é um deles; `bcmpciedhd63.sys` e `4356a2rtecdc.bin` existem só em `DriverStore\FileRepository` e no componente `WinSxS`. Então as cópias de runtime *tanto do firmware quanto da nvram* dependem do estágio PnP `CopyFiles` ter rodado. A carga mínima é, portanto, dois arquivos (firmware OEM de 641.951 bytes mais nvram de 5.361 bytes) e não um, e possivelmente três — isso só se resolve listando o diretório vivo no dispositivo.
3. `devcon.exe` **não** está presente na imagem do WinRE. A opção 2 acima ("forçar o pacote OEM com `devcon update`") exige trazer a ferramenta. `pnputil.exe`, `dism.exe`, `cmd.exe`, `drvload.exe`, `setupapi.dll` e `newdev.dll` estão presentes, e o hive SYSTEM está dentro do WIM, então `pnputil /add-driver` e o trabalho com o registro offline são alcançáveis do console de recuperação.

Duas armadilhas operacionais descobertas ao fazer isso:

- O INF do inbox é UTF-16LE (BOM `ff fe`); o INF do OEM é ASCII. Buscar `nvram` no INF do inbox com grep sem decodificar devolve 0 ocorrências pelo motivo errado. Use `iconv -f UTF-16LE -t UTF-8` antes.
- `wimlib-imagex update` carimba o `Last Modification Time` da imagem com o relógio do host, então dois builds com conteúdo idêntico produzem hashes de contêiner diferentes. Fixe os digests no build final, após a última reconstrução.

## Comportamento do servicing offline

`dism /Add-Driver` numa imagem offline prepara o pacote de driver no DriverStore offline. Não executa uma instalação PnP completa para um dispositivo que não está presente. A operação `CopyFiles` do INF normalmente roda quando o dispositivo é instalado.

Consequências:

- O WIM modificado pode ser verificado quanto ao preparo do pacote de driver.
- A origem da nvram pode ser verificada no DriverStore.
- A cópia final `System32\drivers\4356r2nvram.txt` pode exigir a instalação PnP no hardware, ou uma cópia manual como plano B.
- O QEMU sem o BCM4356 não pode verificar o caminho final do rádio.

## Comandos de verificação

No hardware, antes da correção:

```bat
wmic path Win32_PnPEntity where "DeviceID like '%VEN_14E4&DEV_43EC%'" get Name,DeviceID,Status,ConfigManagerErrorCode
pnputil /enum-drivers
netsh wlan show drivers
```

Depois da correção:

```bat
wmic path Win32_PnPEntity where "DeviceID like '%VEN_14E4&DEV_43EC%'" get Name,DeviceID,Status,ConfigManagerErrorCode
pnputil /enum-drivers
netsh wlan show drivers
netsh wlan show interfaces
```

Esperado: código de erro `0`, o pacote de 2015 listado e o adaptador visível. Se o WMIC estiver ausente no WinRE, use `pnputil /enum-devices /problem` ou `devcon status`, se disponível.

## O que o QEMU pode e não pode provar

Pode provar:

- A imagem alvo contém o pacote de 2017.
- A imagem alvo não contém a nvram.
- A imagem offline tem o pacote de 2017 removido.
- A imagem offline tem o pacote de 2015 preparado.
- A origem da nvram está presente no pacote OEM preparado.
- Os arquivos de driver estão nos caminhos esperados do DriverStore.

Não pode provar:

- O BCM4356 inicia.
- O erro 10 vira 0.
- O Wi-Fi associa.
- A nvram é copiada para `System32\drivers` pelo PnP.

## Reproduzir o sintoma do erro 10 no QEMU (proposto, não provado)

O rádio real não pode ser emulado, mas o *sintoma* do erro 10 pode
potencialmente ser reproduzido sinteticamente. Duas abordagens, com fidelidades diferentes (veja `docs/04`):

- **A - dispositivo falso idêntico + driver real:** apresentar um dispositivo PCI do QEMU com o ID real
  (`x-pci-vendor-id=0x14e4,x-pci-device-id=0x43ec`, mais SUBSYS se o INF conferir) para que o
  Windows enumere `PCI\VEN_14E4&DEV_43EC` e o `bcmwdidhdpcie.inf` real vincule. O
  driver falha em iniciar em hardware não-BCM4356 -> erro 10. Fidelidade máxima de sintoma, mas
  um stub sem resposta não pode então ser *corrigido* (nenhum driver o inicia), então não
  demonstra a correção.
- **B - substituta funcional (e1000) + seleção de driver:** forçar um driver errado para obter o
  erro 10, depois o driver correto para iniciar. Demonstra a correção ponta a ponta, mas o
  dispositivo não é o BCM4356. Fidelidade menor; rotule como substituto.

Ambas precisam de um Windows completo inicializável com PnP (o repositório versiona só o WinRE). KVM é recomendado
por velocidade, não estritamente necessário - o TCG consegue inicializar o Windows devagar; este sandbox não tem
`/dev/kvm` e um boot anterior do WinRE deu BSOD sob TCG (não diagnosticado). Um agente com KVM deve executá-los.
São hipóteses, não resultados. Uma reprodução sintética do sintoma nunca é prova de hardware.
A transferência de texto digitado da nvram pequena (E3) é viável agora sem KVM - veja `docs/04`.

## Referências

- `drivers/README.md`
- `drivers/nvram-delta/README.md`
- `docs/05-offline-servicing.md`
- `docs/08-checklist-hardware.md`
- `experiments/E1-baseline-winre.md`
- `experiments/E2-offline-servicing.md`
