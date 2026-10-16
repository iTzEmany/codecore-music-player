// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appName => 'Codecore';

  @override
  String get chooseFolder => 'Escolher pasta';

  @override
  String get scan => 'Analisar';

  @override
  String get noTracks => 'Nenhuma faixa. Escolha uma pasta e analise.';

  @override
  String get openSettings => 'Abrir definições';

  @override
  String get permissionDenied => 'Permissão de leitura de áudio recusada';

  @override
  String get permissionExplain =>
      'O Codecore precisa de permissão para ler os ficheiros de áudio e mostrar a sua música.';

  @override
  String get navLibrary => 'Biblioteca';

  @override
  String get navFavorites => 'Favoritos';

  @override
  String get navPlaylists => 'Playlists';

  @override
  String get navSettings => 'Definições';

  @override
  String get tracks => 'Faixas';

  @override
  String get albums => 'Álbuns';

  @override
  String get artists => 'Artistas';

  @override
  String get searchHint => 'Pesquisar';

  @override
  String get sortBy => 'Ordenar por';

  @override
  String get addMusicFolder => 'Adicione a sua pasta de música';

  @override
  String get addFolder => 'Adicionar pasta';

  @override
  String get folders => 'Pastas de música';

  @override
  String get refreshLibrary => 'Atualizar biblioteca';

  @override
  String get removeFolder => 'Remover pasta';

  @override
  String get unknownArtist => 'Artista desconhecido';

  @override
  String get unknownAlbum => 'Álbum desconhecido';

  @override
  String get variousArtists => 'Vários artistas';

  @override
  String get play => 'Reproduzir';

  @override
  String get shuffle => 'Aleatório';

  @override
  String get queue => 'Fila';

  @override
  String get nowPlaying => 'A reproduzir';

  @override
  String get nothingPlaying => 'Nenhuma faixa a reproduzir';

  @override
  String get mute => 'Silenciar';

  @override
  String get scanning => 'A analisar…';

  @override
  String get emptyQueue => 'A fila está vazia';

  @override
  String get noResults => 'Sem resultados';

  @override
  String get sortDefault => 'Predefinido';

  @override
  String get sortTitle => 'Título';

  @override
  String get sortArtist => 'Artista';

  @override
  String get sortAlbum => 'Álbum';

  @override
  String get sortYear => 'Ano';

  @override
  String get sortAdded => 'Adicionados recentemente';

  @override
  String get sortDuration => 'Duração';

  @override
  String tracksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count faixas',
      one: '1 faixa',
    );
    return '$_temp0';
  }

  @override
  String albumsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count álbuns',
      one: '1 álbum',
    );
    return '$_temp0';
  }

  @override
  String missingTracksCount(int count) {
    return 'Faixas não encontradas ($count)';
  }

  @override
  String get addedToFavorites => 'Adicionada aos favoritos';

  @override
  String get removedFromFavorites => 'Removida dos favoritos';

  @override
  String get undo => 'Anular';

  @override
  String get noFavorites => 'Ainda sem favoritos';

  @override
  String get newPlaylist => 'Nova playlist';

  @override
  String get newPlaylistEllipsis => 'Nova playlist…';

  @override
  String get playlistName => 'Nome da playlist';

  @override
  String get create => 'Criar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Guardar';

  @override
  String get delete => 'Eliminar';

  @override
  String get rename => 'Mudar o nome';

  @override
  String get noPlaylists => 'Sem playlists. Crie uma.';

  @override
  String get addToPlaylist => 'Adicionar à playlist…';

  @override
  String addedToPlaylist(String name) {
    return 'Adicionada a «$name»';
  }

  @override
  String get playNext => 'Reproduzir a seguir';

  @override
  String get addToQueue => 'Adicionar à fila';

  @override
  String get addedToQueue => 'Adicionada à fila';

  @override
  String get favorite => 'Favorito';

  @override
  String get removeFromFavorites => 'Remover dos favoritos';

  @override
  String get removeFromList => 'Remover';

  @override
  String get editInfo => 'Editar info';

  @override
  String get details => 'Detalhes';

  @override
  String get showInFolder => 'Mostrar na pasta';

  @override
  String get detailPath => 'Caminho';

  @override
  String get detailFormat => 'Formato';

  @override
  String get detailSize => 'Tamanho';

  @override
  String get detailDuration => 'Duração';

  @override
  String get detailAdded => 'Adicionada em';

  @override
  String get detailPlays => 'Reproduções';

  @override
  String get close => 'Fechar';

  @override
  String get fieldTitle => 'Título';

  @override
  String get fieldArtist => 'Artista';

  @override
  String get fieldAlbum => 'Álbum';

  @override
  String get fieldAlbumArtist => 'Artista do álbum';

  @override
  String get fieldYear => 'Ano';

  @override
  String get fieldTrackNumber => 'Número da faixa';

  @override
  String get fieldGenre => 'Género';

  @override
  String get restoreFromFile => 'Restaurar a partir das tags do ficheiro';

  @override
  String get titleRequired => 'O título não pode estar vazio';

  @override
  String get settingsAppearance => 'Aspeto';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get themeNotte => 'Noite violeta';

  @override
  String get themeOled => 'Preto puro';

  @override
  String get settingsTextSize => 'Tamanho do texto';

  @override
  String get textSmall => 'Pequeno';

  @override
  String get textNormal => 'Normal';

  @override
  String get textLarge => 'Grande';

  @override
  String get settingsCompact => 'Modo compacto';

  @override
  String get settingsReducedMotion => 'Animações reduzidas';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsLibrary => 'Biblioteca';

  @override
  String get rescanNow => 'Analisar novamente';

  @override
  String get clearCoverCache => 'Limpar cache das capas';

  @override
  String get coverCacheCleared => 'Cache das capas limpa';

  @override
  String get settingsOnline => 'Online';

  @override
  String get autoEnrich => 'Enriquecimento automático';

  @override
  String get autoEnrichHint =>
      'Pesquisa metadados e capas online para as faixas novas';

  @override
  String get autoLyrics => 'Letras automáticas';

  @override
  String get autoLyricsHint =>
      'Descarrega as letras do LRCLIB para as faixas novas';

  @override
  String get settingsAbout => 'Acerca de';

  @override
  String appVersion(String version) {
    return 'Versão $version';
  }

  @override
  String get licenses => 'Licenças';

  @override
  String get personalUse => 'App para uso pessoal';

  @override
  String get missingTracksTitle => 'Faixas não encontradas';

  @override
  String get removeFromLibrary => 'Remover da biblioteca';

  @override
  String get ignore => 'Ignorar';

  @override
  String get confirmRemoveTitle => 'Remover da biblioteca?';

  @override
  String get confirmRemoveBody =>
      'O ficheiro não é alterado; perde os favoritos e as playlists desta faixa.';

  @override
  String get noMissingTracks => 'Nenhuma faixa em falta';

  @override
  String get retry => 'Tentar novamente';

  @override
  String scanFailed(String error) {
    return 'Falha na análise: $error';
  }

  @override
  String playbackError(String reason, String title) {
    return 'Não é possível reproduzir «$title»: $reason';
  }

  @override
  String get reasonFileMissing => 'ficheiro não encontrado';

  @override
  String get reasonUnplayable => 'ficheiro não reproduzível';

  @override
  String get reasonNotInLibrary => 'faixa não presente na biblioteca';

  @override
  String get searchWeb => 'Pesquisar info na web';

  @override
  String get enrichPreviewTitle => 'Pré-visualização das informações';

  @override
  String get currentValue => 'Atual';

  @override
  String get proposedValue => 'Proposto';

  @override
  String get apply => 'Aplicar';

  @override
  String get nothingFound => 'Nenhuma informação encontrada';

  @override
  String get userEditedLocked => 'Editado por si: não será substituído';

  @override
  String get fieldCover => 'Capa';

  @override
  String get fieldLyrics => 'Letra';

  @override
  String get fieldCuriosity => 'Curiosidades';

  @override
  String get enrichAlbum => 'Enriquecer álbum';

  @override
  String get enrichLibrary => 'Enriquecer toda a biblioteca';

  @override
  String get enrichConfirmTitle => 'Enriquecer a biblioteca?';

  @override
  String enrichConfirmBody(int count, int minutes) {
    return '$count faixas, cerca de $minutes minutos. Só os campos vazios são preenchidos.';
  }

  @override
  String enrichRunning(int done, int total) {
    return 'Enriquecimento $done/$total';
  }

  @override
  String enrichResult(int notFound, int updated) {
    return '$updated atualizadas, $notFound não encontradas';
  }

  @override
  String get enrichBusy => 'Já existe um enriquecimento em curso';

  @override
  String get serviceUnavailable =>
      'Serviço indisponível, tente novamente mais tarde';

  @override
  String get lyrics => 'Letra';

  @override
  String get searchLyrics => 'Pesquisar letra';

  @override
  String get noLyrics => 'Nenhuma letra disponível';

  @override
  String get lyricsNotFound => 'Letra não encontrada';

  @override
  String get copy => 'Copiar';

  @override
  String get copied => 'Copiado';

  @override
  String get sourceWikipedia => 'Fonte: Wikipédia (CC BY-SA)';

  @override
  String get youtube => 'YouTube';

  @override
  String get ytHint => 'Pesquise ou cole um link';

  @override
  String get ytDownload => 'Descarregar';

  @override
  String get ytAlreadyInLibrary => 'Já na biblioteca';

  @override
  String get ytNoResults => 'Sem resultados';

  @override
  String get ytQueued => 'Na fila';

  @override
  String get ytDownloading => 'A descarregar';

  @override
  String get ytDone => 'Concluído';

  @override
  String get ytFailed => 'Falhou';

  @override
  String get ytCancelled => 'Cancelado';

  @override
  String get ytClearCompleted => 'Limpar concluídos';

  @override
  String get ytCancel => 'Cancelar transferência';

  @override
  String get ytErrUnavailable => 'Vídeo indisponível (idade/região/privado)';

  @override
  String get ytErrNetwork => 'Rede indisponível';

  @override
  String get ytErrChanged =>
      'O YouTube mudou alguma coisa: atualize a app ou o pacote';

  @override
  String get ytNoFolder => 'Adicione primeiro uma pasta de música';

  @override
  String get ytLegal =>
      'Apenas para uso pessoal. Respeite os direitos de autor e os termos do YouTube.';

  @override
  String get useDefaultFolder => 'Usar a pasta Música do dispositivo';

  @override
  String get ytErrToolMissing =>
      'yt-dlp não encontrado: instale-o (pip install -U yt-dlp) e tente novamente';

  @override
  String get ytErrRateLimited =>
      'O YouTube pediu para abrandar: tente novamente dentro de alguns minutos';

  @override
  String get playlistChangeCover => 'Alterar capa';

  @override
  String get playlistRemoveCover => 'Remover capa';

  @override
  String get coverTooLarge => 'Imagem demasiado grande (máx. 4 MB)';

  @override
  String get addSongs => 'Adicionar faixas';

  @override
  String addNSongs(int count) {
    return 'Adicionar ($count)';
  }

  @override
  String get allSongsInPlaylist => 'Todas as faixas já estão na playlist';

  @override
  String get shareTitle => 'Partilha';

  @override
  String get shareSend => 'Enviar';

  @override
  String get shareReceive => 'Receber';

  @override
  String get shareAll => 'Toda a biblioteca';

  @override
  String shareSelection(int count) {
    return 'Seleção ($count faixas)';
  }

  @override
  String get sharePick => 'Escolher faixas';

  @override
  String get shareStart => 'Iniciar partilha';

  @override
  String get shareStop => 'Parar';

  @override
  String get shareActive => 'Partilha ativa';

  @override
  String get shareAddress => 'Endereço (IP:porta)';

  @override
  String get sharePin => 'PIN';

  @override
  String get shareConnect => 'Ligar';

  @override
  String shareDownloadSelected(int count) {
    return 'Descarregar selecionadas ($count)';
  }

  @override
  String shareProgress(int done, int total) {
    return 'Faixa $done de $total';
  }

  @override
  String shareDone(int count) {
    return '$count faixas recebidas';
  }

  @override
  String shareConnectedTo(String name) {
    return 'Ligado a $name';
  }

  @override
  String get shareErrUnreachable =>
      'Dispositivo inacessível: verifique o endereço e o Wi‑Fi';

  @override
  String get shareErrPin => 'PIN incorreto';

  @override
  String get shareErrBlocked =>
      'Demasiadas tentativas: tente novamente dentro de um minuto';

  @override
  String get shareErrNotCodecore => 'Não é um dispositivo Codecore';

  @override
  String get shareErrFailed => 'Falha na transferência';

  @override
  String get shareNoNetwork => 'Nenhuma rede local encontrada';

  @override
  String get shareFirewall =>
      'O Windows pode pedir autorização da firewall na primeira partilha.';

  @override
  String get shareHint =>
      'Na mesma rede Wi‑Fi, abra «Receber» no outro dispositivo e introduza o endereço e o PIN.';

  @override
  String get shareMenu => 'Partilhar…';

  @override
  String get shareDeviceName => 'Nome do dispositivo';

  @override
  String get importOld => 'Importar da app antiga';

  @override
  String get importOldHint => 'Escolha o codecore_library.db da versão Python';

  @override
  String importSummary(
    int favorites,
    int lyrics,
    int playlists,
    int unmatched,
  ) {
    return '$favorites favoritos, $playlists playlists, $lyrics letras importadas, $unmatched sem correspondência';
  }

  @override
  String get importFailed => 'Falha na importação: ficheiro inválido';

  @override
  String get sleepTimer => 'Temporizador de repouso';

  @override
  String sleepMinutes(int count) {
    return '$count minutos';
  }

  @override
  String get sleepEndOfTrack => 'No fim da faixa';

  @override
  String get sleepCancel => 'Cancelar temporizador';

  @override
  String get pause => 'Pausa';

  @override
  String get nextTrack => 'Faixa seguinte';

  @override
  String get previousTrack => 'Faixa anterior';

  @override
  String get repeat => 'Repetir';

  @override
  String get moreOptions => 'Mais opções';

  @override
  String get back => 'Voltar';

  @override
  String get settingsPlayback => 'Reprodução';

  @override
  String get normalizeVolume => 'Normalizar volume';

  @override
  String get normalizeVolumeHint =>
      'Usa o ReplayGain dos ficheiros para reduzir as faixas demasiado altas';

  @override
  String get nearbyDevices => 'Dispositivos próximos';

  @override
  String get searchingDevices => 'A procurar dispositivos na rede…';

  @override
  String get noDevicesHint =>
      'Nenhum dispositivo encontrado. Abra também a Partilha no outro dispositivo, na mesma rede.';

  @override
  String sendToDevice(String name) {
    return 'Enviar para $name';
  }

  @override
  String offerSent(String name) {
    return 'Pedido enviado a $name';
  }

  @override
  String get offerChooseFirst => 'Escolha primeiro as faixas a enviar';

  @override
  String get sentRequests => 'Pedidos enviados';

  @override
  String get receivedRequests => 'Pedidos recebidos';

  @override
  String get offerPending => 'A aguardar resposta';

  @override
  String get offerAccepted => 'Aceite';

  @override
  String get offerDeclined => 'Recusada';

  @override
  String get offerCancelled => 'Cancelada';

  @override
  String get offerExpired => 'Expirada';

  @override
  String get offerDone => 'Concluída';

  @override
  String get offerFailed => 'Falhada';

  @override
  String incomingTitle(String name) {
    return '$name quer enviar-lhe faixas';
  }

  @override
  String incomingBody(int count, String size) {
    return '$count faixas, $size MB';
  }

  @override
  String get accept => 'Aceitar';

  @override
  String get decline => 'Recusar';

  @override
  String receivingProgress(int done, int total) {
    return 'A receber $done/$total';
  }

  @override
  String get manualConnection => 'Ligação manual (IP e PIN)';

  @override
  String get receiveFromLan => 'Receber da rede local';

  @override
  String get receiveFromLanHint =>
      'Torna o dispositivo visível e recebe pedidos mesmo em segundo plano. No Android mostra uma notificação fixa com a qual pode desativá-lo';

  @override
  String get receiveServiceTitle => 'O Codecore está visível na rede';

  @override
  String get receiveServiceText =>
      'Pronto para receber faixas de dispositivos próximos';

  @override
  String get receiveServiceDisable => 'Desativar';

  @override
  String get jamTitle => 'Jam';

  @override
  String get jamStart => 'Iniciar uma Jam';

  @override
  String jamStartWith(String name) {
    return 'Iniciar Jam com $name';
  }

  @override
  String jamWaiting(String name) {
    return 'A aguardar que $name aceite…';
  }

  @override
  String jamDeclined(String name) {
    return '$name recusou a Jam';
  }

  @override
  String jamBusy(String name) {
    return '$name já tem uma Jam em curso';
  }

  @override
  String get jamUnreachable => 'Dispositivo inacessível';

  @override
  String jamIncomingTitle(String name) {
    return '$name quer iniciar uma Jam';
  }

  @override
  String get jamIncomingBody => 'Ouçam juntos a partir de uma fila partilhada.';

  @override
  String jamIncomingDialog(String name) {
    return '$name quer iniciar uma Jam consigo. A música toca neste dispositivo e ambos podem adicionar faixas.';
  }

  @override
  String get jamQueue => 'Fila partilhada';

  @override
  String get jamEmpty => 'A fila está vazia. Adicione faixas.';

  @override
  String jamAddedBy(String name) {
    return 'adicionada por $name';
  }

  @override
  String get jamYou => 'si';

  @override
  String get jamAddTracks => 'Adicionar faixas';

  @override
  String get jamAddToJam => 'Adicionar à Jam';

  @override
  String jamAdded(int count) {
    return 'Adicionadas à Jam: $count';
  }

  @override
  String get jamOutput => 'Saída de áudio';

  @override
  String get jamOutputHere => 'Este dispositivo';

  @override
  String jamOutputOther(String name) {
    return '$name';
  }

  @override
  String get jamEnd => 'Terminar Jam';

  @override
  String get jamLeave => 'Sair da Jam';

  @override
  String get jamEnded => 'A Jam terminou';

  @override
  String get jamLost => 'Ligação perdida';

  @override
  String get jamGuestCannotSkip => 'Só quem iniciou a Jam pode mudar de faixa';

  @override
  String get jamRemoveForbidden => 'Só pode remover as suas faixas';

  @override
  String get jamNowPlaying => 'A reproduzir';

  @override
  String get jamNothingPlaying => 'Nada a reproduzir';

  @override
  String jamWith(String name) {
    return 'Jam com $name';
  }

  @override
  String get jamUnavailable => 'Indisponível';

  @override
  String get jamPlaying => 'A Jam está ativa';

  @override
  String get jamOpen => 'Abrir a Jam';

  @override
  String jamSynced(int ms) {
    return 'Sincronizado · desvio $ms ms';
  }

  @override
  String get jamSyncing => 'A sincronizar…';

  @override
  String jamLatency(int ms) {
    return 'Latência desta saída: $ms ms';
  }

  @override
  String get jamLatencyHint =>
      'Para auscultadores ou colunas Bluetooth: aumente até as saídas soarem em sincronia.';

  @override
  String get jamOutputsHint => 'Várias saídas tocam em simultâneo';

  @override
  String get renamePlaylist => 'Mudar o nome da playlist';

  @override
  String get confirmDeletePlaylistTitle => 'Eliminar a playlist?';

  @override
  String confirmDeletePlaylistBody(String name) {
    return '«$name» será eliminada. As faixas permanecem na biblioteca.';
  }

  @override
  String get confirmRemoveFolderTitle => 'Remover a pasta?';

  @override
  String get confirmRemoveFolderBody =>
      'As faixas desta pasta desaparecem da biblioteca. Os ficheiros permanecem no dispositivo.';

  @override
  String get confirmClearCoversTitle => 'Limpar a cache das capas?';

  @override
  String get confirmClearCoversBody =>
      'As capas serão recriadas na próxima análise.';

  @override
  String get confirmRestoreTitle => 'Restaurar a partir das tags do ficheiro?';

  @override
  String get confirmRestoreBody =>
      'As suas alterações a esta faixa serão substituídas pelos dados do ficheiro.';

  @override
  String get removedFromPlaylist => 'Removida da playlist';

  @override
  String get removedFromQueue => 'Removida da fila';

  @override
  String get playNextDone => 'Será reproduzida a seguir';

  @override
  String get ytSearchPrompt => 'Pesquise uma faixa ou cole um link';

  @override
  String get loadFailed => 'Não foi possível carregar os dados.';

  @override
  String get navHome => 'Início';

  @override
  String get navSearch => 'Pesquisar';

  @override
  String get devicesTitle => 'Dispositivos';

  @override
  String get devicesJamActive => 'Jam ativa';

  @override
  String jamPeople(int n) {
    return 'Jam · $n pessoas';
  }

  @override
  String get devicesVisibleTitle => 'Tornar este dispositivo visível';

  @override
  String get devicesVisibleHint =>
      'Para receber faixas ou fazer uma Jam, os outros dispositivos têm de o poder ver na rede.';

  @override
  String get devicesJamShort => 'Jam';

  @override
  String get devicesSendShort => 'Enviar';

  @override
  String get devicesMore => 'Partilha e ligação manual';

  @override
  String jamParticipantsCount(int n) {
    return '$n pessoas';
  }

  @override
  String get playingFrom => 'A reproduzir de';

  @override
  String get playContextSearch => 'Pesquisa';

  @override
  String get allTracks => 'Todas as faixas';

  @override
  String get trackInfo => 'Informações da faixa';

  @override
  String get searchCuriosity => 'Pesquisar curiosidades';

  @override
  String get upNext => 'A seguir';

  @override
  String get openQueue => 'Abrir fila';

  @override
  String get copyLink => 'Copiar link';

  @override
  String get moreActions => 'Mais ações';

  @override
  String get sleepChipEnd => 'fim da faixa';

  @override
  String get yourLibrary => 'A sua biblioteca';

  @override
  String playlistCountLabel(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Playlist · $n faixas',
      one: 'Playlist · 1 faixa',
    );
    return '$_temp0';
  }

  @override
  String get sortRecent => 'Recentes';

  @override
  String get sortAlphabetical => 'Alfabética';

  @override
  String get sortAddedRecently => 'Adicionados recentemente';

  @override
  String get viewAsGrid => 'Ver em grelha';

  @override
  String get viewAsList => 'Ver em lista';

  @override
  String get kindAlbum => 'Álbum';

  @override
  String get kindArtist => 'Artista';

  @override
  String get kindPlaylist => 'Playlist';

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
  String get mostPlayed => 'Mais ouvidos';

  @override
  String get albumsSection => 'Álbuns';

  @override
  String artistMeta(String albums, String tracks) {
    return '$albums · $tracks';
  }

  @override
  String get addAllToQueue => 'Adicionar à fila';

  @override
  String addedNToQueue(int n) {
    return '$n faixas adicionadas à fila';
  }

  @override
  String get editOrder => 'Editar ordem';

  @override
  String get finishEditing => 'Concluir';

  @override
  String get removeFromPlaylistAction => 'Remover da playlist';

  @override
  String get noTracksInPlaylist => 'Esta playlist está vazia';

  @override
  String get greetingMorning => 'Bom dia';

  @override
  String get greetingAfternoon => 'Boa tarde';

  @override
  String get greetingEvening => 'Boa noite';

  @override
  String get homeResume => 'Retomar';

  @override
  String get homeRecentlyPlayed => 'Ouvidos recentemente';

  @override
  String get homeRecentlyAdded => 'Adicionados recentemente';

  @override
  String get homeTopTracks => 'Os mais ouvidos';

  @override
  String get homeRediscover => 'Para redescobrir';

  @override
  String get searchMainResult => 'Resultado principal';

  @override
  String get showAll => 'Mostrar todos';

  @override
  String searchOnYoutube(String query) {
    return 'Pesquisar «$query» no YouTube';
  }

  @override
  String get recentSearches => 'Pesquisas recentes';

  @override
  String get genresTitle => 'Géneros';

  @override
  String downloadsChip(int n) {
    return 'Transferências ($n)';
  }

  @override
  String get gotIt => 'Entendido';

  @override
  String get searchEmptyLibrary => 'Nenhum resultado na biblioteca';

  @override
  String get ytInfoTooltip => 'Informações sobre a utilização';

  @override
  String get removeRecentSearch => 'Remover das pesquisas recentes';

  @override
  String get groupGoTo => 'Ir para';

  @override
  String get goToAlbum => 'Ir para o álbum';

  @override
  String get goToArtist => 'Ir para o artista';

  @override
  String get groupQueue => 'Fila';

  @override
  String get groupCollection => 'Coleção';

  @override
  String get groupEdit => 'Editar';

  @override
  String get groupOther => 'Outros';

  @override
  String get queueNowPlaying => 'A reproduzir';

  @override
  String get queueNext => 'A seguir';

  @override
  String get queueClear => 'Limpar';

  @override
  String get queueCleared => 'Fila limpa';

  @override
  String get jamOutputsAndSync => 'Saídas e sincronização';

  @override
  String get jamHostTag => 'anfitrião';

  @override
  String get jamWaitingEmpty => 'Nenhuma Jam em curso';

  @override
  String get activityTitle => 'Atividade';

  @override
  String activityScan(int done, int total) {
    return 'Análise · $done/$total';
  }

  @override
  String get activityScanIdle => 'Análise em curso';

  @override
  String activityEnrich(int done, int total) {
    return 'Enriquecimento · $done/$total';
  }

  @override
  String activityDownload(String title) {
    return 'Transferência · $title';
  }

  @override
  String activityTransfer(String name, int n) {
    return 'Envio para $name · $n faixas';
  }

  @override
  String get activityNone => 'Nenhuma atividade';

  @override
  String get activityCompleted => 'Concluídas';

  @override
  String get activityClear => 'Limpar';

  @override
  String activityRunning(int n) {
    return '$n atividades em curso';
  }

  @override
  String get settingsLocalNetwork => 'Rede local';

  @override
  String get removeAll => 'Remover todas';

  @override
  String get confirmRemoveAllTitle => 'Remover todas da biblioteca?';

  @override
  String confirmRemoveAllBody(int n) {
    return '$n faixas não encontradas serão removidas da biblioteca. Os ficheiros não são alterados; perde os favoritos e as playlists destas faixas.';
  }

  @override
  String get csvImportMenu => 'Importar do Exportify (CSV)';

  @override
  String get csvImportIntroTitle => 'Importar uma playlist';

  @override
  String get csvImportIntroSource =>
      'O ficheiro CSV é criado gratuitamente no site do Exportify — exportify.net (não é necessária nenhuma app).';

  @override
  String get csvImportStep1 =>
      'Abra https://exportify.net no navegador (também a partir do telemóvel).';

  @override
  String get csvImportStep2 =>
      'Toque em «Get Started» e inicie sessão com a sua conta Spotify.';

  @override
  String get csvImportStep3 =>
      'Junto à playlist pretendida, toque em «Export»: é descarregado um ficheiro .csv com o nome da playlist.';

  @override
  String get csvImportStep4 => 'Volte aqui e toque em «Escolher ficheiro CSV».';

  @override
  String get csvImportNote =>
      'O Codecore procura as faixas na sua biblioteca e descarrega as restantes do YouTube Music.';

  @override
  String get csvImportNoteOffline =>
      'Só serão associadas as faixas que já estão na sua biblioteca.';

  @override
  String get csvImportCopy => 'Copiar endereço';

  @override
  String get csvImportCopied => 'Endereço copiado';

  @override
  String get csvImportPick => 'Escolher ficheiro';

  @override
  String get csvImportNotExportify =>
      'Formato não reconhecido. Escolha um CSV (Exportify, TuneMyMusic, Soundiiz, Last.fm) ou uma playlist M3U/M3U8/XSPF.';

  @override
  String get csvImportReadFailed => 'Não foi possível ler o ficheiro.';

  @override
  String get csvImportPreviewTitle => 'Importar playlist';

  @override
  String get csvImportName => 'Nome da playlist';

  @override
  String csvImportSummary(int total, int known, int todo) {
    return '$total faixas · $known já na biblioteca · $todo por descarregar';
  }

  @override
  String csvImportSkipped(int n) {
    return '$n linhas ignoradas (podcasts ou ficheiros locais)';
  }

  @override
  String csvImportEstimate(int minutes) {
    return 'Tempo estimado: cerca de $minutes min';
  }

  @override
  String get csvImportExists => 'Já existe uma playlist com este nome';

  @override
  String get csvImportUpdate =>
      'Atualizar a existente (adiciona apenas as faixas novas)';

  @override
  String get csvImportNew => 'Criar uma nova playlist';

  @override
  String get csvImportGo => 'Importar';

  @override
  String get csvImportStarted =>
      'Importação iniciada: acompanhe-a no Centro de Atividades';

  @override
  String activityImport(String name, int done, int total) {
    return 'Importação «$name» · $done/$total';
  }

  @override
  String activityImportPaused(String name, int done, int total) {
    return 'Importação «$name» · em pausa · $done/$total';
  }

  @override
  String csvImportBanner(int done, int total, int review, int missing) {
    return 'Importação: $done/$total · $review por verificar · $missing não encontradas';
  }

  @override
  String csvImportBannerPaused(int done, int total, int review, int missing) {
    return 'Importação em pausa: $done/$total · $review por verificar · $missing não encontradas';
  }

  @override
  String get csvImportReview => 'Rever';

  @override
  String get csvImportResume => 'Retomar';

  @override
  String get csvImportPause => 'Pausa';

  @override
  String get csvImportCancelTitle => 'Cancelar a importação?';

  @override
  String get csvImportCancelBody =>
      'As faixas já descarregadas permanecem na playlist.';

  @override
  String csvImportDone(int added, int review, int missing) {
    return 'Importação concluída: $added adicionadas, $review por verificar, $missing não encontradas';
  }

  @override
  String get csvImportFailing =>
      'Demasiados erros seguidos: importação em pausa';

  @override
  String get csvImportReviewTitle => 'Rever';

  @override
  String get csvImportToReview => 'Por verificar';

  @override
  String get csvImportNotFound => 'Não encontradas';

  @override
  String get csvImportErrors => 'Com erros';

  @override
  String get csvImportRetryAll => 'Tentar todas novamente';

  @override
  String get csvImportSkip => 'Saltar';

  @override
  String get csvImportManual => 'Pesquisar manualmente';

  @override
  String get csvImportNothing => 'Nada para rever.';

  @override
  String get csvImportSearch => 'Pesquisar';

  @override
  String csvImportWanted(String title, String artist, String duration) {
    return 'Procurada: $title · $artist · $duration';
  }

  @override
  String get csvImportDownload => 'Descarregar';

  @override
  String get csvImportCancelGo => 'Cancelar importação';

  @override
  String get exportLog => 'Exportar registo';

  @override
  String get exportLogHint =>
      'Ficheiro de texto sem caminhos pessoais, endereços de rede nem PIN';

  @override
  String get exportLogDebugOnly =>
      'Disponível apenas na versão instalada (em debug o registo não é gravado em ficheiro)';

  @override
  String get exportLogNone => 'Ainda não há nenhum registo para exportar';

  @override
  String get exportLogSaved => 'Registo guardado';

  @override
  String get exportLogFailed => 'Não foi possível guardar o registo';

  @override
  String get exportPlaylist => 'Exportar…';

  @override
  String get exportPlaylistTitle => 'Exportar playlist';

  @override
  String get exportFormatM3u8 => 'M3U8 · para outros leitores';

  @override
  String get exportFormatCsv => 'CSV · como o Exportify';

  @override
  String get exportFormatJson => 'JSON · formato Codecore';

  @override
  String get exportRelativePaths => 'Caminhos relativos';

  @override
  String get exportRelativeHint =>
      'Relativos à pasta comum das faixas: guarde o ficheiro aí';

  @override
  String get exportAction => 'Exportar';

  @override
  String get exportSaved => 'Playlist exportada';

  @override
  String get exportEmpty => 'A playlist está vazia';

  @override
  String get exportFailed => 'Não foi possível exportar a playlist';

  @override
  String get ytErrToolOutdated =>
      'O yt-dlp é demasiado antigo: atualize-o (Definições → Transferências → Atualizar) e tente novamente';

  @override
  String ytDlpOutdatedBanner(String version) {
    return 'O yt-dlp $version é demasiado antigo: as transferências podem não funcionar';
  }

  @override
  String get settingsDownloads => 'Transferências';

  @override
  String ytDlpVersion(String version) {
    return 'yt-dlp $version';
  }

  @override
  String get ytDlpUnknownVersion => 'yt-dlp não encontrado';

  @override
  String get ytDlpUpdate => 'Atualizar';

  @override
  String ytDlpUpdating(int percent) {
    return 'A atualizar… $percent%';
  }

  @override
  String ytDlpUpdated(String version) {
    return 'Atualizado para a versão $version';
  }

  @override
  String get ytDlpTooOld => 'Demasiado antigo: toque em Atualizar';

  @override
  String get ytDlpUpdateErrNetwork => 'Falha na atualização: rede inacessível';

  @override
  String get ytDlpUpdateErrHash =>
      'Atualização cancelada: o ficheiro descarregado não passou a verificação de integridade';

  @override
  String get ytDlpUpdateErrOther =>
      'Falha na atualização (detalhes no registo)';

  @override
  String get downloadParallel => 'Transferências em simultâneo';

  @override
  String get downloadParallelHint =>
      'Mais em simultâneo é mais rápido, mas o YouTube pode pedir para abrandar';

  @override
  String get downloadRateLimit => 'Limite de velocidade';

  @override
  String get downloadRateNone => 'Nenhum';

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
    return 'Transferência · $title · nova tentativa em $seconds s ($attempt/$max)';
  }

  @override
  String get downloadOriginal => 'Qualidade original (sem recodificação)';

  @override
  String get downloadOriginalHint =>
      'Mantém o áudio do YouTube tal como está (M4A/Opus): sem perdas, ficheiros mais pequenos. Desativado: MP3 256 kbps';

  @override
  String get searchCacheClear => 'Limpar cache de pesquisas';

  @override
  String searchCacheCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pesquisas guardadas',
      one: '1 pesquisa guardada',
      zero: 'Vazia',
    );
    return '$_temp0';
  }

  @override
  String get searchCacheCleared => 'Cache limpa';

  @override
  String csvImportLengthOff(String found, String wanted) {
    return 'Duração diferente: $found em vez de $wanted';
  }

  @override
  String get csvImportKeep => 'Manter esta';

  @override
  String get csvImportTooBig =>
      'O ficheiro é demasiado grande para ser uma playlist (máximo 5 MB e 10 000 faixas)';

  @override
  String get csvImportAlsoAccepts =>
      'Aceita também: TuneMyMusic, Soundiiz, Last.fm (CSV), M3U/M3U8, XSPF.';

  @override
  String get csvImportPlanned =>
      'Correspondências prontas: verifique-as e descarregue';

  @override
  String get csvImportLinkOnly => 'Só associar (sem transferências)';

  @override
  String get csvImportLinkOnlyHint =>
      'Cria a playlist com o que já tem e mais nada';

  @override
  String get csvImportPlanFirst => 'Rever antes de descarregar';

  @override
  String get csvImportPlanFirstHint =>
      'Procura tudo e depois escolha o que descarregar';

  @override
  String get csvImportPlanTitle => 'Correspondências';

  @override
  String csvImportPlanGo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Descarregar $n faixas',
      one: 'Descarregar 1 faixa',
    );
    return '$_temp0';
  }

  @override
  String get csvImportPlanKnown => 'já descarregada';

  @override
  String get csvImportPlanEmpty => 'Nada para descarregar';

  @override
  String csvImportBannerPlanned(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n faixas por descarregar',
      one: '1 faixa por descarregar',
    );
    return 'Correspondências prontas: $_temp0';
  }

  @override
  String get settingsAdvanced => 'Avançadas';

  @override
  String get importSureThreshold => 'Correspondência segura a partir de';

  @override
  String get importSureThresholdHint =>
      'Acima desta pontuação, uma faixa da importação é descarregada sem perguntar';

  @override
  String get importReviewThreshold => 'Por verificar a partir de';

  @override
  String get importReviewThresholdHint =>
      'Entre esta pontuação e a segura, a faixa vai para «Por verificar»; abaixo, para «Não encontradas»';

  @override
  String get importThresholdsReset => 'Repor os valores predefinidos';

  @override
  String csvImportEstimateHours(int hours, int minutes) {
    return 'Tempo estimado: cerca de $hours h $minutes min';
  }

  @override
  String csvImportBlocks(int size) {
    return 'Importar em blocos de $size';
  }

  @override
  String csvImportBigWarning(int n) {
    return 'São $n faixas a descarregar: vai demorar horas. Em blocos, um a seguir ao outro, a ordem da playlist mantém-se correta e pode parar entre blocos.';
  }

  @override
  String get etaLessThanMinute => 'menos de 1 min';

  @override
  String etaMinutes(int minutes) {
    return 'cerca de $minutes min';
  }

  @override
  String etaHours(int hours, int minutes) {
    return 'cerca de $hours h $minutes min';
  }

  @override
  String get csvImportOwnFolder => 'Pasta para esta playlist';

  @override
  String get csvImportOwnFolderHint =>
      'Guarda as faixas descarregadas numa subpasta com o nome da playlist';

  @override
  String get csvImportNumberFiles => 'Numerar os ficheiros';

  @override
  String get csvImportNumberFilesHint =>
      '07 - Artista - Título: a pasta ouve-se na ordem certa mesmo fora do Codecore';

  @override
  String get csvImportFetchCovers => 'Procurar as capas';

  @override
  String get csvImportFetchCoversHint =>
      'Após cada transferência, procura a capa do álbum no iTunes (álbum e artista do ficheiro)';

  @override
  String get csvImportExport => 'Exportar resultado';

  @override
  String get csvImportExported => 'Resultado guardado';

  @override
  String get csvOutHeaderRow => 'Linha';

  @override
  String get csvOutHeaderTitle => 'Título';

  @override
  String get csvOutHeaderArtists => 'Artistas';

  @override
  String get csvOutHeaderAlbum => 'Álbum';

  @override
  String get csvOutHeaderDuration => 'Duração (ms)';

  @override
  String get csvOutHeaderIsrc => 'ISRC';

  @override
  String get csvOutHeaderStatus => 'Resultado';

  @override
  String get csvOutHeaderNote => 'Motivo';

  @override
  String get csvOutHeaderVideo => 'Vídeo escolhido';

  @override
  String get csvOutHeaderScore => 'Pontuação';

  @override
  String get importStatusPending => 'Por procurar';

  @override
  String get importStatusQueued => 'Na fila';

  @override
  String get importStatusDownloaded => 'Descarregada';

  @override
  String get importStatusLinked => 'Já na biblioteca';

  @override
  String get importStatusReview => 'Por verificar';

  @override
  String get importStatusNotFound => 'Não encontrada';

  @override
  String get importStatusFailed => 'Erro';

  @override
  String get importStatusSkipped => 'Saltada';

  @override
  String get importStatusPlanned => 'Planeada';

  @override
  String get importStatusRemoved => 'Removida da origem';

  @override
  String get importNoteNoResults => 'Sem resultados';

  @override
  String get importNoteLowScore => 'Correspondência pouco segura';

  @override
  String get importNoteLinkOnly => 'Só associação: não pesquisada';

  @override
  String get importNoteYoutubeOff => 'Transferências desativadas';

  @override
  String get importNoteDownloadFailed => 'Falha ao descarregar';

  @override
  String get importNoteLengthOff => 'Duração diferente da do ficheiro';

  @override
  String get importNoteUnchanged => 'Já está na playlist';

  @override
  String get csvImportSync => 'Sincronizar';

  @override
  String csvImportSyncCounts(int added, int removed) {
    return '+$added novas · −$removed removidas da playlist (os ficheiros permanecem)';
  }

  @override
  String get csvImportSyncChecking => 'A verificar as diferenças…';

  @override
  String get playbackSpeed => 'Velocidade de reprodução';

  @override
  String get playbackSpeedHint =>
      'O tom mantém-se o original. O temporizador de repouso conta o tempo real, não o da faixa.';

  @override
  String resumeFrom(String time) {
    return 'retomar em $time';
  }

  @override
  String get restartFromBeginning => 'Recomeçar do início';

  @override
  String get previewTrack => 'Pré-visualização de 20 s';

  @override
  String get equalizer => 'Equalizador';

  @override
  String get eqOutputSpeaker => 'Altifalante';

  @override
  String get eqOutputHeadphones => 'Auscultadores';

  @override
  String get eqHint =>
      'Cada saída memoriza a sua curva: muda sozinha quando liga os auscultadores.';

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
  String get eqReset => 'Repor';

  @override
  String get eqWaiting => 'As bandas aparecem quando a primeira faixa começa.';

  @override
  String get eqUnavailable =>
      'O equalizador não está disponível neste dispositivo.';

  @override
  String get transitionMode => 'Transição entre faixas';

  @override
  String get transitionNormal => 'Normal';

  @override
  String get transitionGapless => 'Sem pausas';

  @override
  String get transitionCrossfade => 'Fusão cruzada';

  @override
  String get transitionHint =>
      'Sem pausas funciona melhor com faixas do mesmo formato (por exemplo, todas FLAC).';

  @override
  String crossfadeLength(int seconds) {
    return 'Duração da fusão: $seconds s';
  }

  @override
  String get crossfadePlainInAlbum => 'Sem fusão dentro do mesmo álbum';

  @override
  String get crossfadePlainInAlbumHint =>
      'Dentro de um álbum as faixas seguem-se sem pausas e sem se sobreporem.';

  @override
  String get selectedRow => 'Selecionado';

  @override
  String selectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selecionados',
      one: '1 selecionado',
    );
    return '$_temp0';
  }

  @override
  String get selectAll => 'Selecionar tudo';

  @override
  String get exitSelection => 'Sair da seleção';

  @override
  String get bulkActions => 'Ações';

  @override
  String playNextMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count faixas serão reproduzidas a seguir',
      one: '1 faixa será reproduzida a seguir',
    );
    return '$_temp0';
  }

  @override
  String addedToQueueMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count faixas adicionadas à fila',
      one: '1 faixa adicionada à fila',
    );
    return '$_temp0';
  }

  @override
  String addedToPlaylistMany(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count faixas adicionadas a «$name»',
      one: '1 faixa adicionada a «$name»',
    );
    return '$_temp0';
  }

  @override
  String addedToPlaylistSkipped(int added, int skipped, String name) {
    return '$added adicionadas a «$name», $skipped já presentes';
  }

  @override
  String allAlreadyInPlaylist(String name) {
    return 'Já estavam todas em «$name»';
  }

  @override
  String favoritesAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count faixas nos favoritos',
      one: '1 faixa nos favoritos',
    );
    return '$_temp0';
  }

  @override
  String favoritesRemoved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count faixas removidas dos favoritos',
      one: '1 faixa removida dos favoritos',
    );
    return '$_temp0';
  }

  @override
  String get bulkAddToFavorites => 'Adicionar aos favoritos';

  @override
  String get bulkRemoveFromFavorites => 'Remover dos favoritos';

  @override
  String removeManyFromPlaylistTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Remover $count faixas da playlist?',
      one: 'Remover 1 faixa da playlist?',
    );
    return '$_temp0';
  }

  @override
  String get removeManyFromPlaylistBody =>
      'Os ficheiros e a biblioteca não são alterados.';

  @override
  String removedManyFromPlaylist(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count faixas removidas',
      one: '1 faixa removida',
    );
    return '$_temp0';
  }

  @override
  String removeManyFromLibraryTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Remover $count faixas da biblioteca?',
      one: 'Remover 1 faixa da biblioteca?',
    );
    return '$_temp0';
  }

  @override
  String get removeManyFromLibraryBody =>
      'Os ficheiros já não existem: desaparecem apenas da biblioteca (perde os favoritos e as playlists destas faixas).';

  @override
  String removedManyFromLibrary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count faixas removidas da biblioteca',
      one: '1 faixa removida da biblioteca',
    );
    return '$_temp0';
  }

  @override
  String ytDownloadsStarted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transferências iniciadas',
      one: '1 transferência iniciada',
    );
    return '$_temp0';
  }

  @override
  String ytDownloadsSkipped(int started, int skipped) {
    return '$started transferências iniciadas, $skipped já na biblioteca ou em curso';
  }

  @override
  String get ytNothingToDownload => 'Já estão todas na biblioteca ou em curso';

  @override
  String get themeChiaro => 'Claro';

  @override
  String get settingsAccent => 'Cor de destaque';

  @override
  String get accentViola => 'Violeta';

  @override
  String get accentBlu => 'Azul';

  @override
  String get accentAcqua => 'Verde-água';

  @override
  String get accentVerde => 'Verde';

  @override
  String get accentAmbra => 'Âmbar';

  @override
  String get accentArancio => 'Laranja';

  @override
  String get accentRosa => 'Rosa';

  @override
  String get accentRosso => 'Vermelho';

  @override
  String get onboardingSkip => 'Saltar';

  @override
  String get onboardingNext => 'Seguinte';

  @override
  String get onboardingStart => 'Começar';

  @override
  String onboardingPageOf(int page, int total) {
    return 'Página $page de $total';
  }

  @override
  String get onboardingWelcomeTitle => 'Bem-vindo ao Codecore';

  @override
  String get onboardingWelcomeBody =>
      'O seu leitor de música pessoal: sem conta e sem servidor. A sua música fica no seu dispositivo.';

  @override
  String get onboardingFoldersTitle => 'A sua música';

  @override
  String get onboardingFoldersBody =>
      'Escolha as pastas onde guarda as suas faixas. O Codecore apenas as lê: não as altera nem as move.';

  @override
  String onboardingFoldersAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pastas adicionadas',
      one: '1 pasta adicionada',
    );
    return '$_temp0';
  }

  @override
  String get onboardingAllowAccess =>
      'Permitir o acesso aos ficheiros de áudio';

  @override
  String get onboardingAccessGranted => 'Acesso permitido';

  @override
  String get onboardingOnlineTitle => 'Funcionalidades online';

  @override
  String get onboardingOnlineBody =>
      'Estão desligadas: o Codecore nunca se liga à Internet por iniciativa própria. Pode ativá-las agora ou mais tarde nas Definições.';

  @override
  String get onboardingShareTitle => 'Transferências, Jam e partilha';

  @override
  String get onboardingYoutubeBody =>
      'Pode transferir faixas do YouTube para o seu dispositivo e ouvi-las como o resto da sua música.';

  @override
  String get onboardingJamBody =>
      'Com uma Jam ouve a mesma música em conjunto com outro dispositivo na mesma rede.';

  @override
  String get onboardingSendBody =>
      'Pode enviar faixas para outros dispositivos próximos com um PIN, sem passar pela Internet.';

  @override
  String get historyTitle => 'Histórico';

  @override
  String get historySubtitle => 'O que ouviu';

  @override
  String get historyToday => 'Hoje';

  @override
  String get historyYesterday => 'Ontem';

  @override
  String get historyEmpty => 'O que ouvir aparecerá aqui.';

  @override
  String get historyOff =>
      'O histórico está desligado: ative-o em Definições → Reprodução.';

  @override
  String get historyClear => 'Limpar histórico';

  @override
  String get historyClearTitle => 'Limpar o histórico?';

  @override
  String get historyClearBody =>
      'Apenas a lista de reproduções é apagada: os contadores, os favoritos e as playlists ficam como estão.';

  @override
  String get historyCleared => 'Histórico limpo';

  @override
  String get settingsRecordHistory => 'Guardar o histórico de reprodução';

  @override
  String get settingsRecordHistoryHint =>
      'Fica no dispositivo. Desligado, nada mais é adicionado à lista.';

  @override
  String get statsTitle => 'Estatísticas';

  @override
  String get statsSubtitle => 'Quanto e o que ouve';

  @override
  String get statsMonth => 'Mês';

  @override
  String get statsYear => 'Ano';

  @override
  String get statsPrevious => 'Período anterior';

  @override
  String get statsNext => 'Período seguinte';

  @override
  String get statsEmpty => 'Nenhuma reprodução neste período.';

  @override
  String statsPlays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reproduções',
      one: '1 reprodução',
    );
    return '$_temp0';
  }

  @override
  String statsDistinct(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count faixas diferentes',
      one: '1 faixa diferente',
    );
    return '$_temp0';
  }

  @override
  String statsHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String get statsTopTracks => 'Faixas mais ouvidas';

  @override
  String get statsTopArtists => 'Artistas mais ouvidos';

  @override
  String get statsTopAlbums => 'Álbuns mais ouvidos';

  @override
  String get statsFavouriteHour => 'Hora preferida';

  @override
  String get statsFirstListen => 'Primeira reprodução';

  @override
  String statsFirstValue(String title, String date) {
    return '$title · $date';
  }

  @override
  String get statsYourMonth => 'O seu mês';

  @override
  String statsTopArtistHome(String name) {
    return 'O mais ouvido: $name';
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
    return 'Não percebo «$term»: procuro-o como texto.';
  }

  @override
  String get ruleHelpTooltip => 'Ajuda da pesquisa';

  @override
  String get smartPlaylistNew => 'Nova playlist inteligente';

  @override
  String get smartPlaylistEdit => 'Editar playlist inteligente';

  @override
  String get smartPlaylistLabel => 'Playlist inteligente';

  @override
  String smartSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Playlist inteligente · $count faixas',
      one: 'Playlist inteligente · 1 faixa',
    );
    return '$_temp0';
  }

  @override
  String get smartName => 'Nome';

  @override
  String get smartNameRequired => 'Escreva um nome';

  @override
  String get smartRules => 'Regras';

  @override
  String get smartRulesHint => 'artist:\"pink floyd\" -live year:1970..1979';

  @override
  String get smartNoRules => 'Sem regras, a playlist contém toda a biblioteca.';

  @override
  String get smartSortBy => 'Ordenar por';

  @override
  String get smartSortMostPlayed => 'Mais ouvidas';

  @override
  String get smartSortRandom => 'Aleatório';

  @override
  String get smartLimit => 'Limite de faixas (opcional)';

  @override
  String get smartTemplates => 'Modelos';

  @override
  String get smartTplNever => 'Nunca ouvidas';

  @override
  String get smartTplRecent => 'Adicionadas recentemente';

  @override
  String get smartTplTop => 'As mais ouvidas';

  @override
  String get smartTpl90s => 'Anos 90';

  @override
  String get smartConvert => 'Converter em playlist normal';

  @override
  String smartConverted(String name) {
    return 'Criada a playlist «$name» com a lista atual';
  }

  @override
  String smartDeleteTitle(String name) {
    return 'Eliminar «$name»?';
  }

  @override
  String get smartDeleteBody =>
      'Apenas a regra é eliminada: as faixas ficam onde estão.';

  @override
  String get smartAutoNote => 'A lista atualiza-se sozinha.';

  @override
  String get tagsTitle => 'Etiquetas';

  @override
  String get tagsSubtitle => 'As suas etiquetas';

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
  String get tagNew => 'Nova etiqueta';

  @override
  String get tagRename => 'Mudar o nome da etiqueta';

  @override
  String get tagColor => 'Cor';

  @override
  String get tagNoColor => 'Sem cor';

  @override
  String get tagNameTaken => 'Já existe uma etiqueta com este nome';

  @override
  String tagDeleteTitle(String name) {
    return 'Eliminar a etiqueta «$name»?';
  }

  @override
  String get tagDeleteBody =>
      'Apenas a etiqueta é retirada das faixas: continuam na biblioteca.';

  @override
  String get tagsEmpty =>
      'Ainda não há etiquetas: crie uma no menu de uma faixa.';

  @override
  String get tagAddToSelection => 'Adicionar etiqueta…';

  @override
  String get tagRemoveFromSelection => 'Retirar etiqueta…';

  @override
  String tagAssigned(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count faixas etiquetadas «$name»',
      one: '1 faixa etiquetada «$name»',
    );
    return '$_temp0';
  }

  @override
  String tagUnassigned(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '«$name» retirada de $count faixas',
      one: '«$name» retirada de 1 faixa',
    );
    return '$_temp0';
  }

  @override
  String get tagNoneToRemove => 'As faixas escolhidas não têm etiquetas.';
}
