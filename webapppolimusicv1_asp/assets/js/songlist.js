/* ==========================================================================
   PoliMusic - Logica de la vista Song List
   --------------------------------------------------------------------------
   Responsabilidades:
     1. Reproductor HTML5 por fila (play / pausa / progreso / seek / auto-next)
     2. Registro de reproducciones contra songActions.asp
     3. Busqueda en vivo sobre la tabla
     4. CRUD (solo administradores) mediante fetch + modales
   ========================================================================== */
(function () {
    'use strict';

    var ENDPOINT = 'songActions.asp';

    /* ---------------------------------------------------------------- Utils */
    function $(selector, scope) { return (scope || document).querySelector(selector); }
    function $$(selector, scope) {
        return Array.prototype.slice.call((scope || document).querySelectorAll(selector));
    }

    function formatTime(seconds) {
        if (!isFinite(seconds) || seconds < 0) { return '0:00'; }
        var total = Math.floor(seconds);
        var min = Math.floor(total / 60);
        var sec = total % 60;
        return min + ':' + (sec < 10 ? '0' : '') + sec;
    }

    function formatNumber(value) {
        try { return Number(value).toLocaleString('es-EC'); }
        catch (err) { return String(value); }
    }

    function normalize(text) {
        var value = String(text || '');
        if (value.normalize) {
            value = value.normalize('NFD').replace(/[\u0300-\u036f]/g, '');
        }
        return value.toLowerCase().trim();
    }

    /* --------------------------------------------------------------- Toasts */
    var toastHost = $('#toasts');

    function toast(message, kind) {
        if (!toastHost || !message) { return; }
        var icons = { ok: 'i-headphones', error: 'i-alert', info: 'i-note' };
        var el = document.createElement('div');
        el.className = 'toast toast--' + (kind || 'info');
        el.innerHTML =
            '<svg class="ico"><use href="#' + (icons[kind] || icons.info) + '"></use></svg>' +
            '<span></span>';
        el.querySelector('span').textContent = message;
        toastHost.appendChild(el);

        window.setTimeout(function () {
            el.classList.add('is-out');
            window.setTimeout(function () {
                if (el.parentNode) { el.parentNode.removeChild(el); }
            }, 260);
        }, 3600);
    }

    /* -------------------------------------------------------------- Peticion */
    function post(action, payload) {
        var body = new URLSearchParams();
        body.append('action', action);
        Object.keys(payload || {}).forEach(function (key) {
            body.append(key, payload[key]);
        });

        return fetch(ENDPOINT, {
            method: 'POST',
            credentials: 'same-origin',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8' },
            body: body.toString()
        }).then(function (response) {
            return response.json().catch(function () {
                return { ok: false, message: 'Respuesta inesperada del servidor.' };
            });
        });
    }

    /* ==================================================================== */
    /*  1. REPRODUCTOR                                                       */
    /* ==================================================================== */
    var players = [];
    var activePlayer = null;

    var dock = $('#dock');
    var dockCover = $('#dockCover');
    var dockName = $('#dockName');
    var dockSub = $('#dockSub');
    var dockFill = $('#dockFill');
    var dockToggle = $('#dockToggle');

    var statPlaysEl = $('#statPlays');
    var totalPlays = statPlaysEl ? parseInt(statPlaysEl.textContent.replace(/\D/g, ''), 10) || 0 : 0;

    function buildPlayer(root) {
        var audio = $('[data-audio]', root);
        if (!audio) { return null; }

        var player = {
            root: root,
            audio: audio,
            row: root.closest('.song-row'),
            btn: $('[data-play]', root),
            rail: $('[data-rail]', root),
            fill: $('[data-fill]', root),
            time: $('[data-time]', root),
            counted: false
        };

        player.btn.addEventListener('click', function () { toggle(player); });

        audio.addEventListener('play', function () {
            players.forEach(function (other) {
                if (other !== player && !other.audio.paused) { other.audio.pause(); }
            });
            root.classList.add('is-playing');
            player.row.classList.add('is-playing');
            activePlayer = player;
            openDock(player);
            registerPlay(player);
        });

        audio.addEventListener('pause', function () {
            root.classList.remove('is-playing');
            player.row.classList.remove('is-playing');
            if (activePlayer === player) {
                dock.classList.add('is-paused');
                dockSub.textContent = 'En pausa';
            }
        });

        audio.addEventListener('timeupdate', function () { renderProgress(player); });
        audio.addEventListener('loadedmetadata', function () { renderProgress(player); });

        audio.addEventListener('ended', function () {
            root.classList.remove('is-playing');
            player.row.classList.remove('is-playing');
            renderProgress(player);
            playNext(player);
        });

        audio.addEventListener('error', function () {
            root.classList.remove('is-playing');
            player.row.classList.remove('is-playing');
            toast('No se pudo reproducir "' + songName(player) + '". Revisa el archivo de audio.', 'error');
        });

        player.rail.addEventListener('click', function (event) {
            seek(player, event);
        });

        player.rail.addEventListener('keydown', function (event) {
            if (!isFinite(player.audio.duration)) { return; }
            if (event.key === 'ArrowRight') {
                event.preventDefault();
                player.audio.currentTime = Math.min(player.audio.duration, player.audio.currentTime + 5);
            } else if (event.key === 'ArrowLeft') {
                event.preventDefault();
                player.audio.currentTime = Math.max(0, player.audio.currentTime - 5);
            }
        });

        return player;
    }

    function songName(player) {
        var node = $('.song__name', player.row);
        return node ? node.textContent.trim() : 'esta cancion';
    }

    function renderProgress(player) {
        var audio = player.audio;
        var duration = audio.duration;
        var ratio = (isFinite(duration) && duration > 0) ? (audio.currentTime / duration) : 0;
        var percent = Math.max(0, Math.min(100, ratio * 100));

        player.fill.style.width = percent + '%';
        player.time.textContent = formatTime(audio.currentTime);
        player.rail.setAttribute('aria-valuenow', String(Math.round(percent)));

        if (activePlayer === player) {
            dockFill.style.width = percent + '%';
        }
    }

    function seek(player, event) {
        var rect = player.rail.getBoundingClientRect();
        if (!rect.width) { return; }
        var ratio = Math.max(0, Math.min(1, (event.clientX - rect.left) / rect.width));

        if (!isFinite(player.audio.duration)) {
            // Aun sin metadatos: forzamos la carga y reintentamos al estar listo.
            player.audio.load();
            player.audio.addEventListener('loadedmetadata', function once() {
                player.audio.removeEventListener('loadedmetadata', once);
                player.audio.currentTime = ratio * player.audio.duration;
            });
            return;
        }
        player.audio.currentTime = ratio * player.audio.duration;
    }

    function toggle(player) {
        if (player.audio.paused) {
            var attempt = player.audio.play();
            if (attempt && typeof attempt.catch === 'function') {
                attempt.catch(function () { /* el evento 'error' ya notifica al usuario */ });
            }
        } else {
            player.audio.pause();
        }
    }

    function playNext(player) {
        var index = players.indexOf(player);
        for (var i = index + 1; i < players.length; i += 1) {
            if (players[i].audio.getAttribute('src')) {
                var attempt = players[i].audio.play();
                if (attempt && typeof attempt.catch === 'function') {
                    attempt.catch(function () { /* silencioso */ });
                }
                return;
            }
        }
    }

    function openDock(player) {
        if (!dock) { return; }
        var cover = $('.song__cover img', player.row);
        if (cover && dockCover) { dockCover.src = cover.src; }
        if (dockName) { dockName.textContent = songName(player); }
        if (dockSub) { dockSub.textContent = 'Reproduciendo ahora'; }
        dock.classList.remove('is-paused');
        dock.hidden = false;
        window.requestAnimationFrame(function () { dock.classList.add('is-open'); });
    }

    if (dockToggle) {
        dockToggle.addEventListener('click', function () {
            if (activePlayer) { toggle(activePlayer); }
        });
    }

    /* --- Incremento de PLAYS (una vez por cancion y por carga) ----------- */
    function registerPlay(player) {
        if (player.counted) { return; }
        player.counted = true;

        var id = player.row.dataset.id;
        if (!id) { return; }

        post('play', { id: id }).then(function (result) {
            if (!result || !result.ok) { return; }

            var current = parseInt(player.row.dataset.plays, 10) || 0;
            var next = (result.data && result.data.plays >= 0) ? result.data.plays : current + 1;

            player.row.dataset.plays = String(next);
            var cell = $('[data-plays-cell] b', player.row);
            if (cell) { cell.textContent = formatNumber(next); }

            totalPlays += (next - current);
            if (statPlaysEl) { statPlaysEl.textContent = formatNumber(totalPlays); }
        }).catch(function () { /* el contador no debe romper la reproduccion */ });
    }

    $$('[data-player]').forEach(function (root) {
        var player = buildPlayer(root);
        if (player) { players.push(player); }
    });

    /* ==================================================================== */
    /*  2. BUSQUEDA                                                          */
    /* ==================================================================== */
    var searchInput = $('#searchInput');
    var searchClear = $('#searchClear');
    var rows = $$('.song-row');
    var noResults = $('#noResults');
    var resultCount = $('#resultCount');

    function applyFilter() {
        if (!searchInput) { return; }

        var term = normalize(searchInput.value);
        var visible = 0;

        rows.forEach(function (row) {
            var haystack = normalize(row.dataset.name + ' ' + (row.dataset.path || ''));
            var match = term === '' || haystack.indexOf(term) !== -1;
            row.hidden = !match;
            if (match) { visible += 1; }
        });

        if (noResults) { noResults.hidden = !(visible === 0 && rows.length > 0); }
        if (resultCount) {
            resultCount.textContent = term === ''
                ? 'Mostrando ' + formatNumber(rows.length) + ' canciones'
                : visible + ' de ' + rows.length + ' canciones coinciden';
        }
        if (searchClear) { searchClear.hidden = term === ''; }
    }

    if (searchInput) {
        searchInput.addEventListener('input', applyFilter);
        searchInput.addEventListener('search', applyFilter);
    }
    if (searchClear) {
        searchClear.addEventListener('click', function () {
            searchInput.value = '';
            applyFilter();
            searchInput.focus();
        });
    }

    /* ==================================================================== */
    /*  3. MODALES                                                           */
    /* ==================================================================== */
    var songModal = $('#songModal');
    var deleteModal = $('#deleteModal');

    function openModal(modal) {
        if (!modal) { return; }
        modal.hidden = false;
        modal.setAttribute('aria-hidden', 'false');
        document.body.style.overflow = 'hidden';

        var focusable = modal.querySelector('input:not([type="hidden"]), button');
        if (focusable) { window.setTimeout(function () { focusable.focus(); }, 60); }
    }

    function closeModal(modal) {
        if (!modal) { return; }
        modal.hidden = true;
        modal.setAttribute('aria-hidden', 'true');
        document.body.style.overflow = '';
    }

    $$('[data-close-modal]').forEach(function (node) {
        node.addEventListener('click', function () {
            closeModal(node.closest('.modal'));
        });
    });

    document.addEventListener('keydown', function (event) {
        if (event.key !== 'Escape') { return; }
        $$('.modal').forEach(function (modal) {
            if (!modal.hidden) { closeModal(modal); }
        });
    });

    /* ==================================================================== */
    /*  4. CRUD (solo administradores)                                       */
    /* ==================================================================== */
    var songForm = $('#songForm');
    var formError = $('#formError');

    if (songForm) {
        var fieldId = $('#fieldId');
        var fieldName = $('#fieldName');
        var fieldPath = $('#fieldPath');
        var fieldPlays = $('#fieldPlays');
        var modalTitle = $('#songModalTitle');
        var modalEyebrow = $('#songModalEyebrow');
        var submitBtn = $('#songSubmit');
        var btnNewSong = $('#btnNewSong');

        function resetForm() {
            songForm.reset();
            fieldId.value = '';
            fieldPlays.value = '0';
            formError.hidden = true;
            fieldName.classList.remove('is-invalid');
            fieldPath.classList.remove('is-invalid');
        }

        function setBusy(busy) {
            if (!submitBtn) { return; }
            submitBtn.disabled = busy;
            submitBtn.textContent = busy ? 'Guardando...' : (fieldId.value ? 'Guardar cambios' : 'Guardar cancion');
        }

        function showFormError(message) {
            formError.textContent = message;
            formError.hidden = false;
        }

        if (btnNewSong) {
            btnNewSong.addEventListener('click', function () {
                resetForm();
                modalTitle.textContent = 'Nueva cancion';
                modalEyebrow.textContent = 'Catalogo';
                submitBtn.textContent = 'Guardar cancion';
                openModal(songModal);
            });
        }

        $$('[data-edit]').forEach(function (button) {
            button.addEventListener('click', function () {
                resetForm();
                fieldId.value = button.dataset.id || '';
                fieldName.value = button.dataset.songName || '';
                fieldPath.value = button.dataset.songPath || '';
                fieldPlays.value = button.dataset.songPlays || '0';
                modalTitle.textContent = 'Editar cancion';
                modalEyebrow.textContent = 'ID #' + (button.dataset.id || '');
                submitBtn.textContent = 'Guardar cambios';
                openModal(songModal);
            });
        });

        songForm.addEventListener('submit', function (event) {
            event.preventDefault();
            formError.hidden = true;

            var name = fieldName.value.trim();
            var path = fieldPath.value.trim();
            var plays = parseInt(fieldPlays.value, 10);

            fieldName.classList.remove('is-invalid');
            fieldPath.classList.remove('is-invalid');

            if (!name) {
                fieldName.classList.add('is-invalid');
                showFormError('El nombre de la cancion es obligatorio.');
                fieldName.focus();
                return;
            }
            if (!path) {
                fieldPath.classList.add('is-invalid');
                showFormError('La ruta del archivo de audio es obligatoria.');
                fieldPath.focus();
                return;
            }
            if (isNaN(plays) || plays < 0) { plays = 0; }

            var isEdit = fieldId.value !== '';
            setBusy(true);

            post(isEdit ? 'update' : 'create', {
                id: fieldId.value,
                song_name: name,
                song_path: path,
                plays: plays
            }).then(function (result) {
                if (!result || !result.ok) {
                    setBusy(false);
                    showFormError((result && result.message) || 'No se pudo guardar la cancion.');
                    return;
                }
                closeModal(songModal);
                toast(result.message || 'Cambios guardados.', 'ok');
                window.setTimeout(function () { window.location.reload(); }, 750);
            }).catch(function () {
                setBusy(false);
                showFormError('No se pudo contactar con el servidor.');
            });
        });
    }

    /* --- Eliminar -------------------------------------------------------- */
    var confirmDelete = $('#confirmDelete');
    var deleteSongName = $('#deleteSongName');
    var pendingDeleteId = null;

    $$('[data-delete]').forEach(function (button) {
        button.addEventListener('click', function () {
            pendingDeleteId = button.dataset.id || null;
            if (deleteSongName) { deleteSongName.textContent = button.dataset.songName || 'esta cancion'; }
            openModal(deleteModal);
        });
    });

    if (confirmDelete) {
        confirmDelete.addEventListener('click', function () {
            if (!pendingDeleteId) { return; }

            confirmDelete.disabled = true;
            confirmDelete.textContent = 'Eliminando...';

            post('delete', { id: pendingDeleteId }).then(function (result) {
                confirmDelete.disabled = false;
                confirmDelete.textContent = 'Si, eliminar';

                if (!result || !result.ok) {
                    closeModal(deleteModal);
                    toast((result && result.message) || 'No se pudo eliminar la cancion.', 'error');
                    return;
                }
                closeModal(deleteModal);
                toast(result.message || 'Cancion eliminada.', 'ok');
                window.setTimeout(function () { window.location.reload(); }, 750);
            }).catch(function () {
                confirmDelete.disabled = false;
                confirmDelete.textContent = 'Si, eliminar';
                toast('No se pudo contactar con el servidor.', 'error');
            });
        });
    }

    /* --- Atajo: barra espaciadora pausa la pista activa ------------------ */
    document.addEventListener('keydown', function (event) {
        if (event.code !== 'Space' || !activePlayer) { return; }
        var tag = (event.target.tagName || '').toLowerCase();
        if (tag === 'input' || tag === 'textarea' || tag === 'button') { return; }
        if (!$('.modal:not([hidden])')) {
            event.preventDefault();
            toggle(activePlayer);
        }
    });
})();
