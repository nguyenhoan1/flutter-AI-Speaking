import 'package:bloc_clean_architecture/src/data/datasource/ai_teacher_remote_data_source.dart';
import 'package:bloc_clean_architecture/src/data/datasource/chat_history_local_data_source.dart';
import 'package:bloc_clean_architecture/src/domain/entities/chat_message.dart';
import 'package:bloc_clean_architecture/src/domain/entities/chat_session.dart';
import 'package:bloc_clean_architecture/src/domain/entities/speaking_grade.dart';
import 'package:bloc_clean_architecture/src/domain/repositories/ai_teacher_repository.dart';

class AiTeacherRepositoryImpl implements AiTeacherRepository {
  AiTeacherRepositoryImpl(this._remoteDataSource, this._historyDataSource);

  final AiTeacherRemoteDataSource _remoteDataSource;
  final ChatHistoryLocalDataSource _historyDataSource;

  @override
  Future<String> sendMessage({
    required List<ChatMessage> history,
    required LearnerLevel level,
  }) {
    return _remoteDataSource.sendMessage(history: history, level: level);
  }

  @override
  Future<SpeakingGrade> gradeSpeaking({
    required List<ChatMessage> history,
    required LearnerLevel level,
  }) {
    return _remoteDataSource.gradeSpeaking(history: history, level: level);
  }

  @override
  Future<void> saveSession(ChatSession session) {
    return _historyDataSource.saveSession(session);
  }

  @override
  Future<List<ChatSession>> loadSessions() {
    return _historyDataSource.loadSessions();
  }

  @override
  Future<void> deleteSession(String id) {
    return _historyDataSource.deleteSession(id);
  }
}
