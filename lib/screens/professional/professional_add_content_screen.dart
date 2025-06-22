import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';

class ProfessionalAddContentScreen extends StatefulWidget {
  const ProfessionalAddContentScreen({super.key});

  @override
  State<ProfessionalAddContentScreen> createState() => _ProfessionalAddContentScreenState();
}

class _ProfessionalAddContentScreenState extends State<ProfessionalAddContentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedType = AppConstants.contentTypeArticle;
  int _selectedContentTypeId = 1;
  String? _filePath;
  bool _isLoading = false;
  String? _error;

  final List<Map<String, dynamic>> _contentTypes = [
    {'id': 1, 'name': 'Article'},
    {'id': 2, 'name': 'Video'},
    {'id': 3, 'name': 'PDF'},
  ];

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'mp4', 'avi', 'mov'],
    );

    if (result != null) {
      setState(() {
        _filePath = result.files.single.path;
      });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final result = await ApiService().addContent(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        contentTypeId: _selectedContentTypeId,
        type: _selectedType,
        filePath: _filePath,
      );

      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
      } else {
        setState(() {
          _error = result['message'];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Content'),
        backgroundColor: AppColors.primaryBlue,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Content Type',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: AppConstants.contentTypeArticle,
                          child: const Text('Article'),
                        ),
                        DropdownMenuItem(
                          value: AppConstants.contentTypeVideo,
                          child: const Text('Video'),
                        ),
                        DropdownMenuItem(
                          value: AppConstants.contentTypePDF,
                          child: const Text('PDF'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedType = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: _selectedContentTypeId,
                      decoration: const InputDecoration(
                        labelText: 'Content Category',
                        border: OutlineInputBorder(),
                      ),
                      items: _contentTypes.map((type) {
                        return DropdownMenuItem<int>(
                          value: type['id'] as int,
                          child: Text(type['name'] as String),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedContentTypeId = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Card(
                      color: AppColors.lightGray,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'File Upload (Optional)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Upload a file to accompany your content. Supported formats: PDF, DOC, DOCX, MP4, AVI, MOV',
                              style: TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _pickFile,
                                    icon: const Icon(Icons.upload_file),
                                    label: const Text('Choose File'),
                                  ),
                                ),
                                if (_filePath != null) ...[
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _filePath!.split('/').last,
                                      style: const TextStyle(fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: const TextStyle(color: AppColors.errorRed),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Add Content'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
} 