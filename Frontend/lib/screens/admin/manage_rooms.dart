import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';

class ManageRoomsScreen extends StatefulWidget {
  const ManageRoomsScreen({super.key});

  @override
  State<ManageRoomsScreen> createState() => _ManageRoomsScreenState();
}

class _ManageRoomsScreenState extends State<ManageRoomsScreen> {
  List<dynamic> _rooms = [];
  List<dynamic> _departments = [];
  List<dynamic> _invigilators = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.getRooms(),
        ApiService.getDepartments(),
        ApiService.getUsers(role: 'invigilator'),
      ]);
      setState(() {
        _rooms = results[0];
        _departments = results[1];
        _invigilators = results[2];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _deleteRoom(Map<String, dynamic> room) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Room'),
        content: Text(
          'Are you sure you want to delete "${room['name']}" (${room['roomNumber']})?',
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
        await ApiService.deleteRoom(room['_id']);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${room['name']} deleted'),
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

  String? _extractId(dynamic field) {
    if (field == null) return null;
    if (field is Map) return field['_id']?.toString();
    return field.toString();
  }

  Future<void> _showForm({Map<String, dynamic>? room}) async {
    final nameCtrl = TextEditingController(text: room?['name'] ?? '');
    final numberCtrl = TextEditingController(text: room?['roomNumber'] ?? '');
    final floorCtrl = TextEditingController(text: '${room?['floor'] ?? 1}');
    String type = room?['type'] ?? 'classroom';

    String? deptId = _extractId(room?['department']);
    String? invId = _extractId(room?['invigilator']);

    // Prevent dropdown crash: only use value if it exists in items
    final deptIds = _departments.map((d) => d['_id'].toString()).toSet();
    final invIds = _invigilators.map((u) => u['_id'].toString()).toSet();
    if (deptId != null && !deptIds.contains(deptId)) deptId = null;
    if (invId != null && !invIds.contains(invId)) invId = null;

    const validTypes = ['classroom', 'laboratory', 'office', 'other'];
    if (!validTypes.contains(type)) type = 'classroom';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(room == null ? 'Add Room' : 'Edit Room'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: numberCtrl,
                  decoration: const InputDecoration(labelText: 'Room Number'),
                ),
                TextField(
                  controller: floorCtrl,
                  decoration: const InputDecoration(labelText: 'Floor'),
                  keyboardType: TextInputType.number,
                ),
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(value: 'classroom', child: Text('Classroom')),
                    DropdownMenuItem(value: 'laboratory', child: Text('Laboratory')),
                    DropdownMenuItem(value: 'office', child: Text('Office')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (v) {
                    if (v != null) setDialogState(() => type = v);
                  },
                ),
                DropdownButtonFormField<String>(
                  value: deptId,
                  decoration: const InputDecoration(labelText: 'Department'),
                  items: _departments
                      .map((d) => DropdownMenuItem<String>(
                            value: d['_id'].toString(),
                            child: Text(d['name'] ?? ''),
                          ))
                      .toList(),
                  onChanged: (v) => setDialogState(() => deptId = v),
                ),
                DropdownButtonFormField<String?>(
                  value: invId,
                  decoration: const InputDecoration(labelText: 'Invigilator'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('— None —'),
                    ),
                    ..._invigilators.map(
                      (u) => DropdownMenuItem<String?>(
                        value: u['_id'].toString(),
                        child: Text(u['name'] ?? ''),
                      ),
                    ),
                  ],
                  onChanged: (v) => setDialogState(() => invId = v),
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
      if (nameCtrl.text.trim().isEmpty || numberCtrl.text.trim().isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Name and Room Number are required'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
        return;
      }
      if (deptId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select a Department'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
        return;
      }

      final body = {
        'name': nameCtrl.text.trim(),
        'roomNumber': numberCtrl.text.trim(),
        'floor': int.tryParse(floorCtrl.text) ?? 1,
        'type': type,
        'department': deptId,
        'invigilator': invId,
      };
      try {
        if (room == null) {
          await ApiService.createRoom(body);
        } else {
          await ApiService.updateRoom(room['_id'], body);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(room == null ? 'Room created' : 'Room updated'),
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

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: _rooms.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('No rooms found. Tap + to add one.')),
                ],
              )
            : ListView.builder(
                itemCount: _rooms.length,
                itemBuilder: (_, i) {
                  final r = _rooms[i];
                  return ListTile(
                    leading: Icon(
                      r['type'] == 'laboratory' ? Icons.science : Icons.meeting_room,
                      color: AppColors.primary,
                    ),
                    title: Text(r['name'] ?? ''),
                    subtitle: Text(
                      '${r['roomNumber']} • ${r['department']?['name'] ?? ''} • Inv: ${r['invigilator']?['name'] ?? 'None'}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: AppColors.primary),
                          tooltip: 'Edit',
                          onPressed: () => _showForm(room: r),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                          tooltip: 'Delete',
                          onPressed: () => _deleteRoom(r),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}