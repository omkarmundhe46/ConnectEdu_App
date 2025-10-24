import 'dart:io'; // For File type
import 'package:connectedu_app/bloc/club_list_bloc.dart';
import 'package:connectedu_app/models/club.dart';
import 'package:connectedu_app/services/api_service.dart'; // For direct upload
import 'package:dio/dio.dart'; // Import Dio for FormData
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart'; // Import image_picker

class ClubEditScreen extends StatefulWidget {
  final Club? club; // If club is null, it's 'Create' mode, otherwise 'Edit' mode

  const ClubEditScreen({super.key, this.club});

  @override
  State<ClubEditScreen> createState() => _ClubEditScreenState();
}

class _ClubEditScreenState extends State<ClubEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _adminEmailController; // Changed from ID to Email
  bool _isSubmitting = false; // Renamed from _isLoading for clarity

  // State for image upload
  XFile? _selectedImageFile; // Stores the selected file from picker
  String? _currentImageUrl; // Stores existing or newly uploaded URL
  bool _isUploadingImage = false;
  final ImagePicker _picker = ImagePicker(); // Instance of image picker

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.club?.name ?? '');
    _descriptionController = TextEditingController(text: widget.club?.description ?? '');
    // For admin email, leave blank in create mode. Fetch in edit mode if needed (more complex).
    _adminEmailController = TextEditingController();
    _currentImageUrl = widget.club?.logoUrl; // Pre-fill image URL if editing
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _adminEmailController.dispose();
    super.dispose();
  }

  // --- IMAGE PICKER LOGIC ---
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70); // Added imageQuality
      if (image != null) {
        // Optional: Check file size before proceeding
        final fileSize = await image.length();
        if (fileSize > (10 * 1024 * 1024)) { // Example: 10MB limit
          if(mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image too large. Please select a file under 10MB.'), backgroundColor: Colors.orange),
            );
          }
          return;
        }

        setState(() {
          _selectedImageFile = image;
          _currentImageUrl = null; // Clear previous URL when new image is picked
        });
        // You could upload immediately here, or wait until the form is submitted
        // await _uploadImage(image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- IMAGE UPLOAD LOGIC ---
  // Returns the S3 URL on success, null on failure
  Future<String?> _uploadImage(XFile image) async {
    setState(() { _isUploadingImage = true; });
    String? uploadedUrl;
    try {
      final apiService = context.read<ApiService>();
      String fileName = image.path.split('/').last;
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(image.path, filename: fileName),
        // "messageType": "IMAGE", // Using IMAGE type for logos/banners
      });

      debugPrint('Uploading image...');
      // IMPORTANT: Using the discussion service endpoint as a placeholder.
      // Replace '1', '1' with valid IDs or create a generic upload endpoint.
      // --- THIS IS THE FIX ---
      // Call the new, correct upload endpoint
      final response = await apiService.dio.post(
        '/api/uploads', // Use the new endpoint via the Gateway
        data: formData,
        onSendProgress: (int sent, int total) {
          debugPrint('Upload progress: ${(sent / total * 100).toStringAsFixed(0)}%');
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        uploadedUrl = response.data['fileUrl'];
        debugPrint('Image uploaded successfully: $uploadedUrl');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Logo uploaded successfully!'), backgroundColor: Colors.green, duration: Duration(seconds: 2)),
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


  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _isSubmitting = true; });

      String? finalImageUrl = _currentImageUrl; // Start with existing or previously uploaded URL

      // Upload image IF a new one was selected
      if (_selectedImageFile != null) {
        final uploadedUrl = await _uploadImage(_selectedImageFile!);
        if (uploadedUrl == null) {
          // Handle upload failure before submitting club data
          if(mounted) setState(() { _isSubmitting = false; });
          return; // Stop submission if upload fails
        }
        finalImageUrl = uploadedUrl; // Use the newly uploaded URL
        _selectedImageFile = null; // Clear the selection after successful upload
      }

      final name = _nameController.text;
      final description = _descriptionController.text;
      final adminEmail = _adminEmailController.text;

      // Email validation
      final isEditMode = widget.club != null;
      if (!isEditMode && adminEmail.isEmpty) { // Required for create
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin Email is required to create a club.'), backgroundColor: Colors.red),
        );
        if(mounted) setState(() { _isSubmitting = false; });
        return;
      }
      if (adminEmail.isNotEmpty && !RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(adminEmail)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid Admin Email format.'), backgroundColor: Colors.red),
        );
        if(mounted) setState(() { _isSubmitting = false; });
        return;
      }

      // Dispatch event to BLoC
      try {
        if (!isEditMode) {
          // Create Mode
          context.read<ClubListBloc>().add(CreateClub(
              name: name,
              description: description,
              adminEmail: adminEmail, // Must provide email for creation
              logoUrl: finalImageUrl
          ));
        } else {
          // Edit Mode
          context.read<ClubListBloc>().add(UpdateClub(
            clubId: widget.club!.id,
            name: name,
            description: description,
            // Only send adminEmail if it was entered, otherwise backend keeps old one
            adminEmail: adminEmail.isNotEmpty ? adminEmail : '',
            logoUrl: finalImageUrl,
          ));
        }
        // Listener will handle navigation on success/failure
      } catch (e) {
        // BLoC error handling should manage this, but we stop loading
        if (mounted) setState(() { _isSubmitting = false; });
        debugPrint("Error dispatching club action: $e");
        ScaffoldMessenger.of(context).showSnackBar( // Show error if dispatch fails instantly
          SnackBar(content: Text('Failed to submit: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } else {
      // Form validation failed
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please correct the errors in the form.'), backgroundColor: Colors.orange),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.club != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Club' : 'Create Club'),
      ),
      // Use BlocListener for feedback and navigation *after* state changes
      body: BlocListener<ClubListBloc, ClubListState>(
        listener: (context, state) {
          // Stop loading indicator when an action completes (success or fail)
          if (state is ClubActionSuccess || state is ClubActionFailure) {
            if (mounted && _isSubmitting) { // Check if we were submitting
              setState(() { _isSubmitting = false; });
            }
          }

          if (state is ClubActionSuccess) {
            ScaffoldMessenger.of(context).removeCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.green),
            );
            if (Navigator.canPop(context)) {
              Navigator.of(context).pop(true); // Go back after success
            }
          } else if (state is ClubActionFailure) {
            ScaffoldMessenger.of(context).removeCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${state.error}'), backgroundColor: Colors.red, duration: const Duration(seconds: 3)),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- LOGO UPLOAD SECTION ---
                Center(
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                            // Display logic: Selected file > Current URL > Placeholder
                            backgroundImage: _selectedImageFile != null
                                ? FileImage(File(_selectedImageFile!.path))
                                : (_currentImageUrl != null && _currentImageUrl!.isNotEmpty
                                ? NetworkImage(_currentImageUrl!)
                                : null) as ImageProvider?,
                            child: (_selectedImageFile == null && (_currentImageUrl == null || _currentImageUrl!.isEmpty))
                                ? Icon(Icons.group_add_outlined, size: 50, color: Theme.of(context).colorScheme.onSecondaryContainer.withOpacity(0.7))
                                : null,
                          ),
                          // Show loading indicator during upload
                          if (_isUploadingImage) const CircularProgressIndicator(),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        icon: Icon(_isUploadingImage ? Icons.hourglass_top : Icons.image_search_outlined),
                        label: Text(_selectedImageFile != null || (_currentImageUrl != null && _currentImageUrl!.isNotEmpty) ? 'Change Logo' : 'Select Logo'),
                        onPressed: _isUploadingImage ? null : _pickImage,
                      ),
                      if (_isUploadingImage) const Text('Uploading... Please wait.'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // --- END LOGO UPLOAD ---

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Club Name', border: OutlineInputBorder()),
                  validator: (value) => value == null || value.isEmpty ? 'Please enter a name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder(), alignLabelWithHint: true),
                  maxLines: 3,
                  validator: (value) => value == null || value.isEmpty ? 'Please enter a description' : null,
                ),
                const SizedBox(height: 16),
                // --- ADMIN EMAIL FIELD ---
                TextFormField(
                  controller: _adminEmailController,
                  decoration: InputDecoration(
                    labelText: 'Assign Admin Email',
                    hintText: isEditMode ? 'Enter email to change admin (optional)' : 'Enter the email of the Club Admin',
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (!isEditMode && (value == null || value.isEmpty)) {
                      return 'Please enter an Admin Email';
                    }
                    if (value != null && value.isNotEmpty && !RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) {
                      return 'Please enter a valid email format';
                    }
                    return null; // Null means valid
                  },
                ),
                // --- END ADMIN EMAIL FIELD ---
                const SizedBox(height: 32),
                _isSubmitting
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                  icon: Icon(isEditMode ? Icons.save_alt_outlined : Icons.add_circle_outline),
                  label: Text(isEditMode ? 'Save Changes' : 'Create Club'),
                  onPressed: _submitForm, // Calls the updated async submit method
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

