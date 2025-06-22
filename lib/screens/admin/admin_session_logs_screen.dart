import 'package:flutter/material.dart';
import 'package:psychology_support_platform/services/api_service.dart';

class AdminSessionLogsScreen extends StatefulWidget {
  const AdminSessionLogsScreen({super.key});

  @override
  State<AdminSessionLogsScreen> createState() => _AdminSessionLogsScreenState();
}

class _AdminSessionLogsScreenState extends State<AdminSessionLogsScreen> {
  late Future<List<dynamic>> _logsFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  void _loadLogs() {
    setState(() {
      _logsFuture = _fetchLogs();
    });
  }

  Future<List<dynamic>> _fetchLogs() async {
    final result = await _apiService.getSessionLogs();
    if (result['success']) {
      final dynamic data = result['data'];
      if (data is Map<String, dynamic>) {
        // Look for the list within the returned map
        final logsList = data['data'] ?? data['logs'] ?? data['session_logs'];
        if (logsList is List) {
          return logsList;
        }
      } else if (data is List) {
        // If the API returns a direct list
        return data;
      }
      return []; // Return empty list if no logs are found
    } else {
      throw Exception('Failed to load session logs: ${result['message']}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _logsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading logs: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No session logs found.'));
        }

        final logs = snapshot.data!;
        return RefreshIndicator(
          onRefresh: () async => _loadLogs(),
          child: ListView.builder(
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index] as Map<String, dynamic>;
              final sessionId = log['id'] ?? 'N/A';
              final clientName = log['client']?['name'] ?? 'N/A';
              final profName = log['professional']?['name'] ?? 'N/A';
              final status = log['status'] ?? 'N/A';
              final date = log['scheduled_at'] ?? 'N/A';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  title: Text('Session #$sessionId - $status'),
                  subtitle:
                      Text('Client: $clientName\nPro: $profName\nDate: $date'),
                  isThreeLine: true,
                ),
              );
            },
          ),
        );
      },
    );
  }
}
