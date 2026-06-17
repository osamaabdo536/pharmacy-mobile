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

  String? get primaryActionLabel {
    final label = data?['action_label'] ?? data?['primary_action'];
    if (label is String && label.isNotEmpty) return label;
    return _inferredActions().$1;
  }

  String? get secondaryActionLabel {
    final label = data?['secondary_action'];
    if (label is String && label.isNotEmpty) return label;
    return _inferredActions().$2;
  }

  bool get primaryActionIsOutlined => _inferredActions().$3;

  (String?, String?, bool) _inferredActions() {
    switch (type) {
      case 'medication_expiring':
      case 'prescription_expiring':
        return ('Renew Now', null, false);
      case 'reservation_expired':
        return (null, 'Re-order', true);
      default:
        return (null, null, false);
    }
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    // Some backends wrap the actual fields under a `data` key.
    final payload = _asMap(json['data']) ?? json;

    return NotificationModel(
      id: _asString(json['id']),
      title: _asString(payload['title'], fallback: 'Notification'),
      body: _asString(payload['message']),
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

