import 'package:flutter/material.dart';
import '../models/trip_map.dart';
import '../services/auth_service.dart';

class InviteUserDialog extends StatefulWidget {
  final TripMap map;

  const InviteUserDialog({super.key, required this.map});

  @override
  State<InviteUserDialog> createState() => _InviteUserDialogState();
}

class _InviteUserDialogState extends State<InviteUserDialog> {
  final _emailCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_emailCtrl.text.trim().isEmpty) return;

    setState(() => _isLoading = true);
    final success = await AuthService.inviteUserByEmail(widget.map.id, _emailCtrl.text);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Voyageur ajouté avec succès !' : 'Aucun compte trouvé avec cet e-mail.'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Partager "${widget.map.title}"'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Entrez l\'e-mail du voyageur à inviter :'),
          const SizedBox(height: 10),
          TextField(
            controller: _emailCtrl,
            decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.person_add)),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Inviter'),
        ),
      ],
    );
  }
}