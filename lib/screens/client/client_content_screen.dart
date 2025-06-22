import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/content_provider.dart';
import '../../models/content.dart';
import '../../utils/constants.dart';
import 'client_content_detail_screen.dart';

class ClientContentScreen extends StatefulWidget {
  const ClientContentScreen({super.key});

  @override
  State<ClientContentScreen> createState() => _ClientContentScreenState();
}

class _ClientContentScreenState extends State<ClientContentScreen> {
  final _searchController = TextEditingController();
  String? _selectedCategory;
  String? _selectedType;
  bool _isLoading = false;

  final List<String> _categories = [
    'All',
    'Anxiety',
    'Depression',
    'Stress',
    'Uncategorized'
  ];
  final List<String> _contentTypes = ['All', 'Article', 'Video', 'PDF'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadContent();
    });
  }

  Future<void> _loadContent() async {
    setState(() {
      _isLoading = true;
    });

    final provider = Provider.of<ContentProvider>(context, listen: false);
    String? category;
    String? type;

    if (_selectedCategory != null && _selectedCategory != 'All') {
      category = _selectedCategory;
    }

    if (_selectedType != null && _selectedType != 'All') {
      type = _selectedType!.toLowerCase();
    }

    await provider.fetchUserContent(category: category, type: type);
    setState(() {
      _isLoading = false;
    });
  }

  void _performSearch() {
    // TODO: Implement search functionality
    _loadContent();
  }

  @override
  Widget build(BuildContext context) {
    final contentProvider = Provider.of<ContentProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mental Health Content'),
        backgroundColor: AppColors.primaryBlue,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: ContentSearchDelegate(contentProvider.contents),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          Container(
            color: AppColors.lightGray,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory ?? 'All',
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                        items: _categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value;
                          });
                          _loadContent();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedType ?? 'All',
                        decoration: const InputDecoration(
                          labelText: 'Type',
                          border: OutlineInputBorder(),
                        ),
                        items: _contentTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedType = value;
                          });
                          _loadContent();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Content List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : contentProvider.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading content',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.red[300],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                contentProvider.error!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.red[300],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadContent,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : contentProvider.contents.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.article_outlined,
                                  size: 64,
                                  color: AppColors.lightGray,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No content available',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: AppColors.lightGray,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Try adjusting your filters or check back later',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.lightGray,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadContent,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: contentProvider.contents.length,
                              itemBuilder: (context, index) {
                                final content = contentProvider.contents[index];
                                return _ContentCard(content: content);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _ContentCard extends StatelessWidget {
  final Content content;

  const _ContentCard({required this.content});

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
        trailing:
            const Icon(Icons.arrow_forward_ios, color: AppColors.primaryBlue),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ClientContentDetailScreen(content: content),
            ),
          );
        },
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

class ContentSearchDelegate extends SearchDelegate<String> {
  final List<Content> contents;

  ContentSearchDelegate(this.contents);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final filteredContents = contents.where((content) {
      return content.title.toLowerCase().contains(query.toLowerCase()) ||
          content.description.toLowerCase().contains(query.toLowerCase());
    }).toList();

    if (filteredContents.isEmpty) {
      return const Center(
        child: Text('No content found.'),
      );
    }

    return ListView.builder(
      itemCount: filteredContents.length,
      itemBuilder: (context, index) {
        final content = filteredContents[index];
        return ListTile(
          title: Text(content.title),
          subtitle: Text(content.description),
          onTap: () {
            close(context, content.title);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ClientContentDetailScreen(content: content),
              ),
            );
          },
        );
      },
    );
  }
}
