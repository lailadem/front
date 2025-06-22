import 'package:flutter/material.dart';
import 'package:psychology_support_platform/models/user.dart';
import 'package:psychology_support_platform/services/api_service.dart';

class AdminApprovalsScreen extends StatefulWidget {
  const AdminApprovalsScreen({super.key});

  @override
  State<AdminApprovalsScreen> createState() => _AdminApprovalsScreenState();
}

class _AdminApprovalsScreenState extends State<AdminApprovalsScreen> {
  late Future<List<User>> _pendingUsersFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadPendingUsers();
  }

  void _loadPendingUsers() {
    setState(() {
      _pendingUsersFuture = _fetchPendingUsers();
    });
  }

  Future<List<User>> _fetchPendingUsers() async {
    final result = await _apiService.getPendingUsers();
    if (result['success']) {
      final dynamic data = result['data'];
      List<dynamic> rawUserList = [];

      // Handle cases where the list might be nested inside the response
      if (data is Map<String, dynamic>) {
        rawUserList = data['data'] ?? data['users'] ?? [];
      } else if (data is List) {
        rawUserList = data;
      }

      if (rawUserList.isNotEmpty) {
        return rawUserList
            .map((e) => User.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      return []; // Return empty list if data is not what we expect
    } else {
      throw Exception('Failed to load pending users: ${result['message']}');
    }
  }

  Future<void> _approveUser(int userId) async {
    final result = await _apiService.approveUser(userId);
    _handleApiResponse(result, 'User approved successfully');
  }

  Future<void> _rejectUser(int userId) async {
    final result = await _apiService.rejectUser(userId);
    _handleApiResponse(result, 'User rejected successfully');
  }

  void _handleApiResponse(Map<String, dynamic> result, String successMessage) {
    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage), backgroundColor: Colors.green),
      );
      _loadPendingUsers(); // Refresh the list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error: ${result['message']}'),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<User>>(
      future: _pendingUsersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
              child:
                  Text('Error loading pending approvals: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
              child: Text('No pending specialist approvals found.'));
        }

        final pendingUsers = snapshot.data!;
        return RefreshIndicator(
          onRefresh: () async => _loadPendingUsers(),
          child: ListView.builder(
            itemCount: pendingUsers.length,
            itemBuilder: (context, index) {
              final user = pendingUsers[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  title: Text(user.name),
                  subtitle: Text(user.email),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon:
                            const Icon(Icons.check_circle, color: Colors.green),
                        onPressed: () => _approveUser(user.id),
                        tooltip: 'Approve',
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () => _rejectUser(user.id),
                        tooltip: 'Reject',
                      ),
                    ],
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
