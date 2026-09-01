import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

class AddressSuggestion {
  final String displayName;
  final LatLng location;

  AddressSuggestion({required this.displayName, required this.location});

  @override
  String toString() => displayName;
}

class ApiService {
  static const String uploadcarePublicKey = String.fromEnvironment(
    'UPLOADCARE_KEY',
  );

  static Future<String?> uploadToUploadcare(XFile file) async {
    try {
      final uri = Uri.parse('https://upload.uploadcare.com/base/');
      final bytes = await file.readAsBytes();

      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: file.name.isNotEmpty ? file.name : 'upload.jpg',
      );

      final request = http.MultipartRequest('POST', uri)
        ..fields['UPLOADCARE_PUB_KEY'] = uploadcarePublicKey
        ..fields['UPLOADCARE_STORE'] = '1'
        ..files.add(multipartFile);

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final json = jsonDecode(responseData);
        final fileId = json['file'];
        return 'https://4tzndtpq5a.ucarecd.net/$fileId/-/preview/';
      } else {
        debugPrint('Erreur Uploadcare (${response.statusCode}) : $responseData');
      }
    } catch (e) {
      debugPrint('Exception upload : $e');
    }
    return null;
  }

  static Future<List<AddressSuggestion>> searchAddressSuggestions(String query) async {
    if (query.trim().isEmpty) return [];

    final url = Uri.parse(
      'https://photon.komoot.io/api/?q=${Uri.encodeComponent(query)}&limit=5',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final List features = data['features'] ?? [];

        return features.map((item) {
          final properties = item['properties'] as Map<String, dynamic>;
          final geometry = item['geometry'] as Map<String, dynamic>;
          final List coordinates = geometry['coordinates'];

          final lon = (coordinates[0] as num).toDouble();
          final lat = (coordinates[1] as num).toDouble();

          final parts = [
            properties['name'],
            properties['street'],
            properties['city'] ?? properties['town'] ?? properties['village'],
            properties['country'],
          ].where((part) => part != null && part.toString().isNotEmpty).toList();

          final displayName = parts.join(', ');

          return AddressSuggestion(
            displayName: displayName.isNotEmpty ? displayName : 'Lieu sans nom',
            location: LatLng(lat, lon),
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('Erreur Photon API : $e');
    }
    return [];
  }
}