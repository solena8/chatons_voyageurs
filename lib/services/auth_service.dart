import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static User? get currentUser => _auth.currentUser;

  /// Écoute la session et écrit immédiatement dans /users si l'utilisateur est connecté
  static Stream<User?> get authStateChanges => _auth.authStateChanges().asyncMap((user) async {
    if (user != null) {
      await syncUserProfile(user);
    }
    return user;
  });

  /// Enregistre ou met à jour le document de l'utilisateur dans /users
  static Future<void> syncUserProfile(User user) async {
    try {
      final userRef = _firestore.collection('users').doc(user.uid);
      await userRef.set({
        'email': (user.email ?? '').toLowerCase(),
        'displayName': user.displayName ?? user.email?.split('@').first ?? 'Voyageur',
        'photoUrl': user.photoURL,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Erreur synchronisation user: $e');
    }
  }

  /// Inscription Email/Mot de passe
  static Future<UserCredential> signUp(String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    if (cred.user != null) await syncUserProfile(cred.user!);
    return cred;
  }

  /// Connexion Email/Mot de passe
  static Future<UserCredential> signIn(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    if (cred.user != null) await syncUserProfile(cred.user!);
    return cred;
  }

  /// Connexion Google
  static Future<UserCredential?> signInWithGoogle() async {
    final googleProvider = GoogleAuthProvider();
    UserCredential cred;
    if (kIsWeb) {
      cred = await _auth.signInWithPopup(googleProvider);
    } else {
      cred = await _auth.signInWithProvider(googleProvider);
    }
    if (cred.user != null) await syncUserProfile(cred.user!);
    return cred;
  }

  /// Déconnexion
  static Future<void> signOut() => _auth.signOut();

  /// Invitation par Email
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