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
  // Form key used for input validation
  final _formKey = GlobalKey<FormState>();

  // Input controllers for form text fields
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _searchController;

  // Form state variables
  LatLng? _selectedLocation;
  String? _imageUrl;
  DateTime _selectedArrivalDate = DateTime.now();
  DateTime _selectedDepartureDate = DateTime.now();
  bool _isLoading = false; // Tracks asynchronous operations (image upload / save)

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.place?.title ?? '');
    _descController = TextEditingController(text: widget.place?.description ?? '');
    _searchController = TextEditingController();
    _imageUrl = widget.place?.imageUrl;

    // Si on modifie un lieu existant, on charge ses dates
    if (widget.place != null) {
      _selectedArrivalDate = widget.place!.arrivalDate;
      _selectedDepartureDate = widget.place!.departureDate;
      _selectedLocation = LatLng(widget.place!.latitude, widget.place!.longitude);
    } else {
      _selectedLocation = widget.initialPosition;
    }
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
    );

    if (pickedRange == null) return;

    setState(() {
      _selectedArrivalDate = pickedRange.start;
      _selectedDepartureDate = pickedRange.end;
    });
  }

  /// Opens the device photo gallery, selects an image, and uploads it via ApiService.
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

  /// Searches for coordinates corresponding to the text entered in the search bar via Nominatim.
  Future<void> _searchAddress() async {
    if (_searchController.text.isEmpty) return;
    final location = await ApiService.searchAddress(_searchController.text);
    if (location != null) {
      setState(() => _selectedLocation = location);
    }
  }

  /// Validates input, builds the payload, and performs an insert or update in Cloud Firestore.
  Future<void> _savePlace() async {
    // Validate required fields (title, coordinates, and uploaded image)
    if (!_formKey.currentState!.validate() || _selectedLocation == null || _imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez compléter tous les champs et ajouter une image.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Map payload matching Firestore schema
    final data = {
      'title': _titleController.text,
      'description': _descController.text,
      'imageUrl': _imageUrl,
      'latitude': _selectedLocation!.latitude,
      'longitude': _selectedLocation!.longitude,
      'arrivalDate': Timestamp.fromDate(_selectedArrivalDate),
      'departureDate': Timestamp.fromDate(_selectedDepartureDate),
    };

    // Insert new document if creating, or update existing document if editing
    if (widget.place == null) {
      await FirebaseFirestore.instance.collection('places').add(data);
    } else {
      await FirebaseFirestore.instance.collection('places').doc(widget.place!.id).update(data);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.place == null ? 'Ajouter un lieu' : 'Modifier le lieu'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Place Title Input
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Titre'),
                validator: (v) => v == null || v.isEmpty ? 'Titre requis' : null,
              ),
              // Place Description Input
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 12),

              OutlinedButton.icon(
                icon: const Icon(Icons.date_range, size: 16),
                label: Text(
                  'Arrivée : ${_selectedArrivalDate.day}/${_selectedArrivalDate.month}/${_selectedArrivalDate.year}'
                      '   →   '
                      'Départ : ${_selectedDepartureDate.day}/${_selectedDepartureDate.month}/${_selectedDepartureDate.year}',
                ),
                onPressed: _selectDateRange,
              ),
              const SizedBox(height: 10),
              const SizedBox(height: 10),

              // Address Search Field & Search Button
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(labelText: 'Rechercher une adresse'),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.search), onPressed: _searchAddress),
                ],
              ),

              // Displays currently assigned coordinates
              if (_selectedLocation != null)
                Text('Coordonnées : ${_selectedLocation!.latitude.toStringAsFixed(4)}, ${_selectedLocation!.longitude.toStringAsFixed(4)}'),
              const SizedBox(height: 10),

              // Image Upload Button
              ElevatedButton.icon(
                onPressed: _pickAndUploadImage,
                icon: const Icon(Icons.upload),
                label: const Text('Uploader une photo'),
              ),

              // Image upload confirmation banner
              if (_imageUrl != null)
                const Text('Image chargée avec succès !', style: TextStyle(color: Colors.green)),

              // Loading spinner during network operations
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(onPressed: _savePlace, child: const Text('Enregistrer')),
      ],
    );
  }
}