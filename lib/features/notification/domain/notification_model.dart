class NotificationModel {
  final String id;
  final String title;
  final String? content;
  final DateTime? createdAt;
  final bool isRead;
  final String? type;
  final Map<String, dynamic> raw;

  const NotificationModel({
    required this.id,
    required this.title,
    this.content,
    this.createdAt,
    this.isRead = false,
    this.type,
    this.raw = const {},
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    final rawDate = json['createdAt'] ??
        json['created_at'] ??
        json['ngayTao'] ??
        json['date'] ??
        json['timestamp'];
    if (rawDate != null) {
      parsedDate = DateTime.tryParse(rawDate.toString());
    }

    final rawTitle = json['title'] ??
        json['tieuDe'] ??
        json['name'] ??
        json['subject'] ??
        'Thông báo UTH';

    final rawContent = json['content'] ??
        json['noiDung'] ??
        json['message'] ??
        json['description'] ??
        json['body'];

    final isReadVal = json['isRead'] == true ||
        json['daXem'] == true ||
        json['read'] == true ||
        json['status'] == 1;

    return NotificationModel(
      id: json['id']?.toString() ??
          json['_id']?.toString() ??
          json['maThongBao']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: rawTitle.toString(),
      content: rawContent?.toString(),
      createdAt: parsedDate,
      isRead: isReadVal,
      type: json['type']?.toString() ?? json['loai']?.toString(),
      raw: json,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'createdAt': createdAt?.toIso8601String(),
        'isRead': isRead,
        'type': type,
        'raw': raw,
      };
}
