import 'dart:convert';
import 'package:http/http.dart' as http;

class AiService {
  final String apiKey;
  static const _model = 'gemini-3-flash-preview:generateContent';
  static const _url = 'https://generativelanguage.googleapis.com/v1beta';

  AiService({required this.apiKey});

  Future<String> summarize(String transcript) async {
    final prompt = '''You are an expert educational assistant. 
Summarize the following class lecture transcript into a clear, structured summary.

Include:
1. 📌 **Main Topic** – One sentence about what the class covered
2. 🔑 **Key Concepts** – Bullet list of the most important ideas
3. 📝 **Detailed Notes** – Organized paragraphs covering the main content
4. 💡 **Key Takeaways** – 3-5 actionable insights or things to remember
5. ❓ **Possible Exam Questions** – 3 questions a teacher might ask based on this content

Transcript:
"""
$transcript
"""

Provide a comprehensive, well-structured summary that a student can use to study from.''';

    final response = await http.post(
      Uri.parse(_url),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': _model,
        'max_tokens': 2000,
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['content'][0]['text'] as String;
    } else {
      final err = jsonDecode(response.body);
      throw Exception('API Error ${response.statusCode}: ${err['error']?['message'] ?? response.body}');
    }
  }

  Future<String> generateTitle(String transcript) async {
    final shortText = transcript.length > 500 ? transcript.substring(0, 500) : transcript;

    final response = await http.post(
      Uri.parse(_url),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': _model,
        'max_tokens': 50,
        'messages': [
          {
            'role': 'user',
            'content': 'Generate a short, descriptive title (max 5 words) for this class lecture transcript. Only respond with the title, nothing else.\n\n$shortText'
          }
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['content'][0]['text'] as String).trim().replaceAll('"', '');
    }
    return 'Class Recording';
  }
}
