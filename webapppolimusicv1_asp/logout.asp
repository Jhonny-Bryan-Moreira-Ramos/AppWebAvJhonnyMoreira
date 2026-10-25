<%@ Language="VBScript" CodePage="65001" %>
<% Option Explicit %>
<%
' ============================================================================
'  PoliMusic - Cierre de sesion
' ----------------------------------------------------------------------------
'  Destruye el contenido de la sesion y devuelve al usuario al login.
' ============================================================================

    Response.Buffer = True
    Response.CodePage = 65001
    Response.Charset = "utf-8"

    ' Limpia cada variable antes de abandonar la sesion.
    Session.Contents.RemoveAll()
    Session.Abandon()

    Response.CacheControl = "no-cache"
    Response.Expires = -1
    Response.Redirect "login.asp"
    Response.End
%>
