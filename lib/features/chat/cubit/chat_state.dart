import 'package:equatable/equatable.dart';

import '../data/models/chat_history_message.dart';
import '../data/models/chat_message.dart';

class ChatState extends Equatable {
  /// Messages shown in the UI (bubbles)
  final List<ChatMessage> messages;

  /// Full conversation history sent to the API on every request
  final List<ChatHistoryMessage> history;

  /// True while waiting for the API response (shows loading bubble)
  final bool isLoading;

  /// Non-null while the AI reply is being "typed" character by character.
  /// null = no typing in progress.
  final String? streamingText;

  final String? error;

  const ChatState({
    this.messages = const [],
    this.history = const [],
    this.isLoading = false,
    this.streamingText,
    this.error,
  });

  bool get isStreaming => streamingText != null;

  ChatState copyWith({
    List<ChatMessage>? messages,
    List<ChatHistoryMessage>? history,
    bool? isLoading,
    String? streamingText,
    bool clearStreaming = false,
    String? error,
    bool clearError = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      streamingText: clearStreaming
          ? null
          : (streamingText ?? this.streamingText),
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
    messages,
    history,
    isLoading,
    streamingText,
    error,
  ];
}
