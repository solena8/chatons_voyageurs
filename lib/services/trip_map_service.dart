import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip_map.dart';

class TripMapService {
  static final _firestore = FirebaseFirestore.instance;

  /// Écoute en direct les cartes dont l'utilisateur est membre
  static Stream<List<TripMap>> getUserMapsStream(String? uid) {
    if (uid == null) return Stream.value([]);
    return _firestore
        .collection('maps')
        .where('members', arrayContains: uid)
        .snapshots()
        .map((snap) => snap.docs.map((d) => TripMap.fromFirestore(d)).toList());
  }

  /// Crée une carte et renvoie son ID généré
  static Future<String> createMap(TripMap map) async {
    final docRef = await _firestore.collection('maps').add(map.toFirestore());
    return docRef.id;
  }

  /// Associe un utilisateur existant via son adresse email
  static Future<bool> inviteUserByEmail(String mapId, String email) async {
    final cleanEmail = email.trim().toLowerCase();
    final query = await _firestore
        .collection('users')
        .where('email', isEqualTo: cleanEmail)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return false;

    final targetUid = query.docs.first.id;
    await _firestore.collection('maps').doc(mapId).update({
      'members': FieldValue.arrayUnion([targetUid]),
    });
    return true;
  }
}