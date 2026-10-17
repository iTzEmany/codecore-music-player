// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Codecore';

  @override
  String get chooseFolder => 'Elegir carpeta';

  @override
  String get scan => 'Escanear';

  @override
  String get noTracks => 'Sin canciones. Elige una carpeta y escanea.';

  @override
  String get openSettings => 'Abrir ajustes';

  @override
  String get permissionDenied => 'Permiso de lectura de audio denegado';

  @override
  String get permissionExplain =>
      'Codecore necesita permiso para leer archivos de audio y mostrar tu música.';

  @override
  String get navLibrary => 'Biblioteca';

  @override
  String get navFavorites => 'Favoritos';

  @override
  String get navPlaylists => 'Listas';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get tracks => 'Canciones';

  @override
  String get albums => 'Álbumes';

  @override
  String get artists => 'Artistas';

  @override
  String get searchHint => 'Buscar';

  @override
  String get sortBy => 'Ordenar por';

  @override
  String get addMusicFolder => 'Añade tu carpeta de música';

  @override
  String get addFolder => 'Añadir carpeta';

  @override
  String get folders => 'Carpetas de música';

  @override
  String get refreshLibrary => 'Actualizar biblioteca';

  @override
  String get removeFolder => 'Quitar carpeta';

  @override
  String get unknownArtist => 'Artista desconocido';

  @override
  String get unknownAlbum => 'Álbum desconocido';

  @override
  String get variousArtists => 'Varios artistas';

  @override
  String get play => 'Reproducir';

  @override
  String get shuffle => 'Aleatorio';

  @override
  String get queue => 'Cola';

  @override
  String get nowPlaying => 'Reproduciendo';

  @override
  String get nothingPlaying => 'Nada en reproducción';

  @override
  String get mute => 'Silenciar';

  @override
  String get scanning => 'Escaneando…';

  @override
  String get emptyQueue => 'La cola está vacía';

  @override
  String get noResults => 'Sin resultados';

  @override
  String get sortDefault => 'Predeterminado';

  @override
  String get sortTitle => 'Título';

  @override
  String get sortArtist => 'Artista';

  @override
  String get sortAlbum => 'Álbum';

  @override
  String get sortYear => 'Año';

  @override
  String get sortAdded => 'Añadidos recientemente';

  @override
  String get sortDuration => 'Duración';

  @override
  String tracksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count canciones',
      one: '1 canción',
    );
    return '$_temp0';
  }

  @override
  String albumsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count álbumes',
      one: '1 álbum',
    );
    return '$_temp0';
  }

  @override
  String missingTracksCount(int count) {
    return 'Canciones no encontradas ($count)';
  }

  @override
  String get addedToFavorites => 'Añadido a favoritos';

  @override
  String get removedFromFavorites => 'Quitado de favoritos';

  @override
  String get undo => 'Deshacer';

  @override
  String get noFavorites => 'Aún no hay favoritos';

  @override
  String get newPlaylist => 'Nueva lista';

  @override
  String get newPlaylistEllipsis => 'Nueva lista…';

  @override
  String get playlistName => 'Nombre de la lista';

  @override
  String get create => 'Crear';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Guardar';

  @override
  String get delete => 'Eliminar';

  @override
  String get rename => 'Renombrar';

  @override
  String get noPlaylists => 'Sin listas. Crea una.';

  @override
  String get addToPlaylist => 'Añadir a lista…';

  @override
  String addedToPlaylist(String name) {
    return 'Añadido a «$name»';
  }

  @override
  String get playNext => 'Reproducir después';

  @override
  String get addToQueue => 'Añadir a la cola';

  @override
  String get addedToQueue => 'Añadido a la cola';

  @override
  String get favorite => 'Favorito';

  @override
  String get removeFromFavorites => 'Quitar de favoritos';

  @override
  String get removeFromList => 'Quitar';

  @override
  String get editInfo => 'Editar info';

  @override
  String get details => 'Detalles';

  @override
  String get showInFolder => 'Mostrar en carpeta';

  @override
  String get detailPath => 'Ruta';

  @override
  String get detailFormat => 'Formato';

  @override
  String get detailSize => 'Tamaño';

  @override
  String get detailDuration => 'Duración';

  @override
  String get detailAdded => 'Añadido el';

  @override
  String get detailPlays => 'Reproducciones';

  @override
  String get close => 'Cerrar';

  @override
  String get fieldTitle => 'Título';

  @override
  String get fieldArtist => 'Artista';

  @override
  String get fieldAlbum => 'Álbum';

  @override
  String get fieldAlbumArtist => 'Artista del álbum';

  @override
  String get fieldYear => 'Año';

  @override
  String get fieldTrackNumber => 'Número de pista';

  @override
  String get fieldGenre => 'Género';

  @override
  String get restoreFromFile => 'Restaurar desde etiquetas del archivo';

  @override
  String get titleRequired => 'El título no puede estar vacío';

  @override
  String get settingsAppearance => 'Apariencia';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get themeNotte => 'Noche violeta';

  @override
  String get themeOled => 'Negro puro';

  @override
  String get settingsTextSize => 'Tamaño del texto';

  @override
  String get textSmall => 'Pequeño';

  @override
  String get textNormal => 'Normal';

  @override
  String get textLarge => 'Grande';

  @override
  String get settingsCompact => 'Modo compacto';

  @override
  String get settingsReducedMotion => 'Reducir animaciones';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsLibrary => 'Biblioteca';

  @override
  String get rescanNow => 'Reescanear ahora';

  @override
  String get clearCoverCache => 'Vaciar caché de carátulas';

  @override
  String get coverCacheCleared => 'Caché de carátulas vaciada';

  @override
  String get settingsOnline => 'En línea';

  @override
  String get autoEnrich => 'Enriquecimiento automático';

  @override
  String get autoEnrichHint =>
      'Busca metadatos y carátulas en línea para canciones nuevas';

  @override
  String get autoLyrics => 'Letras automáticas';

  @override
  String get autoLyricsHint =>
      'Descarga letras de LRCLIB para canciones nuevas';

  @override
  String get settingsAbout => 'Acerca de';

  @override
  String appVersion(String version) {
    return 'Versión $version';
  }

  @override
  String get licenses => 'Licencias';

  @override
  String get personalUse => 'App de uso personal';

  @override
  String get missingTracksTitle => 'Canciones no encontradas';

  @override
  String get removeFromLibrary => 'Quitar de la biblioteca';

  @override
  String get ignore => 'Ignorar';

  @override
  String get confirmRemoveTitle => '¿Quitar de la biblioteca?';

  @override
  String get confirmRemoveBody =>
      'El archivo no se toca; pierdes favoritos y listas de esta canción.';

  @override
  String get noMissingTracks => 'Sin canciones perdidas';

  @override
  String get retry => 'Reintentar';

  @override
  String scanFailed(String error) {
    return 'Error al escanear: $error';
  }

  @override
  String playbackError(String reason, String title) {
    return 'No se puede reproducir «$title»: $reason';
  }

  @override
  String get reasonFileMissing => 'archivo no encontrado';

  @override
  String get reasonUnplayable => 'archivo no reproducible';

  @override
  String get reasonNotInLibrary => 'canción no está en la biblioteca';

  @override
  String get searchWeb => 'Buscar info en la web';

  @override
  String get enrichPreviewTitle => 'Vista previa de información';

  @override
  String get currentValue => 'Actual';

  @override
  String get proposedValue => 'Propuesto';

  @override
  String get apply => 'Aplicar';

  @override
  String get nothingFound => 'No se encontró nada';

  @override
  String get userEditedLocked => 'Editado por ti: no se sobrescribirá';

  @override
  String get fieldCover => 'Carátula';

  @override
  String get fieldLyrics => 'Letra';

  @override
  String get fieldCuriosity => 'Curiosidades';

  @override
  String get enrichAlbum => 'Enriquecer álbum';

  @override
  String get enrichLibrary => 'Enriquecer toda la biblioteca';

  @override
  String get enrichConfirmTitle => '¿Enriquecer la biblioteca?';

  @override
  String enrichConfirmBody(int count, int minutes) {
    return '$count canciones, unos $minutes minutos. Solo se rellenan los campos vacíos.';
  }

  @override
  String enrichRunning(int done, int total) {
    return 'Enriqueciendo $done/$total';
  }

  @override
  String enrichResult(int notFound, int updated) {
    return '$updated actualizados, $notFound no encontrados';
  }

  @override
  String get enrichBusy => 'Ya hay un enriquecimiento en curso';

  @override
  String get serviceUnavailable =>
      'Servicio no disponible, inténtalo más tarde';

  @override
  String get lyrics => 'Letra';

  @override
  String get searchLyrics => 'Buscar letra';

  @override
  String get noLyrics => 'Sin letra disponible';

  @override
  String get lyricsNotFound => 'Letra no encontrada';

  @override
  String get copy => 'Copiar';

  @override
  String get copied => 'Copiado';

  @override
  String get sourceWikipedia => 'Fuente: Wikipedia (CC BY-SA)';

  @override
  String get youtube => 'YouTube';

  @override
  String get ytHint => 'Busca o pega un enlace';

  @override
  String get ytDownload => 'Descargar';

  @override
  String get ytAlreadyInLibrary => 'Ya en la biblioteca';

  @override
  String get ytNoResults => 'Sin resultados';

  @override
  String get ytQueued => 'En cola';

  @override
  String get ytDownloading => 'Descargando';

  @override
  String get ytDone => 'Completado';

  @override
  String get ytFailed => 'Fallido';

  @override
  String get ytCancelled => 'Cancelado';

  @override
  String get ytClearCompleted => 'Vaciar completados';

  @override
  String get ytCancel => 'Cancelar descarga';

  @override
  String get ytErrUnavailable => 'Vídeo no disponible (edad/región/privado)';

  @override
  String get ytErrNetwork => 'Red no disponible';

  @override
  String get ytErrChanged =>
      'YouTube cambió algo: actualiza la app o el paquete';

  @override
  String get ytNoFolder => 'Añade primero una carpeta de música';

  @override
  String get ytLegal =>
      'Solo para uso personal. Respeta los derechos de autor y los términos de YouTube y SoundCloud.';

  @override
  String get useDefaultFolder => 'Usar la carpeta Música del dispositivo';

  @override
  String get ytErrToolMissing =>
      'yt-dlp no encontrado: instálalo (pip install -U yt-dlp) y reintenta';

  @override
  String get ytErrRateLimited =>
      'YouTube pide ir más despacio: inténtalo de nuevo en unos minutos';

  @override
  String get playlistChangeCover => 'Cambiar carátula';

  @override
  String get playlistRemoveCover => 'Quitar carátula';

  @override
  String get coverTooLarge => 'Imagen demasiado grande (máx. 4 MB)';

  @override
  String get addSongs => 'Añadir canciones';

  @override
  String addNSongs(int count) {
    return 'Añadir ($count)';
  }

  @override
  String get allSongsInPlaylist => 'Todas las canciones ya están en la lista';

  @override
  String get shareTitle => 'Compartir';

  @override
  String get shareSend => 'Enviar';

  @override
  String get shareReceive => 'Recibir';

  @override
  String get shareAll => 'Toda la biblioteca';

  @override
  String shareSelection(int count) {
    return 'Selección ($count canciones)';
  }

  @override
  String get sharePick => 'Elegir canciones';

  @override
  String get shareStart => 'Iniciar compartición';

  @override
  String get shareStop => 'Detener';

  @override
  String get shareActive => 'Compartición activa';

  @override
  String get shareAddress => 'Dirección (IP:puerto)';

  @override
  String get sharePin => 'PIN';

  @override
  String get shareConnect => 'Conectar';

  @override
  String shareDownloadSelected(int count) {
    return 'Descargar seleccionadas ($count)';
  }

  @override
  String shareProgress(int done, int total) {
    return 'Canción $done de $total';
  }

  @override
  String shareDone(int count) {
    return '$count canciones recibidas';
  }

  @override
  String shareConnectedTo(String name) {
    return 'Conectado a $name';
  }

  @override
  String get shareErrUnreachable =>
      'Dispositivo inaccesible: revisa la dirección y el Wi‑Fi';

  @override
  String get shareErrPin => 'PIN incorrecto';

  @override
  String get shareErrBlocked => 'Demasiados intentos: reintenta en un minuto';

  @override
  String get shareErrNotCodecore => 'No es un dispositivo Codecore';

  @override
  String get shareErrFailed => 'Transferencia fallida';

  @override
  String get shareNoNetwork => 'No se encontró red local';

  @override
  String get shareFirewall =>
      'Windows puede pedir permiso del firewall la primera vez.';

  @override
  String get shareHint =>
      'En la misma Wi‑Fi, abre «Recibir» en el otro dispositivo e introduce dirección y PIN.';

  @override
  String get shareMenu => 'Compartir…';

  @override
  String get shareDeviceName => 'Nombre del dispositivo';

  @override
  String get importOld => 'Importar de la app antigua';

  @override
  String get importOldHint => 'Elige codecore_library.db de la versión Python';

  @override
  String importSummary(
    int favorites,
    int lyrics,
    int playlists,
    int unmatched,
  ) {
    return '$favorites favoritos, $playlists listas, $lyrics letras importadas, $unmatched sin emparejar';
  }

  @override
  String get importFailed => 'Importación fallida: archivo no válido';

  @override
  String get sleepTimer => 'Temporizador de apagado';

  @override
  String sleepMinutes(int count) {
    return '$count minutos';
  }

  @override
  String get sleepEndOfTrack => 'Al final de la canción';

  @override
  String get sleepCancel => 'Cancelar temporizador';

  @override
  String get pause => 'Pausa';

  @override
  String get nextTrack => 'Siguiente canción';

  @override
  String get previousTrack => 'Canción anterior';

  @override
  String get repeat => 'Repetir';

  @override
  String get moreOptions => 'Más opciones';

  @override
  String get back => 'Atrás';

  @override
  String get settingsPlayback => 'Reproducción';

  @override
  String get normalizeVolume => 'Normalizar volumen';

  @override
  String get normalizeVolumeHint =>
      'Usa el ReplayGain de los archivos para bajar canciones muy fuertes';

  @override
  String get nearbyDevices => 'Dispositivos cercanos';

  @override
  String get searchingDevices => 'Buscando dispositivos en la red…';

  @override
  String get noDevicesHint =>
      'No se encontró ningún dispositivo. Abre Compartir también en el otro dispositivo, en la misma red.';

  @override
  String sendToDevice(String name) {
    return 'Enviar a $name';
  }

  @override
  String offerSent(String name) {
    return 'Solicitud enviada a $name';
  }

  @override
  String get offerChooseFirst => 'Elige primero las canciones a enviar';

  @override
  String get sentRequests => 'Solicitudes enviadas';

  @override
  String get receivedRequests => 'Solicitudes recibidas';

  @override
  String get offerPending => 'Esperando respuesta';

  @override
  String get offerAccepted => 'Aceptada';

  @override
  String get offerDeclined => 'Rechazada';

  @override
  String get offerCancelled => 'Cancelada';

  @override
  String get offerExpired => 'Caducada';

  @override
  String get offerDone => 'Completada';

  @override
  String get offerFailed => 'Fallida';

  @override
  String incomingTitle(String name) {
    return '$name quiere enviarte canciones';
  }

  @override
  String incomingBody(int count, String size) {
    return '$count canciones, $size MB';
  }

  @override
  String get accept => 'Aceptar';

  @override
  String get decline => 'Rechazar';

  @override
  String receivingProgress(int done, int total) {
    return 'Recibiendo $done/$total';
  }

  @override
  String get manualConnection => 'Conexión manual (IP y PIN)';

  @override
  String get receiveFromLan => 'Recibir de la red local';

  @override
  String get receiveFromLanHint =>
      'Hace visible el dispositivo y recibe solicitudes también en segundo plano. En Android muestra una notificación fija para desactivarlo';

  @override
  String get receiveServiceTitle => 'Codecore es visible en la red';

  @override
  String get receiveServiceText =>
      'Listo para recibir canciones de dispositivos cercanos';

  @override
  String get receiveServiceDisable => 'Desactivar';

  @override
  String get jamTitle => 'Jam';

  @override
  String get jamStart => 'Iniciar una Jam';

  @override
  String jamStartWith(String name) {
    return 'Iniciar Jam con $name';
  }

  @override
  String jamWaiting(String name) {
    return 'Esperando a que $name acepte…';
  }

  @override
  String jamDeclined(String name) {
    return '$name rechazó la Jam';
  }

  @override
  String jamBusy(String name) {
    return '$name ya tiene una Jam en curso';
  }

  @override
  String get jamUnreachable => 'Dispositivo no accesible';

  @override
  String jamIncomingTitle(String name) {
    return '$name quiere iniciar una Jam';
  }

  @override
  String get jamIncomingBody => 'Escuchad juntos desde una cola compartida.';

  @override
  String jamIncomingDialog(String name) {
    return '$name quiere iniciar una Jam contigo. La música suena en este dispositivo y ambos podéis añadir canciones.';
  }

  @override
  String get jamQueue => 'Cola compartida';

  @override
  String get jamEmpty => 'La cola está vacía. Añade canciones.';

  @override
  String jamAddedBy(String name) {
    return 'añadido por $name';
  }

  @override
  String get jamYou => 'ti';

  @override
  String get jamAddTracks => 'Añadir canciones';

  @override
  String get jamAddToJam => 'Añadir a la Jam';

  @override
  String jamAdded(int count) {
    return 'Añadidas a la Jam: $count';
  }

  @override
  String get jamOutput => 'Salida de audio';

  @override
  String get jamOutputHere => 'Este dispositivo';

  @override
  String jamOutputOther(String name) {
    return '$name';
  }

  @override
  String get jamEnd => 'Terminar Jam';

  @override
  String get jamLeave => 'Salir de la Jam';

  @override
  String get jamEnded => 'La Jam ha terminado';

  @override
  String get jamLost => 'Conexión perdida';

  @override
  String get jamGuestCannotSkip => 'Solo el anfitrión puede cambiar de canción';

  @override
  String get jamRemoveForbidden => 'Solo puedes quitar tus canciones';

  @override
  String get jamNowPlaying => 'Reproduciendo';

  @override
  String get jamNothingPlaying => 'Nada en reproducción';

  @override
  String jamWith(String name) {
    return 'Jam con $name';
  }

  @override
  String get jamUnavailable => 'No disponible';

  @override
  String get jamPlaying => 'La Jam está activa';

  @override
  String get jamOpen => 'Abrir Jam';

  @override
  String jamSynced(int ms) {
    return 'Sincronizado · desvío $ms ms';
  }

  @override
  String get jamSyncing => 'Sincronizando…';

  @override
  String jamLatency(int ms) {
    return 'Latencia de esta salida: $ms ms';
  }

  @override
  String get jamLatencyHint =>
      'Para auriculares o altavoces Bluetooth: súbela hasta que las salidas coincidan.';

  @override
  String get jamOutputsHint => 'Varias salidas suenan juntas';

  @override
  String get renamePlaylist => 'Renombrar lista';

  @override
  String get confirmDeletePlaylistTitle => '¿Eliminar la lista?';

  @override
  String confirmDeletePlaylistBody(String name) {
    return '«$name» se eliminará. Las canciones siguen en la biblioteca.';
  }

  @override
  String get confirmRemoveFolderTitle => '¿Quitar la carpeta?';

  @override
  String get confirmRemoveFolderBody =>
      'Sus canciones salen de la biblioteca. Los archivos siguen en el dispositivo.';

  @override
  String get confirmClearCoversTitle => '¿Vaciar la caché de carátulas?';

  @override
  String get confirmClearCoversBody =>
      'Las carátulas se recrean en el próximo escaneo.';

  @override
  String get confirmRestoreTitle =>
      '¿Restaurar desde las etiquetas del archivo?';

  @override
  String get confirmRestoreBody =>
      'Tus cambios en esta canción se sustituyen por los datos del archivo.';

  @override
  String get removedFromPlaylist => 'Quitada de la lista';

  @override
  String get removedFromQueue => 'Quitada de la cola';

  @override
  String get playNextDone => 'Sonará a continuación';

  @override
  String get ytSearchPrompt => 'Busca una canción o pega un enlace';

  @override
  String get loadFailed => 'No se pudieron cargar los datos.';

  @override
  String get navHome => 'Inicio';

  @override
  String get navSearch => 'Buscar';

  @override
  String get devicesTitle => 'Dispositivos';

  @override
  String get devicesJamActive => 'Jam activa';

  @override
  String jamPeople(int n) {
    return 'Jam · $n personas';
  }

  @override
  String get devicesVisibleTitle => 'Hacer visible este dispositivo';

  @override
  String get devicesVisibleHint =>
      'Para recibir canciones o iniciar una Jam, los demás dispositivos deben verte en la red.';

  @override
  String get devicesJamShort => 'Jam';

  @override
  String get devicesSendShort => 'Enviar';

  @override
  String get devicesMore => 'Compartir y conexión manual';

  @override
  String jamParticipantsCount(int n) {
    return '$n personas';
  }

  @override
  String get playingFrom => 'Reproduciendo desde';

  @override
  String get playContextSearch => 'Búsqueda';

  @override
  String get allTracks => 'Todas las canciones';

  @override
  String get trackInfo => 'Información de la canción';

  @override
  String get searchCuriosity => 'Buscar curiosidades';

  @override
  String get upNext => 'A continuación';

  @override
  String get openQueue => 'Abrir cola';

  @override
  String get copyLink => 'Copiar enlace';

  @override
  String get moreActions => 'Más acciones';

  @override
  String get sleepChipEnd => 'fin de la canción';

  @override
  String get yourLibrary => 'Tu biblioteca';

  @override
  String playlistCountLabel(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Lista · $n canciones',
      one: 'Lista · 1 canción',
    );
    return '$_temp0';
  }

  @override
  String get sortRecent => 'Recientes';

  @override
  String get sortAlphabetical => 'Alfabético';

  @override
  String get sortAddedRecently => 'Añadidos recientemente';

  @override
  String get viewAsGrid => 'Ver como cuadrícula';

  @override
  String get viewAsList => 'Ver como lista';

  @override
  String get kindAlbum => 'Álbum';

  @override
  String get kindArtist => 'Artista';

  @override
  String get kindPlaylist => 'Lista';

  @override
  String discN(int n) {
    return 'Disco $n';
  }

  @override
  String albumMeta(String details) {
    return 'Álbum · $details';
  }

  @override
  String durationMinutes(int n) {
    return '$n min';
  }

  @override
  String tracksAndDuration(String tracks, String duration) {
    return '$tracks, $duration';
  }

  @override
  String get mostPlayed => 'Más escuchadas';

  @override
  String get albumsSection => 'Álbumes';

  @override
  String artistMeta(String albums, String tracks) {
    return '$albums · $tracks';
  }

  @override
  String get addAllToQueue => 'Añadir a la cola';

  @override
  String addedNToQueue(int n) {
    return '$n canciones añadidas a la cola';
  }

  @override
  String get editOrder => 'Editar orden';

  @override
  String get finishEditing => 'Listo';

  @override
  String get removeFromPlaylistAction => 'Quitar de la lista';

  @override
  String get noTracksInPlaylist => 'Esta lista está vacía';

  @override
  String get greetingMorning => 'Buenos días';

  @override
  String get greetingAfternoon => 'Buenas tardes';

  @override
  String get greetingEvening => 'Buenas noches';

  @override
  String get homeResume => 'Continuar';

  @override
  String get homeRecentlyPlayed => 'Escuchado recientemente';

  @override
  String get homeRecentlyAdded => 'Añadido recientemente';

  @override
  String get homeTopTracks => 'Más escuchadas';

  @override
  String get homeRediscover => 'Para redescubrir';

  @override
  String get searchMainResult => 'Mejor resultado';

  @override
  String get showAll => 'Mostrar todo';

  @override
  String searchOnYoutube(String query) {
    return 'Buscar «$query» en YouTube';
  }

  @override
  String get recentSearches => 'Búsquedas recientes';

  @override
  String get genresTitle => 'Géneros';

  @override
  String downloadsChip(int n) {
    return 'Descargas ($n)';
  }

  @override
  String get gotIt => 'Entendido';

  @override
  String get searchEmptyLibrary => 'Sin resultados en la biblioteca';

  @override
  String get ytInfoTooltip => 'Información de uso';

  @override
  String get removeRecentSearch => 'Quitar de búsquedas recientes';

  @override
  String get groupGoTo => 'Ir a';

  @override
  String get goToAlbum => 'Ir al álbum';

  @override
  String get goToArtist => 'Ir al artista';

  @override
  String get groupQueue => 'Cola';

  @override
  String get groupCollection => 'Colección';

  @override
  String get groupEdit => 'Editar';

  @override
  String get groupOther => 'Más';

  @override
  String get queueNowPlaying => 'Reproduciendo';

  @override
  String get queueNext => 'A continuación';

  @override
  String get queueClear => 'Vaciar';

  @override
  String get queueCleared => 'Cola vaciada';

  @override
  String get jamOutputsAndSync => 'Salidas y sincronía';

  @override
  String get jamHostTag => 'anfitrión';

  @override
  String get jamWaitingEmpty => 'No hay ninguna Jam en curso';

  @override
  String get activityTitle => 'Actividad';

  @override
  String activityScan(int done, int total) {
    return 'Escaneo · $done/$total';
  }

  @override
  String get activityScanIdle => 'Escaneando';

  @override
  String activityEnrich(int done, int total) {
    return 'Enriquecimiento · $done/$total';
  }

  @override
  String activityDownload(String title) {
    return 'Descarga · $title';
  }

  @override
  String activityTransfer(String name, int n) {
    return 'Envío a $name · $n canciones';
  }

  @override
  String get activityNone => 'Sin actividad';

  @override
  String get activityCompleted => 'Completadas';

  @override
  String get activityClear => 'Limpiar';

  @override
  String activityRunning(int n) {
    return '$n actividades en curso';
  }

  @override
  String get settingsLocalNetwork => 'Red local';

  @override
  String get removeAll => 'Quitar todas';

  @override
  String get confirmRemoveAllTitle => '¿Quitar todas de la biblioteca?';

  @override
  String confirmRemoveAllBody(int n) {
    return 'Se quitarán $n canciones no encontradas de la biblioteca. Los archivos no se tocan; pierdes favoritos y listas de estas canciones.';
  }

  @override
  String get csvImportMenu => 'Importar desde Exportify (CSV)';

  @override
  String get csvImportIntroTitle => 'Importar una lista';

  @override
  String get csvImportIntroSource =>
      'El archivo CSV se crea gratis en el sitio Exportify — exportify.net (no hace falta ninguna app).';

  @override
  String get csvImportStep1 =>
      'Abre https://exportify.net en el navegador (también desde el móvil).';

  @override
  String get csvImportStep2 =>
      'Toca «Get Started» e inicia sesión con tu cuenta de Spotify.';

  @override
  String get csvImportStep3 =>
      'Junto a la lista que quieras toca «Export»: se descarga un archivo .csv con el nombre de la lista.';

  @override
  String get csvImportStep4 => 'Vuelve aquí y toca «Elegir archivo CSV».';

  @override
  String get csvImportNote =>
      'Codecore busca las canciones en tu biblioteca y descarga las demás de YouTube Music.';

  @override
  String get csvImportNoteOffline =>
      'Solo se enlazarán las canciones que ya están en tu biblioteca.';

  @override
  String get csvImportCopy => 'Copiar dirección';

  @override
  String get csvImportCopied => 'Dirección copiada';

  @override
  String get csvImportPick => 'Elegir archivo';

  @override
  String get csvImportNotExportify =>
      'Formato no reconocido. Elige un CSV (Exportify, TuneMyMusic, Soundiiz, Last.fm) o una lista M3U/M3U8/XSPF.';

  @override
  String get csvImportReadFailed => 'No se pudo leer el archivo.';

  @override
  String get csvImportPreviewTitle => 'Importar lista';

  @override
  String get csvImportName => 'Nombre de la lista';

  @override
  String csvImportSummary(int total, int known, int todo) {
    return '$total canciones · $known ya en la biblioteca · $todo por descargar';
  }

  @override
  String csvImportSkipped(int n) {
    return '$n filas ignoradas (podcasts o archivos locales)';
  }

  @override
  String csvImportEstimate(int minutes) {
    return 'Tiempo estimado: unos $minutes min';
  }

  @override
  String get csvImportExists => 'Ya existe una lista con este nombre';

  @override
  String get csvImportUpdate =>
      'Actualizar la existente (solo añade las nuevas)';

  @override
  String get csvImportNew => 'Crear una lista nueva';

  @override
  String get csvImportGo => 'Importar';

  @override
  String get csvImportStarted =>
      'Importación iniciada: síguela en el Centro de actividad';

  @override
  String activityImport(String name, int done, int total) {
    return 'Importación «$name» · $done/$total';
  }

  @override
  String activityImportPaused(String name, int done, int total) {
    return 'Importación «$name» · en pausa · $done/$total';
  }

  @override
  String csvImportBanner(int done, int total, int review, int missing) {
    return 'Importación: $done/$total · $review por revisar · $missing no encontradas';
  }

  @override
  String csvImportBannerPaused(int done, int total, int review, int missing) {
    return 'Importación en pausa: $done/$total · $review por revisar · $missing no encontradas';
  }

  @override
  String get csvImportReview => 'Revisar';

  @override
  String get csvImportResume => 'Reanudar';

  @override
  String get csvImportPause => 'Pausar';

  @override
  String get csvImportCancelTitle => '¿Cancelar la importación?';

  @override
  String get csvImportCancelBody =>
      'Las canciones ya descargadas se quedan en la lista.';

  @override
  String csvImportDone(int added, int review, int missing) {
    return 'Importación terminada: $added añadidas, $review por revisar, $missing no encontradas';
  }

  @override
  String get csvImportFailing =>
      'Demasiados errores seguidos: importación en pausa';

  @override
  String get csvImportReviewTitle => 'Revisar';

  @override
  String get csvImportToReview => 'Por revisar';

  @override
  String get csvImportNotFound => 'No encontradas';

  @override
  String get csvImportErrors => 'Con errores';

  @override
  String get csvImportRetryAll => 'Reintentar todas';

  @override
  String get csvImportSkip => 'Omitir';

  @override
  String get csvImportManual => 'Buscar a mano';

  @override
  String get csvImportNothing => 'Nada que revisar.';

  @override
  String get csvImportSearch => 'Buscar';

  @override
  String csvImportWanted(String title, String artist, String duration) {
    return 'Buscada: $title · $artist · $duration';
  }

  @override
  String get csvImportDownload => 'Descargar';

  @override
  String get csvImportCancelGo => 'Cancelar importación';

  @override
  String get exportLog => 'Exportar registro';

  @override
  String get exportLogHint =>
      'Archivo de texto sin rutas personales, direcciones de red ni PIN';

  @override
  String get exportLogDebugOnly =>
      'Solo en la versión instalada (en depuración el registro no se escribe en un archivo)';

  @override
  String get exportLogNone => 'Todavía no hay ningún registro para exportar';

  @override
  String get exportLogSaved => 'Registro guardado';

  @override
  String get exportLogFailed => 'No se pudo guardar el registro';

  @override
  String get exportPlaylist => 'Exportar…';

  @override
  String get exportPlaylistTitle => 'Exportar lista';

  @override
  String get exportFormatM3u8 => 'M3U8 · para otros reproductores';

  @override
  String get exportFormatCsv => 'CSV · como Exportify';

  @override
  String get exportFormatJson => 'JSON · formato Codecore';

  @override
  String get exportRelativePaths => 'Rutas relativas';

  @override
  String get exportRelativeHint =>
      'Relativas a la carpeta común de las canciones: guarda el archivo allí';

  @override
  String get exportAction => 'Exportar';

  @override
  String get exportSaved => 'Lista exportada';

  @override
  String get exportEmpty => 'La lista está vacía';

  @override
  String get exportFailed => 'No se pudo exportar la lista';

  @override
  String get ytErrToolOutdated =>
      'yt-dlp es demasiado antiguo: actualízalo (Ajustes → Descargas → Actualizar) e inténtalo de nuevo';

  @override
  String ytDlpOutdatedBanner(String version) {
    return 'yt-dlp $version es demasiado antiguo: puede que las descargas no funcionen';
  }

  @override
  String get settingsDownloads => 'Descargas';

  @override
  String ytDlpVersion(String version) {
    return 'yt-dlp $version';
  }

  @override
  String get ytDlpUnknownVersion => 'yt-dlp no encontrado';

  @override
  String get ytDlpUpdate => 'Actualizar';

  @override
  String ytDlpUpdating(int percent) {
    return 'Actualizando… $percent%';
  }

  @override
  String ytDlpUpdated(String version) {
    return 'Actualizado a la versión $version';
  }

  @override
  String get ytDlpTooOld => 'Demasiado antiguo: toca Actualizar';

  @override
  String get ytDlpUpdateErrNetwork => 'Error al actualizar: red inaccesible';

  @override
  String get ytDlpUpdateErrHash =>
      'Actualización cancelada: el archivo descargado no pasó la comprobación de integridad';

  @override
  String get ytDlpUpdateErrOther =>
      'Error al actualizar (consulta el registro)';

  @override
  String get downloadParallel => 'Descargas simultáneas';

  @override
  String get downloadParallelHint =>
      'Más a la vez es más rápido, pero YouTube puede pedir que vayas más despacio';

  @override
  String get downloadRateLimit => 'Límite de velocidad';

  @override
  String get downloadRateNone => 'Sin límite';

  @override
  String downloadRateKb(int kb) {
    return '$kb KB/s';
  }

  @override
  String downloadRateMb(int mb) {
    return '$mb MB/s';
  }

  @override
  String activityDownloadRetry(
    String title,
    int seconds,
    int attempt,
    int max,
  ) {
    return 'Descarga · $title · nuevo intento en $seconds s ($attempt/$max)';
  }

  @override
  String get downloadOriginal => 'Calidad original (sin recodificar)';

  @override
  String get downloadOriginalHint =>
      'Conserva el audio de YouTube tal cual (M4A/Opus): sin pérdida extra, archivos más pequeños. Desactivado: MP3 256 kbps';

  @override
  String get searchCacheClear => 'Vaciar caché de búsquedas';

  @override
  String searchCacheCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count búsquedas guardadas',
      one: '1 búsqueda guardada',
      zero: 'Vacía',
    );
    return '$_temp0';
  }

  @override
  String get searchCacheCleared => 'Caché vaciada';

  @override
  String csvImportLengthOff(String found, String wanted) {
    return 'Duración distinta: $found en lugar de $wanted';
  }

  @override
  String get csvImportKeep => 'Quedarme con este';

  @override
  String get csvImportTooBig =>
      'El archivo es demasiado grande para una lista (máximo 5 MB y 10.000 canciones)';

  @override
  String get csvImportAlsoAccepts =>
      'También se aceptan: TuneMyMusic, Soundiiz, Last.fm (CSV), M3U/M3U8, XSPF.';

  @override
  String get csvImportPlanned => 'Coincidencias listas: revísalas y descarga';

  @override
  String get csvImportLinkOnly => 'Solo enlazar (sin descargas)';

  @override
  String get csvImportLinkOnlyHint =>
      'Crea la lista con lo que ya tienes y nada más';

  @override
  String get csvImportPlanFirst => 'Revisar antes de descargar';

  @override
  String get csvImportPlanFirstHint =>
      'Busca todo y luego eliges qué descargar';

  @override
  String get csvImportPlanTitle => 'Coincidencias';

  @override
  String csvImportPlanGo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Descargar $n canciones',
      one: 'Descargar 1 canción',
    );
    return '$_temp0';
  }

  @override
  String get csvImportPlanKnown => 'ya descargada';

  @override
  String get csvImportPlanEmpty => 'Nada que descargar';

  @override
  String csvImportBannerPlanned(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n canciones por descargar',
      one: '1 canción por descargar',
    );
    return 'Coincidencias listas: $_temp0';
  }

  @override
  String get settingsAdvanced => 'Avanzado';

  @override
  String get importSureThreshold => 'Coincidencia segura desde';

  @override
  String get importSureThresholdHint =>
      'Por encima de esta puntuación una canción importada se descarga sin preguntar';

  @override
  String get importReviewThreshold => 'Por revisar desde';

  @override
  String get importReviewThresholdHint =>
      'Entre esta puntuación y la segura la canción va a «Por revisar»; por debajo, a «No encontradas»';

  @override
  String get importThresholdsReset => 'Restablecer valores predeterminados';

  @override
  String csvImportEstimateHours(int hours, int minutes) {
    return 'Tiempo estimado: unas $hours h $minutes min';
  }

  @override
  String csvImportBlocks(int size) {
    return 'Importar en bloques de $size';
  }

  @override
  String csvImportBigWarning(int n) {
    return '$n canciones por descargar: tardará horas. En bloques, uno tras otro, el orden de la lista se mantiene y puedes parar entre bloques.';
  }

  @override
  String get etaLessThanMinute => 'menos de 1 min';

  @override
  String etaMinutes(int minutes) {
    return 'unos $minutes min';
  }

  @override
  String etaHours(int hours, int minutes) {
    return 'unas $hours h $minutes min';
  }

  @override
  String get csvImportOwnFolder => 'Carpeta para esta lista';

  @override
  String get csvImportOwnFolderHint =>
      'Guarda las descargas en una subcarpeta con el nombre de la lista';

  @override
  String get csvImportNumberFiles => 'Numerar los archivos';

  @override
  String get csvImportNumberFilesHint =>
      '07 - Artista - Título: la carpeta suena en el orden correcto incluso fuera de Codecore';

  @override
  String get csvImportFetchCovers => 'Buscar carátulas';

  @override
  String get csvImportFetchCoversHint =>
      'Tras cada descarga busca la carátula del álbum en iTunes (álbum y artista del archivo)';

  @override
  String get csvImportExport => 'Exportar resultado';

  @override
  String get csvImportExported => 'Resultado guardado';

  @override
  String get csvOutHeaderRow => 'Fila';

  @override
  String get csvOutHeaderTitle => 'Título';

  @override
  String get csvOutHeaderArtists => 'Artistas';

  @override
  String get csvOutHeaderAlbum => 'Álbum';

  @override
  String get csvOutHeaderDuration => 'Duración (ms)';

  @override
  String get csvOutHeaderIsrc => 'ISRC';

  @override
  String get csvOutHeaderStatus => 'Resultado';

  @override
  String get csvOutHeaderNote => 'Motivo';

  @override
  String get csvOutHeaderVideo => 'Vídeo elegido';

  @override
  String get csvOutHeaderScore => 'Puntuación';

  @override
  String get importStatusPending => 'Por buscar';

  @override
  String get importStatusQueued => 'En cola';

  @override
  String get importStatusDownloaded => 'Descargada';

  @override
  String get importStatusLinked => 'Ya en la biblioteca';

  @override
  String get importStatusReview => 'Por revisar';

  @override
  String get importStatusNotFound => 'No encontrada';

  @override
  String get importStatusFailed => 'Error';

  @override
  String get importStatusSkipped => 'Omitida';

  @override
  String get importStatusPlanned => 'Planificada';

  @override
  String get importStatusRemoved => 'Quitada de la fuente';

  @override
  String get importNoteNoResults => 'Sin resultados';

  @override
  String get importNoteLowScore => 'Coincidencia poco segura';

  @override
  String get importNoteLinkOnly => 'Solo enlazar: no se buscó';

  @override
  String get importNoteYoutubeOff => 'Descargas desactivadas';

  @override
  String get importNoteDownloadFailed => 'Error al descargar';

  @override
  String get importNoteLengthOff => 'Duración distinta de la del archivo';

  @override
  String get importNoteUnchanged => 'Ya está en la lista';

  @override
  String get csvImportSync => 'Sincronizar';

  @override
  String csvImportSyncCounts(int added, int removed) {
    return '+$added nuevas · −$removed quitadas de la lista (los archivos se quedan)';
  }

  @override
  String get csvImportSyncChecking => 'Comprobando las diferencias…';

  @override
  String get playbackSpeed => 'Velocidad de reproducción';

  @override
  String get playbackSpeedHint =>
      'El tono se mantiene. El temporizador de apagado cuenta tiempo real, no el de la canción.';

  @override
  String resumeFrom(String time) {
    return 'continuar en $time';
  }

  @override
  String get restartFromBeginning => 'Empezar desde el principio';

  @override
  String get previewTrack => 'Vista previa de 20 s';

  @override
  String get equalizer => 'Ecualizador';

  @override
  String get eqOutputSpeaker => 'Altavoz';

  @override
  String get eqOutputHeadphones => 'Auriculares';

  @override
  String get eqHint =>
      'Cada salida recuerda su curva: cambia sola al conectar auriculares.';

  @override
  String get eqPresetFlat => 'Plano';

  @override
  String get eqPresetBass => 'Graves';

  @override
  String get eqPresetVoice => 'Voz';

  @override
  String get eqPresetTreble => 'Agudos';

  @override
  String get eqPresetCustom => 'Personalizado';

  @override
  String get eqReset => 'Restablecer';

  @override
  String get eqWaiting =>
      'Las bandas aparecen cuando empieza la primera canción.';

  @override
  String get eqUnavailable =>
      'El ecualizador no está disponible en este dispositivo.';

  @override
  String get transitionMode => 'Transición entre canciones';

  @override
  String get transitionNormal => 'Normal';

  @override
  String get transitionGapless => 'Sin pausas';

  @override
  String get transitionCrossfade => 'Fundido cruzado';

  @override
  String get transitionHint =>
      'Sin pausas funciona mejor con canciones del mismo formato (por ejemplo, todas en FLAC).';

  @override
  String crossfadeLength(int seconds) {
    return 'Duración del fundido: $seconds s';
  }

  @override
  String get crossfadePlainInAlbum => 'No fundir dentro de un álbum';

  @override
  String get crossfadePlainInAlbumHint =>
      'Dentro de un álbum las canciones se suceden sin pausas y sin solaparse.';

  @override
  String get selectedRow => 'Seleccionado';

  @override
  String selectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seleccionadas',
      one: '1 seleccionada',
    );
    return '$_temp0';
  }

  @override
  String get selectAll => 'Seleccionar todo';

  @override
  String get exitSelection => 'Salir de la selección';

  @override
  String get bulkActions => 'Acciones';

  @override
  String playNextMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count canciones sonarán a continuación',
      one: '1 canción sonará a continuación',
    );
    return '$_temp0';
  }

  @override
  String addedToQueueMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count canciones añadidas a la cola',
      one: '1 canción añadida a la cola',
    );
    return '$_temp0';
  }

  @override
  String addedToPlaylistMany(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count canciones añadidas a «$name»',
      one: '1 canción añadida a «$name»',
    );
    return '$_temp0';
  }

  @override
  String addedToPlaylistSkipped(int added, int skipped, String name) {
    return '$added añadidas a «$name», $skipped ya estaban';
  }

  @override
  String allAlreadyInPlaylist(String name) {
    return 'Ya estaban todas en «$name»';
  }

  @override
  String favoritesAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count canciones añadidas a favoritos',
      one: '1 canción añadida a favoritos',
    );
    return '$_temp0';
  }

  @override
  String favoritesRemoved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count canciones quitadas de favoritos',
      one: '1 canción quitada de favoritos',
    );
    return '$_temp0';
  }

  @override
  String get bulkAddToFavorites => 'Añadir a favoritos';

  @override
  String get bulkRemoveFromFavorites => 'Quitar de favoritos';

  @override
  String removeManyFromPlaylistTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '¿Quitar $count canciones de la lista?',
      one: '¿Quitar 1 canción de la lista?',
    );
    return '$_temp0';
  }

  @override
  String get removeManyFromPlaylistBody =>
      'Los archivos y la biblioteca no se tocan.';

  @override
  String removedManyFromPlaylist(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count canciones quitadas',
      one: '1 canción quitada',
    );
    return '$_temp0';
  }

  @override
  String removeManyFromLibraryTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '¿Quitar $count canciones de la biblioteca?',
      one: '¿Quitar 1 canción de la biblioteca?',
    );
    return '$_temp0';
  }

  @override
  String get removeManyFromLibraryBody =>
      'Los archivos ya no existen: solo desaparecen de la biblioteca (pierdes los favoritos y las listas de estas canciones).';

  @override
  String removedManyFromLibrary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count canciones quitadas de la biblioteca',
      one: '1 canción quitada de la biblioteca',
    );
    return '$_temp0';
  }

  @override
  String ytDownloadsStarted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count descargas iniciadas',
      one: '1 descarga iniciada',
    );
    return '$_temp0';
  }

  @override
  String ytDownloadsSkipped(int started, int skipped) {
    return '$started descargas iniciadas, $skipped ya en la biblioteca o en curso';
  }

  @override
  String get ytNothingToDownload =>
      'Ya están todos en la biblioteca o en curso';

  @override
  String get themeChiaro => 'Claro';

  @override
  String get settingsAccent => 'Color de acento';

  @override
  String get accentViola => 'Violeta';

  @override
  String get accentBlu => 'Azul';

  @override
  String get accentAcqua => 'Turquesa';

  @override
  String get accentVerde => 'Verde';

  @override
  String get accentAmbra => 'Ámbar';

  @override
  String get accentArancio => 'Naranja';

  @override
  String get accentRosa => 'Rosa';

  @override
  String get accentRosso => 'Rojo';

  @override
  String get onboardingSkip => 'Omitir';

  @override
  String get onboardingNext => 'Siguiente';

  @override
  String get onboardingStart => 'Empezar';

  @override
  String onboardingPageOf(int page, int total) {
    return 'Página $page de $total';
  }

  @override
  String get onboardingWelcomeTitle => 'Te damos la bienvenida a Codecore';

  @override
  String get onboardingWelcomeBody =>
      'Tu reproductor de música personal: sin cuenta y sin servidor. Tu música se queda en tu dispositivo.';

  @override
  String get onboardingFoldersTitle => 'Tu música';

  @override
  String get onboardingFoldersBody =>
      'Elige las carpetas donde guardas tus canciones. Codecore solo las lee: no las modifica ni las mueve.';

  @override
  String onboardingFoldersAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count carpetas añadidas',
      one: '1 carpeta añadida',
    );
    return '$_temp0';
  }

  @override
  String get onboardingAllowAccess =>
      'Permitir el acceso a los archivos de audio';

  @override
  String get onboardingAccessGranted => 'Acceso permitido';

  @override
  String get onboardingOnlineTitle => 'Funciones en línea';

  @override
  String get onboardingOnlineBody =>
      'Están desactivadas: Codecore nunca se conecta a Internet por su cuenta. Puedes activarlas ahora o más tarde en Ajustes.';

  @override
  String get onboardingShareTitle => 'Descargas, Jam y compartir';

  @override
  String get onboardingYoutubeBody =>
      'Puedes descargar canciones de YouTube en tu dispositivo y escucharlas como el resto de tu música.';

  @override
  String get onboardingJamBody =>
      'Con una Jam escuchas la misma música junto con otro dispositivo de la misma red.';

  @override
  String get onboardingSendBody =>
      'Puedes enviar canciones a otros dispositivos cercanos con un PIN, sin pasar por Internet.';

  @override
  String get historyTitle => 'Historial';

  @override
  String get historySubtitle => 'Lo que has escuchado';

  @override
  String get historyToday => 'Hoy';

  @override
  String get historyYesterday => 'Ayer';

  @override
  String get historyEmpty => 'Aquí aparecerá lo que escuches.';

  @override
  String get historyOff =>
      'El historial está desactivado: actívalo en Ajustes → Reproducción.';

  @override
  String get historyClear => 'Borrar historial';

  @override
  String get historyClearTitle => '¿Borrar el historial?';

  @override
  String get historyClearBody =>
      'Solo se borra la lista de reproducciones: los contadores, los favoritos y las listas se quedan como están.';

  @override
  String get historyCleared => 'Historial borrado';

  @override
  String get settingsRecordHistory => 'Guardar el historial de escucha';

  @override
  String get settingsRecordHistoryHint =>
      'Se queda en el dispositivo. Si se apaga, no se añade nada más a la lista.';

  @override
  String get statsTitle => 'Estadísticas';

  @override
  String get statsSubtitle => 'Cuánto y qué escuchas';

  @override
  String get statsMonth => 'Mes';

  @override
  String get statsYear => 'Año';

  @override
  String get statsPrevious => 'Periodo anterior';

  @override
  String get statsNext => 'Periodo siguiente';

  @override
  String get statsEmpty => 'No hay reproducciones en este periodo.';

  @override
  String statsPlays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reproducciones',
      one: '1 reproducción',
    );
    return '$_temp0';
  }

  @override
  String statsDistinct(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count canciones distintas',
      one: '1 canción distinta',
    );
    return '$_temp0';
  }

  @override
  String statsHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String get statsTopTracks => 'Canciones más escuchadas';

  @override
  String get statsTopArtists => 'Artistas más escuchados';

  @override
  String get statsTopAlbums => 'Álbumes más escuchados';

  @override
  String get statsFavouriteHour => 'Hora favorita';

  @override
  String get statsFirstListen => 'Primera reproducción';

  @override
  String statsFirstValue(String title, String date) {
    return '$title · $date';
  }

  @override
  String get statsYourMonth => 'Tu mes';

  @override
  String statsTopArtistHome(String name) {
    return 'El más escuchado: $name';
  }

  @override
  String get ruleChipArtist => 'artist:';

  @override
  String get ruleChipYear => 'year:';

  @override
  String get ruleChipGenre => 'genre:';

  @override
  String get ruleChipTag => 'tag:';

  @override
  String get ruleChipFavorites => 'favorites';

  @override
  String ruleWarning(String term) {
    return 'No entiendo «$term»: lo busco como texto.';
  }

  @override
  String get ruleHelpTooltip => 'Ayuda de la búsqueda';

  @override
  String get smartPlaylistNew => 'Nueva lista inteligente';

  @override
  String get smartPlaylistEdit => 'Editar lista inteligente';

  @override
  String get smartPlaylistLabel => 'Lista inteligente';

  @override
  String smartSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Lista inteligente · $count canciones',
      one: 'Lista inteligente · 1 canción',
    );
    return '$_temp0';
  }

  @override
  String get smartName => 'Nombre';

  @override
  String get smartNameRequired => 'Escribe un nombre';

  @override
  String get smartRules => 'Reglas';

  @override
  String get smartRulesHint => 'artist:\"pink floyd\" -live year:1970..1979';

  @override
  String get smartNoRules =>
      'Sin reglas, la lista contiene toda la biblioteca.';

  @override
  String get smartSortBy => 'Ordenar por';

  @override
  String get smartSortMostPlayed => 'Más escuchadas';

  @override
  String get smartSortRandom => 'Al azar';

  @override
  String get smartLimit => 'Límite de canciones (opcional)';

  @override
  String get smartTemplates => 'Plantillas';

  @override
  String get smartTplNever => 'Nunca escuchadas';

  @override
  String get smartTplRecent => 'Añadidas recientemente';

  @override
  String get smartTplTop => 'Las más escuchadas';

  @override
  String get smartTpl90s => 'Los años 90';

  @override
  String get smartConvert => 'Convertir en lista normal';

  @override
  String smartConverted(String name) {
    return 'Creada la lista «$name» con la lista actual';
  }

  @override
  String smartDeleteTitle(String name) {
    return '¿Eliminar «$name»?';
  }

  @override
  String get smartDeleteBody =>
      'Solo se elimina la regla: las canciones se quedan donde están.';

  @override
  String get smartAutoNote => 'La lista se actualiza sola.';

  @override
  String get tagsTitle => 'Etiquetas';

  @override
  String get tagsSubtitle => 'Tus propias etiquetas';

  @override
  String tagsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count etiquetas',
      one: '1 etiqueta',
    );
    return '$_temp0';
  }

  @override
  String get tagsEllipsis => 'Etiquetas…';

  @override
  String get tagNew => 'Nueva etiqueta';

  @override
  String get tagRename => 'Renombrar etiqueta';

  @override
  String get tagColor => 'Color';

  @override
  String get tagNoColor => 'Sin color';

  @override
  String get tagNameTaken => 'Ya existe una etiqueta con ese nombre';

  @override
  String tagDeleteTitle(String name) {
    return '¿Eliminar la etiqueta «$name»?';
  }

  @override
  String get tagDeleteBody =>
      'Solo se quita la etiqueta de las canciones: siguen en la biblioteca.';

  @override
  String get tagsEmpty =>
      'Aún no hay etiquetas: crea una desde el menú de una canción.';

  @override
  String get tagAddToSelection => 'Añadir etiqueta…';

  @override
  String get tagRemoveFromSelection => 'Quitar etiqueta…';

  @override
  String tagAssigned(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count canciones etiquetadas «$name»',
      one: '1 canción etiquetada «$name»',
    );
    return '$_temp0';
  }

  @override
  String tagUnassigned(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '«$name» quitada de $count canciones',
      one: '«$name» quitada de 1 canción',
    );
    return '$_temp0';
  }

  @override
  String get tagNoneToRemove => 'Las canciones elegidas no tienen etiquetas.';

  @override
  String get ruleHelpTitle => 'Buscar con operadores';

  @override
  String get ruleHelpIntro =>
      'Escribe palabras como siempre, o añade operadores: todos deben cumplirse a la vez.';

  @override
  String get ruleHelpArtist =>
      'artist:\"pink floyd\" — canciones de un artista (basta una parte del nombre); igual con album:, genre:, folder:';

  @override
  String get ruleHelpYear =>
      'year:1990..1999 — un intervalo (también abierto: year:..1980, year:2000..); year>1990, year<=1985';

  @override
  String get ruleHelpDuration =>
      'duration>5m — duración (m minutos, s segundos): duration<90s, duration:2m..4m';

  @override
  String get ruleHelpAdded =>
      'added<30g — añadidas hace menos de 30 días (g días, sett semanas, mesi meses): added>6mesi';

  @override
  String get ruleHelpNot =>
      '-live — el signo menos excluye: -artist:floyd, -\"live at\"';

  @override
  String get ruleHelpOr =>
      'rock OR jazz — OR (en mayúsculas) entre dos términos: basta uno';

  @override
  String get ruleHelpFlags =>
      'favorites, never-played — solo favoritas, o canciones nunca escuchadas; plays>10 para las más escuchadas';

  @override
  String get ruleHelpOthers =>
      'tag:live, format:flac — una de tus etiquetas, o el formato del archivo (nombre completo, sin distinguir mayúsculas)';

  @override
  String get ruleHelpSmart =>
      'Las mismas reglas sirven para las listas inteligentes (Biblioteca → + → Nueva lista inteligente).';

  @override
  String get cleanupSection => 'Limpieza de la biblioteca';

  @override
  String get duplicatesTitle => 'Duplicados';

  @override
  String get duplicatesTileHint =>
      'La misma canción en varias copias o calidades';

  @override
  String get duplicatesIntro =>
      'Busca la misma canción en varias copias: el mismo archivo en dos carpetas o la misma canción en dos calidades. Antes de unir ves una vista previa. Favoritos, listas, reproducciones, letras y etiquetas pasan a la canción que conservas; las demás solo se ocultan y puedes recuperarlas desde «Canciones ocultas». Ningún archivo se borra sin una doble confirmación.';

  @override
  String get duplicatesSearch => 'Buscar duplicados';

  @override
  String get duplicatesSearchAgain => 'Buscar de nuevo';

  @override
  String get duplicatesReading => 'Leyendo la biblioteca…';

  @override
  String duplicatesHashing(int done, int total) {
    return 'Comprobando archivos: $done de $total';
  }

  @override
  String get duplicatesGrouping => 'Comparando canciones…';

  @override
  String get duplicatesFailed => 'La búsqueda ha fallado. Inténtalo de nuevo.';

  @override
  String get duplicatesNone => 'No se han encontrado duplicados';

  @override
  String duplicatesSummary(int groups, int hidden) {
    String _temp0 = intl.Intl.pluralLogic(
      groups,
      locale: localeName,
      other: '$groups grupos',
      one: '1 grupo',
    );
    String _temp1 = intl.Intl.pluralLogic(
      hidden,
      locale: localeName,
      other: '$hidden canciones por ocultar',
      one: '1 canción por ocultar',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get duplicatesExactBadge => 'Idénticos';

  @override
  String get duplicatesProbableBadge => 'Probables';

  @override
  String get duplicatesKeepLabel => 'Conservar';

  @override
  String get duplicatesPickKeep => 'Toca una canción para conservarla';

  @override
  String get duplicatesMerge => 'Unir';

  @override
  String get duplicatesNotDuplicates => 'No son duplicados';

  @override
  String duplicatesMergeAllExact(int count) {
    return 'Unir todos los idénticos ($count)';
  }

  @override
  String get duplicatesMergeAllTitle => '¿Unir todos los idénticos?';

  @override
  String duplicatesMergeAllBody(int groups, int hidden) {
    String _temp0 = intl.Intl.pluralLogic(
      groups,
      locale: localeName,
      other: '$groups grupos',
      one: '1 grupo',
    );
    String _temp1 = intl.Intl.pluralLogic(
      hidden,
      locale: localeName,
      other: '$hidden canciones ocultas',
      one: '1 canción oculta',
    );
    return '$_temp0, $_temp1. Favoritos, listas, reproducciones y letras pasan a las canciones que se quedan.';
  }

  @override
  String duplicatesMerged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count canciones ocultas',
      one: '1 canción oculta',
    );
    return 'Unido: $_temp0';
  }

  @override
  String duplicatesDeleteFiles(int count, String size) {
    return 'Eliminar también los archivos ($count, $size)';
  }

  @override
  String get duplicatesDeleteListTitle => '¿Eliminar estos archivos?';

  @override
  String get duplicatesDeleteListBody =>
      'Se borrarán del dispositivo y no se pueden recuperar. Las canciones que conservas se quedan donde están.';

  @override
  String get duplicatesDeleteContinue => 'Continuar';

  @override
  String duplicatesDeleteFinalTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '¿Eliminar definitivamente $count archivos?',
      one: '¿Eliminar definitivamente 1 archivo?',
    );
    return '$_temp0';
  }

  @override
  String duplicatesDeleteFinalBody(String size) {
    return 'Espacio liberado: $size. Esta acción no se puede deshacer.';
  }

  @override
  String get duplicatesDeleteGo => 'Eliminar definitivamente';

  @override
  String get duplicatesDeleteDoneTitle => 'Hecho';

  @override
  String duplicatesDeleteDone(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count archivos eliminados',
      one: '1 archivo eliminado',
    );
    return '$_temp0 ($size).';
  }

  @override
  String duplicatesDeleteFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count archivos no eliminados:',
      one: '1 archivo no eliminado:',
    );
    return '$_temp0';
  }

  @override
  String duplicatesDeleteSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count archivos sin tocar: son el mismo archivo que la canción conservada.',
      one:
          '1 archivo sin tocar: es el mismo archivo que la canción conservada.',
    );
    return '$_temp0';
  }

  @override
  String get duplicatesDeleteAndroidHint =>
      'En Android solo se pueden eliminar archivos de las carpetas a las que la app tiene acceso.';

  @override
  String activityCleanup(int done, int total) {
    return 'Buscando duplicados: $done de $total';
  }

  @override
  String get hiddenTracksTitle => 'Canciones ocultas';

  @override
  String hiddenTracksCount(int count) {
    return 'Canciones ocultas ($count)';
  }

  @override
  String get hiddenTracksEmpty => 'No hay canciones ocultas';

  @override
  String get hiddenTracksHint =>
      'Los duplicados unidos no aparecen en la biblioteca. «Restaurar» los devuelve a su sitio.';

  @override
  String get hiddenRestore => 'Restaurar';

  @override
  String hiddenRestored(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count canciones restauradas',
      one: '1 canción restaurada',
    );
    return '$_temp0';
  }

  @override
  String get albumMergeWith => 'Unir con…';

  @override
  String get albumMergeTitle => 'Unir álbumes';

  @override
  String albumMergeIntro(String name) {
    return 'Elige los álbumes que se unirán a «$name». Las canciones pasan a un solo álbum con el título y el artista que indiques; la portada sigue siendo la de «$name».';
  }

  @override
  String get albumMergeSearch => 'Buscar un álbum';

  @override
  String get albumMergeNone => 'No hay otros álbumes';

  @override
  String get albumFieldTitle => 'Título del álbum';

  @override
  String get albumFieldArtist => 'Artista del álbum';

  @override
  String get albumMergeAction => 'Unir álbumes';

  @override
  String albumMerged(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count álbumes unidos en «$name»',
      one: '1 álbum unido en «$name»',
    );
    return '$_temp0';
  }

  @override
  String get moveToAlbum => 'Mover a un álbum nuevo…';

  @override
  String get moveToAlbumTitle => 'Mover a un álbum';

  @override
  String moveToAlbumBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count canciones irán',
      one: '1 canción irá',
    );
    return '$_temp0 al álbum indicado. Si ya existe, se unirán a él.';
  }

  @override
  String get moveToAlbumGo => 'Mover';

  @override
  String movedToAlbum(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count canciones movidas a «$name»',
      one: '1 canción movida a «$name»',
    );
    return '$_temp0';
  }

  @override
  String get searchSourceYoutube => 'YouTube';

  @override
  String get searchSourceYoutubeMusic => 'YouTube Music';

  @override
  String get searchSourceSoundcloud => 'SoundCloud';

  @override
  String get importSoundCloud =>
      'Buscar también en SoundCloud si no se encuentra una canción';

  @override
  String get importSoundCloudHint =>
      'Solo para las filas de una importación que YouTube no encuentra: una búsqueda más por fila. Desactivado de serie.';

  @override
  String get ytHintSoundcloud => 'Buscar en SoundCloud';
}
