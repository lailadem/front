import 'package:flutter/material.dart';
import 'package:psychology_support_platform/screens/admin/admin_approvals_screen.dart';
import 'package:psychology_support_platform/screens/admin/admin_content_screen.dart';
import 'package:psychology_support_platform/screens/admin/admin_session_logs_screen.dart';
import 'package:psychology_support_platform/screens/admin/admin_profile_screen.dart';
import 'package:psychology_support_platform/screens/splash_screen.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    const AdminApprovalsScreen(),
    const AdminContentScreen(),
    const AdminSessionLogsScreen(),
    const AdminProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle(_selectedIndex)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Provider.of<AuthProvider>(context, listen: false).logout();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const SplashScreen()),
                  (Route<dynamic> route) => false,
                );
              }
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.how_to_reg),
            label: 'Approvals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.article),
            label: 'Content',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Logs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Good for 4+ items
      ),
    );
  }

  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return 'Pending Approvals';
      case 1:
        return 'Content Management';
      case 2:
        return 'Session Logs';
      case 3:
        return 'Admin Profile';
      default:
        return 'Admin Dashboard';
    }
  }
}
