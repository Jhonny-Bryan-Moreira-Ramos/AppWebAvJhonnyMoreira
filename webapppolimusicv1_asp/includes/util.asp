<%
' ============================================================================
'  PoliMusic - Funciones utilitarias compartidas
'  Requiere que includes/config.asp se haya incluido ANTES que este archivo.
' ============================================================================

' --- Salida segura para HTML -------------------------------------------------
Function H(ByVal value)
    H = Server.HTMLEncode(CStr(value & ""))
End Function

' --- Escapado de cadenas para construir JSON a mano --------------------------
Function JsStr(ByVal value)
    Dim s
    s = CStr(value & "")
    s = Replace(s, "\", "\\")
    s = Replace(s, """", "\""")
    s = Replace(s, vbCrLf, "\n")
    s = Replace(s, vbCr, "\n")
    s = Replace(s, vbLf, "\n")
    s = Replace(s, vbTab, "\t")
    JsStr = """" & s & """"
End Function

' --- Conversion segura a entero ---------------------------------------------
Function ToInt(ByVal value, ByVal fallback)
    Dim result
    ToInt = fallback
    If Not IsNumeric(value) Then Exit Function
    On Error Resume Next
    result = CLng(value)
    If Err.Number = 0 Then
        ToInt = result
    Else
        Err.Clear
    End If
    On Error GoTo 0
End Function

' --- Formato 1.234.567 (separador de miles en espanol) ----------------------
Function FormatIntEs(ByVal value)
    Dim s, i, buffer, group
    s = CStr(ToInt(value, 0))
    buffer = ""
    group = 0
    For i = Len(s) To 1 Step -1
        buffer = Mid(s, i, 1) & buffer
        group = group + 1
        If (group Mod 3) = 0 And i > 1 Then buffer = "." & buffer
    Next
    FormatIntEs = buffer
End Function

' --- Mapa de carpetas logicas (BDD) -> carpetas fisicas de recursos ----------
Function MapResourceFolder(ByVal folderName)
    Dim key
    key = LCase(Trim(folderName & ""))
    Select Case key
        Case "songfiles"
            MapResourceFolder = "SongFiles"
        Case "userimages"
            MapResourceFolder = "UserImages"
        Case "playlistimages"
            MapResourceFolder = "PlaylistImages"
        Case "albumimages"
            MapResourceFolder = "AlbumImages"
        Case "artistimages"
            MapResourceFolder = "ArtistImages"
        Case Else
            MapResourceFolder = folderName
    End Select
End Function

' --- Ruta fisica relativa:  ~/songFiles/x.mp3  ->  SongFilesAndImages_resources/SongFiles/x.mp3
Function ResolvePhysicalPath(ByVal rawPath)
    Dim p, slashPos, firstSeg, rest, mapped
    p = Trim(CStr(rawPath & ""))
    ResolvePhysicalPath = ""
    If Len(p) = 0 Then Exit Function

    If LCase(Left(p, 7)) = "http://" Or LCase(Left(p, 8)) = "https://" Then
        ResolvePhysicalPath = p
        Exit Function
    End If

    p = Replace(p, "\", "/")
    Do While InStr(p, "//") > 0
        p = Replace(p, "//", "/")
    Loop

    Do While Len(p) > 0
        If Left(p, 1) = "~" Or Left(p, 1) = "/" Then
            p = Mid(p, 2)
        Else
            Exit Do
        End If
    Loop

    If Len(p) = 0 Then Exit Function

    ' Si la ruta ya viene con la carpeta de recursos, se respeta tal cual.
    If LCase(Left(p, Len(RESOURCES_ROOT) + 1)) = LCase(RESOURCES_ROOT & "/") Then
        ResolvePhysicalPath = p
        Exit Function
    End If

    slashPos = InStr(p, "/")
    If slashPos > 0 Then
        firstSeg = Left(p, slashPos - 1)
        rest = Mid(p, slashPos + 1)
    Else
        firstSeg = p
        rest = ""
    End If

    mapped = MapResourceFolder(firstSeg)
    If Len(rest) > 0 Then
        ResolvePhysicalPath = RESOURCES_ROOT & "/" & mapped & "/" & rest
    Else
        ResolvePhysicalPath = RESOURCES_ROOT & "/" & mapped
    End If
End Function

' --- Codificacion de una ruta para usarla como URL ---------------------------
Function EncodeUrlPath(ByVal path)
    Dim i, ch, buffer, code
    buffer = ""
    For i = 1 To Len(path)
        ch = Mid(path, i, 1)
        Select Case ch
            Case " ", "#", "?", "%", "+", "&"
                code = Hex(Asc(ch))
                If Len(code) = 1 Then code = "0" & code
                buffer = buffer & "%" & code
            Case Else
                buffer = buffer & ch
        End Select
    Next
    EncodeUrlPath = buffer
End Function

' --- URL publica de un recurso almacenado en la base de datos ----------------
Function ResolveResourcePath(ByVal rawPath)
    ResolveResourcePath = EncodeUrlPath(ResolvePhysicalPath(rawPath))
End Function

' --- Verifica que el archivo exista fisicamente ------------------------------
Function ResourceFileExists(ByVal rawPath)
    Dim physical, fso, full
    ResourceFileExists = False
    physical = ResolvePhysicalPath(rawPath)
    If Len(physical) = 0 Then Exit Function

    If LCase(Left(physical, 7)) = "http://" Or LCase(Left(physical, 8)) = "https://" Then
        ResourceFileExists = True
        Exit Function
    End If

    On Error Resume Next
    Set fso = Server.CreateObject("Scripting.FileSystemObject")
    full = Server.MapPath(physical)
    If Err.Number = 0 Then
        ResourceFileExists = fso.FileExists(full)
    Else
        Err.Clear
    End If
    If Err.Number <> 0 Then Err.Clear
    Set fso = Nothing
    On Error GoTo 0
End Function

' --- Etiquetas de rol a partir de USER_TYPE ----------------------------------
Function RoleLabel(ByVal userType)
    If ToInt(userType, USER_TYPE_NORMAL) = USER_TYPE_ADMIN Then
        RoleLabel = "Administrador"
    Else
        RoleLabel = "Usuario"
    End If
End Function

Function RoleSlug(ByVal userType)
    If ToInt(userType, USER_TYPE_NORMAL) = USER_TYPE_ADMIN Then
        RoleSlug = "admin"
    Else
        RoleSlug = "user"
    End If
End Function

' --- Icono (id del sprite) asociado al rol -----------------------------------
Function RoleIcon(ByVal adminFlag)
    If adminFlag Then
        RoleIcon = "shield"
    Else
        RoleIcon = "eye"
    End If
End Function

' --- Respuesta JSON uniforme -------------------------------------------------
Sub SendJson(ByVal success, ByVal message, ByVal dataJson)
    Dim flag, payload
    If success Then flag = "true" Else flag = "false"

    payload = "null"
    If Not IsEmpty(dataJson) And Not IsNull(dataJson) Then
        If Len(Trim(CStr(dataJson & ""))) > 0 Then payload = CStr(dataJson)
    End If

    Response.Write "{" & """ok"":" & flag & _
                   ",""message"":" & JsStr(message) & _
                   ",""data"":" & payload & "}"
End Sub
%>
