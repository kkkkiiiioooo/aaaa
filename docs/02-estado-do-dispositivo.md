# Estado do dispositivo alvo

## Significado

`drivers/estado-dispositivo/` é o subconjunto quebrado do DriverStore da Broadcom. É a linha de base, não a correção.

## Pastas exatas

| Pasta | Arquivos | Pacote |
|---|---|---|
| `bcmwdidhdpcie.inf_amd64_977dcc915465b0e9/` | 4 | Wi-Fi PCIe |
| `bcmdhd64.inf_amd64_e0bae6831f60ea5f/` | 5 | Wi-Fi SDIO |
| `bcmfn2.inf_amd64_5ebadf201c5b5845/` | 2 | Função SDIO |

Esses nomes fazem parte do retrato do DriverStore alvo. A imagem de origem não está neste repositório.

## Arquivos Wi-Fi alvo

```text
bcmwdidhdpcie.inf
bcmpciedhd63.sys
4356a2rtecdc.bin
43596a0rtecdc.bin
```

Nenhum arquivo de nvram está presente.

O arquivo `43596a0rtecdc.bin` pertence à seção BCM4359 / `DEV_4355`. Ele fica na pasta porque o DriverStore alvo é mantido idêntico. A seção `DEV_43EC` usa `4356a2rtecdc.bin`.

## Arquivos SDIO alvo

`bcmdhd64.inf_amd64_e0bae6831f60ea5f/`:

```text
bcmdhd64.inf
bcmdhd63.sys
43241b4rtecdc.bin
4324b5rtecdc.bin
43341b0rtecdc.bin
```

`bcmfn2.inf_amd64_5ebadf201c5b5845/`:

```text
bcmfn2.inf
bcmfn2.sys
```

## Checksums

Manifesto: `drivers/estado-dispositivo/SHA256SUMS`.

É um artefato do repositório no nível acima, fora das pastas do DriverStore. Verifique com:

```sh
cd drivers/estado-dispositivo
sha256sum -c SHA256SUMS
```

## O que não está aqui

- A nvram não está aqui.
- A partição de recuperação completa de 398 MB não está aqui.
- O pacote OEM não está aqui.
- O `bcmpciedhd63.sys` de 2015 não está aqui.
- A correção não está aplicada.

## Relação com o pacote OEM

O estado alvo é o pacote inbox 2017. O pacote OEM em `drivers/mipad2-oficial/wifi/` é a substituição. O `oem25.inf` OEM é da versão 1.558.14.0 e contém a regra de cópia da nvram. O `bcmwdidhdpcie.inf` alvo é da versão 1.558.53.25 e não contém a regra de cópia da nvram.

## Regras do estado alvo

- Não adicione a nvram neste diretório.
- Não substitua os arquivos inbox pelos OEM no lugar.
- Não trate os pacotes SDIO ou de função como a correção do Wi-Fi.
- Não reivindique que este subconjunto é a imagem de recuperação completa.
- Se o estado alvo mudar no dispositivo, atualize este diretório e os seus checksums juntos.
