import '../models/chat_message_model.dart';

class ScanResult {
  final String id;
  final String documentType;
  final String imagePath;
  final String summary;
  final String keyFindings;
  final String medicines;
  final String sideEffects;
  final String questionsToAsk;
  final DateTime scannedAt;
  final List<ChatMessage> followUpMessages;

  const ScanResult({
    required this.id,
    required this.documentType,
    required this.imagePath,
    required this.summary,
    required this.keyFindings,
    required this.medicines,
    required this.sideEffects,
    required this.questionsToAsk,
    required this.scannedAt,
    this.followUpMessages = const [],
  });

  ScanResult copyWith({
    String? summary,
    List<ChatMessage>? followUpMessages,
  }) => ScanResult(
    id: id,
    documentType: documentType,
    imagePath: imagePath,
    summary: summary ?? this.summary,
    keyFindings: keyFindings,
    medicines: medicines,
    sideEffects: sideEffects,
    questionsToAsk: questionsToAsk,
    scannedAt: scannedAt,
    followUpMessages: followUpMessages ?? this.followUpMessages,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'documentType': documentType,
    'imagePath': imagePath,
    'summary': summary,
    'keyFindings': keyFindings,
    'medicines': medicines,
    'sideEffects': sideEffects,
    'questionsToAsk': questionsToAsk,
    'scannedAt': scannedAt.toIso8601String(),
    'followUpMessages': followUpMessages.map((m) => {
      'role': m.role,
      'content': m.content,
    }).toList(),
  };

  factory ScanResult.fromJson(Map<String, dynamic> json) => ScanResult(
    id: json['id'] ?? '',
    documentType: json['documentType'] ?? '',
    imagePath: json['imagePath'] ?? '',
    summary: json['summary'] ?? '',
    keyFindings: json['keyFindings'] ?? '',
    medicines: json['medicines'] ?? '',
    sideEffects: json['sideEffects'] ?? '',
    questionsToAsk: json['questionsToAsk'] ?? '',
    scannedAt: DateTime.tryParse(json['scannedAt'] ?? '') ?? DateTime.now(),
    followUpMessages: (json['followUpMessages'] as List<dynamic>? ?? [])
        .map((m) => ChatMessage(
      role: m['role'] ?? 'user',
      content: m['content'] ?? '',
      timestamp: DateTime.now(),
    ))
        .toList(),
  );
}