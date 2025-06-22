import 'package:flutter/material.dart';
import '../../models/content.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import 'professional_add_content_screen.dart';

class ProfessionalContentScreen extends StatefulWidget {
  const ProfessionalContentScreen({super.key});

  @override
  State<ProfessionalContentScreen> createState() =>
      _ProfessionalContentScreenState();
}

class _ProfessionalContentScreenState extends State<ProfessionalContentScreen> {
  List<Content> _contents = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await ApiService().getProfessionalContent();

    if (result['success']) {
      setState(() {
        _contents = List<Content>.from(result['contents'] ?? []);
      });
    } else {
      setState(() {
        _error = result['message'];
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _deleteContent(Content content) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Content'),
        content: Text('Are you sure you want to delete "${content.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.errorRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      final result = await ApiService().deleteContent(content.id);

      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        _loadContent();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Content'),
        backgroundColor: AppColors.primaryBlue,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Content',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ProfessionalAddContentScreen()),
              );
              if (result == true) {
                _loadContent();
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _contents.isEmpty
              ? const Center(
                  child: Text('No content available.'),
                )
              : RefreshIndicator(
                  onRefresh: _loadContent,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _contents.length,
                    itemBuilder: (context, index) {
                      final content = _contents[index];
                      return _ContentCard(
                        content: content,
                        onDelete: () => _deleteContent(content),
                      );
                    },
                  ),
                ),
    );
  }
}

class _ContentCard extends StatelessWidget {
  final Content content;
  final VoidCallback onDelete;

  const _ContentCard({required this.content, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.lightBlue,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: _getContentIcon(),
        title: Text(
          content.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              content.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: Text(content.type.toUpperCase()),
                  backgroundColor: AppColors.primaryBlue,
                  labelStyle:
                      const TextStyle(color: Colors.white, fontSize: 12),
                ),
                if (content.categories.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(content.categories.first.name),
                    backgroundColor: AppColors.lightPurple,
                    labelStyle: const TextStyle(
                        color: AppColors.primaryBlue, fontSize: 12),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                // TODO: Navigate to edit content screen
                break;
              case 'delete':
                onDelete();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, color: AppColors.primaryBlue),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: AppColors.errorRed),
                  SizedBox(width: 8),
                  Text('Delete'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getContentIcon() {
    switch (content.type.toLowerCase()) {
      case 'article':
        return const Icon(Icons.article,
            color: AppColors.primaryBlue, size: 32);
      case 'video':
        return const Icon(Icons.video_library,
            color: AppColors.primaryBlue, size: 32);
      case 'pdf':
        return const Icon(Icons.picture_as_pdf,
            color: AppColors.primaryBlue, size: 32);
      default:
        return const Icon(Icons.description,
            color: AppColors.primaryBlue, size: 32);
    }
  }
}
