import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('it'),
  ];

  /// No description provided for @appName.
  ///
  /// In it, this message translates to:
  /// **'Codecore'**
  String get appName;

  /// No description provided for @chooseFolder.
  ///
  /// In it, this message translates to:
  /// **'Scegli cartella'**
  String get chooseFolder;

  /// No description provided for @scan.
  ///
  /// In it, this message translates to:
  /// **'Scansiona'**
  String get scan;

  /// No description provided for @noTracks.
  ///
  /// In it, this message translates to:
  /// **'Nessun brano. Scegli una cartella e scansiona.'**
  String get noTracks;

  /// No description provided for @openSettings.
  ///
  /// In it, this message translates to:
  /// **'Apri impostazioni'**
  String get openSettings;

  /// No description provided for @permissionDenied.
  ///
  /// In it, this message translates to:
  /// **'Permesso di lettura audio negato'**
  String get permissionDenied;

  /// No description provided for @permissionExplain.
  ///
  /// In it, this message translates to:
  /// **'Codecore ha bisogno del permesso di leggere i file audio per mostrare la tua musica.'**
  String get permissionExplain;

  /// No description provided for @navLibrary.
  ///
  /// In it, this message translates to:
  /// **'Libreria'**
  String get navLibrary;

  /// No description provided for @navFavorites.
  ///
  /// In it, this message translates to:
  /// **'Preferiti'**
  String get navFavorites;

  /// No description provided for @navPlaylists.
  ///
  /// In it, this message translates to:
  /// **'Playlist'**
  String get navPlaylists;

  /// No description provided for @navSettings.
  ///
  /// In it, this message translates to:
  /// **'Impostazioni'**
  String get navSettings;

  /// No description provided for @tracks.
  ///
  /// In it, this message translates to:
  /// **'Brani'**
  String get tracks;

  /// No description provided for @albums.
  ///
  /// In it, this message translates to:
  /// **'Album'**
  String get albums;

  /// No description provided for @artists.
  ///
  /// In it, this message translates to:
  /// **'Artisti'**
  String get artists;

  /// No description provided for @searchHint.
  ///
  /// In it, this message translates to:
  /// **'Cerca'**
  String get searchHint;

  /// No description provided for @sortBy.
  ///
  /// In it, this message translates to:
  /// **'Ordina per'**
  String get sortBy;

  /// No description provided for @addMusicFolder.
  ///
  /// In it, this message translates to:
  /// **'Aggiungi la tua cartella musicale'**
  String get addMusicFolder;

  /// No description provided for @addFolder.
  ///
  /// In it, this message translates to:
  /// **'Aggiungi cartella'**
  String get addFolder;

  /// No description provided for @folders.
  ///
  /// In it, this message translates to:
  /// **'Cartelle musicali'**
  String get folders;

  /// No description provided for @refreshLibrary.
  ///
  /// In it, this message translates to:
  /// **'Aggiorna libreria'**
  String get refreshLibrary;

  /// No description provided for @removeFolder.
  ///
  /// In it, this message translates to:
  /// **'Rimuovi cartella'**
  String get removeFolder;

  /// No description provided for @unknownArtist.
  ///
  /// In it, this message translates to:
  /// **'Artista sconosciuto'**
  String get unknownArtist;

  /// No description provided for @unknownAlbum.
  ///
  /// In it, this message translates to:
  /// **'Album sconosciuto'**
  String get unknownAlbum;

  /// No description provided for @variousArtists.
  ///
  /// In it, this message translates to:
  /// **'Artisti vari'**
  String get variousArtists;

  /// No description provided for @play.
  ///
  /// In it, this message translates to:
  /// **'Riproduci'**
  String get play;

  /// No description provided for @shuffle.
  ///
  /// In it, this message translates to:
  /// **'Casuale'**
  String get shuffle;

  /// No description provided for @queue.
  ///
  /// In it, this message translates to:
  /// **'Coda'**
  String get queue;

  /// No description provided for @nowPlaying.
  ///
  /// In it, this message translates to:
  /// **'In riproduzione'**
  String get nowPlaying;

  /// No description provided for @nothingPlaying.
  ///
  /// In it, this message translates to:
  /// **'Nessun brano in riproduzione'**
  String get nothingPlaying;

  /// No description provided for @mute.
  ///
  /// In it, this message translates to:
  /// **'Muto'**
  String get mute;

  /// No description provided for @scanning.
  ///
  /// In it, this message translates to:
  /// **'Scansione in corso…'**
  String get scanning;

  /// No description provided for @emptyQueue.
  ///
  /// In it, this message translates to:
  /// **'La coda è vuota'**
  String get emptyQueue;

  /// No description provided for @noResults.
  ///
  /// In it, this message translates to:
  /// **'Nessun risultato'**
  String get noResults;

  /// No description provided for @sortDefault.
  ///
  /// In it, this message translates to:
  /// **'Predefinito'**
  String get sortDefault;

  /// No description provided for @sortTitle.
  ///
  /// In it, this message translates to:
  /// **'Titolo'**
  String get sortTitle;

  /// No description provided for @sortArtist.
  ///
  /// In it, this message translates to:
  /// **'Artista'**
  String get sortArtist;

  /// No description provided for @sortAlbum.
  ///
  /// In it, this message translates to:
  /// **'Album'**
  String get sortAlbum;

  /// No description provided for @sortYear.
  ///
  /// In it, this message translates to:
  /// **'Anno'**
  String get sortYear;

  /// No description provided for @sortAdded.
  ///
  /// In it, this message translates to:
  /// **'Aggiunti di recente'**
  String get sortAdded;

  /// No description provided for @sortDuration.
  ///
  /// In it, this message translates to:
  /// **'Durata'**
  String get sortDuration;

  /// No description provided for @tracksCount.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, one{1 brano} other{{count} brani}}'**
  String tracksCount(int count);

  /// No description provided for @albumsCount.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, one{1 album} other{{count} album}}'**
  String albumsCount(int count);

  /// No description provided for @missingTracksCount.
  ///
  /// In it, this message translates to:
  /// **'Brani non trovati ({count})'**
  String missingTracksCount(int count);

  /// No description provided for @addedToFavorites.
  ///
  /// In it, this message translates to:
  /// **'Aggiunto ai preferiti'**
  String get addedToFavorites;

  /// No description provided for @removedFromFavorites.
  ///
  /// In it, this message translates to:
  /// **'Rimosso dai preferiti'**
  String get removedFromFavorites;

  /// No description provided for @undo.
  ///
  /// In it, this message translates to:
  /// **'Annulla'**
  String get undo;

  /// No description provided for @noFavorites.
  ///
  /// In it, this message translates to:
  /// **'Nessun preferito ancora'**
  String get noFavorites;

  /// No description provided for @newPlaylist.
  ///
  /// In it, this message translates to:
  /// **'Nuova playlist'**
  String get newPlaylist;

  /// No description provided for @newPlaylistEllipsis.
  ///
  /// In it, this message translates to:
  /// **'Nuova playlist…'**
  String get newPlaylistEllipsis;

  /// No description provided for @playlistName.
  ///
  /// In it, this message translates to:
  /// **'Nome della playlist'**
  String get playlistName;

  /// No description provided for @create.
  ///
  /// In it, this message translates to:
  /// **'Crea'**
  String get create;

  /// No description provided for @cancel.
  ///
  /// In it, this message translates to:
  /// **'Annulla'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In it, this message translates to:
  /// **'Salva'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In it, this message translates to:
  /// **'Elimina'**
  String get delete;

  /// No description provided for @rename.
  ///
  /// In it, this message translates to:
  /// **'Rinomina'**
  String get rename;

  /// No description provided for @noPlaylists.
  ///
  /// In it, this message translates to:
  /// **'Nessuna playlist. Creane una.'**
  String get noPlaylists;

  /// No description provided for @addToPlaylist.
  ///
  /// In it, this message translates to:
  /// **'Aggiungi a playlist…'**
  String get addToPlaylist;

  /// No description provided for @addedToPlaylist.
  ///
  /// In it, this message translates to:
  /// **'Aggiunto a «{name}»'**
  String addedToPlaylist(String name);

  /// No description provided for @playNext.
  ///
  /// In it, this message translates to:
  /// **'Riproduci dopo'**
  String get playNext;

  /// No description provided for @addToQueue.
  ///
  /// In it, this message translates to:
  /// **'Aggiungi in coda'**
  String get addToQueue;

  /// No description provided for @addedToQueue.
  ///
  /// In it, this message translates to:
  /// **'Aggiunto in coda'**
  String get addedToQueue;

  /// No description provided for @favorite.
  ///
  /// In it, this message translates to:
  /// **'Preferito'**
  String get favorite;

  /// No description provided for @removeFromFavorites.
  ///
  /// In it, this message translates to:
  /// **'Rimuovi dai preferiti'**
  String get removeFromFavorites;

  /// No description provided for @removeFromList.
  ///
  /// In it, this message translates to:
  /// **'Rimuovi'**
  String get removeFromList;

  /// No description provided for @editInfo.
  ///
  /// In it, this message translates to:
  /// **'Modifica info'**
  String get editInfo;

  /// No description provided for @details.
  ///
  /// In it, this message translates to:
  /// **'Dettagli'**
  String get details;

  /// No description provided for @showInFolder.
  ///
  /// In it, this message translates to:
  /// **'Mostra nella cartella'**
  String get showInFolder;

  /// No description provided for @detailPath.
  ///
  /// In it, this message translates to:
  /// **'Percorso'**
  String get detailPath;

  /// No description provided for @detailFormat.
  ///
  /// In it, this message translates to:
  /// **'Formato'**
  String get detailFormat;

  /// No description provided for @detailSize.
  ///
  /// In it, this message translates to:
  /// **'Dimensione'**
  String get detailSize;

  /// No description provided for @detailDuration.
  ///
  /// In it, this message translates to:
  /// **'Durata'**
  String get detailDuration;

  /// No description provided for @detailAdded.
  ///
  /// In it, this message translates to:
  /// **'Aggiunto il'**
  String get detailAdded;

  /// No description provided for @detailPlays.
  ///
  /// In it, this message translates to:
  /// **'Riproduzioni'**
  String get detailPlays;

  /// No description provided for @close.
  ///
  /// In it, this message translates to:
  /// **'Chiudi'**
  String get close;

  /// No description provided for @fieldTitle.
  ///
  /// In it, this message translates to:
  /// **'Titolo'**
  String get fieldTitle;

  /// No description provided for @fieldArtist.
  ///
  /// In it, this message translates to:
  /// **'Artista'**
  String get fieldArtist;

  /// No description provided for @fieldAlbum.
  ///
  /// In it, this message translates to:
  /// **'Album'**
  String get fieldAlbum;

  /// No description provided for @fieldAlbumArtist.
  ///
  /// In it, this message translates to:
  /// **'Artista album'**
  String get fieldAlbumArtist;

  /// No description provided for @fieldYear.
  ///
  /// In it, this message translates to:
  /// **'Anno'**
  String get fieldYear;

  /// No description provided for @fieldTrackNumber.
  ///
  /// In it, this message translates to:
  /// **'Numero traccia'**
  String get fieldTrackNumber;

  /// No description provided for @fieldGenre.
  ///
  /// In it, this message translates to:
  /// **'Genere'**
  String get fieldGenre;

  /// No description provided for @restoreFromFile.
  ///
  /// In it, this message translates to:
  /// **'Ripristina dai tag del file'**
  String get restoreFromFile;

  /// No description provided for @titleRequired.
  ///
  /// In it, this message translates to:
  /// **'Il titolo non può essere vuoto'**
  String get titleRequired;

  /// No description provided for @settingsAppearance.
  ///
  /// In it, this message translates to:
  /// **'Aspetto'**
  String get settingsAppearance;

  /// No description provided for @settingsTheme.
  ///
  /// In it, this message translates to:
  /// **'Tema'**
  String get settingsTheme;

  /// No description provided for @themeNotte.
  ///
  /// In it, this message translates to:
  /// **'Notte viola'**
  String get themeNotte;

  /// No description provided for @themeOled.
  ///
  /// In it, this message translates to:
  /// **'Nero puro'**
  String get themeOled;

  /// No description provided for @settingsTextSize.
  ///
  /// In it, this message translates to:
  /// **'Dimensione testo'**
  String get settingsTextSize;

  /// No description provided for @textSmall.
  ///
  /// In it, this message translates to:
  /// **'Piccolo'**
  String get textSmall;

  /// No description provided for @textNormal.
  ///
  /// In it, this message translates to:
  /// **'Normale'**
  String get textNormal;

  /// No description provided for @textLarge.
  ///
  /// In it, this message translates to:
  /// **'Grande'**
  String get textLarge;

  /// No description provided for @settingsCompact.
  ///
  /// In it, this message translates to:
  /// **'Modalità compatta'**
  String get settingsCompact;

  /// No description provided for @settingsReducedMotion.
  ///
  /// In it, this message translates to:
  /// **'Animazioni ridotte'**
  String get settingsReducedMotion;

  /// No description provided for @settingsLanguage.
  ///
  /// In it, this message translates to:
  /// **'Lingua'**
  String get settingsLanguage;

  /// No description provided for @settingsLibrary.
  ///
  /// In it, this message translates to:
  /// **'Libreria'**
  String get settingsLibrary;

  /// No description provided for @rescanNow.
  ///
  /// In it, this message translates to:
  /// **'Riscansiona ora'**
  String get rescanNow;

  /// No description provided for @clearCoverCache.
  ///
  /// In it, this message translates to:
  /// **'Svuota cache copertine'**
  String get clearCoverCache;

  /// No description provided for @coverCacheCleared.
  ///
  /// In it, this message translates to:
  /// **'Cache copertine svuotata'**
  String get coverCacheCleared;

  /// No description provided for @settingsOnline.
  ///
  /// In it, this message translates to:
  /// **'Online'**
  String get settingsOnline;

  /// No description provided for @autoEnrich.
  ///
  /// In it, this message translates to:
  /// **'Arricchimento automatico'**
  String get autoEnrich;

  /// No description provided for @autoEnrichHint.
  ///
  /// In it, this message translates to:
  /// **'Cerca metadati e copertine online per i brani nuovi'**
  String get autoEnrichHint;

  /// No description provided for @autoLyrics.
  ///
  /// In it, this message translates to:
  /// **'Testi automatici'**
  String get autoLyrics;

  /// No description provided for @autoLyricsHint.
  ///
  /// In it, this message translates to:
  /// **'Scarica i testi da LRCLIB per i brani nuovi'**
  String get autoLyricsHint;

  /// No description provided for @settingsAbout.
  ///
  /// In it, this message translates to:
  /// **'Info'**
  String get settingsAbout;

  /// No description provided for @appVersion.
  ///
  /// In it, this message translates to:
  /// **'Versione {version}'**
  String appVersion(String version);

  /// No description provided for @licenses.
  ///
  /// In it, this message translates to:
  /// **'Licenze'**
  String get licenses;

  /// No description provided for @personalUse.
  ///
  /// In it, this message translates to:
  /// **'App per uso personale'**
  String get personalUse;

  /// No description provided for @missingTracksTitle.
  ///
  /// In it, this message translates to:
  /// **'Brani non trovati'**
  String get missingTracksTitle;

  /// No description provided for @removeFromLibrary.
  ///
  /// In it, this message translates to:
  /// **'Rimuovi dalla libreria'**
  String get removeFromLibrary;

  /// No description provided for @ignore.
  ///
  /// In it, this message translates to:
  /// **'Ignora'**
  String get ignore;

  /// No description provided for @confirmRemoveTitle.
  ///
  /// In it, this message translates to:
  /// **'Rimuovere dalla libreria?'**
  String get confirmRemoveTitle;

  /// No description provided for @confirmRemoveBody.
  ///
  /// In it, this message translates to:
  /// **'Il file non viene toccato; perdi preferiti e playlist di questo brano.'**
  String get confirmRemoveBody;

  /// No description provided for @noMissingTracks.
  ///
  /// In it, this message translates to:
  /// **'Nessun brano mancante'**
  String get noMissingTracks;

  /// No description provided for @retry.
  ///
  /// In it, this message translates to:
  /// **'Riprova'**
  String get retry;

  /// No description provided for @scanFailed.
  ///
  /// In it, this message translates to:
  /// **'Scansione non riuscita: {error}'**
  String scanFailed(String error);

  /// No description provided for @playbackError.
  ///
  /// In it, this message translates to:
  /// **'Impossibile riprodurre «{title}»: {reason}'**
  String playbackError(String reason, String title);

  /// No description provided for @reasonFileMissing.
  ///
  /// In it, this message translates to:
  /// **'file non trovato'**
  String get reasonFileMissing;

  /// No description provided for @reasonUnplayable.
  ///
  /// In it, this message translates to:
  /// **'file non riproducibile'**
  String get reasonUnplayable;

  /// No description provided for @reasonNotInLibrary.
  ///
  /// In it, this message translates to:
  /// **'brano non presente in libreria'**
  String get reasonNotInLibrary;

  /// No description provided for @searchWeb.
  ///
  /// In it, this message translates to:
  /// **'Cerca info sul web'**
  String get searchWeb;

  /// No description provided for @enrichPreviewTitle.
  ///
  /// In it, this message translates to:
  /// **'Anteprima informazioni'**
  String get enrichPreviewTitle;

  /// No description provided for @currentValue.
  ///
  /// In it, this message translates to:
  /// **'Attuale'**
  String get currentValue;

  /// No description provided for @proposedValue.
  ///
  /// In it, this message translates to:
  /// **'Proposto'**
  String get proposedValue;

  /// No description provided for @apply.
  ///
  /// In it, this message translates to:
  /// **'Applica'**
  String get apply;

  /// No description provided for @nothingFound.
  ///
  /// In it, this message translates to:
  /// **'Nessuna informazione trovata'**
  String get nothingFound;

  /// No description provided for @userEditedLocked.
  ///
  /// In it, this message translates to:
  /// **'Modificato da te: non viene sovrascritto'**
  String get userEditedLocked;

  /// No description provided for @fieldCover.
  ///
  /// In it, this message translates to:
  /// **'Copertina'**
  String get fieldCover;

  /// No description provided for @fieldLyrics.
  ///
  /// In it, this message translates to:
  /// **'Testo'**
  String get fieldLyrics;

  /// No description provided for @fieldCuriosity.
  ///
  /// In it, this message translates to:
  /// **'Curiosità'**
  String get fieldCuriosity;

  /// No description provided for @enrichAlbum.
  ///
  /// In it, this message translates to:
  /// **'Arricchisci album'**
  String get enrichAlbum;

  /// No description provided for @enrichLibrary.
  ///
  /// In it, this message translates to:
  /// **'Arricchisci tutta la libreria'**
  String get enrichLibrary;

  /// No description provided for @enrichConfirmTitle.
  ///
  /// In it, this message translates to:
  /// **'Arricchire la libreria?'**
  String get enrichConfirmTitle;

  /// No description provided for @enrichConfirmBody.
  ///
  /// In it, this message translates to:
  /// **'{count} brani, circa {minutes} minuti. Vengono riempiti solo i campi vuoti.'**
  String enrichConfirmBody(int count, int minutes);

  /// No description provided for @enrichRunning.
  ///
  /// In it, this message translates to:
  /// **'Arricchimento {done}/{total}'**
  String enrichRunning(int done, int total);

  /// No description provided for @enrichResult.
  ///
  /// In it, this message translates to:
  /// **'{updated} aggiornati, {notFound} non trovati'**
  String enrichResult(int notFound, int updated);

  /// No description provided for @enrichBusy.
  ///
  /// In it, this message translates to:
  /// **'Un arricchimento è già in corso'**
  String get enrichBusy;

  /// No description provided for @serviceUnavailable.
  ///
  /// In it, this message translates to:
  /// **'Servizio non disponibile, riprova più tardi'**
  String get serviceUnavailable;

  /// No description provided for @lyrics.
  ///
  /// In it, this message translates to:
  /// **'Testo'**
  String get lyrics;

  /// No description provided for @searchLyrics.
  ///
  /// In it, this message translates to:
  /// **'Cerca testo'**
  String get searchLyrics;

  /// No description provided for @noLyrics.
  ///
  /// In it, this message translates to:
  /// **'Nessun testo disponibile'**
  String get noLyrics;

  /// No description provided for @lyricsNotFound.
  ///
  /// In it, this message translates to:
  /// **'Testo non trovato'**
  String get lyricsNotFound;

  /// No description provided for @copy.
  ///
  /// In it, this message translates to:
  /// **'Copia'**
  String get copy;

  /// No description provided for @copied.
  ///
  /// In it, this message translates to:
  /// **'Copiato'**
  String get copied;

  /// No description provided for @sourceWikipedia.
  ///
  /// In it, this message translates to:
  /// **'Fonte: Wikipedia (CC BY-SA)'**
  String get sourceWikipedia;

  /// No description provided for @youtube.
  ///
  /// In it, this message translates to:
  /// **'YouTube'**
  String get youtube;

  /// No description provided for @ytHint.
  ///
  /// In it, this message translates to:
  /// **'Cerca o incolla un link'**
  String get ytHint;

  /// No description provided for @ytDownload.
  ///
  /// In it, this message translates to:
  /// **'Scarica'**
  String get ytDownload;

  /// No description provided for @ytAlreadyInLibrary.
  ///
  /// In it, this message translates to:
  /// **'Già in libreria'**
  String get ytAlreadyInLibrary;

  /// No description provided for @ytNoResults.
  ///
  /// In it, this message translates to:
  /// **'Nessun risultato'**
  String get ytNoResults;

  /// No description provided for @ytQueued.
  ///
  /// In it, this message translates to:
  /// **'In coda'**
  String get ytQueued;

  /// No description provided for @ytDownloading.
  ///
  /// In it, this message translates to:
  /// **'Download in corso'**
  String get ytDownloading;

  /// No description provided for @ytDone.
  ///
  /// In it, this message translates to:
  /// **'Completato'**
  String get ytDone;

  /// No description provided for @ytFailed.
  ///
  /// In it, this message translates to:
  /// **'Non riuscito'**
  String get ytFailed;

  /// No description provided for @ytCancelled.
  ///
  /// In it, this message translates to:
  /// **'Annullato'**
  String get ytCancelled;

  /// No description provided for @ytClearCompleted.
  ///
  /// In it, this message translates to:
  /// **'Svuota completati'**
  String get ytClearCompleted;

  /// No description provided for @ytCancel.
  ///
  /// In it, this message translates to:
  /// **'Annulla download'**
  String get ytCancel;

  /// No description provided for @ytErrUnavailable.
  ///
  /// In it, this message translates to:
  /// **'Video non disponibile (età/regione/privato)'**
  String get ytErrUnavailable;

  /// No description provided for @ytErrNetwork.
  ///
  /// In it, this message translates to:
  /// **'Rete non disponibile'**
  String get ytErrNetwork;

  /// No description provided for @ytErrChanged.
  ///
  /// In it, this message translates to:
  /// **'YouTube ha cambiato qualcosa: aggiorna l’app o il pacchetto'**
  String get ytErrChanged;

  /// No description provided for @ytNoFolder.
  ///
  /// In it, this message translates to:
  /// **'Aggiungi prima una cartella musicale'**
  String get ytNoFolder;

  /// No description provided for @ytLegal.
  ///
  /// In it, this message translates to:
  /// **'Solo per uso personale. Rispetta i diritti d’autore e i termini di YouTube.'**
  String get ytLegal;

  /// No description provided for @useDefaultFolder.
  ///
  /// In it, this message translates to:
  /// **'Usa la cartella Musica del dispositivo'**
  String get useDefaultFolder;

  /// No description provided for @ytErrToolMissing.
  ///
  /// In it, this message translates to:
  /// **'yt-dlp non trovato: installalo (pip install -U yt-dlp) e riprova'**
  String get ytErrToolMissing;

  /// No description provided for @ytErrRateLimited.
  ///
  /// In it, this message translates to:
  /// **'YouTube ha chiesto di rallentare: riprova tra qualche minuto'**
  String get ytErrRateLimited;

  /// No description provided for @playlistChangeCover.
  ///
  /// In it, this message translates to:
  /// **'Cambia copertina'**
  String get playlistChangeCover;

  /// No description provided for @playlistRemoveCover.
  ///
  /// In it, this message translates to:
  /// **'Rimuovi copertina'**
  String get playlistRemoveCover;

  /// No description provided for @coverTooLarge.
  ///
  /// In it, this message translates to:
  /// **'Immagine troppo grande (max 4 MB)'**
  String get coverTooLarge;

  /// No description provided for @addSongs.
  ///
  /// In it, this message translates to:
  /// **'Aggiungi brani'**
  String get addSongs;

  /// No description provided for @addNSongs.
  ///
  /// In it, this message translates to:
  /// **'Aggiungi ({count})'**
  String addNSongs(int count);

  /// No description provided for @allSongsInPlaylist.
  ///
  /// In it, this message translates to:
  /// **'Tutti i brani sono già nella playlist'**
  String get allSongsInPlaylist;

  /// No description provided for @shareTitle.
  ///
  /// In it, this message translates to:
  /// **'Condivisione'**
  String get shareTitle;

  /// No description provided for @shareSend.
  ///
  /// In it, this message translates to:
  /// **'Invia'**
  String get shareSend;

  /// No description provided for @shareReceive.
  ///
  /// In it, this message translates to:
  /// **'Ricevi'**
  String get shareReceive;

  /// No description provided for @shareAll.
  ///
  /// In it, this message translates to:
  /// **'Tutta la libreria'**
  String get shareAll;

  /// No description provided for @shareSelection.
  ///
  /// In it, this message translates to:
  /// **'Selezione ({count} brani)'**
  String shareSelection(int count);

  /// No description provided for @sharePick.
  ///
  /// In it, this message translates to:
  /// **'Scegli brani'**
  String get sharePick;

  /// No description provided for @shareStart.
  ///
  /// In it, this message translates to:
  /// **'Avvia condivisione'**
  String get shareStart;

  /// No description provided for @shareStop.
  ///
  /// In it, this message translates to:
  /// **'Ferma'**
  String get shareStop;

  /// No description provided for @shareActive.
  ///
  /// In it, this message translates to:
  /// **'Condivisione attiva'**
  String get shareActive;

  /// No description provided for @shareAddress.
  ///
  /// In it, this message translates to:
  /// **'Indirizzo (IP:porta)'**
  String get shareAddress;

  /// No description provided for @sharePin.
  ///
  /// In it, this message translates to:
  /// **'PIN'**
  String get sharePin;

  /// No description provided for @shareConnect.
  ///
  /// In it, this message translates to:
  /// **'Connetti'**
  String get shareConnect;

  /// No description provided for @shareDownloadSelected.
  ///
  /// In it, this message translates to:
  /// **'Scarica selezionati ({count})'**
  String shareDownloadSelected(int count);

  /// No description provided for @shareProgress.
  ///
  /// In it, this message translates to:
  /// **'Brano {done} di {total}'**
  String shareProgress(int done, int total);

  /// No description provided for @shareDone.
  ///
  /// In it, this message translates to:
  /// **'{count} brani ricevuti'**
  String shareDone(int count);

  /// No description provided for @shareConnectedTo.
  ///
  /// In it, this message translates to:
  /// **'Connesso a {name}'**
  String shareConnectedTo(String name);

  /// No description provided for @shareErrUnreachable.
  ///
  /// In it, this message translates to:
  /// **'Dispositivo non raggiungibile: controlla indirizzo e Wi‑Fi'**
  String get shareErrUnreachable;

  /// No description provided for @shareErrPin.
  ///
  /// In it, this message translates to:
  /// **'PIN errato'**
  String get shareErrPin;

  /// No description provided for @shareErrBlocked.
  ///
  /// In it, this message translates to:
  /// **'Troppi tentativi: riprova tra un minuto'**
  String get shareErrBlocked;

  /// No description provided for @shareErrNotCodecore.
  ///
  /// In it, this message translates to:
  /// **'Non è un dispositivo Codecore'**
  String get shareErrNotCodecore;

  /// No description provided for @shareErrFailed.
  ///
  /// In it, this message translates to:
  /// **'Trasferimento non riuscito'**
  String get shareErrFailed;

  /// No description provided for @shareNoNetwork.
  ///
  /// In it, this message translates to:
  /// **'Nessuna rete locale trovata'**
  String get shareNoNetwork;

  /// No description provided for @shareFirewall.
  ///
  /// In it, this message translates to:
  /// **'Windows può chiedere il permesso del firewall alla prima condivisione.'**
  String get shareFirewall;

  /// No description provided for @shareHint.
  ///
  /// In it, this message translates to:
  /// **'Sullo stesso Wi‑Fi, apri «Ricevi» sull’altro dispositivo e inserisci indirizzo e PIN.'**
  String get shareHint;

  /// No description provided for @shareMenu.
  ///
  /// In it, this message translates to:
  /// **'Condividi…'**
  String get shareMenu;

  /// No description provided for @shareDeviceName.
  ///
  /// In it, this message translates to:
  /// **'Nome dispositivo'**
  String get shareDeviceName;

  /// No description provided for @importOld.
  ///
  /// In it, this message translates to:
  /// **'Importa dalla vecchia app'**
  String get importOld;

  /// No description provided for @importOldHint.
  ///
  /// In it, this message translates to:
  /// **'Scegli codecore_library.db della versione Python'**
  String get importOldHint;

  /// No description provided for @importSummary.
  ///
  /// In it, this message translates to:
  /// **'{favorites} preferiti, {playlists} playlist, {lyrics} testi importati, {unmatched} non abbinati'**
  String importSummary(int favorites, int lyrics, int playlists, int unmatched);

  /// No description provided for @importFailed.
  ///
  /// In it, this message translates to:
  /// **'Importazione non riuscita: file non valido'**
  String get importFailed;

  /// No description provided for @sleepTimer.
  ///
  /// In it, this message translates to:
  /// **'Timer di spegnimento'**
  String get sleepTimer;

  /// No description provided for @sleepMinutes.
  ///
  /// In it, this message translates to:
  /// **'{count} minuti'**
  String sleepMinutes(int count);

  /// No description provided for @sleepEndOfTrack.
  ///
  /// In it, this message translates to:
  /// **'A fine brano'**
  String get sleepEndOfTrack;

  /// No description provided for @sleepCancel.
  ///
  /// In it, this message translates to:
  /// **'Annulla timer'**
  String get sleepCancel;

  /// No description provided for @pause.
  ///
  /// In it, this message translates to:
  /// **'Pausa'**
  String get pause;

  /// No description provided for @nextTrack.
  ///
  /// In it, this message translates to:
  /// **'Brano successivo'**
  String get nextTrack;

  /// No description provided for @previousTrack.
  ///
  /// In it, this message translates to:
  /// **'Brano precedente'**
  String get previousTrack;

  /// No description provided for @repeat.
  ///
  /// In it, this message translates to:
  /// **'Ripeti'**
  String get repeat;

  /// No description provided for @moreOptions.
  ///
  /// In it, this message translates to:
  /// **'Altre opzioni'**
  String get moreOptions;

  /// No description provided for @back.
  ///
  /// In it, this message translates to:
  /// **'Indietro'**
  String get back;

  /// No description provided for @settingsPlayback.
  ///
  /// In it, this message translates to:
  /// **'Riproduzione'**
  String get settingsPlayback;

  /// No description provided for @normalizeVolume.
  ///
  /// In it, this message translates to:
  /// **'Normalizza volume'**
  String get normalizeVolume;

  /// No description provided for @normalizeVolumeHint.
  ///
  /// In it, this message translates to:
  /// **'Usa il ReplayGain dei file per ridurre i brani troppo forti'**
  String get normalizeVolumeHint;

  /// No description provided for @nearbyDevices.
  ///
  /// In it, this message translates to:
  /// **'Dispositivi vicini'**
  String get nearbyDevices;

  /// No description provided for @searchingDevices.
  ///
  /// In it, this message translates to:
  /// **'Ricerca di dispositivi sulla rete…'**
  String get searchingDevices;

  /// No description provided for @noDevicesHint.
  ///
  /// In it, this message translates to:
  /// **'Nessun dispositivo trovato. Apri Condivisione anche sull’altro dispositivo, sulla stessa rete.'**
  String get noDevicesHint;

  /// No description provided for @sendToDevice.
  ///
  /// In it, this message translates to:
  /// **'Invia a {name}'**
  String sendToDevice(String name);

  /// No description provided for @offerSent.
  ///
  /// In it, this message translates to:
  /// **'Richiesta inviata a {name}'**
  String offerSent(String name);

  /// No description provided for @offerChooseFirst.
  ///
  /// In it, this message translates to:
  /// **'Scegli prima i brani da inviare'**
  String get offerChooseFirst;

  /// No description provided for @sentRequests.
  ///
  /// In it, this message translates to:
  /// **'Richieste inviate'**
  String get sentRequests;

  /// No description provided for @receivedRequests.
  ///
  /// In it, this message translates to:
  /// **'Richieste ricevute'**
  String get receivedRequests;

  /// No description provided for @offerPending.
  ///
  /// In it, this message translates to:
  /// **'In attesa di risposta'**
  String get offerPending;

  /// No description provided for @offerAccepted.
  ///
  /// In it, this message translates to:
  /// **'Accettata'**
  String get offerAccepted;

  /// No description provided for @offerDeclined.
  ///
  /// In it, this message translates to:
  /// **'Rifiutata'**
  String get offerDeclined;

  /// No description provided for @offerCancelled.
  ///
  /// In it, this message translates to:
  /// **'Annullata'**
  String get offerCancelled;

  /// No description provided for @offerExpired.
  ///
  /// In it, this message translates to:
  /// **'Scaduta'**
  String get offerExpired;

  /// No description provided for @offerDone.
  ///
  /// In it, this message translates to:
  /// **'Completata'**
  String get offerDone;

  /// No description provided for @offerFailed.
  ///
  /// In it, this message translates to:
  /// **'Non riuscita'**
  String get offerFailed;

  /// No description provided for @incomingTitle.
  ///
  /// In it, this message translates to:
  /// **'{name} vuole inviarti dei brani'**
  String incomingTitle(String name);

  /// No description provided for @incomingBody.
  ///
  /// In it, this message translates to:
  /// **'{count} brani, {size} MB'**
  String incomingBody(int count, String size);

  /// No description provided for @accept.
  ///
  /// In it, this message translates to:
  /// **'Accetta'**
  String get accept;

  /// No description provided for @decline.
  ///
  /// In it, this message translates to:
  /// **'Rifiuta'**
  String get decline;

  /// No description provided for @receivingProgress.
  ///
  /// In it, this message translates to:
  /// **'Ricezione {done}/{total}'**
  String receivingProgress(int done, int total);

  /// No description provided for @manualConnection.
  ///
  /// In it, this message translates to:
  /// **'Collegamento manuale (IP e PIN)'**
  String get manualConnection;

  /// No description provided for @receiveFromLan.
  ///
  /// In it, this message translates to:
  /// **'Ricevi dalla rete locale'**
  String get receiveFromLan;

  /// No description provided for @receiveFromLanHint.
  ///
  /// In it, this message translates to:
  /// **'Rende il dispositivo visibile e riceve richieste anche in background. Su Android mostra una notifica fissa con cui puoi disattivarlo'**
  String get receiveFromLanHint;

  /// No description provided for @receiveServiceTitle.
  ///
  /// In it, this message translates to:
  /// **'Codecore è visibile sulla rete'**
  String get receiveServiceTitle;

  /// No description provided for @receiveServiceText.
  ///
  /// In it, this message translates to:
  /// **'Pronto a ricevere brani dai dispositivi vicini'**
  String get receiveServiceText;

  /// No description provided for @receiveServiceDisable.
  ///
  /// In it, this message translates to:
  /// **'Disattiva'**
  String get receiveServiceDisable;

  /// No description provided for @jamTitle.
  ///
  /// In it, this message translates to:
  /// **'Jam'**
  String get jamTitle;

  /// No description provided for @jamStart.
  ///
  /// In it, this message translates to:
  /// **'Avvia una Jam'**
  String get jamStart;

  /// No description provided for @jamStartWith.
  ///
  /// In it, this message translates to:
  /// **'Avvia Jam con {name}'**
  String jamStartWith(String name);

  /// No description provided for @jamWaiting.
  ///
  /// In it, this message translates to:
  /// **'In attesa che {name} accetti…'**
  String jamWaiting(String name);

  /// No description provided for @jamDeclined.
  ///
  /// In it, this message translates to:
  /// **'{name} ha rifiutato la Jam'**
  String jamDeclined(String name);

  /// No description provided for @jamBusy.
  ///
  /// In it, this message translates to:
  /// **'{name} ha già una Jam in corso'**
  String jamBusy(String name);

  /// No description provided for @jamUnreachable.
  ///
  /// In it, this message translates to:
  /// **'Dispositivo non raggiungibile'**
  String get jamUnreachable;

  /// No description provided for @jamIncomingTitle.
  ///
  /// In it, this message translates to:
  /// **'{name} vuole avviare una Jam'**
  String jamIncomingTitle(String name);

  /// No description provided for @jamIncomingBody.
  ///
  /// In it, this message translates to:
  /// **'Ascoltate insieme da una coda condivisa.'**
  String get jamIncomingBody;

  /// No description provided for @jamIncomingDialog.
  ///
  /// In it, this message translates to:
  /// **'{name} vuole avviare una Jam con te. La musica parte da questo dispositivo e potete aggiungere brani entrambi.'**
  String jamIncomingDialog(String name);

  /// No description provided for @jamQueue.
  ///
  /// In it, this message translates to:
  /// **'Coda condivisa'**
  String get jamQueue;

  /// No description provided for @jamEmpty.
  ///
  /// In it, this message translates to:
  /// **'La coda è vuota. Aggiungi dei brani.'**
  String get jamEmpty;

  /// No description provided for @jamAddedBy.
  ///
  /// In it, this message translates to:
  /// **'aggiunto da {name}'**
  String jamAddedBy(String name);

  /// No description provided for @jamYou.
  ///
  /// In it, this message translates to:
  /// **'te'**
  String get jamYou;

  /// No description provided for @jamAddTracks.
  ///
  /// In it, this message translates to:
  /// **'Aggiungi brani'**
  String get jamAddTracks;

  /// No description provided for @jamAddToJam.
  ///
  /// In it, this message translates to:
  /// **'Aggiungi alla Jam'**
  String get jamAddToJam;

  /// No description provided for @jamAdded.
  ///
  /// In it, this message translates to:
  /// **'Aggiunti alla Jam: {count}'**
  String jamAdded(int count);

  /// No description provided for @jamOutput.
  ///
  /// In it, this message translates to:
  /// **'Uscita audio'**
  String get jamOutput;

  /// No description provided for @jamOutputHere.
  ///
  /// In it, this message translates to:
  /// **'Questo dispositivo'**
  String get jamOutputHere;

  /// No description provided for @jamOutputOther.
  ///
  /// In it, this message translates to:
  /// **'{name}'**
  String jamOutputOther(String name);

  /// No description provided for @jamEnd.
  ///
  /// In it, this message translates to:
  /// **'Termina Jam'**
  String get jamEnd;

  /// No description provided for @jamLeave.
  ///
  /// In it, this message translates to:
  /// **'Esci dalla Jam'**
  String get jamLeave;

  /// No description provided for @jamEnded.
  ///
  /// In it, this message translates to:
  /// **'La Jam è terminata'**
  String get jamEnded;

  /// No description provided for @jamLost.
  ///
  /// In it, this message translates to:
  /// **'Connessione persa'**
  String get jamLost;

  /// No description provided for @jamGuestCannotSkip.
  ///
  /// In it, this message translates to:
  /// **'Solo chi ha avviato la Jam può cambiare brano'**
  String get jamGuestCannotSkip;

  /// No description provided for @jamRemoveForbidden.
  ///
  /// In it, this message translates to:
  /// **'Puoi rimuovere solo i tuoi brani'**
  String get jamRemoveForbidden;

  /// No description provided for @jamNowPlaying.
  ///
  /// In it, this message translates to:
  /// **'In riproduzione'**
  String get jamNowPlaying;

  /// No description provided for @jamNothingPlaying.
  ///
  /// In it, this message translates to:
  /// **'Niente in riproduzione'**
  String get jamNothingPlaying;

  /// No description provided for @jamWith.
  ///
  /// In it, this message translates to:
  /// **'Jam con {name}'**
  String jamWith(String name);

  /// No description provided for @jamUnavailable.
  ///
  /// In it, this message translates to:
  /// **'Non disponibile'**
  String get jamUnavailable;

  /// No description provided for @jamPlaying.
  ///
  /// In it, this message translates to:
  /// **'La Jam è attiva'**
  String get jamPlaying;

  /// No description provided for @jamOpen.
  ///
  /// In it, this message translates to:
  /// **'Apri la Jam'**
  String get jamOpen;

  /// No description provided for @jamSynced.
  ///
  /// In it, this message translates to:
  /// **'Sincronizzato · scarto {ms} ms'**
  String jamSynced(int ms);

  /// No description provided for @jamSyncing.
  ///
  /// In it, this message translates to:
  /// **'Sincronizzazione in corso…'**
  String get jamSyncing;

  /// No description provided for @jamLatency.
  ///
  /// In it, this message translates to:
  /// **'Latenza di questa uscita: {ms} ms'**
  String jamLatency(int ms);

  /// No description provided for @jamLatencyHint.
  ///
  /// In it, this message translates to:
  /// **'Per cuffie o casse Bluetooth: aumenta finché le uscite suonano insieme.'**
  String get jamLatencyHint;

  /// No description provided for @jamOutputsHint.
  ///
  /// In it, this message translates to:
  /// **'Più uscite suonano insieme'**
  String get jamOutputsHint;

  /// No description provided for @renamePlaylist.
  ///
  /// In it, this message translates to:
  /// **'Rinomina playlist'**
  String get renamePlaylist;

  /// No description provided for @confirmDeletePlaylistTitle.
  ///
  /// In it, this message translates to:
  /// **'Eliminare la playlist?'**
  String get confirmDeletePlaylistTitle;

  /// No description provided for @confirmDeletePlaylistBody.
  ///
  /// In it, this message translates to:
  /// **'«{name}» verrà eliminata. I brani restano nella libreria.'**
  String confirmDeletePlaylistBody(String name);

  /// No description provided for @confirmRemoveFolderTitle.
  ///
  /// In it, this message translates to:
  /// **'Rimuovere la cartella?'**
  String get confirmRemoveFolderTitle;

  /// No description provided for @confirmRemoveFolderBody.
  ///
  /// In it, this message translates to:
  /// **'I suoi brani spariscono dalla libreria. I file restano sul dispositivo.'**
  String get confirmRemoveFolderBody;

  /// No description provided for @confirmClearCoversTitle.
  ///
  /// In it, this message translates to:
  /// **'Svuotare la cache delle copertine?'**
  String get confirmClearCoversTitle;

  /// No description provided for @confirmClearCoversBody.
  ///
  /// In it, this message translates to:
  /// **'Le copertine verranno ricreate alla prossima scansione.'**
  String get confirmClearCoversBody;

  /// No description provided for @confirmRestoreTitle.
  ///
  /// In it, this message translates to:
  /// **'Ripristinare dai tag del file?'**
  String get confirmRestoreTitle;

  /// No description provided for @confirmRestoreBody.
  ///
  /// In it, this message translates to:
  /// **'Le tue modifiche a questo brano verranno sostituite con i dati del file.'**
  String get confirmRestoreBody;

  /// No description provided for @removedFromPlaylist.
  ///
  /// In it, this message translates to:
  /// **'Rimosso dalla playlist'**
  String get removedFromPlaylist;

  /// No description provided for @removedFromQueue.
  ///
  /// In it, this message translates to:
  /// **'Rimosso dalla coda'**
  String get removedFromQueue;

  /// No description provided for @playNextDone.
  ///
  /// In it, this message translates to:
  /// **'Verrà riprodotto dopo'**
  String get playNextDone;

  /// No description provided for @ytSearchPrompt.
  ///
  /// In it, this message translates to:
  /// **'Cerca un brano o incolla un link'**
  String get ytSearchPrompt;

  /// No description provided for @loadFailed.
  ///
  /// In it, this message translates to:
  /// **'Non riesco a caricare i dati.'**
  String get loadFailed;

  /// No description provided for @navHome.
  ///
  /// In it, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navSearch.
  ///
  /// In it, this message translates to:
  /// **'Cerca'**
  String get navSearch;

  /// No description provided for @devicesTitle.
  ///
  /// In it, this message translates to:
  /// **'Dispositivi'**
  String get devicesTitle;

  /// No description provided for @devicesJamActive.
  ///
  /// In it, this message translates to:
  /// **'Jam attiva'**
  String get devicesJamActive;

  /// No description provided for @jamPeople.
  ///
  /// In it, this message translates to:
  /// **'Jam · {n} persone'**
  String jamPeople(int n);

  /// No description provided for @devicesVisibleTitle.
  ///
  /// In it, this message translates to:
  /// **'Rendi visibile questo dispositivo'**
  String get devicesVisibleTitle;

  /// No description provided for @devicesVisibleHint.
  ///
  /// In it, this message translates to:
  /// **'Per ricevere brani o fare una Jam, gli altri dispositivi devono poterti vedere sulla rete.'**
  String get devicesVisibleHint;

  /// No description provided for @devicesJamShort.
  ///
  /// In it, this message translates to:
  /// **'Jam'**
  String get devicesJamShort;

  /// No description provided for @devicesSendShort.
  ///
  /// In it, this message translates to:
  /// **'Invia'**
  String get devicesSendShort;

  /// No description provided for @devicesMore.
  ///
  /// In it, this message translates to:
  /// **'Condivisione e collegamento manuale'**
  String get devicesMore;

  /// No description provided for @jamParticipantsCount.
  ///
  /// In it, this message translates to:
  /// **'{n} persone'**
  String jamParticipantsCount(int n);

  /// No description provided for @playingFrom.
  ///
  /// In it, this message translates to:
  /// **'In riproduzione da'**
  String get playingFrom;

  /// No description provided for @playContextSearch.
  ///
  /// In it, this message translates to:
  /// **'Ricerca'**
  String get playContextSearch;

  /// No description provided for @allTracks.
  ///
  /// In it, this message translates to:
  /// **'Tutti i brani'**
  String get allTracks;

  /// No description provided for @trackInfo.
  ///
  /// In it, this message translates to:
  /// **'Info sul brano'**
  String get trackInfo;

  /// No description provided for @searchCuriosity.
  ///
  /// In it, this message translates to:
  /// **'Cerca curiosità'**
  String get searchCuriosity;

  /// No description provided for @upNext.
  ///
  /// In it, this message translates to:
  /// **'Prossimi'**
  String get upNext;

  /// No description provided for @openQueue.
  ///
  /// In it, this message translates to:
  /// **'Apri coda'**
  String get openQueue;

  /// No description provided for @copyLink.
  ///
  /// In it, this message translates to:
  /// **'Copia link'**
  String get copyLink;

  /// No description provided for @moreActions.
  ///
  /// In it, this message translates to:
  /// **'Altre azioni'**
  String get moreActions;

  /// No description provided for @sleepChipEnd.
  ///
  /// In it, this message translates to:
  /// **'fine brano'**
  String get sleepChipEnd;

  /// No description provided for @yourLibrary.
  ///
  /// In it, this message translates to:
  /// **'La tua libreria'**
  String get yourLibrary;

  /// No description provided for @playlistCountLabel.
  ///
  /// In it, this message translates to:
  /// **'{n, plural, one{Playlist · 1 brano} other{Playlist · {n} brani}}'**
  String playlistCountLabel(int n);

  /// No description provided for @sortRecent.
  ///
  /// In it, this message translates to:
  /// **'Recenti'**
  String get sortRecent;

  /// No description provided for @sortAlphabetical.
  ///
  /// In it, this message translates to:
  /// **'Alfabetico'**
  String get sortAlphabetical;

  /// No description provided for @sortAddedRecently.
  ///
  /// In it, this message translates to:
  /// **'Aggiunti di recente'**
  String get sortAddedRecently;

  /// No description provided for @viewAsGrid.
  ///
  /// In it, this message translates to:
  /// **'Mostra come griglia'**
  String get viewAsGrid;

  /// No description provided for @viewAsList.
  ///
  /// In it, this message translates to:
  /// **'Mostra come elenco'**
  String get viewAsList;

  /// No description provided for @kindAlbum.
  ///
  /// In it, this message translates to:
  /// **'Album'**
  String get kindAlbum;

  /// No description provided for @kindArtist.
  ///
  /// In it, this message translates to:
  /// **'Artista'**
  String get kindArtist;

  /// No description provided for @kindPlaylist.
  ///
  /// In it, this message translates to:
  /// **'Playlist'**
  String get kindPlaylist;

  /// No description provided for @discN.
  ///
  /// In it, this message translates to:
  /// **'Disco {n}'**
  String discN(int n);

  /// No description provided for @albumMeta.
  ///
  /// In it, this message translates to:
  /// **'Album · {details}'**
  String albumMeta(String details);

  /// No description provided for @durationMinutes.
  ///
  /// In it, this message translates to:
  /// **'{n} min'**
  String durationMinutes(int n);

  /// No description provided for @tracksAndDuration.
  ///
  /// In it, this message translates to:
  /// **'{tracks}, {duration}'**
  String tracksAndDuration(String tracks, String duration);

  /// No description provided for @mostPlayed.
  ///
  /// In it, this message translates to:
  /// **'Più ascoltati'**
  String get mostPlayed;

  /// No description provided for @albumsSection.
  ///
  /// In it, this message translates to:
  /// **'Album'**
  String get albumsSection;

  /// No description provided for @artistMeta.
  ///
  /// In it, this message translates to:
  /// **'{albums} · {tracks}'**
  String artistMeta(String albums, String tracks);

  /// No description provided for @addAllToQueue.
  ///
  /// In it, this message translates to:
  /// **'Aggiungi in coda'**
  String get addAllToQueue;

  /// No description provided for @addedNToQueue.
  ///
  /// In it, this message translates to:
  /// **'{n} brani aggiunti in coda'**
  String addedNToQueue(int n);

  /// No description provided for @editOrder.
  ///
  /// In it, this message translates to:
  /// **'Modifica ordine'**
  String get editOrder;

  /// No description provided for @finishEditing.
  ///
  /// In it, this message translates to:
  /// **'Fine'**
  String get finishEditing;

  /// No description provided for @removeFromPlaylistAction.
  ///
  /// In it, this message translates to:
  /// **'Rimuovi dalla playlist'**
  String get removeFromPlaylistAction;

  /// No description provided for @noTracksInPlaylist.
  ///
  /// In it, this message translates to:
  /// **'Questa playlist è vuota'**
  String get noTracksInPlaylist;

  /// No description provided for @greetingMorning.
  ///
  /// In it, this message translates to:
  /// **'Buongiorno'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In it, this message translates to:
  /// **'Buon pomeriggio'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In it, this message translates to:
  /// **'Buonasera'**
  String get greetingEvening;

  /// No description provided for @homeResume.
  ///
  /// In it, this message translates to:
  /// **'Riprendi'**
  String get homeResume;

  /// No description provided for @homeRecentlyPlayed.
  ///
  /// In it, this message translates to:
  /// **'Ascoltati di recente'**
  String get homeRecentlyPlayed;

  /// No description provided for @homeRecentlyAdded.
  ///
  /// In it, this message translates to:
  /// **'Aggiunti di recente'**
  String get homeRecentlyAdded;

  /// No description provided for @homeTopTracks.
  ///
  /// In it, this message translates to:
  /// **'I più ascoltati'**
  String get homeTopTracks;

  /// No description provided for @homeRediscover.
  ///
  /// In it, this message translates to:
  /// **'Da riscoprire'**
  String get homeRediscover;

  /// No description provided for @searchMainResult.
  ///
  /// In it, this message translates to:
  /// **'Risultato principale'**
  String get searchMainResult;

  /// No description provided for @showAll.
  ///
  /// In it, this message translates to:
  /// **'Mostra tutti'**
  String get showAll;

  /// No description provided for @searchOnYoutube.
  ///
  /// In it, this message translates to:
  /// **'Cerca «{query}» su YouTube'**
  String searchOnYoutube(String query);

  /// No description provided for @recentSearches.
  ///
  /// In it, this message translates to:
  /// **'Ricerche recenti'**
  String get recentSearches;

  /// No description provided for @genresTitle.
  ///
  /// In it, this message translates to:
  /// **'Generi'**
  String get genresTitle;

  /// No description provided for @downloadsChip.
  ///
  /// In it, this message translates to:
  /// **'Download ({n})'**
  String downloadsChip(int n);

  /// No description provided for @gotIt.
  ///
  /// In it, this message translates to:
  /// **'Ho capito'**
  String get gotIt;

  /// No description provided for @searchEmptyLibrary.
  ///
  /// In it, this message translates to:
  /// **'Nessun risultato in libreria'**
  String get searchEmptyLibrary;

  /// No description provided for @ytInfoTooltip.
  ///
  /// In it, this message translates to:
  /// **'Informazioni sull’uso'**
  String get ytInfoTooltip;

  /// No description provided for @removeRecentSearch.
  ///
  /// In it, this message translates to:
  /// **'Rimuovi dalle ricerche recenti'**
  String get removeRecentSearch;

  /// No description provided for @groupGoTo.
  ///
  /// In it, this message translates to:
  /// **'Vai a'**
  String get groupGoTo;

  /// No description provided for @goToAlbum.
  ///
  /// In it, this message translates to:
  /// **'Vai all’album'**
  String get goToAlbum;

  /// No description provided for @goToArtist.
  ///
  /// In it, this message translates to:
  /// **'Vai all’artista'**
  String get goToArtist;

  /// No description provided for @groupQueue.
  ///
  /// In it, this message translates to:
  /// **'Coda'**
  String get groupQueue;

  /// No description provided for @groupCollection.
  ///
  /// In it, this message translates to:
  /// **'Raccolta'**
  String get groupCollection;

  /// No description provided for @groupEdit.
  ///
  /// In it, this message translates to:
  /// **'Modifica'**
  String get groupEdit;

  /// No description provided for @groupOther.
  ///
  /// In it, this message translates to:
  /// **'Altro'**
  String get groupOther;

  /// No description provided for @queueNowPlaying.
  ///
  /// In it, this message translates to:
  /// **'In riproduzione'**
  String get queueNowPlaying;

  /// No description provided for @queueNext.
  ///
  /// In it, this message translates to:
  /// **'Prossimi'**
  String get queueNext;

  /// No description provided for @queueClear.
  ///
  /// In it, this message translates to:
  /// **'Svuota'**
  String get queueClear;

  /// No description provided for @queueCleared.
  ///
  /// In it, this message translates to:
  /// **'Coda svuotata'**
  String get queueCleared;

  /// No description provided for @jamOutputsAndSync.
  ///
  /// In it, this message translates to:
  /// **'Uscite e sincronia'**
  String get jamOutputsAndSync;

  /// No description provided for @jamHostTag.
  ///
  /// In it, this message translates to:
  /// **'host'**
  String get jamHostTag;

  /// No description provided for @jamWaitingEmpty.
  ///
  /// In it, this message translates to:
  /// **'Nessuna Jam in corso'**
  String get jamWaitingEmpty;

  /// No description provided for @activityTitle.
  ///
  /// In it, this message translates to:
  /// **'Attività'**
  String get activityTitle;

  /// No description provided for @activityScan.
  ///
  /// In it, this message translates to:
  /// **'Scansione · {done}/{total}'**
  String activityScan(int done, int total);

  /// No description provided for @activityScanIdle.
  ///
  /// In it, this message translates to:
  /// **'Scansione in corso'**
  String get activityScanIdle;

  /// No description provided for @activityEnrich.
  ///
  /// In it, this message translates to:
  /// **'Arricchimento · {done}/{total}'**
  String activityEnrich(int done, int total);

  /// No description provided for @activityDownload.
  ///
  /// In it, this message translates to:
  /// **'Download · {title}'**
  String activityDownload(String title);

  /// No description provided for @activityTransfer.
  ///
  /// In it, this message translates to:
  /// **'Invio a {name} · {n} brani'**
  String activityTransfer(String name, int n);

  /// No description provided for @activityNone.
  ///
  /// In it, this message translates to:
  /// **'Nessuna attività'**
  String get activityNone;

  /// No description provided for @activityCompleted.
  ///
  /// In it, this message translates to:
  /// **'Completate'**
  String get activityCompleted;

  /// No description provided for @activityClear.
  ///
  /// In it, this message translates to:
  /// **'Pulisci'**
  String get activityClear;

  /// No description provided for @activityRunning.
  ///
  /// In it, this message translates to:
  /// **'{n} attività in corso'**
  String activityRunning(int n);

  /// No description provided for @settingsLocalNetwork.
  ///
  /// In it, this message translates to:
  /// **'Rete locale'**
  String get settingsLocalNetwork;

  /// No description provided for @removeAll.
  ///
  /// In it, this message translates to:
  /// **'Rimuovi tutti'**
  String get removeAll;

  /// No description provided for @confirmRemoveAllTitle.
  ///
  /// In it, this message translates to:
  /// **'Rimuovere tutti dalla libreria?'**
  String get confirmRemoveAllTitle;

  /// No description provided for @confirmRemoveAllBody.
  ///
  /// In it, this message translates to:
  /// **'{n} brani non trovati verranno tolti dalla libreria. I file non vengono toccati; perdi preferiti e playlist di questi brani.'**
  String confirmRemoveAllBody(int n);

  /// No description provided for @csvImportMenu.
  ///
  /// In it, this message translates to:
  /// **'Importa da Exportify (CSV)'**
  String get csvImportMenu;

  /// No description provided for @csvImportIntroTitle.
  ///
  /// In it, this message translates to:
  /// **'Importa una playlist di Spotify'**
  String get csvImportIntroTitle;

  /// No description provided for @csvImportIntroSource.
  ///
  /// In it, this message translates to:
  /// **'Il file CSV si crea gratis dal sito Exportify — exportify.net (non serve nessuna app).'**
  String get csvImportIntroSource;

  /// No description provided for @csvImportStep1.
  ///
  /// In it, this message translates to:
  /// **'Apri https://exportify.net nel browser (anche dal telefono).'**
  String get csvImportStep1;

  /// No description provided for @csvImportStep2.
  ///
  /// In it, this message translates to:
  /// **'Tocca «Get Started» e accedi con il tuo account Spotify.'**
  String get csvImportStep2;

  /// No description provided for @csvImportStep3.
  ///
  /// In it, this message translates to:
  /// **'Accanto alla playlist che vuoi tocca «Export»: si scarica un file .csv col nome della playlist.'**
  String get csvImportStep3;

  /// No description provided for @csvImportStep4.
  ///
  /// In it, this message translates to:
  /// **'Torna qui e tocca «Scegli file CSV».'**
  String get csvImportStep4;

  /// No description provided for @csvImportNote.
  ///
  /// In it, this message translates to:
  /// **'Codecore cerca i brani nella tua libreria e scarica gli altri da YouTube Music.'**
  String get csvImportNote;

  /// No description provided for @csvImportNoteOffline.
  ///
  /// In it, this message translates to:
  /// **'Verranno collegati solo i brani già presenti nella tua libreria.'**
  String get csvImportNoteOffline;

  /// No description provided for @csvImportCopy.
  ///
  /// In it, this message translates to:
  /// **'Copia indirizzo'**
  String get csvImportCopy;

  /// No description provided for @csvImportCopied.
  ///
  /// In it, this message translates to:
  /// **'Indirizzo copiato'**
  String get csvImportCopied;

  /// No description provided for @csvImportPick.
  ///
  /// In it, this message translates to:
  /// **'Scegli file CSV'**
  String get csvImportPick;

  /// No description provided for @csvImportNotExportify.
  ///
  /// In it, this message translates to:
  /// **'Questo file non sembra un CSV di Exportify. Controlla di aver esportato la playlist da exportify.net.'**
  String get csvImportNotExportify;

  /// No description provided for @csvImportReadFailed.
  ///
  /// In it, this message translates to:
  /// **'Impossibile leggere il file.'**
  String get csvImportReadFailed;

  /// No description provided for @csvImportPreviewTitle.
  ///
  /// In it, this message translates to:
  /// **'Importa playlist'**
  String get csvImportPreviewTitle;

  /// No description provided for @csvImportName.
  ///
  /// In it, this message translates to:
  /// **'Nome della playlist'**
  String get csvImportName;

  /// No description provided for @csvImportSummary.
  ///
  /// In it, this message translates to:
  /// **'{total} brani · {known} già in libreria · {todo} da scaricare'**
  String csvImportSummary(int total, int known, int todo);

  /// No description provided for @csvImportSkipped.
  ///
  /// In it, this message translates to:
  /// **'{n} righe ignorate (podcast o file locali)'**
  String csvImportSkipped(int n);

  /// No description provided for @csvImportEstimate.
  ///
  /// In it, this message translates to:
  /// **'Tempo stimato: circa {minutes} min'**
  String csvImportEstimate(int minutes);

  /// No description provided for @csvImportExists.
  ///
  /// In it, this message translates to:
  /// **'Esiste già una playlist con questo nome'**
  String get csvImportExists;

  /// No description provided for @csvImportUpdate.
  ///
  /// In it, this message translates to:
  /// **'Aggiorna quella esistente (aggiunge solo i brani nuovi)'**
  String get csvImportUpdate;

  /// No description provided for @csvImportNew.
  ///
  /// In it, this message translates to:
  /// **'Crea una nuova playlist'**
  String get csvImportNew;

  /// No description provided for @csvImportGo.
  ///
  /// In it, this message translates to:
  /// **'Importa'**
  String get csvImportGo;

  /// No description provided for @csvImportStarted.
  ///
  /// In it, this message translates to:
  /// **'Importazione avviata: la segui nel Centro Attività'**
  String get csvImportStarted;

  /// No description provided for @activityImport.
  ///
  /// In it, this message translates to:
  /// **'Importazione «{name}» · {done}/{total}'**
  String activityImport(String name, int done, int total);

  /// No description provided for @activityImportPaused.
  ///
  /// In it, this message translates to:
  /// **'Importazione «{name}» · in pausa · {done}/{total}'**
  String activityImportPaused(String name, int done, int total);

  /// No description provided for @csvImportBanner.
  ///
  /// In it, this message translates to:
  /// **'Importazione: {done}/{total} · {review} da verificare · {missing} non trovati'**
  String csvImportBanner(int done, int total, int review, int missing);

  /// No description provided for @csvImportBannerPaused.
  ///
  /// In it, this message translates to:
  /// **'Importazione in pausa: {done}/{total} · {review} da verificare · {missing} non trovati'**
  String csvImportBannerPaused(int done, int total, int review, int missing);

  /// No description provided for @csvImportReview.
  ///
  /// In it, this message translates to:
  /// **'Rivedi'**
  String get csvImportReview;

  /// No description provided for @csvImportResume.
  ///
  /// In it, this message translates to:
  /// **'Riprendi'**
  String get csvImportResume;

  /// No description provided for @csvImportPause.
  ///
  /// In it, this message translates to:
  /// **'Pausa'**
  String get csvImportPause;

  /// No description provided for @csvImportCancelTitle.
  ///
  /// In it, this message translates to:
  /// **'Annullare l\'importazione?'**
  String get csvImportCancelTitle;

  /// No description provided for @csvImportCancelBody.
  ///
  /// In it, this message translates to:
  /// **'I brani già scaricati restano nella playlist.'**
  String get csvImportCancelBody;

  /// No description provided for @csvImportDone.
  ///
  /// In it, this message translates to:
  /// **'Importazione completata: {added} aggiunti, {review} da verificare, {missing} non trovati'**
  String csvImportDone(int added, int review, int missing);

  /// No description provided for @csvImportFailing.
  ///
  /// In it, this message translates to:
  /// **'Troppi errori di fila: importazione in pausa'**
  String get csvImportFailing;

  /// No description provided for @csvImportReviewTitle.
  ///
  /// In it, this message translates to:
  /// **'Rivedi'**
  String get csvImportReviewTitle;

  /// No description provided for @csvImportToReview.
  ///
  /// In it, this message translates to:
  /// **'Da verificare'**
  String get csvImportToReview;

  /// No description provided for @csvImportNotFound.
  ///
  /// In it, this message translates to:
  /// **'Non trovati'**
  String get csvImportNotFound;

  /// No description provided for @csvImportErrors.
  ///
  /// In it, this message translates to:
  /// **'Con errori'**
  String get csvImportErrors;

  /// No description provided for @csvImportRetryAll.
  ///
  /// In it, this message translates to:
  /// **'Riprova tutti'**
  String get csvImportRetryAll;

  /// No description provided for @csvImportSkip.
  ///
  /// In it, this message translates to:
  /// **'Salta'**
  String get csvImportSkip;

  /// No description provided for @csvImportManual.
  ///
  /// In it, this message translates to:
  /// **'Cerca a mano'**
  String get csvImportManual;

  /// No description provided for @csvImportNothing.
  ///
  /// In it, this message translates to:
  /// **'Niente da rivedere.'**
  String get csvImportNothing;

  /// No description provided for @csvImportSearch.
  ///
  /// In it, this message translates to:
  /// **'Cerca'**
  String get csvImportSearch;

  /// No description provided for @csvImportWanted.
  ///
  /// In it, this message translates to:
  /// **'Cercato: {title} · {artist} · {duration}'**
  String csvImportWanted(String title, String artist, String duration);

  /// No description provided for @csvImportDownload.
  ///
  /// In it, this message translates to:
  /// **'Scarica'**
  String get csvImportDownload;

  /// No description provided for @csvImportCancelGo.
  ///
  /// In it, this message translates to:
  /// **'Annulla importazione'**
  String get csvImportCancelGo;

  /// No description provided for @exportLog.
  ///
  /// In it, this message translates to:
  /// **'Esporta log'**
  String get exportLog;

  /// No description provided for @exportLogHint.
  ///
  /// In it, this message translates to:
  /// **'File di testo senza percorsi personali, indirizzi di rete né PIN'**
  String get exportLogHint;

  /// No description provided for @exportLogDebugOnly.
  ///
  /// In it, this message translates to:
  /// **'Disponibile solo nella versione installata (in debug il log non viene scritto su file)'**
  String get exportLogDebugOnly;

  /// No description provided for @exportLogNone.
  ///
  /// In it, this message translates to:
  /// **'Non c\'è ancora nessun log da esportare'**
  String get exportLogNone;

  /// No description provided for @exportLogSaved.
  ///
  /// In it, this message translates to:
  /// **'Log salvato'**
  String get exportLogSaved;

  /// No description provided for @exportLogFailed.
  ///
  /// In it, this message translates to:
  /// **'Impossibile salvare il log'**
  String get exportLogFailed;

  /// No description provided for @exportPlaylist.
  ///
  /// In it, this message translates to:
  /// **'Esporta…'**
  String get exportPlaylist;

  /// No description provided for @exportPlaylistTitle.
  ///
  /// In it, this message translates to:
  /// **'Esporta playlist'**
  String get exportPlaylistTitle;

  /// No description provided for @exportFormatM3u8.
  ///
  /// In it, this message translates to:
  /// **'M3U8 · per altri lettori'**
  String get exportFormatM3u8;

  /// No description provided for @exportFormatCsv.
  ///
  /// In it, this message translates to:
  /// **'CSV · come Exportify'**
  String get exportFormatCsv;

  /// No description provided for @exportFormatJson.
  ///
  /// In it, this message translates to:
  /// **'JSON · formato Codecore'**
  String get exportFormatJson;

  /// No description provided for @exportRelativePaths.
  ///
  /// In it, this message translates to:
  /// **'Percorsi relativi'**
  String get exportRelativePaths;

  /// No description provided for @exportRelativeHint.
  ///
  /// In it, this message translates to:
  /// **'Rispetto alla cartella comune dei brani: salva il file lì'**
  String get exportRelativeHint;

  /// No description provided for @exportAction.
  ///
  /// In it, this message translates to:
  /// **'Esporta'**
  String get exportAction;

  /// No description provided for @exportSaved.
  ///
  /// In it, this message translates to:
  /// **'Playlist esportata'**
  String get exportSaved;

  /// No description provided for @exportEmpty.
  ///
  /// In it, this message translates to:
  /// **'La playlist è vuota'**
  String get exportEmpty;

  /// No description provided for @exportFailed.
  ///
  /// In it, this message translates to:
  /// **'Impossibile esportare la playlist'**
  String get exportFailed;

  /// No description provided for @ytErrToolOutdated.
  ///
  /// In it, this message translates to:
  /// **'yt-dlp è troppo vecchio: aggiornalo (Impostazioni → Download → Aggiorna) e riprova'**
  String get ytErrToolOutdated;

  /// No description provided for @ytDlpOutdatedBanner.
  ///
  /// In it, this message translates to:
  /// **'yt-dlp {version} è troppo vecchio: i download potrebbero non funzionare'**
  String ytDlpOutdatedBanner(String version);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'es', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
