import 'package:equatable/equatable.dart';

/// Một dòng sửa lỗi cụ thể trong câu nói của học viên.
class GradeCorrection extends Equatable {
  const GradeCorrection({
    required this.original,
    required this.suggested,
    required this.why,
  });

  final String original;
  final String suggested;
  final String why;

  factory GradeCorrection.fromJson(Map<String, dynamic> json) {
    return GradeCorrection(
      original: (json['original'] ?? '').toString(),
      suggested: (json['suggested'] ?? '').toString(),
      why: (json['why'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'original': original,
        'suggested': suggested,
        'why': why,
      };

  @override
  List<Object?> get props => [original, suggested, why];
}

/// Báo cáo chấm điểm bài speaking do AI tạo ra.
class SpeakingGrade extends Equatable {
  const SpeakingGrade({
    required this.overall,
    required this.grammar,
    required this.vocabulary,
    required this.fluency,
    required this.content,
    required this.summary,
    required this.strengths,
    required this.improvements,
    required this.corrections,
    required this.createdAt,
  });

  /// Điểm tổng 0-10
  final double overall;

  /// Các tiêu chí, mỗi cái 0-10
  final double grammar;
  final double vocabulary;
  final double fluency;
  final double content;

  /// Nhận xét tổng quát 1-3 câu
  final String summary;
  final List<String> strengths;
  final List<String> improvements;
  final List<GradeCorrection> corrections;
  final DateTime createdAt;

  /// Letter grade dựa trên overall.
  String get letterGrade {
    if (overall >= 9) return 'A+';
    if (overall >= 8) return 'A';
    if (overall >= 7) return 'B+';
    if (overall >= 6) return 'B';
    if (overall >= 5) return 'C';
    if (overall >= 4) return 'D';
    return 'F';
  }

  factory SpeakingGrade.fromJson(Map<String, dynamic> json) {
    double parseScore(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble().clamp(0, 10);
      final parsed = double.tryParse(v.toString());
      return (parsed ?? 0).clamp(0, 10);
    }

    List<String> parseList(dynamic v) {
      if (v is List) {
        return v.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
      }
      return const [];
    }

    return SpeakingGrade(
      overall: parseScore(json['overall']),
      grammar: parseScore(json['grammar']),
      vocabulary: parseScore(json['vocabulary']),
      fluency: parseScore(json['fluency']),
      content: parseScore(json['content']),
      summary: (json['summary'] ?? '').toString(),
      strengths: parseList(json['strengths']),
      improvements: parseList(json['improvements']),
      corrections: (json['corrections'] is List)
          ? (json['corrections'] as List)
              .whereType<Map<String, dynamic>>()
              .map(GradeCorrection.fromJson)
              .toList()
          : const [],
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'overall': overall,
        'grammar': grammar,
        'vocabulary': vocabulary,
        'fluency': fluency,
        'content': content,
        'summary': summary,
        'strengths': strengths,
        'improvements': improvements,
        'corrections': corrections.map((c) => c.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [
        overall,
        grammar,
        vocabulary,
        fluency,
        content,
        summary,
        strengths,
        improvements,
        corrections,
        createdAt,
      ];
}
