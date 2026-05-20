part of 'ai_teacher_bloc.dart';

enum AiTeacherStatus { idle, sending, grading, error }

class AiTeacherState extends Equatable {
  const AiTeacherState({
    required this.status,
    required this.level,
    required this.messages,
    required this.sessions,
    required this.ttsEnabled,
    required this.sessionId,
    this.grade,
    this.errorMessage,
  });

  AiTeacherState.initial()
      : status = AiTeacherStatus.idle,
        level = LearnerLevel.intermediate,
        messages = const [],
        sessions = const [],
        ttsEnabled = true,
        sessionId = DateTime.now().millisecondsSinceEpoch.toString(),
        grade = null,
        errorMessage = null;

  final AiTeacherStatus status;
  final LearnerLevel level;
  final List<ChatMessage> messages;
  final List<ChatSession> sessions;
  final bool ttsEnabled;
  final String sessionId;
  final SpeakingGrade? grade;
  final String? errorMessage;

  bool get isSending => status == AiTeacherStatus.sending;
  bool get isGrading => status == AiTeacherStatus.grading;

  /// Có đủ nội dung để chấm điểm chưa (>=2 lượt user nói).
  bool get canGrade =>
      messages.where((m) => m.role == MessageRole.user).length >= 2;

  AiTeacherState copyWith({
    AiTeacherStatus? status,
    LearnerLevel? level,
    List<ChatMessage>? messages,
    List<ChatSession>? sessions,
    bool? ttsEnabled,
    String? sessionId,
    SpeakingGrade? grade,
    String? errorMessage,
    bool clearError = false,
    bool clearGrade = false,
  }) {
    return AiTeacherState(
      status: status ?? this.status,
      level: level ?? this.level,
      messages: messages ?? this.messages,
      sessions: sessions ?? this.sessions,
      ttsEnabled: ttsEnabled ?? this.ttsEnabled,
      sessionId: sessionId ?? this.sessionId,
      grade: clearGrade ? null : (grade ?? this.grade),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        level,
        messages,
        sessions,
        ttsEnabled,
        sessionId,
        grade,
        errorMessage,
      ];
}
