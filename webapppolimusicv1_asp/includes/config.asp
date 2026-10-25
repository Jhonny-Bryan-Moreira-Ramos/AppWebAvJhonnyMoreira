<%
' ============================================================================
'  PoliMusic - Configuracion global
'  Proyecto : webapppolimusicv1_asp
'  Autor    : Jhonny Moreira
' ----------------------------------------------------------------------------
'  Este archivo concentra TODAS las constantes del sistema. Cambia aqui y
'  no en otro lugar si necesitas mover la base de datos o los recursos.
' ============================================================================

' --- Identidad de la aplicacion ---------------------------------------------
Const APP_NAME        = "PoliMusic"
Const APP_SUBTITLE    = "Biblioteca musical"
Const APP_VERSION     = "1.0"

' --- Carpeta de recursos estaticos (imagenes, portadas, audio) --------------
Const RESOURCES_ROOT  = "SongFilesAndImages_resources"

' --- Conexion a SQL Server (localhost) --------------------------------------
Const DB_SERVER       = "localhost"
Const DB_NAME         = "BDD_PoliMusic"
Const DB_USER         = "usr_polimusic"
Const DB_PASSWORD     = "Politecnica1"

' --- Catalogo TBL_CATALOG -> 'USER TYPE' ------------------------------------
'     COD_CATALOG_PARENT = '1' | COD_CATALOG '0' = USER | '1' = ADMIN
Const USER_TYPE_NORMAL = 0
Const USER_TYPE_ADMIN  = 1

' --- Nombres de las variables de sesion creadas en login.asp ----------------
Const SESSION_KEY_USERNAME = "USERNAME"
Const SESSION_KEY_USERTYPE = "USER_TYPE"
Const SESSION_KEY_PHOTO    = "USER_PHOTO"
Const SESSION_KEY_IDUSER   = "ID_USER"
%>
