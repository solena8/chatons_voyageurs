import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a travel location data model used across the app and stored in Firestore.
class Place {
  final String id;                  // Unique identifier corresponding to the Firestore Document ID
  final String title;
  final String? description;
  final String imageUrl;
  final double latitude;
  final double longitude;
  final DateTime arrivalDate;
  final DateTime departureDate;

  Place({
    required this.id,
    required this.title,
    this.description,
    required this.imageUrl,
    required this.latitude,
    required this.longitude,
    required this.arrivalDate,
    required this.departureDate,
  });

  /// Factory constructor to convert a Firestore DocumentSnapshot into a strongly-typed Place object.
  factory Place.fromFirestore(DocumentSnapshot doc) {
    // Casts raw document data into a key-value Map
    final data = doc.data() as Map<String, dynamic>;
    // String = type de la clé, dynamic : type de la valeur, peut être variable
    // .data : méthode de la classe DocumentSnapshot de cloud firestore
    // Map est un type : dictionnaire

    return Place(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'],
      imageUrl: data['imageUrl'] ?? '',
      // Explicit cast from num to double handles both int and double values stored in Firestore
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
      // Converts Firestore Timestamp instances into Dart DateTime objects
      arrivalDate: (data['arrivalDate'] as Timestamp).toDate(),
      departureDate: (data['departureDate'] as Timestamp).toDate(),
    );
  }

  /// Converts the Place instance fields into a Map suitable for saving to Cloud Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      // Converts Dart DateTime objects back to Firestore Timestamp objects
      'arrivalDate': Timestamp.fromDate(arrivalDate),
      'departureDate': Timestamp.fromDate(departureDate),
    };
  }
}