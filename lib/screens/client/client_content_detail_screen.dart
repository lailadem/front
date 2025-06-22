import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/content.dart';
import '../../utils/constants.dart';

class ClientContentDetailScreen extends StatelessWidget {
  final Content content;

  const ClientContentDetailScreen({super.key, required this.content});

  Future<void> _openContent() async {
    if (content.filePath != null && content.filePath!.isNotEmpty) {
      final url = Uri.parse(content.filePath!);
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        // Handle error
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Content Details'),
        backgroundColor: AppColors.primaryBlue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: AppColors.lightBlue,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _getContentIcon(),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                content.title,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Chip(
                                label: Text(content.type.toUpperCase()),
                                backgroundColor: AppColors.primaryBlue,
                                labelStyle: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      content.description,
                      style: const TextStyle(fontSize: 16),
                    ),
                    if (content.categories.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        children: content.categories.map((category) {
                          return Chip(
                            label: Text(category.name),
                            backgroundColor: AppColors.lightPurple,
                            labelStyle: const TextStyle(color: AppColors.primaryBlue),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      'Published: ${content.createdAt.split('T')[0]}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (content.filePath != null && content.filePath!.isNotEmpty) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _openContent,
                  icon: const Icon(Icons.open_in_new),
                  label: Text('Open ${content.type}'),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Card(
              color: AppColors.lightGray,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'About this content:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This ${content.type.toLowerCase()} is designed to help you with your mental health journey. '
                      'Take your time to read or watch the content, and feel free to revisit it whenever you need support.',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
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
        return const Icon(Icons.article, color: AppColors.primaryBlue, size: 48);
      case 'video':
        return const Icon(Icons.video_library, color: AppColors.primaryBlue, size: 48);
      case 'pdf':
        return const Icon(Icons.picture_as_pdf, color: AppColors.primaryBlue, size: 48);
      default:
        return const Icon(Icons.description, color: AppColors.primaryBlue, size: 48);
    }
  }
} 