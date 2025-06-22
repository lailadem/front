import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/session.dart';
import '../../providers/session_provider.dart';
import '../../utils/constants.dart';
import '../chat_screen.dart';

class ProfessionalSessionsScreen extends StatefulWidget {
  const ProfessionalSessionsScreen({super.key});

  @override
  State<ProfessionalSessionsScreen> createState() =>
      _ProfessionalSessionsScreenState();
}

class _ProfessionalSessionsScreenState extends State<ProfessionalSessionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Use the provider to load sessions
    Future.microtask(() => Provider.of<SessionProvider>(context, listen: false)
        .fetchProfessionalSessions());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _joinSession(Session session) async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatScreen(session: session),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use Consumer to listen to changes in SessionProvider
    return Consumer<SessionProvider>(
      builder: (context, sessionProvider, child) {
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
          ),
          body: sessionProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : sessionProvider.error != null
                  ? Center(
                      child: Text('Error: ${sessionProvider.error}',
                          style: const TextStyle(color: Colors.red)))
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _SessionList(
                          sessions: sessionProvider.upcomingSessions,
                          onRefresh: () =>
                              sessionProvider.fetchProfessionalSessions(),
                          isUpcoming: true,
                          onJoin: _joinSession,
                        ),
                        _SessionList(
                          sessions: sessionProvider.pastSessions,
                          onRefresh: () =>
                              sessionProvider.fetchProfessionalSessions(),
                          isUpcoming: false,
                          onJoin: _joinSession,
                        ),
                      ],
                    ),
        );
      },
    );
  }
}

class _SessionList extends StatelessWidget {
  final List<Session> sessions;
  final Future<void> Function() onRefresh;
  final bool isUpcoming;
  final Function(Session) onJoin;

  const _SessionList({
    required this.sessions,
    required this.onRefresh,
    required this.isUpcoming,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return Center(
        child: Text(isUpcoming ? 'No upcoming sessions.' : 'No past sessions.'),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: sessions.length,
        itemBuilder: (context, index) {
          final session = sessions[index];
          return _SessionCard(
            session: session,
            isUpcoming: isUpcoming,
            onJoin: onJoin,
          );
        },
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final Session session;
  final bool isUpcoming;
  final Function(Session) onJoin;

  const _SessionCard({
    required this.session,
    required this.isUpcoming,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    final sessionProvider =
        Provider.of<SessionProvider>(context, listen: false);
    final bool isCanceled = session.status?.toLowerCase() == 'cancelled';

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Session with ${session.client?.name ?? 'Anonymous Client'}',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue),
            ),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.calendar_today,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(DateFormat.yMMMd()
                  .add_jm()
                  .format(DateTime.parse(session.scheduledAt))),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.person,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text('Type: ${session.sessionType}'),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.info_outline,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text('Status: ${session.status}',
                  style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color:
                          isCanceled ? Colors.red : AppColors.textSecondary)),
            ]),
            if (isUpcoming) ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!isCanceled) ...[
                    TextButton(
                      child: const Text('CANCEL',
                          style: TextStyle(color: Colors.red)),
                      onPressed: () {
                        sessionProvider
                            .professionalCancelSession(session.id)
                            .then((result) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                  result['message'] ?? 'Action completed.'),
                              backgroundColor:
                                  result['success'] ? Colors.green : Colors.red,
                            ));
                          }
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      child: const Text('JOIN'),
                      onPressed: () => onJoin(session),
                    ),
                  ] else ...[
                    TextButton(
                      child: const Text('DELETE',
                          style: TextStyle(color: Colors.grey)),
                      onPressed: () {
                        // Optional: Implement delete logic
                      },
                    )
                  ]
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
