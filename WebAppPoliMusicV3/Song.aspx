<%@ Page Title="Canciones" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Song.aspx.cs" Inherits="WebAppPoliMusicV3.Song" %>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">

    <main class="songs-page">

        <header class="songs-hero">
            <div>
                <p class="songs-eyebrow">Catálogo</p>
                <h1>Canciones</h1>
                <p class="songs-sub">
                    Archivos MP3 servidos desde <code>~/SongFiles</code> &middot; tabla <code>TBL_SONG</code>
                </p>
            </div>
            <div class="songs-stats">
                <span class="songs-stat">
                    <b><asp:Literal ID="litTotalSongs" runat="server" /></b> canciones
                </span>
                <span class="songs-stat">
                    <b><asp:Literal ID="litTotalPlays" runat="server" /></b> reproducciones
                </span>
            </div>
        </header>

        <asp:Panel ID="pnlError" runat="server" Visible="false" CssClass="alert alert-danger songs-alert" role="alert">
            <strong>No se pudo cargar el catálogo.</strong>
            <asp:Literal ID="litError" runat="server" />
        </asp:Panel>

        <div class="songs-card">
            <div class="table-responsive">
                <asp:GridView ID="gvSongs" runat="server"
                    AutoGenerateColumns="false"
                    DataKeyNames="ID"
                    CssClass="table songs-table align-middle"
                    GridLines="None"
                    UseAccessibleHeader="true"
                    EmptyDataText="Todavía no hay canciones registradas en el catálogo."
                    EmptyDataRowStyle-CssClass="songs-empty"
                    OnRowDataBound="gvSongs_RowDataBound">
                    <Columns>

                        <asp:TemplateField HeaderText="ID" ItemStyle-CssClass="col-id" HeaderStyle-CssClass="col-id">
                            <ItemTemplate>
                                <span class="song-id"><%# Eval("ID") %></span>
                            </ItemTemplate>
                        </asp:TemplateField>

                        <asp:TemplateField HeaderText="Nombre" ItemStyle-CssClass="col-name">
                            <ItemTemplate>
                                <span class="song-name"><%#: Eval("SongName") %></span>
                            </ItemTemplate>
                        </asp:TemplateField>

                        <asp:TemplateField HeaderText="Ruta" ItemStyle-CssClass="col-path">
                            <ItemTemplate>
                                <code class="song-path" title='<%#: Eval("SongPath") %>'><%#: Eval("SongPath") %></code>
                            </ItemTemplate>
                        </asp:TemplateField>

                        <asp:TemplateField HeaderText="Reproducciones" ItemStyle-CssClass="col-plays" HeaderStyle-CssClass="col-plays">
                            <ItemTemplate>
                                <span class="song-plays">
                                    <svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
                                        <path d="M12 3a9 9 0 0 0-9 9v5a3 3 0 0 0 3 3h1.5a1.5 1.5 0 0 0 1.5-1.5v-4A1.5 1.5 0 0 0 7.5 13H5v-1a7 7 0 1 1 14 0v1h-2.5a1.5 1.5 0 0 0-1.5 1.5v4A1.5 1.5 0 0 0 16.5 20H18a3 3 0 0 0 3-3v-5a9 9 0 0 0-9-9Z" />
                                    </svg>
                                    <%# Eval("Plays") %>
                                </span>
                            </ItemTemplate>
                        </asp:TemplateField>

                        <asp:TemplateField HeaderText="Reproducir" ItemStyle-CssClass="col-player" HeaderStyle-CssClass="col-player">
                            <ItemTemplate>
                                <asp:PlaceHolder ID="phPlayer" runat="server" Visible='<%# SongFileExists(Eval("SongPath")) %>'>
                                    <audio class="song-audio" controls="controls" preload="metadata"
                                        src='<%#: SongUrl(Eval("SongPath")) %>'>
                                        Tu navegador no soporta el elemento de audio.
                                    </audio>
                                </asp:PlaceHolder>
                                <asp:PlaceHolder ID="phNoFile" runat="server" Visible='<%# !SongFileExists(Eval("SongPath")) %>'>
                                    <span class="song-nofile">Sin archivo</span>
                                </asp:PlaceHolder>
                            </ItemTemplate>
                        </asp:TemplateField>

                    </Columns>
                </asp:GridView>
            </div>
        </div>

        <p class="songs-foot">
            Sesión iniciada como <b><asp:Literal ID="litCurrentUser" runat="server" /></b>
            &middot; base de datos <code>BDD_PoliMusic</code>
        </p>

    </main>

    <script type="text/javascript">
        // Reproduce una sola canción a la vez y resalta la fila en reproducción.
        (function () {
            function rowOf(audio) {
                var node = audio.parentNode;
                while (node && node.nodeName !== "TR") {
                    node = node.parentNode;
                }
                return node;
            }

            function init() {
                var audios = document.querySelectorAll("audio.song-audio");
                for (var i = 0; i < audios.length; i++) {
                    (function (audio) {
                        audio.addEventListener("play", function () {
                            for (var j = 0; j < audios.length; j++) {
                                if (audios[j] !== audio) {
                                    audios[j].pause();
                                    var otherRow = rowOf(audios[j]);
                                    if (otherRow) { otherRow.classList.remove("is-playing"); }
                                }
                            }
                            var row = rowOf(audio);
                            if (row) { row.classList.add("is-playing"); }
                        }, false);

                        audio.addEventListener("pause", function () {
                            var row = rowOf(audio);
                            if (row) { row.classList.remove("is-playing"); }
                        }, false);

                        // Si el navegador no puede cargar el archivo, se marca el reproductor.
                        audio.addEventListener("error", function () {
                            audio.classList.add("is-error");
                            audio.title = "No se pudo cargar el audio: " + (audio.getAttribute("src") || "(sin src)");
                        }, false);
                    })(audios[i]);
                }
            }

            if (document.readyState === "loading") {
                document.addEventListener("DOMContentLoaded", init, false);
            } else {
                init();
            }
        })();
    </script>

</asp:Content>
