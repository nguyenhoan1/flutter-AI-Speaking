import 'package:equatable/equatable.dart';

enum MessageRole { user, assistant, system }

enum LearnerLevel { beginner, intermediate, advanced }

extension LearnerLevelX on LearnerLevel {
  String get label {
    switch (this) {
      case LearnerLevel.beginner:
        return 'Beginner';
      case LearnerLevel.intermediate:
        return 'Intermediate';
      case LearnerLevel.advanced:
        return 'Advanced';
    }
  }

  String get emoji {
    switch (this) {
      case LearnerLevel.beginner:
        return '🌱';
      case LearnerLevel.intermediate:
        return '🚀';
      case LearnerLevel.advanced:
        return '🏆';
    }
  }
}

class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.isStreaming = false,
  });

  final String id;
  final MessageRole role;
  final String content;
  final DateTime createdAt;
  final bool isStreaming;

  ChatMessage copyWith({
    String? id,
    MessageRole? role,
    String? content,
    DateTime? createdAt,
    bool? isStreaming,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }

  Map<String, dynamic> toOpenAi() => {
        'role': role.name,
        'content': content,
      };

  /// Convert sang format của Google Gemini API.
  /// Gemini dùng role 'user' và 'model' (không có 'assistant').
  Map<String, dynamic> toGemini() => {
        'role': role == MessageRole.assistant ? 'model' : 'user',
        'parts': [
          {'text': content},
        ],
      };

  @override
  List<Object?> get props => [id, role, content, createdAt, isStreaming];
}
