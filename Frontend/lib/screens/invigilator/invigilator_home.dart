import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/auth_provider.dart';
import '../../services/api_service.dart';
import '../../models/task.dart';
import '../../utils/constants.dart';
import '../../widgets/task_card.dart';

class InvigilatorHome extends StatefulWidget {
  const InvigilatorHome({super.key});

  @override
  State<InvigilatorHome> createState() => _InvigilatorHomeState();
}

class _InvigilatorHomeState extends State<InvigilatorHome> {
  List<CleaningTask> _tasks = [];
  bool _loading = true;
  DateTime _date = DateTime.now();
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getInvigilatorTasks(
        date: DateFormat('yyyy-MM-dd').format(_date),
        status: _statusFilter,
      );
      setState(() {
        _tasks = data.map((e) => CleaningTask.fromJson(e)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _verify(CleaningTask task) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verify Cleaning'),
        content: Text('Confirm that ${task.room?.name ?? 'this room'} has been cleaned satisfactorily?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Verify'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService.verifyTask(task.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Verified successfully'), backgroundColor: AppColors.success),
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

  Future<void> _reject(CleaningTask task) async {
    final reasonCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Cleaning'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Provide a reason for rejecting ${task.room?.name ?? 'this room'}:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (reasonCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reason is required'), backgroundColor: AppColors.danger),
        );
        return;
      }
      try {
        await ApiService.rejectTask(task.id, reasonCtrl.text.trim());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rejected'), backgroundColor: AppColors.warning),
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

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cleaning Verification'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final p = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2024),
                lastDate: DateTime.now().add(const Duration(days: 7)),
              );
              if (p != null) {
                setState(() => _date = p);
                _load();
              }
            },
          ),
          PopupMenuButton<String>(
  icon: const Icon(Icons.account_circle),
  itemBuilder: (_) => [
    PopupMenuItem<String>(
      enabled: false,
      child: Text(auth.user?.name ?? ''),
    ),
    const PopupMenuDivider(),
    const PopupMenuItem<String>(
      value: 'logout',
      child: Row(children: [Icon(Icons.logout, size: 20), SizedBox(width: 8), Text('Logout')]),
    ),
  ],
  onSelected: (value) {
    if (value == 'logout') auth.logout();
  },
),
        ],   
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chip(null, 'All'),
                  _chip('completed', 'To Verify'),
                  _chip('verified', 'Verified'),
                  _chip('rejected', 'Rejected'),
                  _chip('pending', 'Pending'),
                ],
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _tasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.verified_user, size: 64, color: AppColors.textSecondary.withOpacity(0.5)),
                            const SizedBox(height: 16),
                            Text(
                              'No tasks for ${DateFormat('dd MMM yyyy').format(_date)}',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _tasks.length,
                          itemBuilder: (_, i) {
                            final task = _tasks[i];
                            return TaskCard(
                              task: task,
                              actions: task.isCompleted
                                  ? Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () => _verify(task),
                                            icon: const Icon(Icons.check, size: 18),
                                            label: const Text('Verify'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.success,
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () => _reject(task),
                                            icon: const Icon(Icons.close, size: 18),
                                            label: const Text('Reject'),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: AppColors.danger,
                                              side: const BorderSide(color: AppColors.danger),
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : null,
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String? status, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label),
        selected: _statusFilter == status,
        onSelected: (_) {
          setState(() => _statusFilter = status);
          _load();
        },
        selectedColor: AppColors.primary.withOpacity(0.2),
      ),
    );
  }
}
