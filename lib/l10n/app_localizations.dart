import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_pt.dart';

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
    Locale('fr'),
    Locale('it'),
    Locale('pt'),
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
  /// **'Solo per uso personale. Rispetta i diritti d’autore e i termini di YouTube e SoundCloud.'**
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
  /// **'Importa una playlist'**
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
  /// **'Scegli file'**
  String get csvImportPick;

  /// No description provided for @csvImportNotExportify.
  ///
  /// In it, this message translates to:
  /// **'Formato non riconosciuto. Scegli un CSV (Exportify, TuneMyMusic, Soundiiz, Last.fm) o una playlist M3U/M3U8/XSPF.'**
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

  /// No description provided for @settingsDownloads.
  ///
  /// In it, this message translates to:
  /// **'Download'**
  String get settingsDownloads;

  /// No description provided for @ytDlpVersion.
  ///
  /// In it, this message translates to:
  /// **'yt-dlp {version}'**
  String ytDlpVersion(String version);

  /// No description provided for @ytDlpUnknownVersion.
  ///
  /// In it, this message translates to:
  /// **'yt-dlp non trovato'**
  String get ytDlpUnknownVersion;

  /// No description provided for @ytDlpUpdate.
  ///
  /// In it, this message translates to:
  /// **'Aggiorna'**
  String get ytDlpUpdate;

  /// No description provided for @ytDlpUpdating.
  ///
  /// In it, this message translates to:
  /// **'Aggiornamento… {percent}%'**
  String ytDlpUpdating(int percent);

  /// No description provided for @ytDlpUpdated.
  ///
  /// In it, this message translates to:
  /// **'Aggiornato alla versione {version}'**
  String ytDlpUpdated(String version);

  /// No description provided for @ytDlpTooOld.
  ///
  /// In it, this message translates to:
  /// **'Troppo vecchio: tocca Aggiorna'**
  String get ytDlpTooOld;

  /// No description provided for @ytDlpUpdateErrNetwork.
  ///
  /// In it, this message translates to:
  /// **'Aggiornamento non riuscito: rete non raggiungibile'**
  String get ytDlpUpdateErrNetwork;

  /// No description provided for @ytDlpUpdateErrHash.
  ///
  /// In it, this message translates to:
  /// **'Aggiornamento annullato: il file scaricato non ha superato il controllo di integrità'**
  String get ytDlpUpdateErrHash;

  /// No description provided for @ytDlpUpdateErrOther.
  ///
  /// In it, this message translates to:
  /// **'Aggiornamento non riuscito (dettagli nel log)'**
  String get ytDlpUpdateErrOther;

  /// No description provided for @downloadParallel.
  ///
  /// In it, this message translates to:
  /// **'Download contemporanei'**
  String get downloadParallel;

  /// No description provided for @downloadParallelHint.
  ///
  /// In it, this message translates to:
  /// **'Più insieme è più veloce, ma YouTube può chiedere di rallentare'**
  String get downloadParallelHint;

  /// No description provided for @downloadRateLimit.
  ///
  /// In it, this message translates to:
  /// **'Limite di velocità'**
  String get downloadRateLimit;

  /// No description provided for @downloadRateNone.
  ///
  /// In it, this message translates to:
  /// **'Nessuno'**
  String get downloadRateNone;

  /// No description provided for @downloadRateKb.
  ///
  /// In it, this message translates to:
  /// **'{kb} KB/s'**
  String downloadRateKb(int kb);

  /// No description provided for @downloadRateMb.
  ///
  /// In it, this message translates to:
  /// **'{mb} MB/s'**
  String downloadRateMb(int mb);

  /// No description provided for @activityDownloadRetry.
  ///
  /// In it, this message translates to:
  /// **'Download · {title} · nuovo tentativo tra {seconds} s ({attempt}/{max})'**
  String activityDownloadRetry(String title, int seconds, int attempt, int max);

  /// No description provided for @downloadOriginal.
  ///
  /// In it, this message translates to:
  /// **'Qualità originale (senza ricodifica)'**
  String get downloadOriginal;

  /// No description provided for @downloadOriginalHint.
  ///
  /// In it, this message translates to:
  /// **'Tiene l\'audio di YouTube com\'è (M4A/Opus): nessuna perdita, file più piccoli. Spento: MP3 256 kbps'**
  String get downloadOriginalHint;

  /// No description provided for @searchCacheClear.
  ///
  /// In it, this message translates to:
  /// **'Svuota cache ricerche'**
  String get searchCacheClear;

  /// No description provided for @searchCacheCount.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, =0{Vuota} one{1 ricerca salvata} other{{count} ricerche salvate}}'**
  String searchCacheCount(int count);

  /// No description provided for @searchCacheCleared.
  ///
  /// In it, this message translates to:
  /// **'Cache svuotata'**
  String get searchCacheCleared;

  /// No description provided for @csvImportLengthOff.
  ///
  /// In it, this message translates to:
  /// **'Durata diversa: {found} invece di {wanted}'**
  String csvImportLengthOff(String found, String wanted);

  /// No description provided for @csvImportKeep.
  ///
  /// In it, this message translates to:
  /// **'Tieni questo'**
  String get csvImportKeep;

  /// No description provided for @csvImportTooBig.
  ///
  /// In it, this message translates to:
  /// **'Il file è troppo grande per essere una playlist (massimo 5 MB e 10.000 brani)'**
  String get csvImportTooBig;

  /// No description provided for @csvImportAlsoAccepts.
  ///
  /// In it, this message translates to:
  /// **'Accetta anche: TuneMyMusic, Soundiiz, Last.fm (CSV), M3U/M3U8, XSPF.'**
  String get csvImportAlsoAccepts;

  /// No description provided for @csvImportPlanned.
  ///
  /// In it, this message translates to:
  /// **'Abbinamenti pronti: controllali e scarica'**
  String get csvImportPlanned;

  /// No description provided for @csvImportLinkOnly.
  ///
  /// In it, this message translates to:
  /// **'Solo collega (nessun download)'**
  String get csvImportLinkOnly;

  /// No description provided for @csvImportLinkOnlyHint.
  ///
  /// In it, this message translates to:
  /// **'Crea la playlist con quello che hai già e basta'**
  String get csvImportLinkOnlyHint;

  /// No description provided for @csvImportPlanFirst.
  ///
  /// In it, this message translates to:
  /// **'Rivedi prima di scaricare'**
  String get csvImportPlanFirst;

  /// No description provided for @csvImportPlanFirstHint.
  ///
  /// In it, this message translates to:
  /// **'Cerca tutto, poi scegli cosa scaricare'**
  String get csvImportPlanFirstHint;

  /// No description provided for @csvImportPlanTitle.
  ///
  /// In it, this message translates to:
  /// **'Abbinamenti'**
  String get csvImportPlanTitle;

  /// No description provided for @csvImportPlanGo.
  ///
  /// In it, this message translates to:
  /// **'{n, plural, one{Scarica 1 brano} other{Scarica {n} brani}}'**
  String csvImportPlanGo(int n);

  /// No description provided for @csvImportPlanKnown.
  ///
  /// In it, this message translates to:
  /// **'già scaricato'**
  String get csvImportPlanKnown;

  /// No description provided for @csvImportPlanEmpty.
  ///
  /// In it, this message translates to:
  /// **'Niente da scaricare'**
  String get csvImportPlanEmpty;

  /// No description provided for @csvImportBannerPlanned.
  ///
  /// In it, this message translates to:
  /// **'Abbinamenti pronti: {n, plural, one{1 brano da scaricare} other{{n} brani da scaricare}}'**
  String csvImportBannerPlanned(int n);

  /// No description provided for @settingsAdvanced.
  ///
  /// In it, this message translates to:
  /// **'Avanzate'**
  String get settingsAdvanced;

  /// No description provided for @importSureThreshold.
  ///
  /// In it, this message translates to:
  /// **'Abbinamento sicuro da'**
  String get importSureThreshold;

  /// No description provided for @importSureThresholdHint.
  ///
  /// In it, this message translates to:
  /// **'Sopra questo punteggio un brano dell\'importazione si scarica senza chiedere'**
  String get importSureThresholdHint;

  /// No description provided for @importReviewThreshold.
  ///
  /// In it, this message translates to:
  /// **'Da verificare da'**
  String get importReviewThreshold;

  /// No description provided for @importReviewThresholdHint.
  ///
  /// In it, this message translates to:
  /// **'Tra questo punteggio e quello sicuro il brano finisce in «Da verificare»; sotto, in «Non trovati»'**
  String get importReviewThresholdHint;

  /// No description provided for @importThresholdsReset.
  ///
  /// In it, this message translates to:
  /// **'Ripristina i valori predefiniti'**
  String get importThresholdsReset;

  /// No description provided for @csvImportEstimateHours.
  ///
  /// In it, this message translates to:
  /// **'Tempo stimato: circa {hours} h {minutes} min'**
  String csvImportEstimateHours(int hours, int minutes);

  /// No description provided for @csvImportBlocks.
  ///
  /// In it, this message translates to:
  /// **'Importa a blocchi da {size}'**
  String csvImportBlocks(int size);

  /// No description provided for @csvImportBigWarning.
  ///
  /// In it, this message translates to:
  /// **'Sono {n} brani da scaricare: ci vorranno ore. A blocchi, uno dopo l\'altro, l\'ordine della playlist resta giusto e puoi fermarti tra un blocco e l\'altro.'**
  String csvImportBigWarning(int n);

  /// No description provided for @etaLessThanMinute.
  ///
  /// In it, this message translates to:
  /// **'meno di 1 min'**
  String get etaLessThanMinute;

  /// No description provided for @etaMinutes.
  ///
  /// In it, this message translates to:
  /// **'circa {minutes} min'**
  String etaMinutes(int minutes);

  /// No description provided for @etaHours.
  ///
  /// In it, this message translates to:
  /// **'circa {hours} h {minutes} min'**
  String etaHours(int hours, int minutes);

  /// No description provided for @csvImportOwnFolder.
  ///
  /// In it, this message translates to:
  /// **'Cartella per questa playlist'**
  String get csvImportOwnFolder;

  /// No description provided for @csvImportOwnFolderHint.
  ///
  /// In it, this message translates to:
  /// **'Salva i brani scaricati in una sottocartella col nome della playlist'**
  String get csvImportOwnFolderHint;

  /// No description provided for @csvImportNumberFiles.
  ///
  /// In it, this message translates to:
  /// **'Numera i file'**
  String get csvImportNumberFiles;

  /// No description provided for @csvImportNumberFilesHint.
  ///
  /// In it, this message translates to:
  /// **'07 - Artista - Titolo: la cartella si ascolta nell\'ordine giusto anche fuori da Codecore'**
  String get csvImportNumberFilesHint;

  /// No description provided for @csvImportFetchCovers.
  ///
  /// In it, this message translates to:
  /// **'Cerca le copertine'**
  String get csvImportFetchCovers;

  /// No description provided for @csvImportFetchCoversHint.
  ///
  /// In it, this message translates to:
  /// **'Dopo ogni download cerca la copertina dell\'album su iTunes (album e artista del file)'**
  String get csvImportFetchCoversHint;

  /// No description provided for @csvImportExport.
  ///
  /// In it, this message translates to:
  /// **'Esporta esito'**
  String get csvImportExport;

  /// No description provided for @csvImportExported.
  ///
  /// In it, this message translates to:
  /// **'Esito salvato'**
  String get csvImportExported;

  /// No description provided for @csvOutHeaderRow.
  ///
  /// In it, this message translates to:
  /// **'Riga'**
  String get csvOutHeaderRow;

  /// No description provided for @csvOutHeaderTitle.
  ///
  /// In it, this message translates to:
  /// **'Titolo'**
  String get csvOutHeaderTitle;

  /// No description provided for @csvOutHeaderArtists.
  ///
  /// In it, this message translates to:
  /// **'Artisti'**
  String get csvOutHeaderArtists;

  /// No description provided for @csvOutHeaderAlbum.
  ///
  /// In it, this message translates to:
  /// **'Album'**
  String get csvOutHeaderAlbum;

  /// No description provided for @csvOutHeaderDuration.
  ///
  /// In it, this message translates to:
  /// **'Durata (ms)'**
  String get csvOutHeaderDuration;

  /// No description provided for @csvOutHeaderIsrc.
  ///
  /// In it, this message translates to:
  /// **'ISRC'**
  String get csvOutHeaderIsrc;

  /// No description provided for @csvOutHeaderStatus.
  ///
  /// In it, this message translates to:
  /// **'Esito'**
  String get csvOutHeaderStatus;

  /// No description provided for @csvOutHeaderNote.
  ///
  /// In it, this message translates to:
  /// **'Motivo'**
  String get csvOutHeaderNote;

  /// No description provided for @csvOutHeaderVideo.
  ///
  /// In it, this message translates to:
  /// **'Video scelto'**
  String get csvOutHeaderVideo;

  /// No description provided for @csvOutHeaderScore.
  ///
  /// In it, this message translates to:
  /// **'Punteggio'**
  String get csvOutHeaderScore;

  /// No description provided for @importStatusPending.
  ///
  /// In it, this message translates to:
  /// **'Da cercare'**
  String get importStatusPending;

  /// No description provided for @importStatusQueued.
  ///
  /// In it, this message translates to:
  /// **'In coda'**
  String get importStatusQueued;

  /// No description provided for @importStatusDownloaded.
  ///
  /// In it, this message translates to:
  /// **'Scaricato'**
  String get importStatusDownloaded;

  /// No description provided for @importStatusLinked.
  ///
  /// In it, this message translates to:
  /// **'Già in libreria'**
  String get importStatusLinked;

  /// No description provided for @importStatusReview.
  ///
  /// In it, this message translates to:
  /// **'Da verificare'**
  String get importStatusReview;

  /// No description provided for @importStatusNotFound.
  ///
  /// In it, this message translates to:
  /// **'Non trovato'**
  String get importStatusNotFound;

  /// No description provided for @importStatusFailed.
  ///
  /// In it, this message translates to:
  /// **'Errore'**
  String get importStatusFailed;

  /// No description provided for @importStatusSkipped.
  ///
  /// In it, this message translates to:
  /// **'Saltato'**
  String get importStatusSkipped;

  /// No description provided for @importStatusPlanned.
  ///
  /// In it, this message translates to:
  /// **'Pianificato'**
  String get importStatusPlanned;

  /// No description provided for @importStatusRemoved.
  ///
  /// In it, this message translates to:
  /// **'Rimosso dalla sorgente'**
  String get importStatusRemoved;

  /// No description provided for @importNoteNoResults.
  ///
  /// In it, this message translates to:
  /// **'Nessun risultato'**
  String get importNoteNoResults;

  /// No description provided for @importNoteLowScore.
  ///
  /// In it, this message translates to:
  /// **'Abbinamento poco sicuro'**
  String get importNoteLowScore;

  /// No description provided for @importNoteLinkOnly.
  ///
  /// In it, this message translates to:
  /// **'Solo collegamento: non cercato'**
  String get importNoteLinkOnly;

  /// No description provided for @importNoteYoutubeOff.
  ///
  /// In it, this message translates to:
  /// **'Download disattivato'**
  String get importNoteYoutubeOff;

  /// No description provided for @importNoteDownloadFailed.
  ///
  /// In it, this message translates to:
  /// **'Download non riuscito'**
  String get importNoteDownloadFailed;

  /// No description provided for @importNoteLengthOff.
  ///
  /// In it, this message translates to:
  /// **'Durata diversa dal file'**
  String get importNoteLengthOff;

  /// No description provided for @importNoteUnchanged.
  ///
  /// In it, this message translates to:
  /// **'Già nella playlist'**
  String get importNoteUnchanged;

  /// No description provided for @csvImportSync.
  ///
  /// In it, this message translates to:
  /// **'Sincronizza'**
  String get csvImportSync;

  /// No description provided for @csvImportSyncCounts.
  ///
  /// In it, this message translates to:
  /// **'+{added} nuovi · −{removed} rimossi dalla playlist (i file restano)'**
  String csvImportSyncCounts(int added, int removed);

  /// No description provided for @csvImportSyncChecking.
  ///
  /// In it, this message translates to:
  /// **'Controllo le differenze…'**
  String get csvImportSyncChecking;

  /// No description provided for @playbackSpeed.
  ///
  /// In it, this message translates to:
  /// **'Velocità di riproduzione'**
  String get playbackSpeed;

  /// No description provided for @playbackSpeedHint.
  ///
  /// In it, this message translates to:
  /// **'Il tono resta quello originale. Il timer di spegnimento conta il tempo reale, non quello del brano.'**
  String get playbackSpeedHint;

  /// No description provided for @resumeFrom.
  ///
  /// In it, this message translates to:
  /// **'riprendi da {time}'**
  String resumeFrom(String time);

  /// No description provided for @restartFromBeginning.
  ///
  /// In it, this message translates to:
  /// **'Ricomincia dall’inizio'**
  String get restartFromBeginning;

  /// No description provided for @previewTrack.
  ///
  /// In it, this message translates to:
  /// **'Anteprima 20 s'**
  String get previewTrack;

  /// No description provided for @equalizer.
  ///
  /// In it, this message translates to:
  /// **'Equalizzatore'**
  String get equalizer;

  /// No description provided for @eqOutputSpeaker.
  ///
  /// In it, this message translates to:
  /// **'Altoparlante'**
  String get eqOutputSpeaker;

  /// No description provided for @eqOutputHeadphones.
  ///
  /// In it, this message translates to:
  /// **'Cuffie'**
  String get eqOutputHeadphones;

  /// No description provided for @eqHint.
  ///
  /// In it, this message translates to:
  /// **'Ogni uscita ricorda la sua curva: cambia da sola quando colleghi le cuffie.'**
  String get eqHint;

  /// No description provided for @eqPresetFlat.
  ///
  /// In it, this message translates to:
  /// **'Piatto'**
  String get eqPresetFlat;

  /// No description provided for @eqPresetBass.
  ///
  /// In it, this message translates to:
  /// **'Bassi'**
  String get eqPresetBass;

  /// No description provided for @eqPresetVoice.
  ///
  /// In it, this message translates to:
  /// **'Voce'**
  String get eqPresetVoice;

  /// No description provided for @eqPresetTreble.
  ///
  /// In it, this message translates to:
  /// **'Acuti'**
  String get eqPresetTreble;

  /// No description provided for @eqPresetCustom.
  ///
  /// In it, this message translates to:
  /// **'Personalizzato'**
  String get eqPresetCustom;

  /// No description provided for @eqReset.
  ///
  /// In it, this message translates to:
  /// **'Reimposta'**
  String get eqReset;

  /// No description provided for @eqWaiting.
  ///
  /// In it, this message translates to:
  /// **'Le bande compaiono quando parte il primo brano.'**
  String get eqWaiting;

  /// No description provided for @eqUnavailable.
  ///
  /// In it, this message translates to:
  /// **'L\'equalizzatore non è disponibile su questo dispositivo.'**
  String get eqUnavailable;

  /// No description provided for @transitionMode.
  ///
  /// In it, this message translates to:
  /// **'Passaggio tra i brani'**
  String get transitionMode;

  /// No description provided for @transitionNormal.
  ///
  /// In it, this message translates to:
  /// **'Normale'**
  String get transitionNormal;

  /// No description provided for @transitionGapless.
  ///
  /// In it, this message translates to:
  /// **'Senza pause'**
  String get transitionGapless;

  /// No description provided for @transitionCrossfade.
  ///
  /// In it, this message translates to:
  /// **'Dissolvenza'**
  String get transitionCrossfade;

  /// No description provided for @transitionHint.
  ///
  /// In it, this message translates to:
  /// **'Senza pause funziona meglio con brani dello stesso formato (per esempio tutti FLAC).'**
  String get transitionHint;

  /// No description provided for @crossfadeLength.
  ///
  /// In it, this message translates to:
  /// **'Durata della dissolvenza: {seconds} s'**
  String crossfadeLength(int seconds);

  /// No description provided for @crossfadePlainInAlbum.
  ///
  /// In it, this message translates to:
  /// **'Non sfumare nello stesso album'**
  String get crossfadePlainInAlbum;

  /// No description provided for @crossfadePlainInAlbumHint.
  ///
  /// In it, this message translates to:
  /// **'Dentro un album i brani si susseguono senza pause, senza sovrapporsi.'**
  String get crossfadePlainInAlbumHint;

  /// No description provided for @selectedRow.
  ///
  /// In it, this message translates to:
  /// **'Selezionato'**
  String get selectedRow;

  /// No description provided for @selectedRowAt.
  ///
  /// In it, this message translates to:
  /// **'Selezionato, numero {position}'**
  String selectedRowAt(int position);

  /// No description provided for @curiositySong.
  ///
  /// In it, this message translates to:
  /// **'Sul brano'**
  String get curiositySong;

  /// No description provided for @curiosityArtist.
  ///
  /// In it, this message translates to:
  /// **'Sull\'artista'**
  String get curiosityArtist;

  /// No description provided for @showMore.
  ///
  /// In it, this message translates to:
  /// **'Mostra tutto'**
  String get showMore;

  /// No description provided for @showLess.
  ///
  /// In it, this message translates to:
  /// **'Mostra meno'**
  String get showLess;

  /// No description provided for @curiosityNoSong.
  ///
  /// In it, this message translates to:
  /// **'Nessuna pagina dedicata a questo brano'**
  String get curiosityNoSong;

  /// No description provided for @curiosityNoArtist.
  ///
  /// In it, this message translates to:
  /// **'Nessuna pagina sull\'artista'**
  String get curiosityNoArtist;

  /// No description provided for @themeNew.
  ///
  /// In it, this message translates to:
  /// **'Nuovo tema'**
  String get themeNew;

  /// No description provided for @themeEdit.
  ///
  /// In it, this message translates to:
  /// **'Modifica'**
  String get themeEdit;

  /// No description provided for @themeDuplicate.
  ///
  /// In it, this message translates to:
  /// **'Duplica'**
  String get themeDuplicate;

  /// No description provided for @themeDelete.
  ///
  /// In it, this message translates to:
  /// **'Elimina'**
  String get themeDelete;

  /// No description provided for @themeExport.
  ///
  /// In it, this message translates to:
  /// **'Esporta'**
  String get themeExport;

  /// No description provided for @themeImport.
  ///
  /// In it, this message translates to:
  /// **'Importa tema'**
  String get themeImport;

  /// No description provided for @themeName.
  ///
  /// In it, this message translates to:
  /// **'Nome del tema'**
  String get themeName;

  /// No description provided for @themeBase.
  ///
  /// In it, this message translates to:
  /// **'Parti da'**
  String get themeBase;

  /// No description provided for @themeModeSimple.
  ///
  /// In it, this message translates to:
  /// **'Semplice'**
  String get themeModeSimple;

  /// No description provided for @themeModeAdvanced.
  ///
  /// In it, this message translates to:
  /// **'Avanzata'**
  String get themeModeAdvanced;

  /// No description provided for @themeSave.
  ///
  /// In it, this message translates to:
  /// **'Salva'**
  String get themeSave;

  /// No description provided for @themeEditorTitle.
  ///
  /// In it, this message translates to:
  /// **'Tema personalizzato'**
  String get themeEditorTitle;

  /// No description provided for @themeDiscardTitle.
  ///
  /// In it, this message translates to:
  /// **'Scartare le modifiche?'**
  String get themeDiscardTitle;

  /// No description provided for @themeDiscardBody.
  ///
  /// In it, this message translates to:
  /// **'Le modifiche a questo tema non sono state salvate.'**
  String get themeDiscardBody;

  /// No description provided for @themeDiscard.
  ///
  /// In it, this message translates to:
  /// **'Scarta'**
  String get themeDiscard;

  /// No description provided for @themePreview.
  ///
  /// In it, this message translates to:
  /// **'Anteprima'**
  String get themePreview;

  /// No description provided for @themeResetColor.
  ///
  /// In it, this message translates to:
  /// **'Ripristina il colore'**
  String get themeResetColor;

  /// No description provided for @themeContrastTitle.
  ///
  /// In it, this message translates to:
  /// **'Leggibilità'**
  String get themeContrastTitle;

  /// No description provided for @themeContrastLow.
  ///
  /// In it, this message translates to:
  /// **'Poco leggibile'**
  String get themeContrastLow;

  /// No description provided for @themeContrastOk.
  ///
  /// In it, this message translates to:
  /// **'Leggibile'**
  String get themeContrastOk;

  /// No description provided for @themeFix.
  ///
  /// In it, this message translates to:
  /// **'Correggi'**
  String get themeFix;

  /// No description provided for @themeSaved.
  ///
  /// In it, this message translates to:
  /// **'Tema salvato'**
  String get themeSaved;

  /// No description provided for @themeLimit.
  ///
  /// In it, this message translates to:
  /// **'Hai già 20 temi: eliminane uno'**
  String get themeLimit;

  /// No description provided for @themeImported.
  ///
  /// In it, this message translates to:
  /// **'Tema importato'**
  String get themeImported;

  /// No description provided for @themeImportFailed.
  ///
  /// In it, this message translates to:
  /// **'Il file non è un tema valido'**
  String get themeImportFailed;

  /// No description provided for @themeDeleted.
  ///
  /// In it, this message translates to:
  /// **'Tema eliminato'**
  String get themeDeleted;

  /// No description provided for @themeMine.
  ///
  /// In it, this message translates to:
  /// **'I miei temi'**
  String get themeMine;

  /// No description provided for @tokenBg.
  ///
  /// In it, this message translates to:
  /// **'Sfondo'**
  String get tokenBg;

  /// No description provided for @tokenSurface1.
  ///
  /// In it, this message translates to:
  /// **'Superficie 1'**
  String get tokenSurface1;

  /// No description provided for @tokenSurface2.
  ///
  /// In it, this message translates to:
  /// **'Superficie 2'**
  String get tokenSurface2;

  /// No description provided for @tokenSurface3.
  ///
  /// In it, this message translates to:
  /// **'Superficie 3'**
  String get tokenSurface3;

  /// No description provided for @tokenAccent.
  ///
  /// In it, this message translates to:
  /// **'Accento'**
  String get tokenAccent;

  /// No description provided for @tokenAccentSoft.
  ///
  /// In it, this message translates to:
  /// **'Accento chiaro'**
  String get tokenAccentSoft;

  /// No description provided for @tokenOnAccent.
  ///
  /// In it, this message translates to:
  /// **'Testo sull\'accento'**
  String get tokenOnAccent;

  /// No description provided for @tokenText.
  ///
  /// In it, this message translates to:
  /// **'Testo'**
  String get tokenText;

  /// No description provided for @tokenTextMuted.
  ///
  /// In it, this message translates to:
  /// **'Testo secondario'**
  String get tokenTextMuted;

  /// No description provided for @tokenTextFaint.
  ///
  /// In it, this message translates to:
  /// **'Testo tenue'**
  String get tokenTextFaint;

  /// No description provided for @tokenHero.
  ///
  /// In it, this message translates to:
  /// **'Sfondo del lettore'**
  String get tokenHero;

  /// No description provided for @tokenError.
  ///
  /// In it, this message translates to:
  /// **'Errore'**
  String get tokenError;

  /// No description provided for @pickerHue.
  ///
  /// In it, this message translates to:
  /// **'Tonalità'**
  String get pickerHue;

  /// No description provided for @pickerSv.
  ///
  /// In it, this message translates to:
  /// **'Saturazione e luminosità'**
  String get pickerSv;

  /// No description provided for @pickerAlpha.
  ///
  /// In it, this message translates to:
  /// **'Trasparenza'**
  String get pickerAlpha;

  /// No description provided for @pickerHex.
  ///
  /// In it, this message translates to:
  /// **'Codice colore'**
  String get pickerHex;

  /// No description provided for @pickerInvalid.
  ///
  /// In it, this message translates to:
  /// **'Codice non valido'**
  String get pickerInvalid;

  /// No description provided for @pickerRecent.
  ///
  /// In it, this message translates to:
  /// **'Usati di recente'**
  String get pickerRecent;

  /// No description provided for @contrastTextBg.
  ///
  /// In it, this message translates to:
  /// **'Testo su sfondo'**
  String get contrastTextBg;

  /// No description provided for @contrastMutedSurface.
  ///
  /// In it, this message translates to:
  /// **'Testo secondario su superficie'**
  String get contrastMutedSurface;

  /// No description provided for @contrastOnAccent.
  ///
  /// In it, this message translates to:
  /// **'Testo sull\'accento'**
  String get contrastOnAccent;

  /// No description provided for @contrastAccentBg.
  ///
  /// In it, this message translates to:
  /// **'Accento su sfondo'**
  String get contrastAccentBg;

  /// No description provided for @themeBackground.
  ///
  /// In it, this message translates to:
  /// **'Sfondo delle pagine'**
  String get themeBackground;

  /// No description provided for @bgSolid.
  ///
  /// In it, this message translates to:
  /// **'Tinta unita'**
  String get bgSolid;

  /// No description provided for @bgGradient.
  ///
  /// In it, this message translates to:
  /// **'Sfumatura'**
  String get bgGradient;

  /// No description provided for @bgImage.
  ///
  /// In it, this message translates to:
  /// **'Immagine'**
  String get bgImage;

  /// No description provided for @bgGradientEnd.
  ///
  /// In it, this message translates to:
  /// **'Colore finale'**
  String get bgGradientEnd;

  /// No description provided for @bgAngle.
  ///
  /// In it, this message translates to:
  /// **'Direzione'**
  String get bgAngle;

  /// No description provided for @bgPickImage.
  ///
  /// In it, this message translates to:
  /// **'Scegli immagine…'**
  String get bgPickImage;

  /// No description provided for @bgRemoveImage.
  ///
  /// In it, this message translates to:
  /// **'Rimuovi immagine'**
  String get bgRemoveImage;

  /// No description provided for @bgDim.
  ///
  /// In it, this message translates to:
  /// **'Oscuramento'**
  String get bgDim;

  /// No description provided for @bgBlur.
  ///
  /// In it, this message translates to:
  /// **'Sfocatura'**
  String get bgBlur;

  /// No description provided for @bgCoverBackdrop.
  ///
  /// In it, this message translates to:
  /// **'In riproduzione: tinta della copertina'**
  String get bgCoverBackdrop;

  /// No description provided for @bgImageFailed.
  ///
  /// In it, this message translates to:
  /// **'Impossibile usare l\'immagine'**
  String get bgImageFailed;

  /// No description provided for @themeCopyName.
  ///
  /// In it, this message translates to:
  /// **'{name} (copia)'**
  String themeCopyName(String name);

  /// No description provided for @selectedCount.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, one{1 selezionato} other{{count} selezionati}}'**
  String selectedCount(int count);

  /// No description provided for @selectAll.
  ///
  /// In it, this message translates to:
  /// **'Seleziona tutto'**
  String get selectAll;

  /// No description provided for @exitSelection.
  ///
  /// In it, this message translates to:
  /// **'Esci dalla selezione'**
  String get exitSelection;

  /// No description provided for @bulkActions.
  ///
  /// In it, this message translates to:
  /// **'Azioni'**
  String get bulkActions;

  /// No description provided for @playNextMany.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, one{1 brano verrà riprodotto dopo} other{{count} brani verranno riprodotti dopo}}'**
  String playNextMany(int count);

  /// No description provided for @addedToQueueMany.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, one{1 brano aggiunto in coda} other{{count} brani aggiunti in coda}}'**
  String addedToQueueMany(int count);

  /// No description provided for @addedToPlaylistMany.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, one{1 brano aggiunto a «{name}»} other{{count} brani aggiunti a «{name}»}}'**
  String addedToPlaylistMany(int count, String name);

  /// No description provided for @addedToPlaylistSkipped.
  ///
  /// In it, this message translates to:
  /// **'{added} aggiunti a «{name}», {skipped} già presenti'**
  String addedToPlaylistSkipped(int added, int skipped, String name);

  /// No description provided for @allAlreadyInPlaylist.
  ///
  /// In it, this message translates to:
  /// **'Erano già tutti in «{name}»'**
  String allAlreadyInPlaylist(String name);

  /// No description provided for @favoritesAdded.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, one{1 brano nei preferiti} other{{count} brani nei preferiti}}'**
  String favoritesAdded(int count);

  /// No description provided for @favoritesRemoved.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, one{1 brano tolto dai preferiti} other{{count} brani tolti dai preferiti}}'**
  String favoritesRemoved(int count);

  /// No description provided for @bulkAddToFavorites.
  ///
  /// In it, this message translates to:
  /// **'Aggiungi ai preferiti'**
  String get bulkAddToFavorites;

  /// No description provided for @bulkRemoveFromFavorites.
  ///
  /// In it, this message translates to:
  /// **'Togli dai preferiti'**
  String get bulkRemoveFromFavorites;

  /// No description provided for @removeManyFromPlaylistTitle.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, one{Rimuovere 1 brano dalla playlist?} other{Rimuovere {count} brani dalla playlist?}}'**
  String removeManyFromPlaylistTitle(int count);

  /// No description provided for @removeManyFromPlaylistBody.
  ///
  /// In it, this message translates to:
  /// **'I file e la libreria non vengono toccati.'**
  String get removeManyFromPlaylistBody;

  /// No description provided for @removedManyFromPlaylist.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, one{1 brano rimosso} other{{count} brani rimossi}}'**
  String removedManyFromPlaylist(int count);

  /// No description provided for @removeManyFromLibraryTitle.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, one{Togliere 1 brano dalla libreria?} other{Togliere {count} brani dalla libreria?}}'**
  String removeManyFromLibraryTitle(int count);

  /// No description provided for @removeManyFromLibraryBody.
  ///
  /// In it, this message translates to:
  /// **'I file non esistono più: spariscono solo dalla libreria (perdi preferiti e playlist di questi brani).'**
  String get removeManyFromLibraryBody;

  /// No description provided for @removedManyFromLibrary.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, one{1 brano tolto dalla libreria} other{{count} brani tolti dalla libreria}}'**
  String removedManyFromLibrary(int count);

  /// No description provided for @ytDownloadsStarted.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, one{1 download avviato} other{{count} download avviati}}'**
  String ytDownloadsStarted(int count);

  /// No description provided for @ytDownloadsSkipped.
  ///
  /// In it, this message translates to:
  /// **'{started} download avviati, {skipped} già in libreria o in corso'**
  String ytDownloadsSkipped(int started, int skipped);

  /// No description provided for @ytNothingToDownload.
  ///
  /// In it, this message translates to:
  /// **'Sono già tutti in libreria o in corso'**
  String get ytNothingToDownload;

  /// No description provided for @themeChiaro.
  ///
  /// In it, this message translates to:
  /// **'Chiaro'**
  String get themeChiaro;

  /// No description provided for @settingsAccent.
  ///
  /// In it, this message translates to:
  /// **'Colore d\'accento'**
  String get settingsAccent;

  /// No description provided for @accentViola.
  ///
  /// In it, this message translates to:
  /// **'Viola'**
  String get accentViola;

  /// No description provided for @accentBlu.
  ///
  /// In it, this message translates to:
  /// **'Blu'**
  String get accentBlu;

  /// No description provided for @accentAcqua.
  ///
  /// In it, this message translates to:
  /// **'Verde acqua'**
  String get accentAcqua;

  /// No description provided for @accentVerde.
  ///
  /// In it, this message translates to:
  /// **'Verde'**
  String get accentVerde;

  /// No description provided for @accentAmbra.
  ///
  /// In it, this message translates to:
  /// **'Ambra'**
  String get accentAmbra;

  /// No description provided for @accentArancio.
  ///
  /// In it, this message translates to:
  /// **'Arancio'**
  String get accentArancio;

  /// No description provided for @accentRosa.
  ///
  /// In it, this message translates to:
  /// **'Rosa'**
  String get accentRosa;

  /// No description provided for @accentRosso.
  ///
  /// In it, this message translates to:
  /// **'Rosso'**
  String get accentRosso;

  /// No description provided for @onboardingSkip.
  ///
  /// In it, this message translates to:
  /// **'Salta'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In it, this message translates to:
  /// **'Avanti'**
  String get onboardingNext;

  /// No description provided for @onboardingStart.
  ///
  /// In it, this message translates to:
  /// **'Inizia'**
  String get onboardingStart;

  /// No description provided for @onboardingPageOf.
  ///
  /// In it, this message translates to:
  /// **'Pagina {page} di {total}'**
  String onboardingPageOf(int page, int total);

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In it, this message translates to:
  /// **'Benvenuto in Codecore'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeBody.
  ///
  /// In it, this message translates to:
  /// **'Il tuo lettore musicale personale: niente account, niente server. La musica resta sul tuo dispositivo.'**
  String get onboardingWelcomeBody;

  /// No description provided for @onboardingFoldersTitle.
  ///
  /// In it, this message translates to:
  /// **'La tua musica'**
  String get onboardingFoldersTitle;

  /// No description provided for @onboardingFoldersBody.
  ///
  /// In it, this message translates to:
  /// **'Scegli le cartelle dove tieni i brani. Codecore li legge: non li modifica e non li sposta.'**
  String get onboardingFoldersBody;

  /// No description provided for @onboardingFoldersAdded.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, one{1 cartella aggiunta} other{{count} cartelle aggiunte}}'**
  String onboardingFoldersAdded(int count);

  /// No description provided for @onboardingAllowAccess.
  ///
  /// In it, this message translates to:
  /// **'Consenti l’accesso ai file audio'**
  String get onboardingAllowAccess;

  /// No description provided for @onboardingAccessGranted.
  ///
  /// In it, this message translates to:
  /// **'Accesso consentito'**
  String get onboardingAccessGranted;

  /// No description provided for @onboardingOnlineTitle.
  ///
  /// In it, this message translates to:
  /// **'Funzioni online'**
  String get onboardingOnlineTitle;

  /// No description provided for @onboardingOnlineBody.
  ///
  /// In it, this message translates to:
  /// **'Sono spente: Codecore non si collega a Internet per conto suo. Puoi accenderle ora o più tardi dalle Impostazioni.'**
  String get onboardingOnlineBody;

  /// No description provided for @onboardingShareTitle.
  ///
  /// In it, this message translates to:
  /// **'Download, Jam e condivisione'**
  String get onboardingShareTitle;

  /// No description provided for @onboardingYoutubeBody.
  ///
  /// In it, this message translates to:
  /// **'Puoi scaricare brani da YouTube sul tuo dispositivo, per ascoltarli come il resto della tua musica.'**
  String get onboardingYoutubeBody;

  /// No description provided for @onboardingJamBody.
  ///
  /// In it, this message translates to:
  /// **'Con una Jam ascolti la stessa musica insieme a un altro dispositivo sulla stessa rete.'**
  String get onboardingJamBody;

  /// No description provided for @onboardingSendBody.
  ///
  /// In it, this message translates to:
  /// **'Puoi inviare brani ad altri dispositivi vicini, con un PIN, senza passare da Internet.'**
  String get onboardingSendBody;

  /// No description provided for @historyTitle.
  ///
  /// In it, this message translates to:
  /// **'Cronologia'**
  String get historyTitle;

  /// No description provided for @historySubtitle.
  ///
  /// In it, this message translates to:
  /// **'Quello che hai ascoltato'**
  String get historySubtitle;

  /// No description provided for @historyToday.
  ///
  /// In it, this message translates to:
  /// **'Oggi'**
  String get historyToday;

  /// No description provided for @historyYesterday.
  ///
  /// In it, this message translates to:
  /// **'Ieri'**
  String get historyYesterday;

  /// No description provided for @historyEmpty.
  ///
  /// In it, this message translates to:
  /// **'Qui comparirà quello che ascolti.'**
  String get historyEmpty;

  /// No description provided for @historyOff.
  ///
  /// In it, this message translates to:
  /// **'La cronologia è spenta: attivala in Impostazioni → Riproduzione.'**
  String get historyOff;

  /// No description provided for @historyClear.
  ///
  /// In it, this message translates to:
  /// **'Cancella cronologia'**
  String get historyClear;

  /// No description provided for @historyClearTitle.
  ///
  /// In it, this message translates to:
  /// **'Cancellare la cronologia?'**
  String get historyClearTitle;

  /// No description provided for @historyClearBody.
  ///
  /// In it, this message translates to:
  /// **'Si cancella solo l’elenco degli ascolti: contatori, preferiti e playlist restano come sono.'**
  String get historyClearBody;

  /// No description provided for @historyCleared.
  ///
  /// In it, this message translates to:
  /// **'Cronologia cancellata'**
  String get historyCleared;

  /// No description provided for @settingsRecordHistory.
  ///
  /// In it, this message translates to:
  /// **'Registra la cronologia di ascolto'**
  String get settingsRecordHistory;

  /// No description provided for @settingsRecordHistoryHint.
  ///
  /// In it, this message translates to:
  /// **'Resta sul dispositivo. Spenta, non si aggiunge nient’altro all’elenco.'**
  String get settingsRecordHistoryHint;

  /// No description provided for @statsTitle.
  ///
  /// In it, this message translates to:
  /// **'Statistiche'**
  String get statsTitle;

  /// No description provided for @statsSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Quanto e cosa ascolti'**
  String get statsSubtitle;

  /// No description provided for @statsMonth.
  ///
  /// In it, this message translates to:
  /// **'Mese'**
  String get statsMonth;

  /// No description provided for @statsYear.
  ///
  /// In it, this message translates to:
  /// **'Anno'**
  String get statsYear;

  /// No description provided for @statsPrevious.
  ///
  /// In it, this message translates to:
  /// **'Periodo precedente'**
  String get statsPrevious;

  /// No description provided for @statsNext.
  ///
  /// In it, this message translates to:
  /// **'Periodo successivo'**
  String get statsNext;

  /// No description provided for @statsEmpty.
  ///
  /// In it, this message translates to:
  /// **'Nessun ascolto in questo periodo.'**
  String get statsEmpty;

  /// No description provided for @statsPlays.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, one{1 ascolto} other{{count} ascolti}}'**
  String statsPlays(int count);

  /// No description provided for @statsDistinct.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, one{1 brano diverso} other{{count} brani diversi}}'**
  String statsDistinct(int count);

  /// No description provided for @statsHoursMinutes.
  ///
  /// In it, this message translates to:
  /// **'{hours} h {minutes} min'**
  String statsHoursMinutes(int hours, int minutes);

  /// No description provided for @statsTopTracks.
  ///
  /// In it, this message translates to:
  /// **'Brani più ascoltati'**
  String get statsTopTracks;

  /// No description provided for @statsTopArtists.
  ///
  /// In it, this message translates to:
  /// **'Artisti più ascoltati'**
  String get statsTopArtists;

  /// No description provided for @statsTopAlbums.
  ///
  /// In it, this message translates to:
  /// **'Album più ascoltati'**
  String get statsTopAlbums;

  /// No description provided for @statsFavouriteHour.
  ///
  /// In it, this message translates to:
  /// **'Ora preferita'**
  String get statsFavouriteHour;

  /// No description provided for @statsFirstListen.
  ///
  /// In it, this message translates to:
  /// **'Primo ascolto'**
  String get statsFirstListen;

  /// No description provided for @statsFirstValue.
  ///
  /// In it, this message translates to:
  /// **'{title} · {date}'**
  String statsFirstValue(String title, String date);

  /// No description provided for @statsYourMonth.
  ///
  /// In it, this message translates to:
  /// **'Il tuo mese'**
  String get statsYourMonth;

  /// No description provided for @statsTopArtistHome.
  ///
  /// In it, this message translates to:
  /// **'Il più ascoltato: {name}'**
  String statsTopArtistHome(String name);

  /// No description provided for @ruleChipArtist.
  ///
  /// In it, this message translates to:
  /// **'artista:'**
  String get ruleChipArtist;

  /// No description provided for @ruleChipYear.
  ///
  /// In it, this message translates to:
  /// **'anno:'**
  String get ruleChipYear;

  /// No description provided for @ruleChipGenre.
  ///
  /// In it, this message translates to:
  /// **'genere:'**
  String get ruleChipGenre;

  /// No description provided for @ruleChipTag.
  ///
  /// In it, this message translates to:
  /// **'tag:'**
  String get ruleChipTag;

  /// No description provided for @ruleChipFavorites.
  ///
  /// In it, this message translates to:
  /// **'preferiti'**
  String get ruleChipFavorites;

  /// No description provided for @ruleWarning.
  ///
  /// In it, this message translates to:
  /// **'Non capisco «{term}»: lo cerco come testo.'**
  String ruleWarning(String term);

  /// No description provided for @ruleHelpTooltip.
  ///
  /// In it, this message translates to:
  /// **'Aiuto sulla ricerca'**
  String get ruleHelpTooltip;

  /// No description provided for @smartPlaylistNew.
  ///
  /// In it, this message translates to:
  /// **'Nuova playlist intelligente'**
  String get smartPlaylistNew;

  /// No description provided for @smartPlaylistEdit.
  ///
  /// In it, this message translates to:
  /// **'Modifica playlist intelligente'**
  String get smartPlaylistEdit;

  /// No description provided for @smartPlaylistLabel.
  ///
  /// In it, this message translates to:
  /// **'Playlist intelligente'**
  String get smartPlaylistLabel;

  /// No description provided for @smartSubtitle.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, one{Playlist intelligente · 1 brano} other{Playlist intelligente · {count} brani}}'**
  String smartSubtitle(int count);

  /// No description provided for @smartName.
  ///
  /// In it, this message translates to:
  /// **'Nome'**
  String get smartName;

  /// No description provided for @smartNameRequired.
  ///
  /// In it, this message translates to:
  /// **'Scrivi un nome'**
  String get smartNameRequired;

  /// No description provided for @smartRules.
  ///
  /// In it, this message translates to:
  /// **'Regole'**
  String get smartRules;

  /// No description provided for @smartRulesHint.
  ///
  /// In it, this message translates to:
  /// **'artista:\"pink floyd\" -live anno:1970..1979'**
  String get smartRulesHint;

  /// No description provided for @smartNoRules.
  ///
  /// In it, this message translates to:
  /// **'Senza regole la playlist contiene tutta la libreria.'**
  String get smartNoRules;

  /// No description provided for @smartSortBy.
  ///
  /// In it, this message translates to:
  /// **'Ordina per'**
  String get smartSortBy;

  /// No description provided for @smartSortMostPlayed.
  ///
  /// In it, this message translates to:
  /// **'Più ascoltati'**
  String get smartSortMostPlayed;

  /// No description provided for @smartSortRandom.
  ///
  /// In it, this message translates to:
  /// **'A caso'**
  String get smartSortRandom;

  /// No description provided for @smartLimit.
  ///
  /// In it, this message translates to:
  /// **'Limite di brani (facoltativo)'**
  String get smartLimit;

  /// No description provided for @smartTemplates.
  ///
  /// In it, this message translates to:
  /// **'Modelli'**
  String get smartTemplates;

  /// No description provided for @smartTplNever.
  ///
  /// In it, this message translates to:
  /// **'Mai ascoltati'**
  String get smartTplNever;

  /// No description provided for @smartTplRecent.
  ///
  /// In it, this message translates to:
  /// **'Aggiunti di recente'**
  String get smartTplRecent;

  /// No description provided for @smartTplTop.
  ///
  /// In it, this message translates to:
  /// **'I più ascoltati'**
  String get smartTplTop;

  /// No description provided for @smartTpl90s.
  ///
  /// In it, this message translates to:
  /// **'Anni ’90'**
  String get smartTpl90s;

  /// No description provided for @smartConvert.
  ///
  /// In it, this message translates to:
  /// **'Converti in playlist normale'**
  String get smartConvert;

  /// No description provided for @smartConverted.
  ///
  /// In it, this message translates to:
  /// **'Creata la playlist «{name}» con l’elenco attuale'**
  String smartConverted(String name);

  /// No description provided for @smartDeleteTitle.
  ///
  /// In it, this message translates to:
  /// **'Eliminare «{name}»?'**
  String smartDeleteTitle(String name);

  /// No description provided for @smartDeleteBody.
  ///
  /// In it, this message translates to:
  /// **'Si elimina solo la regola: i brani restano dove sono.'**
  String get smartDeleteBody;

  /// No description provided for @smartAutoNote.
  ///
  /// In it, this message translates to:
  /// **'L’elenco si aggiorna da solo.'**
  String get smartAutoNote;

  /// No description provided for @tagsTitle.
  ///
  /// In it, this message translates to:
  /// **'Etichette'**
  String get tagsTitle;

  /// No description provided for @tagsSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Le tue etichette'**
  String get tagsSubtitle;

  /// No description provided for @tagsCount.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, one{1 etichetta} other{{count} etichette}}'**
  String tagsCount(int count);

  /// No description provided for @tagsEllipsis.
  ///
  /// In it, this message translates to:
  /// **'Etichette…'**
  String get tagsEllipsis;

  /// No description provided for @tagNew.
  ///
  /// In it, this message translates to:
  /// **'Nuova etichetta'**
  String get tagNew;

  /// No description provided for @tagRename.
  ///
  /// In it, this message translates to:
  /// **'Rinomina etichetta'**
  String get tagRename;

  /// No description provided for @tagColor.
  ///
  /// In it, this message translates to:
  /// **'Colore'**
  String get tagColor;

  /// No description provided for @tagNoColor.
  ///
  /// In it, this message translates to:
  /// **'Nessun colore'**
  String get tagNoColor;

  /// No description provided for @tagNameTaken.
  ///
  /// In it, this message translates to:
  /// **'Esiste già un’etichetta con questo nome'**
  String get tagNameTaken;

  /// No description provided for @tagDeleteTitle.
  ///
  /// In it, this message translates to:
  /// **'Eliminare l’etichetta «{name}»?'**
  String tagDeleteTitle(String name);

  /// No description provided for @tagDeleteBody.
  ///
  /// In it, this message translates to:
  /// **'Si toglie solo l’etichetta dai brani: i brani restano nella libreria.'**
  String get tagDeleteBody;

  /// No description provided for @tagsEmpty.
  ///
  /// In it, this message translates to:
  /// **'Nessuna etichetta: creane una dal menu di un brano.'**
  String get tagsEmpty;

  /// No description provided for @tagAddToSelection.
  ///
  /// In it, this message translates to:
  /// **'Aggiungi etichetta…'**
  String get tagAddToSelection;

  /// No description provided for @tagRemoveFromSelection.
  ///
  /// In it, this message translates to:
  /// **'Togli etichetta…'**
  String get tagRemoveFromSelection;

  /// No description provided for @tagAssigned.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, one{1 brano etichettato «{name}»} other{{count} brani etichettati «{name}»}}'**
  String tagAssigned(int count, String name);

  /// No description provided for @tagUnassigned.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, one{«{name}» tolta da 1 brano} other{«{name}» tolta da {count} brani}}'**
  String tagUnassigned(int count, String name);

  /// No description provided for @tagNoneToRemove.
  ///
  /// In it, this message translates to:
  /// **'I brani scelti non hanno etichette.'**
  String get tagNoneToRemove;

  /// No description provided for @ruleHelpTitle.
  ///
  /// In it, this message translates to:
  /// **'Cercare con gli operatori'**
  String get ruleHelpTitle;

  /// No description provided for @ruleHelpIntro.
  ///
  /// In it, this message translates to:
  /// **'Scrivi parole come sempre, oppure aggiungi operatori: tutti devono valere insieme.'**
  String get ruleHelpIntro;

  /// No description provided for @ruleHelpArtist.
  ///
  /// In it, this message translates to:
  /// **'artista:\"pink floyd\" — brani di un artista (basta una parte del nome); lo stesso con album:, genere:, cartella:'**
  String get ruleHelpArtist;

  /// No description provided for @ruleHelpYear.
  ///
  /// In it, this message translates to:
  /// **'anno:1990..1999 — un intervallo (anche aperto: anno:..1980, anno:2000..); anno>1990, anno<=1985'**
  String get ruleHelpYear;

  /// No description provided for @ruleHelpDuration.
  ///
  /// In it, this message translates to:
  /// **'durata>5m — durata (m minuti, s secondi): durata<90s, durata:2m..4m'**
  String get ruleHelpDuration;

  /// No description provided for @ruleHelpAdded.
  ///
  /// In it, this message translates to:
  /// **'aggiunto<30g — aggiunti da meno di 30 giorni (g giorni, sett settimane, mesi): aggiunto>6mesi'**
  String get ruleHelpAdded;

  /// No description provided for @ruleHelpNot.
  ///
  /// In it, this message translates to:
  /// **'-live — il segno meno esclude: -artista:floyd, -\"dal vivo\"'**
  String get ruleHelpNot;

  /// No description provided for @ruleHelpOr.
  ///
  /// In it, this message translates to:
  /// **'rock OR jazz — OR (maiuscolo) tra due termini: ne basta uno'**
  String get ruleHelpOr;

  /// No description provided for @ruleHelpFlags.
  ///
  /// In it, this message translates to:
  /// **'preferiti, mai-ascoltati — solo i preferiti, o i brani mai ascoltati; ascolti>10 per quelli più ascoltati'**
  String get ruleHelpFlags;

  /// No description provided for @ruleHelpOthers.
  ///
  /// In it, this message translates to:
  /// **'tag:live, formato:flac — un’etichetta tua, o il formato del file (nome intero, senza maiuscole)'**
  String get ruleHelpOthers;

  /// No description provided for @ruleHelpSmart.
  ///
  /// In it, this message translates to:
  /// **'Le stesse regole servono per le playlist intelligenti (Libreria → + → Nuova playlist intelligente).'**
  String get ruleHelpSmart;

  /// No description provided for @cleanupSection.
  ///
  /// In it, this message translates to:
  /// **'Pulizia libreria'**
  String get cleanupSection;

  /// No description provided for @duplicatesTitle.
  ///
  /// In it, this message translates to:
  /// **'Duplicati'**
  String get duplicatesTitle;

  /// No description provided for @duplicatesTileHint.
  ///
  /// In it, this message translates to:
  /// **'Lo stesso brano in più copie o qualità'**
  String get duplicatesTileHint;

  /// No description provided for @duplicatesIntro.
  ///
  /// In it, this message translates to:
  /// **'Cerca lo stesso brano in più copie: lo stesso file in due cartelle o lo stesso brano in due qualità. Prima di unire vedi un’anteprima. Preferiti, playlist, ascolti, testi ed etichette passano al brano che tieni; gli altri vengono solo nascosti e li ripristini da «Brani nascosti». Nessun file viene cancellato senza una doppia conferma.'**
  String get duplicatesIntro;

  /// No description provided for @duplicatesSearch.
  ///
  /// In it, this message translates to:
  /// **'Cerca duplicati'**
  String get duplicatesSearch;

  /// No description provided for @duplicatesSearchAgain.
  ///
  /// In it, this message translates to:
  /// **'Cerca di nuovo'**
  String get duplicatesSearchAgain;

  /// No description provided for @duplicatesReading.
  ///
  /// In it, this message translates to:
  /// **'Leggo la libreria…'**
  String get duplicatesReading;

  /// No description provided for @duplicatesHashing.
  ///
  /// In it, this message translates to:
  /// **'Controllo i file: {done} di {total}'**
  String duplicatesHashing(int done, int total);

  /// No description provided for @duplicatesGrouping.
  ///
  /// In it, this message translates to:
  /// **'Confronto i brani…'**
  String get duplicatesGrouping;

  /// No description provided for @duplicatesFailed.
  ///
  /// In it, this message translates to:
  /// **'La ricerca non è riuscita. Riprova.'**
  String get duplicatesFailed;

  /// No description provided for @duplicatesNone.
  ///
  /// In it, this message translates to:
  /// **'Nessun duplicato trovato'**
  String get duplicatesNone;

  /// No description provided for @duplicatesSummary.
  ///
  /// In it, this message translates to:
  /// **'{groups, plural, one{1 gruppo} other{{groups} gruppi}} · {hidden, plural, one{1 brano da nascondere} other{{hidden} brani da nascondere}}'**
  String duplicatesSummary(int groups, int hidden);

  /// No description provided for @duplicatesExactBadge.
  ///
  /// In it, this message translates to:
  /// **'Identici'**
  String get duplicatesExactBadge;

  /// No description provided for @duplicatesProbableBadge.
  ///
  /// In it, this message translates to:
  /// **'Probabili'**
  String get duplicatesProbableBadge;

  /// No description provided for @duplicatesKeepLabel.
  ///
  /// In it, this message translates to:
  /// **'Da tenere'**
  String get duplicatesKeepLabel;

  /// No description provided for @duplicatesPickKeep.
  ///
  /// In it, this message translates to:
  /// **'Tocca un brano per tenerlo'**
  String get duplicatesPickKeep;

  /// No description provided for @duplicatesMerge.
  ///
  /// In it, this message translates to:
  /// **'Unisci'**
  String get duplicatesMerge;

  /// No description provided for @duplicatesNotDuplicates.
  ///
  /// In it, this message translates to:
  /// **'Non sono duplicati'**
  String get duplicatesNotDuplicates;

  /// No description provided for @duplicatesMergeAllExact.
  ///
  /// In it, this message translates to:
  /// **'Unisci tutti gli identici ({count})'**
  String duplicatesMergeAllExact(int count);

  /// No description provided for @duplicatesMergeAllTitle.
  ///
  /// In it, this message translates to:
  /// **'Unire tutti gli identici?'**
  String get duplicatesMergeAllTitle;

  /// No description provided for @duplicatesMergeAllBody.
  ///
  /// In it, this message translates to:
  /// **'{groups, plural, one{1 gruppo} other{{groups} gruppi}}, {hidden, plural, one{1 brano nascosto} other{{hidden} brani nascosti}}. Preferiti, playlist, ascolti e testi passano ai brani che restano.'**
  String duplicatesMergeAllBody(int groups, int hidden);

  /// No description provided for @duplicatesMerged.
  ///
  /// In it, this message translates to:
  /// **'Unito: {count, plural, one{1 brano nascosto} other{{count} brani nascosti}}'**
  String duplicatesMerged(int count);

  /// No description provided for @duplicatesDeleteFiles.
  ///
  /// In it, this message translates to:
  /// **'Elimina anche i file ({count}, {size})'**
  String duplicatesDeleteFiles(int count, String size);

  /// No description provided for @duplicatesDeleteListTitle.
  ///
  /// In it, this message translates to:
  /// **'Eliminare questi file?'**
  String get duplicatesDeleteListTitle;

  /// No description provided for @duplicatesDeleteListBody.
  ///
  /// In it, this message translates to:
  /// **'Verranno cancellati dal dispositivo e non si possono recuperare. I brani che tieni restano dove sono.'**
  String get duplicatesDeleteListBody;

  /// No description provided for @duplicatesDeleteContinue.
  ///
  /// In it, this message translates to:
  /// **'Continua'**
  String get duplicatesDeleteContinue;

  /// No description provided for @duplicatesDeleteFinalTitle.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, one{Eliminare definitivamente 1 file?} other{Eliminare definitivamente {count} file?}}'**
  String duplicatesDeleteFinalTitle(int count);

  /// No description provided for @duplicatesDeleteFinalBody.
  ///
  /// In it, this message translates to:
  /// **'Spazio liberato: {size}. Questa azione non si può annullare.'**
  String duplicatesDeleteFinalBody(String size);

  /// No description provided for @duplicatesDeleteGo.
  ///
  /// In it, this message translates to:
  /// **'Elimina definitivamente'**
  String get duplicatesDeleteGo;

  /// No description provided for @duplicatesDeleteDoneTitle.
  ///
  /// In it, this message translates to:
  /// **'Fatto'**
  String get duplicatesDeleteDoneTitle;

  /// No description provided for @duplicatesDeleteDone.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, one{1 file eliminato} other{{count} file eliminati}} ({size}).'**
  String duplicatesDeleteDone(int count, String size);

  /// No description provided for @duplicatesDeleteFailed.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, one{1 file non eliminato:} other{{count} file non eliminati:}}'**
  String duplicatesDeleteFailed(int count);

  /// No description provided for @duplicatesDeleteSkipped.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, one{1 file non toccato: è lo stesso file del brano tenuto.} other{{count} file non toccati: sono lo stesso file del brano tenuto.}}'**
  String duplicatesDeleteSkipped(int count);

  /// No description provided for @duplicatesDeleteAndroidHint.
  ///
  /// In it, this message translates to:
  /// **'Su Android si possono eliminare solo i file nelle cartelle a cui l’app ha accesso.'**
  String get duplicatesDeleteAndroidHint;

  /// No description provided for @activityCleanup.
  ///
  /// In it, this message translates to:
  /// **'Ricerca duplicati: {done} di {total}'**
  String activityCleanup(int done, int total);

  /// No description provided for @hiddenTracksTitle.
  ///
  /// In it, this message translates to:
  /// **'Brani nascosti'**
  String get hiddenTracksTitle;

  /// No description provided for @hiddenTracksCount.
  ///
  /// In it, this message translates to:
  /// **'Brani nascosti ({count})'**
  String hiddenTracksCount(int count);

  /// No description provided for @hiddenTracksEmpty.
  ///
  /// In it, this message translates to:
  /// **'Nessun brano nascosto'**
  String get hiddenTracksEmpty;

  /// No description provided for @hiddenTracksHint.
  ///
  /// In it, this message translates to:
  /// **'I doppioni uniti non compaiono in libreria. «Ripristina» li rimette al loro posto.'**
  String get hiddenTracksHint;

  /// No description provided for @hiddenRestore.
  ///
  /// In it, this message translates to:
  /// **'Ripristina'**
  String get hiddenRestore;

  /// No description provided for @hiddenRestored.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, one{1 brano ripristinato} other{{count} brani ripristinati}}'**
  String hiddenRestored(int count);

  /// No description provided for @albumMergeWith.
  ///
  /// In it, this message translates to:
  /// **'Unisci con…'**
  String get albumMergeWith;

  /// No description provided for @albumMergeTitle.
  ///
  /// In it, this message translates to:
  /// **'Unisci album'**
  String get albumMergeTitle;

  /// No description provided for @albumMergeIntro.
  ///
  /// In it, this message translates to:
  /// **'Scegli gli album da unire a «{name}». I brani passano a un solo album con il titolo e l’artista che indichi; la copertina resta quella di «{name}».'**
  String albumMergeIntro(String name);

  /// No description provided for @albumMergeSearch.
  ///
  /// In it, this message translates to:
  /// **'Cerca un album'**
  String get albumMergeSearch;

  /// No description provided for @albumMergeNone.
  ///
  /// In it, this message translates to:
  /// **'Non ci sono altri album'**
  String get albumMergeNone;

  /// No description provided for @albumFieldTitle.
  ///
  /// In it, this message translates to:
  /// **'Titolo dell’album'**
  String get albumFieldTitle;

  /// No description provided for @albumFieldArtist.
  ///
  /// In it, this message translates to:
  /// **'Artista dell’album'**
  String get albumFieldArtist;

  /// No description provided for @albumMergeAction.
  ///
  /// In it, this message translates to:
  /// **'Unisci album'**
  String get albumMergeAction;

  /// No description provided for @albumMerged.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, one{1 album unito in «{name}»} other{{count} album uniti in «{name}»}}'**
  String albumMerged(int count, String name);

  /// No description provided for @moveToAlbum.
  ///
  /// In it, this message translates to:
  /// **'Sposta in un nuovo album…'**
  String get moveToAlbum;

  /// No description provided for @moveToAlbumTitle.
  ///
  /// In it, this message translates to:
  /// **'Sposta in un album'**
  String get moveToAlbumTitle;

  /// No description provided for @moveToAlbumBody.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, one{1 brano andrà} other{{count} brani andranno}} nell’album indicato. Se esiste già, si uniranno ad esso.'**
  String moveToAlbumBody(int count);

  /// No description provided for @moveToAlbumGo.
  ///
  /// In it, this message translates to:
  /// **'Sposta'**
  String get moveToAlbumGo;

  /// No description provided for @movedToAlbum.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, one{1 brano spostato in «{name}»} other{{count} brani spostati in «{name}»}}'**
  String movedToAlbum(int count, String name);

  /// No description provided for @searchSourceYoutube.
  ///
  /// In it, this message translates to:
  /// **'YouTube'**
  String get searchSourceYoutube;

  /// No description provided for @searchSourceYoutubeMusic.
  ///
  /// In it, this message translates to:
  /// **'YouTube Music'**
  String get searchSourceYoutubeMusic;

  /// No description provided for @searchSourceSoundcloud.
  ///
  /// In it, this message translates to:
  /// **'SoundCloud'**
  String get searchSourceSoundcloud;

  /// No description provided for @importSoundCloud.
  ///
  /// In it, this message translates to:
  /// **'Cerca anche su SoundCloud se un brano non si trova'**
  String get importSoundCloud;

  /// No description provided for @importSoundCloudHint.
  ///
  /// In it, this message translates to:
  /// **'Solo per le righe di un’importazione che YouTube non trova: una ricerca in più per riga. Spento di serie.'**
  String get importSoundCloudHint;

  /// No description provided for @ytHintSoundcloud.
  ///
  /// In it, this message translates to:
  /// **'Cerca su SoundCloud'**
  String get ytHintSoundcloud;

  /// No description provided for @playlistSourceTitle.
  ///
  /// In it, this message translates to:
  /// **'Playlist o canale YouTube'**
  String get playlistSourceTitle;

  /// No description provided for @playlistSourceLoading.
  ///
  /// In it, this message translates to:
  /// **'Leggo l’elenco dei video…'**
  String get playlistSourceLoading;

  /// No description provided for @playlistSourceName.
  ///
  /// In it, this message translates to:
  /// **'Nome della playlist'**
  String get playlistSourceName;

  /// No description provided for @playlistSourceCount.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, one{1 video} other{{count} video}}'**
  String playlistSourceCount(int count);

  /// No description provided for @playlistSourceUnavailable.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, one{1 video non disponibile (privato o rimosso)} other{{count} video non disponibili (privati o rimossi)}}'**
  String playlistSourceUnavailable(int count);

  /// No description provided for @playlistSourceTruncated.
  ///
  /// In it, this message translates to:
  /// **'Mostro i primi {count} video.'**
  String playlistSourceTruncated(int count);

  /// No description provided for @playlistSourceLong.
  ///
  /// In it, this message translates to:
  /// **'Sono {count} video: ci vorrà {time}.'**
  String playlistSourceLong(int count, String time);

  /// No description provided for @playlistSourceNone.
  ///
  /// In it, this message translates to:
  /// **'Nessuno'**
  String get playlistSourceNone;

  /// No description provided for @playlistSourceEmpty.
  ///
  /// In it, this message translates to:
  /// **'Non ci sono video da scaricare qui.'**
  String get playlistSourceEmpty;

  /// No description provided for @playlistSourceGo.
  ///
  /// In it, this message translates to:
  /// **'Scarica in una playlist ({count})'**
  String playlistSourceGo(int count);

  /// No description provided for @playlistSourceStarted.
  ///
  /// In it, this message translates to:
  /// **'Download avviati nella playlist «{name}»'**
  String playlistSourceStarted(String name);

  /// No description provided for @podcastsTitle.
  ///
  /// In it, this message translates to:
  /// **'Podcast'**
  String get podcastsTitle;

  /// No description provided for @podcastsSubtitle.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, one{1 podcast} other{{count} podcast}}'**
  String podcastsSubtitle(int count);

  /// No description provided for @podcastsNotice.
  ///
  /// In it, this message translates to:
  /// **'I podcast si aggiornano solo quando lo chiedi.'**
  String get podcastsNotice;

  /// No description provided for @podcastsEmpty.
  ///
  /// In it, this message translates to:
  /// **'Non sei iscritto a nessun podcast.'**
  String get podcastsEmpty;

  /// No description provided for @podcastAdd.
  ///
  /// In it, this message translates to:
  /// **'Aggiungi podcast'**
  String get podcastAdd;

  /// No description provided for @podcastRefreshAll.
  ///
  /// In it, this message translates to:
  /// **'Aggiorna tutti'**
  String get podcastRefreshAll;

  /// No description provided for @podcastRefresh.
  ///
  /// In it, this message translates to:
  /// **'Aggiorna'**
  String get podcastRefresh;

  /// No description provided for @podcastRefreshed.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, =0{Nessun episodio nuovo} one{1 episodio nuovo} other{{count} episodi nuovi}}'**
  String podcastRefreshed(int count);

  /// No description provided for @podcastRefreshFailed.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, one{1 podcast non aggiornato} other{{count} podcast non aggiornati}}'**
  String podcastRefreshFailed(int count);

  /// No description provided for @podcastFeedUrl.
  ///
  /// In it, this message translates to:
  /// **'URL del feed'**
  String get podcastFeedUrl;

  /// No description provided for @podcastSubscribe.
  ///
  /// In it, this message translates to:
  /// **'Iscriviti'**
  String get podcastSubscribe;

  /// No description provided for @podcastSearchHint.
  ///
  /// In it, this message translates to:
  /// **'Cerca un podcast per nome'**
  String get podcastSearchHint;

  /// No description provided for @podcastSearchNone.
  ///
  /// In it, this message translates to:
  /// **'Nessun podcast trovato'**
  String get podcastSearchNone;

  /// No description provided for @podcastSubscribed.
  ///
  /// In it, this message translates to:
  /// **'Iscritto a «{name}»'**
  String podcastSubscribed(String name);

  /// No description provided for @podcastEpisodesCount.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, one{1 episodio} other{{count} episodi}}'**
  String podcastEpisodesCount(int count);

  /// No description provided for @podcastToListen.
  ///
  /// In it, this message translates to:
  /// **'{count} da ascoltare'**
  String podcastToListen(int count);

  /// No description provided for @podcastNoEpisodes.
  ///
  /// In it, this message translates to:
  /// **'Nessun episodio.'**
  String get podcastNoEpisodes;

  /// No description provided for @podcastStateDownloaded.
  ///
  /// In it, this message translates to:
  /// **'Scaricato'**
  String get podcastStateDownloaded;

  /// No description provided for @podcastStateDownloading.
  ///
  /// In it, this message translates to:
  /// **'Scarico… {percent}%'**
  String podcastStateDownloading(int percent);

  /// No description provided for @podcastStateHeard.
  ///
  /// In it, this message translates to:
  /// **'Ascoltato'**
  String get podcastStateHeard;

  /// No description provided for @podcastStateRemaining.
  ///
  /// In it, this message translates to:
  /// **'Mancano {time}'**
  String podcastStateRemaining(String time);

  /// No description provided for @podcastMarkHeard.
  ///
  /// In it, this message translates to:
  /// **'Segna come ascoltato'**
  String get podcastMarkHeard;

  /// No description provided for @podcastMarkNotHeard.
  ///
  /// In it, this message translates to:
  /// **'Segna come da ascoltare'**
  String get podcastMarkNotHeard;

  /// No description provided for @podcastDeleteFile.
  ///
  /// In it, this message translates to:
  /// **'Elimina il file'**
  String get podcastDeleteFile;

  /// No description provided for @podcastAutoDelete.
  ///
  /// In it, this message translates to:
  /// **'Elimina gli episodi ascoltati'**
  String get podcastAutoDelete;

  /// No description provided for @podcastAutoDeleteNever.
  ///
  /// In it, this message translates to:
  /// **'Mai'**
  String get podcastAutoDeleteNever;

  /// No description provided for @podcastAutoDeleteAfter.
  ///
  /// In it, this message translates to:
  /// **'{days, plural, one{Dopo 1 giorno} other{Dopo {days} giorni}}'**
  String podcastAutoDeleteAfter(int days);

  /// No description provided for @podcastUnsubscribe.
  ///
  /// In it, this message translates to:
  /// **'Annulla l’iscrizione'**
  String get podcastUnsubscribe;

  /// No description provided for @podcastUnsubscribeTitle.
  ///
  /// In it, this message translates to:
  /// **'Annullare l’iscrizione?'**
  String get podcastUnsubscribeTitle;

  /// No description provided for @podcastUnsubscribeBody.
  ///
  /// In it, this message translates to:
  /// **'Il podcast e {count, plural, one{1 episodio scaricato} other{{count} episodi scaricati}} verranno eliminati dal dispositivo.'**
  String podcastUnsubscribeBody(int count);

  /// No description provided for @podcastLastChecked.
  ///
  /// In it, this message translates to:
  /// **'Aggiornato {when}'**
  String podcastLastChecked(String when);

  /// No description provided for @podcastNeverChecked.
  ///
  /// In it, this message translates to:
  /// **'Mai aggiornato'**
  String get podcastNeverChecked;

  /// No description provided for @podcastErrInvalidUrl.
  ///
  /// In it, this message translates to:
  /// **'Questo non sembra un indirizzo web valido.'**
  String get podcastErrInvalidUrl;

  /// No description provided for @podcastErrTooLarge.
  ///
  /// In it, this message translates to:
  /// **'Il feed è troppo grande.'**
  String get podcastErrTooLarge;

  /// No description provided for @podcastErrNetwork.
  ///
  /// In it, this message translates to:
  /// **'Non riesco a raggiungere il server.'**
  String get podcastErrNetwork;

  /// No description provided for @podcastErrNotFeed.
  ///
  /// In it, this message translates to:
  /// **'Questo indirizzo non è un feed di podcast.'**
  String get podcastErrNotFeed;

  /// No description provided for @podcastErrParserMissing.
  ///
  /// In it, this message translates to:
  /// **'La lettura dei feed non è ancora disponibile in questa versione.'**
  String get podcastErrParserMissing;

  /// No description provided for @podcastErrUnsupportedFormat.
  ///
  /// In it, this message translates to:
  /// **'Formato audio non supportato.'**
  String get podcastErrUnsupportedFormat;

  /// No description provided for @syncTitle.
  ///
  /// In it, this message translates to:
  /// **'Sincronizza playlist'**
  String get syncTitle;

  /// No description provided for @syncAdded.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, one{1 nuova} other{{count} nuove}}'**
  String syncAdded(int count);

  /// No description provided for @syncUpdated.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, one{1 aggiornata} other{{count} aggiornate}}'**
  String syncUpdated(int count);

  /// No description provided for @syncMissing.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, one{1 brano mancante} other{{count} brani mancanti}}'**
  String syncMissing(int count);

  /// No description provided for @syncUpToDate.
  ///
  /// In it, this message translates to:
  /// **'Le playlist sono già allineate'**
  String get syncUpToDate;

  /// No description provided for @syncKept.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, one{1 playlist è più recente qui e resta com’è} other{{count} playlist sono più recenti qui e restano come sono}}'**
  String syncKept(int count);

  /// No description provided for @syncReplaceNote.
  ///
  /// In it, this message translates to:
  /// **'Le playlist aggiornate sostituiscono quelle di questo dispositivo.'**
  String get syncReplaceNote;

  /// No description provided for @syncTagNew.
  ///
  /// In it, this message translates to:
  /// **'Nuova'**
  String get syncTagNew;

  /// No description provided for @syncTagUpdated.
  ///
  /// In it, this message translates to:
  /// **'Aggiornata'**
  String get syncTagUpdated;

  /// No description provided for @syncDetailRenamed.
  ///
  /// In it, this message translates to:
  /// **'rinominata'**
  String get syncDetailRenamed;

  /// No description provided for @syncDetailReordered.
  ///
  /// In it, this message translates to:
  /// **'riordinata'**
  String get syncDetailReordered;

  /// No description provided for @syncDetailRemoved.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, one{1 brano tolto} other{{count} brani tolti}}'**
  String syncDetailRemoved(int count);

  /// No description provided for @syncAskMissing.
  ///
  /// In it, this message translates to:
  /// **'Chiedi i brani mancanti'**
  String get syncAskMissing;

  /// No description provided for @syncApplied.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, one{1 playlist sincronizzata} other{{count} playlist sincronizzate}}'**
  String syncApplied(int count);

  /// No description provided for @trustedSection.
  ///
  /// In it, this message translates to:
  /// **'Dispositivi fidati'**
  String get trustedSection;

  /// No description provided for @trustedFingerprint.
  ///
  /// In it, this message translates to:
  /// **'Impronta {fingerprint}'**
  String trustedFingerprint(String fingerprint);

  /// No description provided for @trustedPairedOn.
  ///
  /// In it, this message translates to:
  /// **'Abbinato il {date}'**
  String trustedPairedOn(String date);

  /// No description provided for @trustedAutoAccept.
  ///
  /// In it, this message translates to:
  /// **'Accetta automaticamente'**
  String get trustedAutoAccept;

  /// No description provided for @trustedAutoAcceptHint.
  ///
  /// In it, this message translates to:
  /// **'Ricevi i brani da questo dispositivo senza chiedere.'**
  String get trustedAutoAcceptHint;

  /// No description provided for @trustedRevoke.
  ///
  /// In it, this message translates to:
  /// **'Revoca'**
  String get trustedRevoke;

  /// No description provided for @trustedRevokeTitle.
  ///
  /// In it, this message translates to:
  /// **'Revocare «{name}»?'**
  String trustedRevokeTitle(String name);

  /// No description provided for @trustedRevokeBody.
  ///
  /// In it, this message translates to:
  /// **'Per inviare di nuovo senza PIN dovrete abbinarvi ancora.'**
  String get trustedRevokeBody;

  /// No description provided for @carMode.
  ///
  /// In it, this message translates to:
  /// **'Modalità in auto'**
  String get carMode;

  /// No description provided for @carExit.
  ///
  /// In it, this message translates to:
  /// **'Esci'**
  String get carExit;

  /// No description provided for @carKeepAwake.
  ///
  /// In it, this message translates to:
  /// **'Schermo sempre acceso'**
  String get carKeepAwake;

  /// No description provided for @carPlaylists.
  ///
  /// In it, this message translates to:
  /// **'Playlist'**
  String get carPlaylists;

  /// No description provided for @carNothing.
  ///
  /// In it, this message translates to:
  /// **'Niente in riproduzione'**
  String get carNothing;

  /// No description provided for @updateCheck.
  ///
  /// In it, this message translates to:
  /// **'Controlla aggiornamenti'**
  String get updateCheck;

  /// No description provided for @updateCheckHint.
  ///
  /// In it, this message translates to:
  /// **'Chiede a GitHub l’ultima versione, solo quando lo chiedi.'**
  String get updateCheckHint;

  /// No description provided for @updateOnStart.
  ///
  /// In it, this message translates to:
  /// **'Controlla all’avvio'**
  String get updateOnStart;

  /// No description provided for @updateOnStartHint.
  ///
  /// In it, this message translates to:
  /// **'Al più una volta al giorno. Non scarica né installa niente.'**
  String get updateOnStartHint;

  /// No description provided for @updateChecking.
  ///
  /// In it, this message translates to:
  /// **'Controllo in corso…'**
  String get updateChecking;

  /// No description provided for @updateAvailable.
  ///
  /// In it, this message translates to:
  /// **'Disponibile la versione {version}'**
  String updateAvailable(String version);

  /// No description provided for @updateUpToDate.
  ///
  /// In it, this message translates to:
  /// **'Hai l’ultima versione ({version})'**
  String updateUpToDate(String version);

  /// No description provided for @updateRateLimited.
  ///
  /// In it, this message translates to:
  /// **'GitHub chiede di aspettare: riprova più tardi.'**
  String get updateRateLimited;

  /// No description provided for @updateFailed.
  ///
  /// In it, this message translates to:
  /// **'Non riesco a leggere l’ultima versione. Controlla la connessione.'**
  String get updateFailed;

  /// No description provided for @updateCopyLink.
  ///
  /// In it, this message translates to:
  /// **'Copia indirizzo'**
  String get updateCopyLink;

  /// No description provided for @updateLinkCopied.
  ///
  /// In it, this message translates to:
  /// **'Indirizzo copiato'**
  String get updateLinkCopied;

  /// No description provided for @backupSection.
  ///
  /// In it, this message translates to:
  /// **'Backup'**
  String get backupSection;

  /// No description provided for @backupCreate.
  ///
  /// In it, this message translates to:
  /// **'Crea backup'**
  String get backupCreate;

  /// No description provided for @backupCreateHint.
  ///
  /// In it, this message translates to:
  /// **'Playlist, preferiti, testi e modifiche in un file zip. La musica non c’è.'**
  String get backupCreateHint;

  /// No description provided for @backupRestore.
  ///
  /// In it, this message translates to:
  /// **'Ripristina da backup'**
  String get backupRestore;

  /// No description provided for @backupRestoreHint.
  ///
  /// In it, this message translates to:
  /// **'Sostituisci questa libreria o unisci i dati di un altro dispositivo.'**
  String get backupRestoreHint;

  /// No description provided for @backupCreating.
  ///
  /// In it, this message translates to:
  /// **'Creo il backup…'**
  String get backupCreating;

  /// No description provided for @backupSaved.
  ///
  /// In it, this message translates to:
  /// **'Backup salvato'**
  String get backupSaved;

  /// No description provided for @backupFailed.
  ///
  /// In it, this message translates to:
  /// **'Backup non riuscito'**
  String get backupFailed;

  /// No description provided for @restoreTitle.
  ///
  /// In it, this message translates to:
  /// **'Ripristina da backup'**
  String get restoreTitle;

  /// No description provided for @restoreInfo.
  ///
  /// In it, this message translates to:
  /// **'Del {date} · app {version} · {tracks} brani · {playlists} playlist'**
  String restoreInfo(String date, String version, int tracks, int playlists);

  /// No description provided for @restoreReplace.
  ///
  /// In it, this message translates to:
  /// **'Sostituisci tutto (stesso dispositivo)'**
  String get restoreReplace;

  /// No description provided for @restoreMerge.
  ///
  /// In it, this message translates to:
  /// **'Unisci a questa libreria'**
  String get restoreMerge;

  /// No description provided for @restoreMergeHint.
  ///
  /// In it, this message translates to:
  /// **'Aggiunge preferiti, playlist, testi e modifiche ai brani che trova. Non cancella niente.'**
  String get restoreMergeHint;

  /// No description provided for @restoreReplaceConfirmTitle.
  ///
  /// In it, this message translates to:
  /// **'Sostituire tutta la libreria?'**
  String get restoreReplaceConfirmTitle;

  /// No description provided for @restoreReplaceConfirmBody.
  ///
  /// In it, this message translates to:
  /// **'Al prossimo avvio i dati di questa app diventano quelli del backup. Quelli attuali restano in una copia di sicurezza accanto al database.'**
  String get restoreReplaceConfirmBody;

  /// No description provided for @restoreReplaceGo.
  ///
  /// In it, this message translates to:
  /// **'Sostituisci'**
  String get restoreReplaceGo;

  /// No description provided for @restoreNotBackup.
  ///
  /// In it, this message translates to:
  /// **'Questo file non è un backup di Codecore che posso leggere.'**
  String get restoreNotBackup;

  /// No description provided for @restoreRestartNeeded.
  ///
  /// In it, this message translates to:
  /// **'Pronto: chiudi l’app e riaprila per completare il ripristino.'**
  String get restoreRestartNeeded;

  /// No description provided for @restoreMergeDone.
  ///
  /// In it, this message translates to:
  /// **'Unione fatta: {recognized} brani riconosciuti, {missing} non trovati, {playlists} playlist create, {favorites} preferiti aggiunti.'**
  String restoreMergeDone(
    int recognized,
    int missing,
    int playlists,
    int favorites,
  );

  /// No description provided for @restoreNotFound.
  ///
  /// In it, this message translates to:
  /// **'Brani non trovati'**
  String get restoreNotFound;

  /// No description provided for @restoreCopyList.
  ///
  /// In it, this message translates to:
  /// **'Copia elenco'**
  String get restoreCopyList;

  /// No description provided for @restoreFailed.
  ///
  /// In it, this message translates to:
  /// **'Ripristino non riuscito'**
  String get restoreFailed;

  /// No description provided for @exportAllPlaylists.
  ///
  /// In it, this message translates to:
  /// **'Esporta tutte le playlist'**
  String get exportAllPlaylists;

  /// No description provided for @shareErrIdentity.
  ///
  /// In it, this message translates to:
  /// **'L’identità di questo dispositivo è cambiata: toglilo dai fidati e abbinalo di nuovo.'**
  String get shareErrIdentity;

  /// No description provided for @incomingTrustedTag.
  ///
  /// In it, this message translates to:
  /// **'Dispositivo fidato'**
  String get incomingTrustedTag;

  /// No description provided for @incomingTrustedTitle.
  ///
  /// In it, this message translates to:
  /// **'{name} (fidato)'**
  String incomingTrustedTitle(String name);

  /// No description provided for @pairAction.
  ///
  /// In it, this message translates to:
  /// **'Abbina'**
  String get pairAction;

  /// No description provided for @trustedBadge.
  ///
  /// In it, this message translates to:
  /// **'Fidato'**
  String get trustedBadge;

  /// No description provided for @pairPinTitle.
  ///
  /// In it, this message translates to:
  /// **'Abbinamento con {name}'**
  String pairPinTitle(String name);

  /// No description provided for @pairPinHint.
  ///
  /// In it, this message translates to:
  /// **'Scrivi il PIN di 6 cifre mostrato su {name}.'**
  String pairPinHint(String name);

  /// No description provided for @pairPinWrong.
  ///
  /// In it, this message translates to:
  /// **'PIN sbagliato. Tentativi rimasti: {count}.'**
  String pairPinWrong(int count);

  /// No description provided for @pairFingerprint.
  ///
  /// In it, this message translates to:
  /// **'Impronta: {fingerprint}'**
  String pairFingerprint(String fingerprint);

  /// No description provided for @pairCompare.
  ///
  /// In it, this message translates to:
  /// **'Controlla che l’impronta sia la stessa sull’altro schermo.'**
  String get pairCompare;

  /// No description provided for @pairRequestTitle.
  ///
  /// In it, this message translates to:
  /// **'{name} vuole abbinarsi'**
  String pairRequestTitle(String name);

  /// No description provided for @pairRequestBody.
  ///
  /// In it, this message translates to:
  /// **'Scrivi questo PIN sull’altro dispositivo, poi tocca Conferma.'**
  String get pairRequestBody;

  /// No description provided for @pairConfirm.
  ///
  /// In it, this message translates to:
  /// **'Conferma'**
  String get pairConfirm;

  /// No description provided for @pairWaiting.
  ///
  /// In it, this message translates to:
  /// **'In attesa della conferma sull’altro dispositivo…'**
  String get pairWaiting;

  /// No description provided for @pairDone.
  ///
  /// In it, this message translates to:
  /// **'Abbinato con {name}'**
  String pairDone(String name);

  /// No description provided for @pairBlocked.
  ///
  /// In it, this message translates to:
  /// **'Troppi tentativi sbagliati: riprova più tardi.'**
  String get pairBlocked;

  /// No description provided for @pairRejected.
  ///
  /// In it, this message translates to:
  /// **'Abbinamento rifiutato.'**
  String get pairRejected;

  /// No description provided for @pairExpired.
  ///
  /// In it, this message translates to:
  /// **'Richiesta scaduta: riprova.'**
  String get pairExpired;

  /// No description provided for @pairFailed.
  ///
  /// In it, this message translates to:
  /// **'Abbinamento non riuscito.'**
  String get pairFailed;

  /// No description provided for @syncDevice.
  ///
  /// In it, this message translates to:
  /// **'Sincronizza playlist'**
  String get syncDevice;

  /// No description provided for @syncUnreachable.
  ///
  /// In it, this message translates to:
  /// **'Il dispositivo non è visibile sulla rete locale.'**
  String get syncUnreachable;

  /// No description provided for @syncFailed.
  ///
  /// In it, this message translates to:
  /// **'Sincronizzazione non riuscita.'**
  String get syncFailed;

  /// No description provided for @syncAsked.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, =0{Nessuno dei brani è sull’altro dispositivo} one{Richiesta inviata: 1 brano in arrivo} other{Richiesta inviata: {count} brani in arrivo}}'**
  String syncAsked(int count);

  /// No description provided for @translateLyrics.
  ///
  /// In it, this message translates to:
  /// **'Traduci'**
  String get translateLyrics;

  /// No description provided for @translateLyricsFrom.
  ///
  /// In it, this message translates to:
  /// **'Lingua del testo'**
  String get translateLyricsFrom;

  /// No description provided for @translateLyricsHint.
  ///
  /// In it, this message translates to:
  /// **'Traduzione sul telefono, nessun testo viene inviato in rete.'**
  String get translateLyricsHint;

  /// No description provided for @translateRemove.
  ///
  /// In it, this message translates to:
  /// **'Mostra solo l\'originale'**
  String get translateRemove;

  /// No description provided for @translateDownloadTitle.
  ///
  /// In it, this message translates to:
  /// **'Scaricare il modello {language}?'**
  String translateDownloadTitle(String language);

  /// No description provided for @translateDownloadBody.
  ///
  /// In it, this message translates to:
  /// **'Servono circa {mb} MB per ogni lingua, meglio con il Wi-Fi. Si scarica una volta sola e poi funziona anche offline.'**
  String translateDownloadBody(int mb);

  /// No description provided for @translateDownload.
  ///
  /// In it, this message translates to:
  /// **'Scarica'**
  String get translateDownload;

  /// No description provided for @translateDownloading.
  ///
  /// In it, this message translates to:
  /// **'Scarico il modello {language}…'**
  String translateDownloading(String language);

  /// No description provided for @translateDownloadFailed.
  ///
  /// In it, this message translates to:
  /// **'Modello non scaricato. Controlla la connessione e lo spazio.'**
  String get translateDownloadFailed;

  /// No description provided for @translateFailed.
  ///
  /// In it, this message translates to:
  /// **'Traduzione non riuscita.'**
  String get translateFailed;

  /// No description provided for @translateSameLanguage.
  ///
  /// In it, this message translates to:
  /// **'Il testo è già in questa lingua.'**
  String get translateSameLanguage;

  /// No description provided for @translationModels.
  ///
  /// In it, this message translates to:
  /// **'Modelli di traduzione'**
  String get translationModels;

  /// No description provided for @translationModelsNone.
  ///
  /// In it, this message translates to:
  /// **'Nessun modello scaricato. Si scaricano dalla schermata dei testi, con «Traduci».'**
  String get translationModelsNone;

  /// No description provided for @translationModelDelete.
  ///
  /// In it, this message translates to:
  /// **'Elimina il modello {language}'**
  String translationModelDelete(String language);

  /// No description provided for @scanCode.
  ///
  /// In it, this message translates to:
  /// **'Scansiona codice'**
  String get scanCode;

  /// No description provided for @scanTitle.
  ///
  /// In it, this message translates to:
  /// **'Inquadra il codice QR'**
  String get scanTitle;

  /// No description provided for @scanNotCodecore.
  ///
  /// In it, this message translates to:
  /// **'Questo codice non è di Codecore.'**
  String get scanNotCodecore;

  /// No description provided for @scanCameraDenied.
  ///
  /// In it, this message translates to:
  /// **'Serve il permesso della fotocamera per leggere il codice.'**
  String get scanCameraDenied;

  /// No description provided for @scanOpenSettings.
  ///
  /// In it, this message translates to:
  /// **'Apri impostazioni'**
  String get scanOpenSettings;

  /// No description provided for @ownFingerprint.
  ///
  /// In it, this message translates to:
  /// **'Impronta di questo dispositivo'**
  String get ownFingerprint;

  /// No description provided for @ownFingerprintHint.
  ///
  /// In it, this message translates to:
  /// **'Si confronta con quella mostrata sull’altro schermo quando ci si abbina.'**
  String get ownFingerprintHint;

  /// No description provided for @writeTagsToFiles.
  ///
  /// In it, this message translates to:
  /// **'Scrivi le modifiche nei file'**
  String get writeTagsToFiles;

  /// No description provided for @writeTagsToFilesHint.
  ///
  /// In it, this message translates to:
  /// **'Titolo, artista, album, anno, genere e traccia modificati qui vengono scritti anche in MP3, FLAC, M4A e OGG. Di ogni file si conserva l’originale. Spenta di default.'**
  String get writeTagsToFilesHint;

  /// No description provided for @writeTagsWarnTitle.
  ///
  /// In it, this message translates to:
  /// **'Scrivere le modifiche nei file?'**
  String get writeTagsWarnTitle;

  /// No description provided for @writeTagsWarnBody.
  ///
  /// In it, this message translates to:
  /// **'Salvando una modifica, i tag vengono riscritti anche nel file musicale (MP3, FLAC, M4A, OGG). Si lavora su una copia, si controlla il risultato e il file viene sostituito solo se tutto torna; prima l’originale è salvato in «Backup dei tag» (gli ultimi 200 o 2 GB). Copertina, testi e ReplayGain non vengono toccati. Prima di attivare conviene fare un backup della libreria (Impostazioni → Backup).'**
  String get writeTagsWarnBody;

  /// No description provided for @writeTagsEnable.
  ///
  /// In it, this message translates to:
  /// **'Attiva'**
  String get writeTagsEnable;

  /// No description provided for @tagsAlsoInFile.
  ///
  /// In it, this message translates to:
  /// **'Scrivi anche nel file'**
  String get tagsAlsoInFile;

  /// No description provided for @tagsNoWriteUnsupported.
  ///
  /// In it, this message translates to:
  /// **'Formato non modificabile ({format}): cambia solo la libreria'**
  String tagsNoWriteUnsupported(String format);

  /// No description provided for @tagsNoWriteReadOnly.
  ///
  /// In it, this message translates to:
  /// **'File in sola lettura: cambia solo la libreria'**
  String get tagsNoWriteReadOnly;

  /// No description provided for @tagsNoWriteMissing.
  ///
  /// In it, this message translates to:
  /// **'File non trovato: cambia solo la libreria'**
  String get tagsNoWriteMissing;

  /// No description provided for @tagsFileWriteFailed.
  ///
  /// In it, this message translates to:
  /// **'Salvato nella libreria, ma {count, plural, one{1 file non è stato modificato} other{{count} file non sono stati modificati}}: {reason}'**
  String tagsFileWriteFailed(int count, String reason);

  /// No description provided for @tagReasonUnsupported.
  ///
  /// In it, this message translates to:
  /// **'formato non supportato'**
  String get tagReasonUnsupported;

  /// No description provided for @tagReasonNotFound.
  ///
  /// In it, this message translates to:
  /// **'file non trovato'**
  String get tagReasonNotFound;

  /// No description provided for @tagReasonReadOnly.
  ///
  /// In it, this message translates to:
  /// **'file in sola lettura'**
  String get tagReasonReadOnly;

  /// No description provided for @tagReasonVerifyFailed.
  ///
  /// In it, this message translates to:
  /// **'il controllo dopo la scrittura è fallito, il file è rimasto com’era'**
  String get tagReasonVerifyFailed;

  /// No description provided for @tagReasonWriteFailed.
  ///
  /// In it, this message translates to:
  /// **'scrittura non riuscita, il file è rimasto com’era'**
  String get tagReasonWriteFailed;

  /// No description provided for @tagReasonBackupFailed.
  ///
  /// In it, this message translates to:
  /// **'backup dell’originale non riuscito, il file è rimasto com’era'**
  String get tagReasonBackupFailed;

  /// No description provided for @tagReasonIoError.
  ///
  /// In it, this message translates to:
  /// **'errore del disco o dei permessi'**
  String get tagReasonIoError;

  /// No description provided for @tagBackupsTitle.
  ///
  /// In it, this message translates to:
  /// **'Backup dei tag'**
  String get tagBackupsTitle;

  /// No description provided for @tagBackupsCount.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, =0{Backup dei tag} one{Backup dei tag (1)} other{Backup dei tag ({count})}}'**
  String tagBackupsCount(int count);

  /// No description provided for @tagBackupsHint.
  ///
  /// In it, this message translates to:
  /// **'L’originale di ogni file riscritto, prima della modifica. Si tengono gli ultimi 200 o 2 GB.'**
  String get tagBackupsHint;

  /// No description provided for @tagBackupsEmpty.
  ///
  /// In it, this message translates to:
  /// **'Nessun backup: i file non sono ancora stati riscritti.'**
  String get tagBackupsEmpty;

  /// No description provided for @tagBackupRestore.
  ///
  /// In it, this message translates to:
  /// **'Ripristina originale'**
  String get tagBackupRestore;

  /// No description provided for @tagBackupRestoreBody.
  ///
  /// In it, this message translates to:
  /// **'Il file «{name}» torna com’era prima della modifica. La libreria tiene le modifiche fatte nell’app.'**
  String tagBackupRestoreBody(String name);

  /// No description provided for @tagBackupRestored.
  ///
  /// In it, this message translates to:
  /// **'Originale ripristinato'**
  String get tagBackupRestored;

  /// No description provided for @tagBackupRestoreFailed.
  ///
  /// In it, this message translates to:
  /// **'Ripristino non riuscito: {reason}'**
  String tagBackupRestoreFailed(String reason);

  /// No description provided for @tagBackupDelete.
  ///
  /// In it, this message translates to:
  /// **'Elimina backup'**
  String get tagBackupDelete;

  /// No description provided for @tagBackupDeleteBody.
  ///
  /// In it, this message translates to:
  /// **'Non potrai più riportare il file a com’era prima della modifica.'**
  String get tagBackupDeleteBody;

  /// No description provided for @tagBackupDeleted.
  ///
  /// In it, this message translates to:
  /// **'Backup eliminato'**
  String get tagBackupDeleted;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'it',
    'pt',
  ].contains(locale.languageCode);

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
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
