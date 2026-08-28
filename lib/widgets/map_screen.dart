import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/place.dart';
import 'add_edit_place_dialog.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Le contrôleur permet de manipuler le zoom et le centrage de la carte par code
  final MapController _mapController = MapController();

  // Référence vers la collection Firestore 'places'
  final CollectionReference _placesRef =
  FirebaseFirestore.instance.collection('places');

  /// Calcule un cadrage (bounding box) englobant tous les marqueurs
  void _fitBounds(List<Place> places) {
    if (places.isEmpty) return;

    final points = places.map((p) => LatLng(p.latitude, p.longitude)).toList();
    final bounds = LatLngBounds.fromPoints(points);

    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
    );
  }

  void _showPlaceDetails(Place place) {
    showDialog(
      context: context,
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final dialogWidth = screenWidth < 500 ? screenWidth * 0.92 : 440.0;

        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          content: SizedBox(
            width: dialogWidth,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (place.imageUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        place.imageUrl,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    place.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Du ${place.arrivalDate.day}/${place.arrivalDate.month}/${place.arrivalDate.year} au ${place.departureDate.day}/${place.departureDate.month}/${place.departureDate.year}',
                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                  if (place.description != null && place.description!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(place.description!, style: const TextStyle(fontSize: 14)),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Supprimer',
              onPressed: () async {
                await _placesRef.doc(place.id).delete();
                if (context.mounted) Navigator.pop(context);
              },
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.blue),
              tooltip: 'Modifier',
              onPressed: () {
                Navigator.pop(context);
                _openAddEditDialog(place: place);
              },
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  void _openAddEditDialog({LatLng? initialPosition, Place? place}) {
    showDialog(
      context: context,
      builder: (context) => AddEditPlaceDialog(
        initialPosition: initialPosition,
        place: place,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nos Voyages')),
      // StreamBuilder écoute les changements Firestore en temps réel
      body: StreamBuilder<QuerySnapshot>(
        stream: _placesRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          // Map des documents Firestore vers notre modèle Dart 'Place'
          final places = snapshot.data!.docs
              .map((doc) => Place.fromFirestore(doc))
              .toList();

          // Transformation des objets Place en marqueurs
          final markers = places.map((place) {
            return Marker(
              point: LatLng(place.latitude, place.longitude),
              width: 40,
              height: 40,
              child: GestureDetector(
                onTap: () => _showPlaceDetails(place),
                child: const Icon(Icons.location_on, color: Colors.red, size: 40),
              ),
            );
          }).toList();

          return FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(20.0, 0.0),
              initialZoom: 2.0,
              // Clic sur la carte = ouverture du formulaire d'ajout avec coordonnées reçues
              onTap: (tapPosition, point) {
                _openAddEditDialog(initialPosition: point);
              },
            ),
            children: [
              // Layer 1 : Fond de carte OpenStreetMap
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),
              // Layer 2 : Calque contenant la liste des pins
              MarkerLayer(markers: markers),
            ],
          );
        },
      ),
      // Bouton pour recentrer la vue sur l'ensemble des marqueurs
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.my_location),
        onPressed: () {
          _placesRef.get().then((snapshot) {
            final places = snapshot.docs.map((d) => Place.fromFirestore(d)).toList();
            _fitBounds(places);
          });
        },
      ),
    );
  }
}