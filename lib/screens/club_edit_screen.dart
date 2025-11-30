import 'dart:io';
import 'package:connectedu_app/bloc/club_list_bloc.dart';
import 'package:connectedu_app/models/club.dart';
import 'package:connectedu_app/services/api_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

class ClubEditScreen extends StatefulWidget {
  final Club? club;

  const ClubEditScreen({super.key, this.club});

  @override
  State<ClubEditScreen> createState() => _ClubEditScreenState();
}

class _ClubEditScreenState extends State<ClubEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _adminEmailController;

  // --- CATEGORY STATE ---
  String _selectedCategory = 'ALL';
  final List<String> _categories = ['ALL', 'CODING', 'SPORTS', 'CULTURAL', 'TECHNICAL', 'ARTS'];
  // ---------------------

  bool _isSubmitting = false;

  // State for image upload
  XFile? _selectedImageFile;
  String? _currentImageUrl;
  bool _isUploadingImage = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.club?.name ?? '');
    _descriptionController = TextEditingController(text: widget.club?.description ?? '');
    _adminEmailController = TextEditingController();

    // --- INIT CATEGORY ---
    _selectedCategory = widget.club?.category ?? 'ALL';
    // Ensure the category from DB exists in our list, otherwise default to ALL
    if (widget.club != null && widget.club!.category.isNotEmpty) {
      if (_categories.contains(widget.club!.category)) {
        _selectedCategory = widget.club!.category;
      }
    }
    // ---------------------

    _currentImageUrl = widget.club?.logoUrl;
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
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (image != null) {
        final fileSize = await image.length();
        if (fileSize > (10 * 1024 * 1024)) {
          if(mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image too large. Please select a file under 10MB.'), backgroundColor: Colors.orange),
            );
          }
          return;
        }

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

  // --- IMAGE UPLOAD LOGIC ---
  Future<String?> _uploadImage(XFile image) async {
    setState(() { _isUploadingImage = true; });
    String? uploadedUrl;
    try {
      final apiService = context.read<ApiService>();
      String fileName = image.path.split('/').last;
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(image.path, filename: fileName),
      });

      debugPrint('Uploading image...');
      final response = await apiService.dio.post(
        '/api/uploads',
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

      String? finalImageUrl = _currentImageUrl;

      if (_selectedImageFile != null) {
        final uploadedUrl = await _uploadImage(_selectedImageFile!);
        if (uploadedUrl == null) {
          if(mounted) setState(() { _isSubmitting = false; });
          return;
        }
        finalImageUrl = uploadedUrl;
        _selectedImageFile = null;
      }

      final name = _nameController.text;
      final description = _descriptionController.text;
      final adminEmail = _adminEmailController.text;

      final isEditMode = widget.club != null;
      if (!isEditMode && adminEmail.isEmpty) {
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

      try {
        if (!isEditMode) {
          // Create Mode
          context.read<ClubListBloc>().add(CreateClub(
            name: name,
            description: description,
            adminEmail: adminEmail,
            logoUrl: finalImageUrl,
            // --- PASS CATEGORY ---
            category: _selectedCategory,
          ));
        } else {
          // Edit Mode
          context.read<ClubListBloc>().add(UpdateClub(
            clubId: widget.club!.id,
            name: name,
            description: description,
            adminEmail: adminEmail.isNotEmpty ? adminEmail : '',
            logoUrl: finalImageUrl,
            // --- PASS CATEGORY ---
            category: _selectedCategory,
          ));
        }
      } catch (e) {
        if (mounted) setState(() { _isSubmitting = false; });
        debugPrint("Error dispatching club action: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } else {
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
      body: BlocListener<ClubListBloc, ClubListState>(
        listener: (context, state) {
          if (state is ClubActionSuccess || state is ClubActionFailure) {
            if (mounted && _isSubmitting) {
              setState(() { _isSubmitting = false; });
            }
          }

          if (state is ClubActionSuccess) {
            ScaffoldMessenger.of(context).removeCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.green),
            );
            if (Navigator.canPop(context)) {
              Navigator.of(context).pop(true);
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
                            backgroundImage: _selectedImageFile != null
                                ? FileImage(File(_selectedImageFile!.path))
                                : (_currentImageUrl != null && _currentImageUrl!.isNotEmpty
                                ? NetworkImage(_currentImageUrl!)
                                : null) as ImageProvider?,
                            child: (_selectedImageFile == null && (_currentImageUrl == null || _currentImageUrl!.isEmpty))
                                ? Icon(Icons.group_add_outlined, size: 50, color: Theme.of(context).colorScheme.onSecondaryContainer.withOpacity(0.7))
                                : null,
                          ),
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

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Club Name', border: OutlineInputBorder()),
                  validator: (value) => value == null || value.isEmpty ? 'Please enter a name' : null,
                ),
                const SizedBox(height: 16),

                // --- CATEGORY DROPDOWN ---
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Club Category',
                    border: OutlineInputBorder(),
                  ),
                  items: _categories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCategory = newValue!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                // --------------------------

                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder(), alignLabelWithHint: true),
                  maxLines: 3,
                  validator: (value) => value == null || value.isEmpty ? 'Please enter a description' : null,
                ),
                const SizedBox(height: 16),

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
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                _isSubmitting
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                  icon: Icon(isEditMode ? Icons.save_alt_outlined : Icons.add_circle_outline),
                  label: Text(isEditMode ? 'Save Changes' : 'Create Club'),
                  onPressed: _submitForm,
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