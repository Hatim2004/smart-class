import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './home_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _controller = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  Future<void> _save() async {
    final key = _controller.text.trim();
    if (key.isEmpty) {
      setState(() => _error = 'Enter a valid Anthropic API key (starts with sk-ant-)');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_key', key);
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen(apiKey: key)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              // Logo
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF4A4AFF), Color(0xFF7B2FFF)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4A4AFF).withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ).animate().scale(delay: 100.ms),
              const SizedBox(height: 28),
              Text(
                'ClassRecord AI',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
              const SizedBox(height: 8),
              Text(
                'Record lectures, transcribe speech in real-time, and get instant AI summaries of your classes.',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: const Color(0xFF6C6C8A),
                  height: 1.6,
                ),
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 48),

              // Features
              ...[
                ('🎙️', 'Real-time Speech to Text', 'Words appear as you speak'),
                ('🤖', 'AI Summarization', 'Get structured notes instantly'),
                ('💾', 'Save & Organize', 'All lectures saved locally'),
              ].mapIndexed((i, item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _FeatureTile(
                      emoji: item.$1,
                      title: item.$2,
                      subtitle: item.$3,
                    )
                        .animate(delay: Duration(milliseconds: 400 + i * 80))
                        .fadeIn()
                        .slideX(begin: 0.1),
                  )),

              const SizedBox(height: 36),

              Text(
                'Anthropic API Key',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _controller,
                obscureText: _obscure,
                style: GoogleFonts.jetBrainsMono(
                  color: Colors.white,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'sk-ant-api03-...',
                  hintStyle: GoogleFonts.jetBrainsMono(
                    color: const Color(0xFF3A3A5C),
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: const Color(0xFF111128),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF252547)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF252547)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF4A4AFF), width: 2),
                  ),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: const Color(0xFF6C6C8A),
                    ),
                  ),
                  errorText: _error,
                  errorStyle: GoogleFonts.inter(color: const Color(0xFFFF6B6B)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                onSubmitted: (_) => _save(),
              ).animate().fadeIn(delay: 700.ms),
              const SizedBox(height: 8),
              Text(
                'Get your API key at console.anthropic.com',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF3A3A5C),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: _loading
                    ? Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4A4AFF), Color(0xFF7B2FFF)],
                          ),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4A4AFF), Color(0xFF7B2FFF)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            child: Text(
                              'Get Started →',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
              ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final String emoji, title, subtitle;
  const _FeatureTile({required this.emoji, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111128),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E1E3A)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  )),
              Text(subtitle,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF6C6C8A),
                    fontSize: 12,
                  )),
            ],
          ),
        ],
      ),
    );
  }
}

extension IndexedMap<T> on List<T> {
  Iterable<R> mapIndexed<R>(R Function(int index, T item) f) {
    var i = 0;
    return map((e) => f(i++, e));
  }
}
