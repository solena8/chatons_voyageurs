import 'package:flutter/material.dart';
import '../models/trip_map.dart';
import '../services/auth_service.dart';
import '../services/trip_map_service.dart';

class CreateMapDialog extends StatefulWidget {
  final ValueChanged<String> onMapCreated;

  const CreateMapDialog({super.key, required this.onMapCreated});

  @override
  State<CreateMapDialog> createState() => _CreateMapDialogState();
}

class _CreateMapDialogState extends State<CreateMapDialog> {
  final _titleCtrl = TextEditingController();
  final List<Color> _availableColors = const [
    Colors.redAccent,
    Colors.blueAccent,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
  ];
  late Color _selectedColor;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedColor = _availableColors.first;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = AuthService.currentUser;
    if (user == null || _titleCtrl.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    final newMap = TripMap(
      id: '',
      title: _titleCtrl.text.trim(),
      ownerId: user.uid,
      members: [user.uid],
      color: _selectedColor,
    );

    final mapId = await TripMapService.createMap(newMap);
    widget.onMapCreated(mapId);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Créer une carte'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'Titre (ex: Roadtrip 2026)'),
          ),
          const SizedBox(height: 16),
          const Text('Couleur des marqueurs :', style: TextStyle(fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _availableColors.map((color) {
              final isSelected = _selectedColor == color;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = color),
                child: CircleAvatar(
                  backgroundColor: color,
                  radius: 16,
                  child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Créer'),
        ),
      ],
    );
  }
}