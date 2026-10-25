<%@ Language="VBScript" CodePage="65001" %>
<% Option Explicit %>
<!--#include file="includes/config.asp"-->
<!--#include file="includes/util.asp"-->
<!--#include file="includes/db.asp"-->
<!--#include file="includes/auth.asp"-->
<%
' ============================================================================
'  PoliMusic - Listado de canciones (vista principal)
' ----------------------------------------------------------------------------
'  - Recupera el usuario logueado desde la sesion creada en login.asp
'  - Aplica el modelo de roles: 0 = lectura / 1 = CRUD completo
'  - Renderiza TBL_SONG con un reproductor HTML5 por fila
' ============================================================================

    Response.Buffer = True
    Response.CodePage = 65001
    Response.Charset = "utf-8"
    Session.CodePage = 65001

    Call LoadSessionContext()
    Call RequireLogin()

    Dim conn, rs, dataRows, rowCount, i
    Dim totalPlays, isAdminUser, roleLabelText, roleSlugText, userPhotoUrl
    Dim rowId, rowName, rowPath, rowPlays, rowSrc, rowAvailable, rowIndexLabel
    Dim covers(5), dbErrorText, coverUrl

    isAdminUser   = IsAdmin()
    roleLabelText = RoleLabel(SESSION_USER_TYPE)
    roleSlugText  = RoleSlug(SESSION_USER_TYPE)

    ' --- Avatar del usuario (con respaldo en la imagen por defecto) ----------
    userPhotoUrl = ResolveResourcePath(SESSION_USER_PHOTO)
    If Len(userPhotoUrl) = 0 Then userPhotoUrl = RESOURCES_ROOT & "/UserImages/default.jpg"

    ' --- Portadas usadas en las filas ---------------------------------------
    covers(0) = RESOURCES_ROOT & "/PlaylistImages/default.jpg"
    For i = 1 To 5
        covers(i) = RESOURCES_ROOT & "/PlaylistImages/playlist" & i & ".png"
    Next

    ' --- Lectura del catalogo ------------------------------------------------
    dbErrorText = ""
    rowCount    = 0
    totalPlays  = 0
    dataRows    = Empty

    Set conn = OpenConnection()
    If conn Is Nothing Then
        dbErrorText = gConnError
    Else
        On Error Resume Next
        Set rs = Server.CreateObject("ADODB.Recordset")
        rs.Open "SELECT ID_SONG, SONG_NAME, SONG_PATH, ISNULL(PLAYS, 0) AS PLAYS " & _
                "FROM dbo.TBL_SONG ORDER BY SONG_NAME ASC", conn, 1, 1
        If Err.Number <> 0 Then
            dbErrorText = Err.Description
            Err.Clear
        End If
        On Error GoTo 0

        If Len(dbErrorText) = 0 Then
            On Error Resume Next
            dataRows = rs.GetRows()
            rowCount = UBound(dataRows, 2) + 1
            If Err.Number <> 0 Then
                rowCount = 0
                Err.Clear
            End If
            On Error GoTo 0
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

    If rowCount > 0 Then
        For i = 0 To rowCount - 1
            totalPlays = totalPlays + ToInt(dataRows(3, i), 0)
        Next
    End If
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Song List &middot; <%=APP_NAME%></title>
    <meta name="description" content="Catalogo de canciones de PoliMusic con reproductor integrado.">
    <link rel="icon" href="<%=RESOURCES_ROOT%>/PlaylistImages/default.jpg">
    <link rel="stylesheet" href="assets/css/polimusic.css">
</head>
<body>

<!-- ====================== SPRITE DE ICONOS ============================== -->
<svg class="svg-sprite" xmlns="http://www.w3.org/2000/svg" aria-hidden="true" focusable="false">
    <symbol id="i-note" viewBox="0 0 24 24">
        <path d="M19 3.5a1 1 0 0 0-1.2-.98l-8 1.7A1 1 0 0 0 9 5.2v9.05A3.6 3.6 0 1 0 11 17.4V8.9l6-1.27v4.62a3.6 3.6 0 1 0 2 3.15V3.5Z"/>
    </symbol>
    <symbol id="i-logout" viewBox="0 0 24 24">
        <path d="M10 3H6a3 3 0 0 0-3 3v12a3 3 0 0 0 3 3h4a1 1 0 1 0 0-2H6a1 1 0 0 1-1-1V6a1 1 0 0 1 1-1h4a1 1 0 1 0 0-2Zm8.7 8.3-3.9-3.9a1 1 0 1 0-1.4 1.4l2.2 2.2H10a1 1 0 1 0 0 2h5.6l-2.2 2.2a1 1 0 0 0 1.4 1.4l3.9-3.9a1 1 0 0 0 0-1.4Z"/>
    </symbol>
    <symbol id="i-search" viewBox="0 0 24 24">
        <path d="M10.5 3a7.5 7.5 0 1 0 4.55 13.46l4.24 4.25a1 1 0 0 0 1.42-1.42l-4.25-4.24A7.5 7.5 0 0 0 10.5 3Zm0 2a5.5 5.5 0 1 1 0 11 5.5 5.5 0 0 1 0-11Z"/>
    </symbol>
    <symbol id="i-plus" viewBox="0 0 24 24">
        <path d="M12 4a1 1 0 0 1 1 1v6h6a1 1 0 1 1 0 2h-6v6a1 1 0 1 1-2 0v-6H5a1 1 0 1 1 0-2h6V5a1 1 0 0 1 1-1Z"/>
    </symbol>
    <symbol id="i-edit" viewBox="0 0 24 24">
        <path d="M15.7 3.3a2.4 2.4 0 0 1 3.4 0l1.6 1.6a2.4 2.4 0 0 1 0 3.4L9.3 19.7l-4.7 1.2a1 1 0 0 1-1.2-1.2l1.2-4.7L15.7 3.3ZM5.8 16.5l-.7 2.5 2.5-.7 9.4-9.4-1.8-1.8-9.4 9.4Z"/>
    </symbol>
    <symbol id="i-trash" viewBox="0 0 24 24">
        <path d="M9 3a1 1 0 0 0-1 1v1H4.5a1 1 0 1 0 0 2H5v12a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V7h.5a1 1 0 1 0 0-2H16V4a1 1 0 0 0-1-1H9Zm0 2h6v1H9V5Zm-2 3h10v12a1 1 0 0 1-1 1H8a1 1 0 0 1-1-1V8Zm3 2a1 1 0 0 1 1 1v7a1 1 0 1 1-2 0v-7a1 1 0 0 1 1-1Zm4 0a1 1 0 0 1 1 1v7a1 1 0 1 1-2 0v-7a1 1 0 0 1 1-1Z"/>
    </symbol>
    <symbol id="i-play" viewBox="0 0 24 24">
        <path d="M8.4 4.6a1 1 0 0 1 1.53-.85l9.2 6.4a1.1 1.1 0 0 1 0 1.7l-9.2 6.4A1 1 0 0 1 8.4 17.4V4.6Z"/>
    </symbol>
    <symbol id="i-pause" viewBox="0 0 24 24">
        <path d="M7 4h3.2a1 1 0 0 1 1 1v14a1 1 0 0 1-1 1H7a1 1 0 0 1-1-1V5a1 1 0 0 1 1-1Zm6.8 0H17a1 1 0 0 1 1 1v14a1 1 0 0 1-1 1h-3.2a1 1 0 0 1-1-1V5a1 1 0 0 1 1-1Z"/>
    </symbol>
    <symbol id="i-headphones" viewBox="0 0 24 24">
        <path d="M12 3a9 9 0 0 0-9 9v5a3 3 0 0 0 3 3h1.5a1.5 1.5 0 0 0 1.5-1.5v-4A1.5 1.5 0 0 0 7.5 13H5v-1a7 7 0 1 1 14 0v1h-2.5a1.5 1.5 0 0 0-1.5 1.5v4A1.5 1.5 0 0 0 16.5 20H18a3 3 0 0 0 3-3v-5a9 9 0 0 0-9-9Z"/>
    </symbol>
    <symbol id="i-shield" viewBox="0 0 24 24">
        <path d="M12 2.2 4.8 5.1a1 1 0 0 0-.63.93v5.4c0 4.4 2.94 8.4 7.1 9.7a1 1 0 0 0 .58 0c4.16-1.3 7.1-5.3 7.1-9.7v-5.4a1 1 0 0 0-.63-.93L12 2.2Zm0 2.1 5.2 2.1v5c0 3.4-2.1 6.6-5.2 7.8-3.1-1.2-5.2-4.4-5.2-7.8v-5L12 4.3Z"/>
    </symbol>
    <symbol id="i-eye" viewBox="0 0 24 24">
        <path d="M12 4.5c-4.9 0-8.8 3.4-10.7 6.7a1.7 1.7 0 0 0 0 1.6C3.2 16.1 7.1 19.5 12 19.5s8.8-3.4 10.7-6.7a1.7 1.7 0 0 0 0-1.6C20.8 7.9 16.9 4.5 12 4.5Zm0 2c3.6 0 6.7 2.4 8.4 5.5-1.7 3.1-4.8 5.5-8.4 5.5S5.3 15.1 3.6 12C5.3 8.9 8.4 6.5 12 6.5Zm0 1.6a3.9 3.9 0 1 0 0 7.8 3.9 3.9 0 0 0 0-7.8Zm0 2a1.9 1.9 0 1 1 0 3.8 1.9 1.9 0 0 1 0-3.8Z"/>
    </symbol>
    <symbol id="i-alert" viewBox="0 0 24 24">
        <path d="M12 3.2c.7 0 1.3.37 1.65.98l8.1 14.2A1.9 1.9 0 0 1 20.1 21H3.9a1.9 1.9 0 0 1-1.65-2.82l8.1-14.2c.35-.6.95-.98 1.65-.98Zm0 2.6L4.7 19h14.6L12 5.8Zm0 3.4a1 1 0 0 1 1 1v4a1 1 0 1 1-2 0v-4a1 1 0 0 1 1-1Zm0 7a1.2 1.2 0 1 1 0 2.4 1.2 1.2 0 0 1 0-2.4Z"/>
    </symbol>
    <symbol id="i-close" viewBox="0 0 24 24">
        <path d="M6.3 4.9 12 10.6l5.7-5.7a1 1 0 1 1 1.4 1.4L13.4 12l5.7 5.7a1 1 0 0 1-1.4 1.4L12 13.4l-5.7 5.7a1 1 0 0 1-1.4-1.4L10.6 12 4.9 6.3a1 1 0 0 1 1.4-1.4Z"/>
    </symbol>
</svg>

<!-- ====================== BARRA SUPERIOR ================================ -->
<header class="topbar">
    <div class="topbar__inner">
        <a class="brand" href="songList.asp">
            <span class="brand__mark"><svg class="ico"><use href="#i-note"></use></svg></span>
            <span class="brand__name">Poli<span>Music</span></span>
        </a>

        <div class="topbar__right">
            <div class="userbox" title="Sesion iniciada como <%=H(SESSION_USERNAME)%>">
                <img class="userbox__avatar" src="<%=H(userPhotoUrl)%>" alt="Foto de <%=H(SESSION_USERNAME)%>">
                <span class="userbox__text">
                    <span class="userbox__hello">Bienvenido,</span>
                    <strong class="userbox__name"><%=H(SESSION_USERNAME)%></strong>
                </span>
                <span class="role-chip role-chip--<%=roleSlugText%>">
                    <svg class="ico"><use href="#i-<%=RoleIcon(isAdminUser)%>"></use></svg>
                    <%=H(roleLabelText)%>
                </span>
            </div>

            <a class="btn btn--ghost" href="logout.asp" title="Cerrar la sesion actual">
                <svg class="ico"><use href="#i-logout"></use></svg>
                <span>Cerrar sesion</span>
            </a>
        </div>
    </div>
</header>

<main class="page">

    <!-- ====================== HERO / ENCABEZADO ========================= -->
    <section class="hero">
        <div class="hero__body">
            <p class="hero__eyebrow">
                <span class="dot"></span> <%=APP_SUBTITLE%>
            </p>
            <h1 class="hero__title">Song List</h1>
            <p class="hero__lead">
                Explora el catalogo completo, reproduce tus pistas favoritas y
                <% If isAdminUser Then %>
                    administra el repertorio desde un solo lugar.
                <% Else %>
                    descubre nueva musica cada dia.
                <% End If %>
            </p>

            <div class="hero__stats">
                <div class="stat">
                    <span class="stat__value" id="statSongs"><%=FormatIntEs(rowCount)%></span>
                    <span class="stat__label">Canciones</span>
                </div>
                <div class="stat">
                    <span class="stat__value" id="statPlays"><%=FormatIntEs(totalPlays)%></span>
                    <span class="stat__label">Reproducciones</span>
                </div>
                <div class="stat">
                    <span class="stat__value stat__value--sm"><%=H(roleLabelText)%></span>
                    <span class="stat__label">Tu acceso</span>
                </div>
            </div>
        </div>

        <div class="hero__art" aria-hidden="true">
            <div class="eq">
                <span></span><span></span><span></span><span></span><span></span><span></span>
                <span></span><span></span><span></span><span></span><span></span><span></span>
                <span></span><span></span><span></span><span></span><span></span><span></span>
            </div>
            <div class="hero__vinyl">
                <span class="hero__vinyl-core"></span>
            </div>
        </div>
    </section>

    <!-- ====================== PANEL DE LA TABLA ========================= -->
    <section class="panel">

        <div class="panel__head">
            <div class="panel__title">
                <h2>Catalogo de canciones</h2>
                <p>
                    <% If isAdminUser Then %>
                        Tienes permisos de administrador: puedes crear, editar y eliminar registros.
                    <% Else %>
                        Modo lectura: puedes reproducir cualquier pista del catalogo.
                    <% End If %>
                </p>
            </div>

            <div class="panel__tools">
                <label class="search" for="searchInput">
                    <svg class="ico search__ico"><use href="#i-search"></use></svg>
                    <input id="searchInput" type="search" placeholder="Buscar por nombre..." autocomplete="off">
                    <button class="search__clear" type="button" id="searchClear" aria-label="Limpiar busqueda" hidden>
                        <svg class="ico"><use href="#i-close"></use></svg>
                    </button>
                </label>

                <% If isAdminUser Then %>
                <button class="btn btn--primary" type="button" id="btnNewSong">
                    <svg class="ico"><use href="#i-plus"></use></svg>
                    <span>Nueva cancion</span>
                </button>
                <% End If %>
            </div>
        </div>

        <% If Len(dbErrorText) > 0 Then %>
        <div class="alert alert--error">
            <svg class="ico"><use href="#i-alert"></use></svg>
            <div>
                <strong>No se pudo cargar el catalogo.</strong>
                <p><%=H(dbErrorText)%></p>
                <p class="alert__hint">
                    Verifica que el servicio de SQL Server este activo, que la base
                    <code>BDD_PoliMusic</code> exista y que las credenciales de
                    <code>includes/config.asp</code> sean correctas.
                </p>
            </div>
        </div>
        <% Else %>

        <div class="table-wrap">
            <table class="songs" id="songsTable">
                <thead>
                    <tr>
                        <th class="col-index" scope="col">#</th>
                        <th class="col-song" scope="col">Cancion</th>
                        <th class="col-plays" scope="col">
                            <svg class="ico"><use href="#i-headphones"></use></svg> Reproducciones
                        </th>
                        <th class="col-player" scope="col">Reproductor</th>
                        <% If isAdminUser Then %>
                        <th class="col-actions" scope="col">Acciones</th>
                        <% End If %>
                    </tr>
                </thead>
                <tbody>
                <%
                    For i = 0 To rowCount - 1
                        rowId      = ToInt(dataRows(0, i), 0)
                        rowName    = CStr(dataRows(1, i) & "")
                        rowPath    = CStr(dataRows(2, i) & "")
                        rowPlays   = ToInt(dataRows(3, i), 0)
                        rowSrc     = ResolveResourcePath(rowPath)
                        rowAvailable = ResourceFileExists(rowPath)
                        rowIndexLabel = Right("0" & CStr(i + 1), 2)
                        coverUrl   = covers((i Mod 5) + 1)
                %>
                    <tr class="song-row" data-id="<%=rowId%>" data-name="<%=H(LCase(rowName))%>"
                        data-path="<%=H(LCase(rowPath))%>"
                        data-plays="<%=rowPlays%>" style="--i:<%=i%>">
                        <td class="col-index"><span class="index"><%=rowIndexLabel%></span></td>

                        <td class="col-song">
                            <div class="song">
                                <span class="song__cover">
                                    <img src="<%=H(coverUrl)%>" alt="" loading="lazy">
                                </span>
                                <span class="song__body">
                                    <span class="song__name"><%=H(rowName)%></span>
                                    <span class="song__meta">ID #<%=rowId%> &middot; <%=H(rowPath)%></span>
                                </span>
                            </div>
                        </td>

                        <td class="col-plays">
                            <span class="plays" data-plays-cell>
                                <svg class="ico"><use href="#i-headphones"></use></svg>
                                <b><%=FormatIntEs(rowPlays)%></b>
                            </span>
                        </td>

                        <td class="col-player">
                            <% If rowAvailable Then %>
                            <div class="player" data-player>
                                <button class="player__btn" type="button" data-play
                                        aria-label="Reproducir <%=H(rowName)%>">
                                    <svg class="ico ico--play"><use href="#i-play"></use></svg>
                                    <svg class="ico ico--pause"><use href="#i-pause"></use></svg>
                                </button>
                                <span class="player__rail" data-rail role="slider" tabindex="0"
                                      aria-label="Progreso de <%=H(rowName)%>"
                                      aria-valuemin="0" aria-valuemax="100" aria-valuenow="0">
                                    <span class="player__fill" data-fill></span>
                                </span>
                                <span class="player__time" data-time>0:00</span>
                                <audio preload="none" src="<%=H(rowSrc)%>" data-audio></audio>
                            </div>
                            <% Else %>
                            <div class="player player--off" title="El archivo no existe en la carpeta de recursos">
                                <span class="player__off-badge">
                                    <svg class="ico"><use href="#i-alert"></use></svg> Sin archivo
                                </span>
                                <code class="player__off-path"><%=H(rowPath)%></code>
                            </div>
                            <% End If %>
                        </td>

                        <% If isAdminUser Then %>
                        <td class="col-actions">
                            <div class="row-actions">
                                <button class="icon-btn" type="button" data-edit
                                        data-id="<%=rowId%>"
                                        data-song-name="<%=H(rowName)%>"
                                        data-song-path="<%=H(rowPath)%>"
                                        data-song-plays="<%=rowPlays%>"
                                        aria-label="Editar <%=H(rowName)%>" title="Editar">
                                    <svg class="ico"><use href="#i-edit"></use></svg>
                                </button>
                                <button class="icon-btn icon-btn--danger" type="button" data-delete
                                        data-id="<%=rowId%>"
                                        data-song-name="<%=H(rowName)%>"
                                        aria-label="Eliminar <%=H(rowName)%>" title="Eliminar">
                                    <svg class="ico"><use href="#i-trash"></use></svg>
                                </button>
                            </div>
                        </td>
                        <% End If %>
                    </tr>
                <% Next %>
                </tbody>
            </table>

            <div class="empty" id="emptyState" <% If rowCount > 0 Then %>hidden<% End If %>>
                <div class="empty__art"><svg class="ico"><use href="#i-note"></use></svg></div>
                <h3>El catalogo esta vacio</h3>
                <p>
                    <% If isAdminUser Then %>
                        Agrega la primera cancion con el boton <strong>Nueva cancion</strong>.
                    <% Else %>
                        Todavia no hay canciones registradas. Vuelve mas tarde.
                    <% End If %>
                </p>
            </div>

            <div class="empty" id="noResults" hidden>
                <div class="empty__art"><svg class="ico"><use href="#i-search"></use></svg></div>
                <h3>Sin coincidencias</h3>
                <p>No encontramos canciones que coincidan con tu busqueda.</p>
            </div>
        </div>

        <div class="panel__foot">
            <span id="resultCount">Mostrando <%=FormatIntEs(rowCount)%> canciones</span>
            <span class="panel__foot-right">
                <% If isAdminUser Then %>
                    <svg class="ico"><use href="#i-shield"></use></svg> Acceso administrador
                <% Else %>
                    <svg class="ico"><use href="#i-eye"></use></svg> Acceso de solo lectura
                <% End If %>
            </span>
        </div>
        <% End If %>
    </section>

    <footer class="site-foot">
        <span><%=APP_NAME%> v<%=APP_VERSION%> &middot; Base de datos <code>BDD_PoliMusic</code></span>
        <span>Tabla <code>TBL_SONG</code> &middot; <%=FormatIntEs(rowCount)%> registros</span>
    </footer>
</main>

<!-- ====================== DOCK "REPRODUCIENDO AHORA" ==================== -->
<div class="dock" id="dock" hidden>
    <img class="dock__cover" id="dockCover" src="<%=RESOURCES_ROOT%>/PlaylistImages/default.jpg" alt="">
    <div class="dock__info">
        <span class="dock__name" id="dockName">&mdash;</span>
        <span class="dock__sub" id="dockSub">Reproduciendo ahora</span>
    </div>
    <div class="dock__rail"><span class="dock__fill" id="dockFill"></span></div>
    <button class="dock__btn" type="button" id="dockToggle" aria-label="Pausar">
        <svg class="ico ico--play"><use href="#i-play"></use></svg>
        <svg class="ico ico--pause"><use href="#i-pause"></use></svg>
    </button>
</div>

<!-- ====================== MODAL CREAR / EDITAR ========================= -->
<% If isAdminUser Then %>
<div class="modal" id="songModal" hidden aria-hidden="true" role="dialog" aria-modal="true"
     aria-labelledby="songModalTitle">
    <div class="modal__backdrop" data-close-modal></div>
    <div class="modal__card" role="document">
        <header class="modal__head">
            <div>
                <p class="modal__eyebrow" id="songModalEyebrow">Catalogo</p>
                <h2 id="songModalTitle">Nueva cancion</h2>
            </div>
            <button class="icon-btn" type="button" data-close-modal aria-label="Cerrar">
                <svg class="ico"><use href="#i-close"></use></svg>
            </button>
        </header>

        <form class="form" id="songForm" novalidate>
            <input type="hidden" name="id" id="fieldId" value="">

            <div class="field">
                <label for="fieldName">Nombre de la cancion</label>
                <input id="fieldName" name="song_name" type="text" maxlength="50"
                       placeholder="Ej. Adventure" required>
                <span class="field__hint">Maximo 50 caracteres (SONG_NAME).</span>
            </div>

            <div class="field">
                <label for="fieldPath">Ruta del archivo de audio</label>
                <input id="fieldPath" name="song_path" type="text" maxlength="255"
                       placeholder="~/songFiles/bensound-adventure.mp3" required>
                <span class="field__hint">
                    Usa la ruta logica <code>~/songFiles/archivo.mp3</code>. El sistema la resuelve
                    dentro de <code>SongFilesAndImages_resources</code>.
                </span>
            </div>

            <div class="field">
                <label for="fieldPlays">Reproducciones iniciales</label>
                <input id="fieldPlays" name="plays" type="number" min="0" step="1" value="0">
                <span class="field__hint">Columna PLAYS de TBL_SONG.</span>
            </div>

            <p class="form__error" id="formError" hidden></p>

            <footer class="modal__foot">
                <button class="btn btn--ghost" type="button" data-close-modal>Cancelar</button>
                <button class="btn btn--primary" type="submit" id="songSubmit">Guardar cancion</button>
            </footer>
        </form>
    </div>
</div>

<!-- ====================== MODAL ELIMINAR =============================== -->
<div class="modal" id="deleteModal" hidden aria-hidden="true" role="dialog" aria-modal="true"
     aria-labelledby="deleteModalTitle">
    <div class="modal__backdrop" data-close-modal></div>
    <div class="modal__card modal__card--sm" role="document">
        <header class="modal__head">
            <div>
                <p class="modal__eyebrow">Confirmacion</p>
                <h2 id="deleteModalTitle">Eliminar cancion</h2>
            </div>
            <button class="icon-btn" type="button" data-close-modal aria-label="Cerrar">
                <svg class="ico"><use href="#i-close"></use></svg>
            </button>
        </header>

        <div class="modal__body">
            <p>
                Vas a eliminar <strong id="deleteSongName">&mdash;</strong> del catalogo.
                Esta accion tambien la quitara de los albumes y playlists asociados.
            </p>
            <p class="modal__warn">Esta operacion no se puede deshacer.</p>
        </div>

        <footer class="modal__foot">
            <button class="btn btn--ghost" type="button" data-close-modal>Cancelar</button>
            <button class="btn btn--danger" type="button" id="confirmDelete">Si, eliminar</button>
        </footer>
    </div>
</div>
<% End If %>

<div class="toasts" id="toasts" aria-live="polite" aria-atomic="true"></div>

<script src="assets/js/songlist.js"></script>
</body>
</html>
