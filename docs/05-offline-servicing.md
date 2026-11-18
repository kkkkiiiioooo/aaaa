# Servicing offline

> **Procedência:** verificada. A imagem base é o WinRE 1809 extraído do ESD
> oficial (`winre-1809-oficial-intacta/`, ESD SHA-1 `8352af76…`, WIM SHA-256 `232199c5…`).
> Os testes de servicing foram feitos numa cópia; os resultados são sobre o procedimento. Veja
> `docs/06-auditoria-imagem-1809.md`.

## Propósito

Modificar uma cópia do WIM do WinRE para que contenha o driver Wi-Fi OEM de 2015 em vez do driver inbox de 2017. O servicing offline funciona sobre a imagem enquanto ela não está inicializada.

Este é o caminho principal. Os planos B são `pnputil` e `devcon` num WinRE em execução.

## Pré-condições

- `cmd` do WinRE disponível.
- Uma cópia do WIM do WinRE acessível.
- O WIM base deve conter `bcmwdidhdpcie.inf` versão `1.558.53.25`. Use o WinRE 1809 re-extraído do ESD oficial (`winre-1809-oficial-intacta/`).
- Não use o WIM de fábrica 10586 como base de drivers: ele não tem `bcmwdidhdpcie.inf` e não consegue reproduzir a falha PCIe de 2017.
- O pacote Wi-Fi OEM acessível num volume local.
- O WIM alvo com backup feito.
- Espaço livre suficiente em `C:` para a cópia, o diretório de montagem e o WIM modificado.
- O dispositivo BCM4356 presente no dispositivo físico. O QEMU não o tem.

## Localizar o WIM

Caminho comum:

```bat
dir D:\Recovery\WindowsRE\Winre.wim
```

Se não for encontrado:

```bat
dir /s /b D:\Winre.wim
```

Ajuste a letra da unidade para a partição de recuperação. Não assuma que é sempre `D:`.

## Backup

```bat
copy /Y D:\Recovery\WindowsRE\Winre.wim C:\winre-orig.wim
```

Mantenha `C:\winre-orig.wim` até a imagem modificada estar verificada e o dispositivo recuperado.

## Montar

```bat
mkdir C:\mnt
dism /Mount-Wim /WimFile:C:\winre-orig.wim /Index:1 /MountDir:C:\mnt
```

## Listar drivers

```bat
dism /Image:C:\mnt /Get-Drivers /Format:Table
```

Ache o pacote inbox da Broadcom. Ele tem:

- Nome de arquivo original: `bcmwdidhdpcie.inf`
- Versão: `1.558.53.25`
- Data: `21/04/2017`
- Nome publicado: `oemXX.inf`

Registre o nome publicado. O valor `XX` é local à imagem.

Se este pacote estiver ausente, a imagem base está errada. Pare e use o WinRE 1809. O WIM de fábrica 10586 não contém este pacote.

## Remover o pacote inbox

```bat
dism /Image:C:\mnt /Remove-Driver /Driver:oemXX.inf
```

Substitua `oemXX.inf` pelo nome publicado do passo anterior.

Se o DISM recusar porque o pacote não é removível, pare e registre o erro exato. Não apague arquivos à mão ainda. Use o caminho alternativo em `docs/03-driver-wifi-erro-10.md`.

## Adicionar o pacote OEM

```bat
dism /Image:C:\mnt /Add-Driver /Driver:C:\OEM\wifi\oem25.inf
```

O diretório deve conter `oem25.inf` e todos os arquivos que ele referencia, incluindo:

- `bcmpciedhd63.sys`
- `bcmpciedhd63.cat`
- `4356a2rtecdc.bin`
- `bcm94356wlpagbl_P3_150828M.txt`
- `bcmihvsrv64.dll`
- `bcmihvui64.dll`

No ambiente QEMU o pacote OEM é colocado em `C:\OEM\wifi`. No dispositivo físico ele precisa já ser local ou chegar pelo canal externo sob teste.

## Verificar o preparo

```bat
dism /Image:C:\mnt /Get-Drivers /Format:Table
```

Esperado:

- O pacote de 2017 sumiu.
- Um pacote Broadcom com versão `1.558.14.0` e data `23/12/2015` está listado.

Confira o DriverStore:

```bat
dir C:\mnt\Windows\System32\DriverStore\FileRepository\oem25.inf_amd64_*
dir C:\mnt\Windows\System32\DriverStore\FileRepository\oem25.inf_amd64_*\4356a2rtecdc.bin
dir C:\mnt\Windows\System32\DriverStore\FileRepository\oem25.inf_amd64_*\bcm94356wlpagbl_P3_150828M.txt
```

O hash exato da pasta é gerado quando o pacote é preparado. Não espere que o nome da pasta inbox permaneça.

## Nota sobre a nvram

`dism /Add-Driver` prepara o pacote. Ele não executa necessariamente a lista de cópia do INF para o dispositivo. A cópia `System32\drivers\4356r2nvram.txt` normalmente acontece durante a instalação PnP.

Se o teste no dispositivo físico mostrar que a nvram não foi copiada, use o plano B antes de inicializar a imagem modificada:

```bat
copy /Y C:\mnt\Windows\System32\DriverStore\FileRepository\oem25.inf_amd64_*\bcm94356wlpagbl_P3_150828M.txt C:\mnt\Windows\System32\drivers\4356r2nvram.txt
```

Faça isso apenas se a regra de cópia não rodar. Prefira o caminho do INF e do PnP. Registre a decisão.

O firmware tem uma renomeação semelhante:

```text
4356a2rtecdc.bin -> 4356r2rtecdc.bin
```

A imagem inbox já contém a origem do firmware. O INF do OEM também a contém. Prefira o caminho de cópia do PnP.

## Commit

```bat
dism /Unmount-Wim /MountDir:C:\mnt /Commit
```

O WIM modificado agora é `C:\winre-orig.wim`. Não sobrescreva o WIM original de recuperação até a cópia modificada estar verificada.

## Inicializar a imagem modificada

QEMU:

- Construa a mídia de boot a partir do WIM modificado.
- Inicialize o WinRE modificado.
- Verifique com `dism`, `pnputil` e `dir`.
- O BCM4356 está ausente, então o resultado do rádio não é testável.

Dispositivo físico:

- Se o WIM modificado couber na partição de recuperação, faça backup do original e substitua-o.
- Se não couber, mantenha-o em `C:` e crie uma entrada no BCD para ele. Isso é avançado e deve ser testado no QEMU antes.
- Não apague o original até a imagem modificada inicializar e o adaptador funcionar.

## Restrição de espaço

A partição de recuperação real tem cerca de 398 MB. O WIM original tem aproximadamente o mesmo tamanho. O WIM modificado pode ficar maior depois de adicionar o pacote OEM. Não assuma que há espaço no `D:`.

Ordem preferida:

1. Mantenha o original em `C:`.
2. Modifique a cópia em `C:`.
3. Inicialize a cópia em `C:` por uma entrada no BCD.
4. Só substitua o `D:` se o arquivo modificado couber e o original estiver com backup.

## Reversão

Reversão imediata:

```bat
copy /Y C:\winre-orig.wim D:\Recovery\WindowsRE\Winre.wim
```

Se uma entrada no BCD foi adicionada, remova-a. Se o original foi substituído, restaure do backup. Registre o resultado da reversão.

## Plano B: pnputil num WinRE em execução

Isso muda o WinRE em execução (baseado em RAM), não o WIM. É útil para download de uma sessão só.

```bat
pnputil /enum-drivers
pnputil /delete-driver oemXX.inf /uninstall /force
pnputil /add-driver C:\OEM\wifi\oem25.inf /install
pnputil /scan-devices
netsh wlan show drivers
```

Se o pacote inbox não puder ser apagado, use `devcon update` ou o equivalente de seleção manual.

## Plano B: devcon

`devcon` não faz parte do WinRE. Ele já precisa estar local.

```bat
devcon update C:\OEM\wifi\oem25.inf "PCI\VEN_14E4&DEV_43EC"
devcon status "PCI\VEN_14E4&DEV_43EC"
```

## Última instância: substituição manual do .sys

Não comece por aqui. Substituir `System32\drivers\bcmpciedhd63.sys` à mão contorna o tratamento normal de pacotes de driver e pode quebrar o registro de serviços ou as verificações de assinatura. Use somente se o DISM e o `pnputil` falharem ambos, e registre cada passo.

## Lista de verificação de validação

- [ ] WIM original com backup.
- [ ] Pacote 2017 identificado pelo nome publicado.
- [ ] Pacote 2017 removido.
- [ ] Pacote 2015 preparado.
- [ ] `Get-Drivers` mostra 1.558.14.0.
- [ ] Origens do firmware e da nvram OEM presentes no pacote preparado.
- [ ] Commit bem-sucedido.
- [ ] WIM modificado inicializa.
- [ ] Decisão do plano B registrada.
- [ ] Verificação de hardware feita separadamente.
