class ChatMessage {
  final String content;
  final String role; // 'user' or 'model'
  final DateTime timestamp;
  final bool isLoading;

  const ChatMessage({
    required this.content,
    required this.role,
    required this.timestamp,
    this.isLoading = false,
  });

  bool get isUser => role == 'user';

  factory ChatMessage.user(String content) => ChatMessage(
    content: content,
    role: 'user',
    timestamp: DateTime.now(),
  );

  factory ChatMessage.assistant(String content) => ChatMessage(
    content: content,
    role: 'model',
    timestamp: DateTime.now(),
  );

  factory ChatMessage.loading() => ChatMessage(
    content: '',
    role: 'model',
    timestamp: DateTime.now(),
    isLoading: true,
  );

  ChatMessage copyWith({String? content, bool? isLoading}) => ChatMessage(
    content: content ?? this.content,
    role: role,
    timestamp: timestamp,
    isLoading: isLoading ?? this.isLoading,
  );
}