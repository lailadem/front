import 'package:flutter/material.dart';
import 'package:psychology_support_platform/models/content.dart';
import 'package:psychology_support_platform/services/api_service.dart';

class AdminContentScreen extends StatefulWidget {
  const AdminContentScreen({super.key});

  @override
  State<AdminContentScreen> createState() => _AdminContentScreenState();
}

class _AdminContentScreenState extends State<AdminContentScreen> {
  late Future<List<Content>> _contentFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  void _loadContent() {
    setState(() {
      _contentFuture = _fetchContent();
    });
  }

  Future<List<Content>> _fetchContent() async {
    final result = await _apiService.adminGetContent();
    if (result['success']) {
      final dynamic data = result['data'];
      // The actual content list is nested inside the paginated response
      if (data != null &&
          data['contents'] != null &&
          data['contents']['data'] is List) {
        final contentsList = (data['contents']['data'] as List)
            .map((item) => Content.fromJson(item))
            .toList();
        return contentsList;
      }
      return [];
    } else {
      throw Exception('Failed to load content: ${result['message']}');
    }
  }

  Future<void> _deleteContent(int contentId) async {
    // Use the new admin-specific API endpoint
    final result = await _apiService.adminDeleteContent(contentId);
    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Content deleted successfully'),
            backgroundColor: Colors.green),
      );
      _loadContent(); // Refresh the list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error: ${result['message']}'),
            backgroundColor: Colors.red),
      );
    }
  }

  void _showDeleteConfirmation(Content content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Content?'),
          content: Text('Are you sure you want to delete "${content.title}"?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteContent(content.id);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Content>>(
      future: _contentFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
              child: Text('Error loading content: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No content found.'));
        }

        final contents = snapshot.data!;
        return RefreshIndicator(
          onRefresh: () async => _loadContent(),
          child: ListView.builder(
            itemCount: contents.length,
            itemBuilder: (context, index) {
              final content = contents[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  title: Text(content.title),
                  subtitle: Text(
                      'Type: ${content.type} - By Professional ID: ${content.professionalId}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _showDeleteConfirmation(content),
                    tooltip: 'Delete Content',
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
