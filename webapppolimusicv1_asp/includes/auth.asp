<%
' ============================================================================
'  PoliMusic - Control de sesion y roles
'  Requiere: config.asp y util.asp incluidos antes que este archivo.
' ----------------------------------------------------------------------------
'  login.asp es el unico punto donde se escriben las variables de sesion:
'      Session("USERNAME")   -> nombre del usuario logueado
'      Session("USER_TYPE")  -> 0 = Usuario normal | 1 = Administrador
'      Session("USER_PHOTO") -> ruta de la foto (~/userImages/...)
'      Session("ID_USER")    -> llave primaria de TBL_USER
' ============================================================================

Dim SESSION_USERNAME, SESSION_USER_TYPE, SESSION_USER_PHOTO, SESSION_USER_ID

' --- Hidrata las variables de sesion en variables de pagina ------------------
Sub LoadSessionContext()
    SESSION_USERNAME   = Trim(CStr(Session(SESSION_KEY_USERNAME) & ""))
    SESSION_USER_TYPE  = ToInt(Session(SESSION_KEY_USERTYPE), USER_TYPE_NORMAL)
    SESSION_USER_PHOTO = Trim(CStr(Session(SESSION_KEY_PHOTO) & ""))
    SESSION_USER_ID    = ToInt(Session(SESSION_KEY_IDUSER), 0)
End Sub

' --- Estado de autenticacion -------------------------------------------------
Function IsLoggedIn()
    IsLoggedIn = (Len(SESSION_USERNAME) > 0)
End Function

' --- Rol del usuario en sesion -----------------------------------------------
Function IsAdmin()
    IsAdmin = (SESSION_USER_TYPE = USER_TYPE_ADMIN)
End Function

' --- Guardia de pagina -------------------------------------------------------
Sub RequireLogin()
    If Not IsLoggedIn() Then
        Response.Redirect "login.asp"
        Response.End
    End If
End Sub

' --- Guardia de endpoint -----------------------------------------------------
'     Se usa en los servicios JSON para no devolver HTML a una peticion fetch.
Sub RequireLoginJson()
    If Not IsLoggedIn() Then
        Response.Status = "401 Unauthorized"
        SendJson False, "Tu sesion expiro. Inicia sesion nuevamente.", ""
        Response.End
    End If
End Sub

Sub RequireAdminJson()
    If Not IsAdmin() Then
        Response.Status = "403 Forbidden"
        SendJson False, "Solo un administrador puede realizar esta accion.", ""
        Response.End
    End If
End Sub
%>
