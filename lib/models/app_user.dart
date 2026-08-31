import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;

  AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AppUser(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? 'Voyageur',
      photoUrl: data['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email.toLowerCase(),
      'displayName': displayName,
      'photoUrl': photoUrl,
      'lastSeen': FieldValue.serverTimestamp(),
    };
  }
}