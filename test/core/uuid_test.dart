import 'package:codecore/core/uuid.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final v4 = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');

  test('the shape of a version 4 UUID', () {
    for (var i = 0; i < 200; i++) {
      expect(newUuid(), matches(v4));
    }
  });

  test('a thousand of them are all different', () {
    expect({for (var i = 0; i < 1000; i++) newUuid()}, hasLength(1000));
  });
}
