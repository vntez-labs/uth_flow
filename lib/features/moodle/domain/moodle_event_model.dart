class MoodleEventModel {
  final int id;
  final String name;
  final String courseName;
  final int timesort;
  final String url;
  final String? actionName;

  const MoodleEventModel({
    required this.id,
    required this.name,
    required this.courseName,
    required this.timesort,
    required this.url,
    this.actionName,
  });

  DateTime get dueDate => DateTime.fromMillisecondsSinceEpoch(timesort * 1000);

  bool get isOverdue => dueDate.isBefore(DateTime.now());

  bool get isUrgent {
    if (isOverdue) return true;
    final diff = dueDate.difference(DateTime.now());
    return diff.inHours <= 24;
  }

  String get countdownText {
    if (isOverdue) return 'Đã quá hạn';
    final diff = dueDate.difference(DateTime.now());
    if (diff.inHours < 1) {
      return '${diff.inMinutes}p';
    }
    if (diff.inHours < 24) {
      final mins = diff.inMinutes % 60;
      return '${diff.inHours}h ${mins}p';
    }
    return '${diff.inDays} ngày';
  }

  String get suffixText {
    if (isOverdue) return '';
    final diff = dueDate.difference(DateTime.now());
    if (diff.inHours < 24) {
      return 'nữa là hết';
    }
    return 'nữa';
  }

  String get formattedDueTime {
    final now = DateTime.now();
    final isToday = dueDate.year == now.year &&
        dueDate.month == now.month &&
        dueDate.day == now.day;
    final tomorrow = now.add(const Duration(days: 1));
    final isTomorrow = dueDate.year == tomorrow.year &&
        dueDate.month == tomorrow.month &&
        dueDate.day == tomorrow.day;

    final hourStr = dueDate.hour.toString().padLeft(2, '0');
    final minStr = dueDate.minute.toString().padLeft(2, '0');
    final timeStr = '$hourStr:$minStr';

    if (isOverdue) {
      if (dueDate.year == now.year) {
        return '$timeStr ngày ${dueDate.day}/${dueDate.month} (Đã quá hạn)';
      }
      return '$timeStr ngày ${dueDate.day}/${dueDate.month}/${dueDate.year} (Đã quá hạn)';
    }

    if (isToday) {
      return '$timeStr hôm nay (Nộp qua LMS)';
    }
    if (isTomorrow) {
      return '$timeStr ngày mai (Nộp qua LMS)';
    }
    if (dueDate.year == now.year) {
      return '$timeStr ngày ${dueDate.day}/${dueDate.month} (Nộp qua LMS)';
    }
    return '$timeStr ngày ${dueDate.day}/${dueDate.month}/${dueDate.year} (Nộp qua LMS)';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'courseName': courseName,
        'timesort': timesort,
        'url': url,
        'actionName': actionName,
      };

  factory MoodleEventModel.fromJson(Map<String, dynamic> json) {
    String courseName = 'Không rõ môn học';
    if (json['course'] is Map) {
      courseName = json['course']['fullname'] as String? ??
          json['course']['shortname'] as String? ??
          courseName;
    }

    return MoodleEventModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name'] as String? ?? 'Bài tập Moodle',
      courseName: courseName,
      timesort: json['timesort'] is int
          ? json['timesort'] as int
          : int.tryParse(json['timesort']?.toString() ?? '') ?? 0,
      url: json['url'] as String? ?? json['action']?['url'] as String? ?? '',
      actionName: json['action']?['name'] as String?,
    );
  }
}
