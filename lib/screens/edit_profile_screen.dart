
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectedu_app/bloc/auth_bloc.dart';
import 'package:connectedu_app/models/user.dart';
import 'package:connectedu_app/services/api_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  final User user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _phoneController;
  final ImagePicker _picker = ImagePicker();

  XFile? _selectedImageFile;
  String? _currentImageUrl;
  bool _isUploading = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.user.phone ?? '');
    _currentImageUrl = widget.user.profileImageUrl;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (image != null) {
        setState(() {
          _selectedImageFile = image;
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

  Future<String?> _uploadImage(XFile image) async {
    setState(() {
      _isUploading = true;
    });
    String? uploadedUrl;
    try {
      final apiService = context.read<ApiService>();
      String fileName = image.path.split('/').last;
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(image.path, filename: fileName),
      });

      final response = await apiService.dio.post('/api/uploads', data: formData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        uploadedUrl = response.data['fileUrl'];
        debugPrint('Image uploaded successfully: $uploadedUrl');
      } else {
        throw Exception('Failed to upload image: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Image upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image upload failed: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
    return uploadedUrl;
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    String? finalImageUrl = _currentImageUrl;

    // 1. If a new image was selected, upload it
    if (_selectedImageFile != null) {
      final uploadedUrl = await _uploadImage(_selectedImageFile!);
      if (uploadedUrl == null) {
        // Upload failed
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
        return; // Stop submission
      }
      finalImageUrl = uploadedUrl; // Use the new URL
    }

    // 2. Dispatch the event to the AuthBloc
    if (mounted) {
      context.read<AuthBloc>().add(
        ProfileUpdated(
          phone: _phoneController.text,
          profileImageUrl: finalImageUrl,
        ),
      );
    }
  }


  Widget _getProfilePlaceholder(BuildContext context) {
    return Icon(
      Icons.person,
      size: 50,
      color: Theme.of(context).colorScheme.onSecondaryContainer.withOpacity(0.7),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthUpdateSuccess) {
            // On success, stop loading and pop the screen
            setState(() {
              _isSubmitting = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green),
            );
            Navigator.of(context).pop();
          }
          if (state is AuthUpdateFailure) {
            // On failure, stop loading and show error
            setState(() {
              _isSubmitting = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${state.error}'), backgroundColor: Colors.red),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: theme.colorScheme.secondaryContainer,
                        backgroundImage: _selectedImageFile != null
                            ? FileImage(File(_selectedImageFile!.path))
                            : (_currentImageUrl != null && _currentImageUrl!.isNotEmpty)
                            ? CachedNetworkImageProvider(_currentImageUrl!)
                            : null as ImageProvider?,
                        child: (_selectedImageFile == null && (_currentImageUrl == null || _currentImageUrl!.isEmpty))
                            ? _getProfilePlaceholder(context)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: _pickImage,
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: theme.colorScheme.primary,
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: 'e.g. 1234567890',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Phone number is required';
                    }
                    if (value.length != 10) {
                      return 'Must be 10 digits';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                (_isSubmitting || _isUploading)
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                  onPressed: _submitProfile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}