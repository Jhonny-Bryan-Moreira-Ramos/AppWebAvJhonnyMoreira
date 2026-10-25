<%@ Language="VBScript" CodePage="65001" %>
<% Option Explicit %>
<!--#include file="includes/config.asp"-->
<!--#include file="includes/util.asp"-->
<!--#include file="includes/db.asp"-->
<!--#include file="includes/auth.asp"-->
<%
' ============================================================================
'  PoliMusic - Servicio JSON de canciones
' ----------------------------------------------------------------------------
'  Endpoint unico consumido por assets/js/songlist.js mediante fetch().
'  Acciones:  create | update | delete | play
'  Entrada :  POST (application/x-www-form-urlencoded)
'  Salida  :  { "ok": true|false, "message": "...", "data": {...} }
' ============================================================================

    Response.Buffer = True
    Response.CodePage = 65001
    Response.Charset = "utf-8"
    Response.ContentType = "application/json"
    Session.CodePage = 65001

    Dim actionName, conn, cmd, rs, songId, songName, songPath, plays
    Dim newId, newPlays, affected, txErr

    ' --- Lee un campo del formulario con respaldo en el query string ---------
    Function FieldValue(ByVal fieldName)
        Dim raw
        raw = Request.Form(fieldName)
        If Len(Trim(CStr(raw & ""))) = 0 Then raw = Request.QueryString(fieldName)
        FieldValue = Trim(CStr(raw & ""))
    End Function

    Set conn = Nothing
    Set cmd = Nothing
    Set rs = Nothing
    txErr = ""

    Call LoadSessionContext()
    Call RequireLoginJson()

    actionName = LCase(FieldValue("action"))
    If Len(actionName) = 0 Then
        SendJson False, "No se especifico ninguna accion.", ""
        Response.End
    End If

    Select Case actionName

        ' ====================================================================
        '  CREATE - Solo administradores
        ' ====================================================================
        Case "create"
            Call RequireAdminJson()

            songName = FieldValue("song_name")
            songPath = FieldValue("song_path")
            plays = ToInt(FieldValue("plays"), 0)

            If Len(songName) = 0 Or Len(songPath) = 0 Then
                SendJson False, "El nombre y la ruta del archivo son obligatorios.", ""
                Response.End
            End If
            If Len(songName) > 50 Then
                SendJson False, "El nombre no puede superar los 50 caracteres.", ""
                Response.End
            End If
            If Len(songPath) > 255 Then
                SendJson False, "La ruta no puede superar los 255 caracteres.", ""
                Response.End
            End If
            If plays < 0 Then plays = 0

            Set conn = OpenConnection()
            If conn Is Nothing Then
                Response.Status = "500 Internal Server Error"
                SendJson False, "No se pudo conectar con la base de datos. " & gConnError, ""
                Response.End
            End If

            Set cmd = NewCommand(conn, "INSERT INTO dbo.TBL_SONG (SONG_NAME, SONG_PATH, PLAYS) " & _
                                      "OUTPUT INSERTED.ID_SONG VALUES (?, ?, ?)")
            AddTextParam cmd, "SONG_NAME", songName, 50
            AddTextParam cmd, "SONG_PATH", songPath, 255
            AddIntParam cmd, "PLAYS", plays

            newId = 0
            On Error Resume Next
            Set rs = cmd.Execute
            If Err.Number <> 0 Then
                txErr = Err.Description
                Err.Clear
            Else
                If Not rs.EOF Then newId = ToInt(rs("ID_SONG"), 0)
                rs.Close
            End If
            On Error GoTo 0
            Set rs = Nothing
            Call CloseConnection(conn)

            If Len(txErr) > 0 Then
                Response.Status = "500 Internal Server Error"
                SendJson False, "No se pudo registrar la cancion. " & txErr, ""
            Else
                SendJson True, "Cancion registrada correctamente.", "{""id"":" & newId & "}"
            End If

        ' ====================================================================
        '  UPDATE - Solo administradores
        ' ====================================================================
        Case "update"
            Call RequireAdminJson()

            songId = ToInt(FieldValue("id"), 0)
            songName = FieldValue("song_name")
            songPath = FieldValue("song_path")
            plays = ToInt(FieldValue("plays"), 0)

            If songId <= 0 Then
                SendJson False, "Identificador de cancion invalido.", ""
                Response.End
            End If
            If Len(songName) = 0 Or Len(songPath) = 0 Then
                SendJson False, "El nombre y la ruta del archivo son obligatorios.", ""
                Response.End
            End If
            If Len(songName) > 50 Then
                SendJson False, "El nombre no puede superar los 50 caracteres.", ""
                Response.End
            End If
            If Len(songPath) > 255 Then
                SendJson False, "La ruta no puede superar los 255 caracteres.", ""
                Response.End
            End If
            If plays < 0 Then plays = 0

            Set conn = OpenConnection()
            If conn Is Nothing Then
                Response.Status = "500 Internal Server Error"
                SendJson False, "No se pudo conectar con la base de datos. " & gConnError, ""
                Response.End
            End If

            Set cmd = NewCommand(conn, "UPDATE dbo.TBL_SONG SET SONG_NAME = ?, SONG_PATH = ?, PLAYS = ? " & _
                                      "WHERE ID_SONG = ?")
            AddTextParam cmd, "SONG_NAME", songName, 50
            AddTextParam cmd, "SONG_PATH", songPath, 255
            AddIntParam cmd, "PLAYS", plays
            AddIntParam cmd, "ID_SONG", songId

            affected = 0
            txErr = ""
            On Error Resume Next
            cmd.Execute affected, , 128
            If Err.Number <> 0 Then
                txErr = Err.Description
                Err.Clear
            End If
            On Error GoTo 0
            Call CloseConnection(conn)

            If Len(txErr) > 0 Then
                Response.Status = "500 Internal Server Error"
                SendJson False, "No se pudo actualizar la cancion. " & txErr, ""
            ElseIf affected = 0 Then
                SendJson False, "La cancion ya no existe en el catalogo.", ""
            Else
                SendJson True, "Cancion actualizada correctamente.", "{""id"":" & songId & "}"
            End If

        ' ====================================================================
        '  DELETE - Solo administradores
        '     Se limpian primero las tablas relacionadas (FK) dentro de una
        '     transaccion para no dejar registros huerfanos.
        ' ====================================================================
        Case "delete"
            Call RequireAdminJson()

            songId = ToInt(FieldValue("id"), 0)
            If songId <= 0 Then
                SendJson False, "Identificador de cancion invalido.", ""
                Response.End
            End If

            Set conn = OpenConnection()
            If conn Is Nothing Then
                Response.Status = "500 Internal Server Error"
                SendJson False, "No se pudo conectar con la base de datos. " & gConnError, ""
                Response.End
            End If

            affected = 0
            txErr = ""
            On Error Resume Next
            conn.BeginTrans
            If Err.Number <> 0 Then
                txErr = Err.Description
                Err.Clear
            End If

            If Len(txErr) = 0 Then
                Set cmd = NewCommand(conn, "DELETE FROM dbo.TBL_TRACKLIST WHERE ID_SONG = ?")
                AddIntParam cmd, "ID_SONG", songId
                cmd.Execute , , 128
                If Err.Number <> 0 Then
                    txErr = Err.Description
                    Err.Clear
                End If
            End If

            If Len(txErr) = 0 Then
                Set cmd = NewCommand(conn, "DELETE FROM dbo.TBL_PLAYER WHERE ID_SONG = ?")
                AddIntParam cmd, "ID_SONG", songId
                cmd.Execute , , 128
                If Err.Number <> 0 Then
                    txErr = Err.Description
                    Err.Clear
                End If
            End If

            If Len(txErr) = 0 Then
                Set cmd = NewCommand(conn, "DELETE FROM dbo.TBL_PLAYLIST_SONG WHERE ID_SONG = ?")
                AddIntParam cmd, "ID_SONG", songId
                cmd.Execute , , 128
                If Err.Number <> 0 Then
                    txErr = Err.Description
                    Err.Clear
                End If
            End If

            If Len(txErr) = 0 Then
                Set cmd = NewCommand(conn, "DELETE FROM dbo.TBL_SONG WHERE ID_SONG = ?")
                AddIntParam cmd, "ID_SONG", songId
                cmd.Execute affected, , 128
                If Err.Number <> 0 Then
                    txErr = Err.Description
                    Err.Clear
                End If
            End If

            If Len(txErr) = 0 Then
                conn.CommitTrans
                If Err.Number <> 0 Then
                    txErr = Err.Description
                    Err.Clear
                End If
            Else
                conn.RollbackTrans
                Err.Clear
            End If
            On Error GoTo 0
            Call CloseConnection(conn)

            If Len(txErr) > 0 Then
                Response.Status = "500 Internal Server Error"
                SendJson False, "No se pudo eliminar la cancion. " & txErr, ""
            ElseIf affected = 0 Then
                SendJson False, "La cancion ya no existe en el catalogo.", ""
            Else
                SendJson True, "Cancion eliminada del catalogo.", "{""id"":" & songId & "}"
            End If

        ' ====================================================================
        '  PLAY - Cualquier usuario autenticado (incrementa PLAYS)
        ' ====================================================================
        Case "play"
            songId = ToInt(FieldValue("id"), 0)
            If songId <= 0 Then
                SendJson False, "Identificador de cancion invalido.", ""
                Response.End
            End If

            Set conn = OpenConnection()
            If conn Is Nothing Then
                Response.Status = "500 Internal Server Error"
                SendJson False, "No se pudo conectar con la base de datos. " & gConnError, ""
                Response.End
            End If

            newPlays = -1
            txErr = ""
            On Error Resume Next
            Set cmd = NewCommand(conn, "UPDATE dbo.TBL_SONG SET PLAYS = ISNULL(PLAYS, 0) + 1 " & _
                                       "OUTPUT INSERTED.PLAYS WHERE ID_SONG = ?")
            AddIntParam cmd, "ID_SONG", songId
            Set rs = cmd.Execute
            If Err.Number <> 0 Then
                txErr = Err.Description
                Err.Clear
            Else
                If Not rs.EOF Then newPlays = ToInt(rs("PLAYS"), -1)
                rs.Close
            End If
            On Error GoTo 0
            Set rs = Nothing
            Call CloseConnection(conn)

            If Len(txErr) > 0 Then
                SendJson False, "No se pudo registrar la reproduccion.", ""
            Else
                SendJson True, "Reproduccion registrada.", "{""id"":" & songId & ",""plays"":" & newPlays & "}"
            End If

        Case Else
            Response.Status = "400 Bad Request"
            SendJson False, "Accion no reconocida: " & actionName, ""

    End Select
%>
