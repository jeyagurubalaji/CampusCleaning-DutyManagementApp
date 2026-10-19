import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../utils/constants.dart';
import 'admin_dashboard.dart';
import 'manage_departments.dart';
import 'manage_rooms.dart';
import 'manage_users.dart';
import 'assign_duties.dart';
import 'all_tasks.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _index = 0;

  final _pages = const [
    AdminDashboard(),
    AllTasksScreen(),
    AssignDutiesScreen(),
    ManageRoomsScreen(),
    ManageUsersScreen(),
  ];

  final _titles = [
    'Dashboard',
    'All Tasks',
    'Assign Duties',
    'Rooms',
    'Users',
  ];

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.apartment),
            tooltip: 'Departments',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManageDepartmentsScreen()),
              );
            },
          ),
          PopupMenuButton<String>(
  icon: const Icon(Icons.account_circle),
  itemBuilder: (_) => [
    PopupMenuItem<String>(
      enabled: false,
      child: Text(auth.user?.name ?? 'Admin'),
    ),
    const PopupMenuDivider(),
    PopupMenuItem<String>(
      value: 'logout',
      child: const Row(
        children: [
          Icon(Icons.logout, size: 20),
          SizedBox(width: 8),
          Text('Logout'),
        ],
      ),
    ),
  ],
  onSelected: (value) {
    if (value == 'logout') auth.logout();
  },
),
        ],   
      ),          
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.list_alt), label: 'Tasks'),
          NavigationDestination(icon: Icon(Icons.assignment_ind), label: 'Assign'),
          NavigationDestination(icon: Icon(Icons.meeting_room), label: 'Rooms'),
          NavigationDestination(icon: Icon(Icons.people), label: 'Users'),
        ],
      ),
    );
  }
}
