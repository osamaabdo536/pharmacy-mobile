class NotificationModel {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final String? type;
  final Map<String, dynamic>? data;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.isRead,
    this.type,
    this.data,
  });

  bool get isUnread => !isRead;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    // Some backends wrap the actual fields under a `data` key.
    final payload = _asMap(json['data']) ?? json;

    return NotificationModel(
      id: _asString(json['id']),
      title: _asString(payload['title']),
      body: _asString(payload['body']),
      createdAt: _asDate(payload['created_at']) ??
          _asDate(payload['createdAt']) ??
          DateTime.now(),
      isRead: _asBool(payload['is_read']) || _asBool(payload['read']),
      type: _nullableString(payload['type']),
      data: _asMap(payload['metadata']),
    );
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    return value is Map<String, dynamic> ? value : null;
  }

  static String _asString(dynamic value, {String fallback = ''}) {
    if (value is String && value.isNotEmpty) return value;
    return fallback;
  }

  static String? _nullableString(dynamic value) {
    if (value is String && value.isNotEmpty) return value;
    return null;
  }

  static bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase();
      return lower == 'true' || lower == '1' || lower == 'yes';
    }
    return false;
  }

  static DateTime? _asDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}

