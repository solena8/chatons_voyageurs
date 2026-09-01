import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../models/place.dart';
import '../models/trip_map.dart';
import '../services/api_service.dart';
import '../services/place_service.dart';

class AddEditPlaceDialog extends StatefulWidget {
  final LatLng? initialPosition;
  final Place? place;
  final String? targetMapId;
  final List<TripMap> availableMaps;

  const AddEditPlaceDialog({
    super.key,
    this.initialPosition,
    this.place,
    this.targetMapId,
    this.availableMaps = const [],
  });

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
  String? _selectedMapId;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.place?.title ?? '');
    _descController = TextEditingController(text: widget.place?.description ?? '');
    _searchController = TextEditingController();
    _imageUrl = widget.place?.imageUrl;
    _selectedMapId = widget.targetMapId ?? (widget.availableMaps.isNotEmpty ? widget.availableMaps.first.id : null);

    if (widget.place != null) {
      _selectedArrivalDate = widget.place!.arrivalDate;
      _selectedDepartureDate = widget.place!.departureDate;
      _selectedLocation = LatLng(widget.place!.latitude, widget.place!.longitude);
      _selectedMapId = widget.place!.mapId ?? _selectedMapId;
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
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(
        start: _selectedArrivalDate,
        end: _selectedDepartureDate.isBefore(_selectedArrivalDate) ? _selectedArrivalDate : _selectedDepartureDate,
      ),
    );

    if (picked != null) {
      setState(() {
        _selectedArrivalDate = picked.start;
        _selectedDepartureDate = picked.end;
      });
    }
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
    if (!_formKey.currentState!.validate() || _selectedLocation == null || _imageUrl == null || _selectedMapId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complétez le titre, la photo, le lieu et choisissez une carte.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final placeData = Place(
      id: widget.place?.id ?? '',
      mapId: _selectedMapId,
      title: _titleController.text.trim(),
      description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      imageUrl: _imageUrl!,
      latitude: _selectedLocation!.latitude,
      longitude: _selectedLocation!.longitude,
      arrivalDate: _selectedArrivalDate,
      departureDate: _selectedDepartureDate,
    );

    if (widget.place == null) {
      await PlaceService.addPlace(_selectedMapId!, placeData);
    } else {
      await PlaceService.updatePlace(_selectedMapId!, placeData);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth < 500 ? screenWidth * 0.92 : 440.0;

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
                if (widget.availableMaps.isNotEmpty && widget.place == null) ...[
                  DropdownButtonFormField<String>(
                    initialValue: _selectedMapId,
                    decoration: const InputDecoration(labelText: 'Carte de destination'),
                    items: widget.availableMaps.map((m) {
                      return DropdownMenuItem(
                        value: m.id,
                        child: Row(
                          children: [
                            CircleAvatar(backgroundColor: m.color, radius: 6),
                            const SizedBox(width: 8),
                            Text(m.title),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedMapId = val),
                  ),
                  const SizedBox(height: 10),
                ],
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Titre'),
                  validator: (v) => v == null || v.isEmpty ? 'Titre requis' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  icon: const Icon(Icons.date_range, size: 18),
                  label: Text(
                    'Du ${_selectedArrivalDate.day}/${_selectedArrivalDate.month}/${_selectedArrivalDate.year} '
                        'au ${_selectedDepartureDate.day}/${_selectedDepartureDate.month}/${_selectedDepartureDate.year}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  onPressed: _selectDateRange,
                ),
                const SizedBox(height: 14),
                Autocomplete<AddressSuggestion>(
                  displayStringForOption: (option) => option.displayName,
                  optionsBuilder: (textVal) async {
                    if (textVal.text.trim().length < 3) return const Iterable<AddressSuggestion>.empty();
                    return await ApiService.searchAddressSuggestions(textVal.text);
                  },
                  onSelected: (selection) {
                    setState(() {
                      _selectedLocation = selection.location;
                      _searchController.text = selection.displayName;
                    });
                  },
                  fieldViewBuilder: (context, textCtrl, focusNode, onFieldSubmitted) {
                    return TextField(
                      controller: textCtrl,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        labelText: 'Rechercher une adresse',
                        hintText: 'Tapez une ville...',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                if (_selectedLocation != null)
                  Text(
                    'Coordonnées : ${_selectedLocation!.latitude.toStringAsFixed(4)}, ${_selectedLocation!.longitude.toStringAsFixed(4)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _pickAndUploadImage,
                  icon: const Icon(Icons.upload),
                  label: const Text('Uploader une photo'),
                ),
                if (_imageUrl != null)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text('Image prête !', style: TextStyle(color: Colors.green), textAlign: TextAlign.center),
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
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(onPressed: _isLoading ? null : _savePlace, child: const Text('Enregistrer')),
      ],
    );
  }
}