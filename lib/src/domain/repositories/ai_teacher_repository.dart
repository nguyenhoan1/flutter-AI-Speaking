import 'package:bloc_clean_architecture/src/domain/entities/chat_message.dart';
import 'package:bloc_clean_architecture/src/domain/entities/chat_session.dart';
import 'package:bloc_clean_architecture/src/domain/entities/speaking_grade.dart';

abstract class AiTeacherRepository {
  /// Gửi 1 lượt chat tới AI và nhận phản hồi.
  Future<String> sendMessage({
    required List<ChatMessage> history,
    required LearnerLevel level,
  });

  /// Yêu cầu AI chấm điểm toàn bộ cuộc hội thoại.
  Future<SpeakingGrade> gradeSpeaking({
    required List<ChatMessage> history,
    required LearnerLevel level,
  });

  /// Lưu lại session vào storage local.
  Future<void> saveSession(ChatSession session);

  /// Đọc tất cả session đã lưu, mới nhất lên đầu.
  Future<List<ChatSession>> loadSessions();

  /// Xoá 1 session theo id.
  Future<void> deleteSession(String id);
}
