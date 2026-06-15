/// UI-only model — what gets rendered as a chat bubble on screen.
/// This is NOT sent to the API.
enum MessageSender { user, ai }

class ChatMessage {
  final String text;
  final MessageSender sender;
  final DateTime timestamp;

  const ChatMessage({
    required this.text,
    required this.sender,
    required this.timestamp,
  });
}
