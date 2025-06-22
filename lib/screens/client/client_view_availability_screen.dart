import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/availability.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import 'client_book_session_screen.dart';

class ClientViewAvailabilityScreen extends StatefulWidget {
  const ClientViewAvailabilityScreen({super.key});

  @override
  State<ClientViewAvailabilityScreen> createState() =>
      _ClientViewAvailabilityScreenState();
}

class _ClientViewAvailabilityScreenState
    extends State<ClientViewAvailabilityScreen> {
  List<Availability> _availabilities = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAvailabilities();
  }

  Future<void> _loadAvailabilities() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await ApiService().getClientAvailabilities();
      if (mounted) {
        setState(() {
          if (result['success']) {
            final data = result['data'] as List;
            _availabilities =
                data.map((item) => Availability.fromJson(item)).toList();
          } else {
            _error = result['message'];
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'An unexpected error occurred: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToBooking(Availability availability) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ClientBookSessionScreen(
          professionalId: availability.professionalId,
          availabilityDate: availability.availableDate,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Professionals' Availability"),
        backgroundColor: AppColors.primaryBlue,
      ),
      body: RefreshIndicator(
        onRefresh: _loadAvailabilities,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Error: $_error',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_availabilities.isEmpty) {
      return const Center(
        child: Text('No availability slots found from any professionals.'),
      );
    }

    // Group availabilities by professional
    final Map<String, List<Availability>> groupedByProfessional = {};
    for (var availability in _availabilities) {
      final professionalName = availability.professional.name;
      if (groupedByProfessional[professionalName] == null) {
        groupedByProfessional[professionalName] = [];
      }
      groupedByProfessional[professionalName]!.add(availability);
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: groupedByProfessional.entries.map((entry) {
        final professionalName = entry.key;
        final professionalAvailabilities = entry.value;

        return Card(
          margin: const EdgeInsets.only(bottom: 20.0),
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile(
            leading: Icon(Icons.person, color: AppColors.primaryBlue),
            title: Text(
              professionalName,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.textPrimary),
            ),
            children: professionalAvailabilities.map<Widget>((availability) {
              final date = DateFormat.yMMMd()
                  .format(DateTime.parse(availability.availableDate));
              final startTime = availability.startTime.substring(0, 5);
              final endTime = availability.endTime.substring(0, 5);

              return ListTile(
                title: Text('Date: $date'),
                subtitle: Text('Time: $startTime - $endTime'),
                trailing: ElevatedButton(
                  child: const Text('Book'),
                  onPressed: () => _navigateToBooking(availability),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}
