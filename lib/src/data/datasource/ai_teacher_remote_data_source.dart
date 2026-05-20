import 'dart:convert';

import 'package:bloc_clean_architecture/src/domain/entities/chat_message.dart';
import 'package:bloc_clean_architecture/src/domain/entities/speaking_grade.dart';
import 'package:dio/dio.dart';

abstract class AiTeacherRemoteDataSource {
  Future<String> sendMessage({
    required List<ChatMessage> history,
    required LearnerLevel level,
  });

  /// Chấm điểm toàn bộ cuộc hội thoại của học viên.
  /// AI sẽ đóng vai giám khảo, trả về điểm các tiêu chí và gợi ý.
  Future<SpeakingGrade> gradeSpeaking({
    required List<ChatMessage> history,
    required LearnerLevel level,
  });
}

/// Prompt chấm điểm — yêu cầu output JSON nghiêm ngặt để parse được.
String _buildGradingPrompt(LearnerLevel level) {
  return '''
You are Coach Lumi acting as an English speaking examiner.
Read the entire conversation above. Evaluate ONLY the LEARNER's (user's) spoken English performance.
Target level: ${level.label} (${level == LearnerLevel.beginner ? 'A1-A2' : level == LearnerLevel.intermediate ? 'B1-B2' : 'C1-C2'}).

Return STRICT JSON ONLY. No markdown, no commentary, no code fences.
Schema:
{
  "overall": <number 0-10>,
  "grammar": <number 0-10>,
  "vocabulary": <number 0-10>,
  "fluency": <number 0-10>,
  "content": <number 0-10>,
  "summary": "<2-3 sentence overall feedback in English, friendly tone>",
  "strengths": ["<3-5 short bullet points>"],
  "improvements": ["<3-5 actionable improvement bullets>"],
  "corrections": [
    {"original": "<learner sentence with mistake>", "suggested": "<corrected version>", "why": "<short why>"}
  ]
}

Scoring guide (based on learner's responses only, not Coach's messages):
- 9-10 Excellent, near native
- 7-8 Strong, minor issues
- 5-6 Communicates but with noticeable errors
- 3-4 Struggles, many errors
- 0-2 Cannot communicate

If learner barely spoke (only 1-2 short messages like "Hi"), keep scores LOW and explain in summary.
List up to 5 corrections, only real mistakes. Keep strings short.
''';
}

// ─── Shared system-prompt builder (dùng chung cho OpenAI & Gemini) ────
String _buildCoachLumiSystemPrompt(LearnerLevel level) {
  final levelHint = switch (level) {
    LearnerLevel.beginner =>
      'The learner is a BEGINNER. Use very simple A1-A2 vocabulary and short sentences. '
          'Speak slowly and warmly. Ask one short question at a time. '
          'Praise effort generously. When correcting, gently rephrase and keep it tiny.',
    LearnerLevel.intermediate =>
      'The learner is INTERMEDIATE (B1-B2). Use natural everyday English, '
          'introduce some idioms and collocations. Ask follow-up questions to push fluency. '
          'Correct grammar briefly inline using "Tip: ..." after your reply.',
    LearnerLevel.advanced =>
      'The learner is ADVANCED (C1-C2). Discuss abstract topics, debate ideas, '
          'and use sophisticated vocabulary. Push them with challenging questions. '
          'Give nuanced feedback on phrasing, register and naturalness when relevant.',
  };

  return '''
You are "Coach Lumi", a friendly, encouraging AI English-speaking teacher inside a mobile app.
Your goal: help the learner PRACTICE SPEAKING English through short, natural conversations.

Rules:
- Always reply in ENGLISH (you may translate one tricky word in Vietnamese in parentheses if helpful).
- Keep replies short: 2–4 sentences max, like a real conversation.
- ALWAYS end your message with ONE engaging question to keep the learner talking.
- Be warm, patient, and use occasional emojis like 😊 🎉 🌟 (sparingly, max 1–2 per reply).
- If the learner makes a mistake, mirror the correct version naturally without lecturing.
- Never break character. Never mention you are an AI model.

$levelHint
''';
}

// ─── OpenAI implementation (giữ lại để có thể chuyển ngược) ──────────
class OpenAiTeacherRemoteDataSource implements AiTeacherRemoteDataSource {
  OpenAiTeacherRemoteDataSource({
    Dio? dio,
    String? apiKey,
    String? model,
  })  : _dio = dio ?? Dio(),
        _apiKey = apiKey ?? const String.fromEnvironment('OPENAI_API_KEY'),
        _model = model ?? 'gpt-4o-mini';

  final Dio _dio;
  final String _apiKey;
  final String _model;

  static const String _endpoint = 'https://api.openai.com/v1/chat/completions';

  @override
  Future<String> sendMessage({
    required List<ChatMessage> history,
    required LearnerLevel level,
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception(
        'Missing OPENAI_API_KEY. Run with --dart-define=OPENAI_API_KEY=sk-...',
      );
    }

    final messages = <Map<String, dynamic>>[
      {'role': 'system', 'content': _buildCoachLumiSystemPrompt(level)},
      ...history
          .where((m) => m.role != MessageRole.system)
          .map((m) => m.toOpenAi()),
    ];

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _endpoint,
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
        data: {
          'model': _model,
          'messages': messages,
          'temperature': 0.8,
          'max_tokens': 220,
        },
      );

      final data = response.data;
      if (data == null) {
        throw Exception('Empty response from OpenAI');
      }
      final choices = data['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        throw Exception('No choices in OpenAI response');
      }
      final message = (choices.first as Map<String, dynamic>)['message']
          as Map<String, dynamic>?;
      final content = message?['content'] as String?;
      if (content == null || content.trim().isEmpty) {
        throw Exception('Empty assistant content');
      }
      return content.trim();
    } on DioException catch (e) {
      final msg = e.response?.data?.toString() ?? e.message ?? 'Network error';
      throw Exception('OpenAI request failed: $msg');
    }
  }

  @override
  Future<SpeakingGrade> gradeSpeaking({
    required List<ChatMessage> history,
    required LearnerLevel level,
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception('Missing OPENAI_API_KEY for grading.');
    }
    final transcript = history
        .where((m) => m.role != MessageRole.system)
        .map((m) => '${m.role == MessageRole.user ? "LEARNER" : "COACH"}: ${m.content}')
        .join('\n');

    final messages = <Map<String, dynamic>>[
      {
        'role': 'system',
        'content': 'You output STRICT JSON only. No markdown.'
      },
      {
        'role': 'user',
        'content':
            '${_buildGradingPrompt(level)}\n\n--- CONVERSATION ---\n$transcript',
      },
    ];

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _endpoint,
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
          sendTimeout: const Duration(seconds: 40),
          receiveTimeout: const Duration(seconds: 40),
        ),
        data: {
          'model': _model,
          'messages': messages,
          'temperature': 0.2,
          'response_format': {'type': 'json_object'},
        },
      );
      final raw = ((response.data?['choices'] as List?)?.first
              as Map?)?['message']?['content']
          ?.toString() ??
          '';
      final json = _extractJson(raw);
      return SpeakingGrade.fromJson(json);
    } on DioException catch (e) {
      final msg = e.response?.data?.toString() ?? e.message ?? 'Network error';
      throw Exception('OpenAI grading failed: $msg');
    }
  }
}

/// Helper: trích JSON object đầu tiên từ chuỗi (phòng khi AI bọc trong ```json).
Map<String, dynamic> _extractJson(String raw) {
  var text = raw.trim();
  // Bỏ code fence ```json ... ```
  text = text.replaceAll(RegExp(r'^```(?:json)?', multiLine: true), '');
  text = text.replaceAll(RegExp(r'```$', multiLine: true), '');
  text = text.trim();

  // Nếu vẫn không phải JSON nguyên đầu, tìm cặp `{ ... }` đầu tiên.
  if (!text.startsWith('{')) {
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start >= 0 && end > start) {
      text = text.substring(start, end + 1);
    }
  }
  final decoded = jsonDecode(text);
  if (decoded is Map<String, dynamic>) return decoded;
  throw const FormatException('Grading response is not a JSON object');
}


class GeminiTeacherRemoteDataSource implements AiTeacherRemoteDataSource {
  GeminiTeacherRemoteDataSource({
    Dio? dio,
    String? apiKey,
    String? model,
  })  : _dio = dio ?? Dio(),
        _apiKey = apiKey ?? const String.fromEnvironment('GEMINI_API_KEY'),
        _model = model ?? 'gemini-2.0-flash';

  final Dio _dio;
  final String _apiKey;
  final String _model;

  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  @override
  Future<String> sendMessage({
    required List<ChatMessage> history,
    required LearnerLevel level,
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception(
        'Missing GEMINI_API_KEY. Run app with '
        '--dart-define=GEMINI_API_KEY=AIza... '
        '(lấy key miễn phí tại https://aistudio.google.com/apikey).',
      );
    }

    // Gemini: lịch sử dùng role 'user' và 'model', system prompt tách riêng.
    final contents = history
        .where((m) => m.role != MessageRole.system)
        .map((m) => m.toGemini())
        .toList();

    final body = <String, dynamic>{
      'contents': contents,
      'systemInstruction': {
        'parts': [
          {'text': _buildCoachLumiSystemPrompt(level)},
        ],
      },
      'generationConfig': {
        'temperature': 0.8,
        'maxOutputTokens': 240,
        'topP': 0.95,
      },
    };

    final url = '$_baseUrl/$_model:generateContent?key=$_apiKey';

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        url,
        options: Options(
          headers: {'Content-Type': 'application/json'},
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
        data: body,
      );

      final data = response.data;
      if (data == null) {
        throw Exception('Empty response from Gemini');
      }

      // Check prompt-block (safety filters).
      final promptFeedback = data['promptFeedback'] as Map<String, dynamic>?;
      final blockReason = promptFeedback?['blockReason'];
      if (blockReason != null) {
        throw Exception('Gemini blocked the request: $blockReason');
      }

      final candidates = data['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        throw Exception('No candidates in Gemini response');
      }

      final first = candidates.first as Map<String, dynamic>;
      final content = first['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>?;
      if (parts == null || parts.isEmpty) {
        throw Exception('Empty parts in Gemini response');
      }

      // Ghép tất cả text parts (thường chỉ có 1).
      final buffer = StringBuffer();
      for (final p in parts) {
        if (p is Map<String, dynamic>) {
          final text = p['text'];
          if (text is String) buffer.write(text);
        }
      }
      final text = buffer.toString().trim();
      if (text.isEmpty) {
        throw Exception('Empty assistant content from Gemini');
      }
      return text;
    } on DioException catch (e) {
      // Cố trích message lỗi rõ ràng từ Gemini để hiện toast cho user.
      String msg;
      final data = e.response?.data;
      if (data is Map && data['error'] is Map) {
        final err = data['error'] as Map;
        msg = (err['message'] ?? err.toString()).toString();
      } else {
        msg = data?.toString() ?? e.message ?? 'Network error';
      }
      throw Exception('Gemini request failed: $msg');
    }
  }

  @override
  Future<SpeakingGrade> gradeSpeaking({
    required List<ChatMessage> history,
    required LearnerLevel level,
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception('Missing GEMINI_API_KEY for grading.');
    }

    final transcript = history
        .where((m) => m.role != MessageRole.system)
        .map((m) =>
            '${m.role == MessageRole.user ? "LEARNER" : "COACH"}: ${m.content}')
        .join('\n');

    final body = <String, dynamic>{
      'contents': [
        {
          'role': 'user',
          'parts': [
            {
              'text':
                  '${_buildGradingPrompt(level)}\n\n--- CONVERSATION ---\n$transcript'
            }
          ],
        }
      ],
      'generationConfig': {
        'temperature': 0.2,
        'maxOutputTokens': 1024,
        'responseMimeType': 'application/json',
      },
    };

    final url = '$_baseUrl/$_model:generateContent?key=$_apiKey';

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        url,
        options: Options(
          headers: {'Content-Type': 'application/json'},
          sendTimeout: const Duration(seconds: 40),
          receiveTimeout: const Duration(seconds: 40),
        ),
        data: body,
      );

      final candidates = response.data?['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        throw Exception('No grading candidates in Gemini response');
      }
      final parts =
          ((candidates.first as Map)['content'] as Map?)?['parts'] as List?;
      final raw = (parts?.first as Map?)?['text']?.toString() ?? '';
      final json = _extractJson(raw);
      return SpeakingGrade.fromJson(json);
    } on DioException catch (e) {
      String msg;
      final data = e.response?.data;
      if (data is Map && data['error'] is Map) {
        msg = ((data['error'] as Map)['message'] ?? data.toString()).toString();
      } else {
        msg = data?.toString() ?? e.message ?? 'Network error';
      }
      throw Exception('Gemini grading failed: $msg');
    }
  }
}
