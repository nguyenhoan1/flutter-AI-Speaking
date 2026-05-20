part of 'ai_teacher_bloc.dart';

abstract class AiTeacherEvent extends Equatable {
  const AiTeacherEvent();

  @override
  List<Object?> get props => [];
}

class AiTeacherStarted extends AiTeacherEvent {
  const AiTeacherStarted();
}

class AiTeacherLevelChanged extends AiTeacherEvent {
  const AiTeacherLevelChanged(this.level);
  final LearnerLevel level;

  @override
  List<Object?> get props => [level];
}

class AiTeacherMessageSent extends AiTeacherEvent {
  const AiTeacherMessageSent(this.text);
  final String text;

  @override
  List<Object?> get props => [text];
}

class AiTeacherTopicPicked extends AiTeacherEvent {
  const AiTeacherTopicPicked(this.topic);
  final String topic;

  @override
  List<Object?> get props => [topic];
}

class AiTeacherCleared extends AiTeacherEvent {
  const AiTeacherCleared();
}

/// Yêu cầu AI chấm bài speaking hiện tại.
class AiTeacherGradeRequested extends AiTeacherEvent {
  const AiTeacherGradeRequested();
}

/// Đóng card chấm điểm.
class AiTeacherGradeDismissed extends AiTeacherEvent {
  const AiTeacherGradeDismissed();
}

/// Bật/tắt TTS đọc câu trả lời của AI.
class AiTeacherTtsToggled extends AiTeacherEvent {
  const AiTeacherTtsToggled();
}

/// Tải lại danh sách session đã lưu.
class AiTeacherHistoryLoaded extends AiTeacherEvent {
  const AiTeacherHistoryLoaded();
}

/// Mở 1 session cũ.
class AiTeacherSessionOpened extends AiTeacherEvent {
  const AiTeacherSessionOpened(this.session);
  final ChatSession session;

  @override
  List<Object?> get props => [session];
}

/// Xoá 1 session cũ.
class AiTeacherSessionDeleted extends AiTeacherEvent {
  const AiTeacherSessionDeleted(this.id);
  final String id;

  @override
  List<Object?> get props => [id];
}
