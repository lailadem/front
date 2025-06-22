import 'package:flutter/material.dart';
import '../../models/session.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../chat_screen.dart';

class ClientSessionDetailScreen extends StatefulWidget {
  final Session session;

  const ClientSessionDetailScreen({super.key, required this.session});

  @override
  State<ClientSessionDetailScreen> createState() =>
      _ClientSessionDetailScreenState();
}

class _ClientSessionDetailScreenState extends State<ClientSessionDetailScreen> {
  bool _isLoading = false;
  String? _error;
  double _rating = 0;
  final _feedbackController = TextEditingController();
  bool _showFeedbackForm = false;

  Future<void> _joinSession() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final result = await ApiService().joinSession(widget.session.id);
    setState(() {
      _isLoading = false;
    });
    if (result['success']) {
      if (mounted) {
        // Navigate to the chat screen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChatScreen(session: widget.session),
          ),
        );
      }
    } else {
      setState(() {
        _error = result['message'];
      });
    }
  }

  Future<void> _submitFeedback() async {
    if (_rating == 0) {
      setState(() {
        _error = 'Please provide a rating.';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final result = await ApiService().submitFeedback(
      sessionId: widget.session.id,
      rating: _rating.toInt().toString(),
      comments: _feedbackController.text.trim(),
    );
    setState(() {
      _isLoading = false;
    });
    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feedback submitted successfully!')),
      );
      Navigator.pop(context, true);
    } else {
      setState(() {
        _error = result['message'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final isUpcoming = session.status == AppConstants.statusScheduled ||
        session.status == AppConstants.statusOngoing;
    final isPast = session.status == AppConstants.statusCompleted;

    return Scaffold(
      appBar: AppBar(
        title: Text('Session Details'),
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
                    Text(
                      'Session with ${session.professional?.name ?? 'Specialist'}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Type: ${session.sessionType.toUpperCase()}'),
                    Text('Date: ${session.scheduledAt}'),
                    Text('Status: ${session.status}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (isUpcoming) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _joinSession,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Join Session'),
                ),
              ),
            ],
            if (isPast && !_showFeedbackForm) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => setState(() => _showFeedbackForm = true),
                  child: const Text('Submit Feedback'),
                ),
              ),
            ],
            if (_showFeedbackForm) ...[
              const SizedBox(height: 16),
              const Text('Rate your session:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: AppColors.warningOrange,
                      size: 32,
                    ),
                    onPressed: () => setState(() => _rating = index + 1),
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _feedbackController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Comments (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitFeedback,
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Submit'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          setState(() => _showFeedbackForm = false),
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppColors.errorRed),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }
}
