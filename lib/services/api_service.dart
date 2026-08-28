import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

/// Helper service for handling image uploads and geocoding API calls.
class ApiService {
  // Public API key for Uploadcare CDN service
  static const String uploadcarePublicKey = '6023ddaf3007d05dbceb';

  /// Uploads an image file to Uploadcare CDN.
  /// Works across both Mobile and Web platforms by reading file data as raw bytes.
  static Future<String?> uploadToUploadcare(XFile file) async {
    try {
      final uri = Uri.parse('https://upload.uploadcare.com/base/');
      // Read raw binary bytes to avoid filesystem path incompatibilities on the web
      final bytes = await file.readAsBytes();

      // Prepare multipart file upload payload
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: file.name.isNotEmpty ? file.name : 'upload.jpg',
      );

      // Build POST multipart request
      final request = http.MultipartRequest('POST', uri)
        ..fields['UPLOADCARE_PUB_KEY'] = uploadcarePublicKey
        ..fields['UPLOADCARE_STORE'] = '1' // Ensures the uploaded file is permanently stored
        ..files.add(multipartFile);

      // Execute request and read string response
      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final json = jsonDecode(responseData);
        final fileId = json['file'];
        // Return standard CDN preview URL using the returned UUID
        return 'https://4tzndtpq5a.ucarecd.net/$fileId/-/preview/';
      } else {
        debugPrint('Erreur Uploadcare (${response.statusCode}) : $responseData');
      }
    } catch (e) {
      debugPrint('Exception upload : $e');
    }
    return null;
  }

  /// Geocodes a text address or city name to GPS coordinates (LatLng) using OpenStreetMap Nominatim API.
  static Future<LatLng?> searchAddress(String query) async {
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=1',
    );

    // Custom User-Agent header is strictly required by Nominatim's Fair Use policy
    final response = await http.get(url, headers: {
      'User-Agent': 'FlutterTravelMapApp/1.0',
    });

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      if (data.isNotEmpty) {
        // Parse latitude and longitude strings from the first result
        final lat = double.parse(data[0]['lat']);
        final lon = double.parse(data[0]['lon']);
        return LatLng(lat, lon);
      }
    }
    return null;
  }
}