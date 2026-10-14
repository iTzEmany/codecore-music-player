/// Temporary Italian strings until ARB localisation (phase 4).
class S {
  S._();

  static const appName = 'Codecore';
  static const chooseFolder = 'Scegli cartella';
  static const scan = 'Scansiona';
  static const noTracks = 'Nessun brano. Scegli una cartella e scansiona.';
  static const openSettings = 'Apri impostazioni';
  static const permissionDenied = 'Permesso di lettura audio negato';

  static const library = 'Libreria';
  static const favorites = 'Preferiti';
  static const playlists = 'Playlist';
  static const settings = 'Impostazioni';
  static const tracks = 'Brani';
  static const albums = 'Album';
  static const artists = 'Artisti';
  static const search = 'Cerca';
  static const sortBy = 'Ordina per';
  static const addMusicFolder = 'Aggiungi la tua cartella musicale';
  static const addFolder = 'Aggiungi cartella';
  static const folders = 'Cartelle musicali';
  static const refreshLibrary = 'Aggiorna libreria';
  static const removeFolder = 'Rimuovi cartella';
  static const unknownArtist = 'Artista sconosciuto';
  static const unknownAlbum = 'Album sconosciuto';
  static const variousArtists = 'Artisti vari';
  static const play = 'Riproduci';
  static const shuffle = 'Casuale';
  static const queue = 'Coda';
  static const nowPlaying = 'In riproduzione';
  static const nothingPlaying = 'Nessun brano in riproduzione';
  static const mute = 'Muto';
  static const scanning = 'Scansione in corso…';
  static const emptyQueue = 'La coda è vuota';
  static const noResults = 'Nessun risultato';

  static const sortDefault = 'Predefinito';
  static const sortTitle = 'Titolo';
  static const sortArtist = 'Artista';
  static const sortAlbum = 'Album';
  static const sortYear = 'Anno';
  static const sortAdded = 'Aggiunti di recente';
  static const sortDuration = 'Durata';

  static String tracksCount(int n) => n == 1 ? '1 brano' : '$n brani';
  static String albumsCount(int n) => n == 1 ? '1 album' : '$n album';
}
