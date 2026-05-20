import 'package:bloc_clean_architecture/src/domain/entities/chat_message.dart';
import 'package:bloc_clean_architecture/src/domain/entities/speaking_grade.dart';
import 'package:equatable/equatable.dart';

/// Một buổi nói chuyện đã lưu lại, có thể có grade kèm theo.
class ChatSession extends Equatable {
  const ChatSession({
    required this.id,
    required this.title,
    required this.level,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
    this.grade,
  });

  final String id;
  final String title;
  final LearnerLevel level;
  final List<ChatMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SpeakingGrade? grade;

  ChatSession copyWith({
    String? id,
    String? title,
    LearnerLevel? level,
    List<ChatMessage>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
    SpeakingGrade? grade,
    bool clearGrade = false,
  }) {
    return ChatSession(
      id: id ?? this.id,
      title: title ?? this.title,
      level: level ?? this.level,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      grade: clearGrade ? null : (grade ?? this.grade),
    );
  }

  static ChatMessage _messageFromJson(Map<String, dynamic> m) {
    return ChatMessage(
      id: (m['id'] ?? '').toString(),
      role: MessageRole.values.firstWhere(
        (r) => r.name == (m['role'] ?? 'user').toString(),
        orElse: () => MessageRole.user,
      ),
      content: (m['content'] ?? '').toString(),
      createdAt: DateTime.tryParse((m['createdAt'] ?? '').toString()) ??
          DateTime.now(),
    );
  }

  static Map<String, dynamic> _messageToJson(ChatMessage m) => {
        'id': m.id,
        'role': m.role.name,
        'content': m.content,
        'createdAt': m.createdAt.toIso8601String(),
      };

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? 'Untitled chat').toString(),
      level: LearnerLevel.values.firstWhere(
        (l) => l.name == (json['level'] ?? 'intermediate').toString(),
        orElse: () => LearnerLevel.intermediate,
      ),
      messages: (json['messages'] is List)
          ? (json['messages'] as List)
              .whereType<Map<String, dynamic>>()
              .map(_messageFromJson)
              .toList()
          : const [],
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      updatedAt: DateTime.tryParse((json['updatedAt'] ?? '').toString()) ??
          DateTime.now(),
      grade: json['grade'] is Map<String, dynamic>
          ? SpeakingGrade.fromJson(json['grade'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'level': level.name,
        'messages': messages.map(_messageToJson).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        if (grade != null) 'grade': grade!.toJson(),
      };

  @override
  List<Object?> get props =>
      [id, title, level, messages, createdAt, updatedAt, grade];
}
