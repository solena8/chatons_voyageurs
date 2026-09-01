import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/place.dart';
import '../models/trip_map.dart';
import '../services/auth_service.dart';
import '../services/place_service.dart';
import '../services/trip_map_service.dart';
import '../utils/map_utils.dart';
import '../widgets/add_edit_place_dialog.dart';
import '../widgets/create_map_dialog.dart';
import '../widgets/invite_user_dialog.dart';
import '../widgets/map_drawer.dart';
import '../widgets/place_details_dialog.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final Set<String> _visibleMapIds = {};
  bool _initialized = false;
  bool _isMapReady = false;
  String _lastFittedKey = '';

  void _openAddEdit({LatLng? pos, Place? place, String? mapId, List<TripMap>? maps}) {
    showDialog(
      context: context,
      builder: (_) => AddEditPlaceDialog(
        initialPosition: pos,
        place: place,
        targetMapId: mapId,
        availableMaps: maps ?? [],
      ),
    );
  }

  void _checkAutoFit(List<Place> places) {
    final key = '${_visibleMapIds.join(",")}_${places.length}';
    if (_isMapReady && places.isNotEmpty && _lastFittedKey != key) {
      _lastFittedKey = key;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        MapUtils.fitCameraToBounds(_mapController, places);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;

    return StreamBuilder<List<TripMap>>(
      stream: TripMapService.getUserMapsStream(user?.uid),
      builder: (context, mapSnapshot) {
        final maps = mapSnapshot.data ?? [];

        if (!_initialized && maps.isNotEmpty) {
          _visibleMapIds.addAll(maps.map((m) => m.id));
          _initialized = true;
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
            onSelectionChanged: (ids) => setState(() => _visibleMapIds..clear()..addAll(ids)),
            onCreateMap: () => showDialog(
              context: context,
              builder: (_) => CreateMapDialog(onMapCreated: (id) => setState(() => _visibleMapIds.add(id))),
            ),
            onInviteUser: (map) => showDialog(
              context: context,
              builder: (_) => InviteUserDialog(map: map),
            ),
          ),
          body: StreamBuilder<List<Place>>(
            stream: PlaceService.getVisiblePlaces(maps, _visibleMapIds),
            builder: (context, placeSnapshot) {
              final places = placeSnapshot.data ?? [];
              _checkAutoFit(places);

              return Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: const LatLng(20.0, 0.0),
                      initialZoom: 2.0,
                      onMapReady: () => setState(() => _isMapReady = true),
                      onTap: (_, pt) => _openAddEdit(pos: pt, maps: maps),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.chatons_voyageurs',
                      ),
                      MarkerLayer(
                        markers: places.map((p) => _buildMarker(p, maps)).toList(),
                      ),
                    ],
                  ),
                  if (places.isNotEmpty)
                    Positioned(
                      right: 16,
                      bottom: 16,
                      child: FloatingActionButton(
                        tooltip: 'Recentrer',
                        child: const Icon(Icons.my_location),
                        onPressed: () => MapUtils.fitCameraToBounds(_mapController, places),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Marker _buildMarker(Place place, List<TripMap> maps) {
    final parent = maps.where((m) => m.id == place.mapId).firstOrNull;
    return Marker(
      point: LatLng(place.latitude, place.longitude),
      width: 40,
      height: 40,
      child: GestureDetector(
        onTap: () => showDialog(
          context: context,
          builder: (_) => PlaceDetailsDialog(
            place: place,
            parentMap: parent,
            onEdit: () => _openAddEdit(place: place, mapId: place.mapId!),
          ),
        ),
        child: Icon(Icons.location_on, color: parent?.color ?? Colors.red, size: 40),
      ),
    );
  }
}