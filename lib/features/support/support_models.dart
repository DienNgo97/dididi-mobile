/// Kết quả 1 lượt hỏi trợ lý CSKH (khớp backend SupportAnswer).
class SupportAnswer {
  final String answer;
  final String source; // "kb" | "llm" | "none"
  final bool escalate;
  SupportAnswer({required this.answer, required this.source, required this.escalate});

  factory SupportAnswer.fromJson(Map<String, dynamic> j) => SupportAnswer(
        answer: (j['answer'] ?? '') as String,
        source: (j['source'] ?? 'none') as String,
        escalate: (j['escalate'] ?? false) as bool,
      );
}
