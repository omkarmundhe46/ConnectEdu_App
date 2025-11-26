import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectedu_app/bloc/event_list_bloc.dart';
import 'package:connectedu_app/models/event.dart';
import 'package:connectedu_app/models/club.dart';
import 'package:connectedu_app/services/api_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class EventEditScreen extends StatefulWidget {
  final Club club;
  final Event? event;

  const EventEditScreen({super.key, required this.club, this.event});

  @override
  State<EventEditScreen> createState() => _EventEditScreenState();
}

class _EventEditScreenState extends State<EventEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _contactName1Controller;
  late TextEditingController _contactPhone1Controller;
  late TextEditingController _contactName2Controller;
  late TextEditingController _contactPhone2Controller;
  final _feeController = TextEditingController();

  DateTime? _selectedDateTime;
  bool _isSubmitting = false;

  // Image upload state
  XFile? _selectedImageFile;
  String? _currentImageUrl;
  bool _isUploadingImage = false;
  final ImagePicker _picker = ImagePicker();

  bool get _isEditMode => widget.event != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.event?.name ?? '');
    _descriptionController = TextEditingController(text: widget.event?.description ?? '');
    _locationController = TextEditingController(text: widget.event?.location ?? '');
    _contactName1Controller = TextEditingController(text: widget.event?.contactName1 ?? '');
    _contactPhone1Controller = TextEditingController(text: widget.event?.contactPhone1 ?? '');
    _contactName2Controller = TextEditingController(text: widget.event?.contactName2 ?? '');
    _contactPhone2Controller = TextEditingController(text: widget.event?.contactPhone2 ?? '');
    _selectedDateTime = widget.event?.date;
    _currentImageUrl = widget.event?.imageUrl;
    _feeController.text = widget.event?.fee.toString() ?? '0';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _contactName1Controller.dispose();
    _contactPhone1Controller.dispose();
    _contactName2Controller.dispose();
    _contactPhone2Controller.dispose();
    _feeController.dispose();
    super.dispose();
  }

  // --- Image Picker Logic ---
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (image != null) {
        setState(() {
          _selectedImageFile = image;
          _currentImageUrl = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- Image Upload Logic ---
  Future<String?> _uploadImage(XFile image) async {
    setState(() { _isUploadingImage = true; });
    String? uploadedUrl;
    try {
      final apiService = context.read<ApiService>();
      String fileName = image.path.split('/').last;
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(image.path, filename: fileName),
      });

      debugPrint('Uploading event image...');
      final response = await apiService.dio.post(
        '/api/uploads', // Generic upload endpoint
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        uploadedUrl = response.data['fileUrl'];
        debugPrint('Image uploaded successfully: $uploadedUrl');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cover photo uploaded successfully!'), backgroundColor: Colors.green, duration: Duration(seconds: 2)),
          );
        }
      } else {
        debugPrint('Image upload failed with status: ${response.statusCode}');
        throw Exception('Failed to upload image: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Image upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image upload failed: ${e.toString()}'), backgroundColor: Colors.red, duration: Duration(seconds: 3)),
        );
      }
    } finally {
      if(mounted) {
        setState(() { _isUploadingImage = false; });
      }
    }
    return uploadedUrl;
  }

  // --- Date Time Picker ---
  Future<void> _pickDateTime() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date == null) return;

    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime ?? DateTime.now().add(const Duration(hours: 1))),
    );
    if (time == null) return;

    setState(() {
      _selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  // --- Form Submission ---
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields.'), backgroundColor: Colors.orange),
      );
      return;
    }
    if (_selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date and time.'), backgroundColor: Colors.orange),
      );
      return;
    }
    if (!_isEditMode && (_currentImageUrl == null && _selectedImageFile == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a cover photo.'), backgroundColor: Colors.orange),
      );
      return;
    }


    setState(() { _isSubmitting = true; });

    String? finalImageUrl = _currentImageUrl;

    // Upload image IF a new one was selected
    if (_selectedImageFile != null) {
      final uploadedUrl = await _uploadImage(_selectedImageFile!);
      if (uploadedUrl == null) {
        if(mounted) setState(() { _isSubmitting = false; });
        return;
      }
      finalImageUrl = uploadedUrl;
    }

    // Prepare data map matching EventRequestDto
    final eventData = {
      'name': _nameController.text,
      'description': _descriptionController.text,
      'location': _locationController.text,
      'date': _selectedDateTime!.toIso8601String(), // Send as ISO 8601 string
      'imageUrl': finalImageUrl,
      'contactName1': _contactName1Controller.text,
      'contactPhone1': _contactPhone1Controller.text,
      'contactName2': _contactName2Controller.text,
      'contactPhone2': _contactPhone2Controller.text,
      'meetingLink': '', // Add meeting link field (can be updated later)
      'fee': double.tryParse(_feeController.text) ?? 0.0,
    };

    try {
      if (!_isEditMode) {
        // Create Mode
        context.read<EventListBloc>().add(CreateEvent(
          clubId: widget.club.id,
          eventData: eventData,
        ));
      } else {
        // Edit Mode
        context.read<EventListBloc>().add(UpdateEvent(
          clubId: widget.club.id,
          eventId: widget.event!.id,
          eventData: eventData,
        ));
      }
      // Listener will handle navigation on success/failure
    } catch (e) {
      if (mounted) setState(() { _isSubmitting = false; });
      debugPrint("Error dispatching event action: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.event != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.club.name), // Club name as subtitle
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton(
              onPressed: (_isSubmitting || _isUploadingImage) ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0), // Smaller padding
                minimumSize: const Size(0, 36), // Minimum size for height
              ),
              child: _isSubmitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(isEditMode ? 'SAVE' : 'NEXT'),
            ),
          )
        ],
      ),
      body: BlocListener<EventListBloc, EventListState>(
        listener: (context, state) {
          if (state is EventActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.green),
            );
            if (Navigator.canPop(context)) {
              Navigator.of(context).pop(true); // Pop with true to signal success
            }
          } else if (state is EventActionFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${state.error}'), backgroundColor: Colors.red),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Event Title (Add title)
                TextFormField(
                  controller: _nameController,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
                  decoration: const InputDecoration(
                    hintText: 'Add title',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Please enter an event title' : null,
                ),
                const SizedBox(height: 16),

                // --- Description Row ---
                _buildInputRow(
                  context: context,
                  icon: Icons.notes,
                  label: 'Add description',
                  controller: _descriptionController,
                  validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                  maxLines: 4,
                  keyboardType: TextInputType.multiline,
                ),
                const Divider(),

                // --- Image Picker Row (Cover Photo) ---
                _buildImagePickerRow(context),
                const Divider(),

                // --- Date Time Picker Row ---
                _buildDateTimeRow(context),
                const Divider(),

                // --- Location Row ---
                _buildInputRow(
                  context: context,
                  icon: Icons.location_on_outlined,
                  label: 'Add location',
                  controller: _locationController,
                  validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                ),
                const Divider(),

                _buildInputRow(
                  context: context,
                  icon: Icons.currency_rupee,
                  label: 'Registration Fee (0 for Free)',
                  controller: _feeController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter a fee';
                    if (double.tryParse(value) == null) return 'Invalid number';
                    return null;
                  },
                ),
                const Divider(),

                // --- Invite People (Placeholder) ---
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Row(
                    children: [
                      Icon(Icons.people_outlined, color: Theme.of(context).hintColor),
                      const SizedBox(width: 16),
                      Text('Invite pepole', style: Theme.of(context).textTheme.bodyLarge),
                    ],
                  ),
                ),
                const Divider(),

                // --- Contact Person 1 Fields ---
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text("Contact Person 1 (Primary)", style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                ),
                _buildInputRow(
                  context: context,
                  icon: Icons.person_outline,
                  label: 'Contact Name 1',
                  controller: _contactName1Controller,
                  validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                ),
                _buildInputRow(
                  context: context,
                  icon: Icons.phone_outlined,
                  label: 'Contact Phone 1',
                  controller: _contactPhone1Controller,
                  keyboardType: TextInputType.phone,
                  validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                ),
                const Divider(),

                // --- Contact Person 2 Fields ---
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text("Contact Person 2 (Secondary)", style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                ),
                _buildInputRow(
                  context: context,
                  icon: Icons.person_outline,
                  label: 'Contact Name 2',
                  controller: _contactName2Controller,
                ),
                _buildInputRow(
                  context: context,
                  icon: Icons.phone_outlined,
                  label: 'Contact Phone 2',
                  controller: _contactPhone2Controller,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper for text input rows
  Widget _buildInputRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(top: maxLines > 1 ? 14.0 : 0), // Align icon top for multiline
            child: Icon(icon, color: Theme.of(context).hintColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextFormField(
              controller: controller,
              decoration: InputDecoration(
                labelText: label,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero, // Remove extra padding
              ),
              maxLines: maxLines,
              keyboardType: keyboardType,
              validator: validator,
            ),
          ),
        ],
      ),
    );
  }

  // Helper for Image Picker row
  Widget _buildImagePickerRow(BuildContext context) {
    ImageProvider? imageProvider;
    if (_selectedImageFile != null) {
      imageProvider = FileImage(File(_selectedImageFile!.path));
    } else if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty) {
      imageProvider = CachedNetworkImageProvider(_currentImageUrl!);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.image_outlined, color: Theme.of(context).hintColor),
          const SizedBox(width: 16),
          Expanded(
            child: InkWell(
              onTap: _isSubmitting || _isUploadingImage ? null : _pickImage,
              child: Text(
                'Add cover photo',
                style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.8)
                ),
              ),
            ),
          ),
          // --- Image Preview / Upload Status ---
          if (_isUploadingImage)
            const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
          else if (imageProvider != null)
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: imageProvider,
                  ),
                  if (!_isEditMode && _currentImageUrl == null) // Show a small X for new image to delete
                    Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _selectedImageFile = null;
                            _currentImageUrl = null;
                          }),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.close, size: 12, color: Colors.white),
                          ),
                        )
                    )
                ],
              ),
            )
        ],
      ),
    );
  }

  // Helper for Date Time Picker row
  Widget _buildDateTimeRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: InkWell(
        onTap: _isSubmitting ? null : _pickDateTime,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_outlined, color: Theme.of(context).hintColor),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                _selectedDateTime == null
                    ? 'Date and time'
                    : DateFormat('E, MMM d, yyyy • hh:mm a').format(_selectedDateTime!),
                style: TextStyle(
                    fontSize: 16,
                    color: _selectedDateTime == null
                        ? Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.8)
                        : Theme.of(context).textTheme.bodyLarge?.color
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}