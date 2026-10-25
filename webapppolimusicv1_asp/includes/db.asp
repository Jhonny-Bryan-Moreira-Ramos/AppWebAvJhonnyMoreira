<%
' ============================================================================
'  PoliMusic - Capa de acceso a datos (ADO / SQL Server)
'  Requiere que includes/config.asp se haya incluido ANTES que este archivo.
' ----------------------------------------------------------------------------
'  ADO no siempre encuentra el mismo proveedor instalado en todas las
'  maquinas, por eso OpenConnection prueba una lista de cadenas de conexion
'  en orden de preferencia y devuelve la primera que responda.
' ============================================================================

Dim gConnError
gConnError = ""

' --- Lista de cadenas candidatas --------------------------------------------
Function BuildConnectionCandidates()
    Dim authPart
    ' Se agregan los parametros de encriptacion y certificado de confianza 
    ' comprobados previamente para la conexion local a SQL Server.
    authPart = ";UID=" & DB_USER & ";PWD=" & DB_PASSWORD & ";Encrypt=Yes;TrustServerCertificate=Yes;"

    BuildConnectionCandidates = Array( _
        "Provider=MSOLEDBSQL;Server=" & DB_SERVER & ";Database=" & DB_NAME & authPart, _
        "Provider=MSOLEDBSQL19;Server=" & DB_SERVER & ";Database=" & DB_NAME & authPart, _
        "Provider=SQLNCLI11;Server=" & DB_SERVER & ";Database=" & DB_NAME & authPart, _
        "Provider=SQLOLEDB;Server=" & DB_SERVER & ";Database=" & DB_NAME & authPart, _
        "Driver={ODBC Driver 18 for SQL Server};Server=" & DB_SERVER & ";Database=" & DB_NAME & authPart, _
        "Driver={ODBC Driver 17 for SQL Server};Server=" & DB_SERVER & ";Database=" & DB_NAME & authPart, _
        "Driver={SQL Server Native Client 11.0};Server=" & DB_SERVER & ";Database=" & DB_NAME & authPart, _
        "Driver={SQL Server};Server=" & DB_SERVER & ";Database=" & DB_NAME & authPart _
    )
End Function

' --- Abre una conexion ------------------------------------------------------
'     Devuelve Nothing si ninguna cadena funciono; el detalle queda en gConnError.
Function OpenConnection()
    Dim candidates, i, cn, lastError
    Set OpenConnection = Nothing
    gConnError = ""
    candidates = BuildConnectionCandidates()

    For i = 0 To UBound(candidates)
        lastError = ""
        On Error Resume Next
        Set cn = Server.CreateObject("ADODB.Connection")
        If Err.Number <> 0 Then
            lastError = Err.Description
            Err.Clear
        Else
            cn.ConnectionTimeout = 5
            cn.Open candidates(i)
            If Err.Number <> 0 Then
                lastError = Err.Description
                Err.Clear
            End If
        End If
        On Error GoTo 0

        If Len(lastError) = 0 Then
            Set OpenConnection = cn
            Exit Function
        End If

        On Error Resume Next
        If IsObject(cn) Then
            If Not (cn Is Nothing) Then
                If cn.State <> 0 Then cn.Close
            End If
            Set cn = Nothing
        End If
        Err.Clear
        On Error GoTo 0
        gConnError = lastError
    Next

    If Len(gConnError) = 0 Then gConnError = "No se pudo establecer conexion con SQL Server."
End Function

' --- Cierre defensivo -------------------------------------------------------
Sub CloseConnection(ByRef cn)
    On Error Resume Next
    If IsObject(cn) Then
        If Not (cn Is Nothing) Then
            If cn.State <> 0 Then cn.Close
        End If
        Set cn = Nothing
    End If
    Err.Clear
    On Error GoTo 0
End Sub

' --- Crea un comando parametrizado (evita inyeccion SQL) --------------------
Function NewCommand(ByRef cn, ByVal sqlText)
    Dim cmd
    Set cmd = Server.CreateObject("ADODB.Command")
    Set cmd.ActiveConnection = cn
    cmd.CommandType = 1              ' adCmdText
    cmd.CommandText = sqlText
    Set NewCommand = cmd
End Function

' --- Parametros tipados -----------------------------------------------------
'     adVarChar = 202 | adInteger = 3 | adParamInput = 1
Sub AddTextParam(ByRef cmd, ByVal name, ByVal value, ByVal size)
    cmd.Parameters.Append cmd.CreateParameter(name, 202, 1, size, CStr(value & ""))
End Sub

Sub AddIntParam(ByRef cmd, ByVal name, ByVal value)
    cmd.Parameters.Append cmd.CreateParameter(name, 3, 1, 4, ToInt(value, 0))
End Sub
%>