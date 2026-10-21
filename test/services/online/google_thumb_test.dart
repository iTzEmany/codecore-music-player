import 'package:codecore/services/online/google_thumb.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('googleThumbAt rounds up to the next step and keeps the rest of the address', () {
    const base = 'https://lh3.googleusercontent.com/abc';
    expect(googleThumbAt('$base=w60-h60-p-l90-rj', 100), '$base=w120-h120-p-l90-rj');
    expect(googleThumbAt('$base=w120-h120-p-l90-rj', 121), '$base=w226-h226-p-l90-rj');
    expect(googleThumbAt('$base=w120-h120-p-l90-rj', 300), '$base=w320-h320-p-l90-rj');
    expect(googleThumbAt('$base=w120-h120-p-l90-rj', 9000), '$base=w544-h544-p-l90-rj');
  });

  test('googleThumbAt leaves other addresses alone', () {
    const video = 'https://i.ytimg.com/vi/abc/mqdefault.jpg';
    expect(googleThumbAt(video, 544), video);
    const noSize = 'https://yt3.googleusercontent.com/abc';
    expect(googleThumbAt(noSize, 544), noSize);
  });
}
