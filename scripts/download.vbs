' download.vbs — baixa um arquivo por HTTP(S) dentro do WinRE 1809.
' Motivo: o WinRE 1809 NAO tem certutil.exe nem powershell.exe (confirmado por inspecao),
' entao "certutil -urlcache" nao funciona. Este script usa WinHttpRequest/MSXML (presentes).
'
' Uso (no cmd do WinRE):
'   cscript //nologo download.vbs https://servidor/win.iso C:\win.iso
'
' Componentes usados, todos confirmados na imagem WinRE 17763:
'   WinHttp.WinHttpRequest.5.1 (fallback MSXML2.XMLHTTP) + ADODB.Stream (WinPE-MDAC).

Option Explicit

Dim url, dest, http, stream, erro

If WScript.Arguments.Count < 2 Then
    WScript.Echo "uso: cscript //nologo download.vbs <URL> <destino>"
    WScript.Quit 1
End If

url  = WScript.Arguments(0)
dest = WScript.Arguments(1)

On Error Resume Next
Set http = CreateObject("WinHttp.WinHttpRequest.5.1")
If Err.Number <> 0 Then
    Err.Clear
    Set http = CreateObject("MSXML2.XMLHTTP")
End If
If Err.Number <> 0 Then
    WScript.Echo "ERRO: nenhum componente HTTP disponivel"
    WScript.Quit 2
End If
On Error GoTo 0

WScript.Echo "baixando: " & url
http.Open "GET", url, False
http.SetTimeouts 30000, 30000, 600000, 600000
On Error Resume Next
http.Send
If Err.Number <> 0 Then
    WScript.Echo "ERRO de rede: " & Err.Description
    WScript.Quit 3
End If
On Error GoTo 0

If http.Status <> 200 Then
    WScript.Echo "ERRO HTTP: " & http.Status & " " & http.StatusText
    WScript.Quit 4
End If

On Error Resume Next
Set stream = CreateObject("ADODB.Stream")
If Err.Number <> 0 Then
    WScript.Echo "ERRO: ADODB.Stream indisponivel (falta WinPE-MDAC)"
    WScript.Quit 5
End If
stream.Type = 1              ' 1 = binario
stream.Open
stream.Write http.ResponseBody
stream.Position = 0
stream.SaveToFile dest, 2    ' 2 = sobrescreve
stream.Close
If Err.Number <> 0 Then
    WScript.Echo "ERRO ao gravar: " & Err.Description
    WScript.Quit 6
End If
On Error GoTo 0

WScript.Echo "ok: " & dest & " (" & LenB(http.ResponseBody) & " bytes)"
