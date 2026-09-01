import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import '../models/place.dart';
import '../models/trip_map.dart';

class PlaceService {
  static final _firestore = FirebaseFirestore.instance;

  /// Écoute réactive de tous les lieux appartenant aux cartes cochées
  static Stream<List<Place>> getVisiblePlaces(List<TripMap> maps, Set<String> visibleIds) {
    final activeMaps = maps.where((m) => visibleIds.contains(m.id)).toList();
    if (activeMaps.isEmpty) return Stream.value([]);

    final streams = activeMaps.map((map) {
      return _firestore
          .collection('maps')
          .doc(map.id)
          .collection('places')
          .snapshots()
          .map((snap) => snap.docs.map((d) => Place.fromFirestore(d, mapId: map.id)).toList());
    });

    return CombineLatestStream.list<List<Place>>(streams)
        .map((lists) => lists.expand((x) => x).toList());
  }

  /// Ajoute un nouveau lieu dans une carte
  static Future<void> addPlace(String mapId, Place place) {
    return _firestore
        .collection('maps')
        .doc(mapId)
        .collection('places')
        .add(place.toFirestore());
  }

  /// Met à jour un lieu existant
  static Future<void> updatePlace(String mapId, Place place) {
    return _firestore
        .collection('maps')
        .doc(mapId)
        .collection('places')
        .doc(place.id)
        .update(place.toFirestore());
  }

  /// Supprime un lieu
  static Future<void> deletePlace(String mapId, String placeId) {
    return _firestore
        .collection('maps')
        .doc(mapId)
        .collection('places')
        .doc(placeId)
        .delete();
  }
}