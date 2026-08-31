import 'package:flutter/material.dart';
import '../models/trip_map.dart';
import '../services/auth_service.dart';

class MapDrawer extends StatelessWidget {
  final List<TripMap> maps;
  final Set<String> visibleMapIds;
  final ValueChanged<Set<String>> onSelectionChanged;
  final VoidCallback onCreateMap;
  final ValueChanged<TripMap> onInviteUser;

  const MapDrawer({
    super.key,
    required this.maps,
    required this.visibleMapIds,
    required this.onSelectionChanged,
    required this.onCreateMap,
    required this.onInviteUser,
  });

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    final allSelected = maps.isNotEmpty && visibleMapIds.length == maps.length;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.blueAccent),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.account_circle, size: 48, color: Colors.white),
                const SizedBox(height: 8),
                Text(
                  user?.email ?? 'Voyageur',
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          CheckboxListTile(
            title: const Text('Tout cocher / décocher', style: TextStyle(fontWeight: FontWeight.bold)),
            value: allSelected,
            tristate: visibleMapIds.isNotEmpty && !allSelected,
            onChanged: (bool? value) {
              if (value == true) {
                onSelectionChanged(maps.map((m) => m.id).toSet());
              } else {
                onSelectionChanged({});
              }
            },
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Mes cartes', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.blueAccent),
                  tooltip: 'Créer une carte',
                  onPressed: onCreateMap,
                ),
              ],
            ),
          ),
          ...maps.map((m) {
            final isChecked = visibleMapIds.contains(m.id);
            final isOwner = m.ownerId == user?.uid;

            return CheckboxListTile(
              value: isChecked,
              secondary: CircleAvatar(backgroundColor: m.color, radius: 10),
              title: Text(m.title, style: const TextStyle(fontSize: 14)),
              subtitle: isOwner
                  ? InkWell(
                onTap: () => onInviteUser(m),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    children: [
                      Icon(Icons.person_add_alt_1, size: 14, color: Colors.blue),
                      SizedBox(width: 4),
                      Text('Inviter', style: TextStyle(color: Colors.blue, fontSize: 12)),
                    ],
                  ),
                ),
              )
                  : const Text('Partagée avec moi', style: TextStyle(fontSize: 12, color: Colors.grey)),
              onChanged: (bool? checked) {
                final updated = Set<String>.from(visibleMapIds);
                if (checked == true) {
                  updated.add(m.id);
                } else {
                  updated.remove(m.id);
                }
                onSelectionChanged(updated);
              },
            );
          }),
        ],
      ),
    );
  }
}