import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/auth_provider.dart';
import '../../services/api_service.dart';
import '../../models/task.dart';
import '../../utils/constants.dart';
import '../../widgets/task_card.dart';

class SweeperHome extends StatefulWidget {
  const SweeperHome({super.key});

  @override
  State<SweeperHome> createState() => _SweeperHomeState();
}

class _SweeperHomeState extends State<SweeperHome> {
  List<CleaningTask> _tasks = [];
  bool _loading = true;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getMyTasks(
        date: DateFormat('yyyy-MM-dd').format(_date),
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

  Future<void> _complete(CleaningTask task) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark as Completed'),
        content: Text('Confirm that you have cleaned ${task.room?.name ?? 'this room'}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Yes, Completed'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService.completeTask(task.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Marked as completed'), backgroundColor: AppColors.success),
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
        title: const Text('My Cleaning Duties'),
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _tasks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cleaning_services, size: 64, color: AppColors.textSecondary.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text(
                        'No duties for ${DateFormat('dd MMM yyyy').format(_date)}',
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
                        actions: (task.isPending || task.isRejected)
                            ? SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _complete(task),
                                  icon: const Icon(Icons.check),
                                  label: Text(task.isRejected ? 'Re-clean & Mark Completed' : 'Mark Completed'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.success,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              )
                            : null,
                      );
                    },
                  ),
                ),
    );
  }
}
