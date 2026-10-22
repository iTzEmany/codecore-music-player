import 'package:codecore/services/radio/country_names.dart';
import 'package:codecore/services/radio/radio_station.dart';
import 'package:codecore/ui/screens/radio/radio_labels.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the country name follows the app language, else the English one', () {
    expect(countryNameIn('IT', 'it', 'Italy'), 'Italia');
    expect(countryNameIn('it', 'de', 'Italy'), 'Italien');
    expect(countryNameIn('ZZ', 'it', 'Zedland'), 'Zedland');
    expect(countryNameIn('IT', 'ja', 'Italy'), 'Italy');
  });

  test('an UNKNOWN codec is not shown', () {
    const s = RadioStation(id: 'a', name: 'A', streamUrl: 'http://a', codec: 'UNKNOWN', bitrate: 128);
    expect(radioQualityLine(s), '128 kbps');
  });
}
