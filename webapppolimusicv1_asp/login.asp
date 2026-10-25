<%@ Language="VBScript" CodePage="65001" %>
<% Option Explicit %>
<!--#include file="includes/config.asp"-->
<!--#include file="includes/util.asp"-->
<!--#include file="includes/db.asp"-->
<%
' ============================================================================
'  PoliMusic - Inicio de sesion
' ----------------------------------------------------------------------------
'  Unico punto del sistema donde se escriben las variables de sesion que
'  consume songList.asp:
'      Session("USERNAME")  | Session("USER_TYPE") | Session("USER_PHOTO")
' ============================================================================

    Response.Buffer = True
    Response.CodePage = 65001
    Response.Charset = "utf-8"
    Session.CodePage = 65001

    Dim username, password, loginError, conn, cmd, rs
    Dim requestMethod, alreadyLogged

    loginError = ""
    username = ""
    alreadyLogged = (Len(Trim(CStr(Session(SESSION_KEY_USERNAME) & ""))) > 0)

    ' Si ya hay sesion activa no tiene sentido volver al formulario.
    If alreadyLogged And Request.ServerVariables("REQUEST_METHOD") <> "POST" Then
        Response.Redirect "songList.asp"
        Response.End
    End If

    requestMethod = UCase(CStr(Request.ServerVariables("REQUEST_METHOD") & ""))

    If requestMethod = "POST" Then
        username = Trim(CStr(Request.Form("username") & ""))
        password = Trim(CStr(Request.Form("password") & ""))

        If Len(username) = 0 Or Len(password) = 0 Then
            loginError = "Ingresa tu usuario y tu contrasena."
        Else
            Set conn = OpenConnection()
            If conn Is Nothing Then
                loginError = "No se pudo conectar con la base de datos. " & gConnError
            Else
                Set rs = Nothing
                On Error Resume Next
                Set cmd = NewCommand(conn, "SELECT TOP 1 ID_USER, USERNAME, USER_TYPE, USER_PHOTO " & _
                                           "FROM dbo.TBL_USER WHERE USERNAME = ? AND PASSWORD = ?")
                AddTextParam cmd, "P_USERNAME", username, 50
                AddTextParam cmd, "P_PASSWORD", password, 50
                Set rs = cmd.Execute
                If Err.Number <> 0 Then
                    loginError = "Error al consultar los usuarios: " & Err.Description
                    Err.Clear
                End If
                On Error GoTo 0

                If Len(loginError) = 0 Then
                    If rs Is Nothing Then
                        loginError = "No se pudo validar el usuario."
                    ElseIf rs.EOF Then
                        loginError = "Usuario o contrasena incorrectos."
                    Else
                        Session(SESSION_KEY_IDUSER)   = ToInt(rs("ID_USER"), 0)
                        Session(SESSION_KEY_USERNAME) = CStr(rs("USERNAME") & "")
                        Session(SESSION_KEY_USERTYPE) = ToInt(rs("USER_TYPE"), USER_TYPE_NORMAL)
                        Session(SESSION_KEY_PHOTO)    = CStr(rs("USER_PHOTO") & "")

                        On Error Resume Next
                        rs.Close
                        Err.Clear
                        On Error GoTo 0
                        Call CloseConnection(conn)

                        Response.Redirect "songList.asp"
                        Response.End
                    End If
                End If

                On Error Resume Next
                If Not (rs Is Nothing) Then
                    If rs.State <> 0 Then rs.Close
                    Set rs = Nothing
                End If
                Err.Clear
                On Error GoTo 0
                Call CloseConnection(conn)
            End If
        End If
    End If
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Iniciar sesion &middot; <%=APP_NAME%></title>
    <link rel="icon" href="<%=RESOURCES_ROOT%>/PlaylistImages/default.jpg">
    <link rel="stylesheet" href="assets/css/polimusic.css">
</head>
<body class="auth-body">

<svg class="svg-sprite" xmlns="http://www.w3.org/2000/svg" aria-hidden="true" focusable="false">
    <symbol id="i-note" viewBox="0 0 24 24">
        <path d="M19 3.5a1 1 0 0 0-1.2-.98l-8 1.7A1 1 0 0 0 9 5.2v9.05A3.6 3.6 0 1 0 11 17.4V8.9l6-1.27v4.62a3.6 3.6 0 1 0 2 3.15V3.5Z"/>
    </symbol>
    <symbol id="i-alert" viewBox="0 0 24 24">
        <path d="M12 3.2c.7 0 1.3.37 1.65.98l8.1 14.2A1.9 1.9 0 0 1 20.1 21H3.9a1.9 1.9 0 0 1-1.65-2.82l8.1-14.2c.35-.6.95-.98 1.65-.98Zm0 2.6L4.7 19h14.6L12 5.8Zm0 3.4a1 1 0 0 1 1 1v4a1 1 0 1 1-2 0v-4a1 1 0 0 1 1-1Zm0 7a1.2 1.2 0 1 1 0 2.4 1.2 1.2 0 0 1 0-2.4Z"/>
    </symbol>
    <symbol id="i-lock" viewBox="0 0 24 24">
        <path d="M12 2.5a5 5 0 0 0-5 5V10H6a2.5 2.5 0 0 0-2.5 2.5v7A2.5 2.5 0 0 0 6 22h12a2.5 2.5 0 0 0 2.5-2.5v-7A2.5 2.5 0 0 0 18 10h-1V7.5a5 5 0 0 0-5-5Zm0 2a3 3 0 0 1 3 3V10H9V7.5a3 3 0 0 1 3-3Zm-6 7.5h12a.5.5 0 0 1 .5.5v7a.5.5 0 0 1-.5.5H6a.5.5 0 0 1-.5-.5v-7a.5.5 0 0 1 .5-.5Zm6 2.2a1.7 1.7 0 0 0-.9 3.14V19a.9.9 0 0 0 1.8 0v-1.66A1.7 1.7 0 0 0 12 14.2Z"/>
    </symbol>
    <symbol id="i-user" viewBox="0 0 24 24">
        <path d="M12 3a4.5 4.5 0 1 0 0 9 4.5 4.5 0 0 0 0-9Zm0 2a2.5 2.5 0 1 1 0 5 2.5 2.5 0 0 1 0-5Zm0 8.5c-4.2 0-7.5 2.4-7.5 5.4V21a1 1 0 0 0 1 1h13a1 1 0 0 0 1-1v-2.1c0-3-3.3-5.4-7.5-5.4Zm0 2c3.1 0 5.5 1.7 5.5 3.4V20h-11v-1.1c0-1.7 2.4-3.4 5.5-3.4Z"/>
    </symbol>
</svg>

<main class="auth">
    <!-- Panel decorativo -->
    <section class="auth__aside">
        <div class="auth__brand">
            <span class="brand__mark"><svg class="ico"><use href="#i-note"></use></svg></span>
            <span class="brand__name">Poli<span>Music</span></span>
        </div>

        <div class="auth__pitch">
            <h1>Toda tu musica,<br>en un solo lugar.</h1>
            <p>Administra el catalogo, reproduce tus pistas favoritas y organiza tu biblioteca personal.</p>
        </div>

        <div class="auth__eq" aria-hidden="true">
            <span></span><span></span><span></span><span></span><span></span><span></span>
            <span></span><span></span><span></span><span></span><span></span><span></span>
            <span></span><span></span><span></span><span></span><span></span><span></span>
        </div>
    </section>

    <!-- Formulario -->
    <section class="auth__panel">
        <div class="auth__card">
            <header class="auth__head">
                <p class="modal__eyebrow">Bienvenido de nuevo</p>
                <h2>Inicia sesion</h2>
                <p class="auth__sub">Usa tus credenciales de <%=APP_NAME%> para continuar.</p>
            </header>

            <% If Len(loginError) > 0 Then %>
            <div class="alert alert--error auth__alert">
                <svg class="ico"><use href="#i-alert"></use></svg>
                <div><%=H(loginError)%></div>
            </div>
            <% End If %>

            <form class="form auth__form" method="post" action="login.asp" autocomplete="on">
                <input type="hidden" name="action" value="login">

                <div class="field">
                    <label for="username">Usuario</label>
                    <div class="input-ico">
                        <svg class="ico"><use href="#i-user"></use></svg>
                        <input id="username" name="username" type="text" maxlength="50"
                               value="<%=H(username)%>" placeholder="userAdmin" required autofocus>
                    </div>
                </div>

                <div class="field">
                    <label for="password">Contrasena</label>
                    <div class="input-ico">
                        <svg class="ico"><use href="#i-lock"></use></svg>
                        <input id="password" name="password" type="password" maxlength="50"
                               placeholder="********" required>
                    </div>
                </div>

                <button class="btn btn--primary auth__submit" type="submit">Entrar al catalogo</button>
            </form>

            <div class="auth__hint">
                <strong>Usuarios de prueba</strong>
                <span><code>userAdmin</code> / <code>12345678</code> &mdash; administrador (CRUD)</span>
                <span><code>userNormal</code> / <code>12345678</code> &mdash; usuario (solo lectura)</span>
            </div>
        </div>

        <p class="auth__foot"><%=APP_NAME%> v<%=APP_VERSION%> &middot; Base de datos <code>BDD_PoliMusic</code></p>
    </section>
</main>

</body>
</html>
