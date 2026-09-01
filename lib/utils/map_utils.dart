import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
import '../models/place.dart';

class MapUtils {
  static void fitCameraToBounds(MapController controller, List<Place> places) {
    if (places.isEmpty) return;

    final points = places.map((p) => LatLng(p.latitude, p.longitude)).toList();
    final first = points.first;
    final allSame = points.every((p) =>
    (p.latitude - first.latitude).abs() < 0.001 &&
        (p.longitude - first.longitude).abs() < 0.001);

    if (points.length == 1 || allSame) {
      controller.move(first, 9.0);
      return;
    }

    controller.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: const EdgeInsets.all(80),
        maxZoom: 15.0,
      ),
    );
  }
}