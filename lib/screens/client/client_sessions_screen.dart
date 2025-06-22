import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/session_provider.dart';
import '../../models/session.dart';
import '../../utils/constants.dart';
import 'client_book_session_screen.dart';
import 'client_session_detail_screen.dart';

class ClientSessionsScreen extends StatefulWidget {
  const ClientSessionsScreen({super.key});

  @override
  State<ClientSessionsScreen> createState() => _ClientSessionsScreenState();
}

class _ClientSessionsScreenState extends State<ClientSessionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SessionProvider>(context, listen: false)
          .fetchClientSessions();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionProvider = Provider.of<SessionProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Sessions'),
        backgroundColor: AppColors.primaryBlue,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.lightPurple,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Book Session',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ClientBookSessionScreen()),
              );
              if (result != null && result is Map<String, dynamic> && mounted) {
                Provider.of<SessionProvider>(context, listen: false)
                    .fetchClientSessions();
              }
            },
          ),
        ],
      ),
      body: sessionProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _SessionList(
                  sessions: sessionProvider.upcomingSessions,
                  isUpcoming: true,
                  onRefresh: sessionProvider.fetchClientSessions,
                ),
                _SessionList(
                  sessions: sessionProvider.pastSessions,
                  isUpcoming: false,
                  onRefresh: sessionProvider.fetchClientSessions,
                ),
              ],
            ),
    );
  }
}

class _SessionList extends StatelessWidget {
  final List<Session> sessions;
  final bool isUpcoming;
  final VoidCallback onRefresh;

  const _SessionList(
      {required this.sessions,
      required this.isUpcoming,
      required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return Center(
        child: Text(isUpcoming ? 'No upcoming sessions.' : 'No past sessions.'),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: sessions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final session = sessions[i];
          final sessionProvider =
              Provider.of<SessionProvider>(context, listen: false);

          return Card(
            color: AppColors.lightBlue,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    title: Text(
                      '${session.sessionType.toUpperCase()} with ${session.professional?.name ?? 'Specialist'}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                        'At: ${session.scheduledAt}\nStatus: ${session.status}'),
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ClientSessionDetailScreen(session: session),
                        ),
                      );
                      if (result == true) {
                        onRefresh();
                      }
                    },
                  ),
                  if (isUpcoming && session.status != 'cancelled')
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Confirm Cancellation'),
                                  content: const Text(
                                      'Are you sure you want to cancel this session?'),
                                  actions: [
                                    TextButton(
                                      child: const Text('No'),
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(false),
                                    ),
                                    TextButton(
                                      child: const Text('Yes, Cancel'),
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(true),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true && context.mounted) {
                                await sessionProvider.cancelSession(session.id);
                              }
                            },
                            child: const Text(
                              'Cancel Session',
                              style: TextStyle(color: AppColors.errorRed),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
