import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../models/place.dart';
import '../services/api_service.dart';

/// Modal dialog for either creating a new place or modifying an existing one.
class AddEditPlaceDialog extends StatefulWidget {
  final LatLng? initialPosition; // GPS coordinates passed when tapping on the map
  final Place? place;            // Existing place instance if opened in "Edit" mode

  const AddEditPlaceDialog({super.key, this.initialPosition, this.place});

  @override
  State<AddEditPlaceDialog> createState() => _AddEditPlaceDialogState();
}

class _AddEditPlaceDialogState extends State<AddEditPlaceDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _searchController;

  LatLng? _selectedLocation;
  String? _imageUrl;
  DateTime _selectedArrivalDate = DateTime.now();
  DateTime _selectedDepartureDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.place?.title ?? '');
    _descController = TextEditingController(text: widget.place?.description ?? '');
    _searchController = TextEditingController();
    _imageUrl = widget.place?.imageUrl;

    if (widget.place != null) {
      _selectedArrivalDate = widget.place!.arrivalDate;
      _selectedDepartureDate = widget.place!.departureDate;
      _selectedLocation = LatLng(widget.place!.latitude, widget.place!.longitude);
    } else {
      _selectedLocation = widget.initialPosition;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(
        start: _selectedArrivalDate,
        end: _selectedDepartureDate.isBefore(_selectedArrivalDate)
            ? _selectedArrivalDate
            : _selectedDepartureDate,
      ),
      builder: (context, child) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 500,
              maxHeight: 600,
            ),
            child: Dialog(
              insetPadding: const EdgeInsets.all(16),
              clipBehavior: Clip.antiAlias,
              child: child,
            ),
          ),
        );
      },
    );

    if (pickedRange == null) return;

    setState(() {
      _selectedArrivalDate = pickedRange.start;
      _selectedDepartureDate = pickedRange.end;
    });
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() => _isLoading = true);
      final url = await ApiService.uploadToUploadcare(file);
      setState(() {
        _imageUrl = url;
        _isLoading = false;
      });
    }
  }

  Future<void> _savePlace() async {
    if (!_formKey.currentState!.validate() || _selectedLocation == null || _imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez compléter tous les champs et ajouter une image.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final data = {
      'title': _titleController.text,
      'description': _descController.text,
      'imageUrl': _imageUrl,
      'latitude': _selectedLocation!.latitude,
      'longitude': _selectedLocation!.longitude,
      'arrivalDate': Timestamp.fromDate(_selectedArrivalDate),
      'departureDate': Timestamp.fromDate(_selectedDepartureDate),
    };

    if (widget.place == null) {
      await FirebaseFirestore.instance.collection('places').add(data);
    } else {
      await FirebaseFirestore.instance.collection('places').doc(widget.place!.id).update(data);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Sur mobile (< 500px), on prend presque tout l'écran, sur PC on plafonne à 440px
    final dialogWidth = screenWidth < 500 ? screenWidth * 0.92 : 440.0;
    final isCompact = screenWidth < 380;

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: Text(widget.place == null ? 'Ajouter un lieu' : 'Modifier le lieu'),
      content: SizedBox(
        width: dialogWidth,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Titre
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Titre',
                    contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Titre requis' : null,
                ),
                const SizedBox(height: 8),

                // Description
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  ),
                ),
                const SizedBox(height: 14),

                // Sélecteur de dates responsive
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.date_range, size: 18),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: isCompact
                    // Si très petit écran : affichage court
                        ? Text(
                      '${_selectedArrivalDate.day}/${_selectedArrivalDate.month}/${_selectedArrivalDate.year} → ${_selectedDepartureDate.day}/${_selectedDepartureDate.month}/${_selectedDepartureDate.year}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    )
                    // Écran standard : affichage aéré
                        : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Du ${_selectedArrivalDate.day}/${_selectedArrivalDate.month}/${_selectedArrivalDate.year}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Icon(Icons.arrow_forward, size: 14, color: Colors.grey),
                        ),
                        Text(
                          'Au ${_selectedDepartureDate.day}/${_selectedDepartureDate.month}/${_selectedDepartureDate.year}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  onPressed: _selectDateRange,
                ),
                const SizedBox(height: 14),

                // Autocomplétion Adresse
                Autocomplete<AddressSuggestion>(
                  displayStringForOption: (AddressSuggestion option) => option.displayName,
                  optionsBuilder: (TextEditingValue textEditingValue) async {
                    if (textEditingValue.text.trim().length < 3) {
                      return const Iterable<AddressSuggestion>.empty();
                    }
                    return await ApiService.searchAddressSuggestions(textEditingValue.text);
                  },
                  onSelected: (AddressSuggestion selection) {
                    setState(() {
                      _selectedLocation = selection.location;
                      _searchController.text = selection.displayName;
                    });
                  },
                  fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                    return TextField(
                      controller: textEditingController,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        labelText: 'Rechercher une adresse',
                        hintText: 'Tapez une ville ou un lieu...',
                        prefixIcon: Icon(Icons.location_on_outlined),
                        contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),

                // Coordonnées GPS
                if (_selectedLocation != null)
                  Text(
                    'Coordonnées : ${_selectedLocation!.latitude.toStringAsFixed(4)}, ${_selectedLocation!.longitude.toStringAsFixed(4)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 12),

                // Upload Photo
                ElevatedButton.icon(
                  onPressed: _pickAndUploadImage,
                  icon: const Icon(Icons.upload),
                  label: const Text('Uploader une photo'),
                ),

                if (_imageUrl != null)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Image chargée avec succès !',
                      style: TextStyle(color: Colors.green),
                      textAlign: TextAlign.center,
                    ),
                  ),

                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 12.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _savePlace,
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}