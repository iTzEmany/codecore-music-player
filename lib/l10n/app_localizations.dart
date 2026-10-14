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
