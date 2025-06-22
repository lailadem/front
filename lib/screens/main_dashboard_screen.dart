import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import 'admin/admin_dashboard_screen.dart';
import 'client/client_home_screen.dart';
import 'professional/professional_home_screen.dart';

class MainDashboardScreen extends StatelessWidget {
  const MainDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    switch (user.role) {
      case AppConstants.roleClient:
        return const ClientHomeScreen();
      case AppConstants.rolePsychologist:
      case AppConstants.roleVolunteer:
        return const ProfessionalHomeScreen();
      case AppConstants.roleAdmin:
        return const AdminDashboardScreen();
      default:
        return Scaffold(
          body: Center(
            child: Text('Unknown role: ${user.role}'),
          ),
        );
    }
  }
}
