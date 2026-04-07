import 'dart:convert';

class Transcript {
  final String id;
  final String title;
  final String text;
  final String? summary;
  final DateTime createdAt;
  final Duration duration;

  Transcript({
    required this.id,
    required this.title,
    required this.text,
    this.summary,
    required this.createdAt,
    required this.duration,
  });

  Transcript copyWith({
    String? title,
    String? text,
    String? summary,
    Duration? duration,
  }) {
    return Transcript(
      id: id,
      title: title ?? this.title,
      text: text ?? this.text,
      summary: summary ?? this.summary,
      createdAt: createdAt,
      duration: duration ?? this.duration,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'text': text,
        'summary': summary,
        'createdAt': createdAt.toIso8601String(),
        'durationSeconds': duration.inSeconds,
      };

  factory Transcript.fromJson(Map<String, dynamic> json) => Transcript(
        id: json['id'],
        title: json['title'],
        text: json['text'],
        summary: json['summary'],
        createdAt: DateTime.parse(json['createdAt']),
        duration: Duration(seconds: json['durationSeconds'] ?? 0),
      );

  String get formattedDuration {
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60);
    final s = duration.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }
}
