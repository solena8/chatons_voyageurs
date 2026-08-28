import 'package:flutter_test/flutter_test.dart';
import 'package:travel_map_app/models/place.dart';

void main() {
  group('Place Model Tests', () {
    test('Initialisation correcte des propriétés', () {
      final now = DateTime.now();
      final place = Place(
        id: '123',
        title: 'Tokyo',
        description: 'Super voyage',
        imageUrl: 'https://example.com/image.jpg',
        latitude: 35.6762,
        longitude: 139.6503,
        arrivalDate: now,
        departureDate: now,
      );

      expect(place.id, '123');
      expect(place.title, 'Tokyo');
      expect(place.latitude, 35.6762);
      expect(place.arrivalDate, now);
    });

    test('toFirestore génère un Map valide', () {
      final arrival = DateTime(2026, 6, 1);
      final departure = DateTime(2026, 6, 10);
      final place = Place(
        id: '456',
        title: 'Madrid',
        imageUrl: '',
        latitude: 40.4168,
        longitude: -3.7038,
        arrivalDate: arrival,
        departureDate: departure,
      );

      final map = place.toFirestore();

      expect(map['title'], 'Madrid');
      expect(map['latitude'], 40.4168);
      expect(map['description'], isNull);
    });
  });
}