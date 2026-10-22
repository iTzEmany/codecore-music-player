import 'radio_browser_client.dart' show RadioState;

/// A region the user can pick for «Vicino a te». Stations type their `state`
/// by hand («Lombardy», «Milano (MI)», «Emilia Romagna»), so a region matches
/// by any of its [names] or [cities] (the provincial capitals).
class RadioRegion {
  const RadioRegion({required this.id, required this.names, this.cities = const []});

  /// Stored in the settings. Italy: a fixed slug; elsewhere the state's name.
  final String id;

  /// First one is the label shown to the user.
  final List<String> names;
  final List<String> cities;

  String get label => names.first;
}

const kItalyCode = 'IT';

/// A foreign country's region: whatever the stations call it.
RadioRegion foreignRegion(String name) => RadioRegion(id: name, names: [name]);

/// The regions to offer for [countryCode]: our table for Italy, the states the
/// API lists (with at least [minStations] stations) for any other country.
List<RadioRegion> regionsFor(String countryCode, List<RadioState> states,
    {int minStations = 3}) {
  if (countryCode.toUpperCase() == kItalyCode) return kItalianRegions;
  return [
    for (final s in states)
      if (s.stationCount >= minStations) foreignRegion(s.name),
  ];
}

/// The region saved as [id] for [countryCode], or null if it is unknown.
RadioRegion? regionById(String countryCode, String id) {
  if (id.isEmpty) return null;
  if (countryCode.toUpperCase() != kItalyCode) return foreignRegion(id);
  for (final r in kItalianRegions) {
    if (r.id == id) return r;
  }
  return null;
}

const kItalianRegions = <RadioRegion>[
  RadioRegion(id: 'abruzzo', names: ['Abruzzo'], cities: ["L'Aquila", 'Teramo', 'Pescara', 'Chieti']),
  RadioRegion(id: 'basilicata', names: ['Basilicata'], cities: ['Potenza', 'Matera']),
  RadioRegion(id: 'calabria', names: ['Calabria'], cities: [
    'Catanzaro', 'Cosenza', 'Reggio Calabria', 'Crotone', 'Vibo Valentia',
  ]),
  RadioRegion(id: 'campania', names: ['Campania'], cities: [
    'Napoli', 'Naples', 'Salerno', 'Caserta', 'Avellino', 'Benevento',
  ]),
  RadioRegion(id: 'emilia-romagna', names: ['Emilia-Romagna', 'Emilia Romagna'], cities: [
    'Bologna', 'Modena', 'Parma', 'Reggio Emilia', 'Piacenza', 'Ferrara', 'Ravenna',
    'Forlì', 'Cesena', 'Rimini',
  ]),
  RadioRegion(
      id: 'friuli-venezia-giulia',
      names: ['Friuli-Venezia Giulia', 'Friuli Venezia Giulia', 'Friuli'],
      cities: ['Trieste', 'Udine', 'Gorizia', 'Pordenone']),
  RadioRegion(id: 'lazio', names: ['Lazio'], cities: [
    'Roma', 'Rome', 'Latina', 'Frosinone', 'Viterbo', 'Rieti',
  ]),
  RadioRegion(id: 'liguria', names: ['Liguria'], cities: [
    'Genova', 'Genoa', 'Imperia', 'Savona', 'La Spezia',
  ]),
  RadioRegion(id: 'lombardia', names: ['Lombardia', 'Lombardy'], cities: [
    'Milano', 'Milan', 'Bergamo', 'Brescia', 'Como', 'Cremona', 'Lecco', 'Lodi',
    'Mantova', 'Pavia', 'Sondrio', 'Varese', 'Monza',
  ]),
  RadioRegion(id: 'marche', names: ['Marche'], cities: [
    'Ancona', 'Pesaro', 'Urbino', 'Macerata', 'Fermo', 'Ascoli Piceno',
  ]),
  RadioRegion(id: 'molise', names: ['Molise'], cities: ['Campobasso', 'Isernia']),
  RadioRegion(id: 'piemonte', names: ['Piemonte', 'Piedmont'], cities: [
    'Torino', 'Turin', 'Vercelli', 'Novara', 'Cuneo', 'Asti', 'Alessandria', 'Biella',
    'Verbania',
  ]),
  RadioRegion(id: 'puglia', names: ['Puglia', 'Apulia'], cities: [
    'Bari', 'Taranto', 'Brindisi', 'Lecce', 'Foggia', 'Andria', 'Barletta', 'Trani',
  ]),
  RadioRegion(id: 'sardegna', names: ['Sardegna', 'Sardinia'], cities: [
    'Cagliari', 'Sassari', 'Nuoro', 'Oristano', 'Carbonia',
  ]),
  RadioRegion(id: 'sicilia', names: ['Sicilia', 'Sicily'], cities: [
    'Palermo', 'Catania', 'Messina', 'Agrigento', 'Caltanissetta', 'Enna', 'Ragusa',
    'Siracusa', 'Trapani',
  ]),
  RadioRegion(id: 'toscana', names: ['Toscana', 'Tuscany'], cities: [
    'Firenze', 'Florence', 'Pisa', 'Siena', 'Arezzo', 'Livorno', 'Lucca', 'Grosseto',
    'Massa', 'Carrara', 'Pistoia', 'Prato',
  ]),
  RadioRegion(
      id: 'trentino-alto-adige',
      names: [
        'Trentino-Alto Adige/Südtirol', 'Trentino-Alto Adige', 'Trentino', 'Alto Adige',
        'Südtirol', 'South Tyrol',
      ],
      cities: ['Trento', 'Bolzano', 'Bozen']),
  RadioRegion(id: 'umbria', names: ['Umbria'], cities: ['Perugia', 'Terni']),
  RadioRegion(
      id: 'valle-d-aosta',
      names: ["Valle d'Aosta", 'Aosta Valley', "Vallée d'Aoste"],
      cities: ['Aosta']),
  RadioRegion(id: 'veneto', names: ['Veneto'], cities: [
    'Venezia', 'Venice', 'Verona', 'Vicenza', 'Padova', 'Treviso', 'Belluno', 'Rovigo',
  ]),
];
