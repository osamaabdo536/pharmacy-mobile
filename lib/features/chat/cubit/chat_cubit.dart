import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import '../../../core/utils/location_service.dart';
import '../data/chat_repository.dart';
import '../data/models/chat_message.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final ChatRepository _repository;
  final LocationService _locationService;

  /// Characters per "tick" for the typewriter effect.
  static const int _charsPerTick = 3;

  /// Delay between ticks — lower = faster typing.
  static const Duration _tickDelay = Duration(milliseconds: 18);

  ChatCubit({
    required ChatRepository repository,
    required LocationService locationService,
  }) : _repository = repository,
       _locationService = locationService,
       super(const ChatState());

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isLoading || state.isStreaming) return;

    // 1. Add user message to UI immediately
    final userMessage = ChatMessage(
      text: trimmed,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
    );

    emit(
      state.copyWith(
        messages: [...state.messages, userMessage],
        isLoading: true,
        clearError: true,
      ),
    );

    // 2. Get GPS (optional)
    final position = await _locationService.getCurrentPosition();

    // 3. Call API
    final result = await _repository.sendMessage(
      message: trimmed,
      history: state.history,
      latitude: position?.latitude,
      longitude: position?.longitude,
    );

    result.fold(
      (failure) {
        emit(state.copyWith(isLoading: false, error: failure.message));
      },
      (response) async {
        debugPrint(
          '[CUBIT DEBUG] updatedHistory length from response: ${response.updatedHistory.length}',
        );
        debugPrint(
          '[CUBIT DEBUG] first item role: ${response.updatedHistory.isNotEmpty ? response.updatedHistory.first.role : "EMPTY"}',
        );

        final reply = response.reply.trim();

        // Ignore empty replies
        if (reply.isEmpty) {
          emit(
            state.copyWith(isLoading: false, history: response.updatedHistory),
          );
          return;
        }

        // 4. Stop loading bubble, start typewriter
        emit(
          state.copyWith(
            isLoading: false,
            history: response.updatedHistory,
            streamingText: '',
          ),
        );

        // 5. Type the reply character by character
        await _typeText(reply);
      },
    );
  }

  Future<void> _typeText(String fullText) async {
    int index = 0;
    while (index < fullText.length) {
      if (isClosed) return;

      index = (index + _charsPerTick).clamp(0, fullText.length);
      final partial = fullText.substring(0, index);

      emit(state.copyWith(streamingText: partial));
      await Future.delayed(_tickDelay);
    }

    // 6. Typing done — move streaming text into messages list
    if (isClosed) return;

    final aiMessage = ChatMessage(
      text: fullText,
      sender: MessageSender.ai,
      timestamp: DateTime.now(),
    );

    emit(
      state.copyWith(
        messages: [...state.messages, aiMessage],
        clearStreaming: true,
      ),
    );
  }

  void clearChat() => emit(const ChatState());

  void clearError() => emit(state.copyWith(clearError: true));
}
