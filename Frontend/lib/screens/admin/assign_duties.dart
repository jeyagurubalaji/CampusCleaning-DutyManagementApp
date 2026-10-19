import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';

class AssignDutiesScreen extends StatefulWidget {
  const AssignDutiesScreen({super.key});

  @override
  State<AssignDutiesScreen> createState() => _AssignDutiesScreenState();
}

class _AssignDutiesScreenState extends State<AssignDutiesScreen> {
  List<dynamic> _rooms = [];
  List<dynamic> _sweepers = [];
  final Map<String, String?> _assignments = {};
  DateTime _date = DateTime.now();
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rooms = await ApiService.getRooms();
      final sweepers = await ApiService.getUsers(role: 'sweeper');
      setState(() {
        _rooms = rooms;
        _sweepers = sweepers;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _submit() async {
    final list = <Map<String, String>>[];
    _assignments.forEach((roomId, sweeperId) {
      if (sweeperId != null && sweeperId.isNotEmpty) {
        list.add({'roomId': roomId, 'sweeperId': sweeperId});
      }
    });

    if (list.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one sweeper for a room'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final result = await ApiService.assignTasks(
        list,
        dutyDate: DateFormat('yyyy-MM-dd').format(_date),
      );
      if (mounted) {
        final count = result['count'] ?? list.length;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$count duties assigned successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        setState(() => _assignments.clear());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
        );
      }
    }
    setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: AppColors.danger)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_sweepers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_off, size: 56, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              const Text(
                'No sweepers found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Go to Users → add a user with role "Sweeper",\nthen come back here to assign duties.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Text('Duty Date: ', style: TextStyle(fontWeight: FontWeight.w600)),
              TextButton.icon(
                icon: const Icon(Icons.calendar_today, size: 18),
                label: Text(DateFormat('dd MMM yyyy').format(_date)),
                onPressed: () async {
                  final p = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime.now().subtract(const Duration(days: 1)),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (p != null) setState(() => _date = p);
                },
              ),
              const Spacer(),
              Text(
                '${_sweepers.length} sweeper(s)',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check),
                label: const Text('Assign'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _rooms.isEmpty
              ? const Center(child: Text('No rooms found. Add rooms first.'))
              : ListView.builder(
                  itemCount: _rooms.length,
                  itemBuilder: (_, i) {
                    final room = _rooms[i];
                    final roomId = room['_id'].toString();
                    final selected = _assignments[roomId];

                    final items = <DropdownMenuItem<String?>>[
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('— None —'),
                      ),
                    ];
                    for (final s in _sweepers) {
                      final id = s['_id']?.toString();
                      if (id == null || id.isEmpty) continue;
                      items.add(
                        DropdownMenuItem<String?>(
                          value: id,
                          child: Text(s['name']?.toString() ?? id),
                        ),
                      );
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: ListTile(
                        leading: Icon(
                          room['type'] == 'laboratory' ? Icons.science : Icons.meeting_room,
                          color: AppColors.primary,
                        ),
                        title: Text(room['name'] ?? ''),
                        subtitle: Text(
                          '${room['roomNumber']} • ${room['department']?['name'] ?? ''}',
                        ),
                        trailing: SizedBox(
                          width: 160,
                          child: DropdownButtonFormField<String?>(
                            value: selected,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: items,
                            onChanged: (v) {
                              setState(() {
                                if (v == null) {
                                  _assignments.remove(roomId);
                                } else {
                                  _assignments[roomId] = v;
                                }
                              });
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}