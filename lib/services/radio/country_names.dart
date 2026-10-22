/// Names of the countries most used for radio, in the app's languages
/// (it, en, de, es, fr, pt). Radio Browser only answers in English.
/// shortcut: a short table, not all countries; others keep the English name.
const _names = <String, List<String>>{
  'IT': ['Italia', 'Italy', 'Italien', 'Italia', 'Italie', 'Itália'],
  'GB': ['Regno Unito', 'United Kingdom', 'Vereinigtes Königreich', 'Reino Unido', 'Royaume-Uni', 'Reino Unido'],
  'US': ['Stati Uniti', 'United States', 'Vereinigte Staaten', 'Estados Unidos', 'États-Unis', 'Estados Unidos'],
  'DE': ['Germania', 'Germany', 'Deutschland', 'Alemania', 'Allemagne', 'Alemanha'],
  'FR': ['Francia', 'France', 'Frankreich', 'Francia', 'France', 'França'],
  'ES': ['Spagna', 'Spain', 'Spanien', 'España', 'Espagne', 'Espanha'],
  'PT': ['Portogallo', 'Portugal', 'Portugal', 'Portugal', 'Portugal', 'Portugal'],
  'BR': ['Brasile', 'Brazil', 'Brasilien', 'Brasil', 'Brésil', 'Brasil'],
  'CH': ['Svizzera', 'Switzerland', 'Schweiz', 'Suiza', 'Suisse', 'Suíça'],
  'AT': ['Austria', 'Austria', 'Österreich', 'Austria', 'Autriche', 'Áustria'],
  'NL': ['Paesi Bassi', 'Netherlands', 'Niederlande', 'Países Bajos', 'Pays-Bas', 'Países Baixos'],
  'BE': ['Belgio', 'Belgium', 'Belgien', 'Bélgica', 'Belgique', 'Bélgica'],
  'IE': ['Irlanda', 'Ireland', 'Irland', 'Irlanda', 'Irlande', 'Irlanda'],
  'CA': ['Canada', 'Canada', 'Kanada', 'Canadá', 'Canada', 'Canadá'],
  'AU': ['Australia', 'Australia', 'Australien', 'Australia', 'Australie', 'Austrália'],
  'MX': ['Messico', 'Mexico', 'Mexiko', 'México', 'Mexique', 'México'],
  'AR': ['Argentina', 'Argentina', 'Argentinien', 'Argentina', 'Argentine', 'Argentina'],
  'SE': ['Svezia', 'Sweden', 'Schweden', 'Suecia', 'Suède', 'Suécia'],
  'PL': ['Polonia', 'Poland', 'Polen', 'Polonia', 'Pologne', 'Polónia'],
  'JP': ['Giappone', 'Japan', 'Japan', 'Japón', 'Japon', 'Japão'],
};

const _langs = ['it', 'en', 'de', 'es', 'fr', 'pt'];

/// The name of [code] in [lang], or [fallback] when the table lacks it.
String countryNameIn(String code, String lang, String fallback) {
  final i = _langs.indexOf(lang);
  return i < 0 ? fallback : _names[code.toUpperCase()]?[i] ?? fallback;
}
