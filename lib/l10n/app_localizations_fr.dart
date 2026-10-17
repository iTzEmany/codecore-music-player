// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Codecore';

  @override
  String get chooseFolder => 'Choisir un dossier';

  @override
  String get scan => 'Analyser';

  @override
  String get noTracks =>
      'Aucun titre. Choisissez un dossier et lancez l’analyse.';

  @override
  String get openSettings => 'Ouvrir les paramètres';

  @override
  String get permissionDenied => 'Autorisation de lecture audio refusée';

  @override
  String get permissionExplain =>
      'Codecore a besoin de l’autorisation de lire les fichiers audio pour afficher votre musique.';

  @override
  String get navLibrary => 'Bibliothèque';

  @override
  String get navFavorites => 'Favoris';

  @override
  String get navPlaylists => 'Playlists';

  @override
  String get navSettings => 'Paramètres';

  @override
  String get tracks => 'Titres';

  @override
  String get albums => 'Albums';

  @override
  String get artists => 'Artistes';

  @override
  String get searchHint => 'Rechercher';

  @override
  String get sortBy => 'Trier par';

  @override
  String get addMusicFolder => 'Ajoutez votre dossier de musique';

  @override
  String get addFolder => 'Ajouter un dossier';

  @override
  String get folders => 'Dossiers de musique';

  @override
  String get refreshLibrary => 'Actualiser la bibliothèque';

  @override
  String get removeFolder => 'Retirer le dossier';

  @override
  String get unknownArtist => 'Artiste inconnu';

  @override
  String get unknownAlbum => 'Album inconnu';

  @override
  String get variousArtists => 'Artistes divers';

  @override
  String get play => 'Lire';

  @override
  String get shuffle => 'Aléatoire';

  @override
  String get queue => 'File d’attente';

  @override
  String get nowPlaying => 'Lecture en cours';

  @override
  String get nothingPlaying => 'Aucun titre en cours de lecture';

  @override
  String get mute => 'Muet';

  @override
  String get scanning => 'Analyse en cours…';

  @override
  String get emptyQueue => 'La file d’attente est vide';

  @override
  String get noResults => 'Aucun résultat';

  @override
  String get sortDefault => 'Par défaut';

  @override
  String get sortTitle => 'Titre';

  @override
  String get sortArtist => 'Artiste';

  @override
  String get sortAlbum => 'Album';

  @override
  String get sortYear => 'Année';

  @override
  String get sortAdded => 'Ajoutés récemment';

  @override
  String get sortDuration => 'Durée';

  @override
  String tracksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count titres',
      one: '1 titre',
      zero: '0 titre',
    );
    return '$_temp0';
  }

  @override
  String albumsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count albums',
      one: '1 album',
      zero: '0 album',
    );
    return '$_temp0';
  }

  @override
  String missingTracksCount(int count) {
    return 'Titres introuvables ($count)';
  }

  @override
  String get addedToFavorites => 'Ajouté aux favoris';

  @override
  String get removedFromFavorites => 'Retiré des favoris';

  @override
  String get undo => 'Annuler';

  @override
  String get noFavorites => 'Aucun favori pour l’instant';

  @override
  String get newPlaylist => 'Nouvelle playlist';

  @override
  String get newPlaylistEllipsis => 'Nouvelle playlist…';

  @override
  String get playlistName => 'Nom de la playlist';

  @override
  String get create => 'Créer';

  @override
  String get cancel => 'Annuler';

  @override
  String get save => 'Enregistrer';

  @override
  String get delete => 'Supprimer';

  @override
  String get rename => 'Renommer';

  @override
  String get noPlaylists => 'Aucune playlist. Créez-en une.';

  @override
  String get addToPlaylist => 'Ajouter à une playlist…';

  @override
  String addedToPlaylist(String name) {
    return 'Ajouté à « $name »';
  }

  @override
  String get playNext => 'Lire ensuite';

  @override
  String get addToQueue => 'Ajouter à la file d’attente';

  @override
  String get addedToQueue => 'Ajouté à la file d’attente';

  @override
  String get favorite => 'Favori';

  @override
  String get removeFromFavorites => 'Retirer des favoris';

  @override
  String get removeFromList => 'Retirer';

  @override
  String get editInfo => 'Modifier les infos';

  @override
  String get details => 'Détails';

  @override
  String get showInFolder => 'Afficher dans le dossier';

  @override
  String get detailPath => 'Chemin';

  @override
  String get detailFormat => 'Format';

  @override
  String get detailSize => 'Taille';

  @override
  String get detailDuration => 'Durée';

  @override
  String get detailAdded => 'Ajouté le';

  @override
  String get detailPlays => 'Lectures';

  @override
  String get close => 'Fermer';

  @override
  String get fieldTitle => 'Titre';

  @override
  String get fieldArtist => 'Artiste';

  @override
  String get fieldAlbum => 'Album';

  @override
  String get fieldAlbumArtist => 'Artiste de l’album';

  @override
  String get fieldYear => 'Année';

  @override
  String get fieldTrackNumber => 'Numéro de piste';

  @override
  String get fieldGenre => 'Genre';

  @override
  String get restoreFromFile => 'Restaurer depuis les tags du fichier';

  @override
  String get titleRequired => 'Le titre ne peut pas être vide';

  @override
  String get settingsAppearance => 'Apparence';

  @override
  String get settingsTheme => 'Thème';

  @override
  String get themeNotte => 'Nuit violette';

  @override
  String get themeOled => 'Noir pur';

  @override
  String get settingsTextSize => 'Taille du texte';

  @override
  String get textSmall => 'Petit';

  @override
  String get textNormal => 'Normal';

  @override
  String get textLarge => 'Grand';

  @override
  String get settingsCompact => 'Mode compact';

  @override
  String get settingsReducedMotion => 'Animations réduites';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsLibrary => 'Bibliothèque';

  @override
  String get rescanNow => 'Réanalyser maintenant';

  @override
  String get clearCoverCache => 'Vider le cache des pochettes';

  @override
  String get coverCacheCleared => 'Cache des pochettes vidé';

  @override
  String get settingsOnline => 'En ligne';

  @override
  String get autoEnrich => 'Enrichissement automatique';

  @override
  String get autoEnrichHint =>
      'Recherche en ligne les métadonnées et les pochettes des nouveaux titres';

  @override
  String get autoLyrics => 'Paroles automatiques';

  @override
  String get autoLyricsHint =>
      'Télécharge les paroles depuis LRCLIB pour les nouveaux titres';

  @override
  String get settingsAbout => 'À propos';

  @override
  String appVersion(String version) {
    return 'Version $version';
  }

  @override
  String get licenses => 'Licences';

  @override
  String get personalUse => 'Application à usage personnel';

  @override
  String get missingTracksTitle => 'Titres introuvables';

  @override
  String get removeFromLibrary => 'Retirer de la bibliothèque';

  @override
  String get ignore => 'Ignorer';

  @override
  String get confirmRemoveTitle => 'Retirer de la bibliothèque ?';

  @override
  String get confirmRemoveBody =>
      'Le fichier n’est pas modifié ; les favoris et playlists de ce titre seront perdus.';

  @override
  String get noMissingTracks => 'Aucun titre manquant';

  @override
  String get retry => 'Réessayer';

  @override
  String scanFailed(String error) {
    return 'Échec de l’analyse : $error';
  }

  @override
  String playbackError(String reason, String title) {
    return 'Impossible de lire « $title » : $reason';
  }

  @override
  String get reasonFileMissing => 'fichier introuvable';

  @override
  String get reasonUnplayable => 'fichier illisible';

  @override
  String get reasonNotInLibrary => 'titre absent de la bibliothèque';

  @override
  String get searchWeb => 'Rechercher des infos sur le web';

  @override
  String get enrichPreviewTitle => 'Aperçu des informations';

  @override
  String get currentValue => 'Actuel';

  @override
  String get proposedValue => 'Proposé';

  @override
  String get apply => 'Appliquer';

  @override
  String get nothingFound => 'Aucune information trouvée';

  @override
  String get userEditedLocked => 'Modifié par vous : ne sera pas écrasé';

  @override
  String get fieldCover => 'Pochette';

  @override
  String get fieldLyrics => 'Paroles';

  @override
  String get fieldCuriosity => 'Anecdotes';

  @override
  String get enrichAlbum => 'Enrichir l’album';

  @override
  String get enrichLibrary => 'Enrichir toute la bibliothèque';

  @override
  String get enrichConfirmTitle => 'Enrichir la bibliothèque ?';

  @override
  String enrichConfirmBody(int count, int minutes) {
    return '$count titres, environ $minutes minutes. Seuls les champs vides sont remplis.';
  }

  @override
  String enrichRunning(int done, int total) {
    return 'Enrichissement $done/$total';
  }

  @override
  String enrichResult(int notFound, int updated) {
    return '$updated mis à jour, $notFound introuvables';
  }

  @override
  String get enrichBusy => 'Un enrichissement est déjà en cours';

  @override
  String get serviceUnavailable => 'Service indisponible, réessayez plus tard';

  @override
  String get lyrics => 'Paroles';

  @override
  String get searchLyrics => 'Rechercher les paroles';

  @override
  String get noLyrics => 'Aucune parole disponible';

  @override
  String get lyricsNotFound => 'Paroles introuvables';

  @override
  String get copy => 'Copier';

  @override
  String get copied => 'Copié';

  @override
  String get sourceWikipedia => 'Source : Wikipédia (CC BY-SA)';

  @override
  String get youtube => 'YouTube';

  @override
  String get ytHint => 'Rechercher ou coller un lien';

  @override
  String get ytDownload => 'Télécharger';

  @override
  String get ytAlreadyInLibrary => 'Déjà dans la bibliothèque';

  @override
  String get ytNoResults => 'Aucun résultat';

  @override
  String get ytQueued => 'En attente';

  @override
  String get ytDownloading => 'Téléchargement en cours';

  @override
  String get ytDone => 'Terminé';

  @override
  String get ytFailed => 'Échec';

  @override
  String get ytCancelled => 'Annulé';

  @override
  String get ytClearCompleted => 'Effacer les terminés';

  @override
  String get ytCancel => 'Annuler le téléchargement';

  @override
  String get ytErrUnavailable => 'Vidéo indisponible (âge/région/privée)';

  @override
  String get ytErrNetwork => 'Réseau indisponible';

  @override
  String get ytErrChanged =>
      'YouTube a changé quelque chose : mettez à jour l’application ou le paquet';

  @override
  String get ytNoFolder => 'Ajoutez d’abord un dossier de musique';

  @override
  String get ytLegal =>
      'Usage personnel uniquement. Respectez les droits d’auteur et les conditions d’utilisation de YouTube et SoundCloud.';

  @override
  String get useDefaultFolder => 'Utiliser le dossier Musique de l’appareil';

  @override
  String get ytErrToolMissing =>
      'yt-dlp introuvable : installez-le (pip install -U yt-dlp) puis réessayez';

  @override
  String get ytErrRateLimited =>
      'YouTube demande de ralentir : réessayez dans quelques minutes';

  @override
  String get playlistChangeCover => 'Changer la pochette';

  @override
  String get playlistRemoveCover => 'Retirer la pochette';

  @override
  String get coverTooLarge => 'Image trop volumineuse (max 4 MB)';

  @override
  String get addSongs => 'Ajouter des titres';

  @override
  String addNSongs(int count) {
    return 'Ajouter ($count)';
  }

  @override
  String get allSongsInPlaylist => 'Tous les titres sont déjà dans la playlist';

  @override
  String get shareTitle => 'Partage';

  @override
  String get shareSend => 'Envoyer';

  @override
  String get shareReceive => 'Recevoir';

  @override
  String get shareAll => 'Toute la bibliothèque';

  @override
  String shareSelection(int count) {
    return 'Sélection ($count titres)';
  }

  @override
  String get sharePick => 'Choisir des titres';

  @override
  String get shareStart => 'Démarrer le partage';

  @override
  String get shareStop => 'Arrêter';

  @override
  String get shareActive => 'Partage actif';

  @override
  String get shareAddress => 'Adresse (IP:port)';

  @override
  String get sharePin => 'PIN';

  @override
  String get shareConnect => 'Se connecter';

  @override
  String shareDownloadSelected(int count) {
    return 'Télécharger la sélection ($count)';
  }

  @override
  String shareProgress(int done, int total) {
    return 'Titre $done sur $total';
  }

  @override
  String shareDone(int count) {
    return '$count titres reçus';
  }

  @override
  String shareConnectedTo(String name) {
    return 'Connecté à $name';
  }

  @override
  String get shareErrUnreachable =>
      'Appareil injoignable : vérifiez l’adresse et le Wi‑Fi';

  @override
  String get shareErrPin => 'PIN incorrect';

  @override
  String get shareErrBlocked =>
      'Trop de tentatives : réessayez dans une minute';

  @override
  String get shareErrNotCodecore => 'Ce n’est pas un appareil Codecore';

  @override
  String get shareErrFailed => 'Échec du transfert';

  @override
  String get shareNoNetwork => 'Aucun réseau local trouvé';

  @override
  String get shareFirewall =>
      'Windows peut demander l’autorisation du pare-feu lors du premier partage.';

  @override
  String get shareHint =>
      'Sur le même Wi‑Fi, ouvrez « Recevoir » sur l’autre appareil et saisissez l’adresse et le PIN.';

  @override
  String get shareMenu => 'Partager…';

  @override
  String get shareDeviceName => 'Nom de l’appareil';

  @override
  String get importOld => 'Importer depuis l’ancienne application';

  @override
  String get importOldHint =>
      'Choisissez codecore_library.db de la version Python';

  @override
  String importSummary(
    int favorites,
    int lyrics,
    int playlists,
    int unmatched,
  ) {
    return '$favorites favoris, $playlists playlists, $lyrics paroles importées, $unmatched non associés';
  }

  @override
  String get importFailed => 'Échec de l’importation : fichier invalide';

  @override
  String get sleepTimer => 'Minuteur d’arrêt';

  @override
  String sleepMinutes(int count) {
    return '$count minutes';
  }

  @override
  String get sleepEndOfTrack => 'À la fin du titre';

  @override
  String get sleepCancel => 'Annuler le minuteur';

  @override
  String get pause => 'Pause';

  @override
  String get nextTrack => 'Titre suivant';

  @override
  String get previousTrack => 'Titre précédent';

  @override
  String get repeat => 'Répéter';

  @override
  String get moreOptions => 'Plus d’options';

  @override
  String get back => 'Retour';

  @override
  String get settingsPlayback => 'Lecture';

  @override
  String get normalizeVolume => 'Normaliser le volume';

  @override
  String get normalizeVolumeHint =>
      'Utilise le ReplayGain des fichiers pour atténuer les titres trop forts';

  @override
  String get nearbyDevices => 'Appareils à proximité';

  @override
  String get searchingDevices => 'Recherche d’appareils sur le réseau…';

  @override
  String get noDevicesHint =>
      'Aucun appareil trouvé. Ouvrez aussi Partage sur l’autre appareil, sur le même réseau.';

  @override
  String sendToDevice(String name) {
    return 'Envoyer à $name';
  }

  @override
  String offerSent(String name) {
    return 'Demande envoyée à $name';
  }

  @override
  String get offerChooseFirst => 'Choisissez d’abord les titres à envoyer';

  @override
  String get sentRequests => 'Demandes envoyées';

  @override
  String get receivedRequests => 'Demandes reçues';

  @override
  String get offerPending => 'En attente de réponse';

  @override
  String get offerAccepted => 'Acceptée';

  @override
  String get offerDeclined => 'Refusée';

  @override
  String get offerCancelled => 'Annulée';

  @override
  String get offerExpired => 'Expirée';

  @override
  String get offerDone => 'Terminée';

  @override
  String get offerFailed => 'Échec';

  @override
  String incomingTitle(String name) {
    return '$name souhaite vous envoyer des titres';
  }

  @override
  String incomingBody(int count, String size) {
    return '$count titres, $size MB';
  }

  @override
  String get accept => 'Accepter';

  @override
  String get decline => 'Refuser';

  @override
  String receivingProgress(int done, int total) {
    return 'Réception $done/$total';
  }

  @override
  String get manualConnection => 'Connexion manuelle (IP et PIN)';

  @override
  String get receiveFromLan => 'Recevoir depuis le réseau local';

  @override
  String get receiveFromLanHint =>
      'Rend l’appareil visible et reçoit les demandes même en arrière-plan. Sur Android, une notification permanente permet de le désactiver';

  @override
  String get receiveServiceTitle => 'Codecore est visible sur le réseau';

  @override
  String get receiveServiceText =>
      'Prêt à recevoir des titres des appareils à proximité';

  @override
  String get receiveServiceDisable => 'Désactiver';

  @override
  String get jamTitle => 'Jam';

  @override
  String get jamStart => 'Démarrer une Jam';

  @override
  String jamStartWith(String name) {
    return 'Démarrer une Jam avec $name';
  }

  @override
  String jamWaiting(String name) {
    return 'En attente de l’acceptation de $name…';
  }

  @override
  String jamDeclined(String name) {
    return '$name a refusé la Jam';
  }

  @override
  String jamBusy(String name) {
    return '$name a déjà une Jam en cours';
  }

  @override
  String get jamUnreachable => 'Appareil injoignable';

  @override
  String jamIncomingTitle(String name) {
    return '$name souhaite démarrer une Jam';
  }

  @override
  String get jamIncomingBody =>
      'Écoutez ensemble depuis une file d’attente partagée.';

  @override
  String jamIncomingDialog(String name) {
    return '$name souhaite démarrer une Jam avec vous. La musique est lue depuis cet appareil et vous pouvez tous les deux ajouter des titres.';
  }

  @override
  String get jamQueue => 'File d’attente partagée';

  @override
  String get jamEmpty => 'La file d’attente est vide. Ajoutez des titres.';

  @override
  String jamAddedBy(String name) {
    return 'ajouté par $name';
  }

  @override
  String get jamYou => 'vous';

  @override
  String get jamAddTracks => 'Ajouter des titres';

  @override
  String get jamAddToJam => 'Ajouter à la Jam';

  @override
  String jamAdded(int count) {
    return 'Ajoutés à la Jam : $count';
  }

  @override
  String get jamOutput => 'Sortie audio';

  @override
  String get jamOutputHere => 'Cet appareil';

  @override
  String jamOutputOther(String name) {
    return '$name';
  }

  @override
  String get jamEnd => 'Terminer la Jam';

  @override
  String get jamLeave => 'Quitter la Jam';

  @override
  String get jamEnded => 'La Jam est terminée';

  @override
  String get jamLost => 'Connexion perdue';

  @override
  String get jamGuestCannotSkip =>
      'Seul l’hôte de la Jam peut changer de titre';

  @override
  String get jamRemoveForbidden =>
      'Vous ne pouvez retirer que vos propres titres';

  @override
  String get jamNowPlaying => 'Lecture en cours';

  @override
  String get jamNothingPlaying => 'Rien en cours de lecture';

  @override
  String jamWith(String name) {
    return 'Jam avec $name';
  }

  @override
  String get jamUnavailable => 'Indisponible';

  @override
  String get jamPlaying => 'La Jam est active';

  @override
  String get jamOpen => 'Ouvrir la Jam';

  @override
  String jamSynced(int ms) {
    return 'Synchronisé · décalage $ms ms';
  }

  @override
  String get jamSyncing => 'Synchronisation en cours…';

  @override
  String jamLatency(int ms) {
    return 'Latence de cette sortie : $ms ms';
  }

  @override
  String get jamLatencyHint =>
      'Pour casques ou enceintes Bluetooth : augmentez jusqu’à ce que les sorties soient synchronisées.';

  @override
  String get jamOutputsHint => 'Plusieurs sorties jouent en même temps';

  @override
  String get renamePlaylist => 'Renommer la playlist';

  @override
  String get confirmDeletePlaylistTitle => 'Supprimer la playlist ?';

  @override
  String confirmDeletePlaylistBody(String name) {
    return '« $name » sera supprimée. Les titres restent dans la bibliothèque.';
  }

  @override
  String get confirmRemoveFolderTitle => 'Retirer le dossier ?';

  @override
  String get confirmRemoveFolderBody =>
      'Ses titres disparaissent de la bibliothèque. Les fichiers restent sur l’appareil.';

  @override
  String get confirmClearCoversTitle => 'Vider le cache des pochettes ?';

  @override
  String get confirmClearCoversBody =>
      'Les pochettes seront recréées à la prochaine analyse.';

  @override
  String get confirmRestoreTitle => 'Restaurer depuis les tags du fichier ?';

  @override
  String get confirmRestoreBody =>
      'Vos modifications de ce titre seront remplacées par les données du fichier.';

  @override
  String get removedFromPlaylist => 'Retiré de la playlist';

  @override
  String get removedFromQueue => 'Retiré de la file d’attente';

  @override
  String get playNextDone => 'Sera lu ensuite';

  @override
  String get ytSearchPrompt => 'Recherchez un titre ou collez un lien';

  @override
  String get loadFailed => 'Impossible de charger les données.';

  @override
  String get navHome => 'Accueil';

  @override
  String get navSearch => 'Rechercher';

  @override
  String get devicesTitle => 'Appareils';

  @override
  String get devicesJamActive => 'Jam active';

  @override
  String jamPeople(int n) {
    return 'Jam · $n personnes';
  }

  @override
  String get devicesVisibleTitle => 'Rendre cet appareil visible';

  @override
  String get devicesVisibleHint =>
      'Pour recevoir des titres ou lancer une Jam, les autres appareils doivent pouvoir vous voir sur le réseau.';

  @override
  String get devicesJamShort => 'Jam';

  @override
  String get devicesSendShort => 'Envoyer';

  @override
  String get devicesMore => 'Partage et connexion manuelle';

  @override
  String jamParticipantsCount(int n) {
    return '$n personnes';
  }

  @override
  String get playingFrom => 'Lecture depuis';

  @override
  String get playContextSearch => 'Recherche';

  @override
  String get allTracks => 'Tous les titres';

  @override
  String get trackInfo => 'Infos sur le titre';

  @override
  String get searchCuriosity => 'Rechercher des anecdotes';

  @override
  String get upNext => 'À suivre';

  @override
  String get openQueue => 'Ouvrir la file d’attente';

  @override
  String get copyLink => 'Copier le lien';

  @override
  String get moreActions => 'Autres actions';

  @override
  String get sleepChipEnd => 'fin du titre';

  @override
  String get yourLibrary => 'Votre bibliothèque';

  @override
  String playlistCountLabel(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Playlist · $n titres',
      one: 'Playlist · 1 titre',
      zero: 'Playlist · 0 titre',
    );
    return '$_temp0';
  }

  @override
  String get sortRecent => 'Récents';

  @override
  String get sortAlphabetical => 'Alphabétique';

  @override
  String get sortAddedRecently => 'Ajoutés récemment';

  @override
  String get viewAsGrid => 'Afficher en grille';

  @override
  String get viewAsList => 'Afficher en liste';

  @override
  String get kindAlbum => 'Album';

  @override
  String get kindArtist => 'Artiste';

  @override
  String get kindPlaylist => 'Playlist';

  @override
  String discN(int n) {
    return 'Disque $n';
  }

  @override
  String albumMeta(String details) {
    return 'Album · $details';
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
  String get mostPlayed => 'Les plus écoutés';

  @override
  String get albumsSection => 'Albums';

  @override
  String artistMeta(String albums, String tracks) {
    return '$albums · $tracks';
  }

  @override
  String get addAllToQueue => 'Ajouter à la file d’attente';

  @override
  String addedNToQueue(int n) {
    return '$n titres ajoutés à la file d’attente';
  }

  @override
  String get editOrder => 'Modifier l’ordre';

  @override
  String get finishEditing => 'Terminé';

  @override
  String get removeFromPlaylistAction => 'Retirer de la playlist';

  @override
  String get noTracksInPlaylist => 'Cette playlist est vide';

  @override
  String get greetingMorning => 'Bonjour';

  @override
  String get greetingAfternoon => 'Bon après-midi';

  @override
  String get greetingEvening => 'Bonsoir';

  @override
  String get homeResume => 'Reprendre';

  @override
  String get homeRecentlyPlayed => 'Écoutés récemment';

  @override
  String get homeRecentlyAdded => 'Ajoutés récemment';

  @override
  String get homeTopTracks => 'Les plus écoutés';

  @override
  String get homeRediscover => 'À redécouvrir';

  @override
  String get searchMainResult => 'Résultat principal';

  @override
  String get showAll => 'Tout afficher';

  @override
  String searchOnYoutube(String query) {
    return 'Rechercher « $query » sur YouTube';
  }

  @override
  String get recentSearches => 'Recherches récentes';

  @override
  String get genresTitle => 'Genres';

  @override
  String downloadsChip(int n) {
    return 'Téléchargements ($n)';
  }

  @override
  String get gotIt => 'Compris';

  @override
  String get searchEmptyLibrary => 'Aucun résultat dans la bibliothèque';

  @override
  String get ytInfoTooltip => 'Informations sur l’utilisation';

  @override
  String get removeRecentSearch => 'Retirer des recherches récentes';

  @override
  String get groupGoTo => 'Aller à';

  @override
  String get goToAlbum => 'Aller à l’album';

  @override
  String get goToArtist => 'Aller à l’artiste';

  @override
  String get groupQueue => 'File d’attente';

  @override
  String get groupCollection => 'Collection';

  @override
  String get groupEdit => 'Modifier';

  @override
  String get groupOther => 'Autre';

  @override
  String get queueNowPlaying => 'Lecture en cours';

  @override
  String get queueNext => 'À suivre';

  @override
  String get queueClear => 'Vider';

  @override
  String get queueCleared => 'File d’attente vidée';

  @override
  String get jamOutputsAndSync => 'Sorties et synchro';

  @override
  String get jamHostTag => 'hôte';

  @override
  String get jamWaitingEmpty => 'Aucune Jam en cours';

  @override
  String get activityTitle => 'Activité';

  @override
  String activityScan(int done, int total) {
    return 'Analyse · $done/$total';
  }

  @override
  String get activityScanIdle => 'Analyse en cours';

  @override
  String activityEnrich(int done, int total) {
    return 'Enrichissement · $done/$total';
  }

  @override
  String activityDownload(String title) {
    return 'Téléchargement · $title';
  }

  @override
  String activityTransfer(String name, int n) {
    return 'Envoi à $name · $n titres';
  }

  @override
  String get activityNone => 'Aucune activité';

  @override
  String get activityCompleted => 'Terminées';

  @override
  String get activityClear => 'Effacer';

  @override
  String activityRunning(int n) {
    return '$n activités en cours';
  }

  @override
  String get settingsLocalNetwork => 'Réseau local';

  @override
  String get removeAll => 'Tout retirer';

  @override
  String get confirmRemoveAllTitle => 'Tout retirer de la bibliothèque ?';

  @override
  String confirmRemoveAllBody(int n) {
    return '$n titres introuvables seront retirés de la bibliothèque. Les fichiers ne sont pas modifiés ; les favoris et playlists de ces titres seront perdus.';
  }

  @override
  String get csvImportMenu => 'Importer depuis Exportify (CSV)';

  @override
  String get csvImportIntroTitle => 'Importer une playlist';

  @override
  String get csvImportIntroSource =>
      'Le fichier CSV se crée gratuitement sur le site Exportify — exportify.net (aucune application nécessaire).';

  @override
  String get csvImportStep1 =>
      'Ouvrez https://exportify.net dans le navigateur (même depuis le téléphone).';

  @override
  String get csvImportStep2 =>
      'Appuyez sur « Get Started » et connectez-vous avec votre compte Spotify.';

  @override
  String get csvImportStep3 =>
      'À côté de la playlist souhaitée, appuyez sur « Export » : un fichier .csv portant le nom de la playlist est téléchargé.';

  @override
  String get csvImportStep4 =>
      'Revenez ici et appuyez sur « Choisir un fichier CSV ».';

  @override
  String get csvImportNote =>
      'Codecore recherche les titres dans votre bibliothèque et télécharge les autres depuis YouTube Music.';

  @override
  String get csvImportNoteOffline =>
      'Seuls les titres déjà présents dans votre bibliothèque seront liés.';

  @override
  String get csvImportCopy => 'Copier l’adresse';

  @override
  String get csvImportCopied => 'Adresse copiée';

  @override
  String get csvImportPick => 'Choisir un fichier';

  @override
  String get csvImportNotExportify =>
      'Format non reconnu. Choisissez un CSV (Exportify, TuneMyMusic, Soundiiz, Last.fm) ou une playlist M3U/M3U8/XSPF.';

  @override
  String get csvImportReadFailed => 'Impossible de lire le fichier.';

  @override
  String get csvImportPreviewTitle => 'Importer la playlist';

  @override
  String get csvImportName => 'Nom de la playlist';

  @override
  String csvImportSummary(int total, int known, int todo) {
    return '$total titres · $known déjà dans la bibliothèque · $todo à télécharger';
  }

  @override
  String csvImportSkipped(int n) {
    return '$n lignes ignorées (podcasts ou fichiers locaux)';
  }

  @override
  String csvImportEstimate(int minutes) {
    return 'Durée estimée : environ $minutes min';
  }

  @override
  String get csvImportExists => 'Une playlist portant ce nom existe déjà';

  @override
  String get csvImportUpdate =>
      'Mettre à jour l’existante (n’ajoute que les nouveaux titres)';

  @override
  String get csvImportNew => 'Créer une nouvelle playlist';

  @override
  String get csvImportGo => 'Importer';

  @override
  String get csvImportStarted =>
      'Importation lancée : suivez-la dans le Centre d’activité';

  @override
  String activityImport(String name, int done, int total) {
    return 'Importation « $name » · $done/$total';
  }

  @override
  String activityImportPaused(String name, int done, int total) {
    return 'Importation « $name » · en pause · $done/$total';
  }

  @override
  String csvImportBanner(int done, int total, int review, int missing) {
    return 'Importation : $done/$total · $review à vérifier · $missing introuvables';
  }

  @override
  String csvImportBannerPaused(int done, int total, int review, int missing) {
    return 'Importation en pause : $done/$total · $review à vérifier · $missing introuvables';
  }

  @override
  String get csvImportReview => 'Revoir';

  @override
  String get csvImportResume => 'Reprendre';

  @override
  String get csvImportPause => 'Pause';

  @override
  String get csvImportCancelTitle => 'Annuler l’importation ?';

  @override
  String get csvImportCancelBody =>
      'Les titres déjà téléchargés restent dans la playlist.';

  @override
  String csvImportDone(int added, int review, int missing) {
    return 'Importation terminée : $added ajoutés, $review à vérifier, $missing introuvables';
  }

  @override
  String get csvImportFailing =>
      'Trop d’erreurs consécutives : importation en pause';

  @override
  String get csvImportReviewTitle => 'Revoir';

  @override
  String get csvImportToReview => 'À vérifier';

  @override
  String get csvImportNotFound => 'Introuvables';

  @override
  String get csvImportErrors => 'Avec erreurs';

  @override
  String get csvImportRetryAll => 'Tout réessayer';

  @override
  String get csvImportSkip => 'Passer';

  @override
  String get csvImportManual => 'Rechercher manuellement';

  @override
  String get csvImportNothing => 'Rien à revoir.';

  @override
  String get csvImportSearch => 'Rechercher';

  @override
  String csvImportWanted(String title, String artist, String duration) {
    return 'Recherché : $title · $artist · $duration';
  }

  @override
  String get csvImportDownload => 'Télécharger';

  @override
  String get csvImportCancelGo => 'Annuler l’importation';

  @override
  String get exportLog => 'Exporter le journal';

  @override
  String get exportLogHint =>
      'Fichier texte sans chemins personnels, adresses réseau ni PIN';

  @override
  String get exportLogDebugOnly =>
      'Disponible uniquement dans la version installée (en debug, le journal n’est pas écrit dans un fichier)';

  @override
  String get exportLogNone => 'Aucun journal à exporter pour l’instant';

  @override
  String get exportLogSaved => 'Journal enregistré';

  @override
  String get exportLogFailed => 'Impossible d’enregistrer le journal';

  @override
  String get exportPlaylist => 'Exporter…';

  @override
  String get exportPlaylistTitle => 'Exporter la playlist';

  @override
  String get exportFormatM3u8 => 'M3U8 · pour d’autres lecteurs';

  @override
  String get exportFormatCsv => 'CSV · comme Exportify';

  @override
  String get exportFormatJson => 'JSON · format Codecore';

  @override
  String get exportRelativePaths => 'Chemins relatifs';

  @override
  String get exportRelativeHint =>
      'Relatifs au dossier commun des titres : enregistrez-y le fichier';

  @override
  String get exportAction => 'Exporter';

  @override
  String get exportSaved => 'Playlist exportée';

  @override
  String get exportEmpty => 'La playlist est vide';

  @override
  String get exportFailed => 'Impossible d’exporter la playlist';

  @override
  String get ytErrToolOutdated =>
      'yt-dlp est trop ancien : mettez-le à jour (Paramètres → Téléchargements → Mettre à jour) et réessayez';

  @override
  String ytDlpOutdatedBanner(String version) {
    return 'yt-dlp $version est trop ancien : les téléchargements pourraient ne pas fonctionner';
  }

  @override
  String get settingsDownloads => 'Téléchargements';

  @override
  String ytDlpVersion(String version) {
    return 'yt-dlp $version';
  }

  @override
  String get ytDlpUnknownVersion => 'yt-dlp introuvable';

  @override
  String get ytDlpUpdate => 'Mettre à jour';

  @override
  String ytDlpUpdating(int percent) {
    return 'Mise à jour… $percent %';
  }

  @override
  String ytDlpUpdated(String version) {
    return 'Mis à jour vers la version $version';
  }

  @override
  String get ytDlpTooOld => 'Trop ancien : appuyez sur Mettre à jour';

  @override
  String get ytDlpUpdateErrNetwork =>
      'Échec de la mise à jour : réseau injoignable';

  @override
  String get ytDlpUpdateErrHash =>
      'Mise à jour annulée : le fichier téléchargé n’a pas réussi la vérification d’intégrité';

  @override
  String get ytDlpUpdateErrOther =>
      'Échec de la mise à jour (détails dans le journal)';

  @override
  String get downloadParallel => 'Téléchargements simultanés';

  @override
  String get downloadParallelHint =>
      'Plus à la fois, c’est plus rapide, mais YouTube peut demander de ralentir';

  @override
  String get downloadRateLimit => 'Limite de vitesse';

  @override
  String get downloadRateNone => 'Aucune';

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
    return 'Téléchargement · $title · nouvelle tentative dans $seconds s ($attempt/$max)';
  }

  @override
  String get downloadOriginal => 'Qualité d’origine (sans réencodage)';

  @override
  String get downloadOriginalHint =>
      'Conserve l’audio de YouTube tel quel (M4A/Opus) : aucune perte, fichiers plus petits. Désactivé : MP3 256 kbps';

  @override
  String get searchCacheClear => 'Vider le cache des recherches';

  @override
  String searchCacheCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recherches enregistrées',
      one: '1 recherche enregistrée',
      zero: 'Vide',
    );
    return '$_temp0';
  }

  @override
  String get searchCacheCleared => 'Cache vidé';

  @override
  String csvImportLengthOff(String found, String wanted) {
    return 'Durée différente : $found au lieu de $wanted';
  }

  @override
  String get csvImportKeep => 'Garder celui-ci';

  @override
  String get csvImportTooBig =>
      'Le fichier est trop volumineux pour une playlist (5 MB et 10 000 titres maximum)';

  @override
  String get csvImportAlsoAccepts =>
      'Également acceptés : TuneMyMusic, Soundiiz, Last.fm (CSV), M3U/M3U8, XSPF.';

  @override
  String get csvImportPlanned =>
      'Correspondances prêtes : vérifiez-les et téléchargez';

  @override
  String get csvImportLinkOnly => 'Lier uniquement (aucun téléchargement)';

  @override
  String get csvImportLinkOnlyHint =>
      'Crée la playlist avec ce que vous avez déjà, sans plus';

  @override
  String get csvImportPlanFirst => 'Vérifier avant de télécharger';

  @override
  String get csvImportPlanFirstHint =>
      'Recherche tout, puis vous choisissez quoi télécharger';

  @override
  String get csvImportPlanTitle => 'Correspondances';

  @override
  String csvImportPlanGo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Télécharger $n titres',
      one: 'Télécharger 1 titre',
      zero: 'Télécharger 0 titre',
    );
    return '$_temp0';
  }

  @override
  String get csvImportPlanKnown => 'déjà téléchargé';

  @override
  String get csvImportPlanEmpty => 'Rien à télécharger';

  @override
  String csvImportBannerPlanned(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n titres à télécharger',
      one: '1 titre à télécharger',
      zero: '0 titre à télécharger',
    );
    return 'Correspondances prêtes : $_temp0';
  }

  @override
  String get settingsAdvanced => 'Avancé';

  @override
  String get importSureThreshold => 'Correspondance sûre à partir de';

  @override
  String get importSureThresholdHint =>
      'Au-dessus de ce score, un titre importé est téléchargé sans demander';

  @override
  String get importReviewThreshold => 'À vérifier à partir de';

  @override
  String get importReviewThresholdHint =>
      'Entre ce score et le score sûr, le titre va dans « À vérifier » ; en dessous, dans « Introuvables »';

  @override
  String get importThresholdsReset => 'Rétablir les valeurs par défaut';

  @override
  String csvImportEstimateHours(int hours, int minutes) {
    return 'Durée estimée : environ $hours h $minutes min';
  }

  @override
  String csvImportBlocks(int size) {
    return 'Importer par blocs de $size';
  }

  @override
  String csvImportBigWarning(int n) {
    return '$n titres à télécharger : cela prendra des heures. Par blocs, l’un après l’autre, l’ordre de la playlist reste correct et vous pouvez vous arrêter entre deux blocs.';
  }

  @override
  String get etaLessThanMinute => 'moins de 1 min';

  @override
  String etaMinutes(int minutes) {
    return 'environ $minutes min';
  }

  @override
  String etaHours(int hours, int minutes) {
    return 'environ $hours h $minutes min';
  }

  @override
  String get csvImportOwnFolder => 'Dossier pour cette playlist';

  @override
  String get csvImportOwnFolderHint =>
      'Enregistre les titres téléchargés dans un sous-dossier portant le nom de la playlist';

  @override
  String get csvImportNumberFiles => 'Numéroter les fichiers';

  @override
  String get csvImportNumberFilesHint =>
      '07 - Artiste - Titre : le dossier se lit dans le bon ordre, même en dehors de Codecore';

  @override
  String get csvImportFetchCovers => 'Rechercher les pochettes';

  @override
  String get csvImportFetchCoversHint =>
      'Après chaque téléchargement, recherche la pochette de l’album sur iTunes (album et artiste du fichier)';

  @override
  String get csvImportExport => 'Exporter le résultat';

  @override
  String get csvImportExported => 'Résultat enregistré';

  @override
  String get csvOutHeaderRow => 'Ligne';

  @override
  String get csvOutHeaderTitle => 'Titre';

  @override
  String get csvOutHeaderArtists => 'Artistes';

  @override
  String get csvOutHeaderAlbum => 'Album';

  @override
  String get csvOutHeaderDuration => 'Durée (ms)';

  @override
  String get csvOutHeaderIsrc => 'ISRC';

  @override
  String get csvOutHeaderStatus => 'Résultat';

  @override
  String get csvOutHeaderNote => 'Motif';

  @override
  String get csvOutHeaderVideo => 'Vidéo choisie';

  @override
  String get csvOutHeaderScore => 'Score';

  @override
  String get importStatusPending => 'À rechercher';

  @override
  String get importStatusQueued => 'En attente';

  @override
  String get importStatusDownloaded => 'Téléchargé';

  @override
  String get importStatusLinked => 'Déjà dans la bibliothèque';

  @override
  String get importStatusReview => 'À vérifier';

  @override
  String get importStatusNotFound => 'Introuvable';

  @override
  String get importStatusFailed => 'Erreur';

  @override
  String get importStatusSkipped => 'Ignoré';

  @override
  String get importStatusPlanned => 'Planifié';

  @override
  String get importStatusRemoved => 'Retiré de la source';

  @override
  String get importNoteNoResults => 'Aucun résultat';

  @override
  String get importNoteLowScore => 'Correspondance peu sûre';

  @override
  String get importNoteLinkOnly => 'Liaison seule : non recherché';

  @override
  String get importNoteYoutubeOff => 'Téléchargement désactivé';

  @override
  String get importNoteDownloadFailed => 'Échec du téléchargement';

  @override
  String get importNoteLengthOff => 'Durée différente de celle du fichier';

  @override
  String get importNoteUnchanged => 'Déjà dans la playlist';

  @override
  String get csvImportSync => 'Synchroniser';

  @override
  String csvImportSyncCounts(int added, int removed) {
    return '+$added nouveaux · −$removed retirés de la playlist (les fichiers restent)';
  }

  @override
  String get csvImportSyncChecking => 'Vérification des différences…';

  @override
  String get playbackSpeed => 'Vitesse de lecture';

  @override
  String get playbackSpeedHint =>
      'La hauteur du son reste inchangée. Le minuteur d’arrêt compte le temps réel, pas celui du titre.';

  @override
  String resumeFrom(String time) {
    return 'reprendre à $time';
  }

  @override
  String get restartFromBeginning => 'Recommencer depuis le début';

  @override
  String get previewTrack => 'Aperçu de 20 s';

  @override
  String get equalizer => 'Égaliseur';

  @override
  String get eqOutputSpeaker => 'Haut-parleur';

  @override
  String get eqOutputHeadphones => 'Casque';

  @override
  String get eqHint =>
      'Chaque sortie mémorise sa courbe : elle change toute seule quand vous branchez un casque.';

  @override
  String get eqPresetFlat => 'Plat';

  @override
  String get eqPresetBass => 'Basses';

  @override
  String get eqPresetVoice => 'Voix';

  @override
  String get eqPresetTreble => 'Aigus';

  @override
  String get eqPresetCustom => 'Personnalisé';

  @override
  String get eqReset => 'Réinitialiser';

  @override
  String get eqWaiting =>
      'Les bandes apparaissent au démarrage du premier titre.';

  @override
  String get eqUnavailable =>
      'L’égaliseur n’est pas disponible sur cet appareil.';

  @override
  String get transitionMode => 'Transition entre les titres';

  @override
  String get transitionNormal => 'Normal';

  @override
  String get transitionGapless => 'Sans pause';

  @override
  String get transitionCrossfade => 'Fondu enchaîné';

  @override
  String get transitionHint =>
      'Le mode Sans pause fonctionne mieux avec des titres du même format (par exemple tous en FLAC).';

  @override
  String crossfadeLength(int seconds) {
    return 'Durée du fondu enchaîné : $seconds s';
  }

  @override
  String get crossfadePlainInAlbum => 'Pas de fondu dans un même album';

  @override
  String get crossfadePlainInAlbumHint =>
      'Dans un album, les titres s’enchaînent sans pause et sans chevauchement.';

  @override
  String get selectedRow => 'Sélectionné';

  @override
  String selectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sélectionnés',
      one: '1 sélectionné',
      zero: '0 sélectionné',
    );
    return '$_temp0';
  }

  @override
  String get selectAll => 'Tout sélectionner';

  @override
  String get exitSelection => 'Quitter la sélection';

  @override
  String get bulkActions => 'Actions';

  @override
  String playNextMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count titres seront lus ensuite',
      one: '1 titre sera lu ensuite',
      zero: '0 titre sera lu ensuite',
    );
    return '$_temp0';
  }

  @override
  String addedToQueueMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count titres ajoutés à la file d’attente',
      one: '1 titre ajouté à la file d’attente',
      zero: '0 titre ajouté à la file d’attente',
    );
    return '$_temp0';
  }

  @override
  String addedToPlaylistMany(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count titres ajoutés à « $name »',
      one: '1 titre ajouté à « $name »',
      zero: '0 titre ajouté à « $name »',
    );
    return '$_temp0';
  }

  @override
  String addedToPlaylistSkipped(int added, int skipped, String name) {
    return '$added ajoutés à « $name », $skipped déjà présents';
  }

  @override
  String allAlreadyInPlaylist(String name) {
    return 'Ils étaient déjà tous dans « $name »';
  }

  @override
  String favoritesAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count titres ajoutés aux favoris',
      one: '1 titre ajouté aux favoris',
      zero: '0 titre ajouté aux favoris',
    );
    return '$_temp0';
  }

  @override
  String favoritesRemoved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count titres retirés des favoris',
      one: '1 titre retiré des favoris',
      zero: '0 titre retiré des favoris',
    );
    return '$_temp0';
  }

  @override
  String get bulkAddToFavorites => 'Ajouter aux favoris';

  @override
  String get bulkRemoveFromFavorites => 'Retirer des favoris';

  @override
  String removeManyFromPlaylistTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Retirer $count titres de la playlist ?',
      one: 'Retirer 1 titre de la playlist ?',
      zero: 'Retirer 0 titre de la playlist ?',
    );
    return '$_temp0';
  }

  @override
  String get removeManyFromPlaylistBody =>
      'Les fichiers et la bibliothèque ne sont pas modifiés.';

  @override
  String removedManyFromPlaylist(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count titres retirés',
      one: '1 titre retiré',
      zero: '0 titre retiré',
    );
    return '$_temp0';
  }

  @override
  String removeManyFromLibraryTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Retirer $count titres de la bibliothèque ?',
      one: 'Retirer 1 titre de la bibliothèque ?',
      zero: 'Retirer 0 titre de la bibliothèque ?',
    );
    return '$_temp0';
  }

  @override
  String get removeManyFromLibraryBody =>
      'Les fichiers n’existent plus : ils disparaissent seulement de la bibliothèque (les favoris et playlists de ces titres seront perdus).';

  @override
  String removedManyFromLibrary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count titres retirés de la bibliothèque',
      one: '1 titre retiré de la bibliothèque',
      zero: '0 titre retiré de la bibliothèque',
    );
    return '$_temp0';
  }

  @override
  String ytDownloadsStarted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count téléchargements lancés',
      one: '1 téléchargement lancé',
      zero: '0 téléchargement lancé',
    );
    return '$_temp0';
  }

  @override
  String ytDownloadsSkipped(int started, int skipped) {
    return '$started téléchargements lancés, $skipped déjà dans la bibliothèque ou en cours';
  }

  @override
  String get ytNothingToDownload =>
      'Tous sont déjà dans la bibliothèque ou en cours';

  @override
  String get themeChiaro => 'Clair';

  @override
  String get settingsAccent => 'Couleur d’accent';

  @override
  String get accentViola => 'Violet';

  @override
  String get accentBlu => 'Bleu';

  @override
  String get accentAcqua => 'Turquoise';

  @override
  String get accentVerde => 'Vert';

  @override
  String get accentAmbra => 'Ambre';

  @override
  String get accentArancio => 'Orange';

  @override
  String get accentRosa => 'Rose';

  @override
  String get accentRosso => 'Rouge';

  @override
  String get onboardingSkip => 'Passer';

  @override
  String get onboardingNext => 'Suivant';

  @override
  String get onboardingStart => 'Commencer';

  @override
  String onboardingPageOf(int page, int total) {
    return 'Page $page sur $total';
  }

  @override
  String get onboardingWelcomeTitle => 'Bienvenue dans Codecore';

  @override
  String get onboardingWelcomeBody =>
      'Votre lecteur de musique personnel : sans compte et sans serveur. Votre musique reste sur votre appareil.';

  @override
  String get onboardingFoldersTitle => 'Votre musique';

  @override
  String get onboardingFoldersBody =>
      'Choisissez les dossiers où se trouvent vos titres. Codecore les lit seulement : il ne les modifie ni ne les déplace.';

  @override
  String onboardingFoldersAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dossiers ajoutés',
      one: '1 dossier ajouté',
    );
    return '$_temp0';
  }

  @override
  String get onboardingAllowAccess => 'Autoriser l’accès aux fichiers audio';

  @override
  String get onboardingAccessGranted => 'Accès autorisé';

  @override
  String get onboardingOnlineTitle => 'Fonctions en ligne';

  @override
  String get onboardingOnlineBody =>
      'Elles sont désactivées : Codecore ne se connecte jamais à Internet de lui-même. Vous pouvez les activer maintenant ou plus tard dans les Paramètres.';

  @override
  String get onboardingShareTitle => 'Téléchargements, Jam et partage';

  @override
  String get onboardingYoutubeBody =>
      'Vous pouvez télécharger des titres depuis YouTube sur votre appareil et les écouter comme le reste de votre musique.';

  @override
  String get onboardingJamBody =>
      'Avec une Jam, vous écoutez la même musique avec un autre appareil du même réseau.';

  @override
  String get onboardingSendBody =>
      'Vous pouvez envoyer des titres à d’autres appareils proches avec un PIN, sans passer par Internet.';

  @override
  String get historyTitle => 'Historique';

  @override
  String get historySubtitle => 'Ce que vous avez écouté';

  @override
  String get historyToday => 'Aujourd’hui';

  @override
  String get historyYesterday => 'Hier';

  @override
  String get historyEmpty => 'Ce que vous écoutez apparaîtra ici.';

  @override
  String get historyOff =>
      'L’historique est désactivé : activez-le dans Paramètres → Lecture.';

  @override
  String get historyClear => 'Effacer l’historique';

  @override
  String get historyClearTitle => 'Effacer l’historique ?';

  @override
  String get historyClearBody =>
      'Seule la liste des écoutes est effacée : les compteurs, les favoris et les playlists restent tels quels.';

  @override
  String get historyCleared => 'Historique effacé';

  @override
  String get settingsRecordHistory => 'Enregistrer l’historique d’écoute';

  @override
  String get settingsRecordHistoryHint =>
      'Il reste sur l’appareil. Désactivé, plus rien n’est ajouté à la liste.';

  @override
  String get statsTitle => 'Statistiques';

  @override
  String get statsSubtitle => 'Combien et quoi vous écoutez';

  @override
  String get statsMonth => 'Mois';

  @override
  String get statsYear => 'Année';

  @override
  String get statsPrevious => 'Période précédente';

  @override
  String get statsNext => 'Période suivante';

  @override
  String get statsEmpty => 'Aucune écoute sur cette période.';

  @override
  String statsPlays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count écoutes',
      one: '1 écoute',
      zero: '0 écoute',
    );
    return '$_temp0';
  }

  @override
  String statsDistinct(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count titres différents',
      one: '1 titre différent',
      zero: '0 titre différent',
    );
    return '$_temp0';
  }

  @override
  String statsHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String get statsTopTracks => 'Titres les plus écoutés';

  @override
  String get statsTopArtists => 'Artistes les plus écoutés';

  @override
  String get statsTopAlbums => 'Albums les plus écoutés';

  @override
  String get statsFavouriteHour => 'Heure préférée';

  @override
  String get statsFirstListen => 'Première écoute';

  @override
  String statsFirstValue(String title, String date) {
    return '$title · $date';
  }

  @override
  String get statsYourMonth => 'Votre mois';

  @override
  String statsTopArtistHome(String name) {
    return 'Le plus écouté : $name';
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
    return 'Je ne comprends pas « $term » : je le cherche comme du texte.';
  }

  @override
  String get ruleHelpTooltip => 'Aide de la recherche';

  @override
  String get smartPlaylistNew => 'Nouvelle playlist intelligente';

  @override
  String get smartPlaylistEdit => 'Modifier la playlist intelligente';

  @override
  String get smartPlaylistLabel => 'Playlist intelligente';

  @override
  String smartSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Playlist intelligente · $count titres',
      one: 'Playlist intelligente · 1 titre',
      zero: 'Playlist intelligente · 0 titre',
    );
    return '$_temp0';
  }

  @override
  String get smartName => 'Nom';

  @override
  String get smartNameRequired => 'Saisissez un nom';

  @override
  String get smartRules => 'Règles';

  @override
  String get smartRulesHint => 'artist:\"pink floyd\" -live year:1970..1979';

  @override
  String get smartNoRules =>
      'Sans règles, la playlist contient toute la bibliothèque.';

  @override
  String get smartSortBy => 'Trier par';

  @override
  String get smartSortMostPlayed => 'Les plus écoutés';

  @override
  String get smartSortRandom => 'Aléatoire';

  @override
  String get smartLimit => 'Limite de titres (facultatif)';

  @override
  String get smartTemplates => 'Modèles';

  @override
  String get smartTplNever => 'Jamais écoutés';

  @override
  String get smartTplRecent => 'Ajoutés récemment';

  @override
  String get smartTplTop => 'Les plus écoutés';

  @override
  String get smartTpl90s => 'Les années 90';

  @override
  String get smartConvert => 'Convertir en playlist normale';

  @override
  String smartConverted(String name) {
    return 'Playlist « $name » créée avec la liste actuelle';
  }

  @override
  String smartDeleteTitle(String name) {
    return 'Supprimer « $name » ?';
  }

  @override
  String get smartDeleteBody =>
      'Seule la règle est supprimée : les titres restent où ils sont.';

  @override
  String get smartAutoNote => 'La liste se met à jour toute seule.';

  @override
  String get tagsTitle => 'Étiquettes';

  @override
  String get tagsSubtitle => 'Vos propres étiquettes';

  @override
  String tagsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count étiquettes',
      one: '1 étiquette',
      zero: '0 étiquette',
    );
    return '$_temp0';
  }

  @override
  String get tagsEllipsis => 'Étiquettes…';

  @override
  String get tagNew => 'Nouvelle étiquette';

  @override
  String get tagRename => 'Renommer l’étiquette';

  @override
  String get tagColor => 'Couleur';

  @override
  String get tagNoColor => 'Aucune couleur';

  @override
  String get tagNameTaken => 'Une étiquette porte déjà ce nom';

  @override
  String tagDeleteTitle(String name) {
    return 'Supprimer l’étiquette « $name » ?';
  }

  @override
  String get tagDeleteBody =>
      'Seule l’étiquette est retirée des titres : ils restent dans la bibliothèque.';

  @override
  String get tagsEmpty =>
      'Pas encore d’étiquettes : créez-en une depuis le menu d’un titre.';

  @override
  String get tagAddToSelection => 'Ajouter une étiquette…';

  @override
  String get tagRemoveFromSelection => 'Retirer une étiquette…';

  @override
  String tagAssigned(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count titres étiquetés « $name »',
      one: '1 titre étiqueté « $name »',
      zero: '0 titre étiqueté « $name »',
    );
    return '$_temp0';
  }

  @override
  String tagUnassigned(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '« $name » retirée de $count titres',
      one: '« $name » retirée de 1 titre',
      zero: '« $name » retirée de 0 titre',
    );
    return '$_temp0';
  }

  @override
  String get tagNoneToRemove => 'Les titres choisis n’ont pas d’étiquettes.';

  @override
  String get ruleHelpTitle => 'Rechercher avec des opérateurs';

  @override
  String get ruleHelpIntro =>
      'Saisissez des mots comme d’habitude, ou ajoutez des opérateurs : tous doivent être vrais ensemble.';

  @override
  String get ruleHelpArtist =>
      'artist:\"pink floyd\" — titres d’un artiste (une partie du nom suffit) ; de même avec album:, genre:, folder:';

  @override
  String get ruleHelpYear =>
      'year:1990..1999 — une plage (aussi ouverte : year:..1980, year:2000..) ; year>1990, year<=1985';

  @override
  String get ruleHelpDuration =>
      'duration>5m — durée (m minutes, s secondes) : duration<90s, duration:2m..4m';

  @override
  String get ruleHelpAdded =>
      'added<30g — ajoutés il y a moins de 30 jours (g jours, sett semaines, mesi mois) : added>6mesi';

  @override
  String get ruleHelpNot =>
      '-live — le signe moins exclut : -artist:floyd, -\"live at\"';

  @override
  String get ruleHelpOr =>
      'rock OR jazz — OR (en majuscules) entre deux termes : un seul suffit';

  @override
  String get ruleHelpFlags =>
      'favorites, never-played — seulement les favoris, ou les titres jamais écoutés ; plays>10 pour les plus écoutés';

  @override
  String get ruleHelpOthers =>
      'tag:live, format:flac — une de vos étiquettes, ou le format du fichier (nom entier, sans tenir compte de la casse)';

  @override
  String get ruleHelpSmart =>
      'Les mêmes règles servent aux playlists intelligentes (Bibliothèque → + → Nouvelle playlist intelligente).';

  @override
  String get cleanupSection => 'Nettoyage de la bibliothèque';

  @override
  String get duplicatesTitle => 'Doublons';

  @override
  String get duplicatesTileHint =>
      'Le même morceau en plusieurs copies ou qualités';

  @override
  String get duplicatesIntro =>
      'Cherche le même morceau en plusieurs copies : le même fichier dans deux dossiers ou le même morceau en deux qualités. Un aperçu s’affiche avant toute fusion. Favoris, playlists, écoutes, paroles et étiquettes passent au morceau conservé ; les autres sont seulement masqués et se rétablissent depuis « Morceaux masqués ». Aucun fichier n’est supprimé sans une double confirmation.';

  @override
  String get duplicatesSearch => 'Chercher les doublons';

  @override
  String get duplicatesSearchAgain => 'Chercher à nouveau';

  @override
  String get duplicatesReading => 'Lecture de la bibliothèque…';

  @override
  String duplicatesHashing(int done, int total) {
    return 'Vérification des fichiers : $done sur $total';
  }

  @override
  String get duplicatesGrouping => 'Comparaison des morceaux…';

  @override
  String get duplicatesFailed => 'La recherche a échoué. Réessaie.';

  @override
  String get duplicatesNone => 'Aucun doublon trouvé';

  @override
  String duplicatesSummary(int groups, int hidden) {
    String _temp0 = intl.Intl.pluralLogic(
      groups,
      locale: localeName,
      other: '$groups groupes',
      one: '1 groupe',
    );
    String _temp1 = intl.Intl.pluralLogic(
      hidden,
      locale: localeName,
      other: '$hidden morceaux à masquer',
      one: '1 morceau à masquer',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get duplicatesExactBadge => 'Identiques';

  @override
  String get duplicatesProbableBadge => 'Probables';

  @override
  String get duplicatesKeepLabel => 'À garder';

  @override
  String get duplicatesPickKeep => 'Touche un morceau pour le garder';

  @override
  String get duplicatesMerge => 'Fusionner';

  @override
  String get duplicatesNotDuplicates => 'Pas des doublons';

  @override
  String duplicatesMergeAllExact(int count) {
    return 'Fusionner tous les identiques ($count)';
  }

  @override
  String get duplicatesMergeAllTitle => 'Fusionner tous les identiques ?';

  @override
  String duplicatesMergeAllBody(int groups, int hidden) {
    String _temp0 = intl.Intl.pluralLogic(
      groups,
      locale: localeName,
      other: '$groups groupes',
      one: '1 groupe',
    );
    String _temp1 = intl.Intl.pluralLogic(
      hidden,
      locale: localeName,
      other: '$hidden morceaux masqués',
      one: '1 morceau masqué',
    );
    return '$_temp0, $_temp1. Favoris, playlists, écoutes et paroles passent aux morceaux conservés.';
  }

  @override
  String duplicatesMerged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count morceaux masqués',
      one: '1 morceau masqué',
    );
    return 'Fusionné : $_temp0';
  }

  @override
  String duplicatesDeleteFiles(int count, String size) {
    return 'Supprimer aussi les fichiers ($count, $size)';
  }

  @override
  String get duplicatesDeleteListTitle => 'Supprimer ces fichiers ?';

  @override
  String get duplicatesDeleteListBody =>
      'Ils seront effacés de l’appareil et ne pourront pas être récupérés. Les morceaux conservés restent où ils sont.';

  @override
  String get duplicatesDeleteContinue => 'Continuer';

  @override
  String duplicatesDeleteFinalTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Supprimer définitivement $count fichiers ?',
      one: 'Supprimer définitivement 1 fichier ?',
    );
    return '$_temp0';
  }

  @override
  String duplicatesDeleteFinalBody(String size) {
    return 'Espace libéré : $size. Cette action est irréversible.';
  }

  @override
  String get duplicatesDeleteGo => 'Supprimer définitivement';

  @override
  String get duplicatesDeleteDoneTitle => 'Terminé';

  @override
  String duplicatesDeleteDone(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fichiers supprimés',
      one: '1 fichier supprimé',
    );
    return '$_temp0 ($size).';
  }

  @override
  String duplicatesDeleteFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fichiers non supprimés :',
      one: '1 fichier non supprimé :',
    );
    return '$_temp0';
  }

  @override
  String duplicatesDeleteSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count fichiers laissés tels quels : c’est le même fichier que le morceau conservé.',
      one: '1 fichier laissé tel quel : c’est le même fichier que le morceau conservé.',
    );
    return '$_temp0';
  }

  @override
  String get duplicatesDeleteAndroidHint =>
      'Sur Android, seuls les fichiers des dossiers accessibles à l’appli peuvent être supprimés.';

  @override
  String activityCleanup(int done, int total) {
    return 'Recherche de doublons : $done sur $total';
  }

  @override
  String get hiddenTracksTitle => 'Morceaux masqués';

  @override
  String hiddenTracksCount(int count) {
    return 'Morceaux masqués ($count)';
  }

  @override
  String get hiddenTracksEmpty => 'Aucun morceau masqué';

  @override
  String get hiddenTracksHint =>
      'Les doublons fusionnés n’apparaissent pas dans la bibliothèque. « Rétablir » les remet en place.';

  @override
  String get hiddenRestore => 'Rétablir';

  @override
  String hiddenRestored(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count morceaux rétablis',
      one: '1 morceau rétabli',
    );
    return '$_temp0';
  }

  @override
  String get albumMergeWith => 'Fusionner avec…';

  @override
  String get albumMergeTitle => 'Fusionner des albums';

  @override
  String albumMergeIntro(String name) {
    return 'Choisis les albums à fusionner avec « $name ». Les morceaux passent dans un seul album, avec le titre et l’artiste indiqués ; la pochette reste celle de « $name ».';
  }

  @override
  String get albumMergeSearch => 'Chercher un album';

  @override
  String get albumMergeNone => 'Il n’y a pas d’autres albums';

  @override
  String get albumFieldTitle => 'Titre de l’album';

  @override
  String get albumFieldArtist => 'Artiste de l’album';

  @override
  String get albumMergeAction => 'Fusionner les albums';

  @override
  String albumMerged(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count albums fusionnés dans « $name »',
      one: '1 album fusionné dans « $name »',
    );
    return '$_temp0';
  }

  @override
  String get moveToAlbum => 'Déplacer vers un nouvel album…';

  @override
  String get moveToAlbumTitle => 'Déplacer vers un album';

  @override
  String moveToAlbumBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count morceaux iront',
      one: '1 morceau ira',
    );
    return '$_temp0 dans l’album indiqué. S’il existe déjà, ils le rejoindront.';
  }

  @override
  String get moveToAlbumGo => 'Déplacer';

  @override
  String movedToAlbum(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count morceaux déplacés vers « $name »',
      one: '1 morceau déplacé vers « $name »',
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
      'Chercher aussi sur SoundCloud si un morceau est introuvable';

  @override
  String get importSoundCloudHint =>
      'Seulement pour les lignes d’un import que YouTube ne trouve pas : une recherche de plus par ligne. Désactivé par défaut.';

  @override
  String get ytHintSoundcloud => 'Chercher sur SoundCloud';

  @override
  String get playlistSourceTitle => 'Playlist ou chaîne YouTube';

  @override
  String get playlistSourceLoading => 'Lecture de la liste des vidéos…';

  @override
  String get playlistSourceName => 'Nom de la playlist';

  @override
  String playlistSourceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vidéos',
      one: '1 vidéo',
    );
    return '$_temp0';
  }

  @override
  String playlistSourceUnavailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vidéos indisponibles (privées ou supprimées)',
      one: '1 vidéo indisponible (privée ou supprimée)',
    );
    return '$_temp0';
  }

  @override
  String playlistSourceTruncated(int count) {
    return 'Affichage des $count premières vidéos.';
  }

  @override
  String playlistSourceLong(int count, String time) {
    return 'Cela fait $count vidéos : il faudra $time.';
  }

  @override
  String get playlistSourceNone => 'Aucune';

  @override
  String get playlistSourceEmpty => 'Il n’y a aucune vidéo à télécharger ici.';

  @override
  String playlistSourceGo(int count) {
    return 'Télécharger dans une playlist ($count)';
  }

  @override
  String playlistSourceStarted(String name) {
    return 'Téléchargements lancés dans la playlist « $name »';
  }

  @override
  String get podcastsTitle => 'Podcasts';

  @override
  String podcastsSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count podcasts',
      one: '1 podcast',
    );
    return '$_temp0';
  }

  @override
  String get podcastsNotice =>
      'Les podcasts ne se mettent à jour que lorsque tu le demandes.';

  @override
  String get podcastsEmpty => 'Tu n’es abonné à aucun podcast.';

  @override
  String get podcastAdd => 'Ajouter un podcast';

  @override
  String get podcastRefreshAll => 'Tout actualiser';

  @override
  String get podcastRefresh => 'Actualiser';

  @override
  String podcastRefreshed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nouveaux épisodes',
      one: '1 nouvel épisode',
      zero: 'Aucun nouvel épisode',
    );
    return '$_temp0';
  }

  @override
  String podcastRefreshFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count podcasts non actualisés',
      one: '1 podcast non actualisé',
    );
    return '$_temp0';
  }

  @override
  String get podcastFeedUrl => 'Adresse du flux';

  @override
  String get podcastSubscribe => 'S’abonner';

  @override
  String get podcastSearchHint => 'Chercher un podcast par nom';

  @override
  String get podcastSearchNone => 'Aucun podcast trouvé';

  @override
  String podcastSubscribed(String name) {
    return 'Abonné à « $name »';
  }

  @override
  String podcastEpisodesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count épisodes',
      one: '1 épisode',
    );
    return '$_temp0';
  }

  @override
  String podcastToListen(int count) {
    return '$count à écouter';
  }

  @override
  String get podcastNoEpisodes => 'Aucun épisode.';

  @override
  String get podcastStateDownloaded => 'Téléchargé';

  @override
  String podcastStateDownloading(int percent) {
    return 'Téléchargement… $percent %';
  }

  @override
  String get podcastStateHeard => 'Écouté';

  @override
  String podcastStateRemaining(String time) {
    return 'Il reste $time';
  }

  @override
  String get podcastMarkHeard => 'Marquer comme écouté';

  @override
  String get podcastMarkNotHeard => 'Marquer comme non écouté';

  @override
  String get podcastDeleteFile => 'Supprimer le fichier';

  @override
  String get podcastAutoDelete => 'Supprimer les épisodes écoutés';

  @override
  String get podcastAutoDeleteNever => 'Jamais';

  @override
  String podcastAutoDeleteAfter(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Après $days jours',
      one: 'Après 1 jour',
    );
    return '$_temp0';
  }

  @override
  String get podcastUnsubscribe => 'Se désabonner';

  @override
  String get podcastUnsubscribeTitle => 'Se désabonner ?';

  @override
  String podcastUnsubscribeBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count épisodes téléchargés',
      one: '1 épisode téléchargé',
    );
    return 'Le podcast et $_temp0 seront supprimés de l’appareil.';
  }

  @override
  String podcastLastChecked(String when) {
    return 'Actualisé $when';
  }

  @override
  String get podcastNeverChecked => 'Jamais actualisé';

  @override
  String get podcastErrInvalidUrl =>
      'Cela ne ressemble pas à une adresse web valide.';

  @override
  String get podcastErrTooLarge => 'Le flux est trop volumineux.';

  @override
  String get podcastErrNetwork => 'Impossible de joindre le serveur.';

  @override
  String get podcastErrNotFeed => 'Cette adresse n’est pas un flux de podcast.';

  @override
  String get podcastErrParserMissing =>
      'La lecture des flux n’est pas encore disponible dans cette version.';

  @override
  String get podcastErrUnsupportedFormat => 'Format audio non pris en charge.';
}
