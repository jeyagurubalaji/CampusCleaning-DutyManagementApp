import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  List<dynamic> _users = [];
  List<dynamic> _departments = [];
  bool _loading = true;
  String? _roleFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.getUsers(role: _roleFilter),
        ApiService.getDepartments(),
      ]);
      setState(() {
        _users = results[0];
        _departments = results[1];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Are you sure you want to delete "${user['name']}" (${user['email']})?\n\nThey will no longer be able to login.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService.deleteUser(user['_id']);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${user['name']} deleted'),
              backgroundColor: AppColors.success,
            ),
          );
        }
        _load();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
          );
        }
      }
    }
  }

  Future<void> _showForm({Map<String, dynamic>? user}) async {
    final nameCtrl = TextEditingController(text: user?['name'] ?? '');
    final emailCtrl = TextEditingController(text: user?['email'] ?? '');
    final phoneCtrl = TextEditingController(text: user?['phone'] ?? '');
    final passCtrl = TextEditingController();
    bool obscure = true;
    String role = user?['role'] ?? 'sweeper';
    String? deptId =
        user?['department'] is Map ? user!['department']['_id'] : user?['department'];

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(user == null ? 'Add User' : 'Edit User'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                TextField(
                  controller: passCtrl,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    labelText: user == null
                        ? 'Password'
                        : 'Password (leave blank to keep current)',
                    hintText: user == null
                        ? 'Min 6 characters'
                        : 'Enter new password to change',
                    suffixIcon: IconButton(
                      icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setDialogState(() => obscure = !obscure),
                    ),
                  ),
                ),
                TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  keyboardType: TextInputType.phone,
                ),
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: const [
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    DropdownMenuItem(value: 'sweeper', child: Text('Sweeper')),
                    DropdownMenuItem(value: 'invigilator', child: Text('Invigilator')),
                  ],
                  onChanged: (v) => setDialogState(() => role = v!),
                ),
                if (role == 'invigilator')
                  DropdownButtonFormField<String>(
                    value: deptId,
                    decoration: const InputDecoration(labelText: 'Department'),
                    items: _departments
                        .map((d) => DropdownMenuItem(
                              value: d['_id'] as String,
                              child: Text(d['name'] ?? ''),
                            ))
                        .toList(),
                    onChanged: (v) => setDialogState(() => deptId = v),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final name = nameCtrl.text.trim();
      final email = emailCtrl.text.trim();
      final password = passCtrl.text;

      if (name.isEmpty || email.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Name and email are required'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
        return;
      }

      if (user == null && password.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password is required for new users'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
        return;
      }

      if (password.isNotEmpty && password.length < 6) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password must be at least 6 characters'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
        return;
      }

      final body = <String, dynamic>{
        'name': name,
        'email': email,
        'phone': phoneCtrl.text.trim(),
        'role': role,
        'department': deptId,
      };

      if (user == null) {
        body['password'] = password;
      } else if (password.isNotEmpty) {
        body['password'] = password;
      }

      try {
        if (user == null) {
          await ApiService.createUser(body);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$role created. They can login with $email'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        } else {
          await ApiService.updateUser(user['_id'], body);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  password.isNotEmpty
                      ? 'User updated. New password set for $email'
                      : 'User updated successfully',
                ),
                backgroundColor: AppColors.success,
              ),
            );
          }
        }
        _load();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chip(null, 'All'),
                  _chip('admin', 'Admin'),
                  _chip('sweeper', 'Sweeper'),
                  _chip('invigilator', 'Invigilator'),
                ],
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.builder(
                      itemCount: _users.length,
                      itemBuilder: (_, i) {
                        final u = _users[i];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary.withOpacity(0.2),
                            child: Text(
                              (u['name'] as String? ?? '?')[0].toUpperCase(),
                              style: const TextStyle(color: AppColors.primary),
                            ),
                          ),
                          title: Text(u['name'] ?? ''),
                          subtitle: Text('${u['email']} • ${u['role']}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: AppColors.primary),
                                tooltip: 'Edit',
                                onPressed: () => _showForm(user: u),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                                tooltip: 'Delete',
                                onPressed: () => _deleteUser(u),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _chip(String? role, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label),
        selected: _roleFilter == role,
        onSelected: (_) {
          setState(() => _roleFilter = role);
          _load();
        },
      ),
    );
  }
}