import 'package:cloud_firestore/cloud_firestore.dart';

class Place {
  final String id;
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

  /// Méthode utilitaire pour convertir proprement n'importe quel type en double
  static double _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Méthode utilitaire pour convertir proprement un Timestamp / String / int en DateTime
  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return DateTime.now();
  }

  factory Place.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return Place(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String?,
      imageUrl: data['imageUrl'] as String? ?? '',
      latitude: _parseDouble(data['latitude']),
      longitude: _parseDouble(data['longitude']),
      arrivalDate: _parseDate(data['arrivalDate']),
      departureDate: _parseDate(data['departureDate']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      if (description != null) 'description': description,
      'imageUrl': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'arrivalDate': Timestamp.fromDate(arrivalDate),
      'departureDate': Timestamp.fromDate(departureDate),
    };
  }
}