import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TripMap {
  final String id;
  final String title;
  final String ownerId;
  final List<String> members;
  final Color color;

  TripMap({
    required this.id,
    required this.title,
    required this.ownerId,
    required this.members,
    required this.color,
  });

  factory TripMap.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final colorHex = data['colorHex'] as String? ?? '0xFFE53935';
    return TripMap(
      id: doc.id,
      title: data['title'] as String? ?? 'Sans titre',
      ownerId: data['ownerId'] as String? ?? '',
      members: List<String>.from(data['members'] ?? []),
      color: Color(int.tryParse(colorHex) ?? 0xFFE53935),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'ownerId': ownerId,
      'members': members,
      'colorHex': '0x${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}',
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}