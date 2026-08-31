import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/place.dart';
import '../models/trip_map.dart';
import '../services/auth_service.dart';
import '../widgets/add_edit_place_dialog.dart';
import '../widgets/create_map_dialog.dart';
import '../widgets/invite_user_dialog.dart';
import '../widgets/map_drawer.dart';
import '../widgets/place_details_dialog.dart';
import 'dart:async';
import 'package:async/async.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final Set<String> _visibleMapIds = {};
  bool _initializedSelection = false;
  bool _isMapReady = false;
  String _lastFittedKey = '';

  void _fitBounds(List<Place> places) {
    if (!_isMapReady || places.isEmpty) return;

    final points = places.map((p) => LatLng(p.latitude, p.longitude)).toList();
    final first = points.first;
    final allSame = points.every((p) =>
    (p.latitude - first.latitude).abs() < 0.001 &&
        (p.longitude - first.longitude).abs() < 0.001);

    if (points.length == 1 || allSame) {
      _mapController.move(first, 9.0);
      return;
    }

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: const EdgeInsets.all(80),
        maxZoom: 15.0,
      ),
    );
  }

  void _openAddEditDialog({LatLng? initialPosition, Place? place, String? targetMapId, List<TripMap>? availableMaps}) {
    showDialog(
      context: context,
      builder: (context) => AddEditPlaceDialog(
        initialPosition: initialPosition,
        place: place,
        targetMapId: targetMapId,
        availableMaps: availableMaps ?? [],
      ),
    );
  }

  Stream<List<Place>> _getVisiblePlacesStream(List<TripMap> maps) {
    final activeMaps = maps.where((m) => _visibleMapIds.contains(m.id)).toList();
    if (activeMaps.isEmpty) return Stream.value([]);

    // On crée un flux d'écoute pour chaque carte cochée
    final streams = activeMaps.map((map) {
      return FirebaseFirestore.instance
          .collection('maps')
          .doc(map.id)
          .collection('places')
          .snapshots()
          .map((snapshot) => snapshot.docs
          .map((doc) => Place.fromFirestore(doc, mapId: map.id))
          .toList());
    }).toList();

    // On fusionne les streams individuels pour reconstruire la liste globale à chaque modification
    return StreamGroup.merge(streams).transform(
      StreamTransformer<List<Place>, List<Place>>.fromHandlers(
        handleData: (places, sink) async {
          // Récupère l'état instantané de toutes les cartes cochées à chaque événement
          final results = await Future.wait(
            activeMaps.map((m) => FirebaseFirestore.instance
                .collection('maps')
                .doc(m.id)
                .collection('places')
                .get()
                .then((snap) => snap.docs
                .map((d) => Place.fromFirestore(d, mapId: m.id))
                .toList())),
          );
          sink.add(results.expand((element) => element).toList());
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('maps')
          .where('members', arrayContains: user?.uid)
          .snapshots(),
      builder: (context, mapSnapshot) {
        final maps = mapSnapshot.hasData
            ? mapSnapshot.data!.docs.map((d) => TripMap.fromFirestore(d)).toList()
            : <TripMap>[];

        if (!_initializedSelection && maps.isNotEmpty) {
          _visibleMapIds.addAll(maps.map((m) => m.id));
          _initializedSelection = true;
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              _visibleMapIds.length == 1
                  ? maps.firstWhere((m) => m.id == _visibleMapIds.first).title
                  : '${_visibleMapIds.length} carte(s) affichée(s)',
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Déconnexion',
                onPressed: () => AuthService.signOut(),
              ),
            ],
          ),
          drawer: MapDrawer(
            maps: maps,
            visibleMapIds: _visibleMapIds,
            onSelectionChanged: (newSelection) => setState(() => _visibleMapIds..clear()..addAll(newSelection)),
            onCreateMap: () => showDialog(
              context: context,
              builder: (_) => CreateMapDialog(onMapCreated: (id) => setState(() => _visibleMapIds.add(id))),
            ),
            onInviteUser: (map) => showDialog(
              context: context,
              builder: (_) => InviteUserDialog(map: map),
            ),
          ),
          body: maps.isEmpty
              ? Center(
            child: ElevatedButton.icon(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => CreateMapDialog(onMapCreated: (id) => setState(() => _visibleMapIds.add(id))),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Créer ma première carte'),
            ),
          )
              : StreamBuilder<List<Place>>(
            stream: _getVisiblePlacesStream(maps),
            builder: (context, placeSnapshot) {
              final places = placeSnapshot.data ?? [];

              final currentKey = '${_visibleMapIds.join(",")}_${places.length}';
              if (_isMapReady && places.isNotEmpty && _lastFittedKey != currentKey) {
                _lastFittedKey = currentKey;
                WidgetsBinding.instance.addPostFrameCallback((_) => _fitBounds(places));
              }

              final markers = places.map((place) {
                final parentMap = maps.where((m) => m.id == place.mapId).firstOrNull;
                return Marker(
                  point: LatLng(place.latitude, place.longitude),
                  width: 40,
                  height: 40,
                  child: GestureDetector(
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => PlaceDetailsDialog(
                        place: place,
                        parentMap: parentMap,
                        onEdit: () => _openAddEditDialog(place: place, targetMapId: place.mapId!),
                      ),
                    ),
                    child: Icon(Icons.location_on, color: parentMap?.color ?? Colors.red, size: 40),
                  ),
                );
              }).toList();

              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: const LatLng(20.0, 0.0),
                  initialZoom: 2.0,
                  onMapReady: () {
                    setState(() => _isMapReady = true);
                    if (places.isNotEmpty) _fitBounds(places);
                  },
                  onTap: (pos, point) => _openAddEditDialog(initialPosition: point, availableMaps: maps),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.chatons_voyageurs',
                  ),
                  MarkerLayer(markers: markers),
                ],
              );
            },
          ),
          floatingActionButton: StreamBuilder<List<Place>>(
            stream: _getVisiblePlacesStream(maps),
            builder: (context, snapshot) {
              final places = snapshot.data ?? [];
              if (places.isEmpty) return const SizedBox.shrink();
              return FloatingActionButton(
                tooltip: 'Recentrer',
                child: const Icon(Icons.my_location),
                onPressed: () => _fitBounds(places),
              );
            },
          ),
        );
      },
    );
  }
}