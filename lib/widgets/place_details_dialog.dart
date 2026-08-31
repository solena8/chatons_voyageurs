import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/place.dart';
import '../models/trip_map.dart';

class PlaceDetailsDialog extends StatelessWidget {
  final Place place;
  final TripMap? parentMap;
  final VoidCallback onEdit;

  const PlaceDetailsDialog({
    super.key,
    required this.place,
    required this.parentMap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
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
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (parentMap != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Chip(
                    avatar: CircleAvatar(backgroundColor: parentMap!.color, radius: 6),
                    label: Text(parentMap!.title, style: const TextStyle(fontSize: 11)),
                    visualDensity: VisualDensity.compact,
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
        if (place.mapId != null)
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Supprimer',
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('maps')
                  .doc(place.mapId!)
                  .collection('places')
                  .doc(place.id)
                  .delete();
              if (context.mounted) Navigator.pop(context);
            },
          ),
        if (place.mapId != null)
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.blue),
            tooltip: 'Modifier',
            onPressed: () {
              Navigator.pop(context);
              onEdit();
            },
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
      ],
    );
  }
}