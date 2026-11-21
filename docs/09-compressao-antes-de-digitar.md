# H-B12 - Compressao antes de digitar (host-only, NAO e prova)

Medido em 21/11/2026 no sandbox (python3 zlib/bz2/lzma). Nada foi testado no WinRE.

| Arquivo | Bytes | Melhor compressor | Comprimido | Hex digitado | Base64 digitado |
|---|---|---|---|---|---|
| 4356r2nvram.txt | 5.361 | lzma (0,321) | 1.720 | 3.440 (era 10.722) | 2.296 (era 7.148) |
| 4356r2nvram.txt | 5.361 | zlib-9 (0,338) | 1.810 | 3.620 | 2.416 |
| 4356a2rtecdc.bin | 641.951 | lzma (0,540) | 346.952 | 693.904 (era 1.283.902) | 462.604 (era 855.936) |
| 4356a2rtecdc.bin | 641.951 | zlib-9 (0,637) | 408.635 | 817.270 | 544.848 |

## Leitura
- Hipotese H-B12 sustentada **so no host**: a nvram cai ~68% (10.722 -> 3.440 chars em hex). O firmware cai 46% no melhor caso, mas ainda sao ~700 mil caracteres: inviavel digitar.
- Custo escondido: o dispositivo precisa de um **descompressor ja presente** no WinRE. Compressao so vale se existir `expand.exe`/`makecab`/`extrac32` (CAB MSZIP/LZX) na imagem. Inventario (`inventory/winre-1809-files.txt`) lista `/Windows/System32/expand.exe` no WinRE 1809 (existencia em arquivo, nao execucao). `makecab` nao confirmado. Falta `where expand` + teste no WinRE real.
- Para a nvram (5,4 KB) o ganho absoluto e pequeno (~7 mil caracteres) e adiciona um passo binario (o CAB e binario, cai no problema do sumidouro E7). Recomendacao provisoria (hipotese): **nao comprimir a nvram**; digitar ASCII direto.
- RLE simples quase nao ajuda (5.361 -> 5.328).

## Refuta / proximo
- Refutaria utilidade: se `expand.exe` nao existir no WinRE real.
- Proximo: H-B13 (firmware ja local) segue sendo o ganho maior; evita digitar os 641.951 B.
