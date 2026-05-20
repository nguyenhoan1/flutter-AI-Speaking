import 'dart:async';

import 'package:bloc_clean_architecture/src/domain/entities/chat_message.dart';
import 'package:bloc_clean_architecture/src/domain/entities/chat_session.dart';
import 'package:bloc_clean_architecture/src/domain/entities/speaking_grade.dart';
import 'package:bloc_clean_architecture/src/domain/repositories/ai_teacher_repository.dart';
import 'package:bloc_clean_architecture/src/utilities/tts_service.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'ai_teacher_event.dart';
part 'ai_teacher_state.dart';

class AiTeacherBloc extends Bloc<AiTeacherEvent, AiTeacherState> {
  AiTeacherBloc(this._repository, this._tts)
      : super(AiTeacherState.initial()) {
    on<AiTeacherStarted>(_onStarted);
    on<AiTeacherLevelChanged>(_onLevelChanged);
    on<AiTeacherMessageSent>(_onMessageSent, transformer: droppable());
    on<AiTeacherTopicPicked>(_onTopicPicked, transformer: droppable());
    on<AiTeacherCleared>(_onCleared);
    on<AiTeacherGradeRequested>(_onGradeRequested, transformer: droppable());
    on<AiTeacherGradeDismissed>(_onGradeDismissed);
    on<AiTeacherTtsToggled>(_onTtsToggled);
    on<AiTeacherHistoryLoaded>(_onHistoryLoaded);
    on<AiTeacherSessionOpened>(_onSessionOpened);
    on<AiTeacherSessionDeleted>(_onSessionDeleted);
  }

  final AiTeacherRepository _repository;
  final TtsService _tts;
  int _idCounter = 0;

  String _nextId() {
    _idCounter += 1;
    return '${DateTime.now().millisecondsSinceEpoch}_$_idCounter';
  }

  ChatMessage _greetingFor(LearnerLevel level) {
    final greeting = switch (level) {
      LearnerLevel.beginner =>
        "Hi there! I'm Coach Lumi 🌟 I'll help you practice speaking English. "
            "Don't worry about mistakes — just try! What's your name?",
      LearnerLevel.intermediate =>
        "Hey! I'm Coach Lumi 😊 Ready to practice some English speaking today? "
            "Tell me — what did you do this morning?",
      LearnerLevel.advanced =>
        "Hello! I'm Coach Lumi. Let's sharpen your speaking with a real conversation. "
            "What's a topic you've been thinking about lately?",
    };
    return ChatMessage(
      id: _nextId(),
      role: MessageRole.assistant,
      content: greeting,
      createdAt: DateTime.now(),
    );
  }

  String _titleFromMessages(List<ChatMessage> messages, LearnerLevel level) {
    final firstUser = messages
        .where((m) => m.role == MessageRole.user)
        .map((m) => m.content)
        .firstOrNull;
    if (firstUser == null || firstUser.trim().isEmpty) {
      return '${level.label} chat';
    }
    final t = firstUser.trim().replaceAll('\n', ' ');
    return t.length <= 32 ? t : '${t.substring(0, 32)}…';
  }

  Future<void> _persist(AiTeacherState s) async {
    // Đừng lưu session rỗng (chỉ có greeting).
    if (s.messages.length <= 1) return;
    try {
      final now = DateTime.now();
      await _repository.saveSession(
        ChatSession(
          id: s.sessionId,
          title: _titleFromMessages(s.messages, s.level),
          level: s.level,
          messages: s.messages
              .where((m) => m.role != MessageRole.system)
              .toList(),
          createdAt: s.messages.isNotEmpty ? s.messages.first.createdAt : now,
          updatedAt: now,
          grade: s.grade,
        ),
      );
    } catch (_) {/* im lặng */}
  }

  Future<void> _onStarted(
    AiTeacherStarted event,
    Emitter<AiTeacherState> emit,
  ) async {
    if (state.messages.isEmpty) {
      emit(state.copyWith(messages: [_greetingFor(state.level)]));
    }
    // Load history nền (không await UI).
    try {
      final sessions = await _repository.loadSessions();
      if (!emit.isDone) emit(state.copyWith(sessions: sessions));
    } catch (_) {}
  }

  Future<void> _onLevelChanged(
    AiTeacherLevelChanged event,
    Emitter<AiTeacherState> emit,
  ) async {
    if (event.level == state.level) return;
    emit(
      state.copyWith(
        level: event.level,
        messages: [_greetingFor(event.level)],
        sessionId: DateTime.now().millisecondsSinceEpoch.toString(),
        clearError: true,
        clearGrade: true,
      ),
    );
  }

  Future<void> _onCleared(
    AiTeacherCleared event,
    Emitter<AiTeacherState> emit,
  ) async {
    emit(
      state.copyWith(
        messages: [_greetingFor(state.level)],
        sessionId: DateTime.now().millisecondsSinceEpoch.toString(),
        clearError: true,
        clearGrade: true,
      ),
    );
  }

  Future<void> _send(String text, Emitter<AiTeacherState> emit) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isSending) return;

    final userMessage = ChatMessage(
      id: _nextId(),
      role: MessageRole.user,
      content: trimmed,
      createdAt: DateTime.now(),
    );

    final newHistory = [...state.messages, userMessage];

    emit(
      state.copyWith(
        status: AiTeacherStatus.sending,
        messages: newHistory,
        clearError: true,
      ),
    );

    try {
      final reply = await _repository.sendMessage(
        history: newHistory,
        level: state.level,
      );

      final assistantMessage = ChatMessage(
        id: _nextId(),
        role: MessageRole.assistant,
        content: reply,
        createdAt: DateTime.now(),
      );

      final updated = state.copyWith(
        status: AiTeacherStatus.idle,
        messages: [...newHistory, assistantMessage],
      );
      emit(updated);

      // TTS đọc reply (nếu user bật).
      if (state.ttsEnabled) {
        unawaited(_tts.speak(reply));
      }

      // Lưu session sau mỗi lượt, sau đó dispatch event reload history
      // (an toàn hơn việc emit trực tiếp từ closure đã đóng).
      unawaited(
        _persist(updated).then((_) {
          if (!isClosed) add(const AiTeacherHistoryLoaded());
        }),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AiTeacherStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onMessageSent(
    AiTeacherMessageSent event,
    Emitter<AiTeacherState> emit,
  ) {
    return _send(event.text, emit);
  }

  Future<void> _onTopicPicked(
    AiTeacherTopicPicked event,
    Emitter<AiTeacherState> emit,
  ) {
    return _send("Let's talk about ${event.topic}.", emit);
  }

  Future<void> _onGradeRequested(
    AiTeacherGradeRequested event,
    Emitter<AiTeacherState> emit,
  ) async {
    if (state.isGrading || state.isSending) return;
    if (!state.canGrade) {
      emit(
        state.copyWith(
          status: AiTeacherStatus.error,
          errorMessage:
              'Hãy nói ít nhất 2 câu trước khi yêu cầu chấm điểm nhé.',
        ),
      );
      return;
    }

    emit(state.copyWith(status: AiTeacherStatus.grading, clearError: true));
    try {
      final grade = await _repository.gradeSpeaking(
        history: state.messages,
        level: state.level,
      );
      final updated = state.copyWith(
        status: AiTeacherStatus.idle,
        grade: grade,
      );
      emit(updated);
      unawaited(
        _persist(updated).then((_) {
          if (!isClosed) add(const AiTeacherHistoryLoaded());
        }),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AiTeacherStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void _onGradeDismissed(
    AiTeacherGradeDismissed event,
    Emitter<AiTeacherState> emit,
  ) {
    emit(state.copyWith(clearGrade: true));
  }

  Future<void> _onTtsToggled(
    AiTeacherTtsToggled event,
    Emitter<AiTeacherState> emit,
  ) async {
    final next = !state.ttsEnabled;
    await _tts.setEnabled(next);
    emit(state.copyWith(ttsEnabled: next));
  }

  Future<void> _onHistoryLoaded(
    AiTeacherHistoryLoaded event,
    Emitter<AiTeacherState> emit,
  ) async {
    try {
      final sessions = await _repository.loadSessions();
      emit(state.copyWith(sessions: sessions));
    } catch (_) {}
  }

  Future<void> _onSessionOpened(
    AiTeacherSessionOpened event,
    Emitter<AiTeacherState> emit,
  ) async {
    final s = event.session;
    emit(
      state.copyWith(
        sessionId: s.id,
        level: s.level,
        messages: s.messages,
        grade: s.grade,
        clearGrade: s.grade == null,
        clearError: true,
        status: AiTeacherStatus.idle,
      ),
    );
  }

  Future<void> _onSessionDeleted(
    AiTeacherSessionDeleted event,
    Emitter<AiTeacherState> emit,
  ) async {
    try {
      await _repository.deleteSession(event.id);
      final sessions = await _repository.loadSessions();
      emit(state.copyWith(sessions: sessions));
    } catch (_) {}
  }
}

