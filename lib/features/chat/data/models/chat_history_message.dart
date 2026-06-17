/// API-only model — represents one turn in the conversation history.
/// Sent to and received from POST /ai/chat.
///
/// The backend returns complex entries (tool_calls, tool results) in
/// updatedHistory. We store the raw JSON so we can send it back as-is,
/// while still being able to extract role/content for display purposes.
class ChatHistoryMessage {
  final String role;
  final String content;

  /// The original raw JSON from the API — sent back as-is on next request.
  final Map<String, dynamic> _raw;

  const ChatHistoryMessage._({
    required this.role,
    required this.content,
    required Map<String, dynamic> raw,
  }) : _raw = raw;

  /// Serialize back to JSON exactly as received — preserves tool_calls etc.
  Map<String, dynamic> toJson() => _raw;

  factory ChatHistoryMessage.fromJson(Map<String, dynamic> json) {
    final role = json['role'] as String? ?? 'assistant';
    final rawContent = json['content'];
    final content = rawContent is String ? rawContent : '';
    return ChatHistoryMessage._(role: role, content: content, raw: json);
  }

  /// Factory for user messages we create locally (before sending to API).
  factory ChatHistoryMessage.user(String text) {
    final raw = {'role': 'user', 'content': text};
    return ChatHistoryMessage._(role: 'user', content: text, raw: raw);
  }

  /// Whether this entry is a real text message (not a tool call/result).
  bool get isTextMessage =>
      (role == 'user' || role == 'assistant') && content.isNotEmpty;
}
