# MedConnect — Flutter AI Chat Feature

## Context for the AI model building this feature

This document contains everything needed to implement the AI Chat screen in the MedConnect Flutter app. Read it fully before writing any code.

---

## What is MedConnect?

MedConnect is an Egyptian pharmacy platform. Users (patients) can:

- Search for drugs
- Find nearby pharmacies
- Reserve drugs with a short code for pickup
- **Chat with an AI pharmacist assistant (this feature)**

---

## The AI Chat Feature — What It Does

The user talks to an AI assistant called "Medo" — a friendly Egyptian pharmacist.

The user types something like:

- "عاوز باندول فين"
- "عندي صداع إيه آخد"
- "بندول" (colloquial spelling)

Medo responds intelligently:

- Finds the drug in the database
- Shows nearby pharmacies that have it
- Suggests alternatives if unavailable
- Responds in the same language the user uses (Arabic or English)
- Handles colloquial Egyptian Arabic

---

## Backend API — Single Endpoint

### `POST /api/v1/ai/chat`

**Headers:**

```
Authorization: Bearer <supabase_jwt_token>
Content-Type: application/json
```

**Request Body:**

```json
{
  "message": "string — required, the user's message",
  "latitude": 30.0444,
  "longitude": 31.2357,
  "conversationHistory": [
    { "role": "user", "content": "previous user message" },
    { "role": "assistant", "content": "previous AI reply" }
  ]
}
```

- `message` — required, non-empty string
- `latitude` / `longitude` — optional but recommended (used to find nearby pharmacies)
- `conversationHistory` — optional array of previous messages. Start with empty `[]` on first message.

**Response (success 200):**

```json
{
  "data": {
    "reply": "لقيت باندول أدفانس في 3 صيدليات قريبة منك...",
    "updatedHistory": [
      { "role": "user", "content": "عاوز باندول" },
      { "role": "assistant", "content": "لقيت باندول أدفانس..." }
    ]
  },
  "meta": {
    "timestamp": "2026-06-13T14:00:00.000Z"
  }
}
```

- `reply` — the AI's response text to display
- `updatedHistory` — the full updated conversation history. **Store this and send it back with the next message.**

**Error response:**

```json
{
  "error": {
    "code": "UNAUTHORIZED",
    "message": "Missing authorization token",
    "timestamp": "..."
  }
}
```

### Important: The app owns the conversation history

The backend is **stateless**. There are no sessions. The app must:

1. Keep the full `updatedHistory` in memory (Cubit state)
2. Send it with every new message
3. Replace it with the new `updatedHistory` from each response

---

## Conversation History Data Model

```dart
// Each message in history
class ChatHistoryMessage {
  final String role;    // "user" or "assistant"
  final String content; // message text

  const ChatHistoryMessage({required this.role, required this.content});

  Map<String, dynamic> toJson() => {
    'role': role,
    'content': content,
  };

  factory ChatHistoryMessage.fromJson(Map<String, dynamic> json) =>
    ChatHistoryMessage(
      role: json['role'] as String,
      content: json['content'] as String,
    );
}
```

---

## UI Messages Model (what the chat screen shows)

Separate from history — this is what you render in the chat bubbles:

```dart
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
```

---

## Cubit

### State

```dart
class ChatState extends Equatable {
  final List<ChatMessage> messages;           // what to show in UI
  final List<ChatHistoryMessage> history;     // what to send to API
  final bool isLoading;
  final String? error;

  const ChatState({
    this.messages = const [],
    this.history = const [],
    this.isLoading = false,
    this.error,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    List<ChatHistoryMessage>? history,
    bool? isLoading,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [messages, history, isLoading, error];
}
```

### Cubit

```dart
class ChatCubit extends Cubit<ChatState> {
  final ChatRepository repository;
  final LocationService locationService;

  ChatCubit({required this.repository, required this.locationService})
      : super(const ChatState());

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // 1. Add user message to UI immediately
    final userMessage = ChatMessage(
      text: text,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
    );

    emit(state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      error: null,
    ));

    // 2. Get GPS if available
    final position = await locationService.getCurrentPosition();

    // 3. Call API
    final result = await repository.sendMessage(
      message: text,
      history: state.history,
      latitude: position?.latitude,
      longitude: position?.longitude,
    );

    result.fold(
      // Error
      (failure) {
        emit(state.copyWith(isLoading: false, error: failure.message));
      },
      // Success
      (response) {
        final aiMessage = ChatMessage(
          text: response.reply,
          sender: MessageSender.ai,
          timestamp: DateTime.now(),
        );

        emit(state.copyWith(
          messages: [...state.messages, aiMessage],
          history: response.updatedHistory,
          isLoading: false,
        ));
      },
    );
  }

  void clearChat() {
    emit(const ChatState());
  }
}
```

---

## Repository

```dart
class ChatRepository {
  final DioClient dio;

  ChatRepository({required this.dio});

  Future<Either<Failure, ChatResponse>> sendMessage({
    required String message,
    required List<ChatHistoryMessage> history,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final response = await dio.post(
        '/ai/chat',
        data: {
          'message': message,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
          if (history.isNotEmpty)
            'conversationHistory': history.map((h) => h.toJson()).toList(),
        },
      );

      return Right(ChatResponse.fromJson(response.data['data']));
    } on DioException catch (e) {
      return Left(ServerFailure(e.response?.data?['error']?['message'] ?? 'Something went wrong'));
    }
  }
}

class ChatResponse {
  final String reply;
  final List<ChatHistoryMessage> updatedHistory;

  ChatResponse({required this.reply, required this.updatedHistory});

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      reply: json['reply'] as String,
      updatedHistory: (json['updatedHistory'] as List)
          .map((e) => ChatHistoryMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
```

---

## UI — Chat Screen

### Layout

```
AppBar: "مساعد ميدو" + clear button
─────────────────────────────────────
ListView (reversed: true)
  - AI bubbles (left, grey)
  - User bubbles (right, primary color)
  - Loading indicator (3 dots animation) when isLoading
─────────────────────────────────────
Bottom input row:
  TextField + Send button
```

### Key behaviors

- `ListView` uses `reverse: true` so latest messages appear at bottom
- Auto-scroll to bottom after each new message
- TextField is cleared after sending
- Send button disabled while `isLoading == true`
- Show loading bubble (3 animated dots) while waiting for AI response
- If `state.error != null` — show a snackbar, don't crash

### Message Bubble Widget

```dart
class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({required this.message, super.key});

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == MessageSender.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? Theme.of(context).primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black87,
            fontSize: 15,
          ),
          textDirection: TextDirection.rtl, // Arabic-first
        ),
      ),
    );
  }
}
```

---

## GPS / Location

```dart
class LocationService {
  Future<Position?> getCurrentPosition() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null; // Don't block chat if no GPS
      }
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 5),
      );
    } catch (_) {
      return null; // GPS is optional — chat still works
    }
  }
}
```

GPS is **optional** — if unavailable, the AI still works but can't show nearby pharmacies.

---

## Conversation Flow Example

### Turn 1 — User sends first message

App sends:

```json
{
  "message": "بندول فين",
  "latitude": 30.0444,
  "longitude": 31.2357,
  "conversationHistory": []
}
```

App receives:

```json
{
  "reply": "لقيت باندول أدفانس في صيدليتين قريبين منك...",
  "updatedHistory": [
    { "role": "user", "content": "بندول فين" },
    { "role": "assistant", "content": "لقيت باندول أدفانس..." }
  ]
}
```

App stores `updatedHistory` in Cubit state.

### Turn 2 — User follows up

App sends:

```json
{
  "message": "طب فيه بديل رخيص؟",
  "latitude": 30.0444,
  "longitude": 31.2357,
  "conversationHistory": [
    { "role": "user", "content": "بندول فين" },
    { "role": "assistant", "content": "لقيت باندول أدفانس..." }
  ]
}
```

The AI understands the context from the history and responds accordingly.

---

## Error Cases to Handle

| Scenario            | What to show user               |
| ------------------- | ------------------------------- |
| No internet         | "تأكد من اتصالك بالإنترنت"      |
| 401 Unauthorized    | Redirect to login               |
| 500 Server Error    | "حصل مشكلة، حاول تاني"          |
| Request timeout     | "الاتصال بطيء، حاول تاني"       |
| Empty reply from AI | Don't add empty bubble — ignore |

---

## Packages Needed

```yaml
flutter_bloc: ^8.1.0 # Cubit
dio: ^5.4.0 # HTTP
geolocator: ^13.0.0 # GPS
equatable: ^2.0.5 # State equality
dartz: ^0.10.1 # Either<Failure, Success>
```

---

## File Structure for This Feature

```
lib/features/chat/
├── data/
│   ├── models/
│   │   ├── chat_message.dart          # UI message model
│   │   ├── chat_history_message.dart  # API history model
│   │   └── chat_response.dart         # API response model
│   └── chat_repository.dart
├── cubit/
│   ├── chat_cubit.dart
│   └── chat_state.dart
└── ui/
    ├── chat_screen.dart
    └── widgets/
        ├── message_bubble.dart
        ├── loading_bubble.dart        # 3 animated dots
        └── chat_input.dart            # TextField + send button
```

---

## Summary

- **1 API endpoint:** `POST /api/v1/ai/chat`
- **App owns history:** store `updatedHistory` and send it back every time
- **GPS is optional:** send if available, skip if not
- **Cubit manages:** messages list (UI), history list (API), loading, error
- **UI:** reversed ListView, RTL text, left/right bubbles
- **No over-engineering:** one Cubit, one Repository, straightforward state
