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
  /// **'Aggiungi alla coda'**
  String get addToQueue;

  /// No description provided for @addedToQueue.
  ///
  /// In it, this message translates to:
  /// **'Aggiunto alla coda'**
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

  /// No description provided for @themeOled.
  ///
  /// In it, this message translates to:
  /// **'OLED'**
  String get themeOled;

  /// No description provided for @themeCarbon.
  ///
  /// In it, this message translates to:
  /// **'Carbone'**
  String get themeCarbon;

  /// No description provided for @themeNavy.
  ///
  /// In it, this message translates to:
  /// **'Blu notte'**
  String get themeNavy;

  /// No description provided for @themeLight.
  ///
  /// In it, this message translates to:
  /// **'Chiaro'**
  String get themeLight;

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
