import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../models/task.dart';
import '../../utils/constants.dart';
import '../../widgets/task_card.dart';

class AllTasksScreen extends StatefulWidget {
  const AllTasksScreen({super.key});

  @override
  State<AllTasksScreen> createState() => _AllTasksScreenState();
}

class _AllTasksScreenState extends State<AllTasksScreen> {
  List<CleaningTask> _tasks = [];
  bool _loading = true;
  String? _statusFilter;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getTasks(
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              FilterChip(
                label: Text(DateFormat('dd MMM').format(_date)),
                onSelected: (_) async {
                  final p = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2024),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (p != null) {
                    setState(() => _date = p);
                    _load();
                  }
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip(null, 'All'),
                      _filterChip('pending', 'Pending'),
                      _filterChip('completed', 'Completed'),
                      _filterChip('verified', 'Verified'),
                      _filterChip('rejected', 'Rejected'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _tasks.isEmpty
                  ? const Center(child: Text('No tasks found'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        itemCount: _tasks.length,
                        itemBuilder: (_, i) => TaskCard(task: _tasks[i]),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _filterChip(String? status, String label) {
    final selected = _statusFilter == status;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          setState(() => _statusFilter = status);
          _load();
        },
        selectedColor: AppColors.primary.withOpacity(0.2),
      ),
    );
  }
}
