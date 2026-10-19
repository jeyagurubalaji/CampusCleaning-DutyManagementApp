import 'user.dart';
import 'room.dart';

class CleaningTask {
  final String id;
  final Room? room;
  final User? sweeper;
  final User? assignedBy;
  final User? verifiedBy;
  final DateTime dutyDate;
  final String status;
  final DateTime? completedAt;
  final DateTime? verifiedAt;
  final String? rejectionReason;
  final String? notes;
  final List<TaskHistory> history;
  final DateTime createdAt;

  CleaningTask({
    required this.id,
    this.room,
    this.sweeper,
    this.assignedBy,
    this.verifiedBy,
    required this.dutyDate,
    required this.status,
    this.completedAt,
    this.verifiedAt,
    this.rejectionReason,
    this.notes,
    this.history = const [],
    required this.createdAt,
  });

  static DateTime? _parseLocal(dynamic value) {
    if (value == null) return null;
    final raw = value.toString();
    if (raw.isEmpty) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return null;
    return parsed.toLocal();
  }

  static DateTime _parseDutyDate(dynamic value) {
    final local = _parseLocal(value) ?? DateTime.now();
    return DateTime(local.year, local.month, local.day);
  }

  factory CleaningTask.fromJson(Map<String, dynamic> json) {
    return CleaningTask(
      id: json['_id'] ?? json['id'] ?? '',
      room: json['room'] != null && json['room'] is Map
          ? Room.fromJson(json['room'])
          : null,
      sweeper: json['sweeper'] != null && json['sweeper'] is Map
          ? User.fromJson(json['sweeper'])
          : null,
      assignedBy: json['assignedBy'] != null && json['assignedBy'] is Map
          ? User.fromJson(json['assignedBy'])
          : null,
      verifiedBy: json['verifiedBy'] != null && json['verifiedBy'] is Map
          ? User.fromJson(json['verifiedBy'])
          : null,
      dutyDate: _parseDutyDate(json['dutyDate']),
      status: json['status'] ?? 'pending',
      completedAt: _parseLocal(json['completedAt']),
      verifiedAt: _parseLocal(json['verifiedAt']),
      rejectionReason: json['rejectionReason'],
      notes: json['notes'],
      history: (json['history'] as List<dynamic>?)
              ?.map((h) => TaskHistory.fromJson(h))
              .toList() ??
          [],
      createdAt: _parseLocal(json['createdAt']) ?? DateTime.now(),
    );
  }

  bool get isPending => status == 'pending';
  bool get isCompleted => status == 'completed';
  bool get isVerified => status == 'verified';
  bool get isRejected => status == 'rejected';
}

class TaskHistory {
  final String status;
  final User? changedBy;
  final DateTime changedAt;
  final String? reason;

  TaskHistory({
    required this.status,
    this.changedBy,
    required this.changedAt,
    this.reason,
  });

  factory TaskHistory.fromJson(Map<String, dynamic> json) {
    final parsed = DateTime.tryParse(json['changedAt']?.toString() ?? '');
    return TaskHistory(
      status: json['status'] ?? '',
      changedBy: json['changedBy'] != null && json['changedBy'] is Map
          ? User.fromJson(json['changedBy'])
          : null,
      changedAt: parsed?.toLocal() ?? DateTime.now(),
      reason: json['reason'],
    );
  }
}