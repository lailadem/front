import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/availability.dart';
import '../../providers/session_provider.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../models/user.dart';

class ClientBookSessionScreen extends StatefulWidget {
  final int? professionalId;
  final String? availabilityDate;

  const ClientBookSessionScreen(
      {super.key, this.professionalId, this.availabilityDate});

  @override
  State<ClientBookSessionScreen> createState() =>
      _ClientBookSessionScreenState();
}

class _ClientBookSessionScreenState extends State<ClientBookSessionScreen> {
  int? _selectedProfessionalId;
  String? _selectedDate;
  String? _selectedTime;
  String _sessionType = AppConstants.sessionTypeChat;
  bool _isAnonymous = false;
  bool _isLoading = false;
  String? _error;
  List<Availability> _availabilities = [];
  List<User> _professionals = [];
  String? _filterSpecialization;

  @override
  void initState() {
    super.initState();
    _selectedProfessionalId = widget.professionalId;
    _selectedDate = widget.availabilityDate;
    _fetchAvailabilities();
  }

  Future<void> _fetchAvailabilities() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final result = await ApiService().getClientAvailabilities();
    if (result['success']) {
      setState(() {
        final data = result['data'] as List;
        _availabilities =
            data.map((item) => Availability.fromJson(item)).toList();
        _professionals = _availabilities.map((a) => a.professional).toList();
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

  List<Availability> get _filteredAvailabilities {
    if (_filterSpecialization == null || _filterSpecialization!.isEmpty) {
      return _availabilities;
    }
    return _availabilities.where((a) {
      final prof = a.professional;
      return prof.specialization == _filterSpecialization;
    }).toList();
  }

  List<User> _getUniqueProfessionals() {
    final uniqueProfessionals = <int, User>{};
    for (final prof in _professionals) {
      uniqueProfessionals[prof.id] = prof;
    }
    if (_filterSpecialization == null || _filterSpecialization!.isEmpty) {
      return uniqueProfessionals.values.toList();
    }
    return uniqueProfessionals.values
        .where((prof) => prof.specialization == _filterSpecialization)
        .toList();
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate.toIso8601String().split('T').first;
      });
    }
  }

  Future<void> _selectTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null) {
      setState(() {
        _selectedTime =
            '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _submit() async {
    if (_selectedProfessionalId == null ||
        _selectedDate == null ||
        _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select professional, date, and time.')),
      );
      return;
    }

    final scheduledAt = '${_selectedDate!} ${_selectedTime!}:00';
    final sessionProvider =
        Provider.of<SessionProvider>(context, listen: false);

    final result = await sessionProvider.bookSession(
      professionalId: _selectedProfessionalId!,
      scheduledAt: scheduledAt,
      sessionType: _sessionType,
      isAnonymous: _isAnonymous,
    );

    if (mounted) {
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session booked successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true on success
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to book session.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Accessing the provider, but not listening to it in the build method
    // to prevent rebuilds when only the session list changes.
    // We will listen to specific properties like isLoading.
    final sessionProvider = context.watch<SessionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Session'),
        backgroundColor: AppColors.primaryBlue,
      ),
      body: sessionProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select Professional',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: _selectedProfessionalId,
                      items: _getUniqueProfessionals().map((prof) {
                        return DropdownMenuItem<int>(
                          value: prof.id,
                          child: Text('${prof.name} (ID: ${prof.id})'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedProfessionalId = val;
                          _selectedDate =
                              null; // Reset date when professional changes
                          _selectedTime =
                              null; // Reset time when professional changes
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Professional',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Select Date',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(_selectedDate ?? 'Select a date'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Select Time',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _selectTime,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Time',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(_selectedTime ?? 'Select a time'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Session Type',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            value: AppConstants.sessionTypeChat,
                            groupValue: _sessionType,
                            onChanged: (val) =>
                                setState(() => _sessionType = val!),
                            title: const Text('Chat'),
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            value: AppConstants.sessionTypeVoice,
                            groupValue: _sessionType,
                            onChanged: (val) =>
                                setState(() => _sessionType = val!),
                            title: const Text('Voice'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      value: _isAnonymous,
                      onChanged: (val) =>
                          setState(() => _isAnonymous = val ?? false),
                      title: const Text('Book as anonymous'),
                    ),
                    if (sessionProvider.error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(sessionProvider.error!,
                            style: const TextStyle(color: AppColors.errorRed)),
                      ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: sessionProvider.isLoading ? null : _submit,
                        child: sessionProvider.isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Book Session'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
