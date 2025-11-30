import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectedu_app/models/certificate_template.dart';
import 'package:connectedu_app/repositories/certificate-service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CertificateConfigScreen extends StatefulWidget {
  final int eventId;
  final String clubCategory;
  const CertificateConfigScreen({super.key, required this.eventId, required this.clubCategory});

  @override
  State<CertificateConfigScreen> createState() => _CertificateConfigScreenState();
}

class _CertificateConfigScreenState extends State<CertificateConfigScreen> {
  List<CertificateTemplate> _templates = [];
  String? _selectedTemplateId;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final repo = context.read<CertificateRepository>();
    try {
      // 1. Load Templates
      final templates = await repo.getTemplates(widget.clubCategory);

      // 2. Load Existing Config
      final config = await repo.getConfig(widget.eventId);

      if (mounted) {
        setState(() {
          _templates = templates;
          if (config != null) {
            _selectedTemplateId = config.templateType;
          } else if (templates.isNotEmpty) {
            // Default to first template
            _selectedTemplateId = templates.first.name;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if(mounted) setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
    }
  }

  Future<void> _save() async {
    if (_selectedTemplateId == null) return;

    setState(() => _isSaving = true);

    try {
      // Call repo to save the template ID
      await context.read<CertificateRepository>().saveConfig(widget.eventId, _selectedTemplateId!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Configuration Saved!'), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Design Certificate')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Select Template Style", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text("Signatures and logos are pre-configured in these templates.", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),

            // Template Grid/Carousel
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 1, // One column (vertical scrolling list)
                  childAspectRatio: 1.4, // Landscape aspect ratio
                  mainAxisSpacing: 16,
                ),
                itemCount: _templates.length,
                itemBuilder: (context, index) {
                  final temp = _templates[index];
                  final isSelected = temp.name == _selectedTemplateId;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedTemplateId = temp.name),
                    child: Container(
                      decoration: BoxDecoration(
                        border: isSelected ? Border.all(color: Theme.of(context).primaryColor, width: 4) : Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                              child: CachedNetworkImage(
                                imageUrl: temp.previewUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                placeholder: (c, u) => Container(color: Colors.grey[200], child: const Center(child: CircularProgressIndicator())),
                                errorWidget: (c, u, e) => const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                              ),
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            color: isSelected ? Theme.of(context).primaryColor : Colors.grey[100],
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  temp.displayName,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.black87,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                if (isSelected) const Icon(Icons.check_circle, color: Colors.white),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                child: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text("Save Configuration", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}