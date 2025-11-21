import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectedu_app/models/banner_model.dart';
import 'package:connectedu_app/repositories/banner_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

class ManageBannersScreen extends StatefulWidget {
  final int? clubId; // If null, it's College Admin mode

  const ManageBannersScreen({super.key, this.clubId});

  @override
  State<ManageBannersScreen> createState() => _ManageBannersScreenState();
}

class _ManageBannersScreenState extends State<ManageBannersScreen> {
  late Future<List<BannerModel>> _bannersFuture;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _linkController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadBanners();
  }

  void _loadBanners() {
    setState(() {
      if (widget.clubId != null) {
        _bannersFuture = context.read<BannerRepository>().getClubBanners(widget.clubId!);
      } else {
        _bannersFuture = context.read<BannerRepository>().getCollegeBanners();
      }
    });
  }

  Future<void> _deleteBanner(int id) async {
    try {
      await context.read<BannerRepository>().deleteBanner(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Banner deleted'), backgroundColor: Colors.green));
        _loadBanners();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _showAddBannerDialog() async {
    _titleController.clear();
    _linkController.clear();
    _selectedImage = null;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Add New Banner'),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () async {
                        final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                        if (image != null) {
                          setStateDialog(() => _selectedImage = File(image.path));
                        }
                      },
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _selectedImage != null
                            ? Image.file(_selectedImage!, fit: BoxFit.cover)
                            : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [Icon(Icons.add_photo_alternate, size: 40), Text("Select Image")],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _linkController,
                      decoration: const InputDecoration(labelText: 'Link URL (Optional)', border: OutlineInputBorder()),
                    ),
                    if (_isUploading) const Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: _isUploading ? null : () async {
                  if (_formKey.currentState!.validate() && _selectedImage != null) {
                    setStateDialog(() => _isUploading = true);
                    try {
                      // 1. Upload Image
                      final imageUrl = await context.read<BannerRepository>().uploadBannerImage(_selectedImage!);

                      // 2. Create Banner
                      if (context.mounted) { // Check mounted for the *dialog's* context isn't easily possible, use parent context logic
                        await context.read<BannerRepository>().createBanner(
                          title: _titleController.text,
                          imageUrl: imageUrl,
                          linkUrl: _linkController.text.isEmpty ? null : _linkController.text,
                          clubId: widget.clubId,
                        );
                        Navigator.pop(context); // Close dialog
                        _loadBanners(); // Refresh list
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Banner added!'), backgroundColor: Colors.green));
                      }
                    } catch (e) {
                      print(e); // Handle error
                    } finally {
                      setStateDialog(() => _isUploading = false);
                    }
                  } else if (_selectedImage == null) {
                    // Show error for missing image
                  }
                },
                child: const Text('Upload'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Banners')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBannerDialog,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<BannerModel>>(
        future: _bannersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));

          final banners = snapshot.data ?? [];
          if (banners.isEmpty) return const Center(child: Text('No active banners.'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: banners.length,
            itemBuilder: (context, index) {
              final banner = banners[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 150,
                      width: double.infinity,
                      child: CachedNetworkImage(imageUrl: banner.imageUrl, fit: BoxFit.cover),
                    ),
                    ListTile(
                      title: Text(banner.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: banner.linkUrl != null ? Text(banner.linkUrl!, maxLines: 1, overflow: TextOverflow.ellipsis) : null,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteBanner(banner.id),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}