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
      'Solo para uso personal. Respeta los derechos de autor y los términos de YouTube.';

  @override
  String get useDefaultFolder => 'Usar la carpeta Música del dispositivo';

  @override
  String get ytErrToolMissing =>
      'yt-dlp no encontrado: instálalo (pip install -U yt-dlp) y reintenta';

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
}
