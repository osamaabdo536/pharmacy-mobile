import 'chat_history_message.dart';

/// Parsed response from POST /ai/chat.
/// Shape: { "data": { "reply": "...", "updatedHistory": [...] } }
class ChatResponse {
  final String reply;
  final List<ChatHistoryMessage> updatedHistory;

  const ChatResponse({required this.reply, required this.updatedHistory});

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    final rawHistory = json['updatedHistory'];

    // Backend may occasionally return non-object entries (empty arrays []).
    // We filter those out and only keep valid Map entries.
    List<ChatHistoryMessage> history = [];
    if (rawHistory is List) {
      for (final entry in rawHistory) {
        if (entry is Map<String, dynamic>) {
          history.add(ChatHistoryMessage.fromJson(entry));
        }
        // skip [], null, or anything else
      }
    }

    return ChatResponse(
      reply: json['reply'] as String? ?? '',
      updatedHistory: history,
    );
  }
}
