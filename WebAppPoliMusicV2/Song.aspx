<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Song.aspx.cs" Inherits="WebAppPoliMusicV2.Song" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml" lang="es">
<head runat="server">
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Song list &middot; PoliMusic</title>
    <style type="text/css">
        :root {
            --bg: #0a0713;
            --panel: #150f24;
            --panel-2: #1b1430;
            --line: rgba(168, 130, 255, .16);
            --text: #f1ecff;
            --muted: #a394c4;
            --purple: #8b5cf6;
            --purple-2: #c084fc;
            --purple-soft: rgba(139, 92, 246, .16);
        }

        * { box-sizing: border-box; }

        html, body { margin: 0; padding: 0; }

        body {
            min-height: 100vh;
            font-family: "Segoe UI", Inter, system-ui, -apple-system, Arial, sans-serif;
            color: var(--text);
            background:
                radial-gradient(900px 420px at 12% -10%, rgba(139, 92, 246, .34), transparent 62%),
                radial-gradient(700px 380px at 92% 0%, rgba(192, 132, 252, .18), transparent 60%),
                linear-gradient(180deg, #120b22 0%, var(--bg) 55%);
            background-attachment: fixed;
            -webkit-font-smoothing: antialiased;
        }

        a { color: inherit; }

        /* ---------------- Top bar ---------------- */
        .topbar {
            position: sticky;
            top: 0;
            z-index: 20;
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 18px;
            padding: 14px 28px;
            background: rgba(10, 7, 19, .82);
            backdrop-filter: blur(14px);
            border-bottom: 1px solid var(--line);
        }

        .brand {
            display: flex;
            align-items: center;
            gap: 11px;
            text-decoration: none;
            font-size: 18px;
            font-weight: 800;
            letter-spacing: .2px;
        }

        .brand__mark {
            display: grid;
            place-items: center;
            width: 34px;
            height: 34px;
            border-radius: 50%;
            background: linear-gradient(145deg, var(--purple-2), var(--purple));
            color: #170a2b;
            font-size: 18px;
            font-weight: 900;
            box-shadow: 0 8px 20px rgba(139, 92, 246, .45);
        }

        .brand__name span { color: var(--purple-2); }

        .topbar__right {
            display: flex;
            align-items: center;
            gap: 14px;
        }

        .userbox {
            display: flex;
            align-items: center;
            gap: 11px;
            padding: 6px 16px 6px 6px;
            border: 1px solid var(--line);
            border-radius: 999px;
            background: rgba(27, 20, 48, .75);
        }

        .userbox__avatar {
            width: 38px;
            height: 38px;
            border-radius: 50%;
            object-fit: cover;
            background: #120b22;
            border: 2px solid rgba(192, 132, 252, .55);
        }

        .userbox__text {
            display: flex;
            flex-direction: column;
            line-height: 1.15;
        }

        .userbox__hello {
            font-size: 10.5px;
            text-transform: uppercase;
            letter-spacing: .14em;
            color: var(--muted);
        }

        .userbox__name {
            font-size: 15px;
            font-weight: 700;
            color: #ffffff;
        }

        .btn-logout {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            padding: 10px 18px;
            border-radius: 999px;
            border: 1px solid rgba(192, 132, 252, .45);
            color: var(--purple-2);
            font-size: 13px;
            font-weight: 700;
            letter-spacing: .04em;
            text-decoration: none;
            transition: background .18s ease, color .18s ease, box-shadow .18s ease, border-color .18s ease;
        }

        .btn-logout:hover {
            background: var(--purple);
            border-color: var(--purple);
            color: #170a2b;
            box-shadow: 0 10px 24px rgba(139, 92, 246, .38);
        }

        .btn-logout svg { width: 15px; height: 15px; }

        /* ---------------- Layout ---------------- */
        .page {
            max-width: 1120px;
            margin: 0 auto;
            padding: 34px 22px 60px;
        }

        .panel {
            background: linear-gradient(180deg, rgba(27, 20, 48, .94), rgba(15, 10, 26, .94));
            border: 1px solid var(--line);
            border-radius: 18px;
            box-shadow: 0 30px 70px rgba(6, 3, 14, .62);
            overflow: hidden;
        }

        .panel__head {
            display: flex;
            flex-wrap: wrap;
            align-items: flex-end;
            justify-content: space-between;
            gap: 12px;
            padding: 26px 26px 20px;
            border-bottom: 1px solid var(--line);
            background:
                radial-gradient(420px 160px at 0% 0%, rgba(139, 92, 246, .26), transparent 70%);
        }

        .panel__head h1 {
            margin: 0;
            font-size: 26px;
            letter-spacing: -.02em;
            font-weight: 800;
        }

        .panel__head h1 em {
            font-style: normal;
            color: var(--purple-2);
        }

        .panel__meta {
            margin: 0;
            font-size: 12.5px;
            color: var(--muted);
        }

        .panel__meta b { color: var(--text); }

        /* ---------------- Table ---------------- */
        .table-wrap {
            width: 100%;
            overflow-x: auto;
        }

        table.songs {
            width: 100%;
            min-width: 780px;
            border-collapse: collapse;
        }

        .songs thead th {
            padding: 14px 22px;
            text-align: left;
            font-size: 10.5px;
            font-weight: 700;
            letter-spacing: .14em;
            text-transform: uppercase;
            color: var(--muted);
            white-space: nowrap;
            background: rgba(13, 9, 24, .70);
            border-bottom: 1px solid var(--line);
        }

        .songs tbody td {
            padding: 16px 22px;
            font-size: 14px;
            vertical-align: middle;
            border-bottom: 1px solid rgba(168, 130, 255, .10);
        }

        .songs tbody tr {
            transition: background .18s ease;
        }

        .songs tbody tr:hover {
            background: rgba(139, 92, 246, .11);
        }

        .songs tbody tr.is-playing {
            background: rgba(139, 92, 246, .18);
        }

        .songs tbody tr:last-child td { border-bottom: 0; }

        .col-id { width: 116px; }

        .id-badge {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            min-width: 38px;
            height: 28px;
            padding: 0 10px;
            border-radius: 9px;
            background: var(--purple-soft);
            border: 1px solid rgba(192, 132, 252, .38);
            color: #d9c4ff;
            font-size: 13px;
            font-weight: 800;
            font-variant-numeric: tabular-nums;
        }

        .song-name {
            font-size: 15px;
            font-weight: 700;
            letter-spacing: .01em;
        }

        .song-path code {
            display: inline-block;
            max-width: 320px;
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
            padding: 4px 9px;
            border-radius: 8px;
            background: rgba(9, 6, 18, .80);
            border: 1px solid rgba(168, 130, 255, .14);
            color: var(--muted);
            font-family: "Cascadia Code", Consolas, "Courier New", monospace;
            font-size: 12.5px;
            vertical-align: middle;
        }

        .col-plays { width: 176px; }

        .plays {
            display: inline-flex;
            align-items: center;
            gap: 7px;
            padding: 5px 12px;
            border-radius: 999px;
            background: rgba(139, 92, 246, .14);
            color: #d5c2ff;
            font-size: 13px;
            font-weight: 700;
        }

        .plays svg { width: 14px; height: 14px; }

        .col-player { width: 330px; }

        .player {
            display: inline-flex;
            align-items: center;
            padding: 4px 10px 4px 6px;
            border-radius: 999px;
            background: #e8e0fb;
            box-shadow: inset 0 0 0 1px rgba(20, 10, 40, .08), 0 8px 18px rgba(6, 3, 14, .38);
        }

        .player audio {
            display: block;
            width: 264px;
            height: 34px;
        }

        .row-empty td {
            padding: 46px 22px;
            text-align: center;
            color: var(--muted);
            font-size: 13.5px;
        }

        /* ---------------- Alert ---------------- */
        .alert {
            display: flex;
            gap: 12px;
            margin: 20px 26px;
            padding: 14px 16px;
            border-radius: 12px;
            background: rgba(255, 86, 86, .10);
            border: 1px solid rgba(255, 86, 86, .35);
            color: #ffc9c9;
            font-size: 13px;
        }

        .alert strong { display: block; margin-bottom: 4px; color: #ffd7d7; }

        .panel__foot {
            display: flex;
            flex-wrap: wrap;
            justify-content: space-between;
            gap: 10px;
            padding: 15px 26px;
            border-top: 1px solid var(--line);
            font-size: 12.5px;
            color: var(--muted);
        }

        .panel__foot code {
            font-family: "Cascadia Code", Consolas, monospace;
            color: #d9c4ff;
        }

        @media (max-width: 640px) {
            .topbar { flex-wrap: wrap; padding: 12px 16px; }
            .userbox__hello { display: none; }
            .page { padding: 20px 12px 40px; }
            .panel__head { padding: 20px 18px 16px; }
            .songs thead th, .songs tbody td { padding: 12px 14px; }
            .player audio { width: 190px; }
            .col-player { width: auto; }
        }
    </style>
</head>
<body>
    <form id="form1" runat="server">

        <!-- ===================== Top bar: user + logout ===================== -->
        <header class="topbar">
            <a class="brand" href="Song.aspx">
                <span class="brand__mark">&#9835;</span>
                <span class="brand__name">Poli<span>Music</span></span>
            </a>

            <div class="topbar__right">
                <div class="userbox" title="Sesión iniciada como <%= H(UserName) %>">
                    <img class="userbox__avatar" src="<%= H(UserPhotoUrl) %>" alt="Foto de <%= H(UserName) %>" />
                    <span class="userbox__text">
                        <span class="userbox__hello">Welcome</span>
                        <strong class="userbox__name"><%= H(UserName) %></strong>
                    </span>
                </div>

                <a class="btn-logout" href="Logout.aspx" title="Cerrar la sesión actual">
                    <svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
                        <path d="M10 3H6a3 3 0 0 0-3 3v12a3 3 0 0 0 3 3h4a1 1 0 1 0 0-2H6a1 1 0 0 1-1-1V6a1 1 0 0 1 1-1h4a1 1 0 1 0 0-2Zm8.7 8.3-3.9-3.9a1 1 0 1 0-1.4 1.4l2.2 2.2H10a1 1 0 1 0 0 2h5.6l-2.2 2.2a1 1 0 0 0 1.4 1.4l3.9-3.9a1 1 0 0 0 0-1.4Z" />
                    </svg>
                    <span>Logout</span>
                </a>
            </div>
        </header>

        <!-- ===================== Song list ===================== -->
        <main class="page">
            <section class="panel">

                <div class="panel__head">
                    <h1>Song <em>list:</em></h1>
                    <p class="panel__meta">
                        <b><%= Songs.Count %></b> canciones &middot;
                        <b><%= TotalPlays %></b> reproducciones &middot; tabla <code>TBL_SONG</code>
                    </p>
                </div>

                <% if (ErrorMessage.Length > 0) { %>
                <div class="alert">
                    <div>
                        <strong>No se pudo cargar el catálogo.</strong>
                        <%= H(ErrorMessage) %>
                    </div>
                </div>
                <% } %>

                <div class="table-wrap">
                    <table class="songs">
                        <thead>
                            <tr>
                                <th class="col-id" scope="col">ID Canción</th>
                                <th scope="col">Nombre</th>
                                <th scope="col">Ruta</th>
                                <th class="col-plays" scope="col">Reproducciones</th>
                                <th class="col-player" scope="col">Reproducir</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% if (Songs.Count == 0) { %>
                            <tr class="row-empty">
                                <td colspan="5">Todavía no hay canciones registradas en el catálogo.</td>
                            </tr>
                            <% } %>
                            <% foreach (WebAppPoliMusicV2.Entities.Song song in Songs) { %>
                            <tr>
                                <td class="col-id">
                                    <span class="id-badge"><%= song.ID %></span>
                                </td>
                                <td>
                                    <span class="song-name"><%= H(song.SongName) %></span>
                                </td>
                                <td class="song-path">
                                    <code title="<%= H(song.SongPath) %>"><%= H(song.SongPath) %></code>
                                </td>
                                <td class="col-plays">
                                    <span class="plays">
                                        <svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
                                            <path d="M12 3a9 9 0 0 0-9 9v5a3 3 0 0 0 3 3h1.5a1.5 1.5 0 0 0 1.5-1.5v-4A1.5 1.5 0 0 0 7.5 13H5v-1a7 7 0 1 1 14 0v1h-2.5a1.5 1.5 0 0 0-1.5 1.5v4A1.5 1.5 0 0 0 16.5 20H18a3 3 0 0 0 3-3v-5a9 9 0 0 0-9-9Z" />
                                        </svg>
                                        <%= song.Plays %>
                                    </span>
                                </td>
                                <td class="col-player">
                                    <div class="player">
                                        <audio class="song-audio" controls="controls" preload="none"
                                            src="<%= H(SongUrl(song.SongPath)) %>">
                                            Tu navegador no soporta el elemento de audio.
                                        </audio>
                                    </div>
                                </td>
                            </tr>
                            <% } %>
                        </tbody>
                    </table>
                </div>

                <div class="panel__foot">
                    <span>Usuario autenticado: <b><%= H(UserName) %></b></span>
                    <span>Base de datos <code>BDD_PoliMusic</code> &middot; <%= Songs.Count %> registros</span>
                </div>
            </section>
        </main>

        <script type="text/javascript">
            // Only one song can be played at a time
            (function () {
                var audios = document.getElementsByTagName("audio");

                /**
                 * Returns the <tr> that contains the given audio element.
                 * @param {HTMLAudioElement} audio
                 * @returns {Element | null}
                 */
                function rowOf(audio) {
                    var node = audio.parentNode;
                    while (node && node.nodeName !== "TR") {
                        node = node.parentNode;
                    }
                    return /** @type {Element | null} */ (node);
                }

                /**
                 * Pause the other players and highlight the current row.
                 * @param {Event} event
                 */
                function onPlay(event) {
                    var audio = /** @type {HTMLAudioElement} */ (event.currentTarget);
                    var all = document.getElementsByTagName("audio");
                    for (var i = 0; i < all.length; i++) {
                        if (all[i] !== audio) {
                            all[i].pause();
                            var otherRow = rowOf(all[i]);
                            if (otherRow) { otherRow.classList.remove("is-playing"); }
                        }
                    }
                    var row = rowOf(audio);
                    if (row) { row.classList.add("is-playing"); }
                }

                /**
                 * Remove the highlight when the song is paused.
                 * @param {Event} event
                 */
                function onPause(event) {
                    var row = rowOf(/** @type {HTMLAudioElement} */ (event.currentTarget));
                    if (row) { row.classList.remove("is-playing"); }
                }

                for (var i = 0; i < audios.length; i++) {
                    if (audios[i].className.indexOf("song-audio") === -1) { continue; }
                    audios[i].addEventListener("play", onPlay, false);
                    audios[i].addEventListener("pause", onPause, false);
                }
            })();
        </script>
    </form>
</body>
</html>
